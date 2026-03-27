#!/usr/bin/env bash
TERMUX_PKG_NAME="ntfs-3g"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2022.10.3"
TERMUX_PKG_SRCURL="https://api.github.com/repos/tuxera/ntfs-3g/tarball/2022.10.3"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    # Apply Termux-specific patches
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/remove-ldconfig.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/fix-symlink.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/fix-hardcoded-path.patch"
}

termux_step_post_make_install() {
    echo "Installing ${TERMUX_PKG_NAME} binaries, man pages, and docs..."
    
    # Binaries
    cp ntfsprogs/mkntfs "$TERMUX_PREFIX/bin/"
    cp ntfsprogs/ntfsmftalloc "$TERMUX_PREFIX/bin/"
    cp ntfsprogs/ntfsresize "$TERMUX_PREFIX/bin/"
    cp ntfsprogs/ntfstruncate "$TERMUX_PREFIX/bin/"
    cp ntfsprogs/ntfsfallocate "$TERMUX_PREFIX/bin/"
    cp ntfsprogs/ntfscmp "$TERMUX_PREFIX/bin/"

    # Man pages
    install -Dm600 doc/*.1 "$TERMUX_PREFIX/share/man/man1/"

    # Documentation
    cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}