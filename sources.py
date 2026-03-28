#!/usr/bin/env python3
import requests
from utils import get_sha256
from config import FALLBACK_URLS
from logger import log
from urllib.parse import quote
import json
from pathlib import Path

# === Load GitHub Token ===
GITHUB_HEADERS = {}
github_file = Path(__file__).resolve().parent / "github_token.json"
if github_file.exists():
    try:
        data = json.loads(github_file.read_text())
        token = data.get("token")
        if token:
            GITHUB_HEADERS = {"Authorization": f"token {token}"}
    except Exception as e:
        log(f"⚠ Failed to read GitHub token: {e}")

# === Load GitLab Token ===
GITLAB_HEADERS = {}
gitlab_file = Path(__file__).resolve().parent / "gitlab_token.json"
if gitlab_file.exists():
    try:
        data = json.loads(gitlab_file.read_text())
        token = data.get("token")
        if token:
            GITLAB_HEADERS = {"Authorization": f"Bearer {token}"}
    except Exception as e:
        log(f"⚠ Failed to read GitLab token: {e}")

# === Detect likely Python packages ===
def is_python_package(pkg_name):
    return pkg_name.startswith("python-") or pkg_name in ["requests", "numpy", "torchaudio"]

# === GitHub Releases ===
def github_releases(pkg_name):
    versions = []
    try:
        search_url = f"https://api.github.com/search/repositories?q={pkg_name}+language:C"
        r = requests.get(search_url, headers=GITHUB_HEADERS, timeout=15)
        r.raise_for_status()
        items = r.json().get("items", [])
        if not items:
            return versions
        repo = items[0]["full_name"]
        releases_url = f"https://api.github.com/repos/{repo}/releases"
        r2 = requests.get(releases_url, headers=GITHUB_HEADERS, timeout=15)
        r2.raise_for_status()
        for release in r2.json():
            tar_url = release.get("tarball_url")
            version = release.get("tag_name")
            sha = get_sha256(tar_url) if tar_url else None
            if tar_url and version:
                versions.append((tar_url, sha, version))
    except Exception as e:
        log(f"⚠ GitHub failed for {pkg_name}: {e}")
    return versions

# === GitLab Releases ===
def gitlab_releases(pkg_name):
    versions = []
    try:
        url = f"https://gitlab.com/api/v4/projects?search={quote(pkg_name)}"
        r = requests.get(url, headers=GITLAB_HEADERS, timeout=15)
        r.raise_for_status()
        projects = r.json()
        if not projects:
            return versions
        project_id = projects[0]["id"]
        releases_url = f"https://gitlab.com/api/v4/projects/{project_id}/releases"
        r2 = requests.get(releases_url, headers=GITLAB_HEADERS, timeout=15)
        r2.raise_for_status()
        for release in r2.json():
            assets = release.get("assets", {}).get("sources", [])
            tar_url = assets[0].get("url") if assets else None
            version = release.get("tag_name")
            sha = get_sha256(tar_url) if tar_url else None
            if tar_url and version:
                versions.append((tar_url, sha, version))
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 403:
            log(f"⚠ GitLab forbidden for {pkg_name}, skipping")
        else:
            log(f"⚠ GitLab failed for {pkg_name}: {e}")
    except Exception as e:
        log(f"⚠ GitLab failed for {pkg_name}: {e}")
    return versions

# === PyPI Releases ===
def pypi_releases(pkg_name):
    versions = []
    if not is_python_package(pkg_name):
        return versions
    try:
        url = f"https://pypi.org/pypi/{pkg_name}/json"
        r = requests.get(url, timeout=15)
        r.raise_for_status()
        data = r.json()
        for v, files in sorted(data.get("releases", {}).items(), reverse=True):
            for f in files:
                tar_url = f.get("url")
                sha = f.get("digests", {}).get("sha256")
                if tar_url:
                    versions.append((tar_url, sha, v))
    except Exception as e:
        log(f"⚠ PyPI failed for {pkg_name}: {e}")
    return versions

# === SourceForge Releases ===
def sourceforge_releases(pkg_name):
    versions = []
    try:
        sf_api = f"https://sourceforge.net/projects/{pkg_name}/files/json"
        r = requests.get(sf_api, timeout=15)
        r.raise_for_status()
        files = r.json().get("files", [])
        for f in files:
            for release in f.get("children", []):
                tar_url = release.get("download_url")
                version = release.get("name")
                if tar_url:
                    versions.append((tar_url, None, version))
    except Exception as e:
        log(f"⚠ SourceForge failed for {pkg_name}: {e}")
    return versions

# === crates.io Releases ===
def cratesio_releases(pkg_name):
    versions = []
    try:
        url = f"https://crates.io/api/v1/crates/{pkg_name}/versions"
        r = requests.get(url, timeout=15)
        r.raise_for_status()
        data = r.json().get("versions", [])
        for v in data:
            version = v.get("num")
            tar_url = f"https://crates.io/api/v1/crates/{pkg_name}/{version}/download"
            versions.append((tar_url, None, version))
    except Exception as e:
        log(f"⚠ crates.io failed for {pkg_name}: {e}")
    return versions

# === Debian Snapshot Releases ===
def debian_snapshot_releases(pkg_name):
    versions = []
    try:
        base_url = f"https://snapshot.debian.org/binary/{pkg_name}/"
        r = requests.get(base_url, timeout=15)
        if r.status_code == 200:
            versions.append((base_url, None, "snapshot-latest"))
    except Exception as e:
        log(f"⚠ Debian snapshot failed for {pkg_name}: {e}")
    return versions

# === Arch AUR ===
def arch_aur_releases(pkg_name):
    versions = []
    try:
        url = f"https://aur.archlinux.org/rpc/?v=5&type=info&arg={quote(pkg_name)}"
        r = requests.get(url, timeout=15)
        r.raise_for_status()
        data = r.json().get("results", {})
        tar_url = data.get("URLPath")
        version = data.get("Version")
        if tar_url and version:
            versions.append((tar_url, None, version))
    except Exception as e:
        log(f"⚠ Arch AUR failed for {pkg_name}: {e}")
    return versions

# === User-Defined Fallback URLs ===
def fallback_release(pkg_name):
    versions = []
    if pkg_name in FALLBACK_URLS:
        for entry in FALLBACK_URLS[pkg_name]:
            url, sha, version = entry
            versions.append((url, sha, version))
    return versions

# === Aggregate all sources for a package ===
def get_all_sources(pkg_name):
    """
    Returns a list of tuples (url, sha256, version) for a package
    from all available sources.
    """
    versions = []
    for source in [github_releases, gitlab_releases, pypi_releases,
                   sourceforge_releases, cratesio_releases,
                   debian_snapshot_releases, arch_aur_releases,
                   fallback_release]:
        try:
            versions.extend(source(pkg_name))
        except Exception as e:
            log(f"⚠ Source {source.__name__} failed for {pkg_name}: {e}")
    # Deduplicate by URL
    seen_urls = set()
    deduped = []
    for u, s, v in versions:
        if u not in seen_urls:
            deduped.append((u, s, v))
            seen_urls.add(u)
    return deduped