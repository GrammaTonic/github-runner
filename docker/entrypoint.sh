#!/bin/bash
set -euo pipefail

# GitHub Actions Runner Entrypoint Script
# Handles runner registration, configuration, and lifecycle management

# Color output for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration variables with defaults
RUNNER_NAME="${RUNNER_NAME:-$(hostname)-$(date +%s)}"
RUNNER_WORKDIR="${RUNNER_WORKDIR:-/home/runner/_work}"
RUNNER_LABELS="${RUNNER_LABELS:-docker,self-hosted,linux}"
RUNNER_GROUP="${RUNNER_GROUP:-default}"
RUNNER_REPLACE_EXISTING="${RUNNER_REPLACE_EXISTING:-true}"

# Required environment variables check
check_required_vars() {
    local missing_vars=()
    
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        missing_vars+=("GITHUB_TOKEN")
    fi
    
    if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
        missing_vars+=("GITHUB_REPOSITORY")
    fi
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        log_error "Please set the following variables:"
        for var in "${missing_vars[@]}"; do
            log_error "  - $var"
        done
        exit 1
    fi
}

# Health check function
health_check() {
    if pgrep -f "Runner.Listener" > /dev/null; then
        log_success "Runner is healthy and running"
        return 0
    else
        log_error "Runner process not found"
        return 1
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up runner registration..."
    
    if [[ -f "/home/runner/actions-runner/.runner" ]]; then
        cd /home/runner/actions-runner
        
        # Get registration token for cleanup
        if ./config.sh remove --token "${GITHUB_TOKEN}" --unattended; then
            log_success "Runner successfully deregistered"
        else
            log_warning "Failed to deregister runner (may already be removed)"
        fi
    fi
    
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Get registration token from GitHub API
get_registration_token() {
    log_info "Getting registration token for repository: ${GITHUB_REPOSITORY}"
    
    local response
    response=$(curl -s -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token")
    
    local token
    token=$(echo "$response" | jq -r '.token // empty')
    
    if [[ -z "$token" || "$token" == "null" ]]; then
        log_error "Failed to get registration token"
        log_error "Response: $response"
        exit 1
    fi
    
    echo "$token"
}

# Configure runner
configure_runner() {
    log_info "Configuring GitHub Actions runner..."
    log_info "Runner name: ${RUNNER_NAME}"
    log_info "Repository: ${GITHUB_REPOSITORY}"
    log_info "Labels: ${RUNNER_LABELS}"
    log_info "Work directory: ${RUNNER_WORKDIR}"
    
    cd /home/runner/actions-runner
    
    # Get registration token
    local reg_token
    reg_token=$(get_registration_token)
    
    # Configure runner
    local config_args=(
        --url "https://github.com/${GITHUB_REPOSITORY}"
        --token "$reg_token"
        --name "$RUNNER_NAME"
        --work "$RUNNER_WORKDIR"
        --labels "$RUNNER_LABELS"
        --runnergroup "$RUNNER_GROUP"
        --unattended
    )
    
    if [[ "$RUNNER_REPLACE_EXISTING" == "true" ]]; then
        config_args+=(--replace)
    fi
    
    if ./config.sh "${config_args[@]}"; then
        log_success "Runner configured successfully"
    else
        log_error "Failed to configure runner"
        exit 1
    fi
}

# Start runner
start_runner() {
    log_info "Starting GitHub Actions runner..."
    
    cd /home/runner/actions-runner
    
    # Start runner listener
    exec ./run.sh
}

# Pre-flight checks
pre_flight_checks() {
    log_info "Running pre-flight checks..."
    
    # Check if running as correct user
    if [[ "$(whoami)" != "runner" ]]; then
        log_error "Must run as 'runner' user"
        exit 1
    fi
    
    # Check if actions-runner directory exists
    if [[ ! -d "/home/runner/actions-runner" ]]; then
        log_error "Actions runner directory not found"
        exit 1
    fi
    
    # Check if config script exists
    if [[ ! -f "/home/runner/actions-runner/config.sh" ]]; then
        log_error "Runner config script not found"
        exit 1
    fi
    
    # Check Docker access (if Docker is available)
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            log_success "Docker access verified"
        else
            log_warning "Docker daemon not accessible"
        fi
    fi
    
    # Create work directory if it doesn't exist
    mkdir -p "$RUNNER_WORKDIR"
    
    log_success "Pre-flight checks completed"
}

# Print runner information
print_runner_info() {
    log_info "=== GitHub Actions Runner Information ==="
    log_info "Runner Name: ${RUNNER_NAME}"
    log_info "Repository: ${GITHUB_REPOSITORY}"
    log_info "Labels: ${RUNNER_LABELS}"
    log_info "Group: ${RUNNER_GROUP}"
    log_info "Work Directory: ${RUNNER_WORKDIR}"
    log_info "Replace Existing: ${RUNNER_REPLACE_EXISTING}"
    log_info "Container User: $(whoami)"
    log_info "Container ID: $(hostname)"
    
    # System information
    log_info "=== System Information ==="
    log_info "OS: $(uname -s) $(uname -r)"
    log_info "Architecture: $(uname -m)"
    log_info "Available Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
    log_info "Available Disk: $(df -h /home/runner | tail -1 | awk '{print $4}')"
    
    # Tool versions
    log_info "=== Tool Versions ==="
    log_info "Git: $(git --version 2>/dev/null || echo 'Not available')"
    log_info "Node.js: $(node --version 2>/dev/null || echo 'Not available')"
    log_info "Python: $(python3 --version 2>/dev/null || echo 'Not available')"
    log_info "Docker: $(docker --version 2>/dev/null || echo 'Not available')"
    
    echo ""
}

# Main execution
main() {
    log_info "Starting GitHub Actions Runner container..."
    
    # Check required environment variables
    check_required_vars
    
    # Run pre-flight checks
    pre_flight_checks
    
    # Print runner information
    print_runner_info
    
    # Configure runner
    configure_runner
    
    # Start runner (this will run indefinitely)
    start_runner
}

# Handle special commands
case "${1:-}" in
    "health-check")
        health_check
        exit $?
        ;;
    "cleanup")
        cleanup
        ;;
    *)
        # Normal startup
        main "$@"
        ;;
esac
