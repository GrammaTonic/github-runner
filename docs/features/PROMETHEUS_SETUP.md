# Prometheus Monitoring Setup Guide

## Status: ✅ Complete

**Created:** 2026-03-02
**Phase:** 5 — Documentation & User Guide
**Task:** TASK-047

---

## Overview

This guide walks you through setting up Prometheus monitoring for GitHub Actions self-hosted runners. The runners expose custom metrics on port 9091 in Prometheus text format. You bring your own Prometheus and Grafana instances; this project provides the metrics endpoint and pre-built dashboards.

---

## Prerequisites

Before you begin, ensure you have:

| Requirement | Version | Purpose |
|---|---|---|
| Docker Engine | 20.10+ | Container runtime |
| Docker Compose | v2.0+ | Orchestration |
| Prometheus | 2.30+ | Metrics scraping and storage |
| Grafana | 9.0+ | Dashboard visualization |
| Network access | — | Prometheus must reach runners on port 9091 |

> **Note:** Prometheus and Grafana are **user-provided** — this project does not deploy or manage them.

---

## Step 1: Deploy Runners with Metrics Enabled

Metrics are enabled by default on all runner types. Each runner exposes metrics on container port `9091`.

### Standard Runner

```bash
# Copy and configure environment
cp config/runner.env.example config/runner.env
# Edit config/runner.env with your GITHUB_TOKEN and GITHUB_REPOSITORY

# Deploy
docker compose -f docker/docker-compose.production.yml up -d
```

Host port mapping: `9091:9091`

### Chrome Runner

```bash
cp config/chrome-runner.env.example config/chrome-runner.env
# Edit config/chrome-runner.env

docker compose -f docker/docker-compose.chrome.yml up -d
```

Host port mapping: `9092:9091`

### Chrome-Go Runner

```bash
cp config/chrome-go-runner.env.example config/chrome-go-runner.env
# Edit config/chrome-go-runner.env

docker compose -f docker/docker-compose.chrome-go.yml up -d
```

Host port mapping: `9093:9091`

---

## Step 2: Verify Metrics Endpoint

Confirm each runner is serving metrics:

```bash
# Standard runner
curl -s http://localhost:9091/metrics | head -20

# Chrome runner
curl -s http://localhost:9092/metrics | head -20

# Chrome-Go runner
curl -s http://localhost:9093/metrics | head -20
```

You should see output in Prometheus text format:

```
# HELP github_runner_status Runner status (1=online, 0=offline)
# TYPE github_runner_status gauge
github_runner_status{runner_name="docker-runner",runner_type="standard"} 1

# HELP github_runner_uptime_seconds Runner uptime in seconds
# TYPE github_runner_uptime_seconds counter
github_runner_uptime_seconds{runner_name="docker-runner",runner_type="standard"} 120
```

---

## Step 3: Configure Prometheus Scrape Targets

Add the runner scrape targets to your `prometheus.yml`. An example configuration is provided at [`monitoring/prometheus-scrape-example.yml`](../../monitoring/prometheus-scrape-example.yml).

### Minimal Scrape Config

Add these jobs to your Prometheus `scrape_configs`:

```yaml
scrape_configs:
  # Standard runner
  - job_name: "github-runner-standard"
    static_configs:
      - targets: ["<runner-host>:9091"]
    scrape_interval: 15s
    metrics_path: /metrics
    scrape_timeout: 10s

  # Chrome runner
  - job_name: "github-runner-chrome"
    static_configs:
      - targets: ["<runner-host>:9092"]
    scrape_interval: 15s
    metrics_path: /metrics
    scrape_timeout: 10s

  # Chrome-Go runner
  - job_name: "github-runner-chrome-go"
    static_configs:
      - targets: ["<runner-host>:9093"]
    scrape_interval: 15s
    metrics_path: /metrics
    scrape_timeout: 10s
```

Replace `<runner-host>` with your Docker host IP or hostname. If Prometheus runs on the same Docker network, use the container service names (e.g., `github-runner-main:9091`).

### Docker Network Scrape Config

When Prometheus is on the same Docker Compose network:

```yaml
scrape_configs:
  - job_name: "github-runner-standard"
    static_configs:
      - targets: ["github-runner-main:9091"]
    scrape_interval: 15s
    metrics_path: /metrics
    scrape_timeout: 10s
```

### Reload Prometheus

After updating the configuration:

```bash
# Option 1: Send SIGHUP
kill -HUP $(pidof prometheus)

# Option 2: Use the reload API (if --web.enable-lifecycle is set)
curl -X POST http://localhost:9090/-/reload
```

---

## Step 4: Configure Grafana Datasource

1. Open Grafana (e.g., `http://localhost:3000`).
2. Go to **Configuration → Data Sources → Add data source**.
3. Select **Prometheus**.
4. Set the URL to your Prometheus server (e.g., `http://prometheus:9090`).
5. Click **Save & Test** to verify connectivity.

---

## Step 5: Import Grafana Dashboards

This project provides 4 pre-built dashboards in `monitoring/grafana/dashboards/`:

| Dashboard | File | Panels |
|---|---|---|
| Runner Overview | `runner-overview.json` | 12 |
| DORA Metrics | `dora-metrics.json` | 12 |
| Performance Trends | `performance-trends.json` | 14 |
| Job Analysis | `job-analysis.json` | 16 |

### Manual Import

1. Open Grafana → **Dashboards → Import**.
2. Click **Upload JSON file**.
3. Select a dashboard JSON file from `monitoring/grafana/dashboards/`.
4. Select your Prometheus datasource when prompted.
5. Click **Import**.
6. Repeat for each dashboard.

### Automatic Provisioning

If you mount the dashboards directory into Grafana, use the provisioning config at [`monitoring/grafana/provisioning/dashboards/dashboards.yml`](../../monitoring/grafana/provisioning/dashboards/dashboards.yml):

```yaml
# docker-compose snippet for Grafana
services:
  grafana:
    image: grafana/grafana:latest
    volumes:
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
    ports:
      - "3000:3000"
```

Grafana will automatically load all dashboards on startup.

---

## Step 6: Verify End-to-End

1. **Prometheus Targets**: Go to Prometheus → Status → Targets. Confirm runner targets show `UP`.
2. **Test Query**: Run in Prometheus:

   ```promql
   github_runner_status
   ```

   Should return `1` for each runner.
3. **Grafana Dashboards**: Open the Runner Overview dashboard. Panels should show live data.

---

## Environment Variables Reference

These variables control metrics behavior in runner containers:

| Variable | Default | Description |
|---|---|---|
| `METRICS_PORT` | `9091` | Port for the metrics HTTP server |
| `METRICS_FILE` | `/tmp/runner_metrics.prom` | Path to the generated metrics file |
| `METRICS_UPDATE_INTERVAL` | `30` | Seconds between metrics updates |
| `RUNNER_NAME` | `unknown` | Runner name label in metrics |
| `RUNNER_TYPE` | `standard` | Runner type label (`standard`, `chrome`, `chrome-go`) |
| `RUNNER_VERSION` | `2.332.0` | Runner version in `github_runner_info` |
| `JOBS_LOG` | `/tmp/jobs.log` | Path to the job log file |
| `JOB_STATE_DIR` | `/tmp/job_state` | Directory for per-job state files |

---

## Port Mapping Summary

| Runner Type | Container Port | Default Host Port | Compose File |
|---|---|---|---|
| Standard | 9091 | 9091 | `docker-compose.production.yml` |
| Chrome | 9091 | 9092 | `docker-compose.chrome.yml` |
| Chrome-Go | 9091 | 9093 | `docker-compose.chrome-go.yml` |

---

## Troubleshooting Setup Issues

| Symptom | Cause | Fix |
|---|---|---|
| `curl` returns "Connection refused" | Container not running or port not mapped | Check `docker ps` and compose port mappings |
| Prometheus target shows `DOWN` | Network connectivity issue | Ensure Prometheus can reach the runner host/port |
| Grafana shows "No Data" | Datasource misconfigured or no scrape data yet | Verify Prometheus datasource URL and wait for first scrape |
| Metrics file empty | Collector script not running | Check container logs: `docker logs <container>` |

For detailed troubleshooting, see [PROMETHEUS_TROUBLESHOOTING.md](PROMETHEUS_TROUBLESHOOTING.md).

---

## Next Steps

- [Quick Start Guide](PROMETHEUS_QUICKSTART.md) — 5-minute setup
- [Usage Guide](PROMETHEUS_USAGE.md) — PromQL queries and dashboard customization
- [Metrics Reference](PROMETHEUS_METRICS_REFERENCE.md) — Full metric definitions
- [Architecture](PROMETHEUS_ARCHITECTURE.md) — How the metrics system works
