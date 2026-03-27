#!/usr/bin/env bash
# Termux build.sh for libfuse2 (patched)

TERMUX_PKG_NAME="libfuse2"
TERMUX_PKG_HOMEPAGE="https://github.com/libfuse/libfuse"
TERMUX_PKG_DESCRIPTION="Filesystem in Userspace library (patched with atomic cancel and loop_mt support)"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2.9.9"
TERMUX_PKG_SRCURL="https://github.com/libfuse/libfuse/releases/download/fuse-2.9.9/fuse-2.9.9.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS="libc, libpthread"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_configure() {
    ./configure --prefix="$TERMUX_PREFIX" \
                --disable-static \
                --enable-shared
}

termux_step_make() {
    make -j$(nproc)
}

termux_step_make_install() {
    make install
}

termux_step_post_make_install() {
    echo "libfuse2 patched install complete for ${TERMUX_PKG_NAME}"
}