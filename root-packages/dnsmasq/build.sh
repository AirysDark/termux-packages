#!/usr/bin/env bash
# Termux build.sh for dnsmasq
TERMUX_PKG_NAME="dnsmasq"
TERMUX_PKG_HOMEPAGE="https://thekelleys.org.uk/dnsmasq/"
TERMUX_PKG_DESCRIPTION="Lightweight DNS forwarder and DHCP server"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v1.4.0"
TERMUX_PKG_SRCURL="https://gitlab.com/kubitus-project/external-images/dnsmasq/-/archive/v1.4.0/dnsmasq-v1.4.0.zip"
TERMUX_PKG_SHA256=""  # Optional: add if known
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_extract_package() {
    echo "[+] Applying patches..."
    # Apply user patches if any
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/dnsmasq.h.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/Makefile.patch"
}

termux_step_configure() {
    echo "[+] Configuring build..."
    # Modify Makefile for Termux paths if needed
    sed -i "s|^PREFIX .*|PREFIX=${TERMUX_PREFIX}|g" Makefile
    sed -i "s|^BINDIR .*|BINDIR=${TERMUX_PREFIX}/bin|g" Makefile
    sed -i "s|^MANDIR .*|MANDIR=${TERMUX_PREFIX}/share/man|g" Makefile
    sed -i "s|^LIBS .*|LIBS=-llog|g" Makefile
}

termux_step_make() {
    echo "[+] Building..."
    make -j$(nproc)
}

termux_step_make_install() {
    echo "[+] Installing..."
    make DESTDIR="$TERMUX_PREFIX" install
}