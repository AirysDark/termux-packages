#!@TERMUX_PREFIX@/bin/sh
# shellcheck shell=sh
# 01-termux-bootstrap-second-stage-fallback.sh
# Fallback script to run Termux bootstrap second stage if never executed
# This script is automatically removed after a successful run.

(
    # Determine the second-stage lock file path
    LOCK_FILE="@TERMUX_BOOTSTRAP__BOOTSTRAP_SECOND_STAGE_DIR@/@TERMUX_BOOTSTRAP__BOOTSTRAP_SECOND_STAGE_ENTRY_POINT_SUBFILE@.lock"
    ENTRY_POINT="@TERMUX_BOOTSTRAP__BOOTSTRAP_SECOND_STAGE_DIR@/@TERMUX_BOOTSTRAP__BOOTSTRAP_SECOND_STAGE_ENTRY_POINT_SUBFILE@"

    # Only run if the second stage has never been run
    if [ ! -L "$LOCK_FILE" ]; then
        echo "Starting fallback run of Termux bootstrap second stage..."

        # Ensure entry point is executable
        chmod +x "$ENTRY_POINT" || exit $?

        # Run the second stage bootstrap
        "$ENTRY_POINT" || exit $?
    fi

    # Remove this fallback script after execution
    SCRIPT_PATH="@TERMUX__PREFIX__PROFILE_D_DIR@/01-termux-bootstrap-second-stage-fallback.sh"
    rm -f "$SCRIPT_PATH" || exit $?

) || return $?