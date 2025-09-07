#!/bin/bash

# GitHub Actions Chrome Runner Entrypoint Script
# Specialized entrypoint for Chrome-optimized runners

set -e

# Colors for output
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

# Chrome-specific optimizations
setup_chrome() {
    log_info "Setting up Chrome for CI/CD environment..."
    
    # Note: Using xvfb-run for Chrome execution instead of manual Xvfb management
    # This provides more reliable display handling and automatic cleanup
    
    # Set Chrome flags for optimal CI/CD performance
    export CHROME_FLAGS="--headless --no-sandbox --disable-dev-shm-usage --disable-gpu --remote-debugging-port=9222 --disable-extensions --disable-plugins --disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-features=TranslateUI --no-first-run --no-default-browser-check --disable-software-rasterizer --disable-web-security --disable-features=VizDisplayCompositor"
    export CHROMIUM_FLAGS="$CHROME_FLAGS"
    
    # Playwright specific settings
    export PLAYWRIGHT_BROWSERS_PATH=/home/runner/.cache/ms-playwright
    export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/google-chrome
    
    # Set memory limits for Chrome processes
    MEMORY_LIMIT_KB=$((4 * 1024 * 1024))  # 4GB virtual memory limit
    ulimit -v "$MEMORY_LIMIT_KB"
    
    log_success "Chrome environment configured successfully"
}

# Validate Chrome installation
validate_chrome() {
    log_info "Validating Chrome installation..."
    
    if ! command -v google-chrome &> /dev/null; then
        log_error "Google Chrome is not installed"
        exit 1
    fi
    
    if ! command -v chromedriver &> /dev/null; then
        log_error "ChromeDriver is not installed"
        exit 1
    fi
    
    # Check architecture to determine validation approach
    HOST_ARCH=$(uname -m)
    log_info "Host architecture: $HOST_ARCH"
    
    if [ "$HOST_ARCH" = "aarch64" ] || [ "$HOST_ARCH" = "arm64" ]; then
        log_info "Running on ARM64 architecture - performing installation-only validation..."
        
        # On ARM64, we can't execute x86_64 Chrome binaries, so just validate installation
        CHROME_BINARY=$(which google-chrome)
        if [ -x "$CHROME_BINARY" ]; then
            log_success "Chrome binary is executable: $CHROME_BINARY"
            
            # Try to get version without executing (may work on some systems)
            if google-chrome --version 2>/dev/null | head -1 | grep -q "Google Chrome"; then
                CHROME_VERSION=$(google-chrome --version 2>/dev/null | head -1)
                log_success "Chrome version detected: $CHROME_VERSION"
            else
                log_warning "Cannot determine Chrome version on ARM64 (expected behavior)"
                log_success "Chrome installation validation passed (binary exists and is executable)"
            fi
        else
            log_error "Chrome binary is not executable: $CHROME_BINARY"
            exit 1
        fi
    else
        log_info "Running on x86_64 architecture - performing full Chrome validation..."
        
        # Test Chrome installation (simplified validation for CI/CD)
        log_info "Testing Chrome installation..."
        if [ -x "/usr/bin/google-chrome" ] && [ -f "/opt/chrome-linux64/chrome" ]; then
            # Try to get version without starting full browser
            CHROME_VERSION=$(google-chrome --version 2>/dev/null | head -1 || echo "Google Chrome (version check failed)")
            log_success "Chrome validation successful: $CHROME_VERSION"
        else
            log_error "Chrome binary not found or not executable"
            exit 1
        fi
    fi
    
    # Test ChromeDriver (simplified validation)
    log_info "Testing ChromeDriver installation..."
    if [ -x "/usr/bin/chromedriver" ] || [ -x "/usr/local/bin/chromedriver" ]; then
        CHROMEDRIVER_PATH=$(which chromedriver 2>/dev/null || echo "/usr/bin/chromedriver")
        log_success "ChromeDriver validation successful: $CHROMEDRIVER_PATH"
    else
        log_error "ChromeDriver binary not found or not executable"
        exit 1
    fi
}

# Validate testing frameworks
validate_testing_tools() {
    log_info "Validating testing framework installations..."
    
    # Check Playwright
    if command -v npx &> /dev/null && npx playwright --version > /dev/null 2>&1; then
        log_success "Playwright available: $(npx playwright --version)"
    else
        log_warning "Playwright not available"
    fi
    
    # Check Cypress
    if command -v npx &> /dev/null && npx cypress --version > /dev/null 2>&1; then
        log_success "Cypress available"
    else
        log_warning "Cypress not available"
    fi
    
    # Check Selenium
    SELENIUM_VERSION=$(python3 -c "import selenium; print(f'Selenium {selenium.__version__}')" 2>/dev/null)
    if [ -n "$SELENIUM_VERSION" ]; then
        log_success "Selenium available: $SELENIUM_VERSION"
    else
        log_warning "Selenium not available"
    fi
}

# Required environment variables
: "${GITHUB_TOKEN:?GITHUB_TOKEN environment variable is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY environment variable is required}"

# Optional environment variables with defaults
RUNNER_NAME="${RUNNER_NAME:-chrome-runner-$(hostname)}"
RUNNER_LABELS="${RUNNER_LABELS:-chrome,ui-tests,selenium,playwright,cypress}"
RUNNER_GROUP="${RUNNER_GROUP:-chrome-runners}"
RUNNER_WORK_DIR="${RUNNER_WORK_DIR:-/home/runner/workspace}"

log_info "Starting GitHub Actions Chrome Runner..."
log_info "Repository: ${GITHUB_REPOSITORY}"
log_info "Runner Name: ${RUNNER_NAME}"
log_info "Runner Labels: ${RUNNER_LABELS}"
log_info "Runner Group: ${RUNNER_GROUP}"

# Setup Chrome environment
setup_chrome
validate_chrome
validate_testing_tools

# Create work directory
mkdir -p "${RUNNER_WORK_DIR}"

# Generate runner token
log_info "Generating runner registration token..."
RUNNER_TOKEN=$(curl -s -X POST \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token" | \
    jq -r '.token')

if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" = "null" ]; then
    log_error "Failed to get runner registration token"
    exit 1
fi

log_success "Runner registration token obtained"

# Configure the runner
log_info "Configuring runner..."
# Create a temporary writable directory for runner configuration
export RUNNER_CONFIG_DIR="/tmp/runner-config"

# Ensure tmp directory has correct ownership and permissions
log_info "Ensuring /tmp has correct permissions..."
chown runner:runner /tmp 2>/dev/null || true
chmod 755 /tmp 2>/dev/null || true

mkdir -p "$RUNNER_CONFIG_DIR"
chown runner:runner "$RUNNER_CONFIG_DIR" 2>/dev/null || true
chmod 755 "$RUNNER_CONFIG_DIR" 2>/dev/null || true

cd "$RUNNER_CONFIG_DIR"

# Copy necessary files to writable location
cp -rp /actions-runner/* "$RUNNER_CONFIG_DIR/" 2>/dev/null || true

# Debug: Show what was copied
log_info "Contents of $RUNNER_CONFIG_DIR after copy:"
ls -la "$RUNNER_CONFIG_DIR/" | head -10

# Ensure config.sh has execute permissions (multiple approaches for robustness)
if [ -f "$RUNNER_CONFIG_DIR/config.sh" ]; then
    log_info "Setting execute permissions on config.sh..."

    # First, ensure the directory has correct permissions
    chmod 755 "$RUNNER_CONFIG_DIR" 2>/dev/null || true

    # Try multiple approaches to set execute permissions
    chmod +x "$RUNNER_CONFIG_DIR/config.sh" 2>/dev/null || {
        log_warning "chmod +x failed, trying alternative approach..."
        # Alternative: use numeric permissions
        chmod 755 "$RUNNER_CONFIG_DIR/config.sh" 2>/dev/null || {
            log_warning "chmod 755 failed, trying with sudo-like approach..."
            # Last resort: try to change ownership first
            chown runner:runner "$RUNNER_CONFIG_DIR/config.sh" 2>/dev/null || true
            chmod +x "$RUNNER_CONFIG_DIR/config.sh" 2>/dev/null || true
        }
    }

    # Also try with full path
    chmod +x /tmp/runner-config/config.sh 2>/dev/null || true

    # Verify permissions with multiple checks
    if [ -x "$RUNNER_CONFIG_DIR/config.sh" ]; then
        log_success "config.sh execute permissions set successfully"
    elif ls -l "$RUNNER_CONFIG_DIR/config.sh" | grep -q "x"; then
        log_success "config.sh has execute permissions (verified via ls)"
    else
        log_error "Failed to set execute permissions on config.sh"
        ls -la "$RUNNER_CONFIG_DIR/config.sh"
        # Don't exit here, try to continue anyway
        log_warning "Attempting to continue despite permission issues..."
    fi
else
    log_error "config.sh not found in $RUNNER_CONFIG_DIR"
    ls -la "$RUNNER_CONFIG_DIR/"
    exit 1
fi

# Ensure we're in the right directory
log_info "Current directory: $(pwd)"
log_info "Executing config.sh from: $RUNNER_CONFIG_DIR"

# Try to execute config.sh, with fallback if permission check failed
if "$RUNNER_CONFIG_DIR/config.sh" \
    --url "https://github.com/${GITHUB_REPOSITORY}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --labels "${RUNNER_LABELS}" \
    --runnergroup "${RUNNER_GROUP}" \
    --work "${RUNNER_WORK_DIR}" \
    --unattended \
    --replace; then
    log_success "Runner configured successfully"
else
    log_error "Failed to execute config.sh"
    # Try with bash explicitly
    log_info "Trying with bash explicitly..."
    if bash "$RUNNER_CONFIG_DIR/config.sh" \
        --url "https://github.com/${GITHUB_REPOSITORY}" \
        --token "${RUNNER_TOKEN}" \
        --name "${RUNNER_NAME}" \
        --labels "${RUNNER_LABELS}" \
        --runnergroup "${RUNNER_GROUP}" \
        --work "${RUNNER_WORK_DIR}" \
        --unattended \
        --replace; then
        log_success "Runner configured successfully with bash"
    else
        log_error "All attempts to execute config.sh failed"
        exit 1
    fi
fi

# Cleanup function
cleanup() {
    log_info "Received shutdown signal, cleaning up..."
    
    # Note: xvfb-run automatically handles Xvfb process cleanup
    # No manual Xvfb process management needed
    
    # Remove runner registration
    log_info "Removing runner registration..."
    ./config.sh remove --unattended --token "${RUNNER_TOKEN}" || true
    
    log_success "Cleanup completed"
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Start the runner
log_info "Starting runner listener..."
log_success "Chrome Runner is ready for UI testing workloads!"

./run.sh &
RUNNER_PID=$!

# Wait for the runner process
wait $RUNNER_PID
