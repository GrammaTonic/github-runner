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
# Assign optional variables with general-purpose defaults (before token check for metrics)
RUNNER_NAME="${RUNNER_NAME:-docker-runner-$(hostname)}"
RUNNER_LABELS="${RUNNER_LABELS:-docker,self-hosted,linux,x64}"
RUNNER_WORK_DIR="${RUNNER_WORK_DIR:-/home/runner/_work}"
GITHUB_HOST="${GITHUB_HOST:-github.com}"
RUNNER_DIR="/actions-runner"

# --- METRICS SETUP (Phase 1: Prometheus Monitoring) ---
# Start metrics services BEFORE token validation to enable standalone testing
# TASK-003: Initialize job log
JOBS_LOG="${JOBS_LOG:-/tmp/jobs.log}"
echo "Initializing job log: ${JOBS_LOG}"
touch "${JOBS_LOG}"

# TASK-004: Start metrics collection services
METRICS_PORT="${METRICS_PORT:-9091}"
METRICS_FILE="${METRICS_FILE:-/tmp/runner_metrics.prom}"
RUNNER_TYPE="${RUNNER_TYPE:-standard}"

echo "Starting Prometheus metrics services..."
echo "  - Metrics endpoint: http://localhost:${METRICS_PORT}/metrics"
echo "  - Runner type: ${RUNNER_TYPE}"

# Start metrics collector in background
if [ -f "/usr/local/bin/metrics-collector.sh" ]; then
	RUNNER_NAME="${RUNNER_NAME}" \
	RUNNER_TYPE="${RUNNER_TYPE}" \
	METRICS_FILE="${METRICS_FILE}" \
	JOBS_LOG="${JOBS_LOG}" \
	UPDATE_INTERVAL="${METRICS_UPDATE_INTERVAL:-30}" \
	/usr/local/bin/metrics-collector.sh &
	COLLECTOR_PID=$!
	echo "Metrics collector started (PID: ${COLLECTOR_PID})"
else
	echo "Warning: metrics-collector.sh not found, metrics collection disabled"
fi

# Start metrics HTTP server in background
if [ -f "/usr/local/bin/metrics-server.sh" ]; then
	METRICS_PORT="${METRICS_PORT}" \
	METRICS_FILE="${METRICS_FILE}" \
	/usr/local/bin/metrics-server.sh &
	SERVER_PID=$!
	echo "Metrics server started (PID: ${SERVER_PID})"
else
	echo "Warning: metrics-server.sh not found, metrics endpoint disabled"
fi

# --- GITHUB RUNNER SETUP ---
# Check for required environment variables (after metrics setup)
: "${GITHUB_TOKEN:?Error: GITHUB_TOKEN environment variable not set.}"
: "${GITHUB_REPOSITORY:?Error: GITHUB_REPOSITORY environment variable not set.}"

# Validate inputs before using them
validate_repository "$GITHUB_REPOSITORY" || exit 1

# Validate GitHub host
validate_hostname "$GITHUB_HOST" || exit 1

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
	echo "Signal received, shutting down..."
	
	# Stop metrics services
	if [ -n "${COLLECTOR_PID:-}" ]; then
		echo "Stopping metrics collector (PID: ${COLLECTOR_PID})..."
		kill -TERM "${COLLECTOR_PID}" 2>/dev/null || true
	fi
	
	if [ -n "${SERVER_PID:-}" ]; then
		echo "Stopping metrics server (PID: ${SERVER_PID})..."
		kill -TERM "${SERVER_PID}" 2>/dev/null || true
	fi
	
	# Remove runner registration
	echo "Removing runner registration..."
	./config.sh remove --token "${RUNNER_TOKEN}"
	echo "Runner registration removed."
}

# Trap signals to run the cleanup function
trap cleanup SIGTERM SIGINT

# Start the runner and wait for the process to exit
echo "Starting general-purpose runner..."
./run.sh &
wait $!
