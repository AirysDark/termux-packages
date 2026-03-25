#!/usr/bin/env bash
# build-package-linux.sh - Linux-native Termux package builder
# Updated for packages-linux repository and buildorder-Linux.py integration

# ----------------------------
# Basic environment setup
# ----------------------------

: "${TMPDIR:=/tmp}"
export TMPDIR

# Handle nested build calls
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

# ----------------------------
# Utilities and helpers
# ----------------------------

source "$TERMUX_SCRIPTDIR/scripts/utils/termux/package/termux_package.sh"
source "$TERMUX_SCRIPTDIR/scripts/build/termux_error_exit.sh"
source "$TERMUX_SCRIPTDIR/scripts/build/termux_download.sh"

# Disable Android-only proot
TERMUX_ON_DEVICE_BUILD=false

# Default Linux architecture and library
: "${TERMUX_ARCH:=x86_64}"
: "${TERMUX_PACKAGE_LIBRARY:=glibc}"

# ----------------------------
# Package tracking functions
# ----------------------------

termux_check_package_in_built_packages_list() {
    [[ ! -f "$TERMUX_BUILD_PACKAGE_CALL_BUILT_PACKAGES_LIST_FILE_PATH" ]] && \
        termux_error_exit "file '$TERMUX_BUILD_PACKAGE_CALL_BUILT_PACKAGES_LIST_FILE_PATH' not found."
    [[ " $(< "$TERMUX_BUILD_PACKAGE_CALL_BUILT_PACKAGES_LIST_FILE_PATH") " == *" $1 "* ]]
    return $?
}

termux_add_package_to_built_packages_list() {
    if ! termux_check_package_in_built_packages_list "$1"; then
        echo -n "$1 " >> "$TERMUX_BUILD_PACKAGE_CALL_BUILT_PACKAGES_LIST_FILE_PATH"
    fi
}

termux_check_package_in_building_packages_list() {
    [[ ! -f "$TERMUX_BUILD_PACKAGE_CALL_BUILDING_PACKAGES_LIST_FILE_PATH" ]] && \
        termux_error_exit "file '$TERMUX_BUILD_PACKAGE_CALL_BUILDING_PACKAGES_LIST_FILE_PATH' not found."
    [[ $'\n'"$(<"$TERMUX_BUILD_PACKAGE_CALL_BUILDING_PACKAGES_LIST_FILE_PATH")"$'\n' == *$'\n'"$1"$'\n'* ]]
    return $?
}

# ----------------------------
# Prevent sudo usage
# ----------------------------
sudo() {
    termux_error_exit "Do not use 'sudo' inside build scripts. Use proper environment setup."
}

# ----------------------------
# Command-line parsing
# ----------------------------
_show_usage() {
    echo "Usage: ./build-package-linux.sh [options] PACKAGE_DIR_1 PACKAGE_DIR_2 ..."
    echo "Options:"
    echo "  -a ARCH     Architecture: aarch64, arm, i686, x86_64"
    echo "  -d          Build with debug symbols"
    echo "  -f          Force build (rebuild even if built)"
    echo "  --library   Library: glibc"
    echo "  -o DIR      Output directory (default: output/)"
    echo "  -c          Continue previous build"
    exit 1
}

declare -a PACKAGE_LIST=()

(( $# )) || _show_usage
while (( $# )); do
    case "$1" in
        -*) _show_usage;;
        *) PACKAGE_LIST+=("$1");;
    esac
    shift 1
done

# ----------------------------
# Generate build order using buildorder-Linux.py
# ----------------------------
if [[ ${#PACKAGE_LIST[@]} -eq 0 ]]; then
    echo "ERROR: No package directories provided."
    _show_usage
fi

# Call buildorder-Linux.py and capture output
BUILD_ORDER=$(python3 "$TERMUX_SCRIPTDIR/buildorder-Linux.py" "${PACKAGE_LIST[@]}")

# ----------------------------
# Loop over packages in dependency order
# ----------------------------
while IFS= read -r line; do
    PKG_NAME=$(echo "$line" | awk '{print $1}')
    PKG_DIR=$(echo "$line" | awk '{print $2}')

    TERMUX_PKG_BUILDER_DIR="$PKG_DIR"
    TERMUX_PKG_BUILDER_SCRIPT="$TERMUX_PKG_BUILDER_DIR/build.sh"
    [[ -f "$TERMUX_PKG_BUILDER_SCRIPT" ]] || termux_error_exit "No build.sh in $PKG_DIR"

    echo "✅ Building package: $PKG_NAME"

    termux_step_setup_variables
    termux_step_handle_buildarch

    termux_step_cleanup_packages
    termux_step_start_build

    termux_step_get_dependencies
    termux_step_override_config_scripts

    termux_step_create_timestamp_file
    termux_step_get_source
    termux_step_post_get_source
    termux_step_handle_host_build

    termux_step_setup_toolchain
    termux_step_patch_package
    termux_step_replace_guess_scripts
    termux_step_pre_configure

    termux_step_configure
    termux_step_make
    termux_step_make_install

    termux_step_post_make_install
    termux_step_install_pacman_hooks
    termux_step_install_service_scripts
    termux_step_install_license
    termux_step_copy_into_massagedir
    termux_step_pre_massage
    termux_step_massage
    termux_step_post_massage

    case "$TERMUX_PACKAGE_FORMAT" in
        debian) termux_step_create_debian_package;;
        pacman) termux_step_create_pacman_package;;
    esac

    termux_add_package_to_built_packages_list "$PKG_NAME"
    termux_step_finish_build

done <<< "$BUILD_ORDER"

# ----------------------------
# Cleanup
# ----------------------------
if (( ! TERMUX_BUILD_PACKAGE_CALL_DEPTH )); then
    rm -f "$TERMUX_BUILD_PACKAGE_CALL_BUILT_PACKAGES_LIST_FILE_PATH"
    rm -f "$TERMUX_BUILD_PACKAGE_CALL_BUILDING_PACKAGES_LIST_FILE_PATH"
fi

echo "✅ Finished Linux-native build for packages-linux."