#!/bin/bash

# Test script: Build and run Chrome runner container locally
set -e




# Local build and override compose file usage
COMPOSE_FILE="docker/docker-compose.chrome.yml"
OVERRIDE_FILE="docker/docker-compose.chrome.override.yml"
SERVICE_NAME="github-runner-chrome"
ENV_FILE="tests/docker/chrome-runner.env"
LOCAL_IMAGE="github-runner-chrome:test-local"

echo "[INFO] Building Chrome runner Docker image locally..."
docker build --platform=linux/amd64 -f docker/Dockerfile.chrome -t "$LOCAL_IMAGE" ./docker

echo "[INFO] Creating Docker Compose override file for local image..."
cat > "$OVERRIDE_FILE" <<EOF
services:
  $SERVICE_NAME:
    image: $LOCAL_IMAGE
EOF


echo "[INFO] Removing any previous test container..."
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -f "$OVERRIDE_FILE" down

echo "[INFO] Starting Chrome runner container using Docker Compose (detached, override, env)..."
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -f "$OVERRIDE_FILE" up -d "$SERVICE_NAME"

# Wait a few seconds for startup
sleep 5

# Get container name from compose (default: service name)
CONTAINER_NAME=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.Names}}" | head -n 1)

if [ -z "$CONTAINER_NAME" ]; then
  echo "[ERROR] Chrome runner container did not start."
  docker compose -f "$COMPOSE_FILE" -f "$OVERRIDE_FILE" logs "$SERVICE_NAME"
  rm -f "$OVERRIDE_FILE"
  exit 1
fi

# Check container status
STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME")

if [ "$STATUS" = "running" ]; then
  echo "[SUCCESS] Container is running and ready for diagnostics or manual jobs."
  echo "[INFO] Container logs (last 20 lines):"
  docker logs "$CONTAINER_NAME" | tail -20


    # Create Playwright screenshot script with detailed logging and correct module path
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  SCREENSHOT_PATH="/tmp/google_screenshot_${TIMESTAMP}.png"
  JS_SCRIPT_PATH="tests/playwright/google_screenshot.js"

  # Copy script into container
  docker cp "$JS_SCRIPT_PATH" "$CONTAINER_NAME":/tmp/google_screenshot.js
    
    # Verify playwright module is available before running
    echo "[INFO] Verifying Playwright module availability..."
    if ! docker exec "$CONTAINER_NAME" node -e "require('playwright')" 2>/dev/null; then
        echo "[ERROR] Playwright module not found in container"
        echo "[INFO] Attempting to install Playwright browsers..."
        docker exec "$CONTAINER_NAME" /usr/bin/npx playwright install chromium --yes
    fi

    # Run the script inside the container using node and capture output with live display
    echo "[INFO] Running Playwright screenshot script inside container..."
    echo "[INFO] Live output from Playwright script:"
    mkdir -p test-results/docker
  docker exec -e SCREENSHOT_PATH="$SCREENSHOT_PATH" "$CONTAINER_NAME" node /tmp/google_screenshot.js 2>&1 | tee test-results/docker/playwright_output_${TIMESTAMP}.log
    
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
  echo "  docker compose --env-file $ENV_FILE -f $COMPOSE_FILE -f $OVERRIDE_FILE down"
  rm -f "$OVERRIDE_FILE"
else
  echo "[ERROR] Container failed to start. Status: $STATUS"
  docker logs "$CONTAINER_NAME"
  rm -f "$OVERRIDE_FILE"
  exit 1
fi
