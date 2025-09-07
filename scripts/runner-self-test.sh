#!/usr/bin/env bash
set -euo pipefail

GH_REPO=${GH_REPO:-}
GH_PAT=${GH_PAT:-}
RUNNER_TOKEN=${RUNNER_TOKEN:-}
RUNNER_LABEL=${RUNNER_LABEL:-gh-runner-test}
COMPOSE_FILE=${COMPOSE_FILE:-docker/docker-compose.production.yml}
WORKFLOW_FILE=${WORKFLOW_FILE:-runner-test-job.yml}

if [[ -z "$GH_REPO" || -z "$GH_PAT" || -z "$RUNNER_TOKEN" ]]; then
  echo "Required envs: GH_REPO, GH_PAT, RUNNER_TOKEN"
  exit 2
fi

export RUNNER_LABEL

docker compose -f "$COMPOSE_FILE" up -d

check_runner_registered() {
  curl -s -H "Authorization: token $GH_PAT" \
    "https://api.github.com/repos/${GH_REPO}/actions/runners" | \
    jq -e --arg label "$RUNNER_LABEL" '.runners[]?.labels[]?.name | select(. == $label)' >/dev/null 2>&1
}

for i in $(seq 1 60); do
  if check_runner_registered; then
    echo "Runner registered."
    break
  fi
  echo "  waiting... ($i/60)"
  sleep 5
done

if ! check_runner_registered; then
  echo "Timed out waiting for runner to register."
  exit 3
fi

gh workflow run ".github/workflows/$WORKFLOW_FILE" --repo "$GH_REPO" --ref main

run_id=""
for i in $(seq 1 60); do
  run_id=$(gh run list --repo "$GH_REPO" --workflow "$WORKFLOW_FILE" --limit 1 --json databaseId --jq '.[0].databaseId') || true
  if [[ -n "$run_id" && "$run_id" != "null" ]]; then
    echo "Found run id: $run_id"
    break
  fi
  echo "  waiting for run id... ($i/60)"
  sleep 2
done

if [[ -z "$run_id" || "$run_id" == "null" ]]; then
  echo "Could not find workflow run for $WORKFLOW_FILE"
  exit 4
fi

gh run watch "$run_id" --repo "$GH_REPO"
status=$(gh run view "$run_id" --repo "$GH_REPO" --json conclusion --jq '.conclusion') || true

docker compose -f "$COMPOSE_FILE" down

if [[ "$status" != "success" ]]; then
  echo "Test workflow did not succeed. Run: https://github.com/${GH_REPO}/runs/$run_id"
  exit 5
fi

echo "Self-hosted runner smoke test passed."
