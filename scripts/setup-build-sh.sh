#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# setup-build-sh.sh
# Auto-generate missing build.sh files for Termux packages.
# Ensures proper permissions for update-packages to run.
# =============================================================================

# -----------------------------------------------------------------------------
# Run Python generators for each package type
# -----------------------------------------------------------------------------
echo "🔧 Generating build.sh files for packages..."
if [ -f "./scripts/bin/generate_build_sh.py" ]; then
    python3 ./scripts/bin/generate_build_sh.py
else
    echo "⚠ Warning: ./scripts/bin/generate_build_sh.py not found, skipping packages."
fi

echo "🔧 Generating build.sh files for root-packages..."
if [ -f "./scripts/bin/generate_root_build_sh.py" ]; then
    python3 ./scripts/bin/generate_root_build_sh.py
else
    echo "⚠ Warning: ./scripts/bin/generate_root_build_sh.py not found, skipping root-packages."
fi

echo "🔧 Generating build.sh files for x11-packages..."
if [ -f "./scripts/bin/generate_x11_build_sh.py" ]; then
    python3 ./scripts/bin/generate_x11_build_sh.py
else
    echo "⚠ Warning: ./scripts/bin/generate_x11_build_sh.py not found, skipping x11-packages."
fi

# -----------------------------------------------------------------------------
# Ensure all build.sh scripts are executable
# -----------------------------------------------------------------------------
echo "🔑 Setting executable permissions for all build.sh scripts..."

find packages root-packages x11-packages -type f -name "build.sh" -exec chmod +x {} \;

echo "✅ build.sh generation and permission setup completed."