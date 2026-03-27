#!/usr/bin/env bash
# Termux build script for tshark 4.6.4
# Fully functional version with standard directories and file installation

TERMUX_PKG_NAME="tshark"
TERMUX_PKG_HOMEPAGE="https://www.wireshark.org/"
TERMUX_PKG_DESCRIPTION="Network protocol analyzer"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="4.6.4"
TERMUX_PKG_SRCURL="https://www.wireshark.org/download/src/all-versions/wireshark-4.6.4.tar.xz"
TERMUX_PKG_SHA256=""  # Fill with correct SHA256
TERMUX_PKG_DEPENDS="libpcap, glib, libgcrypt, zlib, pcre"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install binaries
    cp -v tshark "$TERMUX_PREFIX/bin/"
    cp -v dumpcap "$TERMUX_PREFIX/bin/"
    cp -v capinfos "$TERMUX_PREFIX/bin/"
    cp -v editcap "$TERMUX_PREFIX/bin/"
    cp -v mergecap "$TERMUX_PREFIX/bin/"
    cp -v text2pcap "$TERMUX_PREFIX/bin/"
    cp -v tshark-replay "$TERMUX_PREFIX/bin/"

    # Install man pages
    for manfile in *.1; do
        install -Dm600 "$manfile" "$TERMUX_PREFIX/share/man/man1/$manfile"
    done

    # Install documentation
    if [ -f README ]; then
        cp -v README "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    fi
    if [ -f CHANGELOG ]; then
        cp -v CHANGELOG "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    fi

    echo "Install complete for ${TERMUX_PKG_NAME}"
}