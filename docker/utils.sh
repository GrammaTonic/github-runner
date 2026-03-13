#!/bin/bash
# Shared utility functions for GitHub Runner Docker images
# Centralizes input validation and security checks

# Validate repository format (owner/repo)
validate_repository() {
	local repo="$1"
	if [[ ! "$repo" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
		echo "Error: Invalid GITHUB_REPOSITORY format. Expected: owner/repo" >&2
		return 1
	fi
	return 0
}

# Validate runner name (allows alphanumeric, dashes, underscores, and dots)
validate_runner_name() {
	local name="$1"
	local value="$2"
	if [[ ! "$value" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
		echo "Error: $name contains invalid characters. Received: $value" >&2
		return 1
	fi
	return 0
}

# Validate hostname (alphanumeric, dots, dashes)
validate_hostname() {
	local host="$1"
	if [[ ! "$host" =~ ^[a-zA-Z0-9.-]+$ ]]; then
		echo "Error: Invalid hostname format: $host" >&2
		return 1
	fi
	return 0
}

# Validate numeric input
validate_number() {
	local name="$1"
	local value="$2"
	if [[ ! "$value" =~ ^[0-9]+$ ]]; then
		echo "Error: $name must be a number. Received: $value" >&2
		return 1
	fi
	return 0
}

# Validate path to prevent traversal and enforce /tmp/ base for logs/metrics
validate_path() {
	local name="$1"
	local path="$2"
	local extension="$3"

	if [[ "$path" == *".."* ]]; then
		echo "Error: Path traversal detected in $name: $path" >&2
		return 1
	fi

	if [[ ! "$path" =~ ^/tmp/ ]]; then
		echo "Error: $name must be under /tmp/ for security. Received: $path" >&2
		return 1
	fi

	if [[ -n "$extension" && ! "$path" =~ \."$extension"$ ]]; then
		echo "Error: $name must have .$extension extension. Received: $path" >&2
		return 1
	fi

	return 0
}

# Validate alphanumeric with dashes and underscores
validate_alphanumeric_dash() {
	local name="$1"
	local value="$2"
	if [[ ! "$value" =~ ^[a-zA-Z0-9_-]+$ ]]; then
		echo "Error: $name must be alphanumeric with dashes or underscores. Received: $value" >&2
		return 1
	fi
	return 0
}
