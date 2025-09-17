#!/bin/bash
# Dedicated entrypoint for the General-Purpose GitHub Actions Runner

# Stop immediately on error
set -e

# --- VARIABLE SETUP ---
# Check for required environment variables
: "${GITHUB_TOKEN:?Error: GITHUB_TOKEN environment variable not set.}"
: "${GITHUB_REPOSITORY:?Error: GITHUB_REPOSITORY environment variable not set.}"

# Assign optional variables with general-purpose defaults
RUNNER_NAME="${RUNNER_NAME:-docker-runner-$(hostname)}"
RUNNER_LABELS="${RUNNER_LABELS:-docker,self-hosted,linux,x64}"
RUNNER_WORK_DIR="${RUNNER_WORK_DIR:-/home/runner/_work}"
GITHUB_HOST="${GITHUB_HOST:-github.com}"
RUNNER_DIR="/actions-runner"

# --- RUNNER CONFIGURATION ---
cd "${RUNNER_DIR}"

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
