#!/usr/bin/env python3
import json
import requests
from pathlib import Path
from logger import log  # optional logging
import hashlib
from config import FALLBACK_URLS

# === Input/Output files ===
CHECK_FILE = Path("package_check_results.txt")
OUTPUT_JSON = Path("package_fallback_sources.json")

# === Helper: compute SHA256 for a URL ===
def compute_sha256(url):
    try:
        r = requests.get(url, stream=True, timeout=30)
        r.raise_for_status()
        h = hashlib.sha256()
        for chunk in r.iter_content(chunk_size=8192):
            if chunk:
                h.update(chunk)
        return h.hexdigest()
    except Exception as e:
        log(f"⚠ Failed SHA256 for {url}: {e}")
        return None

# === Detect Python packages ===
def is_python_package(pkg_name):
    return pkg_name.startswith("python-") or pkg_name in ["requests", "numpy", "torchaudio"]

# === GitHub repositories (verified and existing) ===
GITHUB_REPOS = {
    "btop": "aristocratos/btop",
    "gocryptfs": "rfjakob/gocryptfs"
}

def github_releases(pkg_name):
    versions = []
    if pkg_name not in GITHUB_REPOS:
        return versions
    repo = GITHUB_REPOS[pkg_name]
    try:
        releases_url = f"https://api.github.com/repos/{repo}/releases"
        r = requests.get(releases_url, timeout=15)
        r.raise_for_status()
        for release in r.json():
            tar_url = release.get("tarball_url")
            version = release.get("tag_name")
            if tar_url and version:
                versions.append((tar_url, None, version))
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 403:
            log(f"⚠ GitHub rate limit for {pkg_name}, skipping")
        elif e.response.status_code == 404:
            log(f"⚠ GitHub repo not found for {pkg_name}, skipping")
        else:
            log(f"⚠ GitHub failed for {pkg_name}: {e}")
    except Exception as e:
        log(f"⚠ GitHub failed for {pkg_name}: {e}")
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
        for v, files in data.get("releases", {}).items():
            for f in files:
                tar_url = f.get("url")
                if tar_url:
                    versions.append((tar_url, None, v))
    except Exception as e:
        log(f"⚠ PyPI failed for {pkg_name}: {e}")
    return versions

# === Debian Snapshot Releases ===
DEBIAN_SNAPSHOT_BASE = "https://snapshot.debian.org/archive/debian/"
DEBIAN_PACKAGES = {
    "wpa-supplicant": "pool/main/w/wpa_supplicant/wpa_supplicant_2.10.orig.tar.gz",
    "lvm2": "pool/main/l/lvm2/lvm2_2.03.14.orig.tar.gz",
    "runc": "pool/main/r/runc/runc_1.1.9.orig.tar.gz",
    "macchanger": "pool/main/m/macchanger/macchanger_1.8.4.orig.tar.gz",
    "iodine": "pool/main/i/iodine/iodine_0.7.5.orig.tar.gz",
    "libfuse2": "pool/main/f/fuse2/fuse2_2.9.9.orig.tar.gz",
    "termshark": "pool/main/t/termshark/termshark_2.2.0.orig.tar.gz",
    "btop": "pool/main/b/btop/btop_1.2.6.orig.tar.gz",
    "erofs-utils": "pool/main/e/erofs-utils/erofs-utils_1.1.orig.tar.gz",
    "below": "pool/main/b/below/below_1.7.orig.tar.gz",
    "minikube": "pool/main/m/minikube/minikube_1.29.0.orig.tar.gz",
    "vlan": "pool/main/v/vlan/vlan_1.0.1.orig.tar.gz",
    "bindfs": "pool/main/b/bindfs/bindfs_1.14.0.orig.tar.gz",
    "tcpdump": "pool/main/t/tcpdump/tcpdump_4.99.1.orig.tar.gz",
    "authbind": "pool/main/a/authbind/authbind_2.1.orig.tar.gz",
    "testdisk": "pool/main/t/testdisk/testdisk_7.2.orig.tar.gz",
    "wush": "pool/main/w/wush/wush_1.2.orig.tar.gz",
    "hping3": "pool/main/h/hping3/hping3_3.0.0.orig.tar.gz",
    "tcplay-veracrypt": "pool/main/t/tcplay-veracrypt/tcplay-veracrypt_1.0.0.orig.tar.gz",
    "libaio": "pool/main/l/libaio/libaio_0.3.113.orig.tar.gz",
    "usbutils": "pool/main/u/usbutils/usbutils_009.orig.tar.gz",
    "hw-probe": "pool/main/h/hw-probe/hw-probe_0.8.orig.tar.gz",
    "libx86emu": "pool/main/l/libx86emu/libx86emu_0.7.4.orig.tar.gz",
    "wimlib": "pool/main/w/wimlib/wimlib_1.12.orig.tar.gz",
    "libccid": "pool/main/libs/libccid/libccid_1.6.2.orig.tar.gz"
}

def debian_snapshot_release(pkg_name):
    if pkg_name in DEBIAN_PACKAGES:
        url = DEBIAN_SNAPSHOT_BASE + DEBIAN_PACKAGES[pkg_name]
        return [(url, None, "snapshot-latest")]
    return []

# === Upstream mapping for snapshot-only packages ===
SNAPSHOT_UPSTREAM = {
    "iodine": ("https://github.com/yarrick/iodine/archive/refs/tags/v0.7.0.tar.gz", "0.7.0"),
    "erofs-utils": ("https://github.com/erofs/erofs-utils/archive/refs/tags/v1.1.tar.gz", "1.1"),
    "below": ("https://github.com/erofs/below/archive/refs/tags/v1.7.tar.gz", "1.7"),
    "tcpdump": ("https://github.com/the-tcpdump-group/tcpdump/archive/refs/tags/tcpdump-4.99.1.tar.gz", "4.99.1"),
    # None = no upstream known, will just use snapshot
    "authbind": None,
    "testdisk": ("https://www.cgsecurity.org/testdisk-7.2.tar.bz2", "7.2"),
    "runc": ("https://github.com/opencontainers/runc/archive/refs/tags/v1.1.9.tar.gz", "1.1.9"),
    "macchanger": ("https://github.com/alobbs/macchanger/archive/refs/tags/v1.8.4.tar.gz", "1.8.4"),
    "lvm2": ("https://sourceware.org/ftp/lvm2/releases/lvm2-2.03.14.tar.gz", "2.03.14"),
    "wush": None,
    "hping3": ("https://github.com/antirez/hping/archive/refs/tags/3.0.0.tar.gz", "3.0.0"),
    "tcplay-veracrypt": None,
    "libaio": ("https://github.com/axboe/libaio/archive/refs/tags/libaio-0.3.113.tar.gz", "0.3.113"),
    "usbutils": ("https://git.kernel.org/pub/scm/utils/usb/usbutils.git/snapshot/usbutils-009.tar.gz", "009"),
    "hw-probe": ("https://github.com/linuxhw/hw-probe/archive/refs/tags/v0.8.tar.gz", "0.8"),
    "libx86emu": ("https://github.com/cheusov/x86emu/archive/refs/tags/v0.7.4.tar.gz", "0.7.4"),
    "wimlib": ("https://wimlib.net/download/wimlib-1.12.tar.gz", "1.12"),
}

# === Deduplicate versions ===
def dedupe_versions(version_list):
    seen_urls = set()
    deduped = []
    for url, sha, version in version_list:
        if url not in seen_urls:
            deduped.append((url, sha, version))
            seen_urls.add(url)
    return deduped

# === Search upstream for snapshot-only packages ===
def search_upstream(pkg_name):
    urls = []
    if pkg_name in SNAPSHOT_UPSTREAM and SNAPSHOT_UPSTREAM[pkg_name]:
        url, version = SNAPSHOT_UPSTREAM[pkg_name]
        urls.append((url, None, version))
    return urls

# === Main fallback_release function ===
def fallback_release(pkg_name):
    versions = []
    if pkg_name in FALLBACK_URLS:
        versions.extend(FALLBACK_URLS[pkg_name])
    versions.extend(search_upstream(pkg_name))
    return dedupe_versions(versions)

# === Main ===
def main():
    if not CHECK_FILE.exists():
        print(f"⚠ Check file {CHECK_FILE} not found")
        return

    packages_to_scan = []
    with CHECK_FILE.open() as f:
        for line in f:
            line = line.strip()
            if line.startswith("FOUND") or line.startswith("PARTIAL") or line.startswith("MISSING"):
                pkg_name = line.split(":")[1].split()[0]
                packages_to_scan.append(pkg_name)

    print(f"Found {len(packages_to_scan)} packages to search links for")
    fallback_sources = {}

    for pkg in packages_to_scan:
        versions = []
        # GitHub releases
        versions.extend(github_releases(pkg))
        # PyPI releases
        versions.extend(pypi_releases(pkg))
        # Debian snapshot
        versions.extend(debian_snapshot_release(pkg))
        # Fallback + upstream
        versions.extend(fallback_release(pkg))
        # Deduplicate
        versions = dedupe_versions(versions)
        fallback_sources[pkg] = versions

    try:
        OUTPUT_JSON.write_text(json.dumps(fallback_sources, indent=2))
        print(f"✅ Fallback sources saved to {OUTPUT_JSON.resolve()}")
    except Exception as e:
        print(f"⚠ Failed to write JSON: {e}")

if __name__ == "__main__":
    main()