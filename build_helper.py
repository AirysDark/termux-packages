#!/usr/bin/env python3
import os
import subprocess
import sys

# ==========================================================
# build_helper.py - run a package's build.sh and capture logs/errors
# ==========================================================

# -----------------------------
# Package path configuration
# -----------------------------
# Accept path as first argument; default to cwd if none provided
PACKAGE_DIR = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.getcwd()

# Override to always be inside root-packages folder if relative
if not os.path.isabs(PACKAGE_DIR):
    PACKAGE_DIR = os.path.join("/root/termux-packages/root-packages", PACKAGE_DIR)

# Build script path
BUILD_SCRIPT = os.path.join(PACKAGE_DIR, "build.sh")

# Log and error file paths inside the package folder
LOG_FILE = os.path.join(PACKAGE_DIR, "build.log")
ERROR_FILE = os.path.join(PACKAGE_DIR, "build.error")

# -----------------------------
# Sanity checks
# -----------------------------
if not os.path.isdir(PACKAGE_DIR):
    print(f"? Error: Package folder not found: {PACKAGE_DIR}")
    sys.exit(1)

if not os.path.isfile(BUILD_SCRIPT):
    print(f"? Error: build.sh not found in {PACKAGE_DIR}")
    sys.exit(1)

# -----------------------------
# Run the build script
# -----------------------------
print(f"? Building package in {PACKAGE_DIR}...")
print(f"? Logs will be written to {LOG_FILE}")
print(f"? Errors will be written to {ERROR_FILE}")

# Open log and error files
with open(LOG_FILE, "w") as logf, open(ERROR_FILE, "w") as errf:
    process = subprocess.Popen(
        ["/bin/bash", BUILD_SCRIPT],
        cwd=PACKAGE_DIR,
        stdout=logf,
        stderr=errf
    )
    process.wait()
    retcode = process.returncode

# -----------------------------
# Report result
# -----------------------------
if retcode == 0:
    print(f"? Build successful! Log: {LOG_FILE}")
    # Remove error file if it existed from previous builds
    if os.path.isfile(ERROR_FILE):
        os.remove(ERROR_FILE)
else:
    print(f"? Build failed! See {ERROR_FILE} for errors, {LOG_FILE} for logs.")
