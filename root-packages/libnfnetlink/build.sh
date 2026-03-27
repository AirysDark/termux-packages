#!/usr/bin/env bash
# Termux build.sh for libnfnetlink

TERMUX_PKG_NAME="libnfnetlink"
TERMUX_PKG_HOMEPAGE="https://netfilter.org/projects/libnfnetlink/"
TERMUX_PKG_DESCRIPTION="Library providing a userspace API to Netlink sockets for netfilter"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.0.1"
TERMUX_PKG_SRCURL="https://netfilter.org/projects/libnfnetlink/files/libnfnetlink-1.0.1.tar.bz2"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing libnfnetlink for ${TERMUX_PKG_NAME}..."

    # Create directories
    mkdir -p "$TERMUX_PREFIX/lib"
    mkdir -p "$TERMUX_PREFIX/include/libnfnetlink"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"
    mkdir -p "$TERMUX_PREFIX/share/man/man3"

    # Install headers
    cp -v include/libnfnetlink/*.h "$TERMUX_PREFIX/include/libnfnetlink/"

    # Install library
    cp -v libnfnetlink.so* "$TERMUX_PREFIX/lib/"

    # Install man pages if present
    if [ -d "man" ]; then
        cp -v man/*.3 "$TERMUX_PREFIX/share/man/man3/"
    fi

    # Install documentation
    if [ -f "README" ]; then
        cp -v README "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    fi

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}