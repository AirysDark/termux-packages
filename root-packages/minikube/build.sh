#!/usr/bin/env bash
# Auto-generated Termux build.sh for Minikube
TERMUX_PKG_NAME="minikube"
TERMUX_PKG_HOMEPAGE="https://minikube.sigs.k8s.io/"
TERMUX_PKG_DESCRIPTION="Run Kubernetes locally"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.29.0"
TERMUX_PKG_SRCURL="https://github.com/kubernetes/minikube/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS="golang, docker"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    echo "Applying Termux-specific patches..."
    patch -p1 < "${TERMUX_PKG_BUILDER_DIR}/disable-libvirt.patch"
}

termux_step_make() {
    echo "Building minikube..."
    export GO111MODULE=on
    export CGO_ENABLED=0
    export GOOS=linux
    export GOARCH=$(dpkg --print-architecture | sed 's/amd64/x86_64/')
    go build -ldflags="-s -w" -o minikube ./cmd/minikube
}

termux_step_make_install() {
    echo "Installing minikube binary and docs..."
    install -Dm755 minikube "$TERMUX_PREFIX/bin/minikube"
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"
    cp -r docs/* "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/" 2>/dev/null || true
}