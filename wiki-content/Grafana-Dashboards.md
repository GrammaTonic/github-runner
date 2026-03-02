# Grafana Dashboards

![Grafana](https://img.shields.io/badge/Grafana-Dashboards-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Dashboards](https://img.shields.io/badge/Dashboards-4%20Included-blue?style=for-the-badge)

Pre-built Grafana dashboards for visualizing GitHub Actions self-hosted runner metrics. Import the JSON files into your Grafana instance — no custom plugin required.

---

## 📊 Dashboard Overview

All dashboard JSON files are in `monitoring/grafana/dashboards/`:

| Dashboard | File | Panels | Focus |
|---|---|---|---|
| **Runner Overview** | `runner-overview.json` | 12 | Runner status, health, uptime, queue time |
| **DORA Metrics** | `dora-metrics.json` | 12 | Deployment Frequency, Lead Time, CFR, MTTR |
| **Performance Trends** | `performance-trends.json` | 14 | Cache hit rates, build duration percentiles, queue times |
| **Job Analysis** | `job-analysis.json` | 16 | Job summary, duration histograms, status breakdown |

**Total:** 54 panels across 4 dashboards.

---

## 🚀 Importing Dashboards

### Option 1: Manual Import (Recommended for Quick Start)

1. Open Grafana → **Dashboards → Import**.
2. Click **Upload JSON file**.
3. Select a dashboard file from `monitoring/grafana/dashboards/`.
4. Select your **Prometheus datasource** when prompted.
5. Click **Import**.
6. Repeat for each dashboard.

### Option 2: Provisioning (Recommended for Production)

Use the included provisioning configuration to auto-load dashboards on Grafana startup.

```yaml
# monitoring/grafana/provisioning/dashboards/dashboards.yml
apiVersion: 1

providers:
  - name: "github-runner"
    orgId: 1
    folder: "GitHub Runner"
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /etc/grafana/provisioning/dashboards
      foldersFromFilesStructure: false
```

Mount the dashboards directory into your Grafana container:

```yaml
# In your Grafana docker-compose service
volumes:
  - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
  - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards:ro
```

Dashboards will appear automatically in the **GitHub Runner** folder on startup.

---

## ⚙️ Dashboard Variables

All dashboards include these template variables for filtering:

| Variable | Type | Description |
|---|---|---|
| `runner_name` | Multi-select | Filter by runner instance name |
| `runner_type` | Multi-select | Filter by runner type (`standard`, `chrome`, `chrome-go`) |

Variables are populated from live Prometheus label data, so new runners appear automatically.

---

## 📋 Dashboard Details

### Runner Overview

The primary operational dashboard. Shows:

- **Runner Status** — Online/offline indicator per runner
- **Fleet Size** — Total active runners
- **Uptime** — Current uptime per runner
- **Job Success Rate** — Percentage gauge
- **Queue Time** — Average time jobs wait before starting
- **Jobs Over Time** — Time series of job throughput
- **Quick Links** — Navigation to other dashboards

### DORA Metrics

Tracks the four DORA key metrics as calculated from runner data:

- **Deployment Frequency** — Successful jobs per day
- **Lead Time for Changes** — Average job duration (proxy)
- **Change Failure Rate** — Failed jobs / total jobs (%)
- **Mean Time to Recovery** — Time between failure and next success
- **Trend Lines** — 7-day rolling averages
- **Classification** — Elite / High / Medium / Low performance bands

### Performance Trends

Resource utilization and build performance over time:

- **Build Duration Percentiles** — p50, p90, p99
- **Cache Hit Rates** — BuildKit, APT, npm (currently stubbed)
- **Queue Time Trends** — Historical queue wait times
- **Runner Comparison** — Side-by-side performance across runner types

### Job Analysis

Deep dive into individual job metrics:

- **Job Summary** — Total, successful, failed counts
- **Duration Histograms** — Distribution of job execution times
- **Status Breakdown** — Pie/bar charts by status
- **Runner Comparison** — Which runners handle more/faster jobs
- **Duration by Runner Type** — Compare standard vs chrome vs chrome-go

---

## 🔧 Datasource Configuration

Dashboards use the `${DS_PROMETHEUS}` input variable for datasource portability. During import, Grafana will prompt you to map this to your Prometheus datasource.

### Adding a Prometheus Datasource

If you haven't configured one yet:

1. Go to **Configuration → Data Sources → Add data source**.
2. Select **Prometheus**.
3. Set the URL to your Prometheus server (e.g., `http://prometheus:9090`).
4. Click **Save & Test** to verify connectivity.

---

## 🔗 Inter-Dashboard Navigation

Each dashboard includes navigation links to the other dashboards. The **Runner Overview** dashboard has a **Quick Links** panel for easy cross-dashboard navigation.

---

## 📊 What's Next?

| Guide | Description |
|---|---|
| [Monitoring Setup](Monitoring-Setup.md) | Deploy runners and connect Prometheus |
| [Metrics Reference](Metrics-Reference.md) | All 8 metrics with PromQL examples |
| [Monitoring Troubleshooting](Monitoring-Troubleshooting.md) | Fix "No Data" and other dashboard issues |

> 📖 **Full dashboard documentation:** See [GRAFANA_DASHBOARD_METRICS.md](../docs/features/GRAFANA_DASHBOARD_METRICS.md) and [PROMETHEUS_USAGE.md](../docs/features/PROMETHEUS_USAGE.md) in the main docs for PromQL query recipes, alert rule examples, and dashboard customization.
