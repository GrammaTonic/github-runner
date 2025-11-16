#!/bin/bash
# Dedicated entrypoint for the General-Purpose GitHub Actions Runner

# Stop immediately on error and enable strict mode for security
set -euo pipefail

# --- INPUT VALIDATION ---
# Validate repository format (owner/repo) to prevent injection
validate_repository() {
	local repo="$1"
	# Repository must match pattern: alphanumeric, dash, underscore, or dot, with exactly one slash
	if ! echo "$repo" | grep -qE '^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$'; then
		echo "Error: Invalid GITHUB_REPOSITORY format. Expected: owner/repo" >&2
		echo "Received: $repo" >&2
		return 1
	fi
	return 0
}

# Validate hostname to prevent injection
validate_hostname() {
	local host="$1"
	# Hostname must be alphanumeric with dots and dashes only
	if ! echo "$host" | grep -qE '^[a-zA-Z0-9.-]+$'; then
		echo "Error: Invalid GITHUB_HOST format." >&2
		return 1
	fi
	return 0
}

# --- VARIABLE SETUP ---
# Check for required environment variables
: "${GITHUB_TOKEN:?Error: GITHUB_TOKEN environment variable not set.}"
: "${GITHUB_REPOSITORY:?Error: GITHUB_REPOSITORY environment variable not set.}"

# Validate inputs before using them
validate_repository "$GITHUB_REPOSITORY" || exit 1

# Assign optional variables with general-purpose defaults
RUNNER_NAME="${RUNNER_NAME:-docker-runner-$(hostname)}"
RUNNER_LABELS="${RUNNER_LABELS:-docker,self-hosted,linux,x64}"
RUNNER_WORK_DIR="${RUNNER_WORK_DIR:-/home/runner/_work}"
GITHUB_HOST="${GITHUB_HOST:-github.com}"

# Validate GitHub host
validate_hostname "$GITHUB_HOST" || exit 1

RUNNER_DIR="/actions-runner"

# --- RUNNER CONFIGURATION ---
cd "${RUNNER_DIR}"

# Request a registration token from the GitHub API
echo "Requesting registration token for ${GITHUB_REPOSITORY}..."
# Using curl with silent mode and proper error handling to prevent token exposure
RUNNER_TOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
	-H "Authorization: token ${GITHUB_TOKEN}" \
	-H "Accept: application/vnd.github.v3+json" \
	"https://api.${GITHUB_HOST}/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token" 2>&1)

# Extract HTTP status code and response body
HTTP_STATUS=$(echo "$RUNNER_TOKEN_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RUNNER_TOKEN_RESPONSE" | sed '$d')
RUNNER_TOKEN=$(echo "$RESPONSE_BODY" | jq -r '.token // empty' 2>/dev/null)

# Validate response without exposing tokens in error messages
if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" == "null" ]; then
	echo "Error: Failed to get registration token from GitHub API."
	echo "HTTP Status: ${HTTP_STATUS}"
	# Only show error message, never the token or full response
	ERROR_MSG=$(echo "$RESPONSE_BODY" | jq -r '.message // "Unknown error"' 2>/dev/null || echo "Unable to parse error response")
	echo "Error message: ${ERROR_MSG}"
	echo "Please verify:"
	echo "  1. GITHUB_TOKEN has 'repo' scope and is valid"
	echo "  2. GITHUB_REPOSITORY is correct (format: owner/repo)"
	echo "  3. Token has permissions for ${GITHUB_REPOSITORY}"
	exit 1
fi

# Configure the runner
echo "Configuring runner..."
./config.sh \
	--url "https://${GITHUB_HOST}/${GITHUB_REPOSITORY}" \
	--token "${RUNNER_TOKEN}" \
	--name "${RUNNER_NAME}" \
	--labels "${RUNNER_LABELS}" \
	--work "${RUNNER_WORK_DIR}" \
	--unattended \
	--replace

# --- STARTUP AND CLEANUP ---

# Function to clean up the runner on exit
cleanup() {
	echo "Signal received, removing runner registration..."
	./config.sh remove --token "${RUNNER_TOKEN}"
	echo "Runner registration removed."
}

# Trap signals to run the cleanup function
trap cleanup SIGTERM SIGINT

# Start the runner and wait for the process to exit
echo "Starting general-purpose runner..."
./run.sh &
wait $!
