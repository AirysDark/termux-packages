#!/usr/bin/env bash
TERMUX_PKG_NAME="btop"
TERMUX_PKG_HOMEPAGE="https://github.com/aristocratos/btop"
TERMUX_PKG_DESCRIPTION="Advanced, cross-platform monitoring tool."
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v1.4.6"
TERMUX_PKG_SRCURL="https://api.github.com/repos/aristocratos/btop/tarball/v1.4.6"
TERMUX_PKG_SHA256="<INSERT_SHA256>"
TERMUX_PKG_DEPENDS="libc++,ncurses"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    # Apply patches
    patch -p1 < "${TERMUX_PKG_BUILDER_DIR}/getloadavg.patch"
    patch -p1 < "${TERMUX_PKG_BUILDER_DIR}/improve-cpu-sensor-guessing.patch"
}

termux_step_make_install() {
    mkdir -p "$TERMUX_PREFIX/bin"
    make -j$(nproc)
    install -Dm755 "btop" "$TERMUX_PREFIX/bin/btop"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"
    cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
}