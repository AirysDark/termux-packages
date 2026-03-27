#!/usr/bin/env bash
# Termux build script for vlan
TERMUX_PKG_NAME="vlan"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.0.1"
TERMUX_PKG_SRCURL="https://archive.debian.org/debian/pool/main/v/vlan/vlan_2.0.5.tar.xz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install binaries
    cp vconfig "$TERMUX_PREFIX/bin/"

    # Install documentation
    cp README "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    # Install if-pre-up script for VLANs with patched TERMUX path
    mkdir -p "$TERMUX_PREFIX/etc/network/if-pre-up.d"
    install -Dm700 debian/network/if-pre-up.d/vlan "$TERMUX_PREFIX/etc/network/if-pre-up.d/vlan"

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}