#!/usr/bin/env bash
set -euo pipefail

# Mock GH_PAT
export GH_PAT="ghp_test_token_12345"

# Test function mimicking the fix
check_fix() {
    printf "header = \"Authorization: token %s\"\n" "$GH_PAT" | \
        curl -v -K- https://example.com 2>&1 | grep "> Authorization"
}

echo "Testing curl -K- with Authorization header..."
output=$(check_fix)

if echo "$output" | grep -q "Authorization: token ghp_test_token_12345"; then
    echo "SUCCESS: Token found in request headers."
else
    echo "FAILURE: Token not found in request headers."
    echo "Output was: $output"
    exit 1
fi

echo "Verifying that token is NOT in process list (this is a bit tricky to catch mid-flight, but we check if we see any 'curl.*ghp_test_token')"
# Run it in background and check ps
(printf "header = \"Authorization: token %s\"\n" "$GH_PAT" | curl -s -K- https://example.com > /dev/null) &
PID=$!
if ps -fp $PID | grep -q "ghp_test_token"; then
    echo "FAILURE: Token found in process list!"
    kill $PID 2>/dev/null || true
    exit 1
else
    echo "SUCCESS: Token not found in process list for curl."
fi
wait $PID 2>/dev/null || true

echo "All verification tests passed."
