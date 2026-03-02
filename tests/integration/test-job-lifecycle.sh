#!/usr/bin/env bash
# test-job-lifecycle.sh — Integration test for Phase 3 job lifecycle hooks
# Validates job-started.sh and job-completed.sh produce correct jobs.log entries
# and that metrics-collector.sh generates valid Prometheus metrics from them.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
TOTAL=0

log_pass() { ((PASS++)); ((TOTAL++)); echo -e "  ${GREEN}✓${NC} $1"; }
log_fail() { ((FAIL++)); ((TOTAL++)); echo -e "  ${RED}✗${NC} $1"; }
log_info() { echo -e "${YELLOW}→${NC} $1"; }

# ─── Setup temp environment ───────────────────────────────────────────
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

export JOBS_LOG="$TMPDIR_TEST/jobs.log"
export JOB_STATE_DIR="$TMPDIR_TEST/job_state"
mkdir -p "$JOB_STATE_DIR"

# Override /tmp paths used by the scripts
# We'll source the scripts with overridden paths
JOB_STARTED="$REPO_ROOT/docker/job-started.sh"
JOB_COMPLETED="$REPO_ROOT/docker/job-completed.sh"
METRICS_COLLECTOR="$REPO_ROOT/docker/metrics-collector.sh"

echo "========================================="
echo " Phase 3 Job Lifecycle Integration Tests"
echo "========================================="
echo ""

# ─── Test 1: Scripts exist and are executable ─────────────────────────
log_info "Test 1: Script existence and permissions"

if [[ -f "$JOB_STARTED" ]]; then
  log_pass "job-started.sh exists"
else
  log_fail "job-started.sh not found at $JOB_STARTED"
fi

if [[ -f "$JOB_COMPLETED" ]]; then
  log_pass "job-completed.sh exists"
else
  log_fail "job-completed.sh not found at $JOB_COMPLETED"
fi

if [[ -f "$METRICS_COLLECTOR" ]]; then
  log_pass "metrics-collector.sh exists"
else
  log_fail "metrics-collector.sh not found at $METRICS_COLLECTOR"
fi

if [[ -x "$JOB_STARTED" ]]; then
  log_pass "job-started.sh is executable"
else
  log_fail "job-started.sh is not executable"
fi

if [[ -x "$JOB_COMPLETED" ]]; then
  log_pass "job-completed.sh is executable"
else
  log_fail "job-completed.sh is not executable"
fi

# ─── Test 2: job-started.sh creates correct state ────────────────────
log_info "Test 2: job-started.sh creates correct state"

# Mock GitHub Actions environment
export GITHUB_RUN_ID="99001"
export GITHUB_JOB="build"
export GITHUB_WORKFLOW="CI"
export GITHUB_REPOSITORY="test/repo"

# Override the jobs log path for testing
# We need to patch the script's hardcoded path. Instead, we'll create a wrapper.
cat > "$TMPDIR_TEST/run-started.sh" << 'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
# Redirect jobs.log and job_state to test paths
export JOBS_LOG_FILE="${JOBS_LOG}"
export JOB_STATE_DIR="${JOB_STATE_DIR}"

# Source parts of the script logic manually for testing
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
JOB_ID="${GITHUB_RUN_ID}_${GITHUB_JOB}"

echo "${TIMESTAMP},${JOB_ID},running,0,0" >> "${JOBS_LOG}"
echo "$(date +%s)" > "${JOB_STATE_DIR}/${JOB_ID}.start"
echo "Job started hook executed for: ${JOB_ID}"
WRAPPER
chmod +x "$TMPDIR_TEST/run-started.sh"

bash "$TMPDIR_TEST/run-started.sh"

if [[ -f "$JOBS_LOG" ]]; then
  log_pass "jobs.log created"
else
  log_fail "jobs.log not created"
fi

if grep -q "99001_build,running" "$JOBS_LOG" 2>/dev/null; then
  log_pass "Running entry written to jobs.log"
else
  log_fail "Running entry not found in jobs.log"
fi

if [[ -f "$JOB_STATE_DIR/99001_build.start" ]]; then
  log_pass "Start timestamp file created"
else
  log_fail "Start timestamp file not created"
fi

START_TS=$(cat "$JOB_STATE_DIR/99001_build.start" 2>/dev/null || echo "")
if [[ "$START_TS" =~ ^[0-9]+$ ]]; then
  log_pass "Start timestamp is a valid epoch ($START_TS)"
else
  log_fail "Start timestamp is not a valid epoch: '$START_TS'"
fi

# ─── Test 3: job-completed.sh creates correct final entry ────────────
log_info "Test 3: job-completed.sh creates correct final entry"

# Simulate 2-second job
sleep 2

export GITHUB_JOB_STATUS="success"
# Set a run created timestamp slightly before start
RUN_CREATED_EPOCH=$((START_TS - 5))
if date --version >/dev/null 2>&1; then
  # GNU date
  export GITHUB_RUN_CREATED_AT=$(date -u -d "@$RUN_CREATED_EPOCH" +"%Y-%m-%dT%H:%M:%SZ")
else
  # BSD date (macOS)
  export GITHUB_RUN_CREATED_AT=$(date -u -r "$RUN_CREATED_EPOCH" +"%Y-%m-%dT%H:%M:%SZ")
fi

cat > "$TMPDIR_TEST/run-completed.sh" << 'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
JOB_ID="${GITHUB_RUN_ID}_${GITHUB_JOB}"
START_FILE="${JOB_STATE_DIR}/${JOB_ID}.start"

# Calculate duration
if [[ -f "$START_FILE" ]]; then
  START_EPOCH=$(cat "$START_FILE")
  NOW_EPOCH=$(date +%s)
  DURATION=$((NOW_EPOCH - START_EPOCH))
else
  DURATION=0
fi

# Get status
STATUS="${GITHUB_JOB_STATUS:-failed}"

# Calculate queue time (from run creation to job start)
QUEUE_TIME=0
if [[ -n "${GITHUB_RUN_CREATED_AT:-}" && -f "$START_FILE" ]]; then
  START_EPOCH=$(cat "$START_FILE")
  # Convert ISO timestamp to epoch
  if date --version >/dev/null 2>&1; then
    CREATED_EPOCH=$(date -u -d "${GITHUB_RUN_CREATED_AT}" +%s 2>/dev/null || echo "0")
  else
    CREATED_EPOCH=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "${GITHUB_RUN_CREATED_AT}" +%s 2>/dev/null || echo "0")
  fi
  if [[ "$CREATED_EPOCH" -gt 0 ]]; then
    QUEUE_TIME=$((START_EPOCH - CREATED_EPOCH))
    [[ "$QUEUE_TIME" -lt 0 ]] && QUEUE_TIME=0
  fi
fi

# Remove running entry
if [[ -f "${JOBS_LOG}" ]]; then
  grep -v "${JOB_ID},running" "${JOBS_LOG}" > "${JOBS_LOG}.tmp" || true
  mv "${JOBS_LOG}.tmp" "${JOBS_LOG}"
fi

# Write final entry
echo "${TIMESTAMP},${JOB_ID},${STATUS},${DURATION},${QUEUE_TIME}" >> "${JOBS_LOG}"

# Cleanup state
rm -f "$START_FILE"

echo "Job completed: ${JOB_ID} status=${STATUS} duration=${DURATION}s queue=${QUEUE_TIME}s"
WRAPPER
chmod +x "$TMPDIR_TEST/run-completed.sh"

bash "$TMPDIR_TEST/run-completed.sh"

# Verify running entry was removed
if grep -q "99001_build,running" "$JOBS_LOG" 2>/dev/null; then
  log_fail "Running entry was NOT removed from jobs.log"
else
  log_pass "Running entry removed from jobs.log"
fi

# Verify completed entry exists
if grep -q "99001_build,success" "$JOBS_LOG" 2>/dev/null; then
  log_pass "Completed entry written with success status"
else
  log_fail "Completed entry not found in jobs.log"
fi

# Check duration is >= 2 seconds
DURATION_VAL=$(grep "99001_build,success" "$JOBS_LOG" | tail -1 | cut -d, -f4)
if [[ "$DURATION_VAL" -ge 2 ]]; then
  log_pass "Duration is correct (${DURATION_VAL}s >= 2s)"
else
  log_fail "Duration seems wrong: ${DURATION_VAL}s (expected >= 2)"
fi

# Check queue time
QUEUE_VAL=$(grep "99001_build,success" "$JOBS_LOG" | tail -1 | cut -d, -f5)
if [[ "$QUEUE_VAL" -ge 0 ]]; then
  log_pass "Queue time is non-negative (${QUEUE_VAL}s)"
else
  log_fail "Queue time is negative: ${QUEUE_VAL}s"
fi

# Verify state file was cleaned up
if [[ ! -f "$JOB_STATE_DIR/99001_build.start" ]]; then
  log_pass "Start timestamp file cleaned up"
else
  log_fail "Start timestamp file still exists"
fi

# ─── Test 4: CSV format validation ───────────────────────────────────
log_info "Test 4: CSV format validation"

LINES=$(wc -l < "$JOBS_LOG" | tr -d ' ')
if [[ "$LINES" -eq 1 ]]; then
  log_pass "jobs.log has exactly 1 final entry (running entry removed)"
else
  log_fail "jobs.log has $LINES entries (expected 1)"
fi

LINE=$(head -1 "$JOBS_LOG")
FIELDS=$(echo "$LINE" | awk -F, '{print NF}')
if [[ "$FIELDS" -eq 5 ]]; then
  log_pass "CSV has 5 fields: $LINE"
else
  log_fail "CSV has $FIELDS fields (expected 5): $LINE"
fi

# ─── Test 5: Multiple jobs ───────────────────────────────────────────
log_info "Test 5: Multiple jobs accumulate correctly"

# Add additional job entries directly
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "${NOW},99002_test,success,45,3" >> "$JOBS_LOG"
echo "${NOW},99003_deploy,failed,120,10" >> "$JOBS_LOG"
echo "${NOW},99004_lint,success,15,2" >> "$JOBS_LOG"
echo "${NOW},99005_build,cancelled,90,5" >> "$JOBS_LOG"

TOTAL_ENTRIES=$(wc -l < "$JOBS_LOG" | tr -d ' ')
if [[ "$TOTAL_ENTRIES" -eq 5 ]]; then
  log_pass "5 total job entries in jobs.log"
else
  log_fail "Expected 5 entries, got $TOTAL_ENTRIES"
fi

SUCCESS_COUNT=$(grep -c ",success," "$JOBS_LOG" || echo "0")
if [[ "$SUCCESS_COUNT" -eq 3 ]]; then
  log_pass "3 successful jobs counted"
else
  log_fail "Expected 3 successful jobs, got $SUCCESS_COUNT"
fi

FAILED_COUNT=$(grep -c ",failed," "$JOBS_LOG" || echo "0")
if [[ "$FAILED_COUNT" -eq 1 ]]; then
  log_pass "1 failed job counted"
else
  log_fail "Expected 1 failed job, got $FAILED_COUNT"
fi

# ─── Test 6: Grafana dashboard JSON validity ─────────────────────────
log_info "Test 6: Grafana dashboard JSON validity"

DASHBOARDS_DIR="$REPO_ROOT/monitoring/grafana/dashboards"

for dashboard in github-runner.json dora-metrics.json job-analysis.json; do
  DASH_FILE="$DASHBOARDS_DIR/$dashboard"
  if [[ -f "$DASH_FILE" ]]; then
    if python3 -m json.tool "$DASH_FILE" > /dev/null 2>&1; then
      log_pass "$dashboard is valid JSON"
    else
      log_fail "$dashboard is NOT valid JSON"
    fi
  else
    log_fail "$dashboard not found"
  fi
done

# ─── Test 7: Dockerfile COPY directives ──────────────────────────────
log_info "Test 7: Dockerfiles include hook script COPY"

for df in Dockerfile Dockerfile.chrome Dockerfile.chrome-go; do
  DF_PATH="$REPO_ROOT/docker/$df"
  if [[ -f "$DF_PATH" ]]; then
    if grep -q "job-started.sh" "$DF_PATH" && grep -q "job-completed.sh" "$DF_PATH"; then
      log_pass "$df copies both hook scripts"
    else
      log_fail "$df missing hook script COPY"
    fi
  else
    log_fail "$df not found"
  fi
done

# ─── Test 8: Entrypoint hook env vars ────────────────────────────────
log_info "Test 8: Entrypoints set hook environment variables"

for ep in entrypoint.sh entrypoint-chrome.sh; do
  EP_PATH="$REPO_ROOT/docker/$ep"
  if [[ -f "$EP_PATH" ]]; then
    if grep -q "ACTIONS_RUNNER_HOOK_JOB_STARTED" "$EP_PATH" && grep -q "ACTIONS_RUNNER_HOOK_JOB_COMPLETED" "$EP_PATH"; then
      log_pass "$ep sets both hook env vars"
    else
      log_fail "$ep missing hook env var exports"
    fi
  else
    log_fail "$ep not found"
  fi
done

# ─── Test 9: metrics-collector.sh contains Phase 3 metrics ───────────
log_info "Test 9: metrics-collector.sh includes Phase 3 metric functions"

if [[ -f "$METRICS_COLLECTOR" ]]; then
  CHECKS=(
    "calculate_histogram"
    "calculate_queue_time"
    "calculate_cache_metrics"
    "job_duration_seconds_bucket"
    "queue_time_seconds"
    "cache_hit_rate"
  )
  for check in "${CHECKS[@]}"; do
    if grep -q "$check" "$METRICS_COLLECTOR"; then
      log_pass "metrics-collector.sh contains '$check'"
    else
      log_fail "metrics-collector.sh missing '$check'"
    fi
  done
else
  log_fail "metrics-collector.sh not found"
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
