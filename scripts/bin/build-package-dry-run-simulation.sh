#!/usr/bin/env bash
##
## dry-run-build.sh - Simulate a package build without executing it
## This script mimics 'build-package.sh' behavior to validate arguments and package selection
## Only reports what would be done.
##

set -euo pipefail

# ----------------------------
# Environment setup
# ----------------------------
TERMUX_SCRIPTDIR=$(cd "$(realpath "$(dirname "$0")")/../.."; pwd)
DRY_RUN_SCRIPT_NAME=$(basename "$0")
BUILDSCRIPT_NAME="build-package.sh"

TERMUX_ARCH="aarch64"
TERMUX_DEBUG_BUILD="false"
TERMUX_PACKAGES_DIRECTORIES="
packages
root-packages
x11-packages
"

# ----------------------------
# Parse command-line arguments
# ----------------------------
declare -a PACKAGE_LIST=()
while (($# >= 1)); do
    case "$1" in
        *"/$BUILDSCRIPT_NAME") ;; # ignore direct references to build.sh
        -a)
            if [ $# -lt 2 ] || [ -z "$2" ]; then
                echo "$DRY_RUN_SCRIPT_NAME: Option '-a' requires a non-empty argument"
                exit 1
            fi
            TERMUX_ARCH="$2"
            shift 1
            ;;
        -d) TERMUX_DEBUG_BUILD="true" ;;
        -*) ;; # ignore other flags
        *) PACKAGE_LIST+=("$1") ;;
    esac
    shift 1
done

# ----------------------------
# Validate and simulate package builds
# ----------------------------
for ((i=0; i<${#PACKAGE_LIST[@]}; i++)); do
    TERMUX_PKG_NAME=$(basename "${PACKAGE_LIST[i]}")
    TERMUX_PKG_BUILDER_DIR=""

    # Locate package in directories
    for package_directory in $TERMUX_PACKAGES_DIRECTORIES; do
        if [ -d "${TERMUX_SCRIPTDIR}/${package_directory}/${TERMUX_PKG_NAME}" ]; then
            TERMUX_PKG_BUILDER_DIR="${TERMUX_SCRIPTDIR}/$package_directory/$TERMUX_PKG_NAME"
            break
        fi
    done

    if [ -z "${TERMUX_PKG_BUILDER_DIR}" ]; then
        echo "$DRY_RUN_SCRIPT_NAME: No package '$TERMUX_PKG_NAME' found in enabled repositories."
        exit 1
    fi

    TERMUX_PKG_BUILDER_SCRIPT="$TERMUX_PKG_BUILDER_DIR/build.sh"

    # Skip excluded architecture
    if [ "${TERMUX_ARCH}" != "all" ] && \
       grep -qE "^TERMUX_PKG_EXCLUDED_ARCHES=.*${TERMUX_ARCH}" "$TERMUX_PKG_BUILDER_SCRIPT"; then
        echo "$DRY_RUN_SCRIPT_NAME: Skipping $TERMUX_PKG_NAME for arch $TERMUX_ARCH"
        continue
    fi

    # Skip debug build if not enabled
    if [ "${TERMUX_DEBUG_BUILD}" = "true" ] && \
       grep -qE "^TERMUX_PKG_HAS_DEBUG=.*false" "$TERMUX_PKG_BUILDER_SCRIPT"; then
        echo "$DRY_RUN_SCRIPT_NAME: Skipping debug build for $TERMUX_PKG_NAME"
        continue
    fi

    echo "$DRY_RUN_SCRIPT_NAME: Ending dry run simulation ($BUILDSCRIPT_NAME would have continued building $TERMUX_PKG_NAME)"
    exit 0
done

# No packages would have been built
if [ ${#PACKAGE_LIST[@]} -gt 0 ]; then
    echo "$DRY_RUN_SCRIPT_NAME: Ending dry run simulation ($BUILDSCRIPT_NAME would not have built any packages)"
    exit 85 # EX_C__NOOP
fi

# Unknown or unimplemented argument combination
echo "$DRY_RUN_SCRIPT_NAME: Ending dry run simulation (unknown arguments, pass to the real $BUILDSCRIPT_NAME for details)"
exit 0