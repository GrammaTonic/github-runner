# Monitoring Setup

![Prometheus](https://img.shields.io/badge/Prometheus-Metrics-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-Dashboards-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Status](https://img.shields.io/badge/Status-Production%20Ready-success?style=for-the-badge)

All GitHub Actions self-hosted runners expose custom Prometheus metrics on port **9091**. This guide walks you through connecting your existing Prometheus and Grafana instances to collect and visualize runner telemetry.

---

## 🎯 What You Get

- **8 custom metrics** covering runner status, job counts, duration histograms, DORA metrics, and more
- **4 pre-built Grafana dashboards** (54 panels total) for runner health, DORA metrics, performance trends, and job analysis
- **Zero dependencies** — pure Bash implementation, no external exporters required

> **Note:** This project provides the metrics endpoint and dashboards. You bring your own Prometheus and Grafana.

---

## ⚡ 5-Minute Quick Start

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

### Step 3: Add Scrape Target

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

### Step 5: Verify End-to-End

1. **Prometheus**: Open `http://localhost:9090/targets` — runner target should show `UP`.
2. **Grafana**: Open the **Runner Overview** dashboard — panels should display live data.

---

## 🐳 Runner Types and Port Mapping

Each runner type listens on container port 9091 internally, but maps to a different host port:

| Runner Type | Compose File | Host Port | Container Port | Verify Command |
|---|---|---|---|---|
| **Standard** | `docker-compose.production.yml` | `9091` | `9091` | `curl http://localhost:9091/metrics` |
| **Chrome** | `docker-compose.chrome.yml` | `9092` | `9091` | `curl http://localhost:9092/metrics` |
| **Chrome-Go** | `docker-compose.chrome-go.yml` | `9093` | `9091` | `curl http://localhost:9093/metrics` |

### Multi-Runner Deployment

Deploy all three runner types simultaneously:

```bash
# Standard runner (host port 9091)
docker compose -f docker/docker-compose.production.yml up -d

# Chrome runner (host port 9092)
cp config/chrome-runner.env.example config/chrome-runner.env
# Edit chrome-runner.env
docker compose -f docker/docker-compose.chrome.yml up -d

# Chrome-Go runner (host port 9093)
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

## ⚙️ Environment Variables

Configure monitoring behavior through environment variables in your runner `.env` file:

| Variable | Default | Description |
|---|---|---|
| `RUNNER_TYPE` | `standard` | Runner type label (`standard`, `chrome`, `chrome-go`) |
| `METRICS_PORT` | `9091` | Container port for the metrics endpoint |
| `METRICS_UPDATE_INTERVAL` | `30` | Seconds between metrics collector updates |

These are pre-configured in the compose files. Override only if needed.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Your Infrastructure (User-Provided)                         │
│  ┌──────────────────┐    ┌──────────────────┐               │
│  │   Prometheus      │───▶│     Grafana       │              │
│  │   scrapes :909x   │    │  4 dashboards     │              │
│  └────────┬─────────┘    └──────────────────┘               │
│           │                                                   │
├───────────┼───────────────────────────────────────────────────┤
│  Runner Containers (This Project)                             │
│           │                                                   │
│  ┌────────▼─────────┐  ┌───────────────────┐                │
│  │  metrics-server   │  │  metrics-collector │                │
│  │  (netcat :9091)   │  │  (bash, 30s loop)  │                │
│  └────────┬─────────┘  └────────┬──────────┘                │
│           │                      │                            │
│  ┌────────▼──────────────────────▼──────────┐                │
│  │  /tmp/runner_metrics.prom                 │                │
│  │  (Prometheus text format)                 │                │
│  └───────────────────────────────────────────┘                │
└───────────────────────────────────────────────────────────────┘
```

**How it works:**

1. `metrics-collector.sh` runs every 30 seconds, gathers runner data, and writes `/tmp/runner_metrics.prom`.
2. `metrics-server.sh` uses netcat to serve that file over HTTP on port 9091.
3. `job-started.sh` and `job-completed.sh` hook scripts log job events to `/tmp/jobs.log`.
4. Prometheus scrapes the endpoint; Grafana queries Prometheus.

> 📖 **Full architecture details:** See [Prometheus Architecture](../docs/features/PROMETHEUS_ARCHITECTURE.md) in the main docs.

---

## 📊 What's Next?

| Guide | Description |
|---|---|
| [Metrics Reference](Metrics-Reference.md) | All 8 metrics with types, labels, and PromQL examples |
| [Grafana Dashboards](Grafana-Dashboards.md) | Dashboard details, import instructions, and customization |
| [Monitoring Troubleshooting](Monitoring-Troubleshooting.md) | Fix common monitoring issues |
| [Production Deployment](Production-Deployment.md) | Full production setup with monitoring stack |

> 📖 **Detailed documentation:** The [docs/features/](../docs/features/) directory contains comprehensive guides for [setup](../docs/features/PROMETHEUS_SETUP.md), [usage & PromQL](../docs/features/PROMETHEUS_USAGE.md), [architecture](../docs/features/PROMETHEUS_ARCHITECTURE.md), and [troubleshooting](../docs/features/PROMETHEUS_TROUBLESHOOTING.md).
