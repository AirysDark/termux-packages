#!/usr/bin/env bash
# Auto-generated Termux build.sh

TERMUX_PKG_NAME="iptables"
TERMUX_PKG_HOMEPAGE="https://netfilter.org/projects/iptables/index.html"
TERMUX_PKG_DESCRIPTION="iptables user-space tools for packet filtering"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v2.5.1"
TERMUX_PKG_SRCURL="https://api.github.com/repos/aabc/ipt-netflow/tarball/v2.5.1"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS="libnetfilter-queue"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing iptables binaries..."
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man8"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install binaries (from Makefile)
    cp src/iptables "$TERMUX_PREFIX/bin/"
    cp src/ip6tables "$TERMUX_PREFIX/bin/"
    cp src/xtables-multi "$TERMUX_PREFIX/bin/"

    # Install man pages
    install -Dm600 doc/iptables.8 "$TERMUX_PREFIX/share/man/man8/iptables.8"
    install -Dm600 doc/ip6tables.8 "$TERMUX_PREFIX/share/man/man8/ip6tables.8"

    # Install documentation
    cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
}