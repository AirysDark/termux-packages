#!/usr/bin/env bash
# Termux build script for wimlib

TERMUX_PKG_NAME="wimlib"
TERMUX_PKG_HOMEPAGE="https://wimlib.net"
TERMUX_PKG_DESCRIPTION="A library and tools for creating, modifying, extracting, and mounting WIM files"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.14.5"
TERMUX_PKG_SRCURL="https://wimlib.net/downloads/wimlib-1.14.5.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Create standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install binaries
    cp wimlib*/wimlib-imagex "$TERMUX_PREFIX/bin/"
    cp wimlib*/wimlib-imagex-strip "$TERMUX_PREFIX/bin/"
    cp wimlib*/wimlib-imagex-split "$TERMUX_PREFIX/bin/"

    # Install man pages
    install -Dm600 wimlib*/wimlib-imagex.1 "$TERMUX_PREFIX/share/man/man1/"

    # Install documentation
    cp wimlib*/README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    cp wimlib*/LICENSE "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}