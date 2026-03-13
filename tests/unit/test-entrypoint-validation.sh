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

    # Source the script but mock exit and external commands to avoid side effects
    # We only want to test the validation functions that are NOT in utils.sh (e.g., validate_repository)
    local tmp_funcs=$(mktemp)
    sed -n '/^validate_repository()/,/^}/p' "$script" >> "$tmp_funcs"
    sed -n '/^validate_hostname()/,/^}/p' "$script" >> "$tmp_funcs"
    source "$tmp_funcs"

    local failed=false

    # Test validate_numeric
    if ! validate_numeric "9091" "PORT" > /dev/null; then log_error "validate_numeric failed for valid input"; failed=true; fi
    if validate_numeric "abc" "PORT" > /dev/null; then log_error "validate_numeric passed for invalid input (abc)"; failed=true; fi
    if validate_numeric "12.34" "PORT" > /dev/null; then log_error "validate_numeric passed for invalid input (12.34)"; failed=true; fi
    if validate_numeric "" "PORT" > /dev/null; then log_error "validate_numeric passed for empty input"; failed=true; fi

    # Test validate_path
    if ! validate_path "/tmp/metrics.prom" ".prom" > /dev/null; then log_error "validate_path failed for valid .prom path"; failed=true; fi
    if ! validate_path "/tmp/jobs.log" ".log" > /dev/null; then log_error "validate_path failed for valid .log path"; failed=true; fi
    if validate_path "/etc/passwd" ".prom" > /dev/null; then log_error "validate_path passed for invalid directory (/etc)"; failed=true; fi
    if validate_path "/tmp/metrics.txt" ".prom" > /dev/null; then log_error "validate_path passed for invalid extension (.txt)"; failed=true; fi
    if validate_path "/tmp/../etc/passwd" ".prom" > /dev/null; then log_error "validate_path passed for path traversal (..)"; failed=true; fi

    # Test validate_repository (still in entrypoint scripts)
    if ! validate_repository "owner/repo" > /dev/null; then log_error "validate_repository failed for valid repository"; failed=true; fi
    if validate_repository "owner-repo" > /dev/null; then log_error "validate_repository passed for invalid repository"; failed=true; fi

    rm "$tmp_funcs"

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
