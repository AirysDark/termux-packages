#!/usr/bin/env bash
# Termux-ready fio build.sh

TERMUX_PKG_NAME="fio"
TERMUX_PKG_HOMEPAGE="https://github.com/axboe/fio"
TERMUX_PKG_DESCRIPTION="Flexible I/O Tester"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="fio-3.41"
TERMUX_PKG_SRCURL="https://api.github.com/repos/axboe/fio/tarball/fio-3.41"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"
    mkdir -p "$TERMUX_PREFIX/tmp"
    mkdir -p "$TERMUX_PREFIX/lib/fio"
    mkdir -p "$TERMUX_PREFIX/share/fio"

    # Install binaries
    cp fio "$TERMUX_PREFIX/bin/"

    # Install man page
    install -Dm600 fio.1 "$TERMUX_PREFIX/share/man/man1/fio.1"

    # Install additional tools
    cp tools/genfio tools/plot/fio2gnuplot "$TERMUX_PREFIX/bin/"

    # Copy shared fio files
    cp -r engines "$TERMUX_PREFIX/lib/fio/"
    cp -r gpm "$TERMUX_PREFIX/share/fio/"

    echo "Installation complete for ${TERMUX_PKG_NAME}"

    # Patch paths inside installed scripts if needed
    sed -i "s|/tmp|$TERMUX_PREFIX/tmp|g" "$TERMUX_PREFIX/bin/genfio"
    sed -i "s|/usr/share/fio|$TERMUX_PREFIX/share/fio|g" "$TERMUX_PREFIX/bin/fio2gnuplot"
}

# Set version macro for CFLAGS
export CFLAGS="-DFIO_VERSION=\"${TERMUX_PKG_VERSION}\" $CFLAGS"