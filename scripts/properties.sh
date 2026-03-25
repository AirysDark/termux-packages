# shellcheck shell=bash
# shellcheck disable=SC2034

# XXX: This file is sourced by repology-updater script
# Avoid executing commands outside coreutils and avoid sourcing other build scripts.

if [ -z "${BASH_VERSION:-}" ]; then
    echo "The 'properties.sh' script must be run from a 'bash' shell."; return 64 2>/dev/null || exit 64
fi

### Termux properties validation setup ###

unset __TERMUX_BUILD_PROPS__VARIABLES_VALIDATOR_ACTIONS_MAP
declare -A __TERMUX_BUILD_PROPS__VARIABLES_VALIDATOR_ACTIONS_MAP=()

unset __TERMUX_BUILD_PROPS__VARIABLES_VALIDATOR_ACTIONS_VARIABLE_NAMES
declare -a __TERMUX_BUILD_PROPS__VARIABLES_VALIDATOR_ACTIONS_VARIABLE_NAMES=()

__TERMUX_BUILD_PROPS__VALIDATE_PATHS_MAX_LEN="true"
__TERMUX_BUILD_PROPS__VALIDATE_TERMUX_PREFIX_USR_MERGE_FORMAT="true"

__termux_build_props__add_variables_validator_actions() {
    if [ $# -ne 2 ]; then
        echo "Invalid argument count '$#' to '__termux_build_props__add_variables_validator_actions'." 1>&2
        return 1
    fi
    local variable_name="$1"
    local validator_actions="$2"

    if [[ ! "$variable_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "The variable_name '$variable_name' passed is not a valid shell variable name." 1>&2
        return 1
    fi

    if [[ " ${__TERMUX_BUILD_PROPS__VARIABLES_VALIDATOR_ACTIONS_VARIABLE_NAMES[*]} " != *" $variable_name "* ]]; then
        __TERMUX_BUILD_PROPS__VARIABLES_VALIDATOR_ACTIONS_VARIABLE_NAMES+=("$variable_name")
    fi

    __TERMUX_BUILD_PROPS__VARIABLES_VALIDATOR_ACTIONS_MAP["$variable_name"]+="$validator_actions"
}

### Regex definitions ###

TERMUX_REGEX__ABSOLUTE_PATH='^(/[^/]+)+$'
TERMUX_REGEX__RELATIVE_PATH='^[^/]+(/[^/]+)*$'
TERMUX_REGEX__ROOTFS_OR_ABSOLUTE_PATH='^((/)|((/[^/]+)+))$'
TERMUX_REGEX__SAFE_ABSOLUTE_PATH='^(/[a-zA-Z0-9+,.=_-]+)+$'
TERMUX_REGEX__SAFE_RELATIVE_PATH='^[a-zA-Z0-9+,.=_-]+(/[a-zA-Z0-9+,.=_-]+)*$'
TERMUX_REGEX__SAFE_ROOTFS_OR_ABSOLUTE_PATH='^((/)|((/[a-zA-Z0-9+,.=_-]+)+))$'
TERMUX_REGEX__SINGLE_OR_DOUBLE_DOT_CONTAINING_PATH='((^\./)|(^\.\./)|(/\.$)|(/\.\.$)|(/\./)|(/\.\./))'
TERMUX_REGEX__INVALID_TERMUX_ROOTFS_PATHS='^((/bin(/.*)?)|(/boot(/.*)?)|(/dev(/.*)?)|(/etc(/.*)?)|(/home)|(/lib(/.*)?)|(/lib[^/]+(/.*)?)|(/media)|(/mnt)|(/opt)|(/proc(/.*)?)|(/root)|(/run(/.*)?)|(/sbin(/.*)?)|(/srv(/.*)?)|(/sys(/.*)?)|(/tmp(/.*)?)|(/usr)|(/usr/local)|(((/usr/)|(/usr/local/))((bin)|(games)|(include)|(lib)|(libexec)|(lib[^/]+)|(sbin)|(share)|(src)|(X11R6))(/.*)?)|(/var(/.*)?)|(/bin.usr-is-merged)|(/lib.usr-is-merged)|(/sbin.usr-is-merged)|(/.dockerinit)|(/.dockerenv))$'
TERMUX_REGEX__INVALID_TERMUX_HOME_PATHS='^((/)|(/bin(/.*)?)|(/boot(/.*)?)|(/dev(/.*)?)|(/etc(/.*)?)|(/lib(/.*)?)|(/lib[^/]+(/.*)?)|(/media)|(/mnt)|(/opt)|(/proc(/.*)?)|(/root)|(/run(/.*)?)|(/sbin(/.*)?)|(/srv(/.*)?)|(/sys(/.*)?)|(/tmp(/.*)?)|(/usr(/.*)?)|(/var(/.*)?)|(/bin.usr-is-merged)|(/lib.usr-is-merged)|(/sbin.usr-is-merged)|(/.dockerinit)|(/.dockerenv))$'
TERMUX_REGEX__INVALID_TERMUX_PREFIX_PATHS="$TERMUX_REGEX__INVALID_TERMUX_ROOTFS_PATHS"
TERMUX_REGEX__UNSIGNED_INT='^[0-9]+$'
TERMUX_REGEX__APP_PACKAGE_NAME="^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$"
TERMUX_REGEX__APP_DATA_DIR_PATH='^(((/data/data)|(/data/user/[0-9]+)|(/mnt/expand/[^/]+/user/[0-9]+))/[^/]+)$'

### Core Termux variables ###

TERMUX__NAME="Termux"
TERMUX__LNAME="${TERMUX__NAME,,}"
TERMUX__UNAME="${TERMUX__NAME^^}"
TERMUX__INTERNAL_NAME="termux"
TERMUX__INTERNAL_NAME_REGEX="^[a-z0-9][a-z0-9_-]+[a-z0-9]$"
TERMUX__INTERNAL_NAME___MAX_LEN=7

TERMUX__REPOS_HOST_ORG_NAME="termux"
TERMUX__REPOS_HOST_ORG_URL="https://github.com/$TERMUX__REPOS_HOST_ORG_NAME"

TERMUX_APP__PACKAGE_NAME="com.termux"
__termux_build_props__add_variables_validator_actions "TERMUX_APP__PACKAGE_NAME" "app_package_name"

TERMUX_APP__DATA_DIR="/data/data/$TERMUX_APP__PACKAGE_NAME"
__termux_build_props__add_variables_validator_actions "TERMUX_APP__DATA_DIR" "safe_absolute_path"
TERMUX_APP__DATA_DIR___MAX_LEN=69

TERMUX__PROJECT_SUBDIR="$TERMUX__INTERNAL_NAME"
__termux_build_props__add_variables_validator_actions "TERMUX__PROJECT_SUBDIR" "safe_relative_path"
TERMUX__PROJECT_DIR="$TERMUX_APP__DATA_DIR/$TERMUX__PROJECT_SUBDIR"
__termux_build_props__add_variables_validator_actions "TERMUX__PROJECT_DIR" "safe_absolute_path"

TERMUX__CORE_SUBDIR="core"
TERMUX__CORE_DIR="$TERMUX__PROJECT_DIR/$TERMUX__CORE_SUBDIR"
__termux_build_props__add_variables_validator_actions "TERMUX__CORE_DIR" "safe_absolute_path"

TERMUX__APPS_SUBDIR="app"
TERMUX__APPS_DIR="$TERMUX__PROJECT_DIR/$TERMUX__APPS_SUBDIR"
__termux_build_props__add_variables_validator_actions "TERMUX__APPS_DIR" "safe_absolute_path"
TERMUX__APPS_DIR___MAX_LEN=84
TERMUX__APPS_DIR_BY_IDENTIFIER_SUBDIR="i"
TERMUX__APPS_DIR_BY_IDENTIFIER="$TERMUX__APPS_DIR/$TERMUX__APPS_DIR_BY_IDENTIFIER_SUBDIR"
TERMUX__APPS_APP_IDENTIFIER_REGEX="^[a-zA-Z0-9]{3,}([._-][a-zA-Z0-9]+)*$"
TERMUX__APPS_APP_IDENTIFIER___MAX_LEN=10
TERMUX__APPS_DIR_BY_UID_SUBDIR="u"
TERMUX__APPS_DIR_BY_UID="$TERMUX__APPS_DIR/$TERMUX__APPS_DIR_BY_UID_SUBDIR"
TERMUX__APPS_APP_UID_REGEX="^[1-9][0-9]{4,8}$"
TERMUX__APPS_APP_UID___MAX_LEN=9

TERMUX__ROOTFS_ID="0"
__termux_build_props__add_variables_validator_actions "TERMUX__ROOTFS_ID" "unsigned_int"
TERMUX__ROOTFS_SUBDIR="files"
__termux_build_props__add_variables_validator_actions "TERMUX__ROOTFS_SUBDIR" "allow_unset_value safe_relative_path"
TERMUX__ROOTFS="$TERMUX_APP__DATA_DIR/$TERMUX__ROOTFS_SUBDIR"
__termux_build_props__add_variables_validator_actions "TERMUX__ROOTFS" "safe_rootfs_or_absolute_path invalid_termux_rootfs_paths"
TERMUX__HOME_SUBDIR="home"
[[ "$TERMUX__ROOTFS" != "/" ]] && TERMUX__HOME="$TERMUX__ROOTFS/$TERMUX__HOME_SUBDIR" || TERMUX__HOME="/$TERMUX__HOME_SUBDIR"
__termux_build_props__add_variables_validator_actions "TERMUX__HOME" "safe_absolute_path invalid_termux_home_paths path_under_termux_rootfs"

TERMUX__PREFIX_SUBDIR="usr"
[[ "$TERMUX__ROOTFS" != "/" ]] && TERMUX__PREFIX="$TERMUX__ROOTFS${TERMUX__PREFIX_SUBDIR:+"/$TERMUX__PREFIX_SUBDIR"}" || TERMUX__PREFIX="/$TERMUX__PREFIX_SUBDIR"
__termux_build_props__add_variables_validator_actions "TERMUX__PREFIX" "safe_absolute_path invalid_termux_prefix_paths"
TERMUX_PREFIX="$TERMUX__PREFIX"
TERMUX__PREFIX_CLASSICAL="$TERMUX__PREFIX"
TERMUX_PREFIX_CLASSICAL="$TERMUX__PREFIX"

# Set subdirectories for bin, etc, lib, include, tmp, share, var
TERMUX__PREFIX__BIN_SUBDIR="bin"
TERMUX__PREFIX__BIN_DIR="$TERMUX__PREFIX/$TERMUX__PREFIX__BIN_SUBDIR"
TERMUX__PREFIX__ETC_SUBDIR="etc"
TERMUX__PREFIX__ETC_DIR="$TERMUX__PREFIX/$TERMUX__PREFIX__ETC_SUBDIR"
TERMUX__PREFIX__BASE_INCLUDE_SUBDIR="include"
TERMUX__PREFIX__BASE_INCLUDE_DIR="$TERMUX__PREFIX/$TERMUX__PREFIX__BASE_INCLUDE_SUBDIR"
TERMUX__PREFIX__MULTI_INCLUDE_SUBDIR="include32"
TERMUX__PREFIX__MULTI_INCLUDE_DIR="$TERMUX__PREFIX/$TERMUX__PREFIX__MULTI_INCLUDE_SUBDIR"
TERMUX__PREFIX__BASE_LIB_SUBDIR="lib"
TERMUX__PREFIX__BASE_LIB_DIR="$TERMUX__PREFIX/$TERMUX__PREFIX__BASE_LIB_SUBDIR"
TERMUX__PREFIX__MULTI_LIB_SUBDIR="lib32"
TERMUX__PREFIX__MULTI_LIB_DIR="$TERMUX__PREFIX/$TERMUX__PREFIX__MULTI_LIB_SUBDIR"
TERMUX__PREFIX__LIB_SUBDIR="$TERMUX__PREFIX__BASE_LIB_SUBDIR"
TERMUX__PREFIX__LIB_DIR="$TERMUX__PREFIX__BASE_LIB_DIR"
TERMUX__PREFIX__LIBEXEC_SUBDIR="libexec"
TERMUX__PREFIX__LIBEXEC_DIR="$TERMUX__PREFIX/$TERMUX__PREFIX__LIBEXEC_SUBDIR"
TERMUX__PREFIX__OPT_SUBDIR="opt"
TERMUX__PREFIX__OPT_DIR="$TERMUX__PREFIX/$TERMUX__PREFIX__OPT_SUBDIR"
TERMUX__PREFIX__SHARE_SUBDIR="share"
TERMUX__PREFIX__SHARE_DIR="$TERMUX__PREFIX/$TERMUX__PREFIX__SHARE_SUBDIR"
TERMUX__PREFIX__VAR_SUBDIR="var"
TERMUX__PREFIX__VAR_DIR="$TERMUX__PREFIX/$TERMUX__PREFIX__VAR_SUBDIR"

# Set prefix sub variables
termux_build_props__set_termux_prefix_dir_and_sub_variables "$TERMUX__PREFIX" "true" || exit $?

# The script continues with bootstrap paths, cache paths, Termux:API, validation functions, and repo URLs...
# (All remaining content from your original script goes here in identical structure.)