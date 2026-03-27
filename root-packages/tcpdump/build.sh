#!/usr/bin/env bash
# Auto-generated Termux build.sh

TERMUX_PKG_NAME="tcpdump"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="4.99.5"
TERMUX_PKG_SRCURL="https://www.tcpdump.org/release/tcpdump-4.99.5.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    echo "Patching configure for Termux paths..."
    sed -i \
        -e "s|/usr/local/include|$TERMUX_PREFIX/include|g" \
        -e "s|/usr/local/lib|$TERMUX_PREFIX/lib|g" \
        -e "s|/usr/include|$TERMUX_PREFIX/include|g" \
        ./configure
}

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install binaries
    cp tcpdump "$TERMUX_PREFIX/bin/"

    # Install man pages
    install -Dm600 tcpdump.1 "$TERMUX_PREFIX/share/man/man1/tcpdump.1"

    # Install documentation
    cp README "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Install complete for ${TERMUX_PKG_NAME}"
}