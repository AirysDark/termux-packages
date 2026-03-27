#!/usr/bin/env bash
TERMUX_PKG_NAME="lxc"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v6.0.6"
TERMUX_PKG_SRCURL="https://api.github.com/repos/lxc/lxc/tarball/v6.0.6"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Applying patches..."
    patch -p1 < src-include-lxcmntent.c.patch
    patch -p1 < src-lxc-cgroups-cgfsng.c.patch
    patch -p1 < src-lxc-conf.c.patch
    patch -p1 < src-lxc-pam-pam_cgfs.c.patch
    patch -p1 < templates-lxc-download.in.patch
    patch -p1 < templates-lxc-local.in.patch
    patch -p1 < templates-lxc-oci.patch

    echo "Installing directories..."
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"
    mkdir -p "$TERMUX_PREFIX/share/lxc/templates"
    mkdir -p "$TERMUX_PREFIX/libexec/lxc"

    echo "Installing templates..."
    cp templates/* "$TERMUX_PREFIX/share/lxc/templates/"
    sed -i "s|/tmp|$TERMUX_PREFIX/tmp|" "$TERMUX_PREFIX/share/lxc/templates/lxc-oci.in"

    echo "Installing helper scripts..."
    cp lxc-setup-cgroups.sh "$TERMUX_PREFIX/libexec/lxc/"
    chmod +x "$TERMUX_PREFIX/libexec/lxc/lxc-setup-cgroups.sh"

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}