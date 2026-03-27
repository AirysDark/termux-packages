#!/usr/bin/env bash
# Termux build.sh for bubblewrap
TERMUX_PKG_NAME="bubblewrap"
TERMUX_PKG_HOMEPAGE="https://github.com/containers/bubblewrap"
TERMUX_PKG_DESCRIPTION="A setuid sandbox tool for unprivileged container creation."
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v0.11.1"
TERMUX_PKG_SRCURL="https://api.github.com/repos/containers/bubblewrap/tarball/v0.11.1"
TERMUX_PKG_SHA256="<INSERT_SHA256>"
TERMUX_PKG_DEPENDS="libc,libcap"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    # Apply any necessary patches before building (if present)
    if [ -d "${TERMUX_PKG_BUILDER_DIR}/patches" ]; then
        for p in "${TERMUX_PKG_BUILDER_DIR}/patches/"*.patch; do
            patch -p1 < "$p"
        done
    fi
}

termux_step_configure() {
    # Autotools / configure build
    if [ -f configure ]; then
        ./configure --prefix="$TERMUX_PREFIX"
    elif [ -f CMakeLists.txt ]; then
        mkdir -p build
        cd build
        cmake .. -DCMAKE_INSTALL_PREFIX="$TERMUX_PREFIX"
    fi
}

termux_step_make_install() {
    # Build and install
    if [ -f Makefile ]; then
        make -j$(nproc)
        make install DESTDIR="$TERMUX_PREFIX"
    elif [ -d build ]; then
        cd build
        make -j$(nproc)
        make install DESTDIR="$TERMUX_PREFIX"
    fi

    # Ensure standard directories exist
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install the binary explicitly (if not handled by make install)
    if [ -f "src/bwrap" ]; then
        install -Dm755 "src/bwrap" "$TERMUX_PREFIX/bin/bwrap"
    fi

    # Install documentation
    if [ -f README.md ]; then
        cp README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"
    fi

    # Install man page (if available)
    if [ -f doc/bwrap.1 ]; then
        install -Dm644 "doc/bwrap.1" "$TERMUX_PREFIX/share/man/man1/bwrap.1"
    fi
}