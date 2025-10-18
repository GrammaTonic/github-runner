#!/bin/bash
# Simplified entrypoint script for the GitHub Actions Runner (Chrome)

set -e

is_truthy() {
	case "${1,,}" in
		1|true|yes|y|on) return 0;;
		*) return 1;;
	esac
}

relax_docker_sock_perms() {
	if [ -S "/var/run/docker.sock" ]; then
		if command -v sudo >/dev/null 2>&1; then
			sudo chmod 666 /var/run/docker.sock || true
		else
			chmod 666 /var/run/docker.sock 2>/dev/null || true
		fi
	fi
}

start_dummy_listener() {
	echo "Starting dummy Runner.Listener for skip-registration mode..."
	mkdir -p /tmp/runner
	cat >/tmp/runner/Runner.Listener <<'EOF'
#!/bin/bash
trap 'exit 0' TERM INT
while true; do sleep 3600; done
EOF
	chmod +x /tmp/runner/Runner.Listener
	/tmp/runner/Runner.Listener &
	echo $! > /tmp/runner/dummy-listener.pid
}

stop_dummy_listener() {
	if [ -f /tmp/runner/dummy-listener.pid ]; then
		kill "$(cat /tmp/runner/dummy-listener.pid)" 2>/dev/null || true
		rm -f /tmp/runner/dummy-listener.pid
	fi
}

RUNNER_SKIP_REGISTRATION="${RUNNER_SKIP_REGISTRATION:-false}"
RUNNER_WORK_DIR="${RUNNER_WORK_DIR:-${RUNNER_WORKDIR:-/home/runner/workspace}}"
RUNNER_NAME="${RUNNER_NAME:-chrome-runner-$(hostname)}"
RUNNER_LABELS="${RUNNER_LABELS:-chrome,ui-tests,playwright,cypress}"
GITHUB_HOST="${GITHUB_HOST:-github.com}"

cd /actions-runner

if is_truthy "$RUNNER_SKIP_REGISTRATION"; then
	echo "RUNNER_SKIP_REGISTRATION enabled. Skipping GitHub registration."
	relax_docker_sock_perms
	touch "/actions-runner/.runner_configured" || true
	start_dummy_listener
	trap 'stop_dummy_listener; exit 0' SIGTERM SIGINT
	tail -f /dev/null & wait $!
	exit 0
fi

: "${GITHUB_TOKEN:?Error: GITHUB_TOKEN environment variable not set.}"
: "${GITHUB_REPOSITORY:?Error: GITHUB_REPOSITORY environment variable not set.}"

echo "Requesting registration token for ${GITHUB_REPOSITORY}..."
RUNNER_TOKEN=$(curl -s -X POST \
	-H "Authorization: token ${GITHUB_TOKEN}" \
	-H "Accept: application/vnd.github.v3+json" \
	"https://api.${GITHUB_HOST}/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token" | jq -r '.token')

if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" == "null" ]; then
	echo "Error: Failed to get registration token. Check GITHUB_TOKEN and GITHUB_REPOSITORY."
	exit 1
fi

echo "Configuring runner..."
./config.sh \
	--url "https://${GITHUB_HOST}/${GITHUB_REPOSITORY}" \
	--token "${RUNNER_TOKEN}" \
	--name "${RUNNER_NAME}" \
	--labels "${RUNNER_LABELS}" \
	--work "${RUNNER_WORK_DIR}" \
	--unattended \
	--replace

cleanup() {
	echo "Signal received, removing runner registration..."
	./config.sh remove --token "${RUNNER_TOKEN}" || true
	echo "Runner registration removed."
}

trap cleanup SIGTERM SIGINT

relax_docker_sock_perms

echo "Starting runner..."
./run.sh &
wait $!
