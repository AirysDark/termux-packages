#!/usr/bin/env bash
# Auto-generated Termux build.sh for iptables

TERMUX_PKG_NAME="iptables"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION="iptables with netflow support"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v2.5.1"
TERMUX_PKG_SRCURL="https://api.github.com/repos/aabc/ipt-netflow/tarball/v2.5.1"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    echo "Applying patches..."
    patch -p1 < extensions-libxt_cgroup.c.patch
    patch -p1 < include-xtables.h.patch
    patch -p1 < iptables-xtables-monitor.c.patch
    patch -p1 < iptables-Makefile.in.patch
    patch -p1 < libxtables-Makefile.in.patch
}

termux_step_configure() {
    echo "Configuring package..."
    ./configure --prefix="$TERMUX_PREFIX" \
                --disable-nftables \
                --disable-xtables-locking \
                CC="$CC" \
                CFLAGS="$CFLAGS" \
                LDFLAGS="$LDFLAGS"
}

termux_step_make() {
    echo "Building package..."
    make -j$(nproc)
}

termux_step_make_install() {
    echo "Installing binaries..."
    make DESTDIR="$TERMUX_PREFIX" install
}

termux_step_post_make_install() {
    echo "Installing documentation..."
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"
    cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    echo "Install complete for ${TERMUX_PKG_NAME}"
}