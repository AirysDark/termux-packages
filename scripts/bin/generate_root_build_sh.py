#!/usr/bin/env python3
"""
generate_root_build_sh.py - Auto-generate build.sh files for root-packages.
Features:
- Scans root-packages folder recursively.
- UTF-8 safe, cross-platform paths.
- Auto-fills TERMUX_PKG_NAME from folder name.
- Uses highest version automatically.
- Auto-fills TERMUX_PKG_SRCURL, SHA256, and dependencies.
- Overrides existing build.sh if OVERRIDE=True.
- Prepares placeholders for binaries, man pages, docs.
"""

import json
import stat
import re
from pathlib import Path

# === CONFIGURATION ===
OVERRIDE = True  # Overwrite existing build.sh files
ROOT_PACKAGES_DIR = Path("root-packages")  # Folder containing all root packages
CACHE_JSON_FILE = Path("root-packages-cache.json")
SHA256_JSON_FILE = Path("root-packages-sha256.json")

# Validate folders and files exist
if not ROOT_PACKAGES_DIR.is_dir():
    print(f"ERROR: {ROOT_PACKAGES_DIR} does not exist.")
    exit(1)
if not CACHE_JSON_FILE.is_file():
    print(f"ERROR: {CACHE_JSON_FILE} does not exist.")
    exit(1)
if not SHA256_JSON_FILE.is_file():
    print(f"ERROR: {SHA256_JSON_FILE} does not exist.")
    exit(1)

# Load cache and SHA256 data
with CACHE_JSON_FILE.open("r", encoding="utf-8") as f:
    CACHE_DATA = json.load(f)

with SHA256_JSON_FILE.open("r", encoding="utf-8") as f:
    SHA256_DATA = json.load(f)

# === Build.sh template ===
BUILD_SH_TEMPLATE = """#!/usr/bin/env bash
# Auto-generated Termux build.sh
TERMUX_PKG_NAME="{pkg_name}"
TERMUX_PKG_HOMEPAGE="{homepage}"
TERMUX_PKG_DESCRIPTION="{description}"
TERMUX_PKG_LICENSE="{license}"
TERMUX_PKG_MAINTAINER="{maintainer}"
TERMUX_PKG_VERSION="{version}"
TERMUX_PKG_SRCURL="{srcurl}"
TERMUX_PKG_SHA256="{sha256}"
TERMUX_PKG_DEPENDS="{depends}"
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

# === HELPER: parse version strings into tuples ===
def version_key(ver: str):
    """Convert a version string like '2.8.6' or 'v1.4.6' to tuple for comparison."""
    ver = ver.lstrip("v")  # Remove leading 'v'
    parts = re.split(r"[^0-9]+", ver)
    return tuple(int(p) for p in parts if p.isdigit())

# === SCAN ROOT-PACKAGES ===
package_dirs = [p for p in ROOT_PACKAGES_DIR.iterdir() if p.is_dir()]
if not package_dirs:
    print("No packages found in root-packages folder.")
    exit(0)

# === GENERATE build.sh FOR EACH PACKAGE ===
for pkg_dir in sorted(package_dirs):
    pkg_name = pkg_dir.name
    build_file = pkg_dir / "build.sh"

    # Skip existing unless override
    if build_file.is_file() and not OVERRIDE:
        print(f"build.sh already exists for {pkg_name}, skipping.")
        continue

    # Lookup metadata
    pkg_cache = CACHE_DATA.get(pkg_name, {})
    versions = pkg_cache.get("versions", [])

    # Select highest version
    if versions:
        versions_sorted = sorted(
            versions,
            key=lambda v: version_key(v.get("version", "0.0.0")),
            reverse=True
        )
        version_info = versions_sorted[0]
        version = version_info.get("version", "0.0.1")
        srcurl = version_info.get("src_url", "")
        depends = ",".join(version_info.get("depends", [])) if version_info.get("depends") else ""
    else:
        version = "0.0.1"
        srcurl = ""
        depends = ""

    # SHA256
    sha256 = SHA256_DATA.get(pkg_name, {}).get(version, "")

    # Fill placeholders for homepage, description, license, maintainer
    homepage = pkg_cache.get("homepage", "")
    description = pkg_cache.get("description", "")
    license_type = pkg_cache.get("license", "GPL-3.0")
    maintainer = pkg_cache.get("maintainer", "@termux")

    # Write build.sh
    with build_file.open("w", encoding="utf-8", newline="\n") as f:
        f.write(
            BUILD_SH_TEMPLATE.format(
                pkg_name=pkg_name,
                homepage=homepage,
                description=description,
                license=license_type,
                maintainer=maintainer,
                version=version,
                srcurl=srcurl,
                sha256=sha256,
                depends=depends
            )
        )

    # Make executable (Unix-only, harmless on Windows)
    build_file.chmod(build_file.stat().st_mode | stat.S_IEXEC)
    print(f"{'Overwritten' if OVERRIDE else 'Created'} build.sh for {pkg_name} (version {version})")

print("✅ All build.sh files generated for root-packages with highest versions selected.")
