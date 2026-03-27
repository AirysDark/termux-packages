#!/usr/bin/env bash
# Auto-generated Termux build.sh for authbind
set -euo pipefail

TERMUX_PKG_NAME="authbind"
TERMUX_PKG_HOMEPAGE="https://packages.debian.org/sid/authbind"
TERMUX_PKG_DESCRIPTION="Allow non-root programs to bind to low-numbered ports"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2.2.0"
TERMUX_PKG_SRCURL="https://deb.debian.org/debian/pool/main/a/authbind/authbind_2.2.0.orig.tar.gz"
TERMUX_PKG_SHA256=""  # Fill in if known
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Building ${TERMUX_PKG_NAME}..."

    # Apply patches
    patch -p1 < libauthbind.c.patch
    patch -p1 < helper.c.patch
    patch -p1 < Makefile.patch

    # Build
    make DESTDIR="$TERMUX_PREFIX" prefix="$TERMUX_PREFIX" all

    # Install
    make DESTDIR="$TERMUX_PREFIX" prefix="$TERMUX_PREFIX" install

    # Ensure standard directories exist
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Optional: Install placeholders
    # Example binary install (replace with actual build artifacts)
    # cp authbind "$TERMUX_PREFIX/bin/"

    # Example man page install
    # install -Dm600 "doc/authbind.1" "$TERMUX_PREFIX/share/man/man1/"

    # Example documentation install
    # cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Install complete for ${TERMUX_PKG_NAME}"
}
