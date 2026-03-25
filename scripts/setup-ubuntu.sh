#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Ubuntu host setup for Termux package building (Linux-only, Jammy + LLVM 16)
# =============================================================================

# Use sudo only if not root
SUDO="sudo"
if [ "$(id -u)" = "0" ]; then
    SUDO=""
fi

# Source Termux build properties
. "$(dirname "$(realpath "$0")")/properties.sh"

# =============================================================================
# Set defaults for variables that may not be set in CI
# =============================================================================
: "${TERMUX_HOST_LLVM_MAJOR_VERSION:=16}"
: "${TERMUX_HOST_GCC_VERSION:=13}"
: "${TERMUX_PKG_TMPDIR:=/tmp}"

# =============================================================================
# Generate locale early to avoid tex-common / fmtutil errors
# =============================================================================
$SUDO apt-get update
$SUDO apt-get install -y locales
$SUDO locale-gen en_US.UTF-8
$SUDO update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# =============================================================================
# Core package list
# =============================================================================
PACKAGES=""

# Locale
PACKAGES+=" locales"

# Python support
PACKAGES+=" python-is-python3 python3-pip python3-setuptools python-wheel-common python3-venv"

# Build essentials and general tools
PACKAGES+=" curl gnupg git lzip tar unzip lrzip lzop lz4 zstd fuse-overlayfs"
PACKAGES+=" autoconf autogen automake autopoint bison flex g++ g++-multilib gawk gettext gperf intltool libglib2.0-dev libltdl-dev libtool-bin m4 pkg-config scons"

# Documentation tools
PACKAGES+=" asciidoc asciidoctor go-md2man groff help2man pandoc python3-docutils python3-recommonmark python3-myst-parser python3-sphinx python3-sphinx-rtd-theme python3-sphinxcontrib.qthelp scdoc texinfo txt2man xmlto xmltoman"

# Miscellaneous
PACKAGES+=" ed recutils bsdmainutils valac fig2dev gegl gengetopt libdbus-1-dev libelf-dev libexpat1-dev libjpeg-dev librsvg2-dev libsqlite3-dev lua5.2 lua5.3 lua5.4 libncurses5-dev lua-lpeg lua-mpack libyaml-dev ruby libc-ares-dev libc-ares-dev:i386 libicu-dev libsqlite3-dev:i386 re2c php php-xml composer libssl-dev zip tcl openssl zlib1g-dev lld luajit bc libarchive-tools nasm po4a rsync wget libgtk-3-dev comerr-dev docbook-to-man docbook-utils erlang-nox heimdal-multidev libconfig-dev libevent-dev libgc-dev libgmp-dev libjansson-dev libparse-yapp-perl libreadline-dev libunistring-dev alex docbook-xsl-ns gnome-common gobject-introspection gtk-3-examples gtk-doc-tools happy itstool libdbus-glib-1-dev-bin libgdk-pixbuf2.0-dev python3-html5lib python3-xcbgen sassc texlive-extra-utils unifdef xfce4-dev-tools xfonts-utils xutils-dev desktop-file-utils protobuf-c-compiler sqlite3 cvs python3-yaml bash-static triehash aspell guile-3.0-dev python3-jsonschema fontforge-nox guile-3.0 python3-fontforge texlive-metapost libfl-dev libxft-dev libxt-dev xbitmaps xxd libjson-perl jq libcurl4-openssl-dev openjdk-17-jre openjdk-17-jdk openjdk-21-jre openjdk-21-jdk libnss3 libnss3:i386 libnss3-dev libwebp7 libwebp7:i386 libwebp-dev libwebpdemux2 libwebpdemux2:i386 libwebpmux3 libwebpmux3:i386 libfontconfig1 libfontconfig1:i386 libcups2-dev libexpat1:i386 libxkbfile-dev libsecret-1-dev libkrb5-dev libfreetype-dev:i386 libdebuginfod-dev patchelf swig libzstd-dev glslang-tools"

# =============================================================================
# Enable multiarch and update apt
# =============================================================================
$SUDO dpkg --add-architecture i386
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get update
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends jq gnupg curl locales

# =============================================================================
# Add LLVM repository (Jammy + LLVM 16)
# =============================================================================
LLVM_KEY="$(dirname "$(realpath "$0")")/llvm-snapshot.gpg.key"
$SUDO cp "$LLVM_KEY" /etc/apt/trusted.gpg.d/apt.llvm.org.asc
$SUDO chmod a+r /etc/apt/trusted.gpg.d/apt.llvm.org.asc
echo "deb [arch=amd64] http://apt.llvm.org/jammy/ llvm-toolchain-jammy-${TERMUX_HOST_LLVM_MAJOR_VERSION} main" | $SUDO tee /etc/apt/sources.list.d/apt-llvm-org.list

LLVM_PACKAGES="llvm-${TERMUX_HOST_LLVM_MAJOR_VERSION}-dev llvm-${TERMUX_HOST_LLVM_MAJOR_VERSION}-tools clang-${TERMUX_HOST_LLVM_MAJOR_VERSION} lld-${TERMUX_HOST_LLVM_MAJOR_VERSION}"

# =============================================================================
# Install all packages
# =============================================================================
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get update
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends $PACKAGES $LLVM_PACKAGES

# =============================================================================
# Fix ownership of Termux directories
# =============================================================================
$SUDO mkdir -p "$TERMUX__PREFIX"
$SUDO chown -R "$(whoami)" "$TERMUX__PREFIX"
$SUDO mkdir -p "$TERMUX_APP__DATA_DIR"
$SUDO chown -R "$(whoami)" "$(dirname "$TERMUX_APP__DATA_DIR")"

# =============================================================================
# Initial symlink for AOSP dependencies
# =============================================================================
$SUDO ln -sf "$TERMUX_APP__DATA_DIR/aosp" /system

# =============================================================================
# Build and install pkgconf from source (safe defaults)
# =============================================================================
PKGCONF_VERSION=2.3.0
PKGCONF_SHA256=3a9080ac51d03615e7c1910a0a2a8df08424892b5f13b0628a204d3fcce0ea8
HOST_TRIPLET=$(gcc -dumpmachine)
# Use default pkgconfig directories instead of missing personality.d
PKG_CONFIG_DIRS="/usr/lib/pkgconfig:/usr/share/pkgconfig"
SYSTEM_LIBDIRS="/usr/lib"

mkdir -p /tmp/pkgconf-build
cd /tmp/pkgconf-build
curl -O https://distfiles.ariadne.space/pkgconf/pkgconf-${PKGCONF_VERSION}.tar.xz
tar xf pkgconf-${PKGCONF_VERSION}.tar.xz
echo "${PKGCONF_SHA256}  pkgconf-${PKGCONF_VERSION}.tar.xz" | sha256sum -c -
cd pkgconf-${PKGCONF_VERSION}
./configure --prefix=/usr --with-system-libdir=${SYSTEM_LIBDIRS} --with-pkg-config-dir=${PKG_CONFIG_DIRS}
make
$SUDO make install
cd -
rm -rf /tmp/pkgconf-build
$SUDO apt-mark hold pkgconf

# =============================================================================
# Final notice
# =============================================================================
echo "Ubuntu host setup for Termux package building completed."