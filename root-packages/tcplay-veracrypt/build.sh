#!/usr/bin/env bash
# Auto-generated Termux build.sh

TERMUX_PKG_NAME="tcplay-veracrypt"
TERMUX_PKG_HOMEPAGE="https://github.com/bwalex/tc-play"
TERMUX_PKG_DESCRIPTION="Tools for encrypting volumes using TrueCrypt/Veracrypt containers"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="3.3-github"
TERMUX_PKG_SRCURL="https://github.com/bwalex/tc-play/archive/refs/tags/v3.3.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS="libc, libuuid"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    echo "Applying Termux patches for ${TERMUX_PKG_NAME}..."
    # Apply the MKDEV patch to fix makedev issues
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/makedev.patch"
}

termux_step_make() {
    echo "Building ${TERMUX_PKG_NAME}..."
    # Use Termux-friendly make
    make CFLAGS="-fPIC -O2" LDFLAGS=""
}

termux_step_make_install() {
    echo "Installing ${TERMUX_PKG_NAME} to $TERMUX_PREFIX..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Copy binaries
    cp tcplay "$TERMUX_PREFIX/bin/"
    cp tcplay-luks "$TERMUX_PREFIX/bin/"

    # Man pages (if available)
    if [ -f tcplay.1 ]; then
        install -Dm600 tcplay.1 "$TERMUX_PREFIX/share/man/man1/tcplay.1"
    fi

    # Documentation
    if [ -f README.md ]; then
        cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    fi

    echo "Installation of ${TERMUX_PKG_NAME} complete."
}