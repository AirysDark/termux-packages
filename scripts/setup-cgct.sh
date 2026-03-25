#!/usr/bin/env bash
# =============================================================================
# setup CGCT - Cross Gnu Compilers for Termux (glibc-based binaries)
# =============================================================================

set -euo pipefail

# Load environment variables
. "$(dirname "$(realpath "$0")")/properties.sh"
. "$(dirname "$(realpath "$0")")/build/termux_download.sh"

ARCH="x86_64"
REPO_URL="https://service.termux-pacman.dev/cgct/${ARCH}"

# Ensure host architecture matches
if [ "$ARCH" != "$(uname -m)" ]; then
    echo "Error: the requested CGCT is not supported on your architecture"
    exit 1
fi

# Packages and versions
declare -A CGCT=(
    ["cbt"]="2.45.1-0"       # Cross Binutils for Termux
    ["cgt"]="15.2.0-0"       # Cross GCCs for Termux
    ["glibc-cgct"]="2.42-0"  # Glibc for CGCT
    ["cgct-headers"]="6.18.6-0" # Headers for CGCT
)

: "${TERMUX_PKG_TMPDIR:="/tmp"}"
TMPDIR_CGCT="${TERMUX_PKG_TMPDIR}/cgct"
CGCT_DIR="/opt/cgct"  # Base install directory

# Create CGCT tmp directory
mkdir -p "$TMPDIR_CGCT"

# Remove old CGCT installation if present
if [ -d "$CGCT_DIR" ]; then
    echo "Removing old CGCT..."
    rm -rf "$CGCT_DIR"
fi

mkdir -p "$CGCT_DIR"

# Download CGCT JSON manifest
echo "Fetching CGCT manifest..."
curl -sSf "${REPO_URL}/cgct.json" -o "${TMPDIR_CGCT}/cgct.json"

# Download and extract CGCT packages
for pkgname in "${!CGCT[@]}"; do
    version="${CGCT[$pkgname]}"
    version_of_json=$(jq -r '."'$pkgname'"."VERSION"' "${TMPDIR_CGCT}/cgct.json")
    SHA256SUM=$(jq -r '."'$pkgname'"."SHA256SUM"' "${TMPDIR_CGCT}/cgct.json")
    filename=$(jq -r '."'$pkgname'"."FILENAME"' "${TMPDIR_CGCT}/cgct.json")

    # Validate JSON
    if [ "$version" != "$version_of_json" ]; then
        echo "Error: versions do not match for '${pkgname}': requested '${version}', got '${version_of_json}'"
        exit 1
    fi
    if [ "$SHA256SUM" = "null" ] || [ "$filename" = "null" ]; then
        echo "Error: package '${pkgname}' missing SHA256SUM or filename in manifest"
        exit 1
    fi

    # Download if missing
    if [ ! -f "${TMPDIR_CGCT}/${filename}" ]; then
        echo "Downloading ${pkgname}..."
        termux_download "${REPO_URL}/${filename}" "${TMPDIR_CGCT}/${filename}" "${SHA256SUM}"
    fi

    # Extract to CGCT_DIR
    echo "Extracting ${pkgname}..."
    tar xJf "${TMPDIR_CGCT}/${filename}" -C "$CGCT_DIR"
done

# Install gcc-libs for CGCT if missing
if [ ! -f "${CGCT_DIR}/lib/libgcc_s.so" ]; then
    echo "Installing gcc-libs..."
    GCCLIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-15.1.1+r7+gf36ec88aa85a-1-x86_64.pkg.tar.zst"
    GCCLIBS_SHA="6eedd2e4afc53e377b5f1772b5d413de3647197e36ce5dc4a409f993668aa5ed"
    termux_download "$GCCLIBS_URL" "${TMPDIR_CGCT}/gcc-libs.pkg.tar.zst" "$GCCLIBS_SHA"
    mkdir -p "${TMPDIR_CGCT}/usr/lib"
    tar --use-compress-program=unzstd -xf "${TMPDIR_CGCT}/gcc-libs.pkg.tar.zst" -C "${TMPDIR_CGCT}" usr/lib
    cp -r "${TMPDIR_CGCT}/usr/lib/"* "${CGCT_DIR}/lib"
fi

# Validate setup-cgct command exists
if [ ! -f "${CGCT_DIR}/bin/setup-cgct" ]; then
    echo "Error: setup-cgct command not found in CGCT directory"
    exit 1
fi

# Run CGCT setup
echo "Setting up CGCT..."
"${CGCT_DIR}/bin/setup-cgct" "/usr/lib/x86_64-linux-gnu"

echo "CGCT installation complete."