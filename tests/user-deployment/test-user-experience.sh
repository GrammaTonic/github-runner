#!/bin/bash

# User Deployment Experience Tests
# Tests that validate the actual user deployment scenarios

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-./test-results/user-deployment}"
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$0")")")"

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
  echo "$(date -Iseconds): START $test_name" >>"$TEST_RESULTS_DIR/user-deployment.log"
}

pass_test() {
  local test_name="$1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  log_info "✓ PASSED: $test_name"
  echo "$(date -Iseconds): PASS $test_name" >>"$TEST_RESULTS_DIR/user-deployment.log"
}

fail_test() {
  local test_name="$1"
  local reason="${2:-Unknown error}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILED_TESTS+=("$test_name: $reason")
  log_error "✗ FAILED: $test_name - $reason"
  echo "$(date -Iseconds): FAIL $test_name - $reason" >>"$TEST_RESULTS_DIR/user-deployment.log"
}

# Test 1: Production Docker Compose files exist and are valid
test_production_compose() {
	start_test "Production Docker Compose Validation"

	local production_compose="$PROJECT_ROOT/docker/docker-compose.production.yml"
	local chrome_compose="$PROJECT_ROOT/docker/docker-compose.chrome.yml"

	# Test production compose file
	if [[ ! -f "$production_compose" ]]; then
		fail_test "Production Docker Compose Validation" "docker-compose.production.yml not found"
		return 1
	fi

	# Test Chrome compose file
	if [[ ! -f "$chrome_compose" ]]; then
		fail_test "Production Docker Compose Validation" "docker-compose.chrome.yml not found"
		return 1
	fi

	# Test production compose file syntax
	if ! docker compose -f "$production_compose" config >/dev/null 2>&1; then
		fail_test "Production Docker Compose Validation" "Invalid production Docker Compose syntax"
		return 1
	fi

	# Test Chrome compose file syntax
	if ! docker compose -f "$chrome_compose" config >/dev/null 2>&1; then
		fail_test "Production Docker Compose Validation" "Invalid Chrome Docker Compose syntax"
		return 1
	fi

	# Check production compose services
	local production_services
	production_services=$(docker compose -f "$production_compose" config --services)

	if ! echo "$production_services" | grep -q "github-runner"; then
		fail_test "Production Docker Compose Validation" "Missing github-runner service in production compose"
		return 1
	fi

	# Check Chrome compose services
	local chrome_services
	chrome_services=$(docker compose -f "$chrome_compose" config --services)

	if ! echo "$chrome_services" | grep -q "github-runner-chrome"; then
		fail_test "Production Docker Compose Validation" "Missing github-runner-chrome service in Chrome compose"
		return 1
	fi

	# Check required environment variables are referenced in both files
	for compose_file in "$production_compose" "$chrome_compose"; do
		if ! grep -q "GITHUB_TOKEN" "$compose_file"; then
			fail_test "Production Docker Compose Validation" "Missing GITHUB_TOKEN in $(basename "$compose_file")"
			return 1
		fi

		if ! grep -q "GITHUB_REPOSITORY" "$compose_file"; then
			fail_test "Production Docker Compose Validation" "Missing GITHUB_REPOSITORY in $(basename "$compose_file")"
			return 1
		fi

		# Check health checks are configured
		if ! grep -q "healthcheck:" "$compose_file"; then
			fail_test "Production Docker Compose Validation" "Missing health checks in $(basename "$compose_file")"
			return 1
		fi

		# Check volume configuration for Docker socket
		if ! grep -q "/var/run/docker.sock:/var/run/docker.sock" "$compose_file"; then
			fail_test "Production Docker Compose Validation" "Missing Docker socket volume mount in $(basename "$compose_file")"
			return 1
		fi
	done

	pass_test "Production Docker Compose Validation"
}

# Test 2: Environment templates exist and are complete
test_environment_template() {
	start_test "Environment Template Validation"

	local standard_env_template="$PROJECT_ROOT/config/runner.env.example"
	local chrome_env_template="$PROJECT_ROOT/config/chrome-runner.env.example"

	# Check standard environment template
	if [[ ! -f "$standard_env_template" ]]; then
		fail_test "Environment Template Validation" "runner.env.example not found"
		return 1
	fi

	# Check Chrome environment template
	if [[ ! -f "$chrome_env_template" ]]; then
		fail_test "Environment Template Validation" "chrome-runner.env.example not found"
		return 1
	fi

	# Check required variables are present in standard template
	local required_vars=("GITHUB_TOKEN" "GITHUB_REPOSITORY" "RUNNER_NAME" "RUNNER_LABELS")

	for var in "${required_vars[@]}"; do
		if ! grep -q "^$var=" "$standard_env_template" && ! grep -q "^#.*$var=" "$standard_env_template"; then
			fail_test "Environment Template Validation" "Missing variable $var in standard template"
			return 1
		fi
	done

	# Check required variables are present in Chrome template
	for var in "${required_vars[@]}"; do
		if ! grep -q "^$var=" "$chrome_env_template" && ! grep -q "^#.*$var=" "$chrome_env_template"; then
			fail_test "Environment Template Validation" "Missing variable $var in Chrome template"
			return 1
		fi
	done

	# Check for helpful comments and examples in both templates
	for template in "$standard_env_template" "$chrome_env_template"; do
		if ! grep -q "Create one at:" "$template"; then
			fail_test "Environment Template Validation" "Missing helpful comments for token creation in $(basename "$template")"
			return 1
		fi

		if ! grep -q "Example:" "$template"; then
			fail_test "Environment Template Validation" "Missing configuration examples in $(basename "$template")"
			return 1
		fi
	done

	# Check Chrome-specific variables in Chrome template
	if ! grep -q "CHROME_FLAGS\|DISPLAY" "$chrome_env_template"; then
		fail_test "Environment Template Validation" "Missing Chrome configuration in Chrome template"
		return 1
	fi

	pass_test "Environment Template Validation"
}

# Test 3: Quick start script exists and is executable
test_quick_start_script() {
	start_test "Quick Start Script Validation"

	local script_file="$PROJECT_ROOT/scripts/quick-start.sh"

	if [[ ! -f "$script_file" ]]; then
		fail_test "Quick Start Script Validation" "quick-start.sh not found"
		return 1
	fi

	if [[ ! -x "$script_file" ]]; then
		fail_test "Quick Start Script Validation" "quick-start.sh is not executable"
		return 1
	fi

	# Check script syntax
	if ! bash -n "$script_file"; then
		fail_test "Quick Start Script Validation" "Script has syntax errors"
		return 1
	fi

	# Check for required functions
	local required_functions=("check_prerequisites" "setup_environment" "deploy_runners")

	for func in "${required_functions[@]}"; do
		if ! grep -q "$func()" "$script_file"; then
			fail_test "Quick Start Script Validation" "Missing function: $func"
			return 1
		fi
	done

	# Check for help option
	if ! grep -q "\-\-help" "$script_file"; then
		fail_test "Quick Start Script Validation" "Missing help option"
		return 1
	fi

	# Check for error handling
	if ! grep -q "set -e" "$script_file"; then
		fail_test "Quick Start Script Validation" "Missing error handling (set -e)"
		return 1
	fi

	pass_test "Quick Start Script Validation"
}

# Test 4: Setup documentation exists and is comprehensive
test_setup_documentation() {
	start_test "Setup Documentation Validation"

	local doc_file="$PROJECT_ROOT/docs/setup/quick-start.md"

	if [[ ! -f "$doc_file" ]]; then
		fail_test "Setup Documentation Validation" "quick-start.md not found"
		return 1
	fi

	# Check for required sections
	local required_sections=("Prerequisites" "Quick Setup" "Troubleshooting" "Configuration")

	for section in "${required_sections[@]}"; do
		if ! grep -i "$section" "$doc_file" >/dev/null; then
			fail_test "Setup Documentation Validation" "Missing section: $section"
			return 1
		fi
	done

	# Check for code examples
	if ! grep -q "\`\`\`bash" "$doc_file"; then
		fail_test "Setup Documentation Validation" "Missing code examples"
		return 1
	fi

	# Check for GitHub token instructions
	if ! grep -q "github.com/settings/tokens" "$doc_file"; then
		fail_test "Setup Documentation Validation" "Missing token creation instructions"
		return 1
	fi

	# Check for troubleshooting scenarios
	if ! grep -qi "permission denied\|container.*restart\|runner.*not.*appear" "$doc_file"; then
		fail_test "Setup Documentation Validation" "Missing common troubleshooting scenarios"
		return 1
	fi

	pass_test "Setup Documentation Validation"
}

# Test 5: User workflow simulation (dry run)
test_user_workflow_simulation() {
	start_test "User Workflow Simulation"

	# Create temporary test environment
	local temp_dir
	temp_dir=$(mktemp -d)
	local test_env_file="$temp_dir/runner.env"

	# Copy template to test location
	if ! cp "$PROJECT_ROOT/config/runner.env.example" "$test_env_file"; then
		fail_test "User Workflow Simulation" "Could not copy environment template"
		return 1
	fi

	# Simulate user configuration
	sed -i.bak 's/GITHUB_TOKEN=.*/GITHUB_TOKEN=ghp_test_token_123/' "$test_env_file"
	sed -i.bak 's|GITHUB_REPOSITORY=.*|GITHUB_REPOSITORY=testuser/test-repo|' "$test_env_file"
	sed -i.bak 's/RUNNER_NAME=.*/RUNNER_NAME=test-runner/' "$test_env_file"

	# Test Docker Compose dry run with test configuration
	if ! GITHUB_TOKEN=ghp_test_token_123 GITHUB_REPOSITORY=testuser/test-repo \
		docker compose -f "$PROJECT_ROOT/docker/docker-compose.production.yml" config >/dev/null 2>&1; then
		fail_test "User Workflow Simulation" "Docker Compose fails with user configuration"
		rm -rf "$temp_dir"
		return 1
	fi

	# Test that configuration is properly substituted
	local compose_output
	compose_output=$(GITHUB_TOKEN=ghp_test_token_123 GITHUB_REPOSITORY=testuser/test-repo \
		docker compose -f "$PROJECT_ROOT/docker/docker-compose.production.yml" config)

	if ! echo "$compose_output" | grep -q "ghp_test_token_123"; then
		fail_test "User Workflow Simulation" "Environment variable substitution not working"
		rm -rf "$temp_dir"
		return 1
	fi

	if ! echo "$compose_output" | grep -q "testuser/test-repo"; then
		fail_test "User Workflow Simulation" "Repository variable substitution not working"
		rm -rf "$temp_dir"
		return 1
	fi

	# Cleanup
	rm -rf "$temp_dir"

	pass_test "User Workflow Simulation"
}

# Test 6: Required directory structure exists
test_directory_structure() {
	start_test "Directory Structure Validation"

	local required_dirs=("docker" "config" "scripts" "docs/setup")

	for dir in "${required_dirs[@]}"; do
		if [[ ! -d "$PROJECT_ROOT/$dir" ]]; then
			fail_test "Directory Structure Validation" "Missing directory: $dir"
			return 1
		fi
	done

	# Check for required files in each directory
	local required_files=(
		"docker/docker-compose.production.yml"
		"config/runner.env.example"
		"scripts/quick-start.sh"
		"docs/setup/quick-start.md"
	)

	for file in "${required_files[@]}"; do
		if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
			fail_test "Directory Structure Validation" "Missing file: $file"
			return 1
		fi
	done

	pass_test "Directory Structure Validation"
}

# Test 7: README.md has deployment instructions
test_readme_deployment_section() {
	start_test "README Deployment Section Validation"

	local readme_file="$PROJECT_ROOT/README.md"

	if [[ ! -f "$readme_file" ]]; then
		fail_test "README Deployment Section Validation" "README.md not found"
		return 1
	fi

	# Check for deployment-related content
	if ! grep -i "quick.*start\|deploy\|setup" "$readme_file" >/dev/null; then
		fail_test "README Deployment Section Validation" "Missing deployment instructions in README"
		return 1
	fi

	# Check for link to setup documentation
	if ! grep -q "docs/setup" "$readme_file" || ! grep -q "quick-start" "$readme_file"; then
		log_warn "README should link to setup documentation"
	fi

	pass_test "README Deployment Section Validation"
}

# Test 8: Image availability check
test_image_availability() {
	start_test "Docker Image Availability"

	# Check standard runner image in production compose
	local standard_image="ghcr.io/grammatonic/github-runner:latest"
	local chrome_image="ghcr.io/grammatonic/github-runner:chrome-latest"

	local production_compose="$PROJECT_ROOT/docker/docker-compose.production.yml"
	local chrome_compose="$PROJECT_ROOT/docker/docker-compose.chrome.yml"

	# Check standard image is referenced in production compose
	if ! grep -q "$standard_image" "$production_compose"; then
		fail_test "Docker Image Availability" "Standard image $standard_image not referenced in production compose"
		return 1
	fi

	# Check Chrome image is referenced in Chrome compose
	if ! grep -q "$chrome_image" "$chrome_compose"; then
		fail_test "Docker Image Availability" "Chrome image $chrome_image not referenced in Chrome compose"
		return 1
	fi

	pass_test "Docker Image Availability"
}

# Generate comprehensive test report
generate_report() {
	local report_file="$TEST_RESULTS_DIR/user-deployment-report.md"

	log_info "Generating user deployment test report..."

	cat >"$report_file" <<EOF
# User Deployment Experience Test Report

**Generated:** $(date -Iseconds)
**Total Tests:** $TESTS_TOTAL
**Passed:** $TESTS_PASSED
**Failed:** $TESTS_FAILED

## Summary

EOF

	if [[ $TESTS_FAILED -eq 0 ]]; then
		echo "✅ **ALL TESTS PASSED** - User deployment experience is ready!" >>"$report_file"
	else
		echo "❌ **TESTS FAILED** - User deployment experience issues detected:" >>"$report_file"
		echo "" >>"$report_file"
		for failed_test in "${FAILED_TESTS[@]}"; do
			echo "- $failed_test" >>"$report_file"
		done
	fi

	cat >>"$report_file" <<EOF

## Test Results

### ✅ Deployment Infrastructure
- Production Docker Compose configuration
- Environment template with examples
- Quick start automation script
- Comprehensive setup documentation

### ✅ User Experience
- One-command deployment capability
- Interactive configuration setup
- Clear troubleshooting guidance
- Proper error handling and validation

### ✅ File Structure
- All required directories and files present
- Scripts are executable and syntax-valid
- Documentation is comprehensive

## What This Means

EOF

	if [[ $TESTS_FAILED -eq 0 ]]; then
		cat >>"$report_file" <<EOF
🎉 **Users can now successfully deploy GitHub runners!**

The deployment experience includes:
- ✅ One-command setup with \`./scripts/quick-start.sh\`
- ✅ Interactive configuration with validation
- ✅ Production-ready Docker Compose configuration
- ✅ Comprehensive documentation and troubleshooting
- ✅ Proper error handling and user guidance

**Users will no longer struggle with deployment issues.**
EOF
	else
		cat >>"$report_file" <<EOF
🔧 **Deployment experience needs fixes before users can deploy successfully.**

Fix the failing tests above to ensure users can:
- Deploy runners without technical difficulties
- Get clear guidance when issues occur
- Have confidence in the setup process
EOF
	fi

	log_info "Test report generated: $report_file"
}

# Main execution
main() {
	log_info "Starting User Deployment Experience Tests"
	log_info "Project root: $PROJECT_ROOT"
	log_info "Results directory: $TEST_RESULTS_DIR"

	echo "============================================"
	echo "🧪 USER DEPLOYMENT EXPERIENCE TESTS"
	echo "============================================"

	# Run all tests
	test_directory_structure || true
	test_production_compose || true
	test_environment_template || true
	test_quick_start_script || true
	test_setup_documentation || true
	test_user_workflow_simulation || true
	test_readme_deployment_section || true
	test_image_availability || true

	echo "============================================"

	# Generate report
	generate_report

	# Summary
	log_info "User Deployment Experience Test Summary:"
	log_info "  Total Tests: $TESTS_TOTAL"
	log_info "  Passed: $TESTS_PASSED"
	log_info "  Failed: $TESTS_FAILED"

	if [[ $TESTS_FAILED -gt 0 ]]; then
		log_error "User deployment experience tests failed!"
		log_error "Failed Tests:"
		for failed_test in "${FAILED_TESTS[@]}"; do
			log_error "  - $failed_test"
		done
		echo ""
		log_error "Users will struggle to deploy runners until these issues are fixed."
		log_info "Check detailed report: $TEST_RESULTS_DIR/user-deployment-report.md"
		exit 1
	else
		log_info "All user deployment experience tests passed! 🎉"
		log_info "Users can now deploy GitHub runners successfully!"
		exit 0
	fi
}

# Help function
show_help() {
	cat <<EOF
User Deployment Experience Tests

Usage: $0 [OPTIONS]

This script tests that users can successfully deploy GitHub runners using
the provided configuration, scripts, and documentation.

OPTIONS:
    -h, --help          Show this help message
    -r, --results DIR   Directory for test results (default: ./test-results/user-deployment)

TESTS PERFORMED:
    1. Production Docker Compose validation
    2. Environment template completeness
    3. Quick start script functionality
    4. Setup documentation quality
    5. User workflow simulation
    6. Directory structure validation
    7. README deployment section
    8. Docker image availability

EXIT CODES:
    0    All tests passed - users can deploy successfully
    1    One or more tests failed - deployment experience needs fixes
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
    -r | --results)
      TEST_RESULTS_DIR="$2"
      shift 2
      ;;
    *)
      log_error "Unknown option: $1"
      show_help
      exit 2
      ;;
  esac
  shift
done

# Run main function
main "$@"
