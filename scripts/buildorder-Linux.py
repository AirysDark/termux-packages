#!/usr/bin/env python3
"""
buildorder-Linux.py - Generate a build order for Linux-native Termux packages
based on build.sh dependencies. Works with glibc-prefixed packages.
"""

import os
import sys
import json
import re
from itertools import filterfalse

# Environment defaults
termux_arch = os.getenv('TERMUX_ARCH', 'x86_64')
termux_global_library = os.getenv('TERMUX_GLOBAL_LIBRARY', 'false')
termux_pkg_library = os.getenv('TERMUX_PACKAGE_LIBRARY', 'glibc')


# -----------------------------
# Utility functions
# -----------------------------
def unique_everseen(iterable, key=None):
    """List unique elements preserving order."""
    seen = set()
    seen_add = seen.add
    if key is None:
        for element in filterfalse(seen.__contains__, iterable):
            seen_add(element)
            yield element
    else:
        for element in iterable:
            k = key(element)
            if k not in seen:
                seen_add(k)
                yield element


def die(msg):
    sys.exit(f"ERROR: {msg}")


def remove_nl_and_quotes(var):
    for char in "\"'\n":
        var = var.replace(char, '')
    return var


def add_prefix_glibc_to_pkgname(name):
    """Append -glibc if not already glibc-prefixed."""
    parts = name.split('-')
    if "glibc" in parts or "glibc32" in parts:
        return name
    if parts[-1] == "static":
        return name.replace("-static", "-glibc-static")
    return name + "-glibc"


def has_prefix_glibc(pkgname):
    parts = pkgname.split('-')
    return "glibc" in parts or "glibc32" in parts


# -----------------------------
# Parsing build.sh
# -----------------------------
def parse_build_file_dependencies(path, vars=("TERMUX_PKG_DEPENDS", "TERMUX_PKG_BUILD_DEPENDS")):
    deps = set()
    with open(path, encoding="utf-8") as f:
        for line in f:
            for var in vars:
                if line.startswith(var):
                    dep_string = remove_nl_and_quotes(line.split('=')[1])
                    for dep in re.split(r',|\|', dep_string):
                        dep = re.sub(r'\(.*?\)', '', dep).strip()
                        # Replace TERMUX_ARCH variable if present
                        dep = dep.replace("${TERMUX_ARCH/_/-}", termux_arch)
                        if dep:
                            deps.add(dep)
    return deps


def parse_build_file_excluded_arches(path):
    arches = set()
    with open(path, encoding="utf-8") as f:
        for line in f:
            if line.startswith(("TERMUX_PKG_EXCLUDED_ARCHES", "TERMUX_SUBPKG_EXCLUDED_ARCHES")):
                arch_str = remove_nl_and_quotes(line.split('=')[1])
                for arch in arch_str.split(','):
                    arches.add(arch.strip())
    return arches


def parse_build_file_variable_bool(path, var):
    with open(path, encoding="utf-8") as f:
        for line in f:
            if line.startswith(var):
                return remove_nl_and_quotes(line.split('=')[-1]).lower() == 'true'
    return False


# -----------------------------
# Package Classes
# -----------------------------
class TermuxPackage:
    def __init__(self, dir_path, fast_build_mode):
        self.dir = dir_path
        self.fast_build_mode = fast_build_mode
        self.name = os.path.basename(dir_path)
        self.pkgs_cache = []

        build_sh_path = os.path.join(dir_path, "build.sh")
        if not os.path.isfile(build_sh_path):
            raise Exception(f"build.sh not found for package '{self.name}'")

        self.deps = parse_build_file_dependencies(build_sh_path)
        self.excluded_arches = parse_build_file_excluded_arches(build_sh_path)
        self.only_installing = parse_build_file_variable_bool(build_sh_path, 'TERMUX_PKG_ONLY_INSTALLING')
        self.subpkgs = []

        # Automatically add glibc suffix if global library setting is true
        if termux_global_library == "true" and termux_pkg_library == "glibc" and not has_prefix_glibc(self.name):
            self.name = add_prefix_glibc_to_pkgname(self.name)

        self.needed_by = set()

    def recursive_dependencies(self, pkgs_map, dir_root=None):
        result = []
        if dir_root is None:
            dir_root = self.dir

        for dep_name in sorted(self.deps):
            if termux_global_library == "true" and termux_pkg_library == "glibc" and not has_prefix_glibc(dep_name):
                dep_name = add_prefix_glibc_to_pkgname(dep_name)
            if dep_name not in self.pkgs_cache:
                self.pkgs_cache.append(dep_name)
                dep_pkg = pkgs_map[dep_name]
                result += dep_pkg.recursive_dependencies(pkgs_map, dir_root)
                result += [dep_pkg]
        return unique_everseen(result)


# -----------------------------
# Read packages from directories
# -----------------------------
def read_packages_from_directories(dirs, fast_build_mode):
    pkgs_map = {}
    all_packages = []

    for package_dir in dirs:
        for pkg_name in sorted(os.listdir(package_dir)):
            dir_path = os.path.join(package_dir, pkg_name)
            if os.path.isfile(os.path.join(dir_path, "build.sh")):
                pkg = TermuxPackage(dir_path, fast_build_mode)
                if termux_arch in pkg.excluded_arches:
                    continue
                if pkg.name in pkgs_map:
                    die(f"Duplicated package: {pkg.name}")
                pkgs_map[pkg.name] = pkg
                all_packages.append(pkg)

    # Populate reverse dependencies
    for pkg in all_packages:
        for dep_name in pkg.deps:
            if dep_name not in pkgs_map:
                die(f"Package {pkg.name} depends on non-existing package {dep_name}")
            dep_pkg = pkgs_map[dep_name]
            dep_pkg.needed_by.add(pkg)

    return pkgs_map


# -----------------------------
# Build order generation
# -----------------------------
def generate_full_buildorder(pkgs_map):
    build_order = []
    leaf_pkgs = [pkg for pkg in pkgs_map.values() if not pkg.deps]
    if not leaf_pkgs:
        die("No package without dependencies - cannot start build")

    pkg_queue = sorted(leaf_pkgs, key=lambda p: p.name)
    visited = set()
    remaining_deps = {pkg.name: set(pkg.deps) for pkg in pkgs_map.values()}

    while pkg_queue:
        pkg = pkg_queue.pop(0)
        if pkg.name in visited:
            continue
        visited.add(pkg.name)
        build_order.append(pkg)

        for other_pkg in sorted(pkg.needed_by, key=lambda p: p.name):
            remaining_deps[other_pkg.name].discard(pkg.name)
            if not remaining_deps[other_pkg.name]:
                pkg_queue.append(other_pkg)

    if set(pkgs_map.values()) != set(build_order):
        die("Cycle detected in dependencies!")

    return build_order


# -----------------------------
# Main
# -----------------------------
def main():
    import argparse

    parser = argparse.ArgumentParser(description="Generate build order for Linux-native packages")
    parser.add_argument("package_dirs", nargs="+", help="Directories containing packages")
    parser.add_argument("-i", action="store_true", help="Fast-build mode (include subpackages)")
    args = parser.parse_args()

    pkgs_map = read_packages_from_directories(args.package_dirs, args.i)
    build_order = generate_full_buildorder(pkgs_map)

    # Print build order with name and directory
    for pkg in build_order:
        print(f"{pkg.name:<30} {pkg.dir}")


if __name__ == "__main__":
    main()