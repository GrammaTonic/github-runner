#!/bin/bash
# Simplified entrypoint script for the GitHub Actions Runner

# Stop immediately on error
set -e

# Allow test mode to skip GitHub registration
if [[ "${RUNNER_SKIP_REGISTRATION:-false}" == "true" ]]; then
	echo "RUNNER_SKIP_REGISTRATION enabled; skipping GitHub registration and starting idle loop."
	touch /home/runner/.runner_configured
	tail -f /dev/null &
	idle_pid=$!
	trap 'echo "Stopping runner idle loop"; kill "$idle_pid" >/dev/null 2>&1 || true; exit 0' SIGTERM SIGINT
	wait "$idle_pid"
	exit 0
fi

# Check for required environment variables
: "${GITHUB_TOKEN:?Error: GITHUB_TOKEN environment variable not set.}"
: "${GITHUB_REPOSITORY:?Error: GITHUB_REPOSITORY environment variable not set.}"

# Optional variables with default values
RUNNER_NAME="${RUNNER_NAME:-chrome-runner-$(hostname)}"
RUNNER_LABELS="${RUNNER_LABELS:-chrome,ui-tests,playwright,cypress}"
RUNNER_WORK_DIR="${RUNNER_WORK_DIR:-/home/runner/workspace}"
GITHUB_HOST="${GITHUB_HOST:-github.com}" # For GitHub Enterprise

# Change to the runner's directory
cd /actions-runner

# Request a registration token from the GitHub API
echo "Requesting registration token for ${GITHUB_REPOSITORY}..."
RUNNER_TOKEN=$(curl -s -X POST \
	-H "Authorization: token ${GITHUB_TOKEN}" \
	-H "Accept: application/vnd.github.v3+json" \
	"https://api.${GITHUB_HOST}/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token" | jq -r '.token')

if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" == "null" ]; then
	echo "Error: Failed to get registration token. Check GITHUB_TOKEN and GITHUB_REPOSITORY."
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

# Function to clean up the runner on exit
cleanup() {
	echo "Signal received, removing runner registration..."
	./config.sh remove --token "${RUNNER_TOKEN}"
	echo "Runner registration removed."
}

# Trap stop (SIGTERM) and interrupt (SIGINT) signals to run the cleanup function
trap cleanup SIGTERM SIGINT

# Start the runner and wait for the process to exit
echo "Starting runner..."
./run.sh &
wait $!
