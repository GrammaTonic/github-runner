#!/bin/bash

# Test script: Build and run Normal runner container locally
set -e

# Local build and override compose file usage
COMPOSE_FILE="docker/docker-compose.production.yml"
OVERRIDE_FILE="docker/docker-compose.production.override.yml"
SERVICE_NAME="github-runner"
ENV_FILE="tests/docker/runner.env"
LOCAL_IMAGE="github-runner:test-local"

echo "[INFO] Building Normal runner Docker image locally..."
docker build --platform=linux/amd64 -f docker/Dockerfile -t "$LOCAL_IMAGE" ./docker

echo "[INFO] Creating Docker Compose override file for local image..."
cat > "$OVERRIDE_FILE" <<EOF
services:
  $SERVICE_NAME:
    image: $LOCAL_IMAGE
EOF

echo "[INFO] Removing any previous test container..."
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -f "$OVERRIDE_FILE" down

echo "[INFO] Starting Normal runner container using Docker Compose (detached, override, env)..."
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -f "$OVERRIDE_FILE" up -d "$SERVICE_NAME"

# Wait a few seconds for startup
sleep 5

# Get container name from compose (default: service name)
CONTAINER_NAME=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.Names}}" | head -n 1)

if [ -z "$CONTAINER_NAME" ]; then
  echo "[ERROR] Normal runner container did not start."
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

  # Check for GitHub connection
  echo "[INFO] Checking for GitHub connection in container logs..."
  if docker logs "$CONTAINER_NAME" | grep -q "Connected to GitHub"; then
    echo "[SUCCESS] Normal runner successfully connected to GitHub."
  else
    echo "[ERROR] Normal runner did NOT connect to GitHub. Printing full logs for diagnostics:"
    docker logs "$CONTAINER_NAME"
    rm -f "$OVERRIDE_FILE"
    exit 1
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
