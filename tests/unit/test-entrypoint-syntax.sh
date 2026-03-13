#!/bin/bash
# Unit Test: Entrypoint Script Syntax and Env Validation
# Validates shell syntax and checks for required environment variables in entrypoint scripts

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-./test-results/unit}"
mkdir -p "$TEST_RESULTS_DIR"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

ENTRYPOINTS=("docker/entrypoint.sh" "docker/entrypoint-chrome.sh")
REQUIRED_ENV_VARS=("RUNNER_NAME" "RUNNER_TOKEN" "GITHUB_REPOSITORY")

failed=false

for script in "${ENTRYPOINTS[@]}"; do
  log_info "Checking syntax for $script..."
  if ! bash -n "$script"; then
    log_error "Syntax error in $script"
    echo "$script: SYNTAX ERROR" >> "$TEST_RESULTS_DIR/entrypoint-syntax.log"
    failed=true
  else
    log_info "Syntax OK for $script"
  fi

  log_info "Checking required environment variables in $script..."
  for var in "${REQUIRED_ENV_VARS[@]}"; do
    if ! grep -q "$var" "$script"; then
      log_warn "Missing required env var $var in $script"
      echo "$script: MISSING ENV $var" >> "$TEST_RESULTS_DIR/entrypoint-env.log"
    fi
  done

done

if [[ "$failed" == "true" ]]; then
  log_error "✗ Entrypoint syntax validation FAILED"
  exit 1
else
  log_info "✓ Entrypoint syntax validation PASSED"
  exit 0
fi
