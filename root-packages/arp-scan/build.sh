#!/usr/bin/env bash
# Auto-generated Termux build.sh for arp-scan
set -euo pipefail

TERMUX_PKG_NAME="arp-scan"
TERMUX_PKG_HOMEPAGE="https://github.com/royhills/arp-scan"
TERMUX_PKG_DESCRIPTION="Tool for network discovery and fingerprinting using ARP"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.10.0"
TERMUX_PKG_SRCURL="https://api.github.com/repos/royhills/arp-scan/tarball/1.10.0"
TERMUX_PKG_SHA256=""  # Fill in if known
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # --- COMPILE SOURCES ---
    echo "Compiling ${TERMUX_PKG_NAME}..."
    gcc -std=c99 -O2 -I. \
        arp-scan.c error.c wrappers.c utils.c mt19937ar.c format.c \
        hcreate.c hcreate_r.c hsearch_r.c hdestroy_r.c \
        -o arp-scan -lm

    chmod +x arp-scan

    # Install binary
    cp arp-scan "$TERMUX_PREFIX/bin/"

    # Install man pages (placeholder)
    # Example: install -Dm600 "doc/arp-scan.1" "$TERMUX_PREFIX/share/man/man1/"

    # Install documentation (placeholder)
    # Example: cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Install complete for ${TERMUX_PKG_NAME}"
}
