#!/usr/bin/env bash
# =============================================================================
# setup-glibc.sh - Install glibc packages for Termux/pacman environments
# =============================================================================

set -euo pipefail

# Load properties
. "$(dirname "$(realpath "$0")")/properties.sh"

# Load Termux package manager if available
if [ -f "$TERMUX_PREFIX/bin/termux-setup-package-manager" ]; then
    source "$TERMUX_PREFIX/bin/termux-setup-package-manager" || true
fi

# Detect package manager and install glibc packages
if [ "${TERMUX_APP_PACKAGE_MANAGER:-}" = "apt" ]; then
    echo "Error: apt-based Termux environment does not provide glibc packages."
    exit 1
elif [ "${TERMUX_APP_PACKAGE_MANAGER:-}" = "pacman" ]; then
    # Check if gpkg-dev repo is available
    if pacman-conf -r gpkg-dev &>/dev/null; then
        echo "Installing glibc packages from gpkg-dev repository..."
        sudo pacman -Syu gpkg-dev --needed --noconfirm
    else
        echo "Error: no glibc packages repository found (only gpkg-dev supported currently)."
        exit 1
    fi
else
    echo "Error: unsupported or undefined package manager."
    exit 1
fi

echo "glibc packages installation complete."