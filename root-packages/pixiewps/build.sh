#!/usr/bin/env bash
# Auto-generated Termux build.sh

TERMUX_PKG_NAME="pixiewps"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v1.4.2"
TERMUX_PKG_SRCURL="https://api.github.com/repos/wiire-a/pixiewps/tarball/v1.4.2"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    # Apply patch to avoid conflict with system tomcrypt
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/avoid-conflict-with-system-tomcrypt.patch"
}

termux_step_post_make_install() {
    echo "Installing binaries and documentation for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Copy the compiled binary
    cp pixiewps "$TERMUX_PREFIX/bin/"

    # Copy man pages if they exist
    [ -f pixiewps.1 ] && install -Dm600 pixiewps.1 "$TERMUX_PREFIX/share/man/man1/"

    # Copy documentation
    [ -f README.md ] && cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Install complete for ${TERMUX_PKG_NAME}"
}