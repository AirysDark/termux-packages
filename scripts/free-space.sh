#!/usr/bin/env bash
# =============================================================================
# free-space.sh
# Safely clears unnecessary packages and directories to free space in CI.
# Compatible with Ubuntu 22.04 (Jammy)
# =============================================================================

set -euo pipefail

LOG_FILE="/tmp/free_space.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "🚀 Starting free-space cleanup at $(date)" | tee -a "$LOG_FILE"

# -----------------------------------------------------------------------------
# Safety check: only run in CI
# -----------------------------------------------------------------------------
if [ "${CI-false}" != "true" ]; then
    echo "❌ ERROR: Not running in CI. Exiting without deleting system files!" | tee -a "$LOG_FILE"
    exit 1
fi

# -----------------------------------------------------------------------------
# Function: safe purge of packages
# -----------------------------------------------------------------------------
safe_purge() {
    pkg="$1"
    if apt-cache show "$pkg" >/dev/null 2>&1; then
        if dpkg -l | grep -q "^ii  $pkg "; then
            echo "Removing package: $pkg" | tee -a "$LOG_FILE"
            sudo apt purge -yq "$pkg" >> "$LOG_FILE" 2>&1 || \
                echo "⚠ Failed to purge $pkg" | tee -a "$LOG_FILE"
        else
            echo "Package $pkg not installed, skipping." | tee -a "$LOG_FILE"
        fi
    else
        echo "Package $pkg not found in repositories, skipping." | tee -a "$LOG_FILE"
    fi
}

# -----------------------------------------------------------------------------
# Enable multiarch and update apt
# -----------------------------------------------------------------------------
echo "Updating package lists..." | tee -a "$LOG_FILE"
sudo dpkg --add-architecture i386
sudo apt-get update -y >> "$LOG_FILE" 2>&1
sudo apt-get upgrade -y >> "$LOG_FILE" 2>&1

# -----------------------------------------------------------------------------
# Purge large/unneeded packages by name patterns (dynamic)
# -----------------------------------------------------------------------------
echo "Purging large/unneeded packages..." | tee -a "$LOG_FILE"
PATTERNS=(
    'mecab' 'linux-azure-tools-' 'aspnetcore' 'liblldb-' 'netstandard-' 'llvm' 'clang' \
    'gcc-12' 'gcc-13' 'cpp-' 'g++-' 'temurin-' 'gfortran-' 'mysql-' 'google-cloud-cli' \
    'postgresql-' 'cabal-' 'dotnet-' 'ghc-' 'mongodb-' 'libmono' 'mesa-' 'ant' 'liblua' \
    'python3' 'grub2-' 'grub-' 'shim-signed'
)

for pattern in "${PATTERNS[@]}"; do
    pkgs=$(dpkg -l | awk '/^ii/ {print $2}' | grep -P "$pattern" || true)
    for pkg in $pkgs; do
        safe_purge "$pkg"
    done
done

# -----------------------------------------------------------------------------
# Purge specific large known packages
# -----------------------------------------------------------------------------
echo "Purging specific known large packages..." | tee -a "$LOG_FILE"
sudo apt purge -yq \
    snapd \
    kubectl \
    podman \
    mercurial-common \
    git-lfs \
    skopeo \
    buildah \
    vim \
    python3-botocore \
    azure-cli \
    powershell \
    shellcheck \
    firefox >> "$LOG_FILE" 2>&1 || \
    echo "⚠ Some packages could not be removed, check log." | tee -a "$LOG_FILE"

# -----------------------------------------------------------------------------
# Remove large directories that CI does not need
# -----------------------------------------------------------------------------
echo "Removing unnecessary directories..." | tee -a "$LOG_FILE"
DIRS=(
    /opt/ghc /opt/az /opt/hostedtoolcache /opt/actionarchivecache /opt/runner-cache
    /opt/pipx /usr/share/dotnet /usr/share/swift /usr/share/miniconda /usr/share/az_*
    /usr/share/gradle-* /usr/share/java /home/runner/.rustup /etc/skel /home/packer
    /home/linuxbrew /usr/local /usr/src
    "$AGENT_TOOLSDIRECTORY" /var/lib/containerd/io.containerd.content.v1.content
)

for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "Deleting directory: $dir" | tee -a "$LOG_FILE"
        sudo rm -rf "$dir" >> "$LOG_FILE" 2>&1 || echo "⚠ Could not delete $dir" | tee -a "$LOG_FILE"
    fi
done

# -----------------------------------------------------------------------------
# Autoremove and clean apt
# -----------------------------------------------------------------------------
echo "Running apt autoremove and clean..." | tee -a "$LOG_FILE"
sudo apt autoremove -yq >> "$LOG_FILE" 2>&1
sudo apt clean >> "$LOG_FILE" 2>&1

echo "✅ Free-space cleanup completed at $(date)" | tee -a "$LOG_FILE"