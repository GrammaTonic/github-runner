#!/bin/bash
# job-completed.sh - Runner hook script invoked after each job completes
# Called via ACTIONS_RUNNER_HOOK_JOB_COMPLETED environment variable
#
# Implementation: Phase 3, TASK-027, TASK-028
# Records job completion event to /tmp/jobs.log with duration and status
#
# The GitHub Actions runner (v2.300.0+) sets these env vars before calling this hook:
#   GITHUB_JOB          - Job name
#   GITHUB_RUN_ID       - Workflow run ID
#   GITHUB_RUN_NUMBER   - Workflow run number
#   GITHUB_WORKFLOW      - Workflow name
#   GITHUB_REPOSITORY   - Repository (owner/repo)
#
# Additionally, at job completion the runner provides result context.
# We detect success/failure from the runner's internal result code.

set -euo pipefail

# Configuration
JOBS_LOG="${JOBS_LOG:-/tmp/jobs.log}"
JOB_STATE_DIR="${JOB_STATE_DIR:-/tmp/job_state}"
HOOK_LOG="${HOOK_LOG:-/tmp/job-hooks.log}"

# Source shared utility functions
if [ -f "/usr/local/bin/utils.sh" ]; then
	# shellcheck source=/dev/null
	source /usr/local/bin/utils.sh
elif [ -f "$(dirname "$0")/utils.sh" ]; then
	# shellcheck source=docker/utils.sh
	source "$(dirname "$0")/utils.sh"
fi

# Logging function
log() {
	echo "[$(date +'%Y-%m-%d %H:%M:%S')] [job-completed] $*" | tee -a "$HOOK_LOG"
}

# Derive a unique job identifier (must match job-started.sh logic)
get_job_id() {
	local run_id="${GITHUB_RUN_ID:-0}"
	local job_name="${GITHUB_JOB:-unknown}"

	# Validate inputs to prevent path traversal/injection
	validate_alphanumeric_dash "GITHUB_RUN_ID" "$run_id" || run_id="invalid"
	validate_alphanumeric_dash "GITHUB_JOB" "$job_name" || job_name="invalid"

	echo "${run_id}_${job_name}"
}

# Convert ISO 8601 timestamp to epoch seconds (portable)
iso_to_epoch() {
	local ts="$1"
	# Use date -d for GNU date, fall back to python3 for macOS/BSD
	if date -d "$ts" +%s 2>/dev/null; then
		return
	fi
	# Securely pass timestamp as argument to python to avoid command injection
	python3 -c "import sys; from datetime import datetime; print(int(datetime.fromisoformat(sys.argv[1].replace('Z','+00:00')).timestamp()))" "$ts" 2>/dev/null || echo "0"
}

# Determine job status from available signals
# The runner hook doesn't directly pass a "status" env var in all versions.
# We check multiple sources:
#   1. GITHUB_JOB_STATUS (set by some runner versions)
#   2. Runner's result file if available
#   3. Default to "success" (runner only calls completed hook on non-crash)
determine_status() {
	# Check for explicit status env var (runner v2.304.0+)
	if [[ -n "${GITHUB_JOB_STATUS:-}" ]]; then
		echo "${GITHUB_JOB_STATUS,,}" # lowercase
		return
	fi

	# Check runner's internal result context file
	local job_id="$1"
	local result_file="${JOB_STATE_DIR}/${job_id}.result"
	if [[ -f "$result_file" ]]; then
		cat "$result_file"
		return
	fi

	# Default: if the completed hook is called, the job finished
	# (cancelled/crashed jobs may not trigger the hook at all)
	echo "success"
}

# Main logic
main() {
	local job_id
	local timestamp
	local start_timestamp
	local start_epoch
	local end_epoch
	local duration_seconds
	local queue_time_seconds
	local status

	job_id=$(get_job_id)
	timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
	end_epoch=$(date +%s)

	log "Job completed: id=${job_id} job=${GITHUB_JOB:-unknown} run_id=${GITHUB_RUN_ID:-0}"

	# Calculate duration from start timestamp
	duration_seconds=0
	if [[ -f "${JOB_STATE_DIR}/${job_id}.start" ]]; then
		start_timestamp=$(cat "${JOB_STATE_DIR}/${job_id}.start")
		start_epoch=$(iso_to_epoch "$start_timestamp")
		if [[ "$start_epoch" -gt 0 ]]; then
			duration_seconds=$((end_epoch - start_epoch))
			# Guard against negative values (clock skew)
			if [[ "$duration_seconds" -lt 0 ]]; then
				duration_seconds=0
			fi
		fi
	else
		log "WARNING: No start timestamp found for job ${job_id}"
	fi

	# Calculate queue time if GITHUB_RUN_CREATED_AT is available
	# Queue time = time from workflow creation to job start
	queue_time_seconds=0
	if [[ -n "${GITHUB_RUN_CREATED_AT:-}" ]] && [[ -f "${JOB_STATE_DIR}/${job_id}.start" ]]; then
		local created_epoch
		created_epoch=$(iso_to_epoch "$GITHUB_RUN_CREATED_AT")
		if [[ "$created_epoch" -gt 0 ]] && [[ "$start_epoch" -gt 0 ]]; then
			queue_time_seconds=$((start_epoch - created_epoch))
			if [[ "$queue_time_seconds" -lt 0 ]]; then
				queue_time_seconds=0
			fi
		fi
	fi

	# Determine job status
	status=$(determine_status "$job_id")

	# Remove the preliminary "running" entry and append final entry
	# Use a temp file for atomic update to avoid race conditions
	if [[ -f "$JOBS_LOG" ]]; then
		local temp_log
		temp_log=$(mktemp "${JOBS_LOG}.XXXXXX")
		# Remove matching running entry for this job_id
		grep -v ",${job_id},running," "$JOBS_LOG" >"$temp_log" 2>/dev/null || true
		mv "$temp_log" "$JOBS_LOG"
	fi

	# Append final completed entry
	# Format: timestamp,job_id,status,duration_seconds,queue_time_seconds
	echo "${timestamp},${job_id},${status},${duration_seconds},${queue_time_seconds}" >>"$JOBS_LOG"

	log "Job recorded: status=${status} duration=${duration_seconds}s queue_time=${queue_time_seconds}s"

	# Clean up state files for this job
	rm -f "${JOB_STATE_DIR}/${job_id}.start" "${JOB_STATE_DIR}/${job_id}.result"
}

main "$@"
