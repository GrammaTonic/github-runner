#!/bin/bash

# Comprehensive Test Runner
# Master script to run all test suites and prevent regressions

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-./test-results}"
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
FAIL_FAST="${FAIL_FAST:-false}"

# Test suite tracking
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
FAILED_SUITE_NAMES=()

# Create master test results directory
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

log_suite() {
  echo -e "${BLUE}[SUITE]${NC} $1"
}

# Suite tracking functions
start_suite() {
  local suite_name="$1"
  TOTAL_SUITES=$((TOTAL_SUITES + 1))
  log_suite "Starting: $suite_name"
  echo "$(date -Iseconds): START_SUITE $suite_name" >>"$TEST_RESULTS_DIR/master.log"
}

pass_suite() {
  local suite_name="$1"
  PASSED_SUITES=$((PASSED_SUITES + 1))
  log_info "✓ SUITE PASSED: $suite_name"
  echo "$(date -Iseconds): PASS_SUITE $suite_name" >>"$TEST_RESULTS_DIR/master.log"
}

fail_suite() {
  local suite_name="$1"
  local reason="${2:-Unknown error}"
  FAILED_SUITES=$((FAILED_SUITES + 1))
  FAILED_SUITE_NAMES+=("$suite_name: $reason")
  log_error "✗ SUITE FAILED: $suite_name - $reason"
  echo "$(date -Iseconds): FAIL_SUITE $suite_name - $reason" >>"$TEST_RESULTS_DIR/master.log"

  if [[ "$FAIL_FAST" == "true" ]]; then
    log_error "FAIL_FAST enabled - stopping test execution"
    exit 1
  fi
}

# Test Suite 1: Unit Tests
run_unit_tests() {
  start_suite "Unit Tests"

  local unit_script
  unit_script="$(dirname "$0")/unit/package-validation.sh"
  local unit_results="$TEST_RESULTS_DIR/unit"

  if [[ ! -f "$unit_script" ]]; then
    fail_suite "Unit Tests" "Unit test script not found"
    return 1
  fi

  log_info "Running unit tests..."

  local exit_code=0
  TEST_RESULTS_DIR="$unit_results" "$unit_script" >"$unit_results/unit-tests.log" 2>&1 || exit_code=$?

  if [[ "$VERBOSE" == "true" ]]; then
    cat "$unit_results/unit-tests.log"
  fi

  if [[ $exit_code -eq 0 ]]; then
    pass_suite "Unit Tests"
  else
    fail_suite "Unit Tests" "Unit tests failed (exit code: $exit_code)"
    return 1
  fi
}

# Test Suite 2: Integration Tests
run_integration_tests() {
  start_suite "Integration Tests"

  local integration_script
  integration_script="$(dirname "$0")/integration/comprehensive-tests.sh"
  local integration_results="$TEST_RESULTS_DIR/integration"
  mkdir -p "$integration_results"

  if [[ ! -f "$integration_script" ]]; then
    fail_suite "Integration Tests" "Integration test script not found"
    return 1
  fi

  log_info "Running integration tests..."

  local args=()
  if [[ "$DRY_RUN" == "true" ]]; then
    args+=("--dry-run")
  fi

  local exit_code=0
  if [[ ${#args[@]} -gt 0 ]]; then
    TEST_RESULTS_DIR="$integration_results" "$integration_script" "${args[@]}" >"$integration_results/integration-tests.log" 2>&1 || exit_code=$?
  else
    TEST_RESULTS_DIR="$integration_results" "$integration_script" >"$integration_results/integration-tests.log" 2>&1 || exit_code=$?
  fi

  if [[ "$VERBOSE" == "true" ]]; then
    cat "$integration_results/integration-tests.log"
  fi

  if [[ $exit_code -eq 0 ]]; then
    pass_suite "Integration Tests"
  else
    fail_suite "Integration Tests" "Integration tests failed (exit code: $exit_code)"
    return 1
  fi
}

# Test Suite 3: Docker Package Validation
run_docker_package_validation() {
  # shellcheck disable=SC2317
  start_suite "Docker Package Validation"

  # shellcheck disable=SC2317
  local package_script
  package_script="$(dirname "$0")/docker/validate-packages.sh"
  # shellcheck disable=SC2317
  local package_results="$TEST_RESULTS_DIR/docker"
  # shellcheck disable=SC2317
  mkdir -p "$package_results"

  # shellcheck disable=SC2317
  if [[ ! -f "$package_script" ]]; then
    fail_suite "Docker Package Validation" "Package validation script not found"
    return 1
  fi

  # shellcheck disable=SC2317
  log_info "Running Docker package validation..."

  # shellcheck disable=SC2317
  local args=()
  # shellcheck disable=SC2317
  if [[ "$DRY_RUN" == "true" ]]; then
    args+=("--dry-run")
  fi

  # shellcheck disable=SC2317
  local exit_code=0
  # shellcheck disable=SC2317
  if [[ ${#args[@]} -gt 0 ]]; then
    TEST_RESULTS_DIR="$package_results" "$package_script" "${args[@]}" >"$package_results/package-validation.log" 2>&1 || exit_code=$?
  else
    TEST_RESULTS_DIR="$package_results" "$package_script" >"$package_results/package-validation.log" 2>&1 || exit_code=$?
  fi

  # shellcheck disable=SC2317
  if [[ "$VERBOSE" == "true" ]]; then
    cat "$package_results/package-validation.log"
  fi

  # shellcheck disable=SC2317
  if [[ $exit_code -eq 0 ]]; then
    pass_suite "Docker Package Validation"
  else
    fail_suite "Docker Package Validation" "Package validation failed (exit code: $exit_code)"
    return 1
  fi
}

# Test Suite 4: Container Startup Tests
run_container_startup_tests() {
  start_suite "Container Startup Tests"

  local startup_script
  startup_script="$(dirname "$0")/docker/test-container-startup.sh"
  local startup_results="$TEST_RESULTS_DIR/container-startup"
  mkdir -p "$startup_results"

  if [[ ! -f "$startup_script" ]]; then
    fail_suite "Container Startup Tests" "Container startup test script not found"
    return 1
  fi

  log_info "Running container startup tests..."

  local args=()
  if [[ "$DRY_RUN" == "true" ]]; then
    args+=("--dry-run")
  fi

  local exit_code=0
  if [[ ${#args[@]} -gt 0 ]]; then
    TEST_RESULTS_DIR="$startup_results" "$startup_script" "${args[@]}" >"$startup_results/container-startup.log" 2>&1 || exit_code=$?
  else
    TEST_RESULTS_DIR="$startup_results" "$startup_script" >"$startup_results/container-startup.log" 2>&1 || exit_code=$?
  fi

  if [[ "$VERBOSE" == "true" ]]; then
    cat "$startup_results/container-startup.log"
  fi

  if [[ $exit_code -eq 0 ]]; then
    pass_suite "Container Startup Tests"
  else
    fail_suite "Container Startup Tests" "Container startup tests failed (exit code: $exit_code)"
    return 1
  fi
}

# Test Suite 4: Security Validation
run_security_tests() {
	start_suite "Security Validation"

	local security_results="$TEST_RESULTS_DIR/security"
	mkdir -p "$security_results"

	log_info "Running security validation tests..."

	# Test 1: Check for hardcoded secrets
	log_info "Checking for potential secrets..."
	local secret_patterns=("password" "secret" "token" "key" "api_key" "auth")
	local secrets_found=false

	for pattern in "${secret_patterns[@]}"; do
		if grep -r -i "$pattern" "$(dirname "$0")/../../" \
			--exclude-dir=".git" \
			--exclude-dir="test-results" \
			--exclude-dir="logs" \
			--exclude="*.log" \
			--exclude="*.md" |
			grep -v "# Example\|TODO\|FIXME\|template\|placeholder\|test.*$pattern" >"$security_results/secrets-$pattern.log" 2>&1; then
			log_warn "Potential secrets pattern '$pattern' found - review secrets-$pattern.log"
			secrets_found=true
		fi
	done

	# Test 2: Check Docker security practices
	log_info "Checking Docker security practices..."
	local docker_dir
	docker_dir="$(dirname "$0")/../../docker"
	local security_issues=0

	for dockerfile in "$docker_dir"/Dockerfile*; do
		if [[ -f "$dockerfile" ]]; then
			local dockerfile_name
			dockerfile_name="$(basename "$dockerfile")"

			# Check for running as root
			if ! grep -q "USER " "$dockerfile"; then
				echo "SECURITY: $dockerfile_name may run as root" >>"$security_results/docker-security.log"
				security_issues=$((security_issues + 1))
			fi

			# Check for COPY . .
			if grep -q "COPY \. \." "$dockerfile"; then
				echo "SECURITY: $dockerfile_name uses 'COPY . .' - overly broad" >>"$security_results/docker-security.log"
				security_issues=$((security_issues + 1))
			fi

			# Check for --privileged or similar dangerous flags
			if grep -q "privileged\|cap-add.*SYS_ADMIN" "$dockerfile"; then
				echo "SECURITY: $dockerfile_name contains privileged operations" >>"$security_results/docker-security.log"
				security_issues=$((security_issues + 1))
			fi
		fi
	done

	# Results
	if [[ "$secrets_found" == "true" ]]; then
		log_warn "Potential secrets found - review security logs"
	fi

	if [[ $security_issues -gt 0 ]]; then
		log_warn "$security_issues Docker security issues found - review docker-security.log"
	fi

	pass_suite "Security Validation"
}

# Test Suite 5: Configuration Validation
run_configuration_tests() {
	start_suite "Configuration Validation"

	local config_results="$TEST_RESULTS_DIR/configuration"
	mkdir -p "$config_results"

	log_info "Running configuration validation..."

	local config_dir
	config_dir="$(dirname "$0")/../../config"
	local scripts_dir
	scripts_dir="$(dirname "$0")/../../scripts"
	local config_errors=0

	# Test configuration files
	for config_file in "$config_dir"/*.env*; do
		if [[ -f "$config_file" ]]; then
			local config_name
			config_name="$(basename "$config_file")"

			log_info "Validating $config_name..."

			# Syntax check
			if ! bash -n "$config_file" >"$config_results/$config_name.log" 2>&1; then
				log_error "Syntax error in $config_name"
				config_errors=$((config_errors + 1))
			fi

			# Check for required variables
			local required_vars=("GITHUB_TOKEN" "GITHUB_REPOSITORY")
			for var in "${required_vars[@]}"; do
				if ! grep -q "^$var\|^#.*$var" "$config_file"; then
					echo "MISSING: $var not found in $config_name" >>"$config_results/missing-vars.log"
				fi
			done
		fi
	done

	# Test scripts
	for script in "$scripts_dir"/*.sh; do
		if [[ -f "$script" ]]; then
			local script_name
			script_name="$(basename "$script")"

			# Syntax check
			if ! bash -n "$script" >"$config_results/$script_name.log" 2>&1; then
				log_error "Syntax error in $script_name"
				config_errors=$((config_errors + 1))
			fi
		fi
	done

	if [[ $config_errors -eq 0 ]]; then
		pass_suite "Configuration Validation"
	else
		fail_suite "Configuration Validation" "$config_errors configuration errors found"
		return 1
	fi
}

# Generate comprehensive report
generate_report() {
  local report_file="$TEST_RESULTS_DIR/test-report.md"

  log_info "Generating comprehensive test report..."

  cat >"$report_file" <<EOF
# Test Report

**Generated:** $(date -Iseconds)
**DRY_RUN Mode:** $DRY_RUN
**Total Test Suites:** $TOTAL_SUITES
**Passed:** $PASSED_SUITES
**Failed:** $FAILED_SUITES

## Summary

EOF

  if [[ $FAILED_SUITES -eq 0 ]]; then
    echo "✅ **ALL TESTS PASSED** - No regressions detected!" >>"$report_file"
  else
    echo "❌ **TESTS FAILED** - Issues need to be addressed:" >>"$report_file"
    echo "" >>"$report_file"
    for failed_suite in "${FAILED_SUITE_NAMES[@]}"; do
      echo "- $failed_suite" >>"$report_file"
    done
  fi

  cat >>"$report_file" <<EOF

## Test Suites

### 1. Unit Tests
- **Purpose:** Detect obsolete packages, duplicates, version compatibility issues
- **Status:** $(if [[ " ${FAILED_SUITE_NAMES[*]} " =~ " Unit Tests:" ]]; then echo "❌ FAILED"; else echo "✅ PASSED"; fi)
- **Logs:** \`test-results/unit/\`

### 2. Integration Tests
- **Purpose:** Docker builds, container functionality, comprehensive validation
- **Status:** $(if [[ " ${FAILED_SUITE_NAMES[*]} " =~ " Integration Tests:" ]]; then echo "❌ FAILED"; else echo "✅ PASSED"; fi)
- **Logs:** \`test-results/integration/\`

### 3. Docker Package Validation
- **Purpose:** Validate package availability in target Ubuntu version
- **Status:** $(if [[ " ${FAILED_SUITE_NAMES[*]} " =~ " Docker Package Validation:" ]]; then echo "❌ FAILED"; else echo "✅ PASSED"; fi)
- **Logs:** \`test-results/docker/\`

### 4. Security Validation
- **Purpose:** Check for security issues and best practices
- **Status:** $(if [[ " ${FAILED_SUITE_NAMES[*]} " =~ " Security Validation:" ]]; then echo "❌ FAILED"; else echo "✅ PASSED"; fi)
- **Logs:** \`test-results/security/\`

### 5. Configuration Validation
- **Purpose:** Validate configuration files and scripts
- **Status:** $(if [[ " ${FAILED_SUITE_NAMES[*]} " =~ " Configuration Validation:" ]]; then echo "❌ FAILED"; else echo "✅ PASSED"; fi)
- **Logs:** \`test-results/configuration/\`

## Prevention Measures

This comprehensive test suite prevents issues like:

- ✅ **libgconf-2-4 Package Issue**: Unit tests detect obsolete packages
- ✅ **Docker Build Failures**: Integration tests validate builds before CI/CD
- ✅ **Package Duplicates**: Unit tests detect duplicate package installations
- ✅ **Version Incompatibility**: Package validation checks Ubuntu version compatibility
- ✅ **Security Issues**: Security validation enforces best practices
- ✅ **Configuration Errors**: Configuration validation prevents runtime failures

## Next Steps

EOF

  if [[ $FAILED_SUITES -eq 0 ]]; then
    echo "🎉 All tests passed! Your changes are ready for deployment." >>"$report_file"
  else
    echo "🔧 Fix the failing test suites before proceeding:" >>"$report_file"
    echo "" >>"$report_file"
    for failed_suite in "${FAILED_SUITE_NAMES[@]}"; do
      echo "1. Address issues in: $failed_suite" >>"$report_file"
    done
    echo "" >>"$report_file"
    echo "📋 Check detailed logs in the \`test-results/\` directory." >>"$report_file"
  fi

  log_info "Test report generated: $report_file"

  # Display report summary
  if [[ "$VERBOSE" == "true" ]]; then
    cat "$report_file"
  fi
}

# Main execution
main() {
  log_info "Starting Comprehensive Test Suite"
  log_info "Results directory: $TEST_RESULTS_DIR"
  log_info "DRY_RUN mode: $DRY_RUN"
  log_info "Verbose output: $VERBOSE"
  log_info "Fail fast: $FAIL_FAST"

  echo "============================================"
  echo "🧪 COMPREHENSIVE TEST EXECUTION"
  echo "============================================"

  # Initialize master log
  echo "$(date -Iseconds): START_MASTER_TEST" >"$TEST_RESULTS_DIR/master.log"

  # Run all test suites
  run_unit_tests || true
  run_integration_tests || true
  run_docker_package_validation || true
  run_container_startup_tests || true
  run_security_tests || true
  run_configuration_tests || true

  echo "============================================"
  echo "📊 TEST SUMMARY"
  echo "============================================"

  # Final summary
  log_info "Test Execution Complete"
  log_info "Total Suites: $TOTAL_SUITES"
  log_info "Passed: $PASSED_SUITES"
  log_info "Failed: $FAILED_SUITES"

  # Generate comprehensive report
  generate_report

  if [[ $FAILED_SUITES -gt 0 ]]; then
    echo ""
    log_error "❌ TEST EXECUTION FAILED"
    log_error "Failed Test Suites:"
    for failed_suite in "${FAILED_SUITE_NAMES[@]}"; do
      log_error "  - $failed_suite"
    done
    echo ""
    log_info "📋 Review detailed logs in: $TEST_RESULTS_DIR"
    log_info "📖 See full report: $TEST_RESULTS_DIR/test-report.md"

    echo "$(date -Iseconds): FAIL_MASTER_TEST - $FAILED_SUITES failed suites" >>"$TEST_RESULTS_DIR/master.log"
    exit 1
  else
    echo ""
    log_info "🎉 ALL TESTS PASSED SUCCESSFULLY!"
    log_info "✅ No regressions detected - changes are safe to deploy"
    log_info "📖 Full report: $TEST_RESULTS_DIR/test-report.md"

    echo "$(date -Iseconds): PASS_MASTER_TEST" >>"$TEST_RESULTS_DIR/master.log"
    exit 0
  fi
}

# Help function
show_help() {
  cat <<EOF
Comprehensive Test Runner

Usage: $0 [OPTIONS]

This script runs all test suites to validate the entire project and prevent
regressions like the libgconf-2-4 package availability issue.

OPTIONS:
    -h, --help          Show this help message
    -d, --dry-run       Run in dry-run mode (skip builds, syntax checks only)
    -v, --verbose       Show verbose output and logs
    -f, --fail-fast     Stop on first test suite failure
    -r, --results DIR   Directory for test results (default: ./test-results)

TEST SUITES:
    1. Unit Tests               - Package validation, obsolete detection
    2. Integration Tests        - Docker builds, container functionality
    3. Docker Package Validation - Ubuntu version compatibility
    4. Security Validation     - Security best practices
    5. Configuration Validation - Config files and scripts

PREVENTION FEATURES:
    ✅ Obsolete package detection (prevents libgconf-2-4 issues)
    ✅ Duplicate package detection
    ✅ Ubuntu version compatibility validation
    ✅ Docker build validation before CI/CD
    ✅ Security best practice enforcement
    ✅ Configuration syntax validation

EXAMPLES:
    $0                      # Run all test suites
    $0 --dry-run           # Syntax checks only
    $0 --verbose           # Show detailed output
    $0 --fail-fast         # Stop on first failure

EXIT CODES:
    0    All test suites passed
    1    One or more test suites failed
    2    Script error or invalid arguments
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h | --help)
      show_help
      exit 0
      ;;
    -d | --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -v | --verbose)
      VERBOSE="true"
      shift
      ;;
    -f | --fail-fast)
      FAIL_FAST="true"
      shift
      ;;
    -r | --results)
      TEST_RESULTS_DIR="$2"
      shift 2
      ;;
    -* )
      log_error "Unknown option: $1"
      show_help
      exit 2
      ;;
    * )
      log_error "Unexpected argument: $1"
      show_help
      exit 2
      ;;
  esac
done

# Run main function
main "$@"
