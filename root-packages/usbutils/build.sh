#!/usr/bin/env bash
# Auto-generated Termux build.sh
TERMUX_PKG_NAME="usbutils"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="009"
TERMUX_PKG_SRCURL="https://mirrors.edge.kernel.org/pub/linux/utils/usb/usbutils/usbutils-009.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Create standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Copy built binaries (example: lsusb)
    if [ -f "lsusb" ]; then
        cp lsusb "$TERMUX_PREFIX/bin/"
    fi

    # Copy man pages
    if [ -f "lsusb.1" ]; then
        install -Dm600 lsusb.1 "$TERMUX_PREFIX/share/man/man1/lsusb.1"
    fi

    # Copy documentation (README, etc.)
    if [ -f "README" ]; then
        cp README "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    fi

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}