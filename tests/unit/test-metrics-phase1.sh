#!/bin/bash
# Unit tests for Phase 1: Custom Metrics Endpoint - Standard Runner
# Tests TASK-001 through TASK-007 implementation

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
	else
		echo -e "${RED}❌ FAIL${NC}: $test_name"
		if [[ -n "$message" ]]; then
			echo -e "   ${RED}Error: $message${NC}"
		fi
		TESTS_FAILED=$((TESTS_FAILED + 1))
	fi
}

echo "========================================"
echo "Phase 1 Metrics Implementation Tests"
echo "========================================"
echo ""

# Test 1: Verify metrics-server.sh exists and is executable
echo "Test 1: Verify metrics-server.sh exists"
if [[ -f "docker/metrics-server.sh" && -x "docker/metrics-server.sh" ]]; then
	test_result "metrics-server.sh exists and is executable" "PASS"
else
	test_result "metrics-server.sh exists and is executable" "FAIL" "File not found or not executable"
fi

# Test 2: Verify metrics-collector.sh exists and is executable
echo "Test 2: Verify metrics-collector.sh exists"
if [[ -f "docker/metrics-collector.sh" && -x "docker/metrics-collector.sh" ]]; then
	test_result "metrics-collector.sh exists and is executable" "PASS"
else
	test_result "metrics-collector.sh exists and is executable" "FAIL" "File not found or not executable"
fi

# Test 3: Verify bash syntax for metrics-server.sh
echo "Test 3: Verify bash syntax for metrics-server.sh"
if bash -n docker/metrics-server.sh 2>/dev/null; then
	test_result "metrics-server.sh bash syntax valid" "PASS"
else
	test_result "metrics-server.sh bash syntax valid" "FAIL" "Syntax errors found"
fi

# Test 4: Verify bash syntax for metrics-collector.sh
echo "Test 4: Verify bash syntax for metrics-collector.sh"
if bash -n docker/metrics-collector.sh 2>/dev/null; then
	test_result "metrics-collector.sh bash syntax valid" "PASS"
else
	test_result "metrics-collector.sh bash syntax valid" "FAIL" "Syntax errors found"
fi

# Test 5: Verify entrypoint.sh initializes job log (TASK-003)
echo "Test 5: Verify entrypoint.sh initializes job log"
if grep -q 'JOBS_LOG="\${JOBS_LOG:-/tmp/jobs.log}"' docker/entrypoint.sh && \
   grep -q 'touch "\${JOBS_LOG}"' docker/entrypoint.sh; then
	test_result "entrypoint.sh initializes job log" "PASS"
else
	test_result "entrypoint.sh initializes job log" "FAIL" "Job log initialization not found"
fi

# Test 6: Verify entrypoint.sh starts metrics services (TASK-004)
echo "Test 6: Verify entrypoint.sh starts metrics services"
if grep -q 'metrics-collector.sh' docker/entrypoint.sh && \
   grep -q 'metrics-server.sh' docker/entrypoint.sh; then
	test_result "entrypoint.sh starts metrics services" "PASS"
else
	test_result "entrypoint.sh starts metrics services" "FAIL" "Metrics service startup not found"
fi

# Test 7: Verify Dockerfile exposes port 9091 (TASK-005)
echo "Test 7: Verify Dockerfile exposes port 9091"
if grep -q 'EXPOSE 9091' docker/Dockerfile; then
	test_result "Dockerfile exposes port 9091" "PASS"
else
	test_result "Dockerfile exposes port 9091" "FAIL" "EXPOSE 9091 not found"
fi

# Test 8: Verify Dockerfile copies metrics scripts
echo "Test 8: Verify Dockerfile copies metrics scripts"
if grep -q 'COPY.*metrics-server.sh' docker/Dockerfile && \
   grep -q 'COPY.*metrics-collector.sh' docker/Dockerfile; then
	test_result "Dockerfile copies metrics scripts" "PASS"
else
	test_result "Dockerfile copies metrics scripts" "FAIL" "COPY instructions not found"
fi

# Test 9: Verify docker-compose.production.yml exposes port 9091 (TASK-006)
echo "Test 9: Verify docker-compose exposes port 9091"
if grep -q '"9091:9091"' docker/docker-compose.production.yml; then
	test_result "docker-compose exposes port 9091" "PASS"
else
	test_result "docker-compose exposes port 9091" "FAIL" "Port mapping not found"
fi

# Test 10: Verify docker-compose.production.yml has environment variables (TASK-007)
echo "Test 10: Verify docker-compose has metrics environment variables"
if grep -q 'RUNNER_TYPE=standard' docker/docker-compose.production.yml && \
   grep -q 'METRICS_PORT=9091' docker/docker-compose.production.yml; then
	test_result "docker-compose has metrics environment variables" "PASS"
else
	test_result "docker-compose has metrics environment variables" "FAIL" "Environment variables not found"
fi

# Test 11: Verify metrics-server.sh uses netcat
echo "Test 11: Verify metrics-server.sh uses netcat"
if grep -q 'nc -l' docker/metrics-server.sh || grep -q 'netcat' docker/metrics-server.sh; then
	test_result "metrics-server.sh uses netcat" "PASS"
else
	test_result "metrics-server.sh uses netcat" "FAIL" "netcat usage not found"
fi

# Test 12: Verify metrics-server.sh serves Prometheus format
echo "Test 12: Verify metrics-server.sh serves Prometheus format"
if grep -q 'Content-Type: text/plain; version=0.0.4' docker/metrics-server.sh; then
	test_result "metrics-server.sh serves Prometheus format" "PASS"
else
	test_result "metrics-server.sh serves Prometheus format" "FAIL" "Prometheus Content-Type not found"
fi

# Test 13: Verify metrics-collector.sh generates required metrics
echo "Test 13: Verify metrics-collector.sh generates required metrics"
if grep -q 'github_runner_status' docker/metrics-collector.sh && \
   grep -q 'github_runner_info' docker/metrics-collector.sh && \
   grep -q 'github_runner_uptime_seconds' docker/metrics-collector.sh && \
   grep -q 'github_runner_jobs_total' docker/metrics-collector.sh; then
	test_result "metrics-collector.sh generates required metrics" "PASS"
else
	test_result "metrics-collector.sh generates required metrics" "FAIL" "Required metrics not found"
fi

# Test 14: Verify metrics-collector.sh has 30-second default interval
echo "Test 14: Verify metrics-collector.sh has 30-second update interval"
if grep -q 'UPDATE_INTERVAL="\${UPDATE_INTERVAL:-30}"' docker/metrics-collector.sh; then
	test_result "metrics-collector.sh has 30-second update interval" "PASS"
else
	test_result "metrics-collector.sh has 30-second update interval" "FAIL" "Default interval not 30 seconds"
fi

# Test 15: Verify metrics-collector.sh reads from jobs.log
echo "Test 15: Verify metrics-collector.sh reads from jobs.log"
if grep -q '/tmp/jobs.log' docker/metrics-collector.sh; then
	test_result "metrics-collector.sh reads from jobs.log" "PASS"
else
	test_result "metrics-collector.sh reads from jobs.log" "FAIL" "jobs.log reference not found"
fi

# Test 16: Verify shellcheck passes for metrics-server.sh
echo "Test 16: Run shellcheck on metrics-server.sh"
if command -v shellcheck &> /dev/null; then
	if shellcheck docker/metrics-server.sh 2>/dev/null; then
		test_result "shellcheck passes for metrics-server.sh" "PASS"
	else
		test_result "shellcheck passes for metrics-server.sh" "FAIL" "ShellCheck found issues"
	fi
else
	test_result "shellcheck passes for metrics-server.sh" "SKIP" "ShellCheck not installed"
fi

# Test 17: Verify shellcheck passes for metrics-collector.sh
echo "Test 17: Run shellcheck on metrics-collector.sh"
if command -v shellcheck &> /dev/null; then
	if shellcheck docker/metrics-collector.sh 2>/dev/null; then
		test_result "shellcheck passes for metrics-collector.sh" "PASS"
	else
		test_result "shellcheck passes for metrics-collector.sh" "FAIL" "ShellCheck found issues"
	fi
else
	test_result "shellcheck passes for metrics-collector.sh" "SKIP" "ShellCheck not installed"
fi

# Test 18: Verify docker-compose.production.yml syntax
echo "Test 18: Validate docker-compose.production.yml syntax"
if docker compose -f docker/docker-compose.production.yml config --quiet 2>/dev/null; then
	test_result "docker-compose.production.yml syntax valid" "PASS"
else
	test_result "docker-compose.production.yml syntax valid" "FAIL" "Docker Compose validation failed"
fi

# Test 19: Verify netcat is installed in Dockerfile
echo "Test 19: Verify netcat-openbsd is installed in Dockerfile"
if grep -q 'netcat-openbsd' docker/Dockerfile; then
	test_result "netcat-openbsd is installed in Dockerfile" "PASS"
else
	test_result "netcat-openbsd is installed in Dockerfile" "FAIL" "netcat-openbsd not found in package list"
fi

# Test 20: Verify metrics scripts are copied to /usr/local/bin
echo "Test 20: Verify metrics scripts copied to /usr/local/bin"
if grep -q '/usr/local/bin/metrics-server.sh' docker/Dockerfile && \
   grep -q '/usr/local/bin/metrics-collector.sh' docker/Dockerfile; then
	test_result "metrics scripts copied to /usr/local/bin" "PASS"
else
	test_result "metrics scripts copied to /usr/local/bin" "FAIL" "Script installation path incorrect"
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
