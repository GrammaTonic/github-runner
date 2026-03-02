# Monitoring Troubleshooting

![Troubleshooting](https://img.shields.io/badge/Troubleshooting-Monitoring-red?style=for-the-badge)

Common monitoring issues and their solutions. Problems are organized by symptom — find yours and follow the fix.

---

## 🔍 Quick Diagnostic Commands

Run these first to gather information:

```bash
# Container status
docker ps --filter "name=github-runner" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Metrics endpoint health
curl -s -o /dev/null -w "%{http_code}" http://localhost:9091/metrics

# Container logs (last 50 lines)
docker logs --tail 50 <container-name>

# Metrics collector log
docker exec <container-name> cat /tmp/metrics-collector.log

# Metrics server log
docker exec <container-name> cat /tmp/metrics-server.log

# Metrics file size
docker exec <container-name> wc -l /tmp/runner_metrics.prom

# Running processes
docker exec <container-name> ps aux | grep -E "metrics|nc"
```

---

## ❌ Metrics Endpoint Not Responding

**Symptom:** `curl http://localhost:9091/metrics` returns "Connection refused" or times out.

### Check 1: Container Running?

```bash
docker ps | grep github-runner
```

**Fix:** Start the container:

```bash
docker compose -f docker/docker-compose.production.yml up -d
```

### Check 2: Port Mapped Correctly?

```bash
docker port <container-name>
```

Expected port mappings:

| Runner | Host Port | Container Port |
|---|---|---|
| Standard | `9091` | `9091` |
| Chrome | `9092` | `9091` |
| Chrome-Go | `9093` | `9091` |

### Check 3: Metrics Server Running?

```bash
docker exec <container-name> ps aux | grep metrics-server
```

**Fix:** Restart the container if the server is not running:

```bash
docker compose -f docker/docker-compose.production.yml restart
```

### Check 4: Port Conflict?

```bash
lsof -i :9091
# or
ss -tlnp | grep 9091
```

**Fix:** Change the host port in the compose file or stop the conflicting process.

---

## ⏸️ Metrics Not Updating

**Symptom:** `github_runner_uptime_seconds` or `github_runner_last_update_timestamp` does not change between requests.

### Check 1: Collector Running?

```bash
docker exec <container-name> ps aux | grep metrics-collector
```

**Fix:** Check the collector log for errors:

```bash
docker exec <container-name> cat /tmp/metrics-collector.log
```

Restart the container if the collector has crashed.

### Check 2: Disk Space?

```bash
docker exec <container-name> df -h /tmp
```

The metrics file needs `/tmp` to be writable.

### Check 3: Update Interval

The default update interval is **30 seconds**. Wait at least 30 seconds between checks.

```bash
# Watch metrics update in real time
watch -n 5 'curl -s http://localhost:9091/metrics | grep uptime'
```

**Reduce interval** via environment variable:

```yaml
environment:
  METRICS_UPDATE_INTERVAL: "15"
```

---

## 📊 Grafana Dashboard Shows "No Data"

**Symptom:** Dashboard panels display "No data" or are empty.

### Check 1: Prometheus Datasource Configured?

In Grafana → **Configuration → Data Sources** → verify a Prometheus datasource exists → click **Save & Test**.

### Check 2: Prometheus Scraping Runners?

Open `http://<prometheus-host>:9090/targets` and look for `github-runner-*` jobs. Targets should show state `UP`.

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

### Check 3: Datasource Name Mismatch?

Dashboards use `${DS_PROMETHEUS}` as a datasource input variable. During import, you must select your Prometheus datasource.

**Fix:** Re-import the dashboard and select the correct datasource.

### Check 4: Time Range Too Narrow?

If the runner was just deployed, there may not be enough data.

**Fix:** Set the dashboard time range to **Last 15 minutes** or **Last 1 hour**.

### Check 5: No Jobs Executed Yet?

Job metrics (`github_runner_jobs_total`, `github_runner_job_duration_seconds`) only populate after jobs run. Runner status panels update immediately.

**Fix:** Trigger a test workflow in your repository.

---

## 🔻 Prometheus Target Shows DOWN

**Symptom:** Prometheus targets page shows the runner target with state `DOWN`.

### Check 1: Network Connectivity

```bash
# From the Prometheus host, test connectivity
curl http://<runner-host>:9091/metrics
```

**Fix for Docker networks:** Put Prometheus and runners on the same Docker network:

```yaml
networks:
  monitoring:
    external: true
```

### Check 2: Firewall

```bash
nc -zv <runner-host> 9091
```

**Fix:** Open port 9091 in your firewall rules.

### Check 3: Scrape Timeout

```bash
time curl -s http://localhost:9091/metrics > /dev/null
```

**Fix:** If response is slow, increase the scrape timeout:

```yaml
- job_name: "github-runner-standard"
  scrape_timeout: 15s
```

---

## 🔢 Job Counts Not Incrementing

**Symptom:** `github_runner_jobs_total` stays at 0 despite running jobs.

### Check 1: Job Hooks Configured?

```bash
docker exec <container-name> env | grep ACTIONS_RUNNER_HOOK
```

Expected:

```
ACTIONS_RUNNER_HOOK_JOB_STARTED=/home/runner/job-started.sh
ACTIONS_RUNNER_HOOK_JOB_COMPLETED=/home/runner/job-completed.sh
```

These are set by the entrypoint scripts automatically.

### Check 2: Jobs Log Exists?

```bash
docker exec <container-name> ls -la /tmp/jobs.log
docker exec <container-name> cat /tmp/jobs.log
```

### Check 3: Hook Scripts Executable?

```bash
docker exec <container-name> ls -la /home/runner/job-started.sh /home/runner/job-completed.sh
```

Scripts should have execute permission (set during Docker build).

---

## 📈 High Resource Usage

**Symptom:** Runner container using more resources than expected.

```bash
docker stats <container-name> --no-stream
docker exec <container-name> ps aux --sort=-%mem | head -10
```

### Fix: Reduce Scrape Frequency

```yaml
environment:
  METRICS_UPDATE_INTERVAL: "60"  # Reduce from 30s default
```

### Fix: Check Jobs Log Growth

```bash
docker exec <container-name> wc -l /tmp/jobs.log
```

For very long-running containers with thousands of log entries, restart to reset the log.

### Fix: Set Resource Limits

```yaml
deploy:
  resources:
    limits:
      cpus: "2.0"
      memory: 2G
```

---

## 0️⃣ Cache Metrics Always Zero

**Symptom:** `github_runner_cache_hit_rate` reports 0 for all cache types.

**This is expected.** Cache metrics are currently **stubbed** — they always return 0. BuildKit cache logs exist on the Docker host (not inside the runner container), and APT/npm caches are internal to build processes.

Future work will add a sidecar exporter for real cache data. See [Metrics Reference](Metrics-Reference.md) for details.

---

## 📋 Collecting Diagnostic Info

If you need to file a bug report, gather this information:

```bash
# Container info
docker inspect <container-name> | head -100

# Metrics output
curl -s http://localhost:9091/metrics > metrics-dump.txt

# Container logs
docker logs <container-name> > container-logs.txt 2>&1

# Collector log
docker exec <container-name> cat /tmp/metrics-collector.log > collector-log.txt

# Server log
docker exec <container-name> cat /tmp/metrics-server.log > server-log.txt

# Jobs log
docker exec <container-name> cat /tmp/jobs.log > jobs-log.txt

# Environment
docker exec <container-name> env | grep -E "RUNNER|METRICS|JOBS" > env.txt
```

---

## 📊 What's Next?

| Guide | Description |
|---|---|
| [Monitoring Setup](Monitoring-Setup.md) | Initial configuration and deployment |
| [Metrics Reference](Metrics-Reference.md) | All 8 metrics with types and PromQL |
| [Grafana Dashboards](Grafana-Dashboards.md) | Dashboard import and customization |

> 📖 **Full troubleshooting guide:** See [PROMETHEUS_TROUBLESHOOTING.md](../docs/features/PROMETHEUS_TROUBLESHOOTING.md) in the main docs.
