#!/usr/bin/env bash
# generate-build-sh.sh - Automatically create build.sh for all packages from a tree

set -euo pipefail

# Path to your tree file
TREE_FILE="./packages_tree.txt"

if [ ! -f "$TREE_FILE" ]; then
    echo "ERROR: $TREE_FILE not found."
    exit 1
fi

# Extract package directories from the tree file
# Assumes tree /F /A format
PACKAGE_DIRS=$(grep -oP '^\+---\K[^|]+' "$TREE_FILE" | sort -u)

for PKG in $PACKAGE_DIRS; do
    PKG_DIR="./$PKG"
    BUILD_FILE="$PKG_DIR/build.sh"

    if [ ! -d "$PKG_DIR" ]; then
        echo "Skipping non-existent directory: $PKG_DIR"
        continue
    fi

    if [ -f "$BUILD_FILE" ]; then
        echo "build.sh already exists for $PKG, skipping."
        continue
    fi

    mkdir -p "$PKG_DIR"

    cat <<'EOF' > "$BUILD_FILE"
#!/usr/bin/env bash
TERMUX_PKG_HOMEPAGE=""
TERMUX_PKG_DESCRIPTION=""
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.0.1"
TERMUX_PKG_SRCURL=""
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
    return
}
EOF

    chmod +x "$BUILD_FILE"
    echo "Created build.sh for $PKG"
done

echo "All missing build.sh files have been generated."