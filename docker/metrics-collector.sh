#!/bin/bash
# metrics-collector.sh - Collects and updates Prometheus metrics every 30 seconds
# Reads from /tmp/jobs.log and system stats to generate runner metrics
#
# Based on spike research: SPIKE-001 (APPROVED)
# Implementation: Phase 1, TASK-002
# Created: 2025-11-17

set -euo pipefail

# Configuration
METRICS_FILE="${METRICS_FILE:-/tmp/runner_metrics.prom}"
JOBS_LOG="${JOBS_LOG:-/tmp/jobs.log}"
UPDATE_INTERVAL="${UPDATE_INTERVAL:-30}"
RUNNER_NAME="${RUNNER_NAME:-unknown}"
RUNNER_TYPE="${RUNNER_TYPE:-standard}"
RUNNER_VERSION="${RUNNER_VERSION:-2.3.0}"
COLLECTOR_LOG="${COLLECTOR_LOG:-/tmp/metrics-collector.log}"

# Start time for uptime calculation
START_TIME=$(date +%s)

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$COLLECTOR_LOG"
}

# Initialize job log if it doesn't exist
initialize_job_log() {
    if [[ ! -f "$JOBS_LOG" ]]; then
        log "Initializing job log: $JOBS_LOG"
        touch "$JOBS_LOG"
    fi
}

# Count jobs by status from job log
# Expected format: timestamp,job_id,status,duration,queue_time
count_jobs() {
    local status="$1"
    
    if [[ ! -f "$JOBS_LOG" ]]; then
        echo "0"
        return
    fi
    
    # Count lines with matching status (case-insensitive)
    # Use grep with -c for count, or 0 if no matches
    grep -i ",${status}," "$JOBS_LOG" 2>/dev/null | wc -l | tr -d ' ' || echo "0"
}

# Get total job count
count_total_jobs() {
    if [[ ! -f "$JOBS_LOG" ]] || [[ ! -s "$JOBS_LOG" ]]; then
        echo "0"
        return
    fi
    
    # Count non-empty lines
    grep -v '^$' "$JOBS_LOG" 2>/dev/null | wc -l | tr -d ' ' || echo "0"
}

# Calculate runner uptime in seconds
calculate_uptime() {
    local current_time
    current_time=$(date +%s)
    echo $((current_time - START_TIME))
}

# Get runner status (1=online, 0=offline)
get_runner_status() {
    # For now, always return 1 (online) since this script is running
    # Future: could check GitHub API or runner process status
    echo "1"
}

# Generate Prometheus metrics
generate_metrics() {
    local uptime
    local status
    local total_jobs
    local success_jobs
    local failed_jobs
    
    uptime=$(calculate_uptime)
    status=$(get_runner_status)
    total_jobs=$(count_total_jobs)
    success_jobs=$(count_jobs "success")
    failed_jobs=$(count_jobs "failed")
    
    # Generate metrics in Prometheus text format
    cat <<EOF
# HELP github_runner_status Runner status (1=online, 0=offline)
# TYPE github_runner_status gauge
github_runner_status $status

# HELP github_runner_info Runner information
# TYPE github_runner_info gauge
github_runner_info{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE",version="$RUNNER_VERSION"} 1

# HELP github_runner_uptime_seconds Runner uptime in seconds
# TYPE github_runner_uptime_seconds counter
github_runner_uptime_seconds $uptime

# HELP github_runner_jobs_total Total number of jobs processed by status
# TYPE github_runner_jobs_total counter
github_runner_jobs_total{status="total"} $total_jobs
github_runner_jobs_total{status="success"} $success_jobs
github_runner_jobs_total{status="failed"} $failed_jobs

# HELP github_runner_last_update_timestamp Unix timestamp of last metrics update
# TYPE github_runner_last_update_timestamp gauge
github_runner_last_update_timestamp $(date +%s)
EOF
}

# Update metrics file atomically
update_metrics() {
    local temp_file="${METRICS_FILE}.tmp"
    
    # Generate metrics to temporary file
    generate_metrics > "$temp_file"
    
    # Atomic move (replaces old file)
    mv "$temp_file" "$METRICS_FILE"
    
    log "Metrics updated: uptime=$(calculate_uptime)s, jobs=$(count_total_jobs)"
}

# Main collector loop
start_collector() {
    log "Starting Prometheus metrics collector"
    log "Update interval: ${UPDATE_INTERVAL}s"
    log "Runner: $RUNNER_NAME (type: $RUNNER_TYPE, version: $RUNNER_VERSION)"
    log "Metrics file: $METRICS_FILE"
    log "Jobs log: $JOBS_LOG"
    
    initialize_job_log
    
    # Initial metrics update
    update_metrics
    log "Initial metrics generated"
    
    # Continuous update loop
    while true; do
        sleep "$UPDATE_INTERVAL"
        
        # Update metrics
        if update_metrics; then
            : # Success logged in update_metrics
        else
            log "ERROR: Failed to update metrics"
        fi
    done
}

# Handle signals for graceful shutdown
trap 'log "Shutting down metrics collector..."; exit 0' SIGTERM SIGINT

# Start the collector
start_collector
