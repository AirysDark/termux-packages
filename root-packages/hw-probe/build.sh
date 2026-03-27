#!/usr/bin/env bash
# Auto-generated Termux build.sh

TERMUX_PKG_NAME="hw-probe"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION="Hardware probe utility"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.6.5"
TERMUX_PKG_SRCURL="https://github.com/linuxhw/hw-probe/archive/refs/tags/1.6.5.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS="perl"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install the Perl script
    install -Dm755 "hw-probe.pl" "$TERMUX_PREFIX/bin/hw-probe"

    # If there are any support files (JSON, templates), install them
    if [ -f "hw-probe-missing.json" ]; then
        cp "hw-probe-missing.json" "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    fi

    # Install documentation if README exists
    if [ -f "README.md" ]; then
        cp "README.md" "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    fi

    echo "Install complete for ${TERMUX_PKG_NAME}"
}