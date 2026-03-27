#!/usr/bin/env bash
# Termux build script for wireless-tools

TERMUX_PKG_NAME="wireless-tools"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v29"
TERMUX_PKG_SRCURL="https://api.github.com/repos/HewlettPackard/wireless-tools/tarball/v29"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Ensure standard directories exist
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Copy compiled binaries (replace with actual binary names)
    cp iwconfig "$TERMUX_PREFIX/bin/"
    cp iwlist "$TERMUX_PREFIX/bin/"
    cp iwpriv "$TERMUX_PREFIX/bin/"
    cp iwspy "$TERMUX_PREFIX/bin/"
    cp ifrename "$TERMUX_PREFIX/bin/"

    # Install man pages
    install -Dm600 doc/iwconfig.8 "$TERMUX_PREFIX/share/man/man1/iwconfig.1"
    install -Dm600 doc/iwlist.8 "$TERMUX_PREFIX/share/man/man1/iwlist.1"
    install -Dm600 doc/iwpriv.8 "$TERMUX_PREFIX/share/man/man1/iwpriv.1"
    install -Dm600 doc/iwspy.8 "$TERMUX_PREFIX/share/man/man1/iwspy.1"
    install -Dm600 doc/ifrename.8 "$TERMUX_PREFIX/share/man/man1/ifrename.1"

    # Install documentation
    cp README "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    cp COPYING "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}