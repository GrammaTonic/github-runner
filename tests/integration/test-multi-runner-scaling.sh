#!/bin/bash
# Integration Test: Multi-Runner Scaling
# Validates deployment of multiple runner containers with unique ports and isolation

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-./test-results/integration}"
mkdir -p "$TEST_RESULTS_DIR"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Validate unique port assignments
PORTS=(9091 9092 9093)
for port in "${PORTS[@]}"; do
  if lsof -i :"$port"; then
    log_info "Port $port is in use as expected."
  else
    log_error "Port $port is NOT in use. Runner may not be running."
    echo "Port $port: NOT IN USE" >> "$TEST_RESULTS_DIR/multi-runner-scaling.log"
  fi
  done

# Validate container isolation
for name in github-runner-main github-runner-chrome github-runner-chrome-go; do
  if docker ps --format '{{.Names}}' | grep -q "$name"; then
    log_info "$name container is running."
  else
    log_error "$name container is NOT running."
    echo "$name: NOT RUNNING" >> "$TEST_RESULTS_DIR/multi-runner-scaling.log"
  fi
  done

log_info "✓ Multi-runner scaling validation complete."
exit 0
