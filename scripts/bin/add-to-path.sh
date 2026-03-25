#!/usr/bin/env bash
##
## bin-path.sh - Source this script to make the 'bin' directory available in $PATH
## Only works in Bash
##

# Ensure the script is sourced from Bash
if [ -z "${BASH:-}" ]; then
    echo "ERROR: Cannot source because your shell is not Bash!" >&2
else
    # Determine the absolute path of the 'bin' directory
    TERMUX_BINPATH=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

    # Prepend to PATH if not already included
    if [[ ":$PATH:" != *":$TERMUX_BINPATH:"* ]]; then
        PATH="${TERMUX_BINPATH}:${PATH}"
        export PATH
    fi

    echo "✅ Scripts from '$TERMUX_BINPATH' are now available in your \$PATH."

    # Clean up temporary variable
    unset TERMUX_BINPATH
fi