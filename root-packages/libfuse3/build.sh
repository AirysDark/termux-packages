#!/usr/bin/env bash
# Termux build.sh for libfuse3

TERMUX_PKG_NAME="libfuse3"
TERMUX_PKG_HOMEPAGE="https://github.com/libfuse/libfuse"
TERMUX_PKG_DESCRIPTION="FUSE (Filesystem in Userspace) library"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="3.9.1"
TERMUX_PKG_SRCURL="https://github.com/libfuse/libfuse/archive/refs/tags/fuse-3.9.1.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing ${TERMUX_PKG_NAME} files..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"
    mkdir -p "$TERMUX_PREFIX/etc"

    # Install binaries
    install -Dm755 "${TERMUX_PKG_SRCDIR}/util/fusermount3" "$TERMUX_PREFIX/bin/fusermount3"

    # Install configuration
    install -Dm644 "${TERMUX_PKG_SRCDIR}/util/fuse.conf" "$TERMUX_PREFIX/etc/fuse.conf"

    # Install man pages
    install -Dm644 "${TERMUX_PKG_SRCDIR}/doc/fusermount.1" "$TERMUX_PREFIX/share/man/man1/fusermount.1"

    # Install documentation
    cp -r "${TERMUX_PKG_SRCDIR}/doc" "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "${TERMUX_PKG_NAME} installation complete."
}