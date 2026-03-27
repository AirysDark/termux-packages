#!/usr/bin/env bash
# Termux build.sh for hping3

TERMUX_PKG_NAME="hping3"
TERMUX_PKG_HOMEPAGE="https://www.hping.org/"
TERMUX_PKG_DESCRIPTION="Network tool to send custom TCP/IP packets"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="3.0.0"
TERMUX_PKG_SRCURL="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/hping3/3.a2.ds2-10.1/hping3_3.a2.ds2.orig.tar.gz"
TERMUX_PKG_SHA256=""  # Fill in the verified SHA256
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    # Apply patches in the folder
    for p in *.patch; do
        echo "Applying patch $p..."
        patch -p1 < "$p"
    done
}

termux_step_make_install() {
    echo "Building hping3..."
    make
}

termux_step_post_make_install() {
    echo "Installing hping3..."

    # Install binaries
    install -Dm755 hping3 "$TERMUX_PREFIX/bin/hping3"
    ln -sf "$TERMUX_PREFIX/bin/hping3" "$TERMUX_PREFIX/bin/hping"
    ln -sf "$TERMUX_PREFIX/bin/hping3" "$TERMUX_PREFIX/bin/hping2"

    # Install man pages
    install -Dm644 ./docs/hping3.8 "$TERMUX_PREFIX/share/man/man8/hping3.8"

    echo "Installation complete for hping3"
}