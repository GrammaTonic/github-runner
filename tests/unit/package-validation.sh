#!/bin/bash

# Unit Test: Obsolete Package Detection
# This test specifically prevents the libgconf-2-4 issue and similar package problems

set -euo pipefail

# shellcheck disable=SC2329  # Functions are invoked by main() at the end of the script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-./test-results/unit}"
UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"

# Create test results directory
mkdir -p "$TEST_RESULTS_DIR"

# Logging functions
# shellcheck disable=SC2329
log_info() {
	echo -e "${GREEN}[INFO]${NC} $1"
}

# shellcheck disable=SC2329
log_warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
}

# shellcheck disable=SC2329
log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if package is obsolete
is_obsolete_package() {
	local package="$1"
	case "$package" in
	"libgconf-2-4")
		echo "Obsolete since Ubuntu 20.04 - Use GSettings/dconf instead"
		return 0
		;;
	"python2.7")
		echo "Python 2 deprecated - Use python3"
		return 0
		;;
	"python2.7-dev")
		echo "Python 2 deprecated - Use python3-dev"
		return 0
		;;
	"libssl1.0.0")
		echo "Obsolete - Use libssl3 or libssl1.1"
		return 0
		;;
	"libssl1.0-dev")
		echo "Obsolete - Use libssl3-dev or libssl1.1-dev"
		return 0
		;;
	"nodejs")
		echo "Use Node.js from NodeSource repository or snap"
		return 0
		;;
	"libmysqlclient18")
		echo "Obsolete - Use default-libmysqlclient-dev"
		return 0
		;;
	"mysql-client-5.7")
		echo "Obsolete - Use mysql-client-8.0 or default-mysql-client"
		return 0
		;;
	"libicu52")
		echo "Version-specific package - Use libicu-dev for current version"
		return 0
		;;
	"libpng12-0")
		echo "Obsolete - Use libpng16-16"
		return 0
		;;
	"libjpeg62")
		echo "Obsolete - Use libjpeg-turbo8"
		return 0
		;;
	"python-pip")
		echo "Python 2 package - Use python3-pip"
		return 0
		;;
	"python-setuptools")
		echo "Python 2 package - Use python3-setuptools"
		return 0
		;;
	"software-properties-common")
		echo "Renamed to python3-software-properties in some contexts"
		return 0
		;;
	*) return 1 ;;
	esac
}

# Function to get package warning
get_package_warning() {
	local package="$1"
	case "$package" in
	"apt-transport-https")
		echo "Built into apt since Ubuntu 20.04 - may be redundant"
		return 0
		;;
	"ca-certificates-java")
		echo "Only needed if installing Java manually"
		return 0
		;;
	"dbus-x11")
		echo "Consider if X11 forwarding is actually needed"
		return 0
		;;
	"libgtk2.0-0")
		echo "GTK2 deprecated - Use libgtk-3-0 if possible"
		return 0
		;;
	*) return 1 ;;
	esac
}

# Test 1: Check for obsolete packages in Dockerfiles
#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
	echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." &>/dev/null && pwd)"
DOCKER_DIR="$ROOT_DIR/docker"
RESULTS_DIR="$ROOT_DIR/test-results/unit"
mkdir -p "$RESULTS_DIR"

# shellcheck disable=SC2329
validate_dockerfile() {
	local dockerfile=$1
	local name
	name=$(basename "$dockerfile")

	log_info "Validating packages in $name"

	if ! grep -qiE "curl|git|jq|tar|unzip" "$dockerfile"; then
		log_warn "$name: Essential tools not clearly installed"
	fi

	if grep -qiE "apk add|apt-get install" "$dockerfile" && ! grep -qiE "--no-install-recommends|--no-cache" "$dockerfile"; then
		log_warn "$name: Consider using no-recommends/no-cache for smaller images"
	fi

	if grep -qE "RUN .* && \\" "$dockerfile"; then
		log_info "$name: Multi-command RUN steps detected (good for layer minimization)"
	fi

	if grep -qE "^USER root|^#.*USER root" "$dockerfile"; then
		log_warn "$name: Running as root; consider a non-root user where possible"
	fi
}

# shellcheck disable=SC2329
main() {
	mkdir -p "$RESULTS_DIR"

	local errors=0
	for dockerfile in "$DOCKER_DIR"/Dockerfile*; do
		if [[ -f "$dockerfile" ]]; then
			validate_dockerfile "$dockerfile" || errors=$((errors + 1))
		fi
	done

	if [[ $errors -gt 0 ]]; then
		log_error "Package validation found $errors issue(s)"
		return 1
	fi

	log_info "Package validation completed"
	return 0
}

# Test 1: Check for obsolete packages
test_obsolete_packages() {
	local test_name="Obsolete Package Detection"
	local docker_dir
	docker_dir="$(dirname "$0")/../../docker"
	local failed=false
	local warnings=0

	log_info "Starting $test_name..."

	# Find all Dockerfiles
	while IFS= read -r -d '' dockerfile; do
		local dockerfile_name
		dockerfile_name="$(basename "$dockerfile")"

		log_info "Checking $dockerfile_name for obsolete packages..."

		# Extract packages from apt-get install commands
		local packages
		packages=$(grep -A 50 "apt-get install" "$dockerfile" |
			grep -v "^#" |
			sed 's/.*apt-get install[^\\]*\\//' |
			sed 's/&&.*//' |
			sed 's/\\.*//' |
			sed 's/^[[:space:]]*//' |
			sed 's/[[:space:]]*$//' |
			grep -v "^$" |
			grep -v "^--" || true)

		# Check each package against known obsolete packages
		while IFS= read -r package; do
			if [[ -n "$package" ]]; then
				# Check if package is obsolete
				local obsolete_reason
				if obsolete_reason=$(is_obsolete_package "$package"); then
					log_error "OBSOLETE PACKAGE FOUND in $dockerfile_name: $package"
					log_error "  Reason: $obsolete_reason"
					echo "$dockerfile_name: OBSOLETE $package - $obsolete_reason" >>"$TEST_RESULTS_DIR/obsolete-packages.log"
					failed=true
				fi

				# Check for warnings
				local warning_reason
				if warning_reason=$(get_package_warning "$package"); then
					log_warn "WARNING in $dockerfile_name: $package"
					log_warn "  Note: $warning_reason"
					echo "$dockerfile_name: WARNING $package - $warning_reason" >>"$TEST_RESULTS_DIR/package-warnings.log"
					warnings=$((warnings + 1))
				fi
			fi
		done <<<"$packages"

	done < <(find "$docker_dir" -name "Dockerfile*" -type f -print0)

	# Results
	if [[ "$failed" == "true" ]]; then
		log_error "✗ $test_name FAILED - Obsolete packages found!"
		log_error "Check $TEST_RESULTS_DIR/obsolete-packages.log for details"
		return 1
	else
		log_info "✓ $test_name PASSED - No obsolete packages found"
		if [[ $warnings -gt 0 ]]; then
			log_warn "Found $warnings package warnings - check $TEST_RESULTS_DIR/package-warnings.log"
		fi
		return 0
	fi
}

# Test 2: Check for duplicate packages across Dockerfiles
test_duplicate_packages() {
	local test_name="Duplicate Package Detection"
	local docker_dir
	docker_dir="$(dirname "$0")/../../docker"
	local failed=false

	log_info "Starting $test_name..."

	# Find all Dockerfiles
	while IFS= read -r -d '' dockerfile; do
		local dockerfile_name
		dockerfile_name="$(basename "$dockerfile")"

		log_info "Checking $dockerfile_name for duplicate packages..."

		# Check if this is a multi-stage build
		if grep -q "FROM.*AS" "$dockerfile"; then
			log_info "$dockerfile_name is a multi-stage build - duplicates between stages are expected"
			# Skip duplicate check for multi-stage builds since packages often need to be installed in multiple stages
			continue
		fi

		# Extract packages and check for duplicates (single-stage builds only)
		local packages_file="$TEST_RESULTS_DIR/packages-$dockerfile_name.txt"

		# Use improved package extraction logic (same as integration tests)
		if grep -q "apt-get install" "$dockerfile"; then
			# Find RUN commands with apt-get install and extract package names more carefully
			awk '
            /^RUN.*apt-get install/ {
                in_install_block = 1
                line = $0
                # Remove RUN and everything up to apt-get install
                gsub(/^RUN.*apt-get install[^\\]*\\?/, "", line)
                print line
                next
            }
            in_install_block && /\\$/ {
                # Continuation line in install block
                line = $0
                gsub(/^[[:space:]]*/, "", line)  # Remove leading whitespace
                gsub(/\\$/, "", line)          # Remove trailing backslash
                print line
                next
            }
            in_install_block && !/\\$/ {
                # Last line of install block
                line = $0
                gsub(/^[[:space:]]*/, "", line)
                gsub(/&&.*/, "", line)         # Remove everything after &&
                print line
                in_install_block = 0
                next
            }
            ' "$dockerfile" |
				# Filter and clean package names
				grep -v "^#" |
				grep -v "rm -rf" |
				grep -v "apt-get" |
				sed 's/^[[:space:]]*//' |
				sed 's/[[:space:]]*$//' |
				sed 's/^-.*$//' |
				grep -v "^$" |
				grep -v "^--" |
				grep -v "^&&" |
				grep -v ')"' |
				grep -v '";' |
				grep -v 'case' |
				grep -v 'esac' |
				grep -v 'RUNNER_ARCH' |
				grep -v 'curl' |
				grep -v 'wget' |
				grep -v 'echo' |
				grep -v 'http' |
				grep -E '^[a-zA-Z0-9][a-zA-Z0-9\.\-\+]*$' |
				sort >"$packages_file"
		else
			# No apt-get install commands found
			touch "$packages_file"
		fi

		# Find duplicates
		local duplicates
		duplicates=$(uniq -d "$packages_file" || true)

		if [[ -n "$duplicates" ]]; then
			log_error "DUPLICATE PACKAGES FOUND in $dockerfile_name:"
			while IFS= read -r duplicate; do
				if [[ -n "$duplicate" ]]; then
					log_error "  - $duplicate"
					echo "$dockerfile_name: DUPLICATE $duplicate" >>"$TEST_RESULTS_DIR/duplicate-packages.log"
				fi
			done <<<"$duplicates"
			failed=true
		fi

	done < <(find "$docker_dir" -name "Dockerfile*" -type f -print0)

	# Results
	if [[ "$failed" == "true" ]]; then
		log_error "✗ $test_name FAILED - Duplicate packages found!"
		log_error "Check $TEST_RESULTS_DIR/duplicate-packages.log for details"
		return 1
	else
		log_info "✓ $test_name PASSED - No duplicate packages found"
		return 0
	fi
}

# Function to check Ubuntu version compatibility
get_version_issue() {
	local package="$1"
	case "$package" in
	"libssl1.0.0")
		echo "Not available in Ubuntu 24.04"
		return 0
		;;
	"libssl1.0-dev")
		echo "Not available in Ubuntu 24.04"
		return 0
		;;
	"python2.7")
		echo "Not available in Ubuntu 24.04"
		return 0
		;;
	"mysql-client-5.7")
		echo "Not available in Ubuntu 24.04"
		return 0
		;;
	"libicu52")
		echo "Version-specific - Ubuntu 24.04 uses libicu74"
		return 0
		;;
	"libpng12-0")
		echo "Not available in Ubuntu 24.04"
		return 0
		;;
	*) return 1 ;;
	esac
}

# Test 3: Check for Ubuntu version compatibility
test_ubuntu_compatibility() {
	local test_name="Ubuntu Version Compatibility"
	local docker_dir
	docker_dir="$(dirname "$0")/../../docker"
	local failed=false

	log_info "Starting $test_name..."

	# Find all Dockerfiles
	while IFS= read -r -d '' dockerfile; do
		local dockerfile_name
		dockerfile_name="$(basename "$dockerfile")"

		# Check if Dockerfile specifies Ubuntu version
		local dockerfile_ubuntu_version
		dockerfile_ubuntu_version=$(grep "^FROM.*ubuntu:" "$dockerfile" | sed 's/.*ubuntu://' | cut -d' ' -f1 || echo "unknown")

		if [[ "$dockerfile_ubuntu_version" == "24.04" || "$dockerfile_ubuntu_version" == "latest" ]]; then
			log_info "Checking $dockerfile_name (Ubuntu $dockerfile_ubuntu_version) for version compatibility..."

			# Extract packages
			local packages
			packages=$(grep -A 50 "apt-get install" "$dockerfile" |
				grep -v "^#" |
				sed 's/.*apt-get install[^\\]*\\//' |
				sed 's/&&.*//' |
				sed 's/\\.*//' |
				sed 's/^[[:space:]]*//' |
				sed 's/[[:space:]]*$//' |
				grep -v "^$" |
				grep -v "^--" || true)

			# Check for version-specific issues
			while IFS= read -r package; do
				if [[ -n "$package" ]]; then
					local version_issue
					if version_issue=$(get_version_issue "$package"); then
						log_error "VERSION INCOMPATIBILITY in $dockerfile_name: $package"
						log_error "  Issue: $version_issue"
						echo "$dockerfile_name: INCOMPATIBLE $package - $version_issue" >>"$TEST_RESULTS_DIR/version-issues.log"
						failed=true
					fi
				fi
			done <<<"$packages"
		fi

	done < <(find "$docker_dir" -name "Dockerfile*" -type f -print0)

	# Results
	if [[ "$failed" == "true" ]]; then
		log_error "✗ $test_name FAILED - Version compatibility issues found!"
		log_error "Check $TEST_RESULTS_DIR/version-issues.log for details"
		return 1
	else
		log_info "✓ $test_name PASSED - No version compatibility issues found"
		return 0
	fi
}

# Function to get dependency suggestions
get_dependency_suggestion() {
	local package="$1"
	case "$package" in
	"google-chrome-stable")
		echo "Consider: xvfb, fonts-liberation, fonts-noto-color-emoji"
		return 0
		;;
	"nodejs")
		echo "Consider: npm, build-essential for native modules"
		return 0
		;;
	"python3")
		echo "Consider: python3-pip, python3-dev for development"
		return 0
		;;
	"mysql-client")
		echo "Consider: libmysqlclient-dev for development"
		return 0
		;;
	"postgresql-client")
		echo "Consider: libpq-dev for development"
		return 0
		;;
	*) return 1 ;;
	esac
}

# Test 4: Package dependency validation
test_package_dependencies() {
	local test_name="Package Dependency Validation"
	local docker_dir
	docker_dir="$(dirname "$0")/../../docker"
	local warnings=0

	log_info "Starting $test_name..."

	# Find all Dockerfiles
	while IFS= read -r -d '' dockerfile; do
		local dockerfile_name
		dockerfile_name="$(basename "$dockerfile")"

		log_info "Checking $dockerfile_name for dependency recommendations..."

		# Extract packages
		local packages
		packages=$(grep -A 50 "apt-get install" "$dockerfile" |
			grep -v "^#" |
			sed 's/.*apt-get install[^\\]*\\//' |
			sed 's/&&.*//' |
			sed 's/\\.*//' |
			sed 's/^[[:space:]]*//' |
			sed 's/[[:space:]]*$//' |
			grep -v "^$" |
			grep -v "^--" || true)

		# Check for dependency suggestions
		while IFS= read -r package; do
			if [[ -n "$package" ]]; then
				local suggestion
				if suggestion=$(get_dependency_suggestion "$package"); then
					log_warn "DEPENDENCY SUGGESTION for $dockerfile_name: $package"
					log_warn "  $suggestion"
					echo "$dockerfile_name: SUGGESTION $package - $suggestion" >>"$TEST_RESULTS_DIR/dependency-suggestions.log"
					warnings=$((warnings + 1))
				fi
			fi
		done <<<"$packages"

	done < <(find "$docker_dir" -name "Dockerfile*" -type f -print0)

	# Always pass but report suggestions
	log_info "✓ $test_name PASSED"
	if [[ $warnings -gt 0 ]]; then
		log_warn "Found $warnings dependency suggestions - check $TEST_RESULTS_DIR/dependency-suggestions.log"
	fi
	return 0
}

# Main test execution
# shellcheck disable=SC2329
main() {
	local exit_code=0

	log_info "Starting Unit Tests for Package Management"
	log_info "Ubuntu version: $UBUNTU_VERSION"
	log_info "Results directory: $TEST_RESULTS_DIR"

	echo "============================================"

	# Run all unit tests
	test_obsolete_packages || exit_code=1
	test_duplicate_packages || exit_code=1
	test_ubuntu_compatibility || exit_code=1
	test_package_dependencies || true # This is informational only

	echo "============================================"

	if [[ $exit_code -eq 0 ]]; then
		log_info "All unit tests passed! ✓"
	else
		log_error "Some unit tests failed! Please fix the issues above."
		log_info "Detailed logs available in: $TEST_RESULTS_DIR"
	fi

	exit $exit_code
}

# Help function
show_help() {
	cat <<EOF
Unit Test: Obsolete Package Detection

Usage: $0 [OPTIONS]

This script runs unit tests to detect obsolete packages, duplicates,
and version compatibility issues in Dockerfiles.

OPTIONS:
    -h, --help          Show this help message
    -v, --version VER   Ubuntu version to test against (default: 24.04)
    -r, --results DIR   Directory for test results (default: ./test-results/unit)

EXAMPLES:
    $0                      # Run all unit tests
    $0 --version 22.04     # Test against Ubuntu 22.04

EXIT CODES:
    0    All tests passed
    1    One or more tests failed
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
	-v | --version)
		UBUNTU_VERSION="$2"
		shift 2
		;;
	-r | --results)
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
