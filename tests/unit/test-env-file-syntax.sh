#!/bin/bash
# Unit Test: Environment File Syntax Validation
# Validates syntax of all .env files in config/

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

failed=false

for envfile in config/*.env*; do
  log_info "Validating syntax for $envfile..."
  while IFS= read -r line; do
    [[ "$line" =~ ^# ]] && continue
    [[ -z "$line" ]] && continue
    if ! [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      log_error "Invalid syntax in $envfile: $line"
      echo "$envfile: INVALID $line" >> "$TEST_RESULTS_DIR/env-syntax.log"
      failed=true
    fi
  done < "$envfile"
  log_info "Syntax OK for $envfile"
  done

if [[ "$failed" == "true" ]]; then
  log_error "✗ Environment file syntax validation FAILED"
  exit 1
else
  log_info "✓ Environment file syntax validation PASSED"
  exit 0
fi
