#!/usr/bin/env bash
# Termux build script for v4l-utils

TERMUX_PKG_NAME="v4l-utils"
TERMUX_PKG_HOMEPAGE="https://www.linuxtv.org/"
TERMUX_PKG_DESCRIPTION="Video4Linux utilities and libraries"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.22.0"
TERMUX_PKG_SRCURL="https://www.linuxtv.org/downloads/v4l-utils/v4l-utils-1.22.0.tar.bz2"
TERMUX_PKG_SHA256=""  # Fill in the correct hash
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_configure() {
    ./configure --prefix="$TERMUX_PREFIX" \
                --disable-static \
                --disable-udev \
                --disable-android
}

termux_step_make() {
    make -j$(nproc)
}

termux_step_make_install() {
    make install

    # Install extra binaries manually if needed
    for bin in v4l2-ctl v4l2-compliance v4l2-dbg v4l2-info v4l2-sysfs-path v4l2-test;
    do
        if [ -f "$TERMUX_PKG_SRCDIR/$bin" ]; then
            install -Dm755 "$TERMUX_PKG_SRCDIR/$bin" "$TERMUX_PREFIX/bin/$bin"
        fi
    done

    # Install man pages
    for man in v4l2-ctl.1 v4l2-compliance.1 v4l2-dbg.1 v4l2-info.1 v4l2-sysfs-path.1 v4l2-test.1;
    do
        if [ -f "$TERMUX_PKG_SRCDIR/doc/$man" ]; then
            install -Dm644 "$TERMUX_PKG_SRCDIR/doc/$man" "$TERMUX_PREFIX/share/man/man1/$man"
        fi
    done

    # Install documentation
    cp -r "$TERMUX_PKG_SRCDIR"/docs "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
}