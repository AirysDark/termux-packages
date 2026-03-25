#!/usr/bin/env bash
##
## check-pie.sh - Detect non-PIE (Position Independent Executable) binaries
## Works on Linux, does not function on Android without full ELF toolchain
##

set -euo pipefail

# Load Termux properties (defines TERMUX_PREFIX, etc.)
source "$(dirname "$(realpath "$0")")/properties.sh"

# Go to Termux bin directory
cd "${TERMUX_PREFIX}/bin" || { echo "ERROR: Could not change to ${TERMUX_PREFIX}/bin"; exit 1; }

# Loop over all files in bin
for file in *; do
    # Only process regular files
    [ -f "$file" ] || continue

    # Check if ELF executable and non-PIE
    if readelf -h "$file" 2>/dev/null | grep -qE 'Type:[[:space:]]*EXEC'; then
        echo "$file"
    fi
done