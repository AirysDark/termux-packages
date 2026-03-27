#!/usr/bin/env bash
# Termux build script for wpa-supplicant v2.11

TERMUX_PKG_NAME="wpa-supplicant"
TERMUX_PKG_HOMEPAGE="https://w1.fi/wpa_supplicant/"
TERMUX_PKG_DESCRIPTION="A utility providing key negotiation for WPA wireless networks"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2.11"
TERMUX_PKG_SRCURL="https://w1.fi/releases/wpa_supplicant-2.11.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/sbin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"
    mkdir -p "$TERMUX_PREFIX/etc/wpa_supplicant"

    echo "Copying binaries..."
    cp -f wpa_supplicant "$TERMUX_PREFIX/sbin/"
    cp -f wpa_cli "$TERMUX_PREFIX/bin/"
    cp -f wpa_passphrase "$TERMUX_PREFIX/bin/"

    echo "Installing man pages..."
    install -Dm600 doc/wpa_supplicant.8 "$TERMUX_PREFIX/share/man/man1/wpa_supplicant.8"
    install -Dm600 doc/wpa_cli.8 "$TERMUX_PREFIX/share/man/man1/wpa_cli.8"
    install -Dm600 doc/wpa_passphrase.8 "$TERMUX_PREFIX/share/man/man1/wpa_passphrase.8"

    echo "Installing default config..."
    cp -f defconfig "$TERMUX_PREFIX/etc/wpa_supplicant/wpa_supplicant.conf"

    echo "Installing documentation..."
    cp -f README "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    cp -f COPYING "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    cp -f CHANGELOG "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "WPA-Supplicant installation complete for ${TERMUX_PKG_NAME}"
}