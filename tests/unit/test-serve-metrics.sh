#!/bin/bash
# Unit test for serve_metrics function in metrics-server.sh

set -euo pipefail

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Mock log function to avoid output pollution
log() {
    :
}

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test result function
test_result() {
    local test_name="$1"
    local result="$2"
    local message="${3:-}"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}✅ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC}: $test_name"
        if [[ -n "$message" ]]; then
            echo -e "   ${RED}Error: $message${NC}"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Source the script under test
# shellcheck source=docker/metrics-server.sh
source "$(dirname "$0")/../../docker/metrics-server.sh"

echo "========================================"
echo "Testing serve_metrics function"
echo "========================================"
echo ""

# Setup temporary test environment
TEST_TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

# Override METRICS_FILE for testing
METRICS_FILE="$TEST_TMP_DIR/test_metrics.prom"

# Test 1: Metrics file missing (503 Service Unavailable)
echo "Test 1: Metrics file missing"
rm -f "$METRICS_FILE"
output=$(serve_metrics "127.0.0.1" 2>&1 || true)

if echo "$output" | grep -q "HTTP/1.0 503 Service Unavailable"; then
    test_result "serve_metrics returns 503 when file missing" "PASS"
else
    test_result "serve_metrics returns 503 when file missing" "FAIL" "Expected 503, got:\n$output"
fi

# Test 2: Metrics file exists (200 OK)
echo "Test 2: Metrics file exists"
cat > "$METRICS_FILE" <<EOF
test_metric 42
EOF
output=$(serve_metrics "127.0.0.1" 2>&1)

if echo "$output" | grep -q "HTTP/1.0 200 OK"; then
    test_result "serve_metrics returns 200 when file exists" "PASS"
else
    test_result "serve_metrics returns 200 when file exists" "FAIL" "Expected 200, got:\n$output"
fi

if echo "$output" | grep -q "test_metric 42"; then
    test_result "serve_metrics returns correct content" "PASS"
else
    test_result "serve_metrics returns correct content" "FAIL" "Metric content missing or incorrect"
fi

# Test 3: Verify Content-Length
echo "Test 3: Verify Content-Length"
expected_content="test_metric 42"
# Account for the newline added by heredoc
content_length=$(( ${#expected_content} + 1 ))

if echo "$output" | grep -q "Content-Length: $content_length"; then
    test_result "serve_metrics returns correct Content-Length" "PASS"
else
    actual_cl=$(echo "$output" | grep "Content-Length:" | awk '{print $2}')
    test_result "serve_metrics returns correct Content-Length" "FAIL" "Expected $content_length, got $actual_cl"
fi

# Test 4: Verify Content-Type
echo "Test 4: Verify Content-Type"
if echo "$output" | grep -q "Content-Type: text/plain; version=0.0.4; charset=utf-8"; then
    test_result "serve_metrics returns correct Content-Type" "PASS"
else
    test_result "serve_metrics returns correct Content-Type" "FAIL" "Incorrect or missing Content-Type"
fi

echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "Total tests:  ${YELLOW}${TESTS_TOTAL}${NC}"
echo -e "Passed:       ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed:       ${RED}${TESTS_FAILED}${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    exit 1
fi
