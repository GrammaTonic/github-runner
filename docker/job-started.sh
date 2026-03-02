#!/bin/bash
# job-started.sh - Runner hook script invoked before each job starts
# Called via ACTIONS_RUNNER_HOOK_JOB_STARTED environment variable
#
# Implementation: Phase 3, TASK-027, TASK-028
# Records job start event to /tmp/jobs.log for metrics collection
#
# The GitHub Actions runner (v2.300.0+) sets these env vars before calling this hook:
#   GITHUB_JOB          - Job name
#   GITHUB_RUN_ID       - Workflow run ID
#   GITHUB_RUN_NUMBER   - Workflow run number
#   GITHUB_WORKFLOW      - Workflow name
#   GITHUB_REPOSITORY   - Repository (owner/repo)

set -euo pipefail

# Configuration
JOBS_LOG="${JOBS_LOG:-/tmp/jobs.log}"
JOB_STATE_DIR="${JOB_STATE_DIR:-/tmp/job_state}"
HOOK_LOG="${HOOK_LOG:-/tmp/job-hooks.log}"

# Logging function
log() {
	echo "[$(date +'%Y-%m-%d %H:%M:%S')] [job-started] $*" | tee -a "$HOOK_LOG"
}

# Derive a unique job identifier from available environment variables
get_job_id() {
	local run_id="${GITHUB_RUN_ID:-0}"
	local job_name="${GITHUB_JOB:-unknown}"
	# Combine run_id and job_name for uniqueness within a workflow
	echo "${run_id}_${job_name}"
}

# Main logic
main() {
	local job_id
	local timestamp

	job_id=$(get_job_id)
	timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

	log "Job starting: id=${job_id} job=${GITHUB_JOB:-unknown} run_id=${GITHUB_RUN_ID:-0} workflow=${GITHUB_WORKFLOW:-unknown}"

	# Create state directory for per-job tracking
	mkdir -p "$JOB_STATE_DIR"

	# Record start timestamp for duration calculation in job-completed.sh
	echo "$timestamp" >"${JOB_STATE_DIR}/${job_id}.start"

	# Write a preliminary entry to jobs.log (status=running, duration/queue_time TBD)
	# Final entry with duration and status is written by job-completed.sh
	# Format: timestamp,job_id,status,duration_seconds,queue_time_seconds
	echo "${timestamp},${job_id},running,0,0" >>"$JOBS_LOG"

	log "Job start recorded: ${JOB_STATE_DIR}/${job_id}.start"
}

main "$@"
