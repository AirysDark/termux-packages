#!/usr/bin/env bash
# Termux build script for wush

TERMUX_PKG_NAME="wush"
TERMUX_PKG_HOMEPAGE="https://github.com/coder/wush"
TERMUX_PKG_DESCRIPTION="A simple wireless shell utility"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.4.1"
TERMUX_PKG_SRCURL="https://github.com/coder/wush/archive/refs/tags/v0.4.1.tar.gz"
TERMUX_PKG_SHA256=""  # Fill in if known
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Create standard Termux directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Copy the compiled binary
    if [ -f "wush" ]; then
        cp wush "$TERMUX_PREFIX/bin/"
        chmod 755 "$TERMUX_PREFIX/bin/wush"
        echo "Installed binary to $TERMUX_PREFIX/bin/wush"
    else
        echo "Warning: wush binary not found in source directory!"
    fi

    # Install man page if exists
    if [ -f "doc/wush.1" ]; then
        install -Dm600 "doc/wush.1" "$TERMUX_PREFIX/share/man/man1/wush.1"
        echo "Installed man page to $TERMUX_PREFIX/share/man/man1/wush.1"
    fi

    # Install README / documentation if exists
    for doc in README.md README; do
        if [ -f "$doc" ]; then
            cp "$doc" "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
            echo "Installed documentation: $doc"
        fi
    done

    echo "Installation of ${TERMUX_PKG_NAME} complete."
}