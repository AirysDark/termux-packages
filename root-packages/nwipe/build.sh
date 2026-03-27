#!/usr/bin/env bash
# Termux build script for nwipe v0.40

TERMUX_PKG_NAME="nwipe"
TERMUX_PKG_HOMEPAGE="https://github.com/martijnvanbrummelen/nwipe"
TERMUX_PKG_DESCRIPTION="Utility for secure disk wiping"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v0.40"
TERMUX_PKG_SRCURL="https://api.github.com/repos/martijnvanbrummelen/nwipe/tarball/v0.40"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS="libc, ncurses"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install binaries
    cp nwipe "$TERMUX_PREFIX/bin/"

    # Install man pages
    if [ -f doc/nwipe.1 ]; then
        install -Dm600 "doc/nwipe.1" "$TERMUX_PREFIX/share/man/man1/nwipe.1"
    fi

    # Install documentation
    for docfile in README.md CHANGELOG.md LICENSE; do
        if [ -f "$docfile" ]; then
            cp "$docfile" "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
        fi
    done

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}