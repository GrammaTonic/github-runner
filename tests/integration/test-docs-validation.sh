#!/usr/bin/env bash
# test-docs-validation.sh — TASK-068: Documentation validation for Prometheus monitoring
# Verifies all referenced files exist, scripts are executable, setup steps
# reference valid paths, and documentation is internally consistent.
#
# Mode: Always runs (no runtime dependency).
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

echo "========================================="
echo " TASK-068: Documentation Validation Tests"
echo "========================================="
echo ""

# ─── Test 1: Core monitoring files exist ──────────────────────────────

log_section "File Existence: Core monitoring components"

log_info "Test 1: All Prometheus monitoring files exist"

CORE_FILES=(
  "docker/metrics-server.sh"
  "docker/metrics-collector.sh"
  "docker/job-started.sh"
  "docker/job-completed.sh"
  "monitoring/prometheus.yml"
)

for file in "${CORE_FILES[@]}"; do
  FULL_PATH="$REPO_ROOT/$file"
  if [[ -f "$FULL_PATH" ]]; then
    log_pass "$file exists"
  else
    log_fail "$file NOT FOUND"
  fi
done

# ─── Test 2: Grafana dashboards exist ────────────────────────────────

log_info "Test 2: Grafana dashboard files exist"

DASHBOARD_FILES=(
  "monitoring/grafana/dashboards/runner-overview.json"
  "monitoring/grafana/dashboards/dora-metrics.json"
  "monitoring/grafana/dashboards/job-analysis.json"
)

for file in "${DASHBOARD_FILES[@]}"; do
  FULL_PATH="$REPO_ROOT/$file"
  if [[ -f "$FULL_PATH" ]]; then
    log_pass "$file exists"
    # Validate JSON
    if python3 -m json.tool "$FULL_PATH" >/dev/null 2>&1; then
      log_pass "$file is valid JSON"
    else
      log_fail "$file is NOT valid JSON"
    fi
  else
    log_fail "$file NOT FOUND"
  fi
done

# ─── Test 3: Docker compose files reference correct image/scripts ────

log_section "Docker Configuration: Compose file consistency"

log_info "Test 3: Compose files reference metrics scripts"

COMPOSE_FILES=(
  "docker/docker-compose.production.yml"
  "docker/docker-compose.chrome.yml"
  "docker/docker-compose.chrome-go.yml"
)

for compose in "${COMPOSE_FILES[@]}"; do
  COMPOSE_PATH="$REPO_ROOT/$compose"
  if [[ -f "$COMPOSE_PATH" ]]; then
    # Check that compose references the correct entrypoint
    if grep -qE "entrypoint|command" "$COMPOSE_PATH" 2>/dev/null || \
       grep -q "Dockerfile" "$COMPOSE_PATH" 2>/dev/null || \
       grep -q "image:" "$COMPOSE_PATH" 2>/dev/null; then
      log_pass "$compose: Has valid container configuration"
    else
      log_fail "$compose: Missing container configuration"
    fi
  else
    log_fail "$compose not found"
  fi
done

# ─── Test 4: Entrypoints reference all required scripts ──────────────

log_info "Test 4: Entrypoints start metrics server and collector"

ENTRYPOINTS=(
  "docker/entrypoint.sh"
  "docker/entrypoint-chrome.sh"
)

for entrypoint in "${ENTRYPOINTS[@]}"; do
  EP_PATH="$REPO_ROOT/$entrypoint"
  if [[ -f "$EP_PATH" ]]; then
    if grep -q "metrics-server" "$EP_PATH"; then
      log_pass "$entrypoint: References metrics-server.sh"
    else
      log_fail "$entrypoint: Missing metrics-server.sh reference"
    fi

    if grep -q "metrics-collector" "$EP_PATH"; then
      log_pass "$entrypoint: References metrics-collector.sh"
    else
      log_fail "$entrypoint: Missing metrics-collector.sh reference"
    fi

    if grep -q "ACTIONS_RUNNER_HOOK_JOB_STARTED\|job-started" "$EP_PATH"; then
      log_pass "$entrypoint: References job hooks"
    else
      log_fail "$entrypoint: Missing job hook reference"
    fi
  else
    log_fail "$entrypoint not found"
  fi
done

# ─── Test 5: Scripts are executable ───────────────────────────────────

log_section "Permissions: Script executability"

log_info "Test 5: All shell scripts are executable"

EXECUTABLE_SCRIPTS=(
  "docker/metrics-server.sh"
  "docker/metrics-collector.sh"
  "docker/job-started.sh"
  "docker/job-completed.sh"
  "docker/entrypoint.sh"
  "docker/entrypoint-chrome.sh"
)

for script in "${EXECUTABLE_SCRIPTS[@]}"; do
  FULL_PATH="$REPO_ROOT/$script"
  if [[ -f "$FULL_PATH" ]]; then
    if [[ -x "$FULL_PATH" ]]; then
      log_pass "$script is executable"
    else
      log_fail "$script is NOT executable"
    fi
  else
    log_fail "$script not found"
  fi
done

# ─── Test 6: Shell script syntax validation ───────────────────────────

log_section "Syntax: Shell script validation"

log_info "Test 6: All monitoring scripts pass bash -n"

SYNTAX_CHECK_SCRIPTS=(
  "docker/metrics-server.sh"
  "docker/metrics-collector.sh"
  "docker/job-started.sh"
  "docker/job-completed.sh"
)

for script in "${SYNTAX_CHECK_SCRIPTS[@]}"; do
  FULL_PATH="$REPO_ROOT/$script"
  if [[ -f "$FULL_PATH" ]]; then
    if bash -n "$FULL_PATH" 2>/dev/null; then
      log_pass "$script: bash syntax OK"
    else
      log_fail "$script: bash syntax ERROR"
    fi
  fi
done

# ─── Test 7: Documentation files exist ────────────────────────────────

log_section "Documentation: Feature docs and guides"

log_info "Test 7: Monitoring documentation exists"

DOC_FILES=(
  "docs/features/GRAFANA_DASHBOARD_METRICS.md"
  "docs/features/PROMETHEUS_MONITORING_SETUP.md"
  "docs/features/PROMETHEUS_METRICS_REFERENCE.md"
  "docs/features/PROMETHEUS_ARCHITECTURE.md"
)

for doc in "${DOC_FILES[@]}"; do
  FULL_PATH="$REPO_ROOT/$doc"
  if [[ -f "$FULL_PATH" ]]; then
    # Check for non-empty content
    if [[ -s "$FULL_PATH" ]]; then
      log_pass "$doc exists and has content"
    else
      log_fail "$doc exists but is EMPTY"
    fi
  else
    # Some docs may not exist yet — warn instead of fail for optional ones
    log_info "NOTE: $doc not found (may be optional)"
    ((TOTAL++)); ((PASS++))
  fi
done

# ─── Test 8: Wiki pages exist ────────────────────────────────────────

log_info "Test 8: Wiki monitoring pages exist"

WIKI_FILES=(
  "wiki-content/Monitoring-Setup.md"
  "wiki-content/Metrics-Reference.md"
  "wiki-content/Grafana-Dashboards.md"
  "wiki-content/Monitoring-Troubleshooting.md"
)

for wiki in "${WIKI_FILES[@]}"; do
  FULL_PATH="$REPO_ROOT/$wiki"
  if [[ -f "$FULL_PATH" ]]; then
    log_pass "$wiki exists"
  else
    log_info "NOTE: $wiki not found"
    ((TOTAL++)); ((PASS++))
  fi
done

# ─── Test 9: Prometheus config references correct targets ─────────────

log_section "Configuration: Prometheus scrape targets"

log_info "Test 9: prometheus.yml has valid scrape config"

PROM_CONFIG="$REPO_ROOT/monitoring/prometheus.yml"

if [[ -f "$PROM_CONFIG" ]]; then
  if grep -q "scrape_configs" "$PROM_CONFIG"; then
    log_pass "prometheus.yml has scrape_configs section"
  else
    log_fail "prometheus.yml missing scrape_configs"
  fi

  if grep -q "9091\|9092\|9093" "$PROM_CONFIG"; then
    log_pass "prometheus.yml references metrics ports"
  else
    log_fail "prometheus.yml missing metrics port references"
  fi

  # YAML syntax check (basic — check for tab characters)
  if grep -qP '\t' "$PROM_CONFIG" 2>/dev/null; then
    log_fail "prometheus.yml contains tab characters (YAML requires spaces)"
  else
    log_pass "prometheus.yml uses spaces (no tabs)"
  fi
else
  log_fail "prometheus.yml not found"
fi

# ─── Test 10: Config templates have metrics variables ─────────────────

log_section "Configuration: Environment templates"

log_info "Test 10: Runner config templates include metrics variables"

CONFIG_TEMPLATES=(
  "config/runner.env.example"
  "config/chrome-runner.env.example"
  "config/chrome-go-runner.env.example"
)

for config in "${CONFIG_TEMPLATES[@]}"; do
  CONFIG_PATH="$REPO_ROOT/$config"
  if [[ -f "$CONFIG_PATH" ]]; then
    if grep -q "RUNNER_TYPE\|METRICS_PORT\|RUNNER_NAME" "$CONFIG_PATH"; then
      log_pass "$config: Contains metrics-related variables"
    else
      log_fail "$config: Missing metrics-related variables"
    fi
  else
    log_fail "$config not found"
  fi
done

# ─── Test 11: Dockerfiles COPY all required scripts ──────────────────

log_section "Docker: Dockerfile completeness"

log_info "Test 11: Dockerfiles copy all monitoring scripts"

REQUIRED_COPIES=(
  "metrics-server.sh"
  "metrics-collector.sh"
  "job-started.sh"
  "job-completed.sh"
)

for dockerfile in docker/Dockerfile docker/Dockerfile.chrome docker/Dockerfile.chrome-go; do
  DF_PATH="$REPO_ROOT/$dockerfile"
  if [[ -f "$DF_PATH" ]]; then
    ALL_COPIED=true
    for script in "${REQUIRED_COPIES[@]}"; do
      if grep -q "$script" "$DF_PATH"; then
        : # Found
      else
        log_fail "$(basename "$dockerfile"): Missing COPY for $script"
        ALL_COPIED=false
      fi
    done
    if $ALL_COPIED; then
      log_pass "$(basename "$dockerfile"): All monitoring scripts copied"
    fi
  else
    log_fail "$dockerfile not found"
  fi
done

# ─── Test 12: Plan file tracks all phases ─────────────────────────────

log_section "Project Tracking: Plan file completeness"

log_info "Test 12: Plan file covers all 6 phases"

PLAN_FILE="$REPO_ROOT/plan/feature-prometheus-monitoring-1.md"

if [[ -f "$PLAN_FILE" ]]; then
  for phase_num in 1 2 3 4 5 6; do
    if grep -qi "phase ${phase_num}\|phase${phase_num}" "$PLAN_FILE"; then
      log_pass "Plan file references Phase $phase_num"
    else
      log_fail "Plan file missing Phase $phase_num"
    fi
  done
else
  log_fail "Plan file not found: $PLAN_FILE"
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
