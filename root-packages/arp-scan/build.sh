#!/usr/bin/env bash
# Termux-style build.sh for arp-scan

set -euo pipefail

# -------------------------
# Package metadata
# -------------------------
TERMUX_PKG_NAME="arp-scan"
TERMUX_PKG_HOMEPAGE="https://github.com/royhills/arp-scan"
TERMUX_PKG_DESCRIPTION="Command-line tool for network discovery and fingerprinting using ARP"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.10.0"
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL="https://github.com/royhills/arp-scan/archive/refs/tags/${TERMUX_PKG_VERSION}.tar.gz"
TERMUX_PKG_SHA256="204b13487158b8e46bf6dd207757a52621148fdd1d2467ebd104de17493bab25"
TERMUX_PKG_DEPENDS="libpcap"
TERMUX_PKG_BUILD_IN_SRC=true

# -------------------------
# Pre-configure step
# -------------------------
termux_step_pre_configure() {
    echo "Running autoreconf for ${TERMUX_PKG_NAME}..."
    autoreconf -fi
}

# -------------------------
# Post make install
# -------------------------
termux_step_post_make_install() {
    echo "Installing ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Compile sources manually if needed
    echo "Compiling ${TERMUX_PKG_NAME} sources..."
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
        -o "$TERMUX_PKG_BUILDDIR/arp-scan" -lm

    chmod +x "$TERMUX_PKG_BUILDDIR/arp-scan"

    # Install binary
    cp "$TERMUX_PKG_BUILDDIR/arp-scan" "$TERMUX_PREFIX/bin/"

    # Install man pages (placeholder)
    # Example: install -Dm600 "$TERMUX_PKG_SRCDIR/doc/arp-scan.1" "$TERMUX_PREFIX/share/man/man1/arp-scan.1"

    # Install documentation (placeholder)
    # Example: cp "$TERMUX_PKG_SRCDIR/README.md" "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "${TERMUX_PKG_NAME} installation complete!"
}

# -------------------------
# Optional post-patch step
# -------------------------
termux_step_post_patch() {
    echo "No patches for ${TERMUX_PKG_NAME}."
}