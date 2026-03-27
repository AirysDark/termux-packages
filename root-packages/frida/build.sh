#!/usr/bin/env bash
# Termux build.sh for Frida v17.8.3

TERMUX_PKG_NAME="frida"
TERMUX_PKG_HOMEPAGE="https://www.frida.re"
TERMUX_PKG_DESCRIPTION="Dynamic instrumentation toolkit for developers, reverse-engineers, and security researchers"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="17.8.3"
TERMUX_PKG_SRCURL="https://github.com/frida/frida/archive/refs/tags/17.8.3.tar.gz"
TERMUX_PKG_SHA256=""  # Fill in with verified sha256
TERMUX_PKG_DEPENDS="python, libffi, glib"
TERMUX_PKG_BUILD_IN_SRC=true

# Apply subpackage scripts and patches
FRIDA_SUBPACKAGES=("frida-dev" "frida-python")
PATCHES=(
  "frida-resource-compiler.patch"
  "glib-no-pidfd_open-syscall.diff"
  "ndk-version-and-api-level.diff"
  "no-pidfd_open-syscall.patch"
  "quickcompile.patch"
  "skip-elf-cleaner.patch"
  "version-script.patch"
)

termux_step_pre_configure() {
    echo "Applying patches for ${TERMUX_PKG_NAME}..."
    for p in "${PATCHES[@]}"; do
        patch -p1 < "${TERMUX_PKG_BUILDER_DIR}/$p"
    done
}

termux_step_make() {
    echo "Building ${TERMUX_PKG_NAME}..."
    python3 setup.py build --force
}

termux_step_make_install() {
    echo "Installing ${TERMUX_PKG_NAME}..."

    # Install core binaries
    python3 setup.py install --prefix="$TERMUX_PREFIX" --force

    # Install subpackages
    for sub in "${FRIDA_SUBPACKAGES[@]}"; do
        bash "${TERMUX_PKG_BUILDER_DIR}/${sub}.subpackage.sh"
    done
}

termux_step_post_make_install() {
    echo "Finalizing installation of ${TERMUX_PKG_NAME}..."

    # Ensure bin and doc directories exist
    mkdir -p "$TERMUX_PREFIX/bin" \
             "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}" \
             "$TERMUX_PREFIX/share/man/man1"

    echo "${TERMUX_PKG_NAME} build and installation complete."
}