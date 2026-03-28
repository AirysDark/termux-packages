#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Native Termux build environment setup (Ubuntu 22.04, Jammy + LLVM 16)
# Includes Android NDK (r25b) for official Termux cross?compile
# =============================================================================

# -----------------------------
# Prepare logging
# -----------------------------
LOG_FILE="/tmp/cgct_build.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "?? Starting native Termux build setup at $(date)" > "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# -----------------------------
# Use sudo if not root
# -----------------------------
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
# Function to install packages safely and log failures
# -----------------------------------------------------------------------------
apt_install() {
    packages="$*"
    echo "?? Installing packages: $packages"
    if ! $SUDO apt-get install -y $packages; then
        echo "? WARNING: Failed to install packages: $packages" >> "$LOG_FILE"
        echo "You may need to install them manually or fix missing dependencies." >> "$LOG_FILE"
    fi
}

# -----------------------------------------------------------------------------
# Enable multiarch and update apt
# -----------------------------------------------------------------------------
echo "?? Updating system packages..."
$SUDO dpkg --add-architecture i386
$SUDO apt-get update -y
$SUDO apt-get upgrade -y

# -----------------------------------------------------------------------------
# Install essential build packages
# -----------------------------------------------------------------------------
apt_install \
    locales python3 python3-venv python3-pip python3-setuptools python-wheel-common \
    curl gnupg git sudo lzip tar unzip xz-utils pkg-config clang lld \
    autoconf autogen automake autopoint bison flex g++ g++-multilib gawk gettext \
    gperf intltool libglib2.0-dev libltdl-dev libtool-bin m4 scons \
    libwxgtk3.0-gtk3-dev libncurses5-dev lua5.2 lua5.3 lua5.4 lua-lpeg lua-mpack \
    ruby ruby-dev ruby-full php php-xml composer openjdk-17-jdk openjdk-21-jdk \
    texlive-extra-utils texlive-metapost texinfo docbook-utils \
    jq libicu-dev libc6-dev:i386 libstdc++6:i386

# -----------------------------------------------------------------------------
# Generate locale
# -----------------------------------------------------------------------------
echo "?? Generating locale..."
$SUDO locale-gen en_US.UTF-8
$SUDO update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# -----------------------------------------------------------------------------
# CGCT installation
# -----------------------------------------------------------------------------
echo "?? Installing CGCT cross toolchain..."
CGCT_MANIFEST_JSON="$TMP_CGCT/cgct.json"
if ! curl -sSf "https://service.termux-pacman.dev/cgct/x86_64/cgct.json" -o "$CGCT_MANIFEST_JSON"; then
    echo "? ERROR: Failed to download CGCT manifest" >> "$LOG_FILE"
    exit 1
fi

for pkgname in cbt cgt glibc-cgct cgct-headers; do
    SHA256SUM=$(jq -r '."'$pkgname'"."SHA256SUM"' "$CGCT_MANIFEST_JSON")
    FILENAME=$(jq -r '."'$pkgname'"."FILENAME"' "$CGCT_MANIFEST_JSON")
    URL="https://service.termux-pacman.dev/cgct/x86_64/$FILENAME"

    if [ -z "$SHA256SUM" ] || [ -z "$FILENAME" ]; then
        echo "? ERROR: CGCT manifest missing SHA256SUM or FILENAME for $pkgname" >> "$LOG_FILE"
        exit 1
    fi

    echo "? Downloading $pkgname..."
    if ! curl -L -o "$TMP_CGCT/$FILENAME" "$URL"; then
        echo "? ERROR: Failed to download $pkgname from $URL" >> "$LOG_FILE"
        exit 1
    fi

    echo "? Verifying $pkgname checksum..."
    if ! echo "$SHA256SUM  $TMP_CGCT/$FILENAME" | sha256sum -c -; then
        echo "? ERROR: SHA256 mismatch for $pkgname" >> "$LOG_FILE"
        exit 1
    fi

    echo "?? Extracting $pkgname..."
    if ! tar xJf "$TMP_CGCT/$FILENAME" -C "$CGCT_DIR"; then
        echo "? ERROR: Failed to extract $pkgname" >> "$LOG_FILE"
        exit 1
    fi
done

echo "? CGCT setup complete."

# -----------------------------------------------------------------------------
# Android NDK installation (official supported version)
# (necessary for Termux package cross?compile)
# -----------------------------------------------------------------------------
echo "?? Installing Android NDK for Termux builds..."

# Choose a supported Android NDK
NDK_VERSION="r25b"
NDK_ROOT="$HOME/android-ndk-$NDK_VERSION"
NDK_ZIP="android-ndk-$NDK_VERSION-linux.zip"
NDK_URL="https://dl.google.com/android/repository/$NDK_ZIP"

if [ ! -d "$NDK_ROOT" ]; then
    echo "?? Downloading Android NDK $NDK_VERSION..."
    curl -L -o "$TMP_CGCT/$NDK_ZIP" "$NDK_URL"

    echo "?? Extracting Android NDK..."
    unzip -q "$TMP_CGCT/$NDK_ZIP" -d "$HOME"
fi

# Export NDK environment for Termux build scripts
export ANDROID_NDK_HOME="$NDK_ROOT"
export ANDROID_NDK_ROOT="$NDK_ROOT"
export ANDROID_NDK="$NDK_ROOT"
export PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"

# Official Termux NDK version
export TERMUX_NDK_VERSION="$NDK_VERSION"
export TERMUX_NDK_VERSION_NUM=25

echo "?? Android NDK $NDK_VERSION is set up at $ANDROID_NDK_HOME"

# -----------------------------------------------------------------------------
# Native build bypass for Termux NDK checks
# When not building for Android
# -----------------------------------------------------------------------------
if [[ "$(uname -s)" != "Android" ]]; then
    echo "?? Native Linux detected: bypassing Android NDK requirement for native builds..."
    export TERMUX_ON_DEVICE_BUILD=false
    export NDK="$ANDROID_NDK_HOME"
    export TERMUX_NDK_HOME="$ANDROID_NDK_HOME"
    # Mark as valid for Termux scripts even for native
    export TERMUX_NDK_VERSION_NUM="$TERMUX_NDK_VERSION_NUM"
    export TERMUX_NDK_VERSION="$NDK_VERSION"
fi

# -----------------------------------------------------------------------------
# Final log entry
# -----------------------------------------------------------------------------
echo "?? Native Termux build environment setup completed successfully at $(date)" >> "$LOG_FILE"