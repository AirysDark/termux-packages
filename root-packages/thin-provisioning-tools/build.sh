#!/usr/bin/env bash
# Auto-generated Termux build.sh
TERMUX_PKG_NAME="thin-provisioning-tools"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.1.0"
TERMUX_PKG_SRCURL="https://deb.debian.org/debian/pool/main/t/thin-provisioning-tools/thin-provisioning-tools_1.1.0.orig.tar.xz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing directories for ${TERMUX_PKG_NAME}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # --- Custom Install from Makefile.in patch ---
    # The patch changes sbin -> bin and disables static linking
    # Binaries would be installed to $TERMUX_PREFIX/bin
    # Any documentation goes to $TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}
    # Man pages to $TERMUX_PREFIX/share/man/man1

    echo "Install placeholders complete for ${TERMUX_PKG_NAME}"
}