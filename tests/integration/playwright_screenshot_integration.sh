#!/usr/bin/env bash
# playwright_screenshot_integration.sh
# Runs Playwright screenshot test inside Chrome runner container and copies result to host
set -euo pipefail

CONTAINER_NAME="github-runner-chrome"
JS_SCRIPT_PATH="tests/playwright/google_screenshot.js"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCREENSHOT_PATH="/tmp/google_screenshot_${TIMESTAMP}.png"
HOST_RESULTS_DIR="test-results/playwright"
HOST_SCREENSHOT_PATH="$HOST_RESULTS_DIR/google_screenshot_${TIMESTAMP}.png"
LOG_PATH="$HOST_RESULTS_DIR/playwright_output_${TIMESTAMP}.log"

echo "[INFO] Copying Playwright screenshot script into container..."
docker cp "$JS_SCRIPT_PATH" "$CONTAINER_NAME":/tmp/google_screenshot.js

echo "[INFO] Verifying Playwright module availability in container..."
if ! docker exec "$CONTAINER_NAME" node -e "require('playwright')" 2>/dev/null; then
	echo "[ERROR] Playwright module not found in container. Attempting to install Playwright browsers..."
	docker exec "$CONTAINER_NAME" /usr/bin/npx playwright install chromium --yes
fi


echo "[INFO] Running Playwright screenshot script inside container..."
mkdir -p "$HOST_RESULTS_DIR"
docker exec -e SCREENSHOT_PATH="$SCREENSHOT_PATH" "$CONTAINER_NAME" node /tmp/google_screenshot.js 2>&1 | tee "$LOG_PATH"
SCRIPT_EXIT_CODE="${PIPESTATUS[0]}"
echo "[INFO] Playwright script exit code: $SCRIPT_EXIT_CODE"

# Copy screenshot from container to host if script succeeded
if [ "$SCRIPT_EXIT_CODE" -eq 0 ]; then
	echo "[INFO] Attempting to copy screenshot from container to host..."
	if docker cp "$CONTAINER_NAME:$SCREENSHOT_PATH" "$HOST_SCREENSHOT_PATH"; then
		echo "[SUCCESS] Screenshot copied to $HOST_SCREENSHOT_PATH"
	else
		echo "[ERROR] Failed to copy screenshot from container."
		SCRIPT_EXIT_CODE=1
	fi
fi

# Check for error messages in the log
if grep -q "ERROR\|Error\|error\|Cannot find module\|MODULE_NOT_FOUND" "$LOG_PATH"; then
	echo "[WARNING] Error messages detected in log output"
	SCRIPT_EXIT_CODE=1
fi

if [ "$SCRIPT_EXIT_CODE" -eq 0 ]; then
	echo "[SUCCESS] Playwright script completed successfully"
	echo "[INFO] Test results saved in $HOST_RESULTS_DIR:"
	echo "  - Screenshot: $(basename "$HOST_SCREENSHOT_PATH")"
	echo "  - Log file: $(basename "$LOG_PATH")"
else
	echo "[ERROR] Playwright script failed with exit code $SCRIPT_EXIT_CODE"
	echo "[INFO] Check the log file: $LOG_PATH"
fi

exit "$SCRIPT_EXIT_CODE"
