#!/usr/bin/env bash
# Termux build.sh for iodine

TERMUX_PKG_NAME="iodine"
TERMUX_PKG_HOMEPAGE="https://github.com/yarrick/iodine"
TERMUX_PKG_DESCRIPTION="A DNS tunneling tool"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.7.0"
TERMUX_PKG_SRCURL="https://github.com/yarrick/iodine/archive/refs/tags/v0.7.0.tar.gz"
TERMUX_PKG_SHA256=""  # Add SHA256 checksum if available
TERMUX_PKG_DEPENDS="libpcap"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    echo "Applying Termux patches..."
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/000-fix-name-clashes.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/002-fix-ifconfig-path.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/003-no-systemd-selinux.patch"
}

termux_step_make_install() {
    echo "Building iodine..."
    ./configure --prefix="$TERMUX_PREFIX"
    make
    make install
}

termux_step_post_make_install() {
    echo "Install complete for ${TERMUX_PKG_NAME}"
    # Man pages and docs are already installed via make install
}