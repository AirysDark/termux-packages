#!/usr/bin/env bash
# Termux build.sh for vnStat v2.13

TERMUX_PKG_NAME="vnstat"
TERMUX_PKG_HOMEPAGE="https://humdi.net/vnstat/"
TERMUX_PKG_DESCRIPTION="Console-based network traffic monitor"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v2.13"
TERMUX_PKG_SRCURL="https://api.github.com/repos/vergoh/vnstat/tarball/v2.13"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing vnStat directories and files..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/$TERMUX_PKG_NAME"
    mkdir -p "$TERMUX_PREFIX/var/lib/vnstat"
    mkdir -p "$TERMUX_PREFIX/var/log/vnstat"
    mkdir -p "$TERMUX_PREFIX/var/run"

    # Install binaries
    cp vnstat "$TERMUX_PREFIX/bin/"
    cp vnstati "$TERMUX_PREFIX/bin/"

    # Install man pages
    install -Dm600 doc/vnstat.1 "$TERMUX_PREFIX/share/man/man1/vnstat.1"
    install -Dm600 doc/vnstati.1 "$TERMUX_PREFIX/share/man/man1/vnstati.1"

    # Install configuration file
    install -Dm600 cfg/vnstat.conf "$TERMUX_PREFIX/etc/vnstat.conf"

    # Install documentation
    cp README.md "$TERMUX_PREFIX/share/doc/$TERMUX_PKG_NAME/"

    # Apply patched common.h defaults (paths)
    sed -i "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g" src/common.h

    echo "vnStat installation complete."
}