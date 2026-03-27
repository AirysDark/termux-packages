#!/usr/bin/env bash
# Auto-generated Termux build.sh
TERMUX_PKG_NAME="gocryptfs"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="v2.6.1"
TERMUX_PKG_SRCURL="https://api.github.com/repos/rfjakob/gocryptfs/tarball/v2.6.1"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS="golang"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    # Ensure Go modules work correctly
    export GOPATH="$TERMUX_PREFIX/opt/gopath"
    mkdir -p "$GOPATH"
}

termux_step_make() {
    echo "Building ${TERMUX_PKG_NAME}..."
    # Build Go binaries
    go build -o gocryptfs ./cmd/gocryptfs
    go build -o gocryptfs-xray ./cmd/gocryptfs-xray
}

termux_step_post_make_install() {
    echo "Installing ${TERMUX_PKG_NAME} binaries..."

    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"

    # Install the built binaries
    install -Dm755 gocryptfs "$TERMUX_PREFIX/bin/gocryptfs"
    install -Dm755 gocryptfs-xray "$TERMUX_PREFIX/bin/gocryptfs-xray"

    # Optional: install documentation if it exists
    if [ -f "README.md" ]; then
        install -Dm644 README.md "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/README.md"
    fi

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}