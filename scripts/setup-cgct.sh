#!/usr/bin/env bash
# =============================================================================
# setup CGCT - Cross Gnu Compilers for Termux (glibc-based binaries)
# =============================================================================

set -euo pipefail

# -----------------------------
# Logging setup
# -----------------------------
LOGFILE="/tmp/cgct_build.log"
exec > >(tee -a "$LOGFILE") 2>&1

trap 'echo "ERROR: A failure occurred. See $LOGFILE for details."; handle_error $?' ERR

handle_error() {
    local exit_code="$1"
    echo "Exit code: $exit_code" >> "$LOGFILE"

    if grep -q "SHA256SUM or filename" "$LOGFILE"; then
        echo "TIP: Check your cgct.json manifest to ensure all packages have SHA256SUM and FILENAME fields." >> "$LOGFILE"
    elif grep -q "sha256sum -c -" "$LOGFILE"; then
        echo "TIP: Downloaded package may be corrupted. Retry or manually verify the checksum." >> "$LOGFILE"
    elif grep -q "setup-cgct command not found" "$LOGFILE"; then
        echo "TIP: Ensure CGCT packages were correctly extracted into $CGCT_DIR and the correct architecture is selected." >> "$LOGFILE"
    else
        echo "TIP: Review $LOGFILE for more information on the failure." >> "$LOGFILE"
    fi
}

# -----------------------------
# Source required scripts
# -----------------------------
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PROPERTIES_SH="$SCRIPT_DIR/../properties.sh"
TERMUX_DOWNLOAD_SH="$SCRIPT_DIR/termux_download.sh"

if [ ! -f "$PROPERTIES_SH" ]; then
    echo "Error: properties.sh not found at $PROPERTIES_SH"
    exit 1
fi
if [ ! -f "$TERMUX_DOWNLOAD_SH" ]; then
    echo "Error: termux_download.sh not found at $TERMUX_DOWNLOAD_SH"
    exit 1
fi

source "$PROPERTIES_SH"
source "$TERMUX_DOWNLOAD_SH"

# -----------------------------
# Architecture and repo
# -----------------------------
ARCH="x86_64"
REPO_URL="https://service.termux-pacman.dev/cgct/${ARCH}"

HOST_ARCH="$(uname -m)"
if [ "$ARCH" != "$HOST_ARCH" ]; then
    echo "Error: the requested CGCT is not supported on your architecture ($HOST_ARCH)"
    exit 1
fi

# -----------------------------
# CGCT packages and versions
# -----------------------------
declare -A CGCT=(
    ["cbt"]="2.45.1-0"
    ["cgt"]="15.2.0-0"
    ["glibc-cgct"]="2.42-0"
    ["cgct-headers"]="6.18.6-0"
)

# -----------------------------
# Temporary and installation dirs
# -----------------------------
: "${TERMUX_PKG_TMPDIR:="/tmp"}"
TMPDIR_CGCT="${TERMUX_PKG_TMPDIR}/cgct"
CGCT_DIR="/opt/cgct"

mkdir -p "$TMPDIR_CGCT" "$CGCT_DIR"

if [ -d "$CGCT_DIR" ] && [ "$(ls -A "$CGCT_DIR")" ]; then
    echo "Removing old CGCT..."
    rm -rf "$CGCT_DIR"/*
fi

# -----------------------------
# Download CGCT manifest
# -----------------------------
CGCT_MANIFEST_JSON="$TMPDIR_CGCT/cgct.json"
echo "Fetching CGCT manifest..."
curl -sSf "${REPO_URL}/cgct.json" -o "$CGCT_MANIFEST_JSON"

if [ ! -s "$CGCT_MANIFEST_JSON" ]; then
    echo "Error: CGCT manifest is empty or missing"
    exit 1
fi

# -----------------------------
# Download, verify, and extract packages
# -----------------------------
for pkgname in "${!CGCT[@]}"; do
    version="${CGCT[$pkgname]}"
    version_of_json=$(jq -r '."'$pkgname'"."VERSION"' "$CGCT_MANIFEST_JSON")
    SHA256SUM=$(jq -r '."'$pkgname'"."SHA256SUM"' "$CGCT_MANIFEST_JSON")
    filename=$(jq -r '."'$pkgname'"."FILENAME"' "$CGCT_MANIFEST_JSON")

    if [ "$version" != "$version_of_json" ]; then
        echo "Error: version mismatch for '${pkgname}': requested '${version}', got '${version_of_json}'"
        exit 1
    fi
    if [ -z "$SHA256SUM" ] || [ "$SHA256SUM" = "null" ] || [ -z "$filename" ] || [ "$filename" = "null" ]; then
        echo "Error: package '${pkgname}' missing SHA256SUM or filename in manifest"
        exit 1
    fi

    if [ ! -f "$TMPDIR_CGCT/$filename" ]; then
        echo "Downloading ${pkgname}..."
        termux_download "${REPO_URL}/${filename}" "$TMPDIR_CGCT/$filename" "$SHA256SUM"
    fi

    echo "${SHA256SUM}  $TMPDIR_CGCT/$filename" | sha256sum -c -

    echo "Extracting ${pkgname}..."
    tar xJf "$TMPDIR_CGCT/$filename" -C "$CGCT_DIR"
done

# -----------------------------
# Install gcc-libs for CGCT if missing
# -----------------------------
if [ ! -f "$CGCT_DIR/lib/libgcc_s.so" ]; then
    echo "Installing gcc-libs..."
    GCCLIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-15.1.1+r7+gf36ec88aa85a-1-x86_64.pkg.tar.zst"
    GCCLIBS_SHA="6eedd2e4afc53e377b5f1772b5d413de3647197e36ce5dc4a409f993668aa5ed"
    termux_download "$GCCLIBS_URL" "$TMPDIR_CGCT/gcc-libs.pkg.tar.zst" "$GCCLIBS_SHA"

    mkdir -p "$TMPDIR_CGCT/usr/lib"
    tar --use-compress-program=unzstd -xf "$TMPDIR_CGCT/gcc-libs.pkg.tar.zst" -C "$TMPDIR_CGCT" usr/lib
    cp -r "$TMPDIR_CGCT/usr/lib/"* "$CGCT_DIR/lib"
fi

# -----------------------------
# Validate setup-cgct command exists
# -----------------------------
if [ ! -f "$CGCT_DIR/bin/setup-cgct" ]; then
    echo "Error: setup-cgct command not found in CGCT directory"
    exit 1
fi

# -----------------------------
# Run CGCT setup
# -----------------------------
echo "Setting up CGCT..."
"$CGCT_DIR/bin/setup-cgct" "/usr/lib/x86_64-linux-gnu"

echo "CGCT installation complete."
echo "Full log available at $LOGFILE"