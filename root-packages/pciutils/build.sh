#!/usr/bin/env bash
# Termux build.sh for pciutils

TERMUX_PKG_NAME="pciutils"
TERMUX_PKG_HOMEPAGE="https://pciutils.sourceforge.io/"
TERMUX_PKG_DESCRIPTION="Tools for listing PCI devices"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="3.14.0"
TERMUX_PKG_SRCURL="https://api.github.com/repos/pciutils/pciutils/tarball/v3.14.0"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing ${TERMUX_PKG_NAME}..."

    # Directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Binaries
    cp lspci setpci decode-dumpids "$TERMUX_PREFIX/bin/"

    # Man pages
    for manpage in doc/*.1; do
        [ -f "$manpage" ] && install -Dm600 "$manpage" "$TERMUX_PREFIX/share/man/man1/$(basename $manpage)"
    done

    # Documentation
    [ -f README.md ] && cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "${TERMUX_PKG_NAME} installation complete."
}