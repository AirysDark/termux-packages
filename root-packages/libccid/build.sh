#!/usr/bin/env bash
# Updated Termux build.sh for libccid

TERMUX_PKG_NAME="libccid"
TERMUX_PKG_HOMEPAGE="https://ccid.apdu.fr/"
TERMUX_PKG_DESCRIPTION="CCID (USB Smart Card) driver library"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.6.2"
TERMUX_PKG_SRCURL="https://ccid.apdu.fr/files/ccid-1.6.2.tar.xz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    echo "Applying patches for ${TERMUX_PKG_NAME}..."
    patch -p1 < "${TERMUX_PKG_BUILDER_DIR}/issetugid.patch"
}

termux_step_post_make_install() {
    echo "Installing binaries and documentation for ${TERMUX_PKG_NAME}..."

    # Install binaries
    cp ccid-sys-*.so "$TERMUX_PREFIX/lib/"

    # Install helper programs
    install -Dm755 pcscd "$TERMUX_PREFIX/bin/"

    # Install man pages if available
    [ -f ccid.1 ] && install -Dm600 ccid.1 "$TERMUX_PREFIX/share/man/man1/"

    # Install documentation
    [ -f README ] && cp README "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}