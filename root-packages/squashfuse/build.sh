#!/usr/bin/env bash
# Auto-generated Termux build.sh
TERMUX_PKG_NAME="squashfuse"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.6.1"
TERMUX_PKG_SRCURL="https://api.github.com/repos/vasi/squashfuse/tarball/0.6.1"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # --- BINARIES ---
    # Copy the demo binaries enabled by the Makefile.am patch
    cp -f squashfuse_ls "$TERMUX_PREFIX/bin/"
    cp -f squashfuse_extract "$TERMUX_PREFIX/bin/"

    # --- PLACEHOLDERS ---
    # Install man pages (if any)
    # Example: install -Dm600 "doc/squashfuse_ls.1" "$TERMUX_PREFIX/share/man/man1/"
    # Example: install -Dm600 "doc/squashfuse_extract.1" "$TERMUX_PREFIX/share/man/man1/"

    # Install documentation (if any)
    # Example: cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Install complete for ${TERMUX_PKG_NAME}"
}