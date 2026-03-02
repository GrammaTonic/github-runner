# Prometheus Monitoring Usage Guide

## Status: ✅ Complete

**Created:** 2026-03-02
**Phase:** 5 — Documentation & User Guide
**Task:** TASK-048

---

## Overview

This guide covers day-to-day usage of the Prometheus monitoring system for GitHub Actions self-hosted runners: accessing metrics, writing PromQL queries, customizing dashboards, and best practices.

For initial setup, see [PROMETHEUS_SETUP.md](PROMETHEUS_SETUP.md).

---

## Accessing the Metrics Endpoint

Each runner container exposes metrics via HTTP:

```bash
# Raw metrics output
curl http://localhost:9091/metrics

# Filter for a specific metric
curl -s http://localhost:9091/metrics | grep github_runner_jobs_total

# Pretty-print with line numbers
curl -s http://localhost:9091/metrics | cat -n
```

The endpoint returns plain text in [Prometheus exposition format](https://prometheus.io/docs/instrumenting/exposition_formats/).

---

## Understanding Metric Types

The runner metrics use three Prometheus types:

### Gauges (current value, can go up or down)

- `github_runner_status` — Runner online/offline state
- `github_runner_info` — Runner metadata (always 1)
- `github_runner_queue_time_seconds` — Average queue wait time
- `github_runner_cache_hit_rate` — Cache hit ratio per type
- `github_runner_last_update_timestamp` — Last metrics update epoch

### Counters (monotonically increasing)

- `github_runner_uptime_seconds` — Total uptime since container start
- `github_runner_jobs_total` — Cumulative job counts by status

### Histograms (distribution of values)

- `github_runner_job_duration_seconds` — Job duration distribution with buckets at 60s, 300s, 600s, 1800s, 3600s, +Inf

For full metric definitions, see [PROMETHEUS_METRICS_REFERENCE.md](PROMETHEUS_METRICS_REFERENCE.md).

---

## Writing PromQL Queries

### Basic Queries

```promql
# Current status of all runners
github_runner_status

# Filter by runner type
github_runner_status{runner_type="chrome"}

# Runner uptime in hours
github_runner_uptime_seconds / 3600

# Total successful jobs
github_runner_jobs_total{status="success"}
```

### Rate and Aggregation

```promql
# Jobs per hour (success)
rate(github_runner_jobs_total{status="success"}[1h]) * 3600

# Total jobs across all runners in last 24h
sum(increase(github_runner_jobs_total{status="total"}[24h]))

# Failed job rate (percentage)
sum(rate(github_runner_jobs_total{status="failed"}[1h]))
  /
sum(rate(github_runner_jobs_total{status="total"}[1h]))
  * 100
```

### DORA Metrics

```promql
# Deployment Frequency (successful builds per day)
sum(increase(github_runner_jobs_total{status="success"}[24h]))

# Lead Time for Changes (average job duration in minutes)
rate(github_runner_job_duration_seconds_sum[5m])
  /
rate(github_runner_job_duration_seconds_count[5m])
  / 60

# Change Failure Rate (%)
sum(increase(github_runner_jobs_total{status="failed"}[24h]))
  /
sum(increase(github_runner_jobs_total{status="total"}[24h]))
  * 100

# Mean Time to Recovery (average duration of failed jobs in minutes)
rate(github_runner_job_duration_seconds_sum{status="failed"}[1h])
  /
rate(github_runner_job_duration_seconds_count{status="failed"}[1h])
  / 60
```

### Histogram Queries

```promql
# Median job duration (p50)
histogram_quantile(0.50, rate(github_runner_job_duration_seconds_bucket[1h]))

# 90th percentile job duration
histogram_quantile(0.90, rate(github_runner_job_duration_seconds_bucket[1h]))

# 99th percentile job duration
histogram_quantile(0.99, rate(github_runner_job_duration_seconds_bucket[1h]))

# Jobs completing under 5 minutes
github_runner_job_duration_seconds_bucket{le="300"}
```

### Runner Comparison

```promql
# Uptime by runner type
github_runner_uptime_seconds by (runner_type)

# Job success rate per runner
github_runner_jobs_total{status="success"} / github_runner_jobs_total{status="total"}

# Queue time per runner
github_runner_queue_time_seconds by (runner_name)
```

---

## Customizing Dashboards

### Modifying Existing Panels

1. Open a dashboard in Grafana.
2. Click the panel title → **Edit**.
3. Modify the PromQL query in the **Query** tab.
4. Adjust visualization options in the **Panel options** tab.
5. Click **Apply** and then **Save dashboard**.

### Adding New Panels

1. Click **Add** → **Visualization** in the dashboard.
2. Select your Prometheus datasource.
3. Enter a PromQL query.
4. Choose a visualization type (Time series, Stat, Gauge, Table, etc.).
5. Configure thresholds:
   - Green: Normal operation
   - Yellow: Warning threshold
   - Red: Critical threshold

### Using Dashboard Variables

All pre-built dashboards include two template variables:

- **`runner_name`**: Multi-select filter by runner name
- **`runner_type`**: Multi-select filter by runner type (standard, chrome, chrome-go)

Use these in custom queries:

```promql
github_runner_jobs_total{runner_name=~"$runner_name", runner_type=~"$runner_type"}
```

### Exporting Customized Dashboards

1. Open the dashboard → **Settings** (gear icon) → **JSON Model**.
2. Copy the JSON.
3. Save to `monitoring/grafana/dashboards/` for version control.

---

## Setting Up Alerts (Prometheus Alertmanager)

> **Note:** Alertmanager deployment is user-provided. These are example alert rules.

### Example Alert Rules

Create a file `prometheus-rules.yml`:

```yaml
groups:
  - name: github-runner-alerts
    rules:
      # Runner is offline
      - alert: RunnerOffline
        expr: github_runner_status == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Runner {{ $labels.runner_name }} is offline"
          description: "Runner has been offline for more than 5 minutes."

      # High failure rate
      - alert: HighJobFailureRate
        expr: >
          (sum by (runner_name) (increase(github_runner_jobs_total{status="failed"}[1h]))
          /
          sum by (runner_name) (increase(github_runner_jobs_total{status="total"}[1h])))
          > 0.15
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "High job failure rate on {{ $labels.runner_name }}"
          description: "Failure rate exceeds 15% over the last hour."

      # Long queue times
      - alert: HighQueueTime
        expr: github_runner_queue_time_seconds > 300
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High queue time on {{ $labels.runner_name }}"
          description: "Average queue time exceeds 5 minutes."

      # Metrics stale (collector may have crashed)
      - alert: MetricsStale
        expr: time() - github_runner_last_update_timestamp > 120
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Stale metrics from {{ $labels.runner_name }}"
          description: "Metrics have not updated for over 2 minutes."
```

Add to Prometheus configuration:

```yaml
rule_files:
  - "/etc/prometheus/rules/prometheus-rules.yml"
```

---

## Best Practices

### Metrics Retention

- **Short-term** (1–7 days): Keep raw 15s scrape data for real-time dashboards.
- **Medium-term** (30 days): Use Prometheus recording rules to downsample.
- **Long-term** (90+ days): Use remote storage (Thanos, Cortex, Mimir) or export metrics.

### Recording Rules for Performance

Pre-compute expensive queries:

```yaml
groups:
  - name: github-runner-recording-rules
    rules:
      - record: job:github_runner_jobs_total:rate1h
        expr: sum by (runner_name, status) (rate(github_runner_jobs_total[1h]))

      - record: job:github_runner_job_duration:p99_1h
        expr: histogram_quantile(0.99, sum by (le, runner_name) (rate(github_runner_job_duration_seconds_bucket[1h])))
```

### Scrape Interval

- **15s** (default): Good balance of granularity and storage.
- **30s**: Reduces storage by ~50%, sufficient for most use cases.
- **5s**: Only for debugging; increases storage significantly.

### Label Cardinality

Keep label cardinality low to avoid Prometheus performance issues:

- `runner_name`: One per runner instance (bounded by deployment size)
- `runner_type`: Three values (`standard`, `chrome`, `chrome-go`)
- `status`: Three values (`total`, `success`, `failed`)
- `cache_type`: Three values (`buildkit`, `apt`, `npm`)

---

## Next Steps

- [Metrics Reference](PROMETHEUS_METRICS_REFERENCE.md) — Full metric definitions and types
- [Troubleshooting](PROMETHEUS_TROUBLESHOOTING.md) — Common issues and fixes
- [Architecture](PROMETHEUS_ARCHITECTURE.md) — System internals
- [Quick Start](PROMETHEUS_QUICKSTART.md) — 5-minute setup
