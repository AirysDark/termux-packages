#!/usr/bin/env bash
# Auto-generated Termux build.sh

TERMUX_PKG_NAME="hwinfo"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="21.82"
TERMUX_PKG_SRCURL="https://deb.debian.org/debian/pool/main/h/hwinfo/hwinfo_21.82.orig.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_make() {
    # Apply patches automatically if needed
    for patch in "$TERMUX_PKG_SRCDIR"/*.patch; do
        [ -f "$patch" ] && patch -p1 < "$patch"
    done

    # Build with prefix to install into Termux
    make PREFIX="$TERMUX_PREFIX" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"
}

termux_step_make_install() {
    echo "Installing ${TERMUX_PKG_NAME} binaries and docs..."

    # Install main binary
    install -Dm755 hwinfo "$TERMUX_PREFIX/bin/hwinfo"

    # Install hwdata if present
    [ -f hwdata ] && install -Dm644 hwdata "$TERMUX_PREFIX/share/hwdata/hwdata"

    # Install man page
    [ -f hwinfo.1 ] && install -Dm600 hwinfo.1 "$TERMUX_PREFIX/share/man/man1/hwinfo.1"

    # Install documentation
    [ -f README ] && install -Dm644 README "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/README"

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}