#!/usr/bin/env bash
set -e -u

# =============================================================================
# Ubuntu host setup for Termux package building (Linux-only)
# =============================================================================

PACKAGES=""

# Locale
PACKAGES+=" locales"

# Python support
PACKAGES+=" python-is-python3 python3-pip python3-setuptools python-wheel-common python3.12-venv"

# Build essentials and general tools
PACKAGES+=" curl gnupg git lzip tar unzip lrzip lzop lz4 zstd fuse-overlayfs"
PACKAGES+=" autoconf autogen automake autopoint bison flex g++ g++-multilib gawk gettext gperf intltool libglib2.0-dev libltdl-dev libtool-bin m4 pkg-config scons"

# Documentation tools
PACKAGES+=" asciidoc asciidoctor go-md2man groff help2man pandoc python3-docutils python3-recommonmark python3-myst-parser python3-sphinx python3-sphinx-rtd-theme python3-sphinxcontrib.qthelp scdoc texinfo txt2man xmlto xmltoman"

# Miscellaneous
PACKAGES+=" ed recutils bsdmainutils valac fig2dev gegl gengetopt libdbus-1-dev libelf-dev libexpat1-dev libjpeg-dev librsvg2-dev libsqlite3-dev lua5.2 lua5.3 lua5.4 libncurses5-dev lua-lpeg lua-mpack libyaml-dev ruby libc-ares-dev libc-ares-dev:i386 libicu-dev libsqlite3-dev:i386 re2c php php-xml composer libssl-dev libclang-rt-17-dev libclang-rt-17-dev:i386 libsigsegv-dev zip tcl openssl zlib1g-dev libssl-dev:i386 zlib1g-dev:i386 lld luajit bc libarchive-tools nasm po4a rsync wget libwxgtk3.2-dev libgtk-3-dev comerr-dev docbook-to-man docbook-utils erlang-nox heimdal-multidev libconfig-dev libevent-dev libgc-dev libgmp-dev libjansson-dev libparse-yapp-perl libreadline-dev libunistring-dev alex docbook-xsl-ns gnome-common gobject-introspection gtk-3-examples gtk-doc-tools happy itstool libdbus-glib-1-dev-bin libgdk-pixbuf2.0-dev python3-html5lib python3-xcbgen sassc texlive-extra-utils unifdef xfce4-dev-tools xfonts-utils xutils-dev desktop-file-utils protobuf-c-compiler sqlite3 cvs python3-yaml bash-static triehash aspell guile-3.0-dev python3-jsonschema fontforge-nox guile-3.0 python3-fontforge texlive-metapost libfl-dev libxft-dev libxt-dev xbitmaps xxd libjson-perl jq libcurl4-openssl-dev openjdk-17-jre openjdk-17-jdk openjdk-21-jre openjdk-21-jdk libnss3 libnss3:i386 libnss3-dev libwebp7 libwebp7:i386 libwebp-dev libwebpdemux2 libwebpdemux2:i386 libwebpmux3 libwebpmux3:i386 libfontconfig1 libfontconfig1:i386 libcups2-dev libglib2.0-0t64:i386 libexpat1:i386 libxkbfile-dev libsecret-1-dev libkrb5-dev libfreetype-dev:i386 libdebuginfod-dev patchelf swig libzstd-dev glslang-tools"

# Sudo not required if already root
SUDO="sudo"
if [ "$(id -u)" = "0" ]; then
	SUDO=""
fi

# Enable i386 architecture
$SUDO dpkg --add-architecture i386

# Install jq first for properties.sh usage
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get update
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends jq

# Source properties.sh for variables like TERMUX_HOST_LLVM_MAJOR_VERSION
. "$(dirname "$(realpath "$0")")/properties.sh"

# Add apt.llvm.org repo for newer LLVM
$SUDO cp "$(dirname "$(realpath "$0")")/llvm-snapshot.gpg.key" /etc/apt/trusted.gpg.d/apt.llvm.org.asc
$SUDO chmod a+r /etc/apt/trusted.gpg.d/apt.llvm.org.asc
echo "deb [arch=amd64] http://apt.llvm.org/noble/ llvm-toolchain-noble-${TERMUX_HOST_LLVM_MAJOR_VERSION} main" | $SUDO tee /etc/apt/sources.list.d/apt-llvm-org.list

# LLVM packages
LLVM_PACKAGES="llvm-${TERMUX_HOST_LLVM_MAJOR_VERSION}-dev llvm-${TERMUX_HOST_LLVM_MAJOR_VERSION}-tools clang-${TERMUX_HOST_LLVM_MAJOR_VERSION} lld-${TERMUX_HOST_LLVM_MAJOR_VERSION}"

# Update and install all packages
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get update
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends $PACKAGES $LLVM_PACKAGES

# Generate locale
$SUDO locale-gen --purge en_US.UTF-8
echo -e 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' | $SUDO tee -a /etc/default/locale

# Fix ownership for TERMUX__PREFIX and TERMUX_APP__DATA_DIR
$SUDO mkdir -p "$TERMUX__PREFIX"
$SUDO chown -R "$(whoami)" "$TERMUX__PREFIX"
$SUDO mkdir -p "$TERMUX_APP__DATA_DIR"
$SUDO chown -R "$(whoami)" "${TERMUX_APP__DATA_DIR%"${TERMUX_APP__DATA_DIR#/*/}"}"

# Create initial symlink for aosp dependencies
$SUDO ln -sf "$TERMUX_APP__DATA_DIR/aosp" /system

# Build and install newer pkgconf from source
PKGCONF_VERSION=2.3.0
PKGCONF_SHA256=3a9080ac51d03615e7c1910a0a2a8df08424892b5f13b0628a204d3fcce0ea8
HOST_TRIPLET=$(gcc -dumpmachine)
PKG_CONFIG_DIRS=$(grep DefaultSearchPaths: /usr/share/pkgconfig/personality.d/${HOST_TRIPLET}.personality | cut -d ' ' -f 2)
SYSTEM_LIBDIRS=$(grep SystemLibraryPaths: /usr/share/pkgconfig/personality.d/${HOST_TRIPLET}.personality | cut -d ' ' -f 2)

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