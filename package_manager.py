#!/usr/bin/env python3
import os
from logger import log
from cache import load_cache, save_cache
from sources import github_releases, gitlab_releases, pypi_releases, fallback_release
from utils import get_sha256
from config import PACKAGE_DIRS, BUILD_SH_TEMPLATE, get_cache_file, get_missing_file
import json
from pathlib import Path

# === Helper functions for missing packages per folder ===
def load_missing_packages(pkg_dir: Path):
    """Load missing packages JSON for a specific folder"""
    missing_file = get_missing_file(pkg_dir)
    if missing_file.exists():
        try:
            return json.loads(missing_file.read_text())
        except Exception as e:
            log(f"⚠ Failed to load missing packages {missing_file}: {e}")
    return []

def save_missing_packages(pkg_dir: Path, packages):
    """Save missing packages JSON for a specific folder"""
    missing_file = get_missing_file(pkg_dir)
    try:
        missing_file.write_text(json.dumps(packages, indent=2))
    except Exception as e:
        log(f"⚠ Failed to save missing packages for {pkg_dir}: {e}")

def add_missing_package(pkg_name: str, pkg_dir: Path):
    """Record a missing package in folder-specific JSON"""
    packages = load_missing_packages(pkg_dir)
    if pkg_name not in packages:
        packages.append(pkg_name)
        save_missing_packages(pkg_dir, packages)
        log(f"⚠ Recorded missing package: {pkg_name} in {pkg_dir.name}")

# === Main package manager functions ===
def update_package_cache(pkg_path, cache=None, stop_callback=lambda: False, event_callback=None, allowed_packages=None):
    """
    Populate cache for a package with all available versions from multiple sources.
    stop_callback: function returning True to abort scanning.
    event_callback: function(pkg_name, status) called during processing.
    allowed_packages: optional list of package names to process.
    """
    pkg_name = pkg_path.name
    pkg_dir = pkg_path.parent

    # Load folder-specific cache if none provided
    if cache is None:
        cache = load_cache(pkg_dir)

    if allowed_packages and pkg_name not in allowed_packages:
        return  # skip packages not selected

    if stop_callback():
        log(f"⏹ Stop signal received before processing {pkg_name}")
        if event_callback:
            event_callback(pkg_name, "Stopped")
        return

    # Skip if any version is already verified
    if pkg_name in cache and any(v.get("verified") for v in cache[pkg_name].get("versions", [])):
        log(f"ℹ Already verified {pkg_name}, skipping.")
        if event_callback:
            event_callback(pkg_name, "Already verified")
        return

    log(f"🔄 Processing {pkg_name}...")
    if event_callback:
        event_callback(pkg_name, "Processing")

    versions = []
    # Gather versions from all sources
    for source in [github_releases, gitlab_releases, pypi_releases, fallback_release]:
        if stop_callback():
            log(f"⏹ Stop signal received while fetching sources for {pkg_name}")
            if event_callback:
                event_callback(pkg_name, "Stopped")
            return
        try:
            src_versions = source(pkg_name)
            if src_versions:
                versions.extend(src_versions)
                if event_callback:
                    event_callback(pkg_name, f"Fetched from {source.__name__}")
        except Exception as e:
            log(f"⚠ Failed to get versions from {source.__name__} for {pkg_name}: {e}")
            if event_callback:
                event_callback(pkg_name, f"Failed {source.__name__}")

    # Record missing packages
    if not versions:
        log(f"⚠ No sources found for {pkg_name}, recording in missing packages JSON.")
        add_missing_package(pkg_name, pkg_dir)
        if event_callback:
            event_callback(pkg_name, "No sources found")

    # Deduplicate versions by URL
    seen_urls = set()
    deduped_versions = []
    for u, s, v in versions:
        if u not in seen_urls:
            deduped_versions.append({"src_url": u, "sha256": s, "version": v, "verified": False})
            seen_urls.add(u)

    # Store all versions in cache
    cache[pkg_name] = {"versions": deduped_versions}

    # Save folder-specific cache immediately
    cache_file = get_cache_file(pkg_dir)
    try:
        cache_file.write_text(json.dumps(cache, indent=2))
    except Exception as e:
        log(f"⚠ Failed to save cache for {pkg_dir}: {e}")

    if event_callback:
        event_callback(pkg_name, "Cache updated")


def verify_cache(cache, stop_callback=lambda: False, event_callback=None, allowed_packages=None, pkg_dir: Path = None):
    """
    Verify each version in cache and mark verified if SHA256 matches.
    stop_callback: function returning True to abort verification.
    event_callback: function(pkg_name, version, status) called during verification.
    allowed_packages: optional list of package names to verify.
    pkg_dir: optional folder path for saving folder-specific cache.
    """
    for pkg_name, data in cache.items():
        if allowed_packages and pkg_name not in allowed_packages:
            continue
        if stop_callback():
            log(f"⏹ Stop signal received during verification")
            return
        for vdata in data.get("versions", []):
            if stop_callback():
                log(f"⏹ Stop signal received during verification of {pkg_name}")
                return
            if vdata.get("verified") or not vdata.get("src_url"):
                continue
            log(f"🔍 Verifying {pkg_name} {vdata.get('version')}...")
            if event_callback:
                event_callback(pkg_name, vdata.get("version"), "Verifying")
            try:
                sha = get_sha256(vdata["src_url"])
                if sha == vdata.get("sha256"):
                    vdata["verified"] = True
                    log(f"✅ Verified {pkg_name} {vdata.get('version')}")
                    if event_callback:
                        event_callback(pkg_name, vdata.get("version"), "Verified")
                else:
                    log(f"❌ Verification failed {pkg_name} {vdata.get('version')}, will retry next pass.")
                    if event_callback:
                        event_callback(pkg_name, vdata.get("version"), "Verification failed")
            except Exception as e:
                log(f"⚠ Error computing SHA256 for {pkg_name} {vdata.get('version')}: {e}")
                if event_callback:
                    event_callback(pkg_name, vdata.get("version"), f"Error: {e}")
            # Save folder-specific cache after each version
            save_dir = pkg_dir if pkg_dir else Path(".")
            cache_file = get_cache_file(save_dir)
            try:
                cache_file.write_text(json.dumps(cache, indent=2))
            except Exception as e:
                log(f"⚠ Failed to save cache for {pkg_name}: {e}")


def write_build_sh(cache):
    """
    Generate build.sh scripts for all verified versions of all packages.
    """
    for pkg_dir in PACKAGE_DIRS:
        if not pkg_dir.exists():
            continue
        for folder in pkg_dir.iterdir():
            if not folder.is_dir():
                continue
            pkg_name = folder.name
            data = cache.get(pkg_name)
            if not data:
                continue
            for vdata in data.get("versions", []):
                if not vdata.get("verified"):
                    log(f"⚠ Skipping {pkg_name} {vdata.get('version')}, not verified.")
                    continue
                build_file = folder / f"build_{vdata['version']}.sh"
                try:
                    with open(build_file, "w") as f:
                        f.write(BUILD_SH_TEMPLATE.format(
                            package_name=pkg_name,
                            src_url=vdata["src_url"],
                            sha256=vdata.get("sha256") or "UNKNOWN",
                            version=vdata["version"]
                        ))
                    os.chmod(build_file, 0o755)
                    log(f"✅ build.sh written for {pkg_name} {vdata['version']}")
                except Exception as e:
                    log(f"⚠ Failed to write build.sh for {pkg_name} {vdata.get('version')}: {e}")