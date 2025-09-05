#!/bin/bash

# Comprehensive Integration Test Suite
# Tests Docker builds, container functionality, and prevents regressions

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-./test-results/integration}"
DRY_RUN="${DRY_RUN:-false}"
CLEANUP="${CLEANUP:-true}"
TIMEOUT="${TIMEOUT:-300}"

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
    echo "$(date -Iseconds): START $test_name" >> "$TEST_RESULTS_DIR/test.log"
}

pass_test() {
    local test_name="$1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    log_info "✓ PASSED: $test_name"
    echo "$(date -Iseconds): PASS $test_name" >> "$TEST_RESULTS_DIR/test.log"
}

fail_test() {
    local test_name="$1"
    local reason="${2:-Unknown error}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_TESTS+=("$test_name: $reason")
    log_error "✗ FAILED: $test_name - $reason"
    echo "$(date -Iseconds): FAIL $test_name - $reason" >> "$TEST_RESULTS_DIR/test.log"
}

# Cleanup function
cleanup() {
    if [[ "$CLEANUP" == "true" ]]; then
        log_info "Cleaning up test environment..."
        
        # Stop and remove test containers
        docker ps -q --filter "name=test-runner" | xargs -r docker stop > /dev/null 2>&1 || true
        docker ps -aq --filter "name=test-runner" | xargs -r docker rm > /dev/null 2>&1 || true
        
        # Remove test images
        docker images -q --filter "reference=test-github-runner*" | xargs -r docker rmi > /dev/null 2>&1 || true
        
        # Clean up test networks
        docker network ls -q --filter "name=test-runner*" | xargs -r docker network rm > /dev/null 2>&1 || true
    fi
}

# Signal handler for cleanup
trap cleanup EXIT

# Test 1: Docker Package Validation
test_docker_package_validation() {
    start_test "Docker Package Validation"
    
    local script_path="$(dirname "$0")/validate-packages.sh"
    
    if [[ ! -f "$script_path" ]]; then
        fail_test "Docker Package Validation" "Package validation script not found"
        return 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        DRY_RUN=true "$script_path" > "$TEST_RESULTS_DIR/package-validation.log" 2>&1
        pass_test "Docker Package Validation (dry-run)"
        return 0
    fi
    
    if "$script_path" > "$TEST_RESULTS_DIR/package-validation.log" 2>&1; then
        pass_test "Docker Package Validation"
    else
        fail_test "Docker Package Validation" "Package validation failed - see package-validation.log"
        return 1
    fi
}

# Test 2: Dockerfile Syntax Validation
test_dockerfile_syntax() {
    start_test "Dockerfile Syntax Validation"
    
    local docker_dir="$(dirname "$0")/../../docker"
    local syntax_errors=0
    
    # Find all Dockerfiles
    while IFS= read -r -d '' dockerfile; do
        local dockerfile_name
        dockerfile_name="$(basename "$dockerfile")"
        
        log_info "Validating syntax for $dockerfile_name..."
        
        # Test Dockerfile syntax using hadolint if available, or basic docker build dry-run
        if command -v hadolint > /dev/null 2>&1; then
            if ! hadolint "$dockerfile" > "$TEST_RESULTS_DIR/hadolint-$dockerfile_name.log" 2>&1; then
                log_warn "Hadolint warnings for $dockerfile_name (see hadolint-$dockerfile_name.log)"
            fi
        fi
        
        # Test with Docker build dry-run (syntax validation)
        if [[ "$DRY_RUN" != "true" ]]; then
            if ! docker build --dry-run -f "$dockerfile" "$(dirname "$dockerfile")" > "$TEST_RESULTS_DIR/build-test-$dockerfile_name.log" 2>&1; then
                log_error "Dockerfile syntax error in $dockerfile_name"
                syntax_errors=$((syntax_errors + 1))
            fi
        fi
        
    done < <(find "$docker_dir" -name "Dockerfile*" -type f -print0)
    
    if [[ $syntax_errors -eq 0 ]]; then
        pass_test "Dockerfile Syntax Validation"
    else
        fail_test "Dockerfile Syntax Validation" "$syntax_errors Dockerfile(s) have syntax errors"
        return 1
    fi
}

# Test 3: Docker Build Test (Core Runner)
test_docker_build_core() {
    start_test "Docker Build - Core Runner"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        pass_test "Docker Build - Core Runner (dry-run)"
        return 0
    fi
    
    local build_log="$TEST_RESULTS_DIR/build-core.log"
    local docker_dir="$(dirname "$0")/../../docker"
    
    # Build core runner image
    if timeout "$TIMEOUT" docker build -t test-github-runner:core -f "$docker_dir/Dockerfile" "$docker_dir" > "$build_log" 2>&1; then
        pass_test "Docker Build - Core Runner"
        
        # Test basic container functionality
        if docker run --rm --name test-runner-core test-github-runner:core echo "Container test successful" > "$TEST_RESULTS_DIR/container-test-core.log" 2>&1; then
            log_info "Core runner container test passed"
        else
            log_warn "Core runner container test failed"
        fi
    else
        fail_test "Docker Build - Core Runner" "Build failed or timed out - see build-core.log"
        return 1
    fi
}

# Test 4: Docker Build Test (Chrome Runner)
test_docker_build_chrome() {
    start_test "Docker Build - Chrome Runner"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        pass_test "Docker Build - Chrome Runner (dry-run)"
        return 0
    fi
    
    local build_log="$TEST_RESULTS_DIR/build-chrome.log"
    local docker_dir="$(dirname "$0")/../../docker"
    
    # Build Chrome runner image
    if timeout "$TIMEOUT" docker build -t test-github-runner:chrome -f "$docker_dir/Dockerfile.chrome" "$docker_dir" > "$build_log" 2>&1; then
        pass_test "Docker Build - Chrome Runner"
        
        # Test Chrome installation
        if docker run --rm --name test-runner-chrome test-github-runner:chrome google-chrome --version > "$TEST_RESULTS_DIR/chrome-version.log" 2>&1; then
            log_info "Chrome installation test passed"
            cat "$TEST_RESULTS_DIR/chrome-version.log"
        else
            log_warn "Chrome installation test failed"
        fi
    else
        fail_test "Docker Build - Chrome Runner" "Build failed or timed out - see build-chrome.log"
        return 1
    fi
}

# Test 5: Docker Compose Validation
test_docker_compose() {
    start_test "Docker Compose Validation"
    
    local docker_dir="$(dirname "$0")/../../docker"
    local compose_errors=0
    
    # Test all docker-compose files
    for compose_file in "$docker_dir"/docker-compose*.yml; do
        if [[ -f "$compose_file" ]]; then
            local compose_name
            compose_name="$(basename "$compose_file")"
            
            log_info "Validating $compose_name..."
            
            if ! docker compose -f "$compose_file" config --quiet > "$TEST_RESULTS_DIR/compose-$compose_name.log" 2>&1; then
                log_error "Docker Compose validation failed for $compose_name"
                compose_errors=$((compose_errors + 1))
            fi
        fi
    done
    
    if [[ $compose_errors -eq 0 ]]; then
        pass_test "Docker Compose Validation"
    else
        fail_test "Docker Compose Validation" "$compose_errors compose file(s) have validation errors"
        return 1
    fi
}

# Test 6: Configuration File Validation
test_configuration_files() {
    start_test "Configuration File Validation"
    
    local config_dir="$(dirname "$0")/../../config"
    local config_errors=0
    
    # Required variables for runner configuration
    local required_vars=("GITHUB_TOKEN" "GITHUB_REPOSITORY")
    
    # Test environment file templates
    for config_file in "$config_dir"/*.env*; do
        if [[ -f "$config_file" ]]; then
            local config_name
            config_name="$(basename "$config_file")"
            
            log_info "Validating $config_name..."
            
            # Check for required variables
            for var in "${required_vars[@]}"; do
                if ! grep -q "^$var" "$config_file" && ! grep -q "^#.*$var" "$config_file"; then
                    log_warn "$var not found in $config_name"
                fi
            done
            
            # Check for syntax errors (basic shell variable format)
            if ! bash -n "$config_file" > /dev/null 2>&1; then
                log_error "Syntax error in $config_name"
                config_errors=$((config_errors + 1))
            fi
        fi
    done
    
    if [[ $config_errors -eq 0 ]]; then
        pass_test "Configuration File Validation"
    else
        fail_test "Configuration File Validation" "$config_errors configuration file(s) have errors"
        return 1
    fi
}

# Test 7: Script Validation
test_scripts() {
    start_test "Script Validation"
    
    local scripts_dir="$(dirname "$0")/../../scripts"
    local script_errors=0
    
    # Test all shell scripts
    for script in "$scripts_dir"/*.sh; do
        if [[ -f "$script" ]]; then
            local script_name
            script_name="$(basename "$script")"
            
            log_info "Validating script $script_name..."
            
            # Syntax check
            if ! bash -n "$script" > "$TEST_RESULTS_DIR/script-$script_name.log" 2>&1; then
                log_error "Syntax error in $script_name"
                script_errors=$((script_errors + 1))
            fi
            
            # Check for common issues
            if grep -q "rm -rf /" "$script"; then
                log_error "Dangerous rm command found in $script_name"
                script_errors=$((script_errors + 1))
            fi
            
            # Check for required shebang
            if ! head -1 "$script" | grep -q "^#!/"; then
                log_warn "Missing shebang in $script_name"
            fi
            
            # Check for set -e (error handling)
            if ! grep -q "set -e" "$script"; then
                log_warn "Missing 'set -e' in $script_name (consider adding for error handling)"
            fi
        fi
    done
    
    if [[ $script_errors -eq 0 ]]; then
        pass_test "Script Validation"
    else
        fail_test "Script Validation" "$script_errors script(s) have errors"
        return 1
    fi
}

# Test 8: Chrome Specific Tests
test_chrome_specific() {
    start_test "Chrome Specific Tests"
    
    local docker_dir="$(dirname "$0")/../../docker"
    local chrome_errors=0
    
    # Test Chrome entrypoint script
    local chrome_entrypoint="$docker_dir/entrypoint-chrome.sh"
    if [[ -f "$chrome_entrypoint" ]]; then
        # Syntax check
        if ! bash -n "$chrome_entrypoint" > "$TEST_RESULTS_DIR/chrome-entrypoint.log" 2>&1; then
            log_error "Chrome entrypoint script has syntax errors"
            chrome_errors=$((chrome_errors + 1))
        fi
        
        # Check for Chrome validation logic
        if ! grep -q "google-chrome" "$chrome_entrypoint"; then
            log_warn "Chrome validation logic not found in entrypoint"
        fi
        
        # Check for Xvfb setup
        if ! grep -q "Xvfb" "$chrome_entrypoint"; then
            log_warn "Xvfb setup not found in Chrome entrypoint"
        fi
    else
        log_error "Chrome entrypoint script not found"
        chrome_errors=$((chrome_errors + 1))
    fi
    
    # Test Chrome installation script
    local chrome_install="$docker_dir/install-chromedriver.sh"
    if [[ -f "$chrome_install" ]]; then
        if ! bash -n "$chrome_install" > "$TEST_RESULTS_DIR/chrome-install.log" 2>&1; then
            log_error "Chrome install script has syntax errors"
            chrome_errors=$((chrome_errors + 1))
        fi
    fi
    
    if [[ $chrome_errors -eq 0 ]]; then
        pass_test "Chrome Specific Tests"
    else
        fail_test "Chrome Specific Tests" "$chrome_errors Chrome-related error(s)"
        return 1
    fi
}

# Test 9: Security Baseline Test
test_security_baseline() {
    start_test "Security Baseline Test"
    
    local security_errors=0
    
    # Check for secrets in files
    local sensitive_patterns=("password" "secret" "token" "key" "auth")
    
    for pattern in "${sensitive_patterns[@]}"; do
        # Skip test files and logs
        if grep -r -i "$pattern" "$(dirname "$0")/../../" \
            --exclude-dir=".git" \
            --exclude-dir="test-results" \
            --exclude-dir="logs" \
            --exclude="*.log" \
            --exclude="*.md" \
            | grep -v "# Example\|TODO\|FIXME\|template\|placeholder" > "$TEST_RESULTS_DIR/security-$pattern.log" 2>&1; then
            log_warn "Potential sensitive data pattern '$pattern' found - review security-$pattern.log"
        fi
    done
    
    # Check for insecure Docker practices
    local docker_dir="$(dirname "$0")/../../docker"
    for dockerfile in "$docker_dir"/Dockerfile*; do
        if [[ -f "$dockerfile" ]]; then
            # Check for running as root
            if ! grep -q "USER " "$dockerfile"; then
                log_warn "$(basename "$dockerfile") may run as root - consider adding USER instruction"
            fi
            
            # Check for COPY . . (copies everything)
            if grep -q "COPY \. \." "$dockerfile"; then
                log_warn "$(basename "$dockerfile") uses 'COPY . .' - consider being more specific"
            fi
        fi
    done
    
    pass_test "Security Baseline Test"
}

# Main test execution
main() {
    log_info "Starting Comprehensive Integration Test Suite"
    log_info "Results directory: $TEST_RESULTS_DIR"
    log_info "DRY_RUN mode: $DRY_RUN"
    log_info "Cleanup enabled: $CLEANUP"
    log_info "Timeout: ${TIMEOUT}s"
    
    echo "============================================"
    
    # Run all tests
    test_docker_package_validation || true
    test_dockerfile_syntax || true
    test_docker_build_core || true
    test_docker_build_chrome || true
    test_docker_compose || true
    test_configuration_files || true
    test_scripts || true
    test_chrome_specific || true
    test_security_baseline || true
    
    echo "============================================"
    
    # Summary
    log_info "Test Summary:"
    log_info "  Total Tests: $TESTS_TOTAL"
    log_info "  Passed: $TESTS_PASSED"
    log_info "  Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "Failed Tests:"
        for failed_test in "${FAILED_TESTS[@]}"; do
            log_error "  - $failed_test"
        done
        echo ""
        log_error "Integration tests failed! Please fix the issues above."
        log_info "Detailed logs available in: $TEST_RESULTS_DIR"
        exit 1
    else
        log_info "All integration tests passed successfully! 🎉"
        exit 0
    fi
}

# Help function
show_help() {
    cat << EOF
Comprehensive Integration Test Suite

Usage: $0 [OPTIONS]

This script runs comprehensive integration tests to validate Docker builds,
container functionality, and prevent regressions like package availability issues.

OPTIONS:
    -h, --help          Show this help message
    -d, --dry-run       Run in dry-run mode (skip actual builds)
    -n, --no-cleanup    Skip cleanup of test containers and images
    -t, --timeout SEC   Timeout for build operations (default: 300)
    -r, --results DIR   Directory for test results (default: ./test-results/integration)

ENVIRONMENT VARIABLES:
    DRY_RUN            Enable dry-run mode (default: false)
    CLEANUP            Enable cleanup (default: true)
    TIMEOUT            Build timeout in seconds (default: 300)
    TEST_RESULTS_DIR   Results directory

EXAMPLES:
    $0                      # Run all tests
    $0 --dry-run           # Syntax checks only
    $0 --no-cleanup        # Keep test containers for debugging
    $0 --timeout 600       # 10 minute timeout

EXIT CODES:
    0    All tests passed
    1    One or more tests failed
    2    Script error or invalid arguments
EOF
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
        -t|--timeout)
            TIMEOUT="$2"
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
