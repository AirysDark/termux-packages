#!/usr/bin/env bash
# Termux build.sh for containerd

TERMUX_PKG_NAME="containerd"
TERMUX_PKG_HOMEPAGE="https://containerd.io"
TERMUX_PKG_DESCRIPTION="An industry-standard container runtime"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.0"
TERMUX_PKG_SRCURL="https://api.github.com/repos/tiglabs/containerdns/tarball/v1.0"
TERMUX_PKG_SHA256=""  # Fill in if available
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    echo "[*] Applying Termux-specific patches..."
    # Apply all the relevant patches you uploaded
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/fix-paths.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/Makefile.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/too_long_path.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/defaults_unix.go.patch"
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/bundle.go.patch"
    # Add any other .patch files from the uploads
}

termux_step_configure() {
    echo "[*] Configuring containerd build for Termux..."
    # Ensure Go is used correctly and point GOPATH appropriately
    export CGO_ENABLED=1
    export GOOS=linux
    export GOARCH=$(dpkg --print-architecture)
    export GOBIN=$TERMUX_PREFIX/bin
    export GOPATH=$PWD/go
}

termux_step_make() {
    echo "[*] Building containerd..."
    mkdir -p "$GOPATH"
    go mod vendor
    go build -o "$TERMUX_PREFIX/bin/containerd" ./cmd/containerd
    go build -o "$TERMUX_PREFIX/bin/containerd-shim" ./cmd/containerd-shim
    go build -o "$TERMUX_PREFIX/bin/containerd-shim-runc-v1" ./cmd/containerd-shim-runc-v1
    go build -o "$TERMUX_PREFIX/bin/containerd-shim-runc-v2" ./cmd/containerd-shim-runc-v2
}

termux_step_make_install() {
    echo "[*] Installing containerd binaries..."
    install -Dm755 "$TERMUX_PREFIX/bin/containerd" "$TERMUX_PREFIX/bin/containerd"
    install -Dm755 "$TERMUX_PREFIX/bin/containerd-shim" "$TERMUX_PREFIX/bin/containerd-shim"
    install -Dm755 "$TERMUX_PREFIX/bin/containerd-shim-runc-v1" "$TERMUX_PREFIX/bin/containerd-shim-runc-v1"
    install -Dm755 "$TERMUX_PREFIX/bin/containerd-shim-runc-v2" "$TERMUX_PREFIX/bin/containerd-shim-runc-v2"

    # Copy configuration files
    mkdir -p "$TERMUX_PREFIX/etc/containerd"
    cp "$TERMUX_PKG_SRCDIR/config.toml" "$TERMUX_PREFIX/etc/containerd/config.toml"
}

termux_step_post_make_install() {
    echo "[*] Creating Termux containerd runtime directories..."
    mkdir -p "$TERMUX_PREFIX/var/lib/containerd"
    mkdir -p "$TERMUX_PREFIX/var/run/containerd"
    mkdir -p "$TERMUX_PREFIX/var/run/containerd/fifo"
}