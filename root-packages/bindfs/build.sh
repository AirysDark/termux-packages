#!/usr/bin/env bash
# Updated Termux build.sh for bindfs
TERMUX_PKG_NAME="bindfs"
TERMUX_PKG_VERSION="1.14.0"
TERMUX_PKG_SRCURL="https://bindfs.org/downloads/bindfs-1.18.4.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_DEPENDS="fuse, coreutils"

termux_step_pre_configure() {
    # Prepare the build environment
    autoreconf -fi
}

termux_step_configure() {
    ./configure --prefix="$TERMUX_PREFIX"
}

termux_step_make() {
    make -j$(nproc)
}

termux_step_make_install() {
    make install DESTDIR="$TERMUX_PREFIX"

    # Install binaries explicitly if needed
    if [ -f "$TERMUX_PREFIX/bin/bindfs" ]; then
        chmod +x "$TERMUX_PREFIX/bin/bindfs"
    fi

    # Install man pages
    if [ -d man ]; then
        cp man/* "$TERMUX_PREFIX/share/man/man1/"
    fi

    # Install documentation
    for doc in README* CHANGELOG* LICENSE*; do
        if [ -f "$doc" ]; then
            install -Dm644 "$doc" "$TERMUX_PREFIX/share/doc/$TERMUX_PKG_NAME/$doc"
        fi
    done

    echo "Installation complete for $TERMUX_PKG_NAME"
}