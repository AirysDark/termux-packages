#!/usr/bin/env bash
# Termux build.sh for mtr with applied patches

TERMUX_PKG_NAME="mtr"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION="Network diagnostic tool"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.96"
TERMUX_PKG_SRCURL="https://www.bitwizard.nl/mtr/files/mtr-0.96.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/include"
    mkdir -p "$TERMUX_PREFIX/lib"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Apply patches
    patch -p1 < "$TERMUX_PKG_SRCDIR/packet.c.patch"
    patch -p1 < "$TERMUX_PKG_SRCDIR/index_to_strchr.patch"
    patch -p1 < "$TERMUX_PKG_SRCDIR/hsearch.patch"
    patch -p1 < "$TERMUX_PKG_SRCDIR/hcreate.c"
    patch -p1 < "$TERMUX_PKG_SRCDIR/hcreate_r.c"
    patch -p1 < "$TERMUX_PKG_SRCDIR/hdestroy_r.c"
    patch -p1 < "$TERMUX_PKG_SRCDIR/hsearch_r.c"
    patch -p1 < "$TERMUX_PKG_SRCDIR/search.h"

    # Install binaries
    install -Dm755 "$TERMUX_PKG_SRCDIR/mtr" "$TERMUX_PREFIX/bin/mtr"

    # Install headers (if needed)
    install -Dm644 "$TERMUX_PKG_SRCDIR/hsearch.h" "$TERMUX_PREFIX/include/hsearch.h"

    # Install man pages
    install -Dm644 "$TERMUX_PKG_SRCDIR/doc/mtr.1" "$TERMUX_PREFIX/share/man/man1/mtr.1"

    # Install README/documentation
    cp "$TERMUX_PKG_SRCDIR/README.md" "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}