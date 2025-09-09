#!/bin/bash

# Test script: Build and run Chrome runner container locally
set -e

IMAGE_NAME="github-runner-chrome:test-local"
CONTAINER_NAME="chrome-runner-test"
DOCKERFILE_PATH="docker/Dockerfile.chrome"

echo "[INFO] Building Chrome runner Docker image (multi-arch amd64)..."
docker build --platform=linux/amd64 -f "$DOCKERFILE_PATH" -t "$IMAGE_NAME" ./docker

# Remove any previous test container
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "[INFO] Removing previous test container..."
    docker rm -f "$CONTAINER_NAME"
fi

# Run the container in detached mode (multi-arch amd64) with env file
echo "[INFO] Starting Chrome runner container (multi-arch amd64, with env file)..."
docker run --platform=linux/amd64 --name "$CONTAINER_NAME" \
    --env-file tests/docker/chrome-runner.env \
    -m 4g \
    -d "$IMAGE_NAME"

# Wait a few seconds for startup
sleep 5

# Check container status
STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME")

if [ "$STATUS" = "running" ]; then
    echo "[SUCCESS] Container is running and ready for diagnostics or manual jobs."
    echo "[INFO] Container logs (last 20 lines):"
    docker logs "$CONTAINER_NAME" | tail -20

    # Create Playwright screenshot script with detailed logging and correct module path
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    SCREENSHOT_PATH="/tmp/google_screenshot_${TIMESTAMP}.png"
    cat > /tmp/google_screenshot.js <<EOF
const { chromium } = require('playwright');
const fs = require('fs');

// Handle synchronous errors that occur before the async function
process.on('uncaughtException', (error) => {
  console.error('[FATAL] Uncaught exception:', error.message);
  console.error('[FATAL] Stack trace:', error.stack);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('[FATAL] Unhandled rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

(async () => {
  console.log('[DEBUG] Starting Playwright screenshot script...');
  
  try {
    console.log('[DEBUG] Launching Chromium browser...');
    const browser = await chromium.launch({ 
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
    });
    console.log('[DEBUG] Browser launched successfully');
    
    console.log('[DEBUG] Creating new page...');
    const page = await browser.newPage();
    console.log('[DEBUG] New page created');
    
    console.log('[DEBUG] Navigating to https://www.google.com...');
    await page.goto('https://www.google.com', { waitUntil: 'networkidle' });
    console.log('[DEBUG] Page loaded successfully');
    
    // Check if page has content
    const title = await page.title();
    console.log(\`[DEBUG] Page title: \${title}\`);
    
    console.log('[DEBUG] Taking screenshot...');
    await page.screenshot({ path: '${SCREENSHOT_PATH}', fullPage: true });
    console.log('[DEBUG] Screenshot taken successfully');
    
    // Verify file was created
    if (fs.existsSync('${SCREENSHOT_PATH}')) {
      const stats = fs.statSync('${SCREENSHOT_PATH}');
      console.log(\`[DEBUG] Screenshot file created: \${stats.size} bytes at ${SCREENSHOT_PATH}\`);
    } else {
      console.log('[ERROR] Screenshot file was not created!');
      process.exit(1);
    }
    
    console.log('[DEBUG] Closing browser...');
    await browser.close();
    console.log('[DEBUG] Browser closed successfully');
    
  } catch (error) {
    console.error('[ERROR] An error occurred:', error.message);
    console.error('[ERROR] Stack trace:', error.stack);
    process.exit(1);
  }
})().catch((error) => {
  console.error('[FATAL] Top-level error:', error.message);
  console.error('[FATAL] Stack trace:', error.stack);
  process.exit(1);
});
EOF

    # Copy script into container
    docker cp /tmp/google_screenshot.js "$CONTAINER_NAME":/tmp/google_screenshot.js
    
    # Verify playwright module is available before running
    echo "[INFO] Verifying Playwright module availability..."
    if ! docker exec "$CONTAINER_NAME" env NODE_PATH=/usr/lib/node_modules /usr/bin/node -e "require('playwright')" 2>/dev/null; then
        echo "[ERROR] Playwright module not found in container"
        echo "[INFO] Attempting to install Playwright browsers..."
        docker exec "$CONTAINER_NAME" env NODE_PATH=/usr/lib/node_modules /usr/bin/npx playwright install chromium --yes
    fi

    # Run the script inside the container using node and capture output with live display
    echo "[INFO] Running Playwright screenshot script inside container..."
    echo "[INFO] Live output from Playwright script:"
    mkdir -p test-results/docker
    docker exec "$CONTAINER_NAME" env NODE_PATH=/usr/lib/node_modules /usr/bin/node /tmp/google_screenshot.js 2>&1 | tee test-results/docker/playwright_output_${TIMESTAMP}.log
    
    # Check if the script exited successfully and also check for error messages in the log
    SCRIPT_EXIT_CODE=$?
    echo "[INFO] Playwright script exit code: $SCRIPT_EXIT_CODE"
    
    # Also check if there were any error messages in the output
    if grep -q "ERROR\|Error\|error\|Cannot find module\|MODULE_NOT_FOUND" test-results/docker/playwright_output_${TIMESTAMP}.log; then
        echo "[WARNING] Error messages detected in log output"
        SCRIPT_EXIT_CODE=1
    fi
    
    if [ $SCRIPT_EXIT_CODE -eq 0 ]; then
        echo "[SUCCESS] Playwright script completed successfully"
        echo "[INFO] Test results saved in test-results/docker/:"
        echo "  - Screenshot: $(basename $SCREENSHOT_PATH)"
        echo "  - Log file: playwright_output_${TIMESTAMP}.log"
    else
        echo "[ERROR] Playwright script failed with exit code $SCRIPT_EXIT_CODE"
        echo "[INFO] Check the log file: test-results/docker/playwright_output_${TIMESTAMP}.log"
    fi

    # Copy screenshot back to host in test-results folder
    mkdir -p test-results/docker
    docker cp "$CONTAINER_NAME":$SCREENSHOT_PATH test-results/docker/ 2>/dev/null || true
    LOCAL_SCREENSHOT="test-results/docker/$(basename $SCREENSHOT_PATH)"
    
    # Check if screenshot was actually created
    if [ -f "$LOCAL_SCREENSHOT" ] && [ -s "$LOCAL_SCREENSHOT" ]; then
        echo "[SUCCESS] Screenshot saved as $LOCAL_SCREENSHOT"
        # Try to display the screenshot using the default image viewer (macOS: open, Linux: xdg-open)
        if command -v open &> /dev/null; then
            open "$LOCAL_SCREENSHOT"
        elif command -v xdg-open &> /dev/null; then
            xdg-open "$LOCAL_SCREENSHOT"
        else
            echo "[INFO] Screenshot file is available at $LOCAL_SCREENSHOT"
        fi
    else
        echo "[ERROR] Screenshot was not generated or is empty."
        SCRIPT_EXIT_CODE=1
    fi

    echo "[INFO] The container will remain running for workflow jobs or manual debugging."
    echo "[INFO] To stop and remove the container manually, run:"
    echo "  docker rm -f $CONTAINER_NAME"
else
    echo "[ERROR] Container failed to start. Status: $STATUS"
    docker logs "$CONTAINER_NAME"
    exit 1
fi
