#!/usr/bin/env bash
# Auto-generated Termux build.sh
TERMUX_PKG_NAME="libcryptsetup"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION="Userspace setup tool for transparent encryption of block devices using dm-crypt"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2.6.0"
TERMUX_PKG_SRCURL="https://gitlab.com/cryptsetup/cryptsetup/-/archive/v2.6.0/cryptsetup-v2.6.0.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS="libpopt, libblkid, libuuid"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/libexec"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install binaries
    cp bin/* "$TERMUX_PREFIX/bin/"

    # Install man pages
    cp share/man/* "$TERMUX_PREFIX/share/man/"

    # Install subpackage binaries/scripts
    if [ -d bin ]; then
        cp bin/* "$TERMUX_PREFIX/libexec/"
    fi

    # Install documentation
    if [ -f README.md ]; then
        cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    fi

    echo "Install complete for ${TERMUX_PKG_NAME}"
}