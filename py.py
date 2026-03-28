#!/usr/bin/env python3
import os
import re

root_packages_path = os.path.expanduser("~/termux-packages/root-packages")

if not os.path.isdir(root_packages_path):
    print(f"Folder not found: {root_packages_path}")
    exit(1)

x86_64_packages = []

for pkg_dir in os.listdir(root_packages_path):
    pkg_path = os.path.join(root_packages_path, pkg_dir)
    build_sh = os.path.join(pkg_path, "build.sh")
    if os.path.isfile(build_sh):
        with open(build_sh, "r") as f:
            content = f.read()
            # Look for TERMUX_ARCH="x86_64" or absence of exclusions
            arch_match = re.search(r'TERMUX_ARCH\s*=\s*"x86_64"', content)
            excl_match = re.search(r'TERMUX_PKG_EXCLUDED_ARCHES\s*=\s*".*x86_64.*"', content)
            if arch_match or (not excl_match):
                x86_64_packages.append(pkg_dir)

print(f"x86_64 packages found: {len(x86_64_packages)}")
for pkg in sorted(x86_64_packages):
    print("-", pkg)