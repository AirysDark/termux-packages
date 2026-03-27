#!/usr/bin/env bash
# Auto-generated Termux build.sh

TERMUX_PKG_NAME="testdisk"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="7.2"
TERMUX_PKG_SRCURL="https://www.cgsecurity.org/testdisk-7.2.tar.bz2"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # --- INSTALL BINARIES ---
    cp src/testdisk "$TERMUX_PREFIX/bin/"
    cp src/photorec "$TERMUX_PREFIX/bin/"
    cp src/fidentify "$TERMUX_PREFIX/bin/"
    cp src/qphotorec "$TERMUX_PREFIX/bin/"

    # --- INSTALL MAN PAGES ---
    # (Assuming man pages exist under 'doc/' in the source tree)
    if [ -d "doc" ]; then
        install -Dm600 doc/testdisk.1 "$TERMUX_PREFIX/share/man/man1/testdisk.1"
        install -Dm600 doc/photorec.1 "$TERMUX_PREFIX/share/man/man1/photorec.1"
        install -Dm600 doc/fidentify.1 "$TERMUX_PREFIX/share/man/man1/fidentify.1"
        install -Dm600 doc/qphotorec.1 "$TERMUX_PREFIX/share/man/man1/qphotorec.1"
    fi

    # --- INSTALL DOCUMENTATION ---
    cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}