#!/usr/bin/env bash
# Auto-generated Termux build.sh for encfs

TERMUX_PKG_NAME="encfs"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION="Encrypted filesystem in user-space"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v0.7.17"
TERMUX_PKG_SRCURL="https://api.github.com/repos/neurodroid/cryptonite/tarball/v0.7.17"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_extract_package() {
    echo "[+] Applying fixes for Clang build..."

    # Apply the NullCipher patch
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/unbreak-clang-build.patch"
}

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install binaries
    cp -a encfs "$TERMUX_PREFIX/bin/"

    # Install man pages if they exist
    if [ -f encfs.1 ]; then
        install -Dm600 encfs.1 "$TERMUX_PREFIX/share/man/man1/encfs.1"
    fi

    # Install documentation
    if [ -f README.md ]; then
        cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    fi

    echo "[+] Installation complete for ${TERMUX_PKG_NAME}"
}