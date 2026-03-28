#!/usr/bin/env python3
import json
import os
from pathlib import Path

# === BASE DIRECTORIES ===
BASE_DIR = Path(__file__).resolve().parent
PACKAGE_DIRS = [
    BASE_DIR / "packages",
    BASE_DIR / "root-packages",
    BASE_DIR / "x11-packages"
]

# === LOGGING ===
LOG_FILE = BASE_DIR / "termux_fix_builds.log"

# === RETRY CONFIGURATION ===
RETRY_COUNT = 3
RETRY_DELAY = 2  # seconds

# === BUILD OVERRIDE ===
OVERRIDE = True

# === GITHUB TOKEN SUPPORT ===
TOKEN_FILE = BASE_DIR / "github_token.json"
GITHUB_TOKEN = None
if TOKEN_FILE.exists():
    try:
        data = json.loads(TOKEN_FILE.read_text())
        GITHUB_TOKEN = data.get("token")
    except Exception as e:
        print(f"⚠ Failed to read GitHub token: {e}")

GITHUB_HEADERS = {"Authorization": f"token {GITHUB_TOKEN}"} if GITHUB_TOKEN else {}

# === SHA256 SOURCE ===
SHA256_JSON = BASE_DIR / "root-packages-sha256.json"
if SHA256_JSON.exists():
    try:
        ROOT_SHA256 = json.loads(SHA256_JSON.read_text())
    except Exception as e:
        print(f"[!] Failed to load SHA256 JSON: {e}")
        ROOT_SHA256 = {}
else:
    ROOT_SHA256 = {}

# === FALLBACK URLS (SHA256 removed, all preserved) ===
FALLBACK_URLS = {
    "wpa-supplicant": [("https://w1.fi/releases/wpa_supplicant-2.11.tar.gz", None, "2.11")],
    "iodine": [("https://github.com/yarrick/iodine/archive/refs/tags/v0.7.0.tar.gz", None, "0.7.0")],
    "libfuse2": [("https://github.com/libfuse/libfuse/releases/download/fuse-2.9.9/fuse-2.9.9.tar.gz", None, "2.9.9")],
    "termshark": [("https://github.com/gcla/termshark/archive/refs/tags/v2.4.0.tar.gz", None, "2.4.0")],
    "tshark": [("https://www.wireshark.org/download/src/all-versions/wireshark-4.6.4.tar.xz", None, "4.6.4")],
    "i2c-tools": [("https://ftp.iij.ad.jp/pub/linux/kernel/software/utils/i2c-tools/i2c-tools-4.4.tar.xz", None, "4.4")],
    "ethtool": [("https://ftp.debian.org/debian/pool/main/e/ethtool/ethtool_6.19.orig.tar.xz", None, "6.19")],
    "authbind": [("https://deb.debian.org/debian/pool/main/a/authbind/authbind_2.2.0.tar.gz", None, "2.2.0")],
    "tcpdump": [("https://www.tcpdump.org/release/tcpdump-4.99.5.tar.gz", None, "4.99.5")],
    "btop": [("https://api.github.com/repos/aristocratos/btop/tarball/v1.4.6", None, "v1.4.6")],
    "nfs-utils": [("https://www.kernel.org/pub/linux/utils/nfs-utils/2.8.6/nfs-utils-2.8.6.tar.xz", None, "2.8.6")],
    "erofs-utils": [("https://github.com/erofs/erofs-utils/archive/refs/tags/v1.9.1.tar.gz", None, "1.9.1")],
    "below": [("https://github.com/erofs/erofs-utils/archive/refs/tags/v1.7.1.tar.gz", None, "1.1")],
    "gocryptfs": [("https://api.github.com/repos/rfjakob/gocryptfs/tarball/v2.6.1", None, "v2.6.1")],
    "libccid": [("https://ccid.apdu.fr/files/ccid-1.6.2.tar.xz", None, "1.6.2")],
    "minikube": [("https://github.com/kubernetes/minikube/archive/refs/tags/v1.29.0.tar.gz", None, "1.29.0")],
    "vlan": [("https://archive.debian.org/debian/pool/main/v/vlan/vlan_2.0.5.tar.xz", None, "1.0.1")],
    "bindfs": [("https://bindfs.org/downloads/bindfs-1.18.4.tar.gz", None, "1.14.0")],
    "tcplay-veracrypt": [("https://github.com/bwalex/tc-play/archive/refs/tags/v3.3.tar.gz", None, "3.3-github")],
    "testdisk": [("https://www.cgsecurity.org/testdisk-7.2.tar.bz2", None, "7.2")],
    "runc": [("https://github.com/opencontainers/runc/archive/refs/tags/v1.1.9.tar.gz", None, "1.1.9")],
    "macchanger": [("https://github.com/alobbs/macchanger/archive/refs/tags/1.7.0.tar.gz", None, "1.8.4")],
    "lvm2": [("https://sourceware.org/pub/lvm2/releases/LVM2.2.03.38.tgz", None, "2.03.14")],
    "wush": [("https://github.com/coder/wush/archive/refs/tags/v0.4.1.tar.gz", None, "0.4.1")],
    "hping3": [("https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/hping3/3.a2.ds2-10.1/hping3_3.a2.ds2.orig.tar.gz", None, "3.0.0")],
    "libaio": [("https://pagure.io/libaio/archive/libaio-0.3.113/libaio-0.3.113.tar.gz", None, "0.3.113")],
    "usbutils": [("https://mirrors.edge.kernel.org/pub/linux/utils/usb/usbutils/usbutils-009.tar.gz", None, "009")],
    "hw-probe": [("https://github.com/linuxhw/hw-probe/archive/refs/tags/1.6.5.tar.gz", None, "1.6.5")],
    "libx86emu": [("https://deb.debian.org/debian/pool/main/libx/libx86emu/libx86emu_3.5.orig.tar.gz", None, "0.7.5")],
    "wimlib": [("https://wimlib.net/downloads/wimlib-1.14.5.tar.gz", None, "1.14.5")],
    "libnetfilter-queue": [("https://www.netfilter.org/pub/libnetfilter_queue/libnetfilter_queue-1.0.3.tar.bz2", None, "1.0.3")],
    "libnfnetlink": [("https://netfilter.org/projects/libnfnetlink/files/libnfnetlink-1.0.1.tar.bz2", None, "1.0.1")],
    "hwinfo": [("https://deb.debian.org/debian/pool/main/h/hwinfo/hwinfo_21.82.orig.tar.gz", None, "21.82")],
    "v4l-utils": [("https://www.linuxtv.org/downloads/v4l-utils/v4l-utils-1.22.0.tar.bz2", None, "1.22.0")],
    "iw": [("https://www.kernel.org/pub/software/network/iw/iw-5.9.tar.xz", None, "5.9")],
    "libcryptsetup": [("https://gitlab.com/cryptsetup/cryptsetup/-/archive/v2.6.0/cryptsetup-v2.6.0.tar.gz", None, "2.6.0")],
    "hdparm": [("https://raw.githubusercontent.com/AirysDark/Tremux-rootpackages-linux/main/hdparm-9.65.tar.gz", None, "9.65")],
    "docker": [("https://download.docker.com/linux/static/stable/x86_64/docker-24.0.2.tgz", None, "24.0.2")],
    "gptfdisk": [("https://downloads.sourceforge.net/gptfdisk/1.0.10/gptfdisk-1.0.10.tar.gz", None, "1.0.10")],
    "thin-provisioning-tools": [("https://deb.debian.org/debian/pool/main/t/thin-provisioning-tools/thin-provisioning-tools_1.1.0.orig.tar.xz", None, "1.1.0")],
    "nexttrace": [("https://github.com/nxtrace/NTrace-core/archive/refs/tags/v1.6.1.tar.gz", None, "1.6.1")],
    "frida": [("https://github.com/frida/frida/archive/refs/tags/17.8.3.tar.gz", None, "17.8.3")],
    "mtr": [("https://www.bitwizard.nl/mtr/files/mtr-0.96.tar.gz", None, "0.96")],
    "ipset": [("https://www.netfilter.org/pub/ipset/ipset-7.24.tar.bz2", None, "7.24")]
}

# === Helper: deduplicate versions ===
def dedupe_versions(version_list):
    seen_urls = set()
    deduped = []
    for url, sha, version in version_list:
        if url not in seen_urls:
            deduped.append((url, sha, version))
            seen_urls.add(url)
    return deduped

# === Helper functions for per-folder JSON files ===
def get_cache_file(pkg_dir: Path) -> Path:
    return pkg_dir / f"{pkg_dir.name}-cache.json"

def get_missing_file(pkg_dir: Path) -> Path:
    return pkg_dir / f"{pkg_dir.name}-missing.json"

# === BUILD.SH TEMPLATE ===
BUILD_SH_TEMPLATE = """#!/bin/bash
set -e

# Build script for {package_name} version {version}

echo "Building {package_name} version {version}..."
export TERMUX_PKG_SRCDIR=$PWD
export TERMUX_PKG_VERSION="{version}"

if [ -f configure ]; then
    ./configure --prefix=$PREFIX
fi
make -j$(nproc)
make install

echo "Build completed for {package_name} version {version}."
"""