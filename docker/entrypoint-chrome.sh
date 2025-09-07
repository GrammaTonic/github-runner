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
    
    # Start Xvfb for headless display (with cleanup if needed)
    DISPLAY_NUM=99
    export DISPLAY=:$DISPLAY_NUM
    
    # Create X11 directory if it doesn't exist (with proper permissions)
    sudo mkdir -p /tmp/.X11-unix
    sudo chmod 1777 /tmp/.X11-unix
    
    # Clean up any stale display lock files
    if [ -f "/tmp/.X${DISPLAY_NUM}-lock" ]; then
        log_info "Removing stale X11 lock file..."
        sudo rm -f "/tmp/.X${DISPLAY_NUM}-lock"
    fi
    
    # Kill any existing Xvfb on our display
    if pgrep -f "Xvfb :${DISPLAY_NUM}" > /dev/null; then
        log_info "Stopping existing Xvfb instance..."
        sudo pkill -f "Xvfb :${DISPLAY_NUM}" || true
        sleep 1
    fi
    
    # Start Xvfb
    log_info "Starting virtual display (Xvfb)..."
    Xvfb :${DISPLAY_NUM} -screen 0 1920x1080x24 -nolisten tcp -dpi 96 +extension GLX +render -noreset &
    XVFB_PID=$!
    sleep 3
    
    # Verify Xvfb started successfully
    if ! pgrep -f "Xvfb :${DISPLAY_NUM}" > /dev/null; then
        log_error "Failed to start Xvfb"
        exit 1
    fi
    
    # Set Chrome flags for optimal CI/CD performance
    export CHROME_FLAGS="--headless --no-sandbox --disable-dev-shm-usage --disable-gpu --remote-debugging-port=9222 --disable-extensions --disable-plugins --disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-features=TranslateUI --no-first-run --no-default-browser-check --disable-software-rasterizer --disable-web-security --disable-features=VizDisplayCompositor"
    export CHROMIUM_FLAGS="$CHROME_FLAGS"
    
    # Playwright specific settings
    export PLAYWRIGHT_BROWSERS_PATH=/home/runner/.cache/ms-playwright
    export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/google-chrome-stable
    
    # Set memory limits for Chrome processes
    MEMORY_LIMIT_KB=$((4 * 1024 * 1024))  # 4GB virtual memory limit
    ulimit -v "$MEMORY_LIMIT_KB"
    
    log_success "Chrome environment configured successfully"
}

# Validate Chrome installation
validate_chrome() {
    log_info "Validating Chrome installation..."
    
    if ! command -v google-chrome-stable &> /dev/null; then
        log_error "Google Chrome is not installed"
        exit 1
    fi
    
    if ! command -v chromedriver &> /dev/null; then
        log_error "ChromeDriver is not installed"
        exit 1
    fi
    
    # Test Chrome can start with comprehensive headless flags for Docker
    CHROME_TEST_FLAGS="--headless --no-sandbox --disable-dev-shm-usage --disable-gpu --disable-software-rasterizer --disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-features=TranslateUI --disable-extensions --disable-plugins --no-first-run --no-default-browser-check --single-process"
    
    if timeout 10 google-chrome-stable "$CHROME_TEST_FLAGS" --version > /dev/null 2>&1; then
        CHROME_VERSION=$(google-chrome-stable --version 2>/dev/null | head -1)
        log_success "Chrome validation successful: $CHROME_VERSION"
    else
        log_error "Chrome failed to start with flags: $CHROME_TEST_FLAGS"
        log_info "Attempting fallback validation..."
        
        # Try with minimal flags as fallback
        if timeout 5 google-chrome-stable --no-sandbox --single-process --version > /dev/null 2>&1; then
            CHROME_VERSION=$(google-chrome-stable --version 2>/dev/null | head -1)
            log_warning "Chrome validation passed with minimal flags: $CHROME_VERSION"
        else
            log_error "Chrome completely failed to start - this may indicate missing dependencies or incompatible architecture"
            exit 1
        fi
    fi
    
    # Test ChromeDriver
    if chromedriver --version > /dev/null 2>&1; then
        log_success "ChromeDriver validation successful: $(chromedriver --version)"
    else
        log_error "ChromeDriver failed to start"
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
./config.sh \
    --url "https://github.com/${GITHUB_REPOSITORY}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --labels "${RUNNER_LABELS}" \
    --runnergroup "${RUNNER_GROUP}" \
    --work "${RUNNER_WORK_DIR}" \
    --unattended \
    --replace

log_success "Runner configured successfully"

# Cleanup function
cleanup() {
    log_info "Received shutdown signal, cleaning up..."
    
    # Stop Xvfb if running
    if [ -n "$XVFB_PID" ] && kill -0 "$XVFB_PID" 2>/dev/null; then
        log_info "Stopping virtual display (PID: $XVFB_PID)..."
        kill "$XVFB_PID" || true
    elif pgrep -f "Xvfb :${DISPLAY_NUM:-99}" > /dev/null; then
        log_info "Stopping virtual display..."
        sudo pkill -f "Xvfb :${DISPLAY_NUM:-99}" || true
    fi
    
    # Clean up display lock files
    sudo rm -f "/tmp/.X${DISPLAY_NUM:-99}-lock" 2>/dev/null || true
    
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
