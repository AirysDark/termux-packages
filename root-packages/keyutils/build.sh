#!/usr/bin/env bash
# Auto-generated Termux build.sh
TERMUX_PKG_NAME="keyutils"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.6.0"
TERMUX_PKG_SRCURL="https://github.com/.../keyutils-1.6.0.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing ${TERMUX_PKG_NAME} binaries, man pages, and configuration..."

    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/sbin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/keyutils"
    mkdir -p "$TERMUX_PREFIX/etc/keyutils"

    cp keyctl key.dns_resolver "$TERMUX_PREFIX/bin/"
    install -Dm600 keyctl.1 "$TERMUX_PREFIX/share/man/man1/keyctl.1"
    install -Dm600 key.dns_resolver.8 "$TERMUX_PREFIX/share/man/man8/key.dns_resolver.8"
    cp request-key.conf "$TERMUX_PREFIX/etc/keyutils/request-key.conf"

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}