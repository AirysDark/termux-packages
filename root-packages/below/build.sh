#!/usr/bin/env bash
TERMUX_PKG_NAME="avahi"
TERMUX_PKG_VERSION="v0.8"
TERMUX_PKG_SRCURL="https://api.github.com/repos/avahi/avahi/tarball/v0.8"
TERMUX_PKG_SHA256=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_DEPENDS="libc, dbus"

termux_step_pre_configure() {
    # Apply all patches
    for patch in ../*.patch; do
        patch -p1 < "$patch"
    done
}

termux_step_configure() {
    ./configure --prefix="$TERMUX_PREFIX"
}

termux_step_make() {
    make -j$(nproc)
}

termux_step_make_install() {
    make install DESTDIR="$TERMUX_PREFIX"

    # Install service files
    install -Dm644 avahi-daemon-ssh.service "$TERMUX_PREFIX"/share/systemd/system/avahi-daemon-ssh.service
    install -Dm644 avahi-daemon-sftp-ssh.service "$TERMUX_PREFIX"/share/systemd/system/avahi-daemon-sftp-ssh.service
}