#!/bin/bash
# metrics-server.sh - Lightweight HTTP server for Prometheus metrics endpoint
# Uses netcat to serve metrics from /tmp/runner_metrics.prom on port 9091
#
# Based on spike research: SPIKE-001 (APPROVED)
# Implementation: Phase 1, TASK-001
# Created: 2025-11-17

set -euo pipefail

# Configuration
METRICS_PORT="${METRICS_PORT:-9091}"
METRICS_FILE="${METRICS_FILE:-/tmp/runner_metrics.prom}"
SERVER_LOG="${SERVER_LOG:-/tmp/metrics-server.log}"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$SERVER_LOG"
}

# Initialize metrics file if it doesn't exist
initialize_metrics() {
    if [[ ! -f "$METRICS_FILE" ]]; then
        log "Initializing metrics file: $METRICS_FILE"
        cat > "$METRICS_FILE" <<EOF
# HELP github_runner_status Runner status (1=online, 0=offline)
# TYPE github_runner_status gauge
github_runner_status 1

# HELP github_runner_info Runner information
# TYPE github_runner_info gauge
github_runner_info{runner_name="unknown",runner_type="unknown",version="0.0.0"} 1

# HELP github_runner_uptime_seconds Runner uptime in seconds
# TYPE github_runner_uptime_seconds counter
github_runner_uptime_seconds 0
EOF
    fi
}

# Serve HTTP response with metrics
serve_metrics() {
    local client_ip="${1:-unknown}"
    
    if [[ ! -f "$METRICS_FILE" ]]; then
        log "ERROR: Metrics file not found: $METRICS_FILE"
        # Return 503 Service Unavailable
        cat <<EOF
HTTP/1.0 503 Service Unavailable
Content-Type: text/plain; charset=utf-8
Content-Length: 28
Connection: close

Metrics file not available
EOF
        return 1
    fi
    
    # Read metrics file content
    local metrics_content
    metrics_content=$(cat "$METRICS_FILE")
    local content_length=${#metrics_content}
    
    # Send HTTP response with Prometheus text format
    cat <<EOF
HTTP/1.0 200 OK
Content-Type: text/plain; version=0.0.4; charset=utf-8
Content-Length: $content_length
Connection: close

$metrics_content
EOF
    
    log "Served metrics to $client_ip (${content_length} bytes)"
}

# Main server loop
start_server() {
    log "Starting Prometheus metrics server on port $METRICS_PORT"
    log "Serving metrics from: $METRICS_FILE"
    
    # Check if netcat is available
    if ! command -v nc &> /dev/null; then
        log "ERROR: netcat (nc) is not installed. Cannot start metrics server."
        exit 1
    fi
    
    # Check if port is already in use
    if nc -z localhost "$METRICS_PORT" 2>/dev/null; then
        log "ERROR: Port $METRICS_PORT is already in use"
        exit 1
    fi
    
    initialize_metrics
    
    log "Metrics server ready on port $METRICS_PORT"
    
    # Infinite loop to handle requests
    while true; do
        # Use netcat to listen on the port and serve metrics
        # -l: listen mode
        # -p: port number
        # -q 0: quit 0 seconds after EOF on stdin
        {
            serve_metrics "$(date +'%s')"
        } | nc -l -p "$METRICS_PORT" -q 0 2>/dev/null || {
            # Handle errors gracefully
            sleep 1
        }
    done
}

# Handle signals for graceful shutdown
trap 'log "Shutting down metrics server..."; exit 0' SIGTERM SIGINT

# Start the server
start_server
