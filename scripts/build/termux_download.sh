#!/usr/bin/bash
set -euo pipefail

termux_download() {
	if [[ $# != 2 ]] && [[ $# != 3 ]]; then
		echo "termux_download(): Invalid arguments - expected <URL> <DESTINATION> [<CHECKSUM>]" 1>&2
		return 1
	fi

	local URL="$1"
	local DESTINATION="$2"
	local CHECKSUM="${3:-SKIP_CHECKSUM}"

	# Handle local files/directories via file:// scheme
	if [[ "$URL" =~ ^file://(/[^/]+)+$ ]]; then
		local source="${URL:7}" # Remove `file://` prefix

		if [[ -d "$source" ]]; then
			echo "Creating tar from local directory: '$source'"
			rm -f "$DESTINATION"
			(cd "$(dirname "$source")" && tar -cf "$DESTINATION" --exclude=".git" "$(basename "$source")")
			return 0
		elif [[ ! -f "$source" ]]; then
			echo "No local source file found at '$URL'" 1>&2
			return 1
		else
			ln -sf "$source" "$DESTINATION"
			return 0
		fi
	fi

	# Skip download if file exists and checksum matches
	if [[ -f "$DESTINATION" ]] && [[ "$CHECKSUM" != "SKIP_CHECKSUM" ]]; then
		local EXISTING_CHECKSUM
		EXISTING_CHECKSUM=$(sha256sum "$DESTINATION" | cut -d' ' -f1)
		[[ "$EXISTING_CHECKSUM" == "$CHECKSUM" ]] && return 0
	fi

	# Download with curl and retries
	local TMPFILE
	TMPFILE=$(mktemp "${TERMUX_PKG_TMPDIR:-/tmp}/download.${TERMUX_PKG_NAME-unnamed}.XXXXXXXXX")
	local -a CURL_OPTIONS=(
		--fail
		--retry 5
		--retry-connrefused
		--retry-delay 5
		--connect-timeout 30
		--retry-max-time 120
		--speed-limit 1000
		--speed-time 60
		--location
	)

	[[ "${TERMUX_QUIET_BUILD-}" == "true" ]] && CURL_OPTIONS+=(--no-progress-meter)

	echo "Downloading: $URL"
	if ! curl "${CURL_OPTIONS[@]}" --output "$TMPFILE" "$URL"; then
		local error=1 retry=2 delay=60
		for ((i=1;i<=retry;i++)); do
			echo "Retry #$i for $URL in ${delay}s..."
			sleep "$delay"
			if curl "${CURL_OPTIONS[@]}" --output "$TMPFILE" "$URL"; then
				error=0
				break
			fi
		done
		if [[ "$error" != 0 ]]; then
			echo "Failed to download $URL after retries" 1>&2
			rm -f "$TMPFILE"
			return 1
		fi
	fi

	# Verify checksum
	if [[ -n "$CHECKSUM" && "$CHECKSUM" != "SKIP_CHECKSUM" ]]; then
		echo "$CHECKSUM  $TMPFILE" | sha256sum -c - || {
			echo "Checksum mismatch for $URL" 1>&2
			rm -f "$TMPFILE"
			return 1
		}
	elif [[ -z "$CHECKSUM" ]]; then
		local ACTUAL_CHECKSUM
		ACTUAL_CHECKSUM=$(sha256sum "$TMPFILE" | cut -d' ' -f1)
		echo "WARNING: No checksum provided for $URL. Actual: $ACTUAL_CHECKSUM"
	fi

	mv "$TMPFILE" "$DESTINATION"
	return 0
}

# Allow script to be executed standalone
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	termux_download "$@"
fi