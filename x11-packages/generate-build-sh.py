#!/usr/bin/env python3
"""
generate_build_sh.py - Maxed-out automatic build.sh generator for Termux packages.
Features:
- Recursive package discovery from tree /F /A style.
- UTF-8 and UTF-16 support.
- Windows and Unix-safe path handling.
- Auto-fills TERMUX_PKG_NAME based on folder.
- Override existing build.sh files if OVERRIDE=True.
- Prepares install placeholders for binaries, man pages, and docs.
"""

import re
from pathlib import Path
import stat

# === CONFIGURATION ===
OVERRIDE = True  # Set True to overwrite existing build.sh files
TREE_FILE = Path("packages_tree_utf8.txt")
if not TREE_FILE.is_file():
    TREE_FILE = Path("packages_tree.txt")
    if not TREE_FILE.is_file():
        print(f"ERROR: {TREE_FILE} not found.")
        exit(1)

# === EXTRACT PACKAGE DIRECTORIES RECURSIVELY ===
package_dirs = set()
for enc in ("utf-8", "utf-16"):
    try:
        with TREE_FILE.open("r", encoding=enc) as f:
            for line in f:
                line = line.rstrip()
                match = re.match(r'^[\| ]*\+---(.*)', line)
                if match:
                    pkg_name = match.group(1).strip()
                    if pkg_name:
                        pkg_name = pkg_name.replace("\\", "/")  # Windows-safe
                        package_dirs.add(pkg_name)
        break
    except UnicodeError:
        continue
else:
    print(f"ERROR: Could not read {TREE_FILE} (not utf-8 or utf-16).")
    exit(1)

# === MAXED-OUT BUILD.SH TEMPLATE ===
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

# === GENERATE BUILD.SH FOR EACH PACKAGE ===
for pkg in sorted(package_dirs):
    pkg_dir = Path(pkg)
    build_file = pkg_dir / "build.sh"

    # Ensure directory exists
    pkg_dir.mkdir(parents=True, exist_ok=True)

    # Skip existing unless override
    if build_file.is_file() and not OVERRIDE:
        print(f"build.sh already exists for {pkg}, skipping.")
        continue

    # Write build.sh with auto-filled TERMUX_PKG_NAME
    with build_file.open("w", encoding="utf-8", newline="\n") as f:
        f.write(BUILD_SH_TEMPLATE.format(pkg_name=pkg_dir.name))

    # Make executable (Unix-only, harmless on Windows)
    build_file.chmod(build_file.stat().st_mode | stat.S_IEXEC)
    print(f"{'Overwritten' if OVERRIDE else 'Created'} enhanced build.sh for {pkg}")

print("✅ All enhanced build.sh files have been generated recursively with TERMUX_PKG_NAME auto-filled.")