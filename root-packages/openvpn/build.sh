#!/usr/bin/env bash
# Termux build.sh for OpenVPN with applied patches

TERMUX_PKG_NAME="openvpn"
TERMUX_PKG_HOMEPAGE="https://openvpn.net"
TERMUX_PKG_DESCRIPTION="OpenVPN is a robust and highly flexible VPN daemon"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v2.7.0"
TERMUX_PKG_SRCURL="https://api.github.com/repos/OpenVPN/openvpn/tarball/v2.7.0"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS="openssl, lzo, lz4, zlib, libpkcs11-helper"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    echo "Applying patches for OpenVPN..."
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/src-openvpn-tun.c.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/src-openvpn-options.c.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/src-openvpn-console_builtin.c.patch"
}

termux_step_post_make_install() {
    echo "Installing OpenVPN binaries and documentation..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/sbin"
    mkdir -p "$TERMUX_PREFIX/share/man/man8"
    mkdir -p "$TERMUX_PREFIX/share/doc/$TERMUX_PKG_NAME"

    # Install binaries
    install -Dm755 "src/openvpn" "$TERMUX_PREFIX/sbin/openvpn"
    install -Dm755 "src/openvpn" "$TERMUX_PREFIX/bin/openvpn"  # optional symlink for convenience

    # Install man pages
    install -Dm644 "doc/openvpn.8" "$TERMUX_PREFIX/share/man/man8/openvpn.8"

    # Install documentation
    cp -R doc/* "$TERMUX_PREFIX/share/doc/$TERMUX_PKG_NAME/"

    echo "OpenVPN installation complete."
}