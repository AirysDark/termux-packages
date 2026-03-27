#!/usr/bin/env bash
# Termux build script for mtr

TERMUX_PKG_NAME="mtr"
TERMUX_PKG_HOMEPAGE="https://www.bitwizard.nl/mtr/"
TERMUX_PKG_DESCRIPTION="Network diagnostic tool to combine ping and traceroute"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.96"
TERMUX_PKG_SRCURL="https://www.bitwizard.nl/mtr/files/mtr-0.96.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS="libc, libpcap"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    # Apply all patches before building
    for patch in "$TERMUX_PKG_BUILDER_DIR"/*.patch; do
        echo "Applying patch $patch..."
        patch -p1 < "$patch"
    done
}

termux_step_make() {
    echo "Compiling ${TERMUX_PKG_NAME}..."
    # Standard configure/make flow
    ./configure --prefix="$TERMUX_PREFIX" \
                --mandir="$TERMUX_PREFIX/share/man" \
                --with-ssl \
                --with-libpcap
    make -j$(nproc)
}

termux_step_make_install() {
    echo "Installing ${TERMUX_PKG_NAME}..."
    make install DESTDIR="$TERMUX_PREFIX"

    # Ensure proper directories exist
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Copy README
    if [ -f README ]; then
        cp README "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    fi
}