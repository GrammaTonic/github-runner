#!/bin/bash
# Unit tests for job-started.sh

set -euo pipefail

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
	elif [[ "$result" == "SKIP" ]]; then
		echo -e "${YELLOW}⏭️  SKIP${NC}: $test_name"
		if [[ -n "$message" ]]; then
			echo -e "   ${YELLOW}Reason: $message${NC}"
		fi
	else
		echo -e "${RED}❌ FAIL${NC}: $test_name"
		if [[ -n "$message" ]]; then
			echo -e "   ${RED}Error: $message${NC}"
		fi
		TESTS_FAILED=$((TESTS_FAILED + 1))
	fi
}

echo "========================================"
echo "job-started.sh Implementation Tests"
echo "========================================"
echo ""

# Extract get_job_id function from job-started.sh for testing
tmp_script=$(mktemp)
trap 'rm -f "$tmp_script"' EXIT
sed -n '/^get_job_id()/,/^}/p' docker/job-started.sh > "$tmp_script"
source "$tmp_script"

# Test 1: Both GITHUB_RUN_ID and GITHUB_JOB are set
export GITHUB_RUN_ID="12345"
export GITHUB_JOB="test_job"
if [[ "$(get_job_id)" == "12345_test_job" ]]; then
	test_result "get_job_id with both vars set" "PASS"
else
	test_result "get_job_id with both vars set" "FAIL" "Expected 12345_test_job, got $(get_job_id)"
fi

# Test 2: GITHUB_RUN_ID is set, GITHUB_JOB is unset
export GITHUB_RUN_ID="12345"
unset GITHUB_JOB
if [[ "$(get_job_id)" == "12345_unknown" ]]; then
	test_result "get_job_id with GITHUB_JOB unset" "PASS"
else
	test_result "get_job_id with GITHUB_JOB unset" "FAIL" "Expected 12345_unknown, got $(get_job_id)"
fi

# Test 3: GITHUB_RUN_ID is unset, GITHUB_JOB is set
unset GITHUB_RUN_ID
export GITHUB_JOB="test_job"
if [[ "$(get_job_id)" == "0_test_job" ]]; then
	test_result "get_job_id with GITHUB_RUN_ID unset" "PASS"
else
	test_result "get_job_id with GITHUB_RUN_ID unset" "FAIL" "Expected 0_test_job, got $(get_job_id)"
fi

# Test 4: Both vars are unset
unset GITHUB_RUN_ID
unset GITHUB_JOB
if [[ "$(get_job_id)" == "0_unknown" ]]; then
	test_result "get_job_id with both vars unset" "PASS"
else
	test_result "get_job_id with both vars unset" "FAIL" "Expected 0_unknown, got $(get_job_id)"
fi

# Test 5: Empty strings for vars
export GITHUB_RUN_ID=""
export GITHUB_JOB=""
if [[ "$(get_job_id)" == "0_unknown" ]]; then
	test_result "get_job_id with empty string vars" "PASS"
else
	test_result "get_job_id with empty string vars" "FAIL" "Expected 0_unknown, got $(get_job_id)"
fi

# Test 6: Spaces in GITHUB_JOB
export GITHUB_RUN_ID="12345"
export GITHUB_JOB="test job with spaces"
if [[ "$(get_job_id)" == "12345_test job with spaces" ]]; then
	test_result "get_job_id with spaces in job name" "PASS"
else
	test_result "get_job_id with spaces in job name" "FAIL" "Expected '12345_test job with spaces', got $(get_job_id)"
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
