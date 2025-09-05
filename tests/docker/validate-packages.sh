#!/bin/bash

# Docker Package Validation Test
# This script validates that all packages in Dockerfiles are available in the target Ubuntu version
# Prevents issues like the libgconf-2-4 package availability problem

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-/tmp/package-validation}"
DRY_RUN="${DRY_RUN:-false}"

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

# Function to extract packages from a Dockerfile
extract_packages_from_dockerfile() {
    local dockerfile="$1"
    local temp_file
    temp_file="$TEST_RESULTS_DIR/packages_$(basename "$dockerfile").txt"
    
    log_info "Extracting packages from $dockerfile..." >&2
    
    # Ensure temp file exists even if no packages found
    touch "$temp_file"
    
    # Extract apt-get install commands with better multi-line handling
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
        ' "$dockerfile" | \
        # Filter and clean package names
        grep -v "^#" | \
        grep -v "rm -rf" | \
        grep -v "apt-get" | \
        sed 's/^[[:space:]]*//' | \
        sed 's/[[:space:]]*$//' | \
        sed 's/^-.*$//' | \
        grep -v "^$" | \
        grep -v "^--" | \
        grep -v "^&&" | \
        grep -v ')"' | \
        grep -v '";' | \
        grep -v 'case' | \
        grep -v 'esac' | \
        grep -v 'RUNNER_ARCH' | \
        grep -v 'curl' | \
        grep -v 'wget' | \
        grep -v 'echo' | \
        grep -v 'http' | \
        grep -E '^[a-zA-Z0-9][a-zA-Z0-9\.\-\+]*$' | \
        sort | uniq > "$temp_file"
    else
        log_warn "No apt-get install commands found in $dockerfile" >&2
    fi
    
    echo "$temp_file"
}

# Function to validate packages against Ubuntu repositories
validate_packages() {
    local package_file="$1"
    local dockerfile_name="$2"
    
    log_info "Validating packages for $dockerfile_name against Ubuntu $UBUNTU_VERSION..."
    
    # Use a Docker container to test package availability
    local validation_script="$TEST_RESULTS_DIR/validate_${dockerfile_name}.sh"
    
    cat > "$validation_script" << 'EOF'
#!/bin/bash
set -e

# Update package lists
apt-get update > /dev/null 2>&1

failed_packages=()
obsolete_packages=()
total=0

while IFS= read -r package; do
    if [[ -n "$package" && "$package" != \#* ]]; then
        total=$((total + 1))
        echo "Testing package: $package"
        
        # Check if package exists
        if apt-cache show "$package" > /dev/null 2>&1; then
            echo "✓ $package - Available"
        else
            echo "✗ $package - NOT AVAILABLE"
            failed_packages+=("$package")
            
            # Check if it's a known obsolete package
            case "$package" in
                "libgconf-2-4")
                    obsolete_packages+=("$package - Replaced by gsettings/dconf in Ubuntu 20.04+")
                    ;;
                "python2.7")
                    obsolete_packages+=("$package - Python 2 deprecated, use python3")
                    ;;
                "libssl1.0.0")
                    obsolete_packages+=("$package - Use libssl3 or libssl1.1")
                    ;;
                *)
                    # Try to find alternatives
                    echo "  Searching for alternatives..."
                    apt-cache search "$(echo "$package" | sed 's/[0-9]*$//')" | head -3 || true
                    ;;
            esac
        fi
    fi
done < /packages.txt

echo "VALIDATION_SUMMARY:"
echo "Total packages tested: $total"
echo "Failed packages: ${#failed_packages[@]}"
echo "Obsolete packages: ${#obsolete_packages[@]}"

if [[ ${#failed_packages[@]} -gt 0 ]]; then
    echo "FAILED_PACKAGES:"
    printf '%s\n' "${failed_packages[@]}"
fi

if [[ ${#obsolete_packages[@]} -gt 0 ]]; then
    echo "OBSOLETE_PACKAGES:"
    printf '%s\n' "${obsolete_packages[@]}"
fi

exit ${#failed_packages[@]}
EOF

    chmod +x "$validation_script"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY_RUN: Would validate packages using Docker container"
        return 0
    fi
    
    # Run validation in Docker container
    local exit_code=0
    docker run --rm -v "$package_file:/packages.txt" -v "$validation_script:/validate.sh" \
        "ubuntu:$UBUNTU_VERSION" bash /validate.sh > "$TEST_RESULTS_DIR/validation_${dockerfile_name}.log" 2>&1 || exit_code=$?
    
    # Parse results
    local log_file="$TEST_RESULTS_DIR/validation_${dockerfile_name}.log"
    cat "$log_file"
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "Package validation failed for $dockerfile_name (exit code: $exit_code)"
        
        # Extract failed packages from log
        if grep -q "FAILED_PACKAGES:" "$log_file"; then
            log_error "Failed packages:"
            sed -n '/FAILED_PACKAGES:/,/OBSOLETE_PACKAGES:/p' "$log_file" | grep -v "FAILED_PACKAGES:" | grep -v "OBSOLETE_PACKAGES:" || true
        fi
        
        # Extract obsolete packages from log
        if grep -q "OBSOLETE_PACKAGES:" "$log_file"; then
            log_warn "Obsolete packages found:"
            sed -n '/OBSOLETE_PACKAGES:/,$p' "$log_file" | grep -v "OBSOLETE_PACKAGES:" || true
        fi
        
        return $exit_code
    fi
    
    log_info "All packages validated successfully for $dockerfile_name"
    return 0
}

# Function to suggest package alternatives
suggest_alternatives() {
    local failed_package="$1"
    
    case "$failed_package" in
        "libgconf-2-4")
            echo "Alternative: Remove this package - GConf is obsolete. Use GSettings/dconf instead."
            echo "  Modern applications use GSettings which doesn't require additional packages."
            ;;
        "python2.7")
            echo "Alternative: python3, python3-dev"
            ;;
        "libssl1.0.0")
            echo "Alternative: libssl3, libssl1.1"
            ;;
        "nodejs")
            echo "Alternative: Add NodeSource repository or use snap: 'snap install node --classic'"
            ;;
        *)
            echo "Run 'apt-cache search ${failed_package%%-*}' to find alternatives"
            ;;
    esac
}

# Main validation function
main() {
    local dockerfile_dir="${1:-$(dirname "$0")/../../docker}"
    local exit_code=0
    local total_failures=0
    
    log_info "Starting Docker package validation for Ubuntu $UBUNTU_VERSION"
    log_info "Docker directory: $dockerfile_dir"
    
    # Find all Dockerfiles
    local dockerfiles=()
    while IFS= read -r -d '' file; do
        dockerfiles+=("$file")
    done < <(find "$dockerfile_dir" -name "Dockerfile*" -type f -print0)
    
    if [[ ${#dockerfiles[@]} -eq 0 ]]; then
        log_error "No Dockerfiles found in $dockerfile_dir"
        exit 1
    fi
    
    log_info "Found ${#dockerfiles[@]} Dockerfile(s) to validate"
    
    # Process each Dockerfile
    for dockerfile in "${dockerfiles[@]}"; do
        local dockerfile_name
        dockerfile_name="$(basename "$dockerfile")"
        
        log_info "Processing $dockerfile_name..."
        
        # Extract packages
        local package_file
        package_file="$(extract_packages_from_dockerfile "$dockerfile")"
        
        if [[ ! -f "$package_file" ]]; then
            log_error "Failed to create package file: $package_file"
            total_failures=$((total_failures + 1))
            exit_code=1
            continue
        fi
        
        local package_count
        package_count="$(wc -l < "$package_file" 2>/dev/null || echo 0)"
        log_info "Found $package_count packages in $dockerfile_name"
        
        # Validate packages
        if ! validate_packages "$package_file" "$dockerfile_name"; then
            log_error "Validation failed for $dockerfile_name"
            total_failures=$((total_failures + 1))
            exit_code=1
        fi
        
        echo "----------------------------------------"
    done
    
    # Summary
    log_info "Package validation complete"
    log_info "Dockerfiles processed: ${#dockerfiles[@]}"
    log_info "Failures: $total_failures"
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "Package validation failed! Please fix the issues above."
        log_info "Check detailed logs in: $TEST_RESULTS_DIR"
        
        echo ""
        log_info "Common fixes:"
        echo "  1. Remove obsolete packages (like libgconf-2-4)"
        echo "  2. Update package names for current Ubuntu version"
        echo "  3. Add required package repositories"
        echo "  4. Use alternative packages"
    else
        log_info "All package validations passed successfully!"
    fi
    
    exit $exit_code
}

# Help function
show_help() {
    cat << EOF
Docker Package Validation Test

Usage: $0 [OPTIONS] [DOCKER_DIR]

This script validates that all packages listed in Dockerfiles are available
in the specified Ubuntu version repositories.

OPTIONS:
    -h, --help          Show this help message
    -v, --version VER   Ubuntu version to test against (default: 24.04)
    -d, --dry-run       Run in dry-run mode (syntax check only)
    -r, --results DIR   Directory for test results (default: /tmp/package-validation)

ARGUMENTS:
    DOCKER_DIR          Directory containing Dockerfiles (default: ../../docker)

EXAMPLES:
    $0                                    # Validate all Dockerfiles in default location
    $0 /path/to/docker/files             # Validate Dockerfiles in specific directory
    $0 --version 22.04                   # Test against Ubuntu 22.04
    $0 --dry-run                         # Syntax check only

ENVIRONMENT VARIABLES:
    UBUNTU_VERSION      Ubuntu version (default: 24.04)
    DRY_RUN            Enable dry-run mode (default: false)
    TEST_RESULTS_DIR   Results directory (default: /tmp/package-validation)

EXIT CODES:
    0    All packages validated successfully
    1    One or more packages failed validation
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
        -v|--version)
            UBUNTU_VERSION="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN="true"
            shift
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
            break
            ;;
    esac
done

# Run main function
main "$@"
