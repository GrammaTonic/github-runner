# Prometheus Monitoring Architecture

## Status: ✅ Complete

**Created:** 2026-03-02
**Phase:** 5 — Documentation & User Guide
**Task:** TASK-050

---

## Overview

This document describes the internal architecture of the Prometheus monitoring system for GitHub Actions self-hosted runners. The system uses a pure-bash implementation (no external language runtimes) with netcat for HTTP serving.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Runner Container                                 │
│                                                                          │
│  ┌─────────────────┐    ┌──────────────────┐    ┌───────────────────┐   │
│  │  GitHub Actions  │    │  metrics-         │    │  metrics-         │   │
│  │  Runner Binary   │    │  collector.sh     │    │  server.sh        │   │
│  │                  │    │  (background)     │    │  (background)     │   │
│  │  Executes jobs   │    │  Updates every    │    │  Listens on       │   │
│  │                  │    │  30 seconds       │    │  port 9091        │   │
│  └──────┬───────────┘    └──────┬───────────┘    └──────┬───────────┘   │
│         │                       │                        │               │
│         │  Hook scripts         │  Reads + Writes        │  Reads        │
│         │                       │                        │               │
│         ▼                       ▼                        ▼               │
│  ┌──────────────┐    ┌──────────────────┐    ┌───────────────────────┐  │
│  │  job-started  │    │  /tmp/            │    │  HTTP Response        │  │
│  │  .sh          │    │  runner_metrics   │    │  (Prometheus text)    │  │
│  │              │    │  .prom            │    │                       │  │
│  │  job-         │    │                  │    │  GET /metrics         │  │
│  │  completed.sh │    │  (atomic writes)  │    │  → 200 OK            │  │
│  └──────┬───────┘    └──────────────────┘    └──────────┬───────────┘  │
│         │                       ▲                        │               │
│         │  Appends              │  Reads                 │               │
│         ▼                       │                        │               │
│  ┌──────────────┐               │                        │               │
│  │  /tmp/        │───────────────┘                        │               │
│  │  jobs.log    │                                        │               │
│  │  (CSV)       │                                        │               │
│  └──────────────┘                                        │               │
│                                                          │               │
│  Port 9091 ◄─────────────────────────────────────────────┘               │
└──────────────────────────────────────────────────────────────────────────┘
         │
         │  Prometheus scrapes :9091/metrics
         ▼
┌────────────────────┐          ┌────────────────────┐
│  Prometheus Server  │─────────▶│  Grafana            │
│  (User-Provided)    │  queries │  (User-Provided)    │
│                     │          │                     │
│  Stores time-series │          │  4 Pre-built        │
│  data               │          │  Dashboards         │
└────────────────────┘          └────────────────────┘
```

---

## Component Descriptions

### 1. Metrics Server (`docker/metrics-server.sh`)

**Purpose:** Lightweight HTTP server that responds to Prometheus scrape requests.

**Implementation:**

- Uses `netcat` (`nc`) to listen on a TCP port (default: 9091).
- On each incoming request, reads `/tmp/runner_metrics.prom` and returns it with HTTP 200-series headers.
- Returns HTTP 503 if the metrics file is missing.
- Runs as a background process, started by the entrypoint script.

**Key characteristics:**

- Single-threaded (handles one request at a time).
- Stateless — reads the metrics file on every request.
- No request routing — all paths return the same metrics.
- Content-Type: `text/plain; version=0.0.4; charset=utf-8` (Prometheus text format).

**Configuration:**

| Variable | Default | Description |
|---|---|---|
| `METRICS_PORT` | `9091` | TCP port to listen on |
| `METRICS_FILE` | `/tmp/runner_metrics.prom` | Path to metrics file |

### 2. Metrics Collector (`docker/metrics-collector.sh`)

**Purpose:** Periodically reads system state and job logs to generate Prometheus-formatted metrics.

**Implementation:**

- Runs in an infinite loop with a configurable sleep interval (default: 30s).
- Reads job data from `/tmp/jobs.log` (CSV format).
- Computes counters, gauges, and histogram buckets.
- Writes metrics atomically to `/tmp/runner_metrics.prom` (write temp → `mv`).

**Metrics generated:**

| Metric | Type | Source |
|---|---|---|
| `github_runner_status` | gauge | Always 1 while collector runs |
| `github_runner_info` | gauge | Environment variables |
| `github_runner_uptime_seconds` | counter | `$(date +%s) - $START_TIME` |
| `github_runner_jobs_total` | counter | Parsed from `jobs.log` |
| `github_runner_job_duration_seconds` | histogram | Computed from `jobs.log` durations |
| `github_runner_queue_time_seconds` | gauge | Averaged from `jobs.log` queue times |
| `github_runner_cache_hit_rate` | gauge | Stubbed (returns 0) |
| `github_runner_last_update_timestamp` | gauge | `$(date +%s)` at write time |

**Configuration:**

| Variable | Default | Description |
|---|---|---|
| `METRICS_FILE` | `/tmp/runner_metrics.prom` | Output path |
| `JOBS_LOG` | `/tmp/jobs.log` | Job log input path |
| `UPDATE_INTERVAL` | `30` | Seconds between updates |
| `RUNNER_NAME` | `unknown` | Runner name label |
| `RUNNER_TYPE` | `standard` | Runner type label |
| `RUNNER_VERSION` | `2.332.0` | Runner version label |

### 3. Job Hook Scripts (`docker/job-started.sh`, `docker/job-completed.sh`)

**Purpose:** Record job lifecycle events to the jobs log for metrics collection.

**Implementation:**

- Invoked by the GitHub Actions runner binary via environment variables:
  - `ACTIONS_RUNNER_HOOK_JOB_STARTED` → `job-started.sh`
  - `ACTIONS_RUNNER_HOOK_JOB_COMPLETED` → `job-completed.sh`
- `job-started.sh` records a `running` entry and saves the start timestamp to a state file.
- `job-completed.sh` calculates duration, determines status, and writes the final log entry.

**Job Log Format** (`/tmp/jobs.log`):

```
timestamp,job_id,status,duration_seconds,queue_time_seconds
```

Example:

```
2026-03-02T10:00:00Z,12345_build,running,0,0
2026-03-02T10:05:30Z,12345_build,success,330,12
```

**Job state directory:** `/tmp/job_state/` stores per-job start timestamps for duration calculation.

### 4. Entrypoint Scripts (`docker/entrypoint.sh`, `docker/entrypoint-chrome.sh`)

**Purpose:** Container initialization that starts the metrics system alongside the runner.

**Startup sequence:**

1. Configure and register the GitHub Actions runner.
2. Initialize `/tmp/jobs.log` (touch).
3. Copy hook scripts to the runner directory.
4. Set `ACTIONS_RUNNER_HOOK_JOB_STARTED` and `ACTIONS_RUNNER_HOOK_JOB_COMPLETED`.
5. Start `metrics-server.sh` in background.
6. Start `metrics-collector.sh` in background.
7. Start the GitHub Actions runner (foreground).

---

## Data Flow

```
Job Execution → job-started.sh → /tmp/jobs.log (append "running" entry)
                                 /tmp/job_state/<id>.start (timestamp)

Job Completion → job-completed.sh → /tmp/jobs.log (append final entry)
                                    /tmp/job_state/<id>.start (delete)

Every 30s → metrics-collector.sh → reads /tmp/jobs.log
                                  → computes counters, histogram, queue time
                                  → writes /tmp/runner_metrics.prom (atomic)

On scrape → metrics-server.sh → reads /tmp/runner_metrics.prom
                               → returns HTTP 200 with Prometheus text

Prometheus → scrapes :9091/metrics → stores time-series data

Grafana → queries Prometheus → renders dashboards
```

---

## Design Decisions

### Decision: Bash + Netcat (CON-001, CON-002)

**Rationale:** The project constrains implementation to bash scripting with no additional language runtimes. Netcat is available in the base image (`ubuntu:resolute`) and is sufficient for serving simple HTTP responses. This avoids adding Python, Node.js, or Go dependencies to the runner image.

**Trade-offs:**

- (+) Zero additional dependencies.
- (+) Minimal image size impact.
- (+) Simple to debug and modify.
- (-) Single-threaded HTTP server (one request at a time).
- (-) No request routing (all paths return metrics).
- (-) Limited HTTP compliance (HTTP/1.0 only).

**Review:** If scrape concurrency becomes an issue, consider `socat` (multi-connection) or a lightweight Go binary.

### Decision: File-Based Metrics Transfer

**Rationale:** The collector writes metrics to a file; the server reads the file. This decouples the two processes and allows atomic updates via `mv`. No shared memory or IPC required.

**Trade-offs:**

- (+) Simple, robust, no race conditions (atomic `mv`).
- (+) Easy to debug (`cat /tmp/runner_metrics.prom`).
- (-) Slight latency (up to 30s stale data between updates).
- (-) Disk I/O on each update (minimal — file is < 2KB).

### Decision: CSV Job Log Format

**Rationale:** A simple CSV format (`timestamp,job_id,status,duration,queue_time`) is easy to parse with standard shell tools (`grep`, `awk`, `read`). No external parsers needed.

**Trade-offs:**

- (+) Human-readable and inspectable.
- (+) Easy to parse with bash built-ins.
- (-) No schema enforcement.
- (-) Unbounded growth (mitigated by reading only recent entries for queue time).

### Decision: Stub Cache Metrics

**Rationale:** BuildKit cache logs reside on the Docker host, not inside the runner container. APT and npm caches are internal to builds. Real cache hit rate data is not accessible from within the runner.

**Trade-offs:**

- (+) Metrics schema is future-proof (cache_type label ready).
- (+) Dashboards already have cache panels.
- (-) Currently returns 0 for all cache types.

**Future:** A sidecar exporter running on the Docker host could parse BuildKit logs and expose real cache metrics.

---

## Multi-Runner Deployment

When running multiple runner types simultaneously:

```
                    Docker Host
┌──────────────────────────────────────────────┐
│                                              │
│  ┌──────────────┐  Host Port 9091            │
│  │  Standard    │──────────────────┐         │
│  │  Runner      │  Container: 9091 │         │
│  └──────────────┘                  │         │
│                                    ▼         │
│  ┌──────────────┐  Host Port 9092  ┌───────┐ │
│  │  Chrome      │─────────────────▶│ Prom  │ │
│  │  Runner      │  Container: 9091 │ etheus│ │
│  └──────────────┘                  └───────┘ │
│                                    ▲         │
│  ┌──────────────┐  Host Port 9093  │         │
│  │  Chrome-Go   │──────────────────┘         │
│  │  Runner      │  Container: 9091           │
│  └──────────────┘                            │
│                                              │
└──────────────────────────────────────────────┘
```

Each runner type:

- Listens on container port **9091** internally.
- Maps to a unique **host port** (9091, 9092, 9093).
- Has unique `runner_name` and `runner_type` labels.
- Maintains its own `/tmp/jobs.log` and metrics files.

---

## Scalability Considerations

| Factor | Current Limit | Mitigation |
|---|---|---|
| Scrape concurrency | 1 request at a time (netcat) | Prometheus retries; 15s scrape interval > response time |
| Jobs log size | Unbounded growth | Queue time reads last 100 entries; restart resets log |
| Metrics file size | ~2 KB per runner | Negligible disk impact |
| CPU overhead | < 1% (bash + sleep loop) | Configurable `UPDATE_INTERVAL` |
| Memory overhead | < 10 MB per runner | Bash processes, no JVM/runtime |
| Number of runners | Unlimited (unique ports) | Network port planning required |

For large deployments (100+ runners), consider:

- Service discovery in Prometheus (file-based or DNS-based) instead of static targets.
- A metrics aggregation proxy to reduce Prometheus scrape load.
- Log rotation for `/tmp/jobs.log` to prevent disk exhaustion.

---

## File Inventory

| File | Purpose | Started By |
|---|---|---|
| `docker/metrics-server.sh` | HTTP server for `/metrics` | Entrypoint script |
| `docker/metrics-collector.sh` | Periodic metrics generation | Entrypoint script |
| `docker/job-started.sh` | Job start hook | Runner binary |
| `docker/job-completed.sh` | Job completion hook | Runner binary |
| `docker/entrypoint.sh` | Standard runner init | Docker CMD |
| `docker/entrypoint-chrome.sh` | Chrome/Chrome-Go runner init | Docker CMD |
| `monitoring/prometheus.yml` | Full Prometheus config example | User deploys |
| `monitoring/prometheus-scrape-example.yml` | Minimal scrape config | User references |
| `monitoring/grafana/dashboards/*.json` | 4 Grafana dashboards | User imports |
| `monitoring/grafana/provisioning/dashboards/dashboards.yml` | Auto-load config | Grafana |

---

## Next Steps

- [Setup Guide](PROMETHEUS_SETUP.md) — Deploy and configure
- [Usage Guide](PROMETHEUS_USAGE.md) — PromQL queries and dashboards
- [Metrics Reference](PROMETHEUS_METRICS_REFERENCE.md) — Full metric catalog
- [Troubleshooting](PROMETHEUS_TROUBLESHOOTING.md) — Fix common issues
