#!/usr/bin/env bash
TERMUX_PKG_NAME="tinc"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.0.35"
TERMUX_PKG_SRCURL="https://api.github.com/repos/gsliepen/tinc/tarball/1.0.35"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install binaries
    cp tincd tincdctl "$TERMUX_PREFIX/bin/"

    # Install man pages
    install -Dm600 doc/tinc.conf.5 "$TERMUX_PREFIX/share/man/man1/tinc.conf.5"

    # Install documentation
    cp README.md LICENSE "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Apply patched default device: /dev/tun instead of /dev/net/tun"
    sed -i 's|/dev/net/tun|/dev/tun|g' "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/tinc.conf" || true

    echo "Install placeholders complete for ${TERMUX_PKG_NAME}"
}