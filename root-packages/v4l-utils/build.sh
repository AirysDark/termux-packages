#!/usr/bin/env bash
# Auto-generated Termux build.sh for v4l-utils

TERMUX_PKG_NAME="v4l-utils"
TERMUX_PKG_HOMEPAGE="https://www.linuxtv.org/"
TERMUX_PKG_DESCRIPTION="Video4Linux utilities and libraries"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.22.0"
TERMUX_PKG_SRCURL="https://www.linuxtv.org/downloads/v4l-utils/v4l-utils-1.22.0.tar.bz2"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    echo "Applying all v4l-utils patches..."
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/getsubopt.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/no-android.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/no-posix-shm.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/no-udev.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/pthread_cancel.patch"
}

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install binaries
    cp -f bin/* "$TERMUX_PREFIX/bin/"

    # Install man pages
    cp -f doc/*.1 "$TERMUX_PREFIX/share/man/man1/"

    # Install documentation
    cp -f README* "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "v4l-utils installation complete"
}