#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Ubuntu host setup for Termux package building (Linux-only, Jammy + LLVM 16)
# =============================================================================

# Use sudo if not root
SUDO="sudo"
if [ "$(id -u)" = "0" ]; then
    SUDO=""
fi

# -----------------------------------------------------------------------------
# Environment variables
# -----------------------------------------------------------------------------
TERMUX_HOST_LLVM_MAJOR_VERSION=16
TERMUX_HOST_GCC_VERSION=13
TERMUX_PKG_TMPDIR="/tmp"
TERMUX__PREFIX="/usr/local/termux"
TERMUX_APP__DATA_DIR="$HOME/.termux"
TMP_CGCT="$TERMUX_PKG_TMPDIR/cgct"
CGCT_DIR="/opt/cgct"

mkdir -p "$TMP_CGCT" "$CGCT_DIR"

# -----------------------------------------------------------------------------
# Enable multiarch and update apt
# -----------------------------------------------------------------------------
$SUDO dpkg --add-architecture i386
$SUDO apt-get update -y
$SUDO apt-get upgrade -y

# -----------------------------------------------------------------------------
# Install essential build packages
# -----------------------------------------------------------------------------
$SUDO apt-get install -y \
    locales python3 python3-venv python3-pip python3-setuptools python-wheel-common \
    curl gnupg git sudo lzip tar unzip xz-utils pkg-config clang lld \
    autoconf autogen automake autopoint bison flex g++ g++-multilib gawk gettext \
    gperf intltool libglib2.0-dev libltdl-dev libtool-bin m4 scons \
    libwxgtk3.0-gtk3-dev libncurses5-dev lua5.2 lua5.3 lua5.4 lua-lpeg lua-mpack \
    ruby php php-xml composer openjdk-17-jdk openjdk-21-jdk \
    texlive-extra-utils texlive-metapost texinfo docbook-utils \
    jq libicu-dev libc6-dev:i386 libstdc++6:i386

# -----------------------------------------------------------------------------
# Generate locale
# -----------------------------------------------------------------------------
$SUDO locale-gen en_US.UTF-8
$SUDO update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# -----------------------------------------------------------------------------
# CGCT installation
# -----------------------------------------------------------------------------
echo "Installing CGCT cross toolchain..."
CGCT_MANIFEST_JSON="$TMP_CGCT/cgct.json"
curl -sSf "https://service.termux-pacman.dev/cgct/x86_64/cgct.json" -o "$CGCT_MANIFEST_JSON"

for pkgname in cbt cgt glibc-cgct cgct-headers; do
    SHA256SUM=$(jq -r '."'$pkgname'"."SHA256SUM"' "$CGCT_MANIFEST_JSON")
    FILENAME=$(jq -r '."'$pkgname'"."FILENAME"' "$CGCT_MANIFEST_JSON")
    URL="https://service.termux-pacman.dev/cgct/x86_64/$FILENAME"

    echo "Downloading $pkgname..."
    curl -L -o "$TMP_CGCT/$FILENAME" "$URL"

    echo "$SHA256SUM  $TMP_CGCT/$FILENAME" | sha256sum -c -
    echo "Extracting $pkgname..."
    tar xJf "$TMP_CGCT/$FILENAME" -C "$CGCT_DIR"
done

echo "CGCT setup complete."

# -----------------------------------------------------------------------------
# Create log file
# -----------------------------------------------------------------------------
touch /tmp/cgct_build.log
echo "Native Termux build environment setup completed at $(date)" > /tmp/cgct_build.log
