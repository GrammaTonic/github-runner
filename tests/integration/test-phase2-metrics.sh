#!/bin/bash
# Phase 2 Integration Test: Chrome & Chrome-Go Metrics Validation
# Tests TASK-020 through TASK-026 for Issue #1060

set -euo pipefail

# --- CONFIGURATION ---
CHROME_METRICS_PORT=9092
CHROME_GO_METRICS_PORT=9093
STANDARD_METRICS_PORT=9091
TIMEOUT=120  # seconds to wait for metrics to be available

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- HELPER FUNCTIONS ---
log_info() {
	echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

wait_for_metrics() {
	local port=$1
	local runner_type=$2
	local start_time=$(date +%s)

	log_info "Waiting for $runner_type metrics endpoint on port $port..."

	while true; do
		if curl -sf "http://localhost:${port}/metrics" >/dev/null 2>&1; then
			log_info "$runner_type metrics endpoint is ready!"
			return 0
		fi

		local current_time=$(date +%s)
		local elapsed=$((current_time - start_time))

		if [ $elapsed -gt $TIMEOUT ]; then
			log_error "$runner_type metrics endpoint not available after ${TIMEOUT}s"
			return 1
		fi

		sleep 2
	done
}

validate_metrics() {
	local port=$1
	local expected_runner_type=$2
	local test_name=$3

	log_info "Validating $test_name metrics..."

	# Fetch metrics
	local metrics=$(curl -sf "http://localhost:${port}/metrics")

	if [ -z "$metrics" ]; then
		log_error "No metrics returned from port $port"
		return 1
	fi

	# Check for required metrics
	local required_metrics=(
		"github_runner_status"
		"github_runner_info"
		"github_runner_uptime_seconds"
		"github_runner_jobs_total"
		"github_runner_last_update_timestamp"
	)

	for metric in "${required_metrics[@]}"; do
		if ! echo "$metrics" | grep -q "$metric"; then
			log_error "Missing required metric: $metric"
			return 1
		fi
	done

	# Verify runner_type label
	if ! echo "$metrics" | grep -q "runner_type=\"${expected_runner_type}\""; then
		log_error "Runner type label incorrect. Expected: $expected_runner_type"
		echo "Metrics output:"
		echo "$metrics" | grep "runner_type"
		return 1
	fi

	# Verify Prometheus format compliance
	if ! echo "$metrics" | grep -q "# HELP"; then
		log_error "Missing HELP comments in metrics"
		return 1
	fi

	if ! echo "$metrics" | grep -q "# TYPE"; then
		log_error "Missing TYPE comments in metrics"
		return 1
	fi

	log_info "✓ All required metrics present for $test_name"
	log_info "✓ Runner type label correct: $expected_runner_type"
	log_info "✓ Prometheus format valid"

	return 0
}

# --- TASK-024: Validate Chrome Metrics ---
test_chrome_metrics() {
	log_info "===== TASK-024: Testing Chrome Runner Metrics ====="

	wait_for_metrics $CHROME_METRICS_PORT "Chrome" || return 1
	validate_metrics $CHROME_METRICS_PORT "chrome" "Chrome Runner" || return 1

	log_info "✓ TASK-024 PASSED: Chrome metrics validated"
	return 0
}

# --- TASK-025: Validate Chrome-Go Metrics ---
test_chrome_go_metrics() {
	log_info "===== TASK-025: Testing Chrome-Go Runner Metrics ====="

	wait_for_metrics $CHROME_GO_METRICS_PORT "Chrome-Go" || return 1
	validate_metrics $CHROME_GO_METRICS_PORT "chrome-go" "Chrome-Go Runner" || return 1

	log_info "✓ TASK-025 PASSED: Chrome-Go metrics validated"
	return 0
}

# --- TASK-026: Test Concurrent Multi-Runner Deployment ---
test_concurrent_deployment() {
	log_info "===== TASK-026: Testing Concurrent Multi-Runner Deployment ====="

	log_info "Checking all three runner types are accessible..."

	# Check standard runner
	if curl -sf "http://localhost:${STANDARD_METRICS_PORT}/metrics" >/dev/null 2>&1; then
		log_info "✓ Standard runner metrics accessible on port $STANDARD_METRICS_PORT"
	else
		log_warn "Standard runner not running (optional for this test)"
	fi

	# Check Chrome runner
	if curl -sf "http://localhost:${CHROME_METRICS_PORT}/metrics" >/dev/null 2>&1; then
		log_info "✓ Chrome runner metrics accessible on port $CHROME_METRICS_PORT"
	else
		log_error "Chrome runner metrics not accessible"
		return 1
	fi

	# Check Chrome-Go runner
	if curl -sf "http://localhost:${CHROME_GO_METRICS_PORT}/metrics" >/dev/null 2>&1; then
		log_info "✓ Chrome-Go runner metrics accessible on port $CHROME_GO_METRICS_PORT"
	else
		log_error "Chrome-Go runner metrics not accessible"
		return 1
	fi

	# Verify no port conflicts
	log_info "Verifying no port conflicts..."

	local chrome_metrics=$(curl -sf "http://localhost:${CHROME_METRICS_PORT}/metrics")
	local chrome_go_metrics=$(curl -sf "http://localhost:${CHROME_GO_METRICS_PORT}/metrics")

	if echo "$chrome_metrics" | grep -q "runner_type=\"chrome\"" && \
		! echo "$chrome_metrics" | grep -q "runner_type=\"chrome-go\""; then
		log_info "✓ Chrome runner on correct port (9092)"
	else
		log_error "Chrome runner port conflict detected"
		return 1
	fi

	if echo "$chrome_go_metrics" | grep -q "runner_type=\"chrome-go\"" && \
		! echo "$chrome_go_metrics" | grep -q "runner_type=\"chrome\""; then
		log_info "✓ Chrome-Go runner on correct port (9093)"
	else
		log_error "Chrome-Go runner port conflict detected"
		return 1
	fi

	log_info "✓ TASK-026 PASSED: All runners running concurrently without conflicts"
	return 0
}

# --- MAIN TEST EXECUTION ---
main() {
	log_info "Starting Phase 2 Metrics Integration Tests"
	log_info "Testing Chrome and Chrome-Go runner metrics endpoints"
	echo ""

	local failed_tests=0

	# Run tests
	test_chrome_metrics || ((failed_tests++))
	echo ""

	test_chrome_go_metrics || ((failed_tests++))
	echo ""

	test_concurrent_deployment || ((failed_tests++))
	echo ""

	# Summary
	log_info "===== TEST SUMMARY ====="
	if [ $failed_tests -eq 0 ]; then
		log_info "✓ ALL TESTS PASSED (3/3)"
		log_info "Phase 2 implementation validated successfully!"
		return 0
	else
		log_error "✗ $failed_tests TEST(S) FAILED"
		return 1
	fi
}

# Run main if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
	main "$@"
fi
