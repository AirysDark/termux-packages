#!/usr/bin/env bash
# Termux build.sh for Docker v24.0.2

TERMUX_PKG_NAME="docker"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION="Docker static binaries and daemon patched for Termux"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="24.0.2"
TERMUX_PKG_SRCURL="https://download.docker.com/linux/static/stable/x86_64/docker-24.0.2.tgz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    echo "Installing Docker binaries and configuration for Termux..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/etc/docker"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install binaries
    cp dockerd "$TERMUX_PREFIX/bin/"
    cp docker "$TERMUX_PREFIX/bin/"
    cp docker-containerd "$TERMUX_PREFIX/bin/"
    cp docker-init "$TERMUX_PREFIX/bin/"
    cp docker-proxy "$TERMUX_PREFIX/bin/"
    cp docker-runc "$TERMUX_PREFIX/bin/"

    # Install helper scripts
    install -Dm755 dockerd.sh "$TERMUX_PREFIX/bin/dockerd.sh"

    # Install configuration files
    install -Dm644 daemon.json "$TERMUX_PREFIX/etc/docker/daemon.json"

    # Apply patched Go source files if any
    # Note: This assumes patching has been applied during src extraction
    # config.go, database.go, manager.go, defaults_unix.go, etc.
    # These should already be compiled into the binaries

    echo "Docker installation complete for Termux."
}