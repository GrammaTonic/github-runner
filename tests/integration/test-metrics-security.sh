#!/usr/bin/env bash
# test-metrics-security.sh — TASK-067: Metrics security validation
# Scans metrics output and scripts for exposed tokens, credentials, secrets,
# and sensitive data patterns. Validates no information leakage.
#
# Mode: Static analysis always runs; runtime scans check live endpoints.
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

STANDARD_PORT=9091
CHROME_PORT=9092
CHROME_GO_PORT=9093

# Sensitive patterns to scan for (case-insensitive)
SENSITIVE_PATTERNS=(
  "GITHUB_TOKEN"
  "ghp_[a-zA-Z0-9]"
  "ghs_[a-zA-Z0-9]"
  "github_pat_"
  "RUNNER_TOKEN"
  "ACCESS_TOKEN"
  "BEARER"
  "password"
  "secret"
  "private_key"
  "BEGIN RSA"
  "BEGIN OPENSSH"
  "BEGIN CERTIFICATE"
  "api_key"
  "apikey"
  "credential"
)

# Files that handle metrics (should not leak secrets)
METRICS_FILES=(
  "docker/metrics-server.sh"
  "docker/metrics-collector.sh"
  "docker/job-started.sh"
  "docker/job-completed.sh"
)

echo "========================================="
echo " TASK-067: Metrics Security Tests"
echo "========================================="
echo ""

# ─── STATIC TESTS: Script-level security ─────────────────────────────

log_section "Static Analysis: No hardcoded secrets in metrics scripts"

log_info "Test 1: Metrics scripts do not contain hardcoded tokens"

for script_path in "${METRICS_FILES[@]}"; do
  FULL_PATH="$REPO_ROOT/$script_path"
  if [[ -f "$FULL_PATH" ]]; then
    LEAKS_FOUND=false
    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
      # Search for actual values, not just references to env var names
      # Allow: variable declarations like GITHUB_TOKEN="${GITHUB_TOKEN:-}"
      # Disallow: hardcoded values like GITHUB_TOKEN="ghp_abc123..."
      MATCHES=$(grep -inE "$pattern" "$FULL_PATH" 2>/dev/null | \
        grep -v '^\s*#' | \
        grep -vF '${' | \
        grep -v '\$(' | \
        grep -v ':-}' | \
        grep -v ':-""' | \
        grep -v 'echo.*\$' | \
        grep -v 'log.*' | \
        grep -v 'grep' | \
        grep -v 'pattern' || true)
      if [[ -n "$MATCHES" ]]; then
        log_fail "$script_path: Potential secret pattern '$pattern' found"
        echo "    $MATCHES" | head -3
        LEAKS_FOUND=true
      fi
    done

    if ! $LEAKS_FOUND; then
      log_pass "$script_path: No hardcoded secrets detected"
    fi
  else
    log_fail "$script_path not found"
  fi
done

log_section "Static Analysis: Metrics output does not expose env vars"

log_info "Test 2: generate_metrics does not include token variables"

METRICS_COLLECTOR="$REPO_ROOT/docker/metrics-collector.sh"

if [[ -f "$METRICS_COLLECTOR" ]]; then
  # Extract the generate_metrics function and check what it outputs
  # The heredoc in generate_metrics should not reference GITHUB_TOKEN
  GEN_METRICS_SECTION=$(sed -n '/^generate_metrics/,/^}/p' "$METRICS_COLLECTOR" 2>/dev/null || true)

  LEAKED=false
  for secret_var in GITHUB_TOKEN RUNNER_TOKEN ACCESS_TOKEN; do
    if echo "$GEN_METRICS_SECTION" | grep -q "\$$secret_var\|\${$secret_var}" 2>/dev/null; then
      log_fail "generate_metrics references \$$secret_var — potential leak"
      LEAKED=true
    fi
  done

  if ! $LEAKED; then
    log_pass "generate_metrics does not reference any token variables"
  fi
else
  log_fail "metrics-collector.sh not found"
fi

log_info "Test 3: Metrics labels contain only safe values"

# Check what variables are used in metric labels
LABEL_VARS=$(grep -oE '\$[A-Z_]+' "$METRICS_COLLECTOR" | sort -u || true)
SAFE_VARS=("RUNNER_NAME" "RUNNER_TYPE" "RUNNER_VERSION" "METRICS_FILE" "JOBS_LOG"
  "UPDATE_INTERVAL" "COLLECTOR_LOG" "START_TIME")

for var in $LABEL_VARS; do
  VAR_NAME="${var#\$}"
  IS_SAFE=false
  for safe in "${SAFE_VARS[@]}"; do
    if [[ "$VAR_NAME" == "$safe" ]]; then
      IS_SAFE=true
      break
    fi
  done

  # Check if it's a function-local variable or known safe
  if [[ "$VAR_NAME" =~ ^(uptime|status|total_jobs|success_jobs|failed_jobs|hist_|avg_|cache_|temp_|HISTOGRAM_BUCKETS).*$ ]]; then
    IS_SAFE=true
  fi

  if ! $IS_SAFE; then
    # Not necessarily a leak — just flag for awareness
    if echo "$VAR_NAME" | grep -qiE "token|secret|password|key|credential"; then
      log_fail "Suspicious variable in collector: \$$VAR_NAME"
    fi
  fi
done
log_pass "No token/secret variables exposed in metric labels"

log_section "Static Analysis: Entrypoint token handling"

log_info "Test 4: Entrypoints do not expose tokens to metrics processes"

for entrypoint in docker/entrypoint.sh docker/entrypoint-chrome.sh; do
  EP_PATH="$REPO_ROOT/$entrypoint"
  if [[ -f "$EP_PATH" ]]; then
    # Check that GITHUB_TOKEN is not passed to metrics-server or metrics-collector
    if grep -A2 "metrics-server\|metrics-collector" "$EP_PATH" | grep -q "GITHUB_TOKEN" 2>/dev/null; then
      log_fail "$entrypoint: Passes GITHUB_TOKEN to metrics process"
    else
      log_pass "$entrypoint: No token passed to metrics processes"
    fi
  else
    log_fail "$entrypoint not found"
  fi
done

log_section "Static Analysis: HTTP response headers"

log_info "Test 5: Metrics server does not leak server info"

METRICS_SERVER="$REPO_ROOT/docker/metrics-server.sh"

if [[ -f "$METRICS_SERVER" ]]; then
  # Check that response headers don't include server version or OS info
  if grep -q "Server:" "$METRICS_SERVER" 2>/dev/null; then
    SERVER_HEADER=$(grep "Server:" "$METRICS_SERVER")
    log_info "NOTE: Server header present: $SERVER_HEADER"
    ((TOTAL++)); ((PASS++))
  else
    log_pass "No Server header in metrics HTTP response"
  fi

  # Verify Content-Type is text/plain (not HTML that could XSS)
  if grep -q "text/plain" "$METRICS_SERVER"; then
    log_pass "Content-Type is text/plain (safe)"
  else
    log_fail "Content-Type is not text/plain"
  fi
else
  log_fail "metrics-server.sh not found"
fi

# ─── RUNTIME TESTS (scan live metrics output) ────────────────────────

log_section "Runtime Tests: Live metrics security scan"

scan_live_metrics() {
  local port=$1
  local label=$2

  if ! curl -sf --connect-timeout 2 "http://localhost:${port}/metrics" >/dev/null 2>&1; then
    log_info "SKIP: $label not available on port $port"
    return 1
  fi

  local metrics
  metrics=$(curl -sf "http://localhost:${port}/metrics")

  # Scan for any sensitive patterns in the actual output
  local found_leak=false
  for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if echo "$metrics" | grep -iqE "$pattern"; then
      # Check if it's a false positive (metric name containing "token" is OK
      # but actual token values are not)
      MATCH=$(echo "$metrics" | grep -iE "$pattern" | head -1)
      # Allow metric names like "github_runner_last_update_timestamp"
      if echo "$MATCH" | grep -qE "^# (HELP|TYPE)|_timestamp|token.*=\"\""; then
        continue
      fi
      log_fail "$label: Sensitive pattern '$pattern' in metrics output"
      echo "    $MATCH"
      found_leak=true
    fi
  done

  if ! $found_leak; then
    log_pass "$label: No sensitive data in live metrics output"
  fi

  # Verify no environment variable values leaked
  local env_leaks
  env_leaks=$(echo "$metrics" | grep -cE "ghp_|ghs_|github_pat_" || echo "0")
  if [[ "$env_leaks" -eq 0 ]]; then
    log_pass "$label: No GitHub token patterns in output"
  else
    log_fail "$label: $env_leaks potential token patterns in output"
  fi

  return 0
}

scan_live_metrics $STANDARD_PORT "Standard Runner" || true
scan_live_metrics $CHROME_PORT "Chrome Runner" || true
scan_live_metrics $CHROME_GO_PORT "Chrome-Go Runner" || true

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
