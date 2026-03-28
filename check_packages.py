#!/usr/bin/env python3
import subprocess
from pathlib import Path
import json
import requests
import hashlib
from urllib.parse import quote
from config import FALLBACK_URLS
from utils import get_sha256

# === Packages to check ===
PACKAGES = [
    "libnetfilter-queue", "libnfnetlink", "hwinfo", "v4l-utils", "iw",
    "libcryptsetup", "hdparm", "docker", "gptfdisk", "thin-provisioning-tools",
    "nexttrace", "frida", "wpa-supplicant", "iodine", "libfuse2", "termshark",
    "btop", "erofs-utils", "below", "mtr", "ipset", "tshark", "i2c-tools",
    "gocryptfs", "ethtool", "libccid", "nfs-utils", "minikube", "vlan",
    "bindfs", "tcpdump", "authbind", "testdisk", "runc", "macchanger", "lvm2",
    "wush", "hping3", "tcplay-veracrypt", "libaio", "usbutils", "hw-probe",
    "libx86emu", "wimlib"
]

OUTPUT_FILE = Path("package_check_results.txt")
SOURCE_FILE = Path("package_fallback_sources.json")

# === GitHub / GitLab token support ===
GITHUB_HEADERS = {}
GITLAB_HEADERS = {}

github_token_file = Path("github_token.json")
if github_token_file.exists():
    try:
        data = json.loads(github_token_file.read_text())
        token = data.get("token")
        if token:
            GITHUB_HEADERS = {"Authorization": f"token {token}"}
    except Exception as e:
        print(f"⚠ Failed to read GitHub token: {e}")

gitlab_token_file = Path("gitlab_token.json")
if gitlab_token_file.exists():
    try:
        data = json.loads(gitlab_token_file.read_text())
        token = data.get("token")
        if token:
            GITLAB_HEADERS = {"Authorization": f"Bearer {token}"}
    except Exception as e:
        print(f"⚠ Failed to read GitLab token: {e}")

# === Helper to compute SHA256 for a URL ===
def compute_sha256(url: str):
    try:
        r = requests.get(url, stream=True, timeout=30)
        r.raise_for_status()
        hash_sha256 = hashlib.sha256()
        for chunk in r.iter_content(chunk_size=8192):
            if chunk:
                hash_sha256.update(chunk)
        return hash_sha256.hexdigest()
    except Exception as e:
        print(f"⚠ Failed to compute SHA256 for {url}: {e}")
        return None

# === Check package availability in apt ===
def check_package(pkg_name: str):
    """Check if a package is available in apt repositories."""
    try:
        # Exact match search
        result = subprocess.run(
            ["apt-cache", "search", f"^{pkg_name}$"],
            capture_output=True,
            text=True,
            check=True
        )
        lines = result.stdout.strip().splitlines()
        if lines:
            return "FOUND", lines[0].split()[0]

        # Fuzzy match
        result = subprocess.run(
            ["apt-cache", "search", pkg_name],
            capture_output=True,
            text=True,
            check=True
        )
        lines = result.stdout.strip().splitlines()
        if lines:
            return "PARTIAL", lines[0].split()[0]

        return "MISSING", None
    except subprocess.CalledProcessError as e:
        return "ERROR", str(e)

# === GitHub releases search ===
def github_releases(pkg_name):
    versions = []
    search_url = f"https://api.github.com/search/repositories?q={quote(pkg_name)}+language:C"
    try:
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
            if tar_url and version:
                versions.append((tar_url, None, version))
    except Exception as e:
        print(f"⚠ GitHub failed for {pkg_name}: {e}")
    return versions

# === PyPI releases (Python packages only) ===
def is_python_package(pkg_name):
    return pkg_name.startswith("python-") or pkg_name in ["requests", "numpy", "torchaudio"]

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
        print(f"⚠ PyPI failed for {pkg_name}: {e}")
    return versions

# === Fallback user-defined URLs ===
def fallback_release(pkg_name):
    versions = []
    if pkg_name in FALLBACK_URLS:
        for entry in FALLBACK_URLS[pkg_name]:
            url, sha, version = entry
            if not sha:
                print(f"⚡ Computing SHA256 for {pkg_name} from {url}...")
                sha = compute_sha256(url)
            versions.append((url, sha, version))
    return versions

# === Main workflow ===
def main():
    results = []
    fallback_sources = {}

    print("Checking package availability in apt repos...\n")

    for pkg in PACKAGES:
        status, match = check_package(pkg)
        if status == "FOUND":
            line = f"FOUND    : {pkg} (`{match}`)"
        elif status == "PARTIAL":
            line = f"PARTIAL  : {pkg} (~`{match}`)"
        elif status == "MISSING":
            line = f"MISSING  : {pkg}"
            fallback_versions = fallback_release(pkg)
            if fallback_versions:
                fallback_sources[pkg] = fallback_versions
        else:
            line = f"ERROR    : {pkg} ({match})"
        print(line)
        results.append(line)

    # Save text results
    try:
        OUTPUT_FILE.write_text("\n".join(results))
        print(f"\n✅ Results saved to {OUTPUT_FILE.resolve()}")
    except Exception as e:
        print(f"⚠ Failed to write results to file: {e}")

    # Save JSON fallback sources
    if fallback_sources:
        try:
            SOURCE_FILE.write_text(json.dumps(fallback_sources, indent=2))
            print(f"✅ Fallback sources saved to {SOURCE_FILE.resolve()}")
        except Exception as e:
            print(f"⚠ Failed to write fallback sources: {e}")

if __name__ == "__main__":
    main()