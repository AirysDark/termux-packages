#!/usr/bin/env bash
# Termux build script for macchanger
TERMUX_PKG_NAME="macchanger"
TERMUX_PKG_HOMEPAGE="https://github.com/alobbs/macchanger"
TERMUX_PKG_DESCRIPTION="Utility to change the MAC address of network interfaces"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.8.4"
TERMUX_PKG_SRCURL="https://github.com/alobbs/macchanger/archive/refs/tags/1.7.0.tar.gz"
TERMUX_PKG_SHA256=""  # You should fill the correct sha256
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--prefix=$TERMUX_PREFIX"

termux_step_pre_configure() {
    # Apply your patch to autogen.sh
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/autogen.sh.patch"
}

termux_step_make() {
    # Autogen step (configure is skipped in your patch)
    bash ./autogen.sh
    make -j$(nproc)
}

termux_step_make_install() {
    echo "Installing ${TERMUX_PKG_NAME}..."

    make DESTDIR="$TERMUX_PREFIX" install

    # Ensure standard directories exist
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"
}