#!/usr/bin/env bash
# Updated Termux build.sh for libaio

TERMUX_PKG_NAME="libaio"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION="Asynchronous I/O library"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.3.113"
TERMUX_PKG_SRCURL="https://pagure.io/libaio/archive/libaio-0.3.113/libaio-0.3.113.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_extract_package() {
    echo "Applying Termux-specific patches..."
    patch -p1 < "${TERMUX_PKG_BUILDER_DIR}/Makefile.patch"
    patch -p1 < "${TERMUX_PKG_BUILDER_DIR}/src-Makefile.patch"
}

termux_step_make() {
    echo "Building libaio..."
    make -C src
}

termux_step_make_install() {
    echo "Installing libaio..."
    # Install shared and static libraries
    mkdir -p "$TERMUX_PREFIX/lib"
    cp src/libaio.so* "$TERMUX_PREFIX/lib/"
    cp src/libaio.a "$TERMUX_PREFIX/lib/"

    # Install headers
    mkdir -p "$TERMUX_PREFIX/include"
    cp src/*.h "$TERMUX_PREFIX/include/"

    # Install documentation (if any)
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"
    cp README "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/" 2>/dev/null || true

    echo "libaio installation complete."
}