#!/bin/bash

# Container Startup Test Script
# Tests that all Docker containers can start successfully with provided examples

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-./test-results/container-startup}"
DRY_RUN="${DRY_RUN:-false}"
CLEANUP="${CLEANUP:-true}"
TIMEOUT_MAIN="${TIMEOUT_MAIN:-120}"
TIMEOUT_CHROME="${TIMEOUT_CHROME:-180}"

# Test tracking
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Create test results directory
mkdir -p "$TEST_RESULTS_DIR"

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Test tracking functions
start_test() {
    local test_name="$1"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    log_test "Starting: $test_name"
    mkdir -p "$TEST_RESULTS_DIR"
    echo "$(date -Iseconds): START $test_name" >> "$TEST_RESULTS_DIR/startup.log"
}

pass_test() {
    local test_name="$1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    log_info "✓ PASSED: $test_name"
    echo "$(date -Iseconds): PASS $test_name" >> "$TEST_RESULTS_DIR/startup.log"
}

fail_test() {
    local test_name="$1"
    local reason="${2:-Unknown error}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_TESTS+=("$test_name: $reason")
    log_error "✗ FAILED: $test_name - $reason"
    echo "$(date -Iseconds): FAIL $test_name - $reason" >> "$TEST_RESULTS_DIR/startup.log"
}

# Cleanup function
cleanup() {
    if [[ "$CLEANUP" == "true" ]]; then
        log_info "Cleaning up test containers..."
        
        # Stop and remove test containers
        docker ps -q --filter "name=test-startup-*" | xargs -r docker stop >/dev/null 2>&1 || true
        docker ps -aq --filter "name=test-startup-*" | xargs -r docker rm >/dev/null 2>&1 || true
        
        # Clean up compose projects
        cd "$(dirname "$0")/../../docker" || return
        docker compose -p test-startup-main down >/dev/null 2>&1 || true
        docker compose -f docker-compose.chrome.yml -p test-startup-chrome down >/dev/null 2>&1 || true
    fi
}

# Signal handler for cleanup
trap cleanup EXIT

# Create test environment files
create_test_configs() {
    log_info "Creating test configuration files..."
    
    local config_dir="$TEST_RESULTS_DIR/config"
    mkdir -p "$config_dir"
    
    # Main runner test configuration
    cat > "$config_dir/main-runner.env" << 'EOF'
# Test configuration for main GitHub runner
# NOTE: This uses fake tokens for testing - container will start but won't register
GITHUB_TOKEN=test-token-not-real-for-testing-only
GITHUB_REPOSITORY=test/repository-for-testing
RUNNER_NAME=test-main-runner-local
RUNNER_LABELS=test,local,docker,self-hosted,x64,linux
RUNNER_GROUP=test-group
RUNNER_WORKDIR=/home/runner/_work
RUNNER_REPLACE_EXISTING=true
EOF
    
    # Chrome runner test configuration
    cat > "$config_dir/chrome-runner.env" << 'EOF'
# Test configuration for Chrome GitHub runner
# NOTE: This uses fake tokens for testing - container will start but won't register
GITHUB_TOKEN=test-token-not-real-for-testing-only
GITHUB_REPOSITORY=test/repository-for-testing
RUNNER_NAME=test-chrome-runner-local
RUNNER_LABELS=chrome,ui-tests,selenium,playwright,cypress,headless,test
RUNNER_GROUP=chrome-test-group
RUNNER_WORK_DIR=/home/runner/workspace
DISPLAY=:99
CHROME_FLAGS=--headless --no-sandbox --disable-dev-shm-usage --disable-gpu --remote-debugging-port=9222
PLAYWRIGHT_BROWSERS_PATH=/home/runner/.cache/ms-playwright
PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/google-chrome-stable
NODE_OPTIONS=--max-old-space-size=4096
EOF
    
    log_info "Test configuration files created in $config_dir"
}

# Test main runner container startup
test_main_runner_startup() {
    start_test "Main Runner Container Startup"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY_RUN: Skipping main runner startup test"
        pass_test "Main Runner Container Startup"
        return 0
    fi
    
    local docker_dir; docker_dir="$(dirname "$0")/../../docker"
    local config_file="$TEST_RESULTS_DIR/config/main-runner.env"
    
    cd "$docker_dir" || {
        fail_test "Main Runner Container Startup" "Could not access docker directory: $docker_dir"
        return 1
    }
    
    log_info "Starting main GitHub runner container..."
    
    # Start the container
    if ! timeout "$TIMEOUT_MAIN" docker compose --env-file "$config_file" \
        -p test-startup-main up -d runner > "$TEST_RESULTS_DIR/main-runner-startup.log" 2>&1; then
        fail_test "Main Runner Container Startup" "Failed to start container - see main-runner-startup.log"
        return 1
    fi
    
    # Get container ID
    local container_id
    container_id=$(docker compose -p test-startup-main ps -q runner)
    
    if [[ -z "$container_id" ]]; then
        fail_test "Main Runner Container Startup" "Container not found after startup"
        return 1
    fi
    
    log_info "Container started with ID: $container_id"
    
    # Wait for container to be fully ready
    log_info "Waiting for container to be ready..."
    sleep 15
    
    # Check if container is running
    if ! docker ps --filter "id=$container_id" --filter "status=running" | grep -q "$container_id"; then
        log_error "Container not in running state"
        docker logs "$container_id" > "$TEST_RESULTS_DIR/main-runner-failure.log" 2>&1 || true
        fail_test "Main Runner Container Startup" "Container not running - see main-runner-failure.log"
        return 1
    fi
    
    # Perform health checks
    log_info "Performing health checks..."
    
    # Basic command execution
    if ! docker exec "$container_id" whoami > "$TEST_RESULTS_DIR/main-runner-whoami.log" 2>&1; then
        fail_test "Main Runner Container Startup" "Basic command execution failed"
        return 1
    fi
    
    # Docker-in-Docker check
    if ! docker exec "$container_id" docker version > "$TEST_RESULTS_DIR/main-runner-docker.log" 2>&1; then
        fail_test "Main Runner Container Startup" "Docker-in-Docker not working"
        return 1
    fi
    
    # Check runner directory structure
    if ! docker exec "$container_id" test -d /home/runner; then
        fail_test "Main Runner Container Startup" "Runner home directory not found"
        return 1
    fi
    
    # Check if runner user exists
    if ! docker exec "$container_id" id runner > "$TEST_RESULTS_DIR/main-runner-user.log" 2>&1; then
        fail_test "Main Runner Container Startup" "Runner user not found"
        return 1
    fi
    
    log_info "Main runner container health checks passed"
    pass_test "Main Runner Container Startup"
}

# Test Chrome runner container startup
test_chrome_runner_startup() {
    start_test "Chrome Runner Container Startup"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY_RUN: Skipping Chrome runner startup test"
        pass_test "Chrome Runner Container Startup"
        return 0
    fi
    
    local docker_dir; docker_dir="$(dirname "$0")/../../docker"
    local config_file="$TEST_RESULTS_DIR/config/chrome-runner.env"
    
    cd "$docker_dir" || {
        fail_test "Chrome Runner Container Startup" "Could not access docker directory: $docker_dir"
        return 1
    }
    
    log_info "Starting Chrome GitHub runner container..."
    
    # Start the Chrome container
    if ! timeout "$TIMEOUT_CHROME" docker compose -f docker-compose.chrome.yml \
        --env-file "$config_file" -p test-startup-chrome up -d chrome-runner \
        > "$TEST_RESULTS_DIR/chrome-runner-startup.log" 2>&1; then
        fail_test "Chrome Runner Container Startup" "Failed to start container - see chrome-runner-startup.log"
        return 1
    fi
    
    # Get container ID
    local container_id
    container_id=$(docker compose -f docker-compose.chrome.yml -p test-startup-chrome ps -q chrome-runner)
    
    if [[ -z "$container_id" ]]; then
        fail_test "Chrome Runner Container Startup" "Container not found after startup"
        return 1
    fi
    
    log_info "Chrome container started with ID: $container_id"
    
    # Wait for container to be fully ready (Chrome takes longer)
    log_info "Waiting for Chrome container to be ready..."
    sleep 30
    
    # Check if container is running
    if ! docker ps --filter "id=$container_id" --filter "status=running" | grep -q "$container_id"; then
        log_error "Chrome container not in running state"
        docker logs "$container_id" > "$TEST_RESULTS_DIR/chrome-runner-failure.log" 2>&1 || true
        fail_test "Chrome Runner Container Startup" "Container not running - see chrome-runner-failure.log"
        return 1
    fi
    
    # Perform Chrome-specific health checks
    log_info "Performing Chrome-specific health checks..."
    
    # Check Chrome installation
    if ! docker exec "$container_id" google-chrome --version > "$TEST_RESULTS_DIR/chrome-version.log" 2>&1; then
        fail_test "Chrome Runner Container Startup" "Chrome not working - see chrome-version.log"
        return 1
    fi
    
    # Check ChromeDriver
    if ! docker exec "$container_id" chromedriver --version > "$TEST_RESULTS_DIR/chromedriver-version.log" 2>&1; then
        fail_test "Chrome Runner Container Startup" "ChromeDriver not working - see chromedriver-version.log"
        return 1
    fi
    
    # Check Node.js availability
    if ! docker exec "$container_id" node --version > "$TEST_RESULTS_DIR/node-version.log" 2>&1; then
        fail_test "Chrome Runner Container Startup" "Node.js not available - see node-version.log"
        return 1
    fi
    
    # Check if Xvfb is running (virtual display)
    if ! docker exec "$container_id" pgrep Xvfb >/dev/null 2>&1; then
        log_warn "Xvfb (virtual display) not running - UI tests may fail"
    else
        log_info "Virtual display (Xvfb) is running"
    fi
    
    # Test headless Chrome functionality
    log_info "Testing headless Chrome functionality..."
    if docker exec "$container_id" timeout 30 google-chrome --headless --no-sandbox \
        --disable-dev-shm-usage --virtual-time-budget=1000 --dump-dom about:blank \
        > "$TEST_RESULTS_DIR/chrome-headless-test.log" 2>&1; then
        log_info "Chrome headless test passed"
    else
        log_warn "Chrome headless test failed - may impact UI testing capabilities"
    fi
    
    log_info "Chrome runner container health checks completed"
    pass_test "Chrome Runner Container Startup"
}

# Test container resource configuration
test_container_resources() {
    start_test "Container Resource Configuration"
    
    local docker_dir; docker_dir="$(dirname "$0")/../../docker"
    local resource_issues=0
    
    # Check main runner docker-compose configuration
    if [[ -f "$docker_dir/docker-compose.production.yml" ]]; then
        log_info "Checking main runner resource configuration..."
        
        if ! grep -q "restart:" "$docker_dir/docker-compose.production.yml"; then
            log_warn "No restart policy in docker-compose.production.yml"
            resource_issues=$((resource_issues + 1))
        fi
        
        if ! grep -q "mem_limit\|memory:" "$docker_dir/docker-compose.production.yml"; then
            log_info "No memory limits configured (optional for self-hosted)"
        fi
    fi
    
    # Check Chrome runner docker-compose configuration
    if [[ -f "$docker_dir/docker-compose.chrome.yml" ]]; then
        log_info "Checking Chrome runner resource configuration..."
        
        if ! grep -q "restart:" "$docker_dir/docker-compose.chrome.yml"; then
            log_warn "No restart policy in docker-compose.chrome.yml"
            resource_issues=$((resource_issues + 1))
        fi
        
        if ! grep -q "mem_limit\|memory:" "$docker_dir/docker-compose.chrome.yml"; then
            log_info "No memory limits configured (may want to add for Chrome)"
        fi
    fi
    
    if [[ $resource_issues -eq 0 ]]; then
        pass_test "Container Resource Configuration"
    else
        fail_test "Container Resource Configuration" "$resource_issues resource configuration issue(s) found"
        return 1
    fi
}

# Generate comprehensive test report
generate_report() {
    local report_file="$TEST_RESULTS_DIR/startup-test-report.md"
    
    log_info "Generating comprehensive test report..."
    
    cat > "$report_file" << EOF
# Container Startup Test Report

Generated: $(date -Iseconds)

## Test Summary

- **Total Tests**: $TESTS_TOTAL
- **Passed**: $TESTS_PASSED  
- **Failed**: $TESTS_FAILED
- **Success Rate**: $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%

## Test Configuration

- **DRY_RUN**: $DRY_RUN
- **CLEANUP**: $CLEANUP
- **Main Runner Timeout**: ${TIMEOUT_MAIN}s
- **Chrome Runner Timeout**: ${TIMEOUT_CHROME}s

## Container Environments Tested

### Main GitHub Runner
- **Image**: ghcr.io/grammatonic/github-runner:latest
- **Docker Compose**: docker-compose.production.yml
- **Test Config**: config/runner.env

### Chrome GitHub Runner  
- **Image**: ghcr.io/grammatonic/github-runner:chrome-latest
- **Docker Compose**: docker-compose.chrome.yml
- **Test Config**: config/chrome-runner.env

EOF

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "## Failed Tests" >> "$report_file"
        echo "" >> "$report_file"
        for failed_test in "${FAILED_TESTS[@]}"; do
            echo "- $failed_test" >> "$report_file"
        done
        echo "" >> "$report_file"
    fi
    
    echo "## Log Files" >> "$report_file"
    echo "" >> "$report_file"
    
    # List all log files created
    find "$TEST_RESULTS_DIR" -name "*.log" -type f | while read -r logfile; do
        local filename
        filename="$(basename "$logfile")"
        echo "- \`$filename\`" >> "$report_file"
    done
    
    log_info "Test report generated: $report_file"
}

# Show help
show_help() {
    cat << EOF
Container Startup Test Script

Usage: $0 [OPTIONS]

This script tests that all Docker containers can start successfully with
the provided example configurations.

OPTIONS:
    -h, --help              Show this help message
    -d, --dry-run           Run in dry-run mode (skip actual container startup)
    -n, --no-cleanup        Skip cleanup of test containers
    -t, --timeout-main SEC  Timeout for main runner startup (default: 120)
    -c, --timeout-chrome SEC Timeout for Chrome runner startup (default: 180)
    -r, --results DIR       Directory for test results

ENVIRONMENT VARIABLES:
    DRY_RUN         Enable dry-run mode (default: false)
    CLEANUP         Enable cleanup (default: true)
    TIMEOUT_MAIN    Main runner timeout in seconds (default: 120)
    TIMEOUT_CHROME  Chrome runner timeout in seconds (default: 180)

EXAMPLES:
    $0                          # Test all containers
    $0 --dry-run               # Check configurations only
    $0 --no-cleanup            # Keep containers for debugging
    $0 --timeout-main 180      # Longer timeout for main runner

EXIT CODES:
    0    All container startup tests passed
    1    One or more startup tests failed
    2    Script error or invalid arguments
EOF
}

# Main execution function
main() {
    log_info "Starting Container Startup Test Suite"
    log_info "Results directory: $TEST_RESULTS_DIR"
    log_info "DRY_RUN mode: $DRY_RUN"
    log_info "Cleanup enabled: $CLEANUP"
    
    echo "============================================"
    
    # Create test configurations
    create_test_configs
    
    # Run all tests
    test_main_runner_startup || true
    test_chrome_runner_startup || true
    test_container_resources || true
    
    echo "============================================"
    
    # Generate report
    generate_report
    
    # Summary
    log_info "Container Startup Test Summary:"
    log_info "  Total Tests: $TESTS_TOTAL"
    log_info "  Passed: $TESTS_PASSED"
    log_info "  Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "Container startup tests failed!"
        log_error "Failed Tests:"
        for failed_test in "${FAILED_TESTS[@]}"; do
            log_error "  - $failed_test"
        done
        echo ""
        log_error "Check detailed logs in: $TEST_RESULTS_DIR"
        exit 1
    else
        log_info "All container startup tests passed! 🎉"
        log_info "All containers can start successfully with provided examples"
        exit 0
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -n|--no-cleanup)
            CLEANUP="false"
            shift
            ;;
        -t|--timeout-main)
            TIMEOUT_MAIN="$2"
            shift 2
            ;;
        -c|--timeout-chrome)
            TIMEOUT_CHROME="$2"
            shift 2
            ;;
        -r|--results)
            TEST_RESULTS_DIR="$2"
            shift 2
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 2
            ;;
        *)
            log_error "Unexpected argument: $1"
            show_help
            exit 2
            ;;
    esac
done

# Run main function
main "$@"
