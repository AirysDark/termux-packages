#!/usr/bin/env bash
# Termux build script for runc

TERMUX_PKG_NAME="runc"
TERMUX_PKG_HOMEPAGE="https://github.com/opencontainers/runc"
TERMUX_PKG_DESCRIPTION="CLI tool for spawning and running containers according to the OCI specification"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.1.9"
TERMUX_PKG_SRCURL="https://github.com/opencontainers/runc/archive/refs/tags/v1.1.9.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS="libc"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing runc binaries and helpers..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install main runc binary
    install -Dm755 "runc" "$TERMUX_PREFIX/bin/runc"

    # Install stubs or auxiliary C helpers if applicable
    if [ -f "stubs.c" ]; then
        cp stubs.c "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    fi

    # Install default configuration files
    if [ -f "config.json" ]; then
        mkdir -p "$TERMUX_PREFIX/etc/runc"
        cp config.json "$TERMUX_PREFIX/etc/runc/"
    fi

    # Install documentation
    cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "runc installation complete"
}