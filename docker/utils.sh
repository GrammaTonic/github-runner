#!/bin/bash
# Shared utility functions for Docker entrypoint scripts

# Validate numeric input using shell built-ins (more efficient than grep)
validate_numeric() {
	local val="$1"
	local name="$2"
	case "$val" in
		'' | *[!0-9]*)
			echo "Error: Invalid $name format. Expected a number." >&2
			return 1
			;;
	esac
	return 0
}

# Validate metrics path to prevent path traversal
validate_path() {
	local path="$1"
	local extension="$2"
	case "$path" in
		"/tmp/"*"$extension") ;;
		*)
			echo "Error: Path must be under /tmp and end with $extension" >&2
			return 1
			;;
	esac
	if [[ "$path" == *".."* ]]; then
		echo "Error: Path traversal is not allowed." >&2
		return 1
	fi
	return 0
}

# Sanitize a string for use in file paths by replacing unsafe characters with underscores
sanitize_name() {
	local input="$1"
	# Replace anything that isn't alphanumeric, underscore, or dash
	# We exclude dots to prevent path traversal like ../
	echo "${input//[^a-zA-Z0-9_-]/_}"
}

# Shared logging function that writes to stdout and a file
# Parameters:
#   $* - Message to log
# Environment:
#   LOG_FILE - Path to the log file (defaults to /dev/null)
#   LOG_TAG  - Optional tag to include in the log message
log() {
	local timestamp
	timestamp=$(date +'%Y-%m-%d %H:%M:%S')
	local tag="${LOG_TAG:-}"
	local log_file="${LOG_FILE:-/dev/null}"
	local log_prefix="[$timestamp]"

	if [[ -n "$tag" ]]; then
		log_prefix+=" [$tag]"
	fi

	echo "$log_prefix $*" | tee -a "$log_file"
}
