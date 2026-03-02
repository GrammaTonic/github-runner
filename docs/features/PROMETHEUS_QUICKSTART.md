# Prometheus Monitoring Quick Start

## Status: ✅ Complete

**Created:** 2026-03-02
**Phase:** 5 — Documentation & User Guide
**Task:** TASK-056

---

## 5-Minute Setup

Get runner metrics into Prometheus and Grafana in 5 steps.

### Prerequisites

- Docker and Docker Compose installed
- Prometheus server running and accessible
- Grafana server running with Prometheus datasource configured

---

### Step 1: Deploy a Runner

```bash
# Clone the repository
git clone https://github.com/GrammaTonic/github-runner.git
cd github-runner

# Configure
cp config/runner.env.example config/runner.env
# Edit config/runner.env — set GITHUB_TOKEN and GITHUB_REPOSITORY

# Start
docker compose -f docker/docker-compose.production.yml up -d
```

### Step 2: Verify Metrics

```bash
curl http://localhost:9091/metrics
```

You should see Prometheus-formatted output with metrics like `github_runner_status`, `github_runner_uptime_seconds`, etc.

### Step 3: Add Scrape Target to Prometheus

Add to your `prometheus.yml` under `scrape_configs`:

```yaml
- job_name: "github-runner"
  static_configs:
    - targets: ["<your-docker-host>:9091"]
  scrape_interval: 15s
  metrics_path: /metrics
```

Reload Prometheus:

```bash
curl -X POST http://localhost:9090/-/reload
```

### Step 4: Import Grafana Dashboards

1. Open Grafana → **Dashboards → Import**.
2. Upload JSON files from `monitoring/grafana/dashboards/`:
   - `runner-overview.json` — Status and health
   - `dora-metrics.json` — DORA metrics
   - `job-analysis.json` — Job details
   - `performance-trends.json` — Performance data
3. Select your Prometheus datasource when prompted.

### Step 5: Verify

1. Check Prometheus: `http://localhost:9090/targets` — runner target should be `UP`.
2. Check Grafana: Open the **Runner Overview** dashboard — panels should show live data.

---

## Multi-Runner Setup

Deploy all three runner types:

```bash
# Standard runner (port 9091)
docker compose -f docker/docker-compose.production.yml up -d

# Chrome runner (port 9092)
cp config/chrome-runner.env.example config/chrome-runner.env
# Edit chrome-runner.env
docker compose -f docker/docker-compose.chrome.yml up -d

# Chrome-Go runner (port 9093)
cp config/chrome-go-runner.env.example config/chrome-go-runner.env
# Edit chrome-go-runner.env
docker compose -f docker/docker-compose.chrome-go.yml up -d
```

Add all targets to Prometheus:

```yaml
scrape_configs:
  - job_name: "github-runner-standard"
    static_configs:
      - targets: ["<host>:9091"]
  - job_name: "github-runner-chrome"
    static_configs:
      - targets: ["<host>:9092"]
  - job_name: "github-runner-chrome-go"
    static_configs:
      - targets: ["<host>:9093"]
```

---

## What's Next?

| Guide | Description |
|---|---|
| [Full Setup Guide](PROMETHEUS_SETUP.md) | Detailed configuration options and provisioning |
| [Usage Guide](PROMETHEUS_USAGE.md) | PromQL queries, alerts, and dashboard customization |
| [Metrics Reference](PROMETHEUS_METRICS_REFERENCE.md) | Complete metric definitions and examples |
| [Architecture](PROMETHEUS_ARCHITECTURE.md) | How the metrics system works internally |
| [Troubleshooting](PROMETHEUS_TROUBLESHOOTING.md) | Fix common issues |
