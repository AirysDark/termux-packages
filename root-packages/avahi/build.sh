#!/usr/bin/env bash
# Auto-generated Termux build.sh for avahi

TERMUX_PKG_NAME="avahi"
TERMUX_PKG_HOMEPAGE="https://www.avahi.org/"
TERMUX_PKG_DESCRIPTION="Avahi mDNS/DNS-SD daemon and library"
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.8"
TERMUX_PKG_SRCURL="https://api.github.com/repos/avahi/avahi/tarball/v0.8"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS="libc, dbus, glib, dbus-glib"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    echo "[*] Preparing build environment..."
    # Autotools preparation if configure script missing
    if [ ! -f configure ]; then
        echo "[*] Running autoreconf..."
        autoreconf -fi
    fi
}

termux_step_configure() {
    echo "[*] Configuring package..."
    ./configure \
        --prefix="$TERMUX_PREFIX" \
        --disable-systemd \
        --disable-mono \
        --disable-gtk3 \
        --disable-qt4 \
        --disable-qt5 \
        --disable-qt6 \
        --disable-avahi-doxygen
}

termux_step_make() {
    echo "[*] Compiling package..."
    make -j$(nproc)
}

termux_step_make_install() {
    echo "[*] Installing binaries..."
    make install DESTDIR="$TERMUX_PREFIX"

    # Install configuration files
    mkdir -p "$TERMUX_PREFIX/etc/avahi"
    cp avahi-daemon.conf "$TERMUX_PREFIX/etc/avahi/"

    # Install systemd unit files
    mkdir -p "$TERMUX_PREFIX/lib/systemd/system"
    cp avahi-daemon-ssh.service "$TERMUX_PREFIX/lib/systemd/system/"
    cp avahi-daemon-sftp-ssh.service "$TERMUX_PREFIX/lib/systemd/system/"

    # Install libraries for compatibility subpackage
    mkdir -p "$TERMUX_PREFIX/lib"
    cp libdns-sd.so "$TERMUX_PREFIX/lib/"
    cp -r include/avahi-compat-libdns_sd "$TERMUX_PREFIX/include/"

    # Install man pages if present
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    # cp doc/*.1 "$TERMUX_PREFIX/share/man/man1/"

    echo "[*] Installation complete for ${TERMUX_PKG_NAME}"
}