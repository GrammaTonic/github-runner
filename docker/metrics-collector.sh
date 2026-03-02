#!/bin/bash
# metrics-collector.sh - Collects and updates Prometheus metrics every 30 seconds
# Reads from /tmp/jobs.log and system stats to generate runner metrics
#
# Based on spike research: SPIKE-001 (APPROVED)
# Implementation: Phase 1, TASK-002 | Phase 3, TASK-029/030/031/032/033
# Created: 2025-11-17
# Updated: 2026-03-02 - Phase 3: Added histogram, queue time, cache metrics

set -euo pipefail

# Configuration
METRICS_FILE="${METRICS_FILE:-/tmp/runner_metrics.prom}"
JOBS_LOG="${JOBS_LOG:-/tmp/jobs.log}"
UPDATE_INTERVAL="${UPDATE_INTERVAL:-30}"
RUNNER_NAME="${RUNNER_NAME:-unknown}"
RUNNER_TYPE="${RUNNER_TYPE:-standard}"
RUNNER_VERSION="${RUNNER_VERSION:-2.332.0}"
COLLECTOR_LOG="${COLLECTOR_LOG:-/tmp/metrics-collector.log}"

# Start time for uptime calculation
START_TIME=$(date +%s)

# TASK-029: Histogram bucket boundaries (in seconds)
# le=60 (1min), le=300 (5min), le=600 (10min), le=1800 (30min), le=3600 (1hr), le=+Inf
HISTOGRAM_BUCKETS=(60 300 600 1800 3600)

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
# Expected format: timestamp,job_id,status,duration_seconds,queue_time_seconds
count_jobs() {
	local status="$1"

	if [[ ! -f "$JOBS_LOG" ]]; then
		echo "0"
		return
	fi

	# Count lines with matching status (case-insensitive)
	# Exclude "running" entries (preliminary, not yet completed)
	grep -c -i ",${status}," "$JOBS_LOG" 2>/dev/null || echo "0"
}

# Get total job count (excluding running/preliminary entries)
count_total_jobs() {
	if [[ ! -f "$JOBS_LOG" ]] || [[ ! -s "$JOBS_LOG" ]]; then
		echo "0"
		return
	fi

	# Count non-empty lines, excluding "running" entries
	grep -v ',running,' "$JOBS_LOG" 2>/dev/null | grep -c -v '^$' 2>/dev/null || echo "0"
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

# TASK-029: Calculate job duration histogram buckets
# Reads completed job entries from jobs.log and computes cumulative bucket counts
# Output: sets global arrays for histogram data
calculate_histogram() {
	local -n bucket_counts_ref=$1
	local -n sum_ref=$2
	local -n count_ref=$3

	sum_ref=0
	count_ref=0

	# Initialize bucket counts to 0
	local i
	for i in "${!HISTOGRAM_BUCKETS[@]}"; do
		bucket_counts_ref[i]=0
	done
	# +Inf bucket
	bucket_counts_ref[${#HISTOGRAM_BUCKETS[@]}]=0

	if [[ ! -f "$JOBS_LOG" ]] || [[ ! -s "$JOBS_LOG" ]]; then
		return
	fi

	# Read completed job durations (field 4 = duration_seconds)
	# Skip running entries and empty lines
	while IFS=',' read -r _ts _id status duration _queue; do
		# Skip running/incomplete entries
		[[ "$status" == "running" ]] && continue
		[[ -z "$duration" ]] && continue

		# Validate duration is numeric
		if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
			continue
		fi

		# Increment sum and count
		sum_ref=$((sum_ref + duration))
		count_ref=$((count_ref + 1))

		# Increment histogram buckets (cumulative)
		for i in "${!HISTOGRAM_BUCKETS[@]}"; do
			if [[ "$duration" -le "${HISTOGRAM_BUCKETS[$i]}" ]]; then
				bucket_counts_ref[i]=$((bucket_counts_ref[i] + 1))
			fi
		done
		# +Inf bucket always increments
		bucket_counts_ref[${#HISTOGRAM_BUCKETS[@]}]=$((bucket_counts_ref[${#HISTOGRAM_BUCKETS[@]}] + 1))
	done < <(grep -v '^$' "$JOBS_LOG" 2>/dev/null || true)

	# Make buckets cumulative (each bucket includes all smaller buckets)
	# The above loop already counts per-bucket, but Prometheus requires cumulative
	# So we need to accumulate: bucket[i] += bucket[i-1]
	for ((i = 1; i < ${#HISTOGRAM_BUCKETS[@]}; i++)); do
		bucket_counts_ref[i]=$((bucket_counts_ref[i] + bucket_counts_ref[i - 1]))
	done
	# +Inf = total count
	bucket_counts_ref[${#HISTOGRAM_BUCKETS[@]}]=$count_ref
}

# TASK-030: Calculate average queue time from recent jobs
calculate_queue_time() {
	local max_jobs=100
	local total_queue=0
	local queue_count=0

	if [[ ! -f "$JOBS_LOG" ]] || [[ ! -s "$JOBS_LOG" ]]; then
		echo "0"
		return
	fi

	# Read queue times from completed jobs (field 5 = queue_time_seconds)
	while IFS=',' read -r _ts _id status _duration queue_time; do
		[[ "$status" == "running" ]] && continue
		[[ -z "$queue_time" ]] && continue
		if ! [[ "$queue_time" =~ ^[0-9]+$ ]]; then
			continue
		fi

		total_queue=$((total_queue + queue_time))
		queue_count=$((queue_count + 1))

		if [[ "$queue_count" -ge "$max_jobs" ]]; then
			break
		fi
	done < <(tail -n "$max_jobs" "$JOBS_LOG" 2>/dev/null | grep -v '^$' || true)

	if [[ "$queue_count" -gt 0 ]]; then
		echo $((total_queue / queue_count))
	else
		echo "0"
	fi
}

# TASK-031/032/033: Calculate cache hit rates
# TODO: BuildKit cache logs are on the Docker host, not inside the runner container.
# This function currently returns placeholder values (0.0).
# Future work: parse docker build output, query buildx metadata, or use host-side exporter.
# shellcheck disable=SC2034  # Variables assigned via nameref to caller's scope
calculate_cache_metrics() {
	local -n buildkit_ref=$1
	local -n apt_ref=$2
	local -n npm_ref=$3

	# Stub values - data source integration pending
	buildkit_ref="0"
	apt_ref="0"
	npm_ref="0"
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

	# TASK-029: Calculate histogram data
	local -a hist_buckets
	local hist_sum
	local hist_count
	calculate_histogram hist_buckets hist_sum hist_count

	# TASK-030: Calculate queue time
	local avg_queue_time
	avg_queue_time=$(calculate_queue_time)

	# TASK-031/032/033: Calculate cache metrics
	local cache_buildkit cache_apt cache_npm
	calculate_cache_metrics cache_buildkit cache_apt cache_npm

	# Generate metrics in Prometheus text format
	cat <<EOF
# HELP github_runner_status Runner status (1=online, 0=offline)
# TYPE github_runner_status gauge
github_runner_status{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} $status

# HELP github_runner_info Runner information
# TYPE github_runner_info gauge
github_runner_info{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE",version="$RUNNER_VERSION"} 1

# HELP github_runner_uptime_seconds Runner uptime in seconds
# TYPE github_runner_uptime_seconds counter
github_runner_uptime_seconds{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} $uptime

# HELP github_runner_jobs_total Total number of jobs processed by status
# TYPE github_runner_jobs_total counter
github_runner_jobs_total{status="total",runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} $total_jobs
github_runner_jobs_total{status="success",runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} $success_jobs
github_runner_jobs_total{status="failed",runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} $failed_jobs

# HELP github_runner_job_duration_seconds Histogram of job durations in seconds
# TYPE github_runner_job_duration_seconds histogram
github_runner_job_duration_seconds_bucket{le="60",runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} ${hist_buckets[0]:-0}
github_runner_job_duration_seconds_bucket{le="300",runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} ${hist_buckets[1]:-0}
github_runner_job_duration_seconds_bucket{le="600",runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} ${hist_buckets[2]:-0}
github_runner_job_duration_seconds_bucket{le="1800",runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} ${hist_buckets[3]:-0}
github_runner_job_duration_seconds_bucket{le="3600",runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} ${hist_buckets[4]:-0}
github_runner_job_duration_seconds_bucket{le="+Inf",runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} ${hist_buckets[5]:-0}
github_runner_job_duration_seconds_sum{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} $hist_sum
github_runner_job_duration_seconds_count{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} $hist_count

# HELP github_runner_queue_time_seconds Average queue time in seconds (last 100 jobs)
# TYPE github_runner_queue_time_seconds gauge
github_runner_queue_time_seconds{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} $avg_queue_time

# HELP github_runner_cache_hit_rate Cache hit rate by type (0.0-1.0)
# TYPE github_runner_cache_hit_rate gauge
github_runner_cache_hit_rate{cache_type="buildkit",runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} $cache_buildkit
github_runner_cache_hit_rate{cache_type="apt",runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} $cache_apt
github_runner_cache_hit_rate{cache_type="npm",runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} $cache_npm

# HELP github_runner_last_update_timestamp Unix timestamp of last metrics update
# TYPE github_runner_last_update_timestamp gauge
github_runner_last_update_timestamp $(date +%s)
EOF
}

# Update metrics file atomically
update_metrics() {
	local temp_file="${METRICS_FILE}.tmp"

	# Generate metrics to temporary file
	generate_metrics >"$temp_file"

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
