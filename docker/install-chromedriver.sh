#!/bin/bash
set -euo pipefail

# ChromeDriver Installation Script
# This script installs ChromeDriver compatible with the installed Chrome version

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# Get Chrome version

# Detect Chrome binary
if command -v chromium-browser &> /dev/null; then
    CHROME_BIN="chromium-browser"
else
    log_error "chromium-browser not found. Aborting ChromeDriver install."
    exit 1
fi

# Chromium version output: Chromium 123.0.6312.86
CHROME_VERSION=$($CHROME_BIN --version | grep -oP '\d+\.\d+\.\d+\.\d+')
log_info "Chromium version: $CHROME_VERSION"

# Chrome for Testing API URLs
CHROMEDRIVER_URL="https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json"
LATEST_MILESTONES_URL="https://googlechromelabs.github.io/chrome-for-testing/latest-versions-per-milestone-with-downloads.json"

# Try to get exact version match first
log_info "Looking for exact ChromeDriver version match..."
DRIVER_VERSION=$(curl -s "$CHROMEDRIVER_URL" | jq -r --arg version "$CHROME_VERSION" '.versions[] | select(.version == $version) | .downloads.chromedriver[] | select(.platform == "linux64") | .url' | head -1)

# Fallback to milestone version if exact match not found
if [ -z "$DRIVER_VERSION" ]; then
    log_info "ChromeDriver not found for exact version, getting latest stable for major version"
    MAJOR_VERSION="${CHROME_VERSION%%.*}"
    DRIVER_VERSION=$(curl -s "$LATEST_MILESTONES_URL" | jq -r --arg major "$MAJOR_VERSION" '.milestones[$major].downloads.chromedriver[] | select(.platform == "linux64") | .url' | head -1)
fi

# Validate we found a download URL
if [ -z "$DRIVER_VERSION" ]; then
    log_error "Could not find compatible ChromeDriver version for Chrome $CHROME_VERSION"
    exit 1
fi

log_info "ChromeDriver URL: $DRIVER_VERSION"

# Download and install ChromeDriver
log_info "Downloading ChromeDriver..."
curl -L -o chromedriver.zip "$DRIVER_VERSION"

log_info "Installing ChromeDriver..."
unzip chromedriver.zip
chmod +x chromedriver-linux64/chromedriver
mv chromedriver-linux64/chromedriver /usr/local/bin/
rm -rf chromedriver.zip chromedriver-linux64

# Verify installation
INSTALLED_VERSION=$(/usr/local/bin/chromedriver --version)
log_info "ChromeDriver installed successfully: $INSTALLED_VERSION"
