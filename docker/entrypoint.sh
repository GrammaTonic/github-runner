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

# Use secure temporary files for headers and response to prevent token exposure in shell traces
HEADER_FILE=$(mktemp)
RESPONSE_FILE=$(mktemp)

# Create header file with token using heredoc (not leaked in set -x)
cat <<EOF >"$HEADER_FILE"
Authorization: token ${GITHUB_TOKEN}
Accept: application/vnd.github.v3+json
EOF

# Using curl with silent mode and proper error handling to prevent token exposure
HTTP_STATUS=$(curl -s -o "$RESPONSE_FILE" -w "%{http_code}" -X POST \
	-H @"$HEADER_FILE" \
	"https://api.${GITHUB_HOST}/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token")

# Extract runner token from response file
RUNNER_TOKEN=$(jq -r '.token // empty' "$RESPONSE_FILE" 2>/dev/null)

# Securely clean up header file containing GITHUB_TOKEN immediately
rm -f "$HEADER_FILE"

# Validate response without exposing tokens in error messages
if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" == "null" ]; then
	echo "Error: Failed to get registration token from GitHub API."
	echo "HTTP Status: ${HTTP_STATUS}"
	# Only show error message, never the token or full response
	ERROR_MSG=$(jq -r '.message // "Unknown error"' "$RESPONSE_FILE" 2>/dev/null || echo "Unable to parse error response")
	echo "Error message: ${ERROR_MSG}"
	echo "Please verify:"
	echo "  1. GITHUB_TOKEN has 'repo' scope and is valid"
	echo "  2. GITHUB_REPOSITORY is correct (format: owner/repo)"
	echo "  3. Token has permissions for ${GITHUB_REPOSITORY}"
	rm -f "$RESPONSE_FILE"
	exit 1
fi

# Clean up response file
rm -f "$RESPONSE_FILE"

# --- JOB LIFECYCLE HOOKS (Phase 3: DORA Metrics) ---
# TASK-028: Set runner hook env vars for job tracking
# The runner (v2.300.0+) will call these scripts before/after each job
export ACTIONS_RUNNER_HOOK_JOB_STARTED=/usr/local/bin/job-started.sh
export ACTIONS_RUNNER_HOOK_JOB_COMPLETED=/usr/local/bin/job-completed.sh
echo "Job lifecycle hooks configured:"
echo "  - Job started hook: ${ACTIONS_RUNNER_HOOK_JOB_STARTED}"
echo "  - Job completed hook: ${ACTIONS_RUNNER_HOOK_JOB_COMPLETED}"

# Create job state directory for duration tracking
mkdir -p /tmp/job_state

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
