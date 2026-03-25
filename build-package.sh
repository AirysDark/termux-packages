#!/bin/bash

# Setting the TMPDIR variable
: "${TMPDIR:=/tmp}"
export TMPDIR

# Set the build-package.sh call depth
# If its the root call, then create a file to store the list of packages and their dependencies
# that have been compiled at any instant by recursive calls to build-package.sh
if (( ${TERMUX_BUILD_PACKAGE_CALL_DEPTH-0} )); then
    export TERMUX_BUILD_PACKAGE_CALL_DEPTH=$((TERMUX_BUILD_PACKAGE_CALL_DEPTH+1))
else
    TERMUX_BUILD_PACKAGE_CALL_DEPTH=0
    TERMUX_BUILD_PACKAGE_CALL_BUILT_PACKAGES_LIST_FILE_PATH="${TMPDIR}/build-package-call-built-packages-list-$(date +"%Y-%m-%d-%H.%M.%S.")$((RANDOM%1000))"
    TERMUX_BUILD_PACKAGE_CALL_BUILDING_PACKAGES_LIST_FILE_PATH="${TMPDIR}/build-package-call-building-packages-list-$(date +"%Y-%m-%d-%H.%M.%S.")$((RANDOM%1000))"
    export TERMUX_BUILD_PACKAGE_CALL_DEPTH TERMUX_BUILD_PACKAGE_CALL_BUILT_PACKAGES_LIST_FILE_PATH TERMUX_BUILD_PACKAGE_CALL_BUILDING_PACKAGES_LIST_FILE_PATH
    echo -n " " > "$TERMUX_BUILD_PACKAGE_CALL_BUILT_PACKAGES_LIST_FILE_PATH"
    touch "$TERMUX_BUILD_PACKAGE_CALL_BUILDING_PACKAGES_LIST_FILE_PATH"
fi

set -euo pipefail

cd "$(realpath "$(dirname "$0")")"
TERMUX_SCRIPTDIR=$(pwd)
export TERMUX_SCRIPTDIR

# Store pid of current process in a file for docker__run_docker_exec_trap
source "$TERMUX_SCRIPTDIR/scripts/utils/docker/docker.sh"
docker__create_docker_exec_pid_file

# Source termux_package library
source "$TERMUX_SCRIPTDIR/scripts/utils/termux/package/termux_package.sh"

export SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(git -c log.showSignature=false log -1 --pretty=%ct 2>/dev/null || date "+%s")}

if [[ "$(uname -o)" == "Android" || -e "/system/bin/app_process" ]]; then
    if [[ "$(id -u)" == "0" ]]; then
        echo "On-device execution of this script as root is disabled."
        exit 1
    fi
    export TERMUX_ON_DEVICE_BUILD=true
else
    export TERMUX_ON_DEVICE_BUILD=false
fi

# Offline mode detection
if [[ -f "${TERMUX_SCRIPTDIR}/build-tools/.installed" ]]; then
    export TERMUX_PACKAGES_OFFLINE=true
fi

# Lock file
TERMUX_BUILD_LOCK_FILE="${TMPDIR}/.termux-build.lck"
[[ ! -e "$TERMUX_BUILD_LOCK_FILE" ]] && touch "$TERMUX_BUILD_LOCK_FILE"

TERMUX_REPO_PKG_FORMAT="$(jq --raw-output '.pkg_format // "debian"' "${TERMUX_SCRIPTDIR}/repo.json")"
export TERMUX_REPO_PKG_FORMAT
: "${TERMUX_BUILD_IGNORE_LOCK:=false}"

# Utility sources
source "$TERMUX_SCRIPTDIR/scripts/build/termux_error_exit.sh"
source "$TERMUX_SCRIPTDIR/scripts/build/termux_download.sh"
source "$TERMUX_SCRIPTDIR/scripts/build/setup/termux_setup_proot.sh"
source "$TERMUX_SCRIPTDIR/scripts/build/setup/termux_step_setup_cgct_environment.sh"
source "$TERMUX_SCRIPTDIR/scripts/build/termux_step_setup_variables.sh"
source "$TERMUX_SCRIPTDIR/scripts/build/termux_step_handle_buildarch.sh"
source "$TERMUX_SCRIPTDIR/scripts/build/toolchain/termux_setup_toolchain_gnu.sh"
source "$TERMUX_SCRIPTDIR/scripts/build/termux_step_start_build.sh"

declare -a PACKAGE_LIST=()
(( $# )) || _show_usage

while (( $# )); do
    case "$1" in
        -a)
            if [[ "$TERMUX_ON_DEVICE_BUILD" == "true" ]]; then
                termux_error_exit "Option '-a' not available for on-device builds"
            fi
            shift
            export TERMUX_ARCH="$1"
            ;;
        -c) TERMUX_CONTINUE_BUILD=true ;;
        -C) TERMUX_CLEANUP_BUILT_PACKAGES_ON_LOW_DISK_SPACE=true ;;
        -d) export TERMUX_DEBUG_BUILD=true ;;
        -f) TERMUX_FORCE_BUILD=true ;;
        -F) TERMUX_FORCE_BUILD_DEPENDENCIES=true && TERMUX_FORCE_BUILD=true ;;
        -*) termux_error_exit "Illegal option '$1'" ;;
        *) PACKAGE_LIST+=("$1") ;;
    esac
    shift
done

for (( i=0; i < ${#PACKAGE_LIST[@]}; i++ )); do
    (
        [[ "$TERMUX_BUILD_IGNORE_LOCK" != "true" ]] && flock -n 5 || termux_error_exit "Another build is running"
        (
            # Linux-only 'all' arch
            if [[ "$TERMUX_ON_DEVICE_BUILD" == "false" && "${TERMUX_ARCH-}" == 'all' ]]; then
                _SELF_ARGS=()
                [[ "${TERMUX_CLEANUP_BUILT_PACKAGES_ON_LOW_DISK_SPACE:-}" == "true" ]] && _SELF_ARGS+=("-C")
                [[ "${TERMUX_DEBUG_BUILD:-}" == "true" ]] && _SELF_ARGS+=("-d")
                [[ "${TERMUX_FORCE_BUILD:-}" == "true" ]] && _SELF_ARGS+=("-f")
                [[ -n "${TERMUX_OUTPUT_DIR:-}" ]] && _SELF_ARGS+=("-o" "$TERMUX_OUTPUT_DIR")
                [[ -n "${TERMUX_PACKAGE_FORMAT:-}" ]] && _SELF_ARGS+=("--format" "$TERMUX_PACKAGE_FORMAT")
                [[ -n "${TERMUX_PACKAGE_LIBRARY:-}" ]] && _SELF_ARGS+=("--library" "$TERMUX_PACKAGE_LIBRARY")

                for arch in 'x86_64' 'i686'; do
                    env TERMUX_ARCH="$arch" TERMUX_BUILD_IGNORE_LOCK=true ./build-package.sh \
                        "${_SELF_ARGS[@]}" "${PACKAGE_LIST[i]}"
                done
                exit
            fi

            # Normal build
            TERMUX_PKG_NAME="$(basename "${PACKAGE_LIST[i]}")"
            TERMUX_PKG_BUILDER_DIR="${TERMUX_SCRIPTDIR}/packages/$TERMUX_PKG_NAME"
            [[ ! -d "$TERMUX_PKG_BUILDER_DIR" ]] && termux_error_exit "Package $TERMUX_PKG_NAME not found"

            TERMUX_PKG_BUILDER_SCRIPT=$TERMUX_PKG_BUILDER_DIR/build.sh
            [[ ! -f "$TERMUX_PKG_BUILDER_SCRIPT" ]] && termux_error_exit "No build.sh at $TERMUX_PKG_BUILDER_DIR"

            termux_step_setup_variables
            termux_step_handle_buildarch
            termux_step_start_build
        ) 5>&-
    ) 5< "$TERMUX_BUILD_LOCK_FILE"
done

# Cleanup temp package list files
if (( ! TERMUX_BUILD_PACKAGE_CALL_DEPTH )); then
    rm -f "$TERMUX_BUILD_PACKAGE_CALL_BUILT_PACKAGES_LIST_FILE_PATH"
    rm -f "$TERMUX_BUILD_PACKAGE_CALL_BUILDING_PACKAGES_LIST_FILE_PATH"
fi