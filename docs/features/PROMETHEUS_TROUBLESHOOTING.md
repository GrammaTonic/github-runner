# Prometheus Monitoring Troubleshooting Guide

## Status: ✅ Complete

**Created:** 2026-03-02
**Phase:** 5 — Documentation & User Guide
**Task:** TASK-049

---

## Overview

This guide covers common issues with the Prometheus monitoring system for GitHub Actions self-hosted runners and how to resolve them. Problems are organized by symptom.

---

## Quick Diagnostic Commands

Run these first to gather information:

```bash
# Check container status
docker ps --filter "name=github-runner" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check metrics endpoint
curl -s -o /dev/null -w "%{http_code}" http://localhost:9091/metrics

# View container logs (last 50 lines)
docker logs --tail 50 <container-name>

# Check metrics collector log
docker exec <container-name> cat /tmp/metrics-collector.log

# Check metrics server log
docker exec <container-name> cat /tmp/metrics-server.log

# Check if metrics file exists and has content
docker exec <container-name> wc -l /tmp/runner_metrics.prom

# Check running processes inside container
docker exec <container-name> ps aux | grep -E "metrics|nc"
```

---

## Problem: Metrics Endpoint Not Responding

### Symptom

`curl http://localhost:9091/metrics` returns "Connection refused" or times out.

### Possible Causes and Fixes

#### 1. Container Not Running

```bash
docker ps | grep github-runner
```

**Fix:** Start the container:

```bash
docker compose -f docker/docker-compose.production.yml up -d
```

#### 2. Port Not Mapped

```bash
docker port <container-name>
```

**Fix:** Verify the compose file has the correct port mapping:

```yaml
ports:
  - "9091:9091"  # Standard runner
  - "9092:9091"  # Chrome runner
  - "9093:9091"  # Chrome-Go runner
```

#### 3. Metrics Server Not Started

```bash
docker exec <container-name> ps aux | grep metrics-server
```

**Fix:** The metrics server is launched by the entrypoint script. Check logs:

```bash
docker logs <container-name> 2>&1 | grep -i "metrics"
```

If the server is not running, restart the container:

```bash
docker compose -f docker/docker-compose.production.yml restart
```

#### 4. Port Conflict

Another service may be using port 9091 on the host.

```bash
lsof -i :9091
# or
ss -tlnp | grep 9091
```

**Fix:** Change the host port in the compose file:

```yaml
ports:
  - "9094:9091"  # Use alternate host port
```

#### 5. Netcat Not Available

```bash
docker exec <container-name> which nc
```

**Fix:** Netcat (`nc`) should be included in the base image. If missing, rebuild the image.

---

## Problem: Metrics Not Updating

### Symptom

`github_runner_uptime_seconds` or `github_runner_last_update_timestamp` does not change between requests.

### Possible Causes and Fixes

#### 1. Collector Script Not Running

```bash
docker exec <container-name> ps aux | grep metrics-collector
```

**Fix:** Check the collector log for errors:

```bash
docker exec <container-name> cat /tmp/metrics-collector.log
```

Restart the container if the collector crashed:

```bash
docker restart <container-name>
```

#### 2. Metrics File Not Writable

```bash
docker exec <container-name> ls -la /tmp/runner_metrics.prom
```

**Fix:** Ensure `/tmp` is writable (it should be by default). Check disk space:

```bash
docker exec <container-name> df -h /tmp
```

#### 3. Update Interval Too Long

The default update interval is 30 seconds. Wait at least 30 seconds between checks.

```bash
# Watch metrics update in real time
watch -n 5 'curl -s http://localhost:9091/metrics | grep uptime'
```

**Fix:** Reduce the interval via environment variable:

```yaml
environment:
  METRICS_UPDATE_INTERVAL: "15"  # Update every 15 seconds
```

---

## Problem: Grafana Dashboard Shows "No Data"

### Symptom

Dashboard panels display "No data" or are empty.

### Possible Causes and Fixes

#### 1. Prometheus Datasource Not Configured

In Grafana:

1. Go to **Configuration → Data Sources**.
2. Verify a Prometheus datasource exists.
3. Click **Save & Test** to confirm connectivity.

#### 2. Prometheus Not Scraping Runners

Check Prometheus targets:

1. Open `http://<prometheus-host>:9090/targets`.
2. Look for `github-runner-*` jobs.
3. Targets should show state `UP`.

**Fix:** Add runner targets to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: "github-runner-standard"
    static_configs:
      - targets: ["<runner-host>:9091"]
```

Reload Prometheus:

```bash
curl -X POST http://localhost:9090/-/reload
```

#### 3. Datasource Name Mismatch

The dashboards use `${DS_PROMETHEUS}` as a datasource input variable. During import, you must select your Prometheus datasource.

**Fix:** Re-import the dashboard and select the correct datasource at the import prompt.

#### 4. Time Range Too Narrow

If the runner was just deployed, there may not be enough data for the selected time range.

**Fix:** Set the dashboard time range to "Last 15 minutes" or "Last 1 hour".

#### 5. No Jobs Executed Yet

Job metrics (`github_runner_jobs_total`, `github_runner_job_duration_seconds`) only populate after jobs run.

**Fix:** Trigger a test workflow in your repository, or check panels that show runner status (which updates immediately).

---

## Problem: Prometheus Target Shows DOWN

### Symptom

Prometheus targets page shows the runner target with state `DOWN` and an error message.

### Possible Causes and Fixes

#### 1. Network Connectivity

Prometheus cannot reach the runner on the configured port.

```bash
# From the Prometheus host/container, test connectivity
curl http://<runner-host>:9091/metrics
```

**Fix for Docker networks:** Put Prometheus and runners on the same Docker network:

```yaml
# In your Prometheus docker-compose
networks:
  monitoring:
    external: true

# In runner docker-compose, add:
networks:
  monitoring:
    external: true
```

#### 2. Firewall Blocking

```bash
# Check if port is open
nc -zv <runner-host> 9091
```

**Fix:** Open port 9091 in your firewall rules.

#### 3. Scrape Timeout

The metrics endpoint must respond within the `scrape_timeout` (default 10s).

```bash
# Measure response time
time curl -s http://localhost:9091/metrics > /dev/null
```

**Fix:** If response is slow, increase the scrape timeout:

```yaml
- job_name: "github-runner-standard"
  scrape_timeout: 15s
```

---

## Problem: Job Counts Not Incrementing

### Symptom

`github_runner_jobs_total` stays at 0 despite running jobs.

### Possible Causes and Fixes

#### 1. Job Hooks Not Configured

The runner must have job hooks set via environment variables.

```bash
docker exec <container-name> env | grep ACTIONS_RUNNER_HOOK
```

Expected output:

```
ACTIONS_RUNNER_HOOK_JOB_STARTED=/home/runner/job-started.sh
ACTIONS_RUNNER_HOOK_JOB_COMPLETED=/home/runner/job-completed.sh
```

**Fix:** These are configured in the entrypoint scripts. Verify the entrypoint script sets them:

```bash
docker exec <container-name> cat /home/runner/entrypoint.sh | grep HOOK
```

#### 2. Jobs Log Not Writable

```bash
docker exec <container-name> ls -la /tmp/jobs.log
docker exec <container-name> cat /tmp/jobs.log
```

**Fix:** Ensure `/tmp/jobs.log` exists and is writable.

#### 3. Hook Scripts Not Executable

```bash
docker exec <container-name> ls -la /home/runner/job-started.sh /home/runner/job-completed.sh
```

**Fix:** Scripts should have execute permission. This is set during the Docker build.

---

## Problem: High Memory or CPU Usage

### Symptom

Runner container using more resources than expected.

### Diagnostic

```bash
# Check resource usage
docker stats <container-name> --no-stream

# Check metrics processes specifically
docker exec <container-name> ps aux --sort=-%mem | head -10
```

### Fixes

#### Reduce Scrape Frequency

```yaml
environment:
  METRICS_UPDATE_INTERVAL: "60"  # Reduce from 30s to 60s
```

#### Check Jobs Log Growth

```bash
docker exec <container-name> wc -l /tmp/jobs.log
```

If the log has thousands of entries, the histogram calculation may be slow.

**Fix:** The collector processes recent entries (last 100 for queue time). For very long-running containers, consider restarting to reset the log.

#### Resource Limits

Set container resource limits in the compose file:

```yaml
deploy:
  resources:
    limits:
      cpus: "2.0"
      memory: 2G
```

---

## Problem: Cache Metrics Always Zero

### Symptom

`github_runner_cache_hit_rate` reports 0 for all cache types.

### Explanation

Cache metrics are currently **stubbed** — they always return 0. This is by design:

- BuildKit cache logs exist on the Docker host, not inside the runner container.
- APT and npm caches are internal to the build process and not easily instrumented from the runner.

See [PROMETHEUS_METRICS_REFERENCE.md](PROMETHEUS_METRICS_REFERENCE.md) for details.

**Future work:** A sidecar container or host-side exporter could provide real cache metrics.

---

## Collecting Diagnostic Information

If you need to file a bug report, gather this information:

```bash
# 1. Container info
docker inspect <container-name> | head -100

# 2. Metrics output
curl -s http://localhost:9091/metrics > metrics-dump.txt

# 3. Container logs
docker logs <container-name> > container-logs.txt 2>&1

# 4. Collector log
docker exec <container-name> cat /tmp/metrics-collector.log > collector-log.txt

# 5. Server log
docker exec <container-name> cat /tmp/metrics-server.log > server-log.txt

# 6. Jobs log
docker exec <container-name> cat /tmp/jobs.log > jobs-log.txt

# 7. Process list
docker exec <container-name> ps aux > processes.txt

# 8. Environment
docker exec <container-name> env | grep -E "RUNNER|METRICS|JOBS" > env.txt
```

---

## Next Steps

- [Setup Guide](PROMETHEUS_SETUP.md) — Initial configuration
- [Usage Guide](PROMETHEUS_USAGE.md) — PromQL queries and dashboards
- [Architecture](PROMETHEUS_ARCHITECTURE.md) — System internals
- [Metrics Reference](PROMETHEUS_METRICS_REFERENCE.md) — Full metric definitions
