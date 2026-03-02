# Phase 3: Enhanced Metrics & Job Tracking (DORA)

## Overview

Phase 3 adds job lifecycle tracking, DORA metrics calculations, and enhanced Grafana dashboards to the GitHub Actions self-hosted runner monitoring stack. It builds on the Phase 1 & 2 metrics infrastructure (Prometheus text format, netcat HTTP server).

## Architecture

### Job Lifecycle Hooks

The GitHub Actions Runner (v2.300.0+) supports native hook scripts via environment variables:

- **`ACTIONS_RUNNER_HOOK_JOB_STARTED`** → `/usr/local/bin/job-started.sh`
- **`ACTIONS_RUNNER_HOOK_JOB_COMPLETED`** → `/usr/local/bin/job-completed.sh`

These are set in the entrypoint scripts (`entrypoint.sh`, `entrypoint-chrome.sh`) before the runner's `config.sh` executes. The runner binary invokes them automatically at job boundaries.

### Data Flow

```text
GitHub Actions Runner
  ├── Job Starts → job-started.sh
  │     ├── Writes "running" entry to /tmp/jobs.log
  │     └── Saves start timestamp to /tmp/job_state/<job_id>.start
  │
  ├── Job Completes → job-completed.sh
  │     ├── Reads start timestamp, calculates duration_seconds
  │     ├── Reads GITHUB_JOB_STATUS for success/failure
  │     ├── Calculates queue_time from GITHUB_RUN_CREATED_AT
  │     ├── Removes preliminary "running" entry from jobs.log
  │     └── Appends final CSV line to jobs.log
  │
  └── metrics-collector.sh (every 30s)
        ├── Reads /tmp/jobs.log
        ├── Computes histogram buckets, averages, counts
        └── Writes /tmp/runner_metrics.prom (Prometheus text format)
              └── Served by metrics-server.sh via netcat on port 9091/9092/9093
```

## Jobs Log Format

**File:** `/tmp/jobs.log`

**CSV Schema:** `timestamp,job_id,status,duration_seconds,queue_time_seconds`

| Field | Description | Example |
|-------|-------------|---------|
| `timestamp` | ISO 8601 UTC timestamp | `2025-07-25T14:30:00Z` |
| `job_id` | Unique identifier (`GITHUB_RUN_ID_GITHUB_JOB`) | `12345678_build` |
| `status` | Job outcome: `success`, `failed`, `cancelled`, `running` | `success` |
| `duration_seconds` | Wall-clock job duration in seconds | `142` |
| `queue_time_seconds` | Time from run creation to job start | `8` |

**Notes:**

- `running` entries are preliminary (written by `job-started.sh`) and cleaned up by `job-completed.sh`
- If `job-completed.sh` cannot determine status, it defaults to `failed`
- Queue time requires `GITHUB_RUN_CREATED_AT` env var (available in runner v2.304.0+)

## New Metrics Reference

### Job Duration Histogram

```text
# HELP github_runner_job_duration_seconds Histogram of job durations
# TYPE github_runner_job_duration_seconds histogram
github_runner_job_duration_seconds_bucket{le="60",runner_name="...",runner_type="..."} 5
github_runner_job_duration_seconds_bucket{le="300",runner_name="...",runner_type="..."} 12
github_runner_job_duration_seconds_bucket{le="600",runner_name="...",runner_type="..."} 15
github_runner_job_duration_seconds_bucket{le="1800",runner_name="...",runner_type="..."} 18
github_runner_job_duration_seconds_bucket{le="3600",runner_name="...",runner_type="..."} 19
github_runner_job_duration_seconds_bucket{le="+Inf",runner_name="...",runner_type="..."} 20
github_runner_job_duration_seconds_sum{runner_name="...",runner_type="..."} 4500.0
github_runner_job_duration_seconds_count{runner_name="...",runner_type="..."} 20
```

**Bucket boundaries:** 60s (1min), 300s (5min), 600s (10min), 1800s (30min), 3600s (1hr), +Inf

### Queue Time

```text
# HELP github_runner_queue_time_seconds Average queue wait time
# TYPE github_runner_queue_time_seconds gauge
github_runner_queue_time_seconds{runner_name="...",runner_type="..."} 12.5
```

Averaged over the last 100 completed jobs.

### Cache Hit Rate (Stubbed)

```text
# HELP github_runner_cache_hit_rate Cache hit rate by type
# TYPE github_runner_cache_hit_rate gauge
github_runner_cache_hit_rate{cache_type="buildkit",runner_name="...",runner_type="..."} 0
github_runner_cache_hit_rate{cache_type="apt",runner_name="...",runner_type="..."} 0
github_runner_cache_hit_rate{cache_type="npm",runner_name="...",runner_type="..."} 0
```

> **Note:** Cache metrics are currently stubbed (always 0). BuildKit cache logs reside on the Docker host, not inside the runner container. A future phase will integrate a sidecar or host-mounted log parser to populate these values.

### Existing Metrics (Enhanced with Labels)

All existing metrics now include `runner_name` and `runner_type` labels:

- `github_runner_info` — Runner metadata (version, OS, arch)
- `github_runner_status` — Online/offline status (1 or 0)
- `github_runner_uptime_seconds` — Seconds since container start
- `github_runner_jobs_total{status="total|success|failed|cancelled"}` — Job counters
- `github_runner_cpu_usage_percent` — Current CPU usage
- `github_runner_memory_usage_percent` — Current memory usage

## DORA Metrics PromQL Examples

### Deployment Frequency (DF)

How often the runner successfully completes jobs in a 24-hour window:

```promql
# Total successful deployments in last 24h
sum(increase(github_runner_jobs_total{status="success"}[24h]))

# Deployments per hour trend
sum(increase(github_runner_jobs_total{status="success"}[1h]))
```

### Lead Time for Changes (LTFC)

Average job duration as a proxy for commit-to-production time:

```promql
# Average job duration
sum(github_runner_job_duration_seconds_sum)
  / clamp_min(sum(github_runner_job_duration_seconds_count), 1)

# p50, p95, p99 percentiles
histogram_quantile(0.50, sum(rate(github_runner_job_duration_seconds_bucket[5m])) by (le))
histogram_quantile(0.95, sum(rate(github_runner_job_duration_seconds_bucket[5m])) by (le))
histogram_quantile(0.99, sum(rate(github_runner_job_duration_seconds_bucket[5m])) by (le))
```

### Change Failure Rate (CFR)

Percentage of failed jobs out of total:

```promql
# Overall CFR
sum(github_runner_jobs_total{status="failed"})
  / clamp_min(sum(github_runner_jobs_total{status="total"}), 1) * 100

# CFR trend per hour
sum(increase(github_runner_jobs_total{status="failed"}[1h]))
  / clamp_min(sum(increase(github_runner_jobs_total{status="total"}[1h])), 1) * 100
```

### Mean Time to Recovery (MTTR)

Average queue time as a proxy for recovery speed:

```promql
avg(github_runner_queue_time_seconds)
```

## DORA Classification Reference

| Metric | Elite | High | Medium | Low |
|--------|-------|------|--------|-----|
| Deployment Frequency | Multiple/day | Weekly–monthly | Monthly–6 months | < 6 months |
| Lead Time | < 1 hour | 1 day–1 week | 1–6 months | > 6 months |
| Change Failure Rate | 0–15% | 16–30% | 16–30% | > 30% |
| MTTR | < 1 hour | < 1 day | 1 day–1 week | > 6 months |

## Grafana Dashboards

### Overview & DORA (`github-runner.json`)

Main dashboard with 4 rows:

1. **Runner Overview** — Online count, total jobs, success rate gauge, uptime, queue time, runner info table
2. **DORA Metrics** — Deployment frequency, lead time, CFR gauge, MTTR, plus trend charts
3. **Job Analysis** — Duration distribution histogram, status pie chart, queue time trend
4. **Performance** — Cache hit rates, CPU usage (cAdvisor), memory usage (cAdvisor)

### DORA Deep Dive (`dora-metrics.json`)

Focused dashboard for DORA analysis with classification reference table.

### Job Analysis (`job-analysis.json`)

Detailed job-level analysis with percentile trends, runner comparisons, and timeline views.

## Ports

| Runner Type | Metrics Port |
|-------------|-------------|
| Standard | 9091 |
| Chrome | 9092 |
| Chrome-Go | 9093 |

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `docker/job-started.sh` | Added | Hook script for job start events |
| `docker/job-completed.sh` | Added | Hook script for job completion events |
| `docker/entrypoint.sh` | Modified | Added hook environment variables |
| `docker/entrypoint-chrome.sh` | Modified | Added hook environment variables |
| `docker/Dockerfile` | Modified | COPY hook scripts to image |
| `docker/Dockerfile.chrome` | Modified | COPY hook scripts to image |
| `docker/Dockerfile.chrome-go` | Modified | COPY hook scripts to image |
| `docker/metrics-collector.sh` | Rewritten | Added histogram, queue time, cache stubs |
| `monitoring/grafana/dashboards/github-runner.json` | Replaced | Comprehensive DORA overview dashboard |
| `monitoring/grafana/dashboards/dora-metrics.json` | Added | DORA-focused dashboard |
| `monitoring/grafana/dashboards/job-analysis.json` | Added | Job analysis dashboard |
