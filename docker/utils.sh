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
