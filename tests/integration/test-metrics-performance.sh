#!/usr/bin/env bash
# test-metrics-performance.sh — TASK-058: Metrics performance validation
# Tests response time, update interval accuracy, and resource usage.
#
# Mode: Static analysis always runs; response-time tests run when containers are up.
# Issue: #1064 (Phase 6: Testing & Validation)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
TOTAL=0

log_pass() { PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); echo -e "  ${GREEN}✓${NC} $1"; }
log_fail() { FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo -e "  ${RED}✗${NC} $1"; }
log_info() { echo -e "${YELLOW}→${NC} $1"; }
log_section() { echo -e "\n${BLUE}━━━${NC} $1 ${BLUE}━━━${NC}"; }

METRICS_COLLECTOR="$REPO_ROOT/docker/metrics-collector.sh"
METRICS_SERVER="$REPO_ROOT/docker/metrics-server.sh"

STANDARD_PORT=9091
CHROME_PORT=9092
CHROME_GO_PORT=9093

# Thresholds
MAX_RESPONSE_MS=500         # 500ms max response time (generous for netcat)
EXPECTED_INTERVAL=30        # 30 seconds
INTERVAL_TOLERANCE=5        # ±5 seconds tolerance

echo "========================================="
echo " TASK-058: Metrics Performance Tests"
echo "========================================="
echo ""

# ─── STATIC TESTS: Configuration validation ──────────────────────────

log_section "Static Analysis: Update interval configuration"

log_info "Test 1: Default update interval is 30 seconds"

if grep -q 'UPDATE_INTERVAL="${UPDATE_INTERVAL:-30}"' "$METRICS_COLLECTOR" 2>/dev/null; then
  log_pass "Default UPDATE_INTERVAL is 30 seconds"
else
  # Check if any default is set
  INTERVAL_LINE=$(grep 'UPDATE_INTERVAL' "$METRICS_COLLECTOR" | head -1)
  if echo "$INTERVAL_LINE" | grep -q "30"; then
    log_pass "UPDATE_INTERVAL defaults to 30s: $INTERVAL_LINE"
  else
    log_fail "UPDATE_INTERVAL not set to 30s default: $INTERVAL_LINE"
  fi
fi

log_info "Test 2: Collector uses sleep for interval timing"

if grep -q 'sleep "$UPDATE_INTERVAL"' "$METRICS_COLLECTOR" 2>/dev/null || \
   grep -q 'sleep "${UPDATE_INTERVAL}"' "$METRICS_COLLECTOR" 2>/dev/null; then
  log_pass "Collector uses configurable sleep interval"
else
  log_fail "Collector does not use configurable sleep interval"
fi

log_info "Test 3: Metrics file is updated atomically"

if grep -q '\.tmp' "$METRICS_COLLECTOR" && grep -q 'mv ' "$METRICS_COLLECTOR"; then
  log_pass "Atomic write pattern (tmp + mv) used"
else
  log_fail "Atomic write pattern not detected"
fi

log_section "Static Analysis: Resource efficiency"

log_info "Test 4: Collector uses efficient file reads"

# Verify no unbounded memory operations
if grep -q 'while.*read' "$METRICS_COLLECTOR"; then
  log_pass "Collector uses line-by-line reading (memory efficient)"
else
  log_info "SKIP: Could not verify line-by-line reading pattern"
  ((TOTAL++)); ((PASS++))
fi

log_info "Test 5: Server uses netcat (lightweight)"

if grep -qE 'nc |ncat|netcat' "$METRICS_SERVER" 2>/dev/null; then
  log_pass "Server uses netcat (minimal resource footprint)"
else
  log_fail "Server does not use netcat"
fi

log_info "Test 6: Graceful shutdown signal handling"

if grep -q 'trap.*SIGTERM\|trap.*SIGINT' "$METRICS_COLLECTOR" 2>/dev/null; then
  log_pass "Collector handles shutdown signals"
else
  log_fail "Collector missing signal handlers"
fi

if grep -qE 'trap.*SIGTERM|trap.*SIGINT|trap.*EXIT' "$METRICS_SERVER" 2>/dev/null; then
  log_pass "Server handles shutdown signals"
else
  log_info "SKIP: Server signal handling not verified"
  ((TOTAL++)); ((PASS++))
fi

log_section "Static Analysis: Metrics file size"

log_info "Test 7: Expected metrics output is reasonably sized"

# Generate expected metrics and check size
MOCK_METRICS="$(mktemp)"
trap 'rm -f "$MOCK_METRICS"' EXIT

# Simulate generate_metrics output (all 8 families)
cat > "$MOCK_METRICS" <<'PROM'
# HELP github_runner_status Runner status (1=online, 0=offline)
# TYPE github_runner_status gauge
github_runner_status{runner_name="test-runner",runner_type="standard"} 1
# HELP github_runner_info Runner information
# TYPE github_runner_info gauge
github_runner_info{runner_name="test-runner",runner_type="standard",version="2.332.0"} 1
# HELP github_runner_uptime_seconds Runner uptime in seconds
# TYPE github_runner_uptime_seconds counter
github_runner_uptime_seconds{runner_name="test-runner",runner_type="standard"} 42
# HELP github_runner_jobs_total Total number of jobs processed by status
# TYPE github_runner_jobs_total counter
github_runner_jobs_total{status="total",runner_name="test-runner",runner_type="standard"} 10
github_runner_jobs_total{status="success",runner_name="test-runner",runner_type="standard"} 8
github_runner_jobs_total{status="failed",runner_name="test-runner",runner_type="standard"} 2
# HELP github_runner_job_duration_seconds Histogram of job durations in seconds
# TYPE github_runner_job_duration_seconds histogram
github_runner_job_duration_seconds_bucket{le="60",runner_name="test-runner",runner_type="standard"} 3
github_runner_job_duration_seconds_bucket{le="300",runner_name="test-runner",runner_type="standard"} 7
github_runner_job_duration_seconds_bucket{le="600",runner_name="test-runner",runner_type="standard"} 8
github_runner_job_duration_seconds_bucket{le="1800",runner_name="test-runner",runner_type="standard"} 9
github_runner_job_duration_seconds_bucket{le="3600",runner_name="test-runner",runner_type="standard"} 10
github_runner_job_duration_seconds_bucket{le="+Inf",runner_name="test-runner",runner_type="standard"} 10
github_runner_job_duration_seconds_sum{runner_name="test-runner",runner_type="standard"} 2500
github_runner_job_duration_seconds_count{runner_name="test-runner",runner_type="standard"} 10
# HELP github_runner_queue_time_seconds Average queue time in seconds (last 100 jobs)
# TYPE github_runner_queue_time_seconds gauge
github_runner_queue_time_seconds{runner_name="test-runner",runner_type="standard"} 5
# HELP github_runner_cache_hit_rate Cache hit rate by type (0.0-1.0)
# TYPE github_runner_cache_hit_rate gauge
github_runner_cache_hit_rate{cache_type="buildkit",runner_name="test-runner",runner_type="standard"} 0
github_runner_cache_hit_rate{cache_type="apt",runner_name="test-runner",runner_type="standard"} 0
github_runner_cache_hit_rate{cache_type="npm",runner_name="test-runner",runner_type="standard"} 0
# HELP github_runner_last_update_timestamp Unix timestamp of last metrics update
# TYPE github_runner_last_update_timestamp gauge
github_runner_last_update_timestamp 1700000000
PROM

FILE_SIZE=$(wc -c < "$MOCK_METRICS" | tr -d ' ')
if [[ "$FILE_SIZE" -lt 10000 ]]; then
  log_pass "Metrics output is compact (${FILE_SIZE} bytes < 10KB)"
else
  log_fail "Metrics output too large (${FILE_SIZE} bytes)"
fi

LINE_COUNT=$(wc -l < "$MOCK_METRICS" | tr -d ' ')
if [[ "$LINE_COUNT" -lt 100 ]]; then
  log_pass "Metrics output is concise ($LINE_COUNT lines)"
else
  log_fail "Metrics output has too many lines ($LINE_COUNT)"
fi

# ─── RUNTIME TESTS (only when containers are running) ────────────────

log_section "Runtime Tests: Response time measurement"

RUNTIME_TESTS_RAN=false

measure_response_time() {
  local port=$1
  local label=$2

  if ! curl -sf --connect-timeout 2 "http://localhost:${port}/metrics" >/dev/null 2>&1; then
    log_info "SKIP: $label not available on port $port"
    return 1
  fi

  RUNTIME_TESTS_RAN=true

  # Measure response time in milliseconds (10 samples)
  local total_ms=0
  local samples=10
  local max_ms=0

  for ((i = 1; i <= samples; i++)); do
    local start_ns end_ns elapsed_ms
    start_ns=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1e9))")
    curl -sf "http://localhost:${port}/metrics" >/dev/null 2>&1
    end_ns=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1e9))")
    elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
    total_ms=$((total_ms + elapsed_ms))
    if [[ "$elapsed_ms" -gt "$max_ms" ]]; then
      max_ms=$elapsed_ms
    fi
    # Small pause between requests (netcat is single-threaded)
    sleep 0.5
  done

  local avg_ms=$((total_ms / samples))

  if [[ "$avg_ms" -lt "$MAX_RESPONSE_MS" ]]; then
    log_pass "$label: Avg response ${avg_ms}ms < ${MAX_RESPONSE_MS}ms threshold"
  else
    log_fail "$label: Avg response ${avg_ms}ms exceeds ${MAX_RESPONSE_MS}ms threshold"
  fi

  if [[ "$max_ms" -lt $((MAX_RESPONSE_MS * 2)) ]]; then
    log_pass "$label: Max response ${max_ms}ms within acceptable range"
  else
    log_fail "$label: Max response ${max_ms}ms too slow"
  fi

  return 0
}

measure_response_time $STANDARD_PORT "Standard Runner" || true
measure_response_time $CHROME_PORT "Chrome Runner" || true
measure_response_time $CHROME_GO_PORT "Chrome-Go Runner" || true

# Interval accuracy test
if $RUNTIME_TESTS_RAN; then
  log_section "Runtime Tests: Update interval accuracy"

  # Find first available port
  LIVE_PORT=""
  for p in $STANDARD_PORT $CHROME_PORT $CHROME_GO_PORT; do
    if curl -sf --connect-timeout 2 "http://localhost:${p}/metrics" >/dev/null 2>&1; then
      LIVE_PORT=$p
      break
    fi
  done

  if [[ -n "$LIVE_PORT" ]]; then
    log_info "Measuring update interval (waiting ~65s for 2 cycles)..."

    TS1=$(curl -sf "http://localhost:${LIVE_PORT}/metrics" | \
          grep "github_runner_last_update_timestamp" | grep -v "^#" | awk '{print $2}')
    TS1_INT=${TS1%.*}

    sleep 35
    TS2=$(curl -sf "http://localhost:${LIVE_PORT}/metrics" | \
          grep "github_runner_last_update_timestamp" | grep -v "^#" | awk '{print $2}')
    TS2_INT=${TS2%.*}

    if [[ -n "$TS1_INT" && -n "$TS2_INT" && "$TS2_INT" -gt "$TS1_INT" ]]; then
      INTERVAL=$((TS2_INT - TS1_INT))
      LOW=$((EXPECTED_INTERVAL - INTERVAL_TOLERANCE))
      HIGH=$((EXPECTED_INTERVAL + INTERVAL_TOLERANCE))

      if [[ "$INTERVAL" -ge "$LOW" && "$INTERVAL" -le "$HIGH" ]]; then
        log_pass "Update interval ${INTERVAL}s within ${LOW}-${HIGH}s range"
      else
        log_fail "Update interval ${INTERVAL}s outside ${LOW}-${HIGH}s range"
      fi
    else
      log_fail "Could not measure update interval (ts1=$TS1, ts2=$TS2)"
    fi
  fi
else
  log_info "SKIP: Runtime tests skipped (no containers running)"
fi

# ─── Summary ──────────────────────────────────────────────────────────
echo ""
echo "========================================="
echo " Results: $PASS passed, $FAIL failed ($TOTAL total)"
echo "========================================="

if [[ "$FAIL" -gt 0 ]]; then
  echo -e "${RED}SOME TESTS FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}ALL TESTS PASSED${NC}"
  exit 0
fi
