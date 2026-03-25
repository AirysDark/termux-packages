#!@TERMUX_PREFIX@/bin/bash
# shellcheck shell=bash
# termux-bootstrap-second-stage.sh
# Second-stage bootstrap script for Termux.
# Handles post-install configuration of extracted packages.

export TERMUX_PREFIX="@TERMUX_PREFIX@"
export TERMUX_PACKAGE_MANAGER="@TERMUX_PACKAGE_MANAGER@"
export TERMUX_PACKAGE_ARCH="@TERMUX_PACKAGE_ARCH@"

TERMUX__USER_ID___N="@TERMUX_ENV__S_TERMUX@USER_ID"
TERMUX__USER_ID="${!TERMUX__USER_ID___N:-}"

# Logging helpers
log()       { echo "[*]" "$@"; }
log_error() { echo "[*]" "$@" 1>&2; }

show_help() {
	cat <<'HELP_EOF'
@TERMUX_BOOTSTRAP__BOOTSTRAP_SECOND_STAGE_ENTRY_POINT_SUBFILE@ runs the second stage
of Termux bootstrap installation.

Usage:
  @TERMUX_BOOTSTRAP__BOOTSTRAP_SECOND_STAGE_ENTRY_POINT_SUBFILE@

Options:
  [ -h | --help ]    Display this help screen

Description:
  The second stage runs postinst scripts of all packages extracted during
  the bootstrap. Running it more than once is unsafe and prevented by a
  lock file. Force rerun only by deleting the lock file manually.
HELP_EOF
}

main() {
	if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
		show_help
		return 0
	else
		run_bootstrap_second_stage "$@"
		local ret=$?
		if [ $ret -eq 64 ]; then
			echo
			show_help
		fi
		return $ret
	fi
}

run_bootstrap_second_stage() {
	ensure_running_with_termux_uid || return $?

	local LOCK_FILE="@TERMUX_BOOTSTRAP__BOOTSTRAP_SECOND_STAGE_DIR@/@TERMUX_BOOTSTRAP__BOOTSTRAP_SECOND_STAGE_ENTRY_POINT_SUBFILE@.lock"
	local ENTRY_POINT="@TERMUX_BOOTSTRAP__BOOTSTRAP_SECOND_STAGE_DIR@/@TERMUX_BOOTSTRAP__BOOTSTRAP_SECOND_STAGE_ENTRY_POINT_SUBFILE@"

	local output
	output="$(ln -s "$ENTRY_POINT" "$LOCK_FILE" 2>&1)"
	local ret=$?
	if [ $ret -ne 0 ]; then
		if [ $ret -eq 1 ] && [[ "$output" == *"File exists"* ]]; then
			log "The second stage has already been run. Remove '$LOCK_FILE' to force rerun (not recommended)."
			return 0
		else
			log_error "Failed to create lock file at '$LOCK_FILE': $output"
			warn_if_process_killed "$ret" "ln"
			return $ret
		fi
	fi

	log "Running termux bootstrap second stage..."
	run_bootstrap_second_stage_inner || return $?
	log "Bootstrap second stage completed successfully"
	return 0
}

run_bootstrap_second_stage_inner() {
	log "Running postinst maintainer scripts"
	run_package_postinst_maintainer_scripts || return $?
	return 0
}

run_package_postinst_maintainer_scripts() {
	if [ "$TERMUX_PACKAGE_MANAGER" = "apt" ]; then
		for script_path in "${TERMUX_PREFIX}/var/lib/dpkg/info/"*.postinst; do
			local pkg_name="${script_path##*/}"
			pkg_name="${pkg_name::-9}" # remove .postinst
			log "Running '$pkg_name' package postinst"
			chmod u+x "$script_path" || return $?
			(
				cd /
				export DPKG_MAINTSCRIPT_PACKAGE="$pkg_name"
				export DPKG_MAINTSCRIPT_ARCH="$TERMUX_PACKAGE_ARCH"
				export DPKG_MAINTSCRIPT_NAME="postinst"
				"$script_path" configure || exit $?
			) || return $?
		done
	elif [ "$TERMUX_PACKAGE_MANAGER" = "pacman" ]; then
		for script_path in "${TERMUX_PREFIX}/var/lib/pacman/local/"*/install; do
			local pkg_dir="${script_path::-8}"
			local pkg_basename="${pkg_dir##*/}"
			log "Running '$pkg_basename' package post_install"
			(
				cd /
				unset -f post_install || exit $?
				source "$script_path" || return $?
				if [[ "$(type -t post_install 2>/dev/null)" == "function" ]]; then
					post_install "$pkg_basename" || return $?
				fi
			) || return $?
		done
	fi
	return 0
}

ensure_running_with_termux_uid() {
	local uid
	uid="$(id -u 2>&1)" || { log_error "$uid"; return 1; }
	if [[ ! "$uid" =~ ^[0-9]+$ ]]; then
		log_error "Invalid uid: $uid"; return 1
	fi
	if [[ -n "$TERMUX__UID" ]] && [[ "$uid" != "$TERMUX__UID" ]]; then
		log_error "Script must run as TERMUX__UID ($TERMUX__UID), got uid $uid"
		return 1
	fi
	return 0
}

warn_if_process_killed() {
	local ret="${1:-}" cmd="${2:-}"
	if [ "$ret" = "137" ]; then
		log_error "Command '$cmd' was killed by SIGKILL (9). May be Android security policy."
	fi
}

# Only run if executed directly under Bash
if [ -n "${BASH_VERSION:-}" ]; then
	if (return 0 2>/dev/null); then
		echo "${0##*/} cannot be sourced, use execution." 1>&2
		return 64
	else
		main "$@"
		exit $?
	fi
else
	(echo "${0##*/} must be run with bash."; exit 64)
fi