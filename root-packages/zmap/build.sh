#!/usr/bin/env bash
# Termux build script for zmap

TERMUX_PKG_NAME="zmap"
TERMUX_PKG_HOMEPAGE="https://zmap.io/"
TERMUX_PKG_DESCRIPTION="Fast network scanner"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v4.3.4"
TERMUX_PKG_SRCURL="https://api.github.com/repos/zmap/zmap/tarball/v4.3.4"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"
    mkdir -p "$TERMUX_PREFIX/etc/zmap"

    # Install binaries
    cp zmap "$TERMUX_PREFIX/bin/"
    cp zgrab "$TERMUX_PREFIX/bin/" || true   # if included in build
    cp zdns "$TERMUX_PREFIX/bin/" || true    # if included in build

    # Install man pages
    if [ -f doc/zmap.1 ]; then
        install -Dm600 doc/zmap.1 "$TERMUX_PREFIX/share/man/man1/zmap.1"
    fi
    if [ -f doc/zgrab.1 ]; then
        install -Dm600 doc/zgrab.1 "$TERMUX_PREFIX/share/man/man1/zgrab.1"
    fi
    if [ -f doc/zdns.1 ]; then
        install -Dm600 doc/zdns.1 "$TERMUX_PREFIX/share/man/man1/zdns.1"
    fi

    # Install default blocklist
    cp conf/zmap.conf "$TERMUX_PREFIX/etc/zmap/zmap.conf"
    sed -i "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g" "$TERMUX_PREFIX/etc/zmap/zmap.conf"
    mkdir -p "$TERMUX_PREFIX/etc/zmap"
    touch "$TERMUX_PREFIX/etc/zmap/blocklist.conf"

    # Install documentation
    cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    cp LICENSE "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}