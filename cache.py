import json
from logger import log
from pathlib import Path

# === Helper to get per-folder files ===
def get_cache_file(pkg_dir: Path):
    """Return the cache JSON file path for a given package folder."""
    return pkg_dir / f"{pkg_dir.name}-cache.json"

def get_missing_file(pkg_dir: Path):
    """Return the missing packages JSON file path for a given package folder."""
    return pkg_dir / f"{pkg_dir.name}-missing.json"

# === PACKAGE CACHE FUNCTIONS ===
def load_cache(pkg_dir: Path):
    """
    Load the package cache from JSON file for a given folder.
    Supports multiple versions per package.
    """
    CACHE_FILE = get_cache_file(pkg_dir)
    if CACHE_FILE.exists() and CACHE_FILE.stat().st_size > 0:
        try:
            data = json.loads(CACHE_FILE.read_text())
            # Ensure structure supports multiple versions
            for pkg_name, pkg_data in data.items():
                if "versions" not in pkg_data:
                    data[pkg_name] = {"versions": [pkg_data]}
            return data
        except json.JSONDecodeError:
            log(f"⚠ JSON decode error in {CACHE_FILE}, resetting cache")
        except Exception as e:
            log(f"⚠ Failed to load cache {CACHE_FILE}: {e}")
    return {}

def save_cache(pkg_dir: Path, cache: dict):
    """
    Save the package cache to JSON file for a given folder.
    Preserves multiple versions per package.
    """
    CACHE_FILE = get_cache_file(pkg_dir)
    try:
        CACHE_FILE.write_text(json.dumps(cache, indent=2))
    except Exception as e:
        log(f"⚠ Failed to save cache {CACHE_FILE}: {e}")

# === MISSING PACKAGES FUNCTIONS ===
def load_missing_packages(pkg_dir: Path):
    """
    Load the missing packages JSON feed for a given folder.
    Returns a list of package names.
    """
    MISSING_PACKAGES_FILE = get_missing_file(pkg_dir)
    if MISSING_PACKAGES_FILE.exists() and MISSING_PACKAGES_FILE.stat().st_size > 0:
        try:
            return json.loads(MISSING_PACKAGES_FILE.read_text())
        except json.JSONDecodeError:
            log(f"⚠ JSON decode error in {MISSING_PACKAGES_FILE}, resetting missing packages list")
        except Exception as e:
            log(f"⚠ Failed to load missing packages {MISSING_PACKAGES_FILE}: {e}")
    return []

def save_missing_packages(pkg_dir: Path, packages: list):
    """
    Save the missing packages list to JSON feed for a given folder.
    """
    MISSING_PACKAGES_FILE = get_missing_file(pkg_dir)
    try:
        MISSING_PACKAGES_FILE.write_text(json.dumps(packages, indent=2))
    except Exception as e:
        log(f"⚠ Failed to save missing packages {MISSING_PACKAGES_FILE}: {e}")

def add_missing_package(pkg_dir: Path, pkg_name: str):
    """
    Add a package name to the missing packages feed if not already present.
    Updates the JSON file live.
    """
    packages = load_missing_packages(pkg_dir)
    if pkg_name not in packages:
        packages.append(pkg_name)
        save_missing_packages(pkg_dir, packages)
        log(f"⚠ Recorded missing package: {pkg_name}")