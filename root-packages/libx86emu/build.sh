#!/usr/bin/env bash
# Auto-generated Termux build.sh
TERMUX_PKG_NAME="libx86emu"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION="x86 emulator library"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.7.5"
TERMUX_PKG_SRCURL="https://deb.debian.org/debian/pool/main/libx/libx86emu/libx86emu_3.5.orig.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    echo "Applying Termux-specific patches..."
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/mem.c.patch"
    # Add other patches from JSON or extra .patch files if needed
}

termux_step_make_install() {
    echo "Building ${TERMUX_PKG_NAME} in Termux..."
    make CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"
    make install PREFIX="$TERMUX_PREFIX"
}

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install binaries if any (usually library only)
    # Example: cp src/x86emu "$TERMUX_PREFIX/bin/"

    # Install documentation
    cp -v README* "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/" || true

    echo "Install complete for ${TERMUX_PKG_NAME}"
}