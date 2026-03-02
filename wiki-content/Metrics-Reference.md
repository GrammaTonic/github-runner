# Metrics Reference

![Prometheus](https://img.shields.io/badge/Prometheus-Metrics-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)

Complete reference for all Prometheus metrics exposed by GitHub Actions self-hosted runners on port **9091**.

---

## 🏷️ Common Labels

All metrics include these labels unless otherwise noted:

| Label | Description | Example Values |
|---|---|---|
| `runner_name` | Runner instance name | `docker-runner`, `chrome-runner-1` |
| `runner_type` | Runner variant | `standard`, `chrome`, `chrome-go` |

---

## 📊 Metrics Summary

| Metric | Type | Labels | Stubbed? | Description |
|---|---|---|---|---|
| `github_runner_status` | Gauge | name, type | No | Runner online/offline (1/0) |
| `github_runner_info` | Gauge | name, type, version | No | Runner metadata (always 1) |
| `github_runner_uptime_seconds` | Counter | name, type | No | Uptime since collector start |
| `github_runner_jobs_total` | Counter | name, type, status | No | Jobs by status (total/success/failed) |
| `github_runner_job_duration_seconds` | Histogram | name, type, le | No | Job duration distribution |
| `github_runner_queue_time_seconds` | Gauge | name, type | No | Average queue time (last 100 jobs) |
| `github_runner_cache_hit_rate` | Gauge | name, type, cache_type | **Yes** | Cache hit rate (stubbed at 0) |
| `github_runner_last_update_timestamp` | Gauge | — | No | Unix epoch of last update |

---

## 🔍 Metric Details

### `github_runner_status`

**Type:** Gauge — Runner online/offline status.

| Value | Meaning |
|---|---|
| `1` | Online (collector running) |
| `0` | Offline |

```promql
# All online runners
github_runner_status == 1

# Count online runners by type
count by (runner_type) (github_runner_status == 1)

# Alert: runner offline
github_runner_status == 0
```

---

### `github_runner_info`

**Type:** Gauge — Runner metadata. Always `1`; informational labels carry the data.

Extra label: `version` (runner software version).

```promql
# List all runners with versions
github_runner_info

# Filter by version
github_runner_info{version="2.332.0"}
```

---

### `github_runner_uptime_seconds`

**Type:** Counter — Seconds since the metrics collector started.

```promql
# Uptime in hours
github_runner_uptime_seconds / 3600

# Alert: recent restart (uptime < 5 min)
github_runner_uptime_seconds < 300
```

---

### `github_runner_jobs_total`

**Type:** Counter — Total jobs processed, segmented by `status` label.

| Status Value | Description |
|---|---|
| `total` | All completed jobs |
| `success` | Successful jobs |
| `failed` | Failed jobs |

```promql
# Jobs per hour
rate(github_runner_jobs_total{status="total"}[1h]) * 3600

# Success rate (%)
github_runner_jobs_total{status="success"}
  / github_runner_jobs_total{status="total"} * 100

# DORA: Deployment Frequency (successful jobs/24h)
sum(increase(github_runner_jobs_total{status="success"}[24h]))

# DORA: Change Failure Rate (%)
sum(increase(github_runner_jobs_total{status="failed"}[24h]))
  / sum(increase(github_runner_jobs_total{status="total"}[24h])) * 100
```

---

### `github_runner_job_duration_seconds`

**Type:** Histogram — Distribution of job execution durations.

**Bucket boundaries:** `60` (1 min), `300` (5 min), `600` (10 min), `1800` (30 min), `3600` (1 hr), `+Inf`.

Sub-metrics: `_bucket`, `_sum`, `_count`.

```promql
# Median (p50) job duration
histogram_quantile(0.50, rate(github_runner_job_duration_seconds_bucket[1h]))

# 90th percentile
histogram_quantile(0.90, rate(github_runner_job_duration_seconds_bucket[1h]))

# DORA: Lead Time (average duration in minutes)
rate(github_runner_job_duration_seconds_sum[5m])
  / rate(github_runner_job_duration_seconds_count[5m]) / 60
```

> **Note:** Buckets are cumulative — each bucket includes all smaller buckets. The `+Inf` bucket equals `_count`.

---

### `github_runner_queue_time_seconds`

**Type:** Gauge — Average queue wait time in seconds (computed from last 100 completed jobs).

```promql
# Queue time per runner
github_runner_queue_time_seconds by (runner_name)

# Alert: queue time > 5 minutes
github_runner_queue_time_seconds > 300
```

> A value of `0` means jobs started immediately with no queuing.

---

### `github_runner_cache_hit_rate`

**Type:** Gauge — Cache hit rate by `cache_type` label (0.0 to 1.0).

| Cache Type | Description |
|---|---|
| `buildkit` | Docker BuildKit layer cache |
| `apt` | APT package cache |
| `npm` | npm package cache |

> ⚠️ **Currently stubbed** — always returns `0`. BuildKit cache logs exist on the Docker host, not inside the runner container. Future work will add a sidecar exporter for real cache data.

---

### `github_runner_last_update_timestamp`

**Type:** Gauge — Unix timestamp of the last metrics collection cycle.

```promql
# Time since last update (staleness detection)
time() - github_runner_last_update_timestamp

# Alert: metrics stale (>2 minutes)
time() - github_runner_last_update_timestamp > 120
```

---

## 📝 Job Log Format

Metrics are derived from `/tmp/jobs.log` inside the container. Each line is CSV:

```
timestamp,job_id,status,duration_seconds,queue_time_seconds
```

| Field | Description | Example |
|---|---|---|
| `timestamp` | ISO 8601 UTC | `2026-03-02T10:05:30Z` |
| `job_id` | `{run_id}_{job_name}` | `12345_build` |
| `status` | Job result | `running`, `success`, `failed` |
| `duration_seconds` | Execution time | `330` |
| `queue_time_seconds` | Time waiting in queue | `12` |

- `running` entries are written by `job-started.sh` (preliminary, excluded from totals).
- Final entries are written by `job-completed.sh` with actual duration and status.

---

## 📊 What's Next?

| Guide | Description |
|---|---|
| [Monitoring Setup](Monitoring-Setup.md) | Quick start and configuration |
| [Grafana Dashboards](Grafana-Dashboards.md) | Dashboard details, import, and customization |
| [Monitoring Troubleshooting](Monitoring-Troubleshooting.md) | Fix common monitoring issues |

> 📖 **Full reference:** See [PROMETHEUS_METRICS_REFERENCE.md](../docs/features/PROMETHEUS_METRICS_REFERENCE.md) in the main docs for extended examples.
