#!/usr/bin/env bash
# ==========================================================
# Termux-style build.sh for arp-scan
# ==========================================================
set -euo pipefail

# -----------------------------
# Package metadata
# -----------------------------
TERMUX_PKG_NAME="arp-scan"
TERMUX_PKG_VERSION="1.10.0"
TERMUX_PKG_REVISION=1
TERMUX_PKG_HOMEPAGE="https://github.com/royhills/arp-scan"
TERMUX_PKG_DESCRIPTION="ARP network scanner for discovery and fingerprinting"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_SRCURL="https://github.com/royhills/arp-scan/archive/refs/tags/${TERMUX_PKG_VERSION}.tar.gz"
TERMUX_PKG_SHA256="204b13487158b8e46bf6dd207757a52621148fdd1d2467ebd104de17493bab25"
TERMUX_PKG_DEPENDS="libpcap"
TERMUX_PKG_BUILD_IN_SRC=true

# -----------------------------
# Load Termux build functions
# -----------------------------
source "$TERMUX_SCRIPTDIR/scripts/build/termux_step_start_build.sh"
source "$TERMUX_SCRIPTDIR/scripts/build/termux_step_setup_variables.sh"
source "$TERMUX_SCRIPTDIR/scripts/build/termux_step_handle_buildarch.sh"
source "$TERMUX_SCRIPTDIR/scripts/build/termux_step_get_dependencies.sh"
source "$TERMUX_SCRIPTDIR/scripts/build/termux_step_get_dependencies_python.sh"

# -----------------------------
# Setup directories and environment
# -----------------------------
termux_step_setup_variables
termux_step_handle_buildarch

# -----------------------------
# Download and unpack sources
# -----------------------------
termux_step_get_source

# -----------------------------
# Pre-configure hook
# -----------------------------
termux_step_pre_configure() {
    echo "Running autoreconf for ${TERMUX_PKG_NAME}..."
    if [ -d "$TERMUX_PKG_SRCDIR" ]; then
        cp -r "$TERMUX_PKG_BUILDER_DIR/hsearch" "$TERMUX_PKG_SRCDIR/" || true
        autoreconf -fi
    fi
}

# -----------------------------
# Start build
# -----------------------------
termux_step_start_build

# -----------------------------
# Post-make-install hook
# -----------------------------
termux_step_post_make_install() {
    echo "Installing ${TERMUX_PKG_NAME} to $TERMUX_PREFIX..."

    # Create standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Compile sources if not handled by upstream make
    echo "Compiling ${TERMUX_PKG_NAME}..."
    gcc -std=c99 -O2 -I"$TERMUX_PKG_SRCDIR" \
        "$TERMUX_PKG_SRCDIR"/arp-scan.c \
        "$TERMUX_PKG_SRCDIR"/error.c \
        "$TERMUX_PKG_SRCDIR"/wrappers.c \
        "$TERMUX_PKG_SRCDIR"/utils.c \
        "$TERMUX_PKG_SRCDIR"/mt19937ar.c \
        "$TERMUX_PKG_SRCDIR"/format.c \
        "$TERMUX_PKG_SRCDIR"/hcreate.c \
        "$TERMUX_PKG_SRCDIR"/hcreate_r.c \
        "$TERMUX_PKG_SRCDIR"/hsearch_r.c \
        "$TERMUX_PKG_SRCDIR"/hdestroy_r.c \
        -o "$TERMUX_PKG_NAME" -lm

    chmod +x "$TERMUX_PKG_NAME"
    cp "$TERMUX_PKG_NAME" "$TERMUX_PREFIX/bin/"

    # Placeholder for man pages (if any)
    # install -Dm600 "$TERMUX_PKG_SRCDIR/doc/arp-scan.1" "$TERMUX_PREFIX/share/man/man1/"

    # Placeholder for docs
    # cp "$TERMUX_PKG_SRCDIR/README.md" "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Install complete for ${TERMUX_PKG_NAME}!"
}