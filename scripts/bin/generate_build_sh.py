#!/usr/bin/env python3
"""
generate_build_sh.py - Auto-generate build.sh files for Termux packages.

Features:
- Recursively scans `packages/` folder for directories.
- UTF-8 safe, cross-platform path handling.
- Auto-fills TERMUX_PKG_NAME based on folder name.
- Overrides existing build.sh files if OVERRIDE=True.
- Prepares placeholders for binaries, man pages, and docs.
"""

import stat
from pathlib import Path

# === CONFIGURATION ===
OVERRIDE = True  # Overwrite existing build.sh files if they exist
PACKAGES_DIR = Path("packages")  # Top-level packages folder

if not PACKAGES_DIR.is_dir():
    print(f"ERROR: Packages directory {PACKAGES_DIR} does not exist.")
    exit(1)

# === BUILD.SH TEMPLATE ===
BUILD_SH_TEMPLATE = """#!/usr/bin/env bash
# Auto-generated Termux build.sh
TERMUX_PKG_NAME="{pkg_name}"
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.0.1"
TERMUX_PKG_SRCURL=""
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {{
    echo "Installing directories for ${{TERMUX_PKG_NAME}}..."

    # Standard directories
    mkdir -p "$TERMUX_PREFIX/bin"
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    mkdir -p "$TERMUX_PREFIX/share/doc/${{TERMUX_PKG_NAME}}"

    # --- PLACEHOLDERS ---
    # Install binaries
    # Example: cp "myprog" "$TERMUX_PREFIX/bin/"

    # Install man pages
    # Example: install -Dm600 "doc/myprog.1" "$TERMUX_PREFIX/share/man/man1/"

    # Install documentation
    # Example: cp README.md "$TERMUX_PREFIX/share/doc/${{TERMUX_PKG_NAME}}/"

    echo "Install placeholders complete for ${{TERMUX_PKG_NAME}}"
}}
"""

# === SCAN PACKAGE DIRECTORIES ===
package_dirs = [p for p in PACKAGES_DIR.rglob("*") if p.is_dir() and (p / "build.sh").parent == p]

if not package_dirs:
    print("No packages found in 'packages/' directory.")
    exit(0)

# === GENERATE build.sh FOR EACH PACKAGE ===
for pkg_dir in sorted(package_dirs):
    build_file = pkg_dir / "build.sh"

    # Skip existing unless OVERRIDE
    if build_file.is_file() and not OVERRIDE:
        print(f"build.sh already exists for {pkg_dir.name}, skipping.")
        continue

    # Write build.sh with auto-filled TERMUX_PKG_NAME
    with build_file.open("w", encoding="utf-8", newline="\n") as f:
        f.write(BUILD_SH_TEMPLATE.format(pkg_name=pkg_dir.name))

    # Make executable (Unix-only, harmless on Windows)
    build_file.chmod(build_file.stat().st_mode | stat.S_IEXEC)
    print(f"{'Overwritten' if OVERRIDE else 'Created'} build.sh for {pkg_dir.name}")

print("✅ All build.sh files generated for packages.")