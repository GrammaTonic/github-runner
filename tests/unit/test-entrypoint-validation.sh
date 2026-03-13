#!/bin/bash
# Unit Test: Entrypoint Input Validation
# Validates the input validation logic in entrypoint scripts

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

ENTRYPOINTS=("docker/entrypoint.sh" "docker/entrypoint-chrome.sh")

test_validation() {
    local script=$1
    log_info "Testing validation logic for $script..."

    # Source the shared utility script
    if [ -f "docker/utils.sh" ]; then
        source "docker/utils.sh"
    else
        log_error "docker/utils.sh not found"
        return 1
    fi

    local failed=false

    # Test validate_number
    if ! validate_number "PORT" "9091" > /dev/null; then log_error "validate_number failed for valid input"; failed=true; fi
    if validate_number "PORT" "abc" > /dev/null; then log_error "validate_number passed for invalid input (abc)"; failed=true; fi
    if validate_number "PORT" "12.34" > /dev/null; then log_error "validate_number passed for invalid input (12.34)"; failed=true; fi
    if validate_number "PORT" "" > /dev/null; then log_error "validate_number passed for empty input"; failed=true; fi

    # Test validate_path
    if ! validate_path "METRICS_FILE" "/tmp/metrics.prom" "prom" > /dev/null; then log_error "validate_path failed for valid .prom path"; failed=true; fi
    if ! validate_path "JOBS_LOG" "/tmp/jobs.log" "log" > /dev/null; then log_error "validate_path failed for valid .log path"; failed=true; fi
    if validate_path "FILE" "/etc/passwd" "prom" > /dev/null; then log_error "validate_path passed for invalid directory (/etc)"; failed=true; fi
    if validate_path "FILE" "/tmp/metrics.txt" "prom" > /dev/null; then log_error "validate_path passed for invalid extension (.txt)"; failed=true; fi
    if validate_path "FILE" "/tmp/../etc/passwd" "prom" > /dev/null; then log_error "validate_path passed for path traversal (..)"; failed=true; fi

    # Test validate_repository
    if ! validate_repository "owner/repo" > /dev/null; then log_error "validate_repository failed for valid repository"; failed=true; fi
    if validate_repository "owner-repo" > /dev/null; then log_error "validate_repository passed for invalid repository"; failed=true; fi

    # Test validate_hostname
    if ! validate_hostname "github.com" > /dev/null; then log_error "validate_hostname failed for valid hostname"; failed=true; fi
    if validate_hostname "github.com; rm -rf /" > /dev/null; then log_error "validate_hostname passed for invalid hostname"; failed=true; fi

    # Test validate_runner_name
    if ! validate_runner_name "RUNNER_NAME" "runner-1.dot" > /dev/null; then log_error "validate_runner_name failed for valid name"; failed=true; fi
    if validate_runner_name "RUNNER_NAME" "runner; bash" > /dev/null; then log_error "validate_runner_name passed for invalid name"; failed=true; fi

    if [ "$failed" = true ]; then
        return 1
    fi
    return 0
}

overall_failed=false
for script in "${ENTRYPOINTS[@]}"; do
    if ! test_validation "$script"; then
        overall_failed=true
    fi
done

if [ "$overall_failed" = true ]; then
    log_error "✗ Entrypoint validation tests FAILED"
    exit 1
else
    log_info "✓ Entrypoint validation tests PASSED"
    exit 0
fi
