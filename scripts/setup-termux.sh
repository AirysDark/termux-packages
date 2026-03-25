#!/usr/bin/env bash
# =============================================================================
# setup-termux-packages.sh - Install required packages for Termux build scripts
# =============================================================================

set -euo pipefail

# -------------------------
# System packages
# -------------------------
PACKAGES=""

# Tier 1: requirements for core build scripts
PACKAGES+=" clang"           # Required for termux-elf-cleaner and C/C++ packages
PACKAGES+=" file"            # Used in termux_step_massage()
PACKAGES+=" gnupg"           # Used in termux_get_repo_files() and build-package.sh
PACKAGES+=" lzip"            # Used by tar to extract *.tar.lz source archives
PACKAGES+=" patch"           # Used for applying patches on source code
PACKAGES+=" python"          # Used by buildorder.py core script
PACKAGES+=" python3-pip"     # Needed to install Python packages
PACKAGES+=" unzip"           # Used to extract *.zip source archives
PACKAGES+=" jq"              # Used for parsing JSON manifests

# Tier 2: packages required for building many Termux packages
PACKAGES+=" asciidoc asciidoctor autoconf automake bc bison bsdtar cmake ed"
PACKAGES+=" flex gettext git glslang golang gperf help2man intltool libtool"
PACKAGES+=" llvm-tools m4 make ndk-multilib ninja perl pkg-config protobuf"
PACKAGES+=" python2 re2c rust scdoc texinfo spirv-tools uuid-utils valac xmlto zip"

# -------------------------
# Python packages (system-wide)
# -------------------------
PYTHON_PACKAGES=""
PYTHON_PACKAGES+=" itstool"      # Needed to build orca
PYTHON_PACKAGES+=" pygments"     # Needed by mesa/mako
PYTHON_PACKAGES+=" mako"         # Needed by mesa
PYTHON_PACKAGES+=" pyyaml"       # Needed by mesa
PYTHON_PACKAGES+=" setuptools"   # Needed by mesa (system-wide install)

# -------------------------
# Detect Termux/Ubuntu environment
# -------------------------
export TERMUX_SCRIPTDIR=$(dirname "$(realpath "$0")")/..
. "$TERMUX_SCRIPTDIR/properties.sh"

# Load Termux package manager if available
if [ -f "$TERMUX_PREFIX/bin/termux-setup-package-manager" ]; then
    source "$TERMUX_PREFIX/bin/termux-setup-package-manager" || true
fi

# -------------------------
# Install system packages
# -------------------------
if [ "${TERMUX_APP_PACKAGE_MANAGER:-}" = "apt" ]; then
    sudo apt update
    sudo DEBIAN_FRONTEND=noninteractive apt -y dist-upgrade
    sudo DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends $PACKAGES
elif [ "${TERMUX_APP_PACKAGE_MANAGER:-}" = "pacman" ]; then
    sudo pacman -Syu --needed --noconfirm $PACKAGES
else
    echo "Error: no supported package manager found (apt or pacman)"
    exit 1
fi

# -------------------------
# Install Python packages system-wide
# -------------------------
# Should not be installed inside a venv to mimic Ubuntu cross-builder image behavior
pip install --upgrade $PYTHON_PACKAGES

echo "System and Python packages installation complete."