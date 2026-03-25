#!/usr/bin/env bash
# build-linux.sh - build all packages for Linux-native Termux using buildorder.py

set -euo pipefail

TERMUX_SCRIPTDIR=$(cd "$(realpath "$(dirname "$0")")"; pwd)

# Store pid for docker trap if needed
source "$TERMUX_SCRIPTDIR/scripts/utils/docker/docker.sh"; docker__create_docker_exec_pid_file

# Ensure not running on Android
if [ "$(uname -o)" = "Android" ] || [ -e "/system/bin/app_process" ]; then
    echo "On-device execution of this script is not supported."
    exit 1
fi

# Load optional user settings
test -f "$HOME"/.termuxrc && . "$HOME"/.termuxrc

: ${TERMUX_TOPDIR:="$HOME/.termux-build"}
: ${TERMUX_ARCH:="x86_64"}      # Linux-native default
: ${TERMUX_FORMAT:="debian"}
: ${TERMUX_DEBUG_BUILD:=""}
: ${TERMUX_INSTALL_DEPS:="-i"}  # Install dependencies automatically
: ${TERMUX_PACKAGE_LIBRARY:="glibc"}  # Force Linux glibc

_show_usage() {
    echo "Usage: ./build-linux.sh [-a ARCH] [-d] [-i] [-o DIR] [-f FORMAT]"
    echo "Build all packages for Linux-native Termux."
    echo "  -a Architecture: aarch64(default), arm, i686, x86_64 or all"
    echo "  -d Build with debug symbols"
    echo "  -i Build dependencies"
    echo "  -o Output directory (default: termux-system/)"
    echo "  -f Package format: debian(default) or pacman"
    exit 1
}

# Parse CLI options
while getopts :a:hdio:f: option; do
case "$option" in
    a) TERMUX_ARCH="$OPTARG";;
    d) TERMUX_DEBUG_BUILD='-d';;
    i) TERMUX_INSTALL_DEPS='-i';;
    o) TERMUX_OUTPUT_DIR="$(realpath -m "$OPTARG")";;
    f) TERMUX_FORMAT="$OPTARG";;
    h) _show_usage;;
    *) _show_usage >&2 ;;
esac
done
shift $((OPTIND-1))
if [ "$#" -ne 0 ]; then _show_usage; fi

# Validate architecture and format
case "$TERMUX_ARCH" in
    all|aarch64|arm|i686|x86_64);;
    *) echo "ERROR: Invalid arch '$TERMUX_ARCH'" 1>&2; exit 1;;
esac

case "$TERMUX_FORMAT" in
    debian|pacman);;
    *) echo "ERROR: Invalid format '$TERMUX_FORMAT'" 1>&2; exit 1;;
esac

BUILDSCRIPT="$TERMUX_SCRIPTDIR/build-package-linux.sh"
BUILDALL_DIR="$TERMUX_TOPDIR/_build-linux-$TERMUX_ARCH"
BUILDORDER_FILE="$BUILDALL_DIR/buildorder.txt"
BUILDSTATUS_FILE="$BUILDALL_DIR/buildstatus.txt"

mkdir -p "$BUILDALL_DIR"

# Generate or refresh build order
"$TERMUX_SCRIPTDIR/scripts/buildorder.py" > "$BUILDORDER_FILE"

# Prepare logging
exec &> >(tee -a "$BUILDALL_DIR"/ALL.log)
trap 'echo ERROR: See $BUILDALL_DIR/${PKG}.log' ERR

# Build loop
while read -r PKG PKG_DIR; do
    if [ -e "$BUILDSTATUS_FILE" ] && grep -q "^$PKG\$" "$BUILDSTATUS_FILE"; then
        echo "Skipping $PKG"
        continue
    fi

    echo -n "Building $PKG... "
    BUILD_START=$(date "+%s")

    "$BUILDSCRIPT" -a "$TERMUX_ARCH" $TERMUX_DEBUG_BUILD --format "$TERMUX_FORMAT" \
        --library glibc \
        ${TERMUX_OUTPUT_DIR+-o $TERMUX_OUTPUT_DIR} $TERMUX_INSTALL_DEPS "$PKG_DIR" \
        &> "$BUILDALL_DIR"/"${PKG}.log"

    BUILD_END=$(date "+%s")
    BUILD_SECONDS=$(( BUILD_END - BUILD_START ))
    echo "done in $BUILD_SECONDS sec"

    echo "$PKG" >> "$BUILDSTATUS_FILE"
done < "$BUILDORDER_FILE"

# Cleanup status
rm -f "$BUILDSTATUS_FILE"
echo "Finished Linux-native build"