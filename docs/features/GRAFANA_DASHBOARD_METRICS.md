# Grafana Dashboard & Metrics Endpoint Feature

## Status: 🚧 In Development

**Created:** 2025-11-16  
**Feature Branch:** `feature/prometheus-improvements`  
**Target Release:** v2.3.0  
**Scope:** Metrics Endpoint + Grafana Dashboard ONLY

---

## 📋 Executive Summary

Implement a lightweight custom metrics endpoint on each GitHub Actions runner (port 9091) and a pre-built Grafana dashboard for visualization. This implementation assumes users have their own Prometheus and Grafana infrastructure and focuses solely on runner-specific application metrics.

**What's Included:**
- ✅ Custom metrics HTTP endpoint (port 9091) on all runners
- ✅ Grafana dashboard JSON for import
- ✅ Example Prometheus scrape configuration
- ✅ Documentation for integration

**What's NOT Included (User Responsibility):**
- ❌ Prometheus server deployment
- ❌ Grafana server deployment
- ❌ System metrics (CPU, memory, disk) - use Node Exporter
- ❌ Container metrics - use cAdvisor
- ❌ Alert configuration - use Prometheus Alertmanager

---

## 🎯 Objectives

### Primary Goals
1. **Metrics Endpoint**: Expose runner-specific metrics using Go Prometheus client on port 9091
2. **Grafana Dashboard**: Pre-built dashboard showing runner health, jobs, and DORA metrics
3. **Production-Grade**: Official Prometheus client library for reliability and performance
4. **Easy Integration**: Drop-in compatibility with existing Prometheus/Grafana

### Success Criteria
- [ ] Metrics endpoint running on all runner types (standard, Chrome, Chrome-Go)
- [ ] Grafana dashboard JSON ready for import
- [ ] Example Prometheus scrape config documented
- [ ] <1% performance overhead validated
- [ ] Documentation complete

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│              Metrics Endpoint & Dashboard                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  User's Prometheus Server            User's Grafana Instance     │
│  (External - User Provided)           (External - User Provided) │
│         │                                      ▲                  │
│         │ scrapes :9091/metrics                │                  │
│         │                                      │ queries          │
│         ▼                                      │ Prometheus       │
│  ┌──────────────┐      ┌──────────────┐      │                  │
│  │   Runner 1   │      │   Runner 2   │      │                  │
│  │  (standard)  │      │   (chrome)   │      │                  │
│  │              │      │              │      │                  │
│  │ Port 9091 ───┼──────┼─ Port 9091 ──┼──────┘                  │
│  │ /metrics     │      │  /metrics    │                          │
│  └──────┬───────┘      └──────┬───────┘                          │
│         │                      │                                  │
│  ┌──────┴──────────────────────┴──────┐                          │
│  │  Go Metrics Exporter (This Proj)   │      Grafana Dashboard  │
│  │  - Prometheus client library        │      (JSON - This Proj) │
│  │  - Real-time metric updates         │            │            │
│  │  - Prometheus text format           │            │            │
│  │  - Histograms & counters            │            │            │
│  └─────────────────────────────────────┘            ▼            │
│                                          ┌───────────────────────┐│
│                                          │  Dashboard Panels:    ││
│                                          │  - Runner Status      ││
│                                          │  - Jobs & Success Rate││
│                                          │  - DORA Metrics       ││
│                                          │  - Performance Trends ││
│                                          └───────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### Components

#### 1. Custom Metrics Endpoint (Port 9091) - **We Provide**
- **Implementation**: Lightweight bash script using netcat for HTTP server
- **HTTP Server**: netcat (nc) listening on port 9091
- **Metrics Generation**: Bash script generating Prometheus text format
- **Format**: Prometheus text format (OpenMetrics compatible)
- **Update Frequency**: 30 seconds (metrics collector updates periodically)
- **Location**: Bash scripts started by `entrypoint.sh` and `entrypoint-chrome.sh`
- **Metrics**: Runner status, job counts, uptime, cache hit rates, job duration

#### 2. Grafana Dashboard JSON - **We Provide**
- **File**: `monitoring/grafana/dashboards/github-runner-dashboard.json`
- **Panels**: 12 panels covering all key metrics
- **Variables**: Filter by runner_name, runner_type
- **Import**: Users import JSON into their Grafana instance

#### 3. Example Prometheus Config - **We Provide Documentation**
- **File**: `docs/PROMETHEUS_INTEGRATION.md`
- **Content**: Example scrape_configs for Prometheus

#### Components Users Must Provide

- **Prometheus Server**: Users deploy and manage their own
- **Grafana Server**: Users deploy and manage their own
- **Network Access**: Prometheus must reach runners on port 9091

---

## 📊 Metrics Exposed

### Runner Metrics (Port 9091/metrics)

```promql
# Runner status (1=online, 0=offline)
github_runner_status{runner_name="runner-1", runner_type="standard"} 1

# Total jobs executed by status
github_runner_jobs_total{runner_name="runner-1", status="success"} 42
github_runner_jobs_total{runner_name="runner-1", status="failed"} 3

# Job duration histogram (seconds)
github_runner_job_duration_seconds_bucket{runner_name="runner-1", le="60"} 10
github_runner_job_duration_seconds_bucket{runner_name="runner-1", le="300"} 35
github_runner_job_duration_seconds_sum{runner_name="runner-1"} 8542.5
github_runner_job_duration_seconds_count{runner_name="runner-1"} 45

# Queue time (seconds)
github_runner_queue_time_seconds{runner_name="runner-1"} 12.5

# Runner uptime (seconds)
github_runner_uptime_seconds{runner_name="runner-1"} 86400

# Cache hit rate (0.0-1.0)
github_runner_cache_hit_rate{runner_name="runner-1", cache_type="buildkit"} 0.85
github_runner_cache_hit_rate{runner_name="runner-1", cache_type="apt"} 0.95

# Runner info (metadata)
github_runner_info{runner_name="runner-1", runner_type="standard", version="2.329.0"} 1
```

### DORA Metrics (Calculated in Grafana)

```promql
# Deployment Frequency (builds/day)
sum(increase(github_runner_jobs_total{status="success"}[24h]))

# Lead Time for Changes (avg duration in minutes)
avg(rate(github_runner_job_duration_seconds_sum[5m]) / rate(github_runner_job_duration_seconds_count[5m])) / 60

# Change Failure Rate (%)
(sum(increase(github_runner_jobs_total{status="failed"}[24h])) / sum(increase(github_runner_jobs_total[24h]))) * 100
```

---

## 🚀 Implementation Plan

### Phase 1: Custom Metrics Endpoint (Week 1)

**Objective:** Add metrics endpoint to all runner types.

**Tasks:**
- [x] Create feature branch
- [x] Create feature specification
- [ ] Create bash metrics server script using netcat
- [ ] Create bash metrics collector script
- [ ] Initialize job log file in entrypoint scripts
- [ ] Update `docker/entrypoint.sh` to start metrics server and collector
- [ ] Update `docker/entrypoint-chrome.sh` to start metrics server and collector
- [ ] Expose port 9091 in all Dockerfiles
- [ ] Update all Docker Compose files to map port 9091
- [ ] Test metrics endpoint on all runner types

**Files to Create:**
- `docker/metrics-server.sh` - Netcat-based HTTP server for /metrics endpoint
- `docker/metrics-collector.sh` - Bash script to generate Prometheus metrics

**Files to Modify:**
- `docker/entrypoint.sh`
- `docker/entrypoint-chrome.sh`
- `docker/Dockerfile` (add `EXPOSE 9091`)
- `docker/Dockerfile.chrome` (add `EXPOSE 9091`)
- `docker/Dockerfile.chrome-go` (add `EXPOSE 9091`)
- `docker/docker-compose.production.yml` (add port mapping)
- `docker/docker-compose.chrome.yml` (add port mapping)
- `docker/docker-compose.chrome-go.yml` (add port mapping)

**Implementation:**

**1. Create Bash Metrics Server (`docker/metrics-server.sh`):**

```bash
#!/bin/bash
# Metrics HTTP server using netcat
# Serves /tmp/runner_metrics.prom on port 9091

METRICS_FILE="/tmp/runner_metrics.prom"
PORT="${METRICS_PORT:-9091}"

while true; do
    # Wait for connection
    RESPONSE=$(echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain; version=0.0.4\r\n\r\n$(cat \"$METRICS_FILE\" 2>/dev/null || echo '# No metrics available')" | nc -l -p "$PORT" -q 1)
done
```

**2. Create Bash Metrics Collector (`docker/metrics-collector.sh`):**

```bash
#!/bin/bash
# Metrics collector - generates Prometheus metrics every 30 seconds

METRICS_FILE="/tmp/runner_metrics.prom"
JOBS_LOG="/tmp/jobs.log"
START_TIME=$(date +%s)
RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
RUNNER_TYPE="${RUNNER_TYPE:-standard}"
RUNNER_VERSION="2.330.0"

while true; do
    # Calculate uptime
    CURRENT_TIME=$(date +%s)
    UPTIME=$((CURRENT_TIME - START_TIME))
    
    # Count jobs from log
    JOBS_TOTAL=$(wc -l < "$JOBS_LOG" 2>/dev/null || echo 0)
    JOBS_SUCCESS=$(grep -c "success" "$JOBS_LOG" 2>/dev/null || echo 0)
    JOBS_FAILED=$(grep -c "failed" "$JOBS_LOG" 2>/dev/null || echo 0)
    
    # Generate Prometheus metrics
    cat > "$METRICS_FILE" <<EOF
# HELP github_runner_status Runner online status (1=online, 0=offline)
# TYPE github_runner_status gauge
github_runner_status{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} 1

# HELP github_runner_uptime_seconds Runner uptime in seconds
# TYPE github_runner_uptime_seconds gauge
github_runner_uptime_seconds{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE"} $UPTIME

# HELP github_runner_jobs_total Total jobs executed by status
# TYPE github_runner_jobs_total counter
github_runner_jobs_total{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE",status="total"} $JOBS_TOTAL
github_runner_jobs_total{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE",status="success"} $JOBS_SUCCESS
github_runner_jobs_total{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE",status="failed"} $JOBS_FAILED

# HELP github_runner_info Runner metadata
# TYPE github_runner_info gauge
github_runner_info{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE",version="$RUNNER_VERSION"} 1
EOF
    
    # Wait 30 seconds before next update
    sleep 30
done
```

**3. Update Dockerfile (add metrics scripts and expose port):**

```dockerfile
# Copy metrics scripts
COPY metrics-server.sh /tmp/metrics-server.sh
COPY metrics-collector.sh /tmp/metrics-collector.sh
RUN chmod +x /tmp/metrics-server.sh /tmp/metrics-collector.sh

# Expose metrics port
EXPOSE 9091

# ... rest of Dockerfile ...
```

**4. Update `entrypoint.sh`:**

```bash
#!/bin/bash
set -euo pipefail

# Initialize job log
touch /tmp/jobs.log

# Start metrics collector in background
/tmp/metrics-collector.sh &
COLLECTOR_PID=$!
echo "✅ Metrics collector started (PID: $COLLECTOR_PID)"

# Start metrics HTTP server in background
/tmp/metrics-server.sh &
SERVER_PID=$!
echo "✅ Metrics server started (PID: $SERVER_PID) on port 9091"

# Trap to cleanup on exit
trap "kill $COLLECTOR_PID $SERVER_PID 2>/dev/null || true" EXIT

# Continue with normal runner startup...
```
# TYPE github_runner_info gauge
github_runner_info{runner_name="$RUNNER_NAME",runner_type="$RUNNER_TYPE",version="$RUNNER_VERSION"} 1
METRICS

  sleep 30
done
COLLECTOR_EOF

chmod +x /tmp/metrics-collector.sh
/tmp/metrics-collector.sh &

echo "✅ Metrics endpoint started on port $METRICS_PORT"

# Continue with normal runner startup...
```

**Deliverables:**
- [ ] Metrics endpoint accessible at `http://<runner-host>:9091/metrics`
- [ ] Metrics update in real-time using Prometheus client library
- [ ] All runner types supported (standard, Chrome, Chrome-Go)
- [ ] Production-grade implementation with official Go client
- [ ] Health check endpoint at `http://<runner-host>:9091/health`

**Testing:**
```bash
# Test metrics endpoint
curl http://localhost:9091/metrics

# Expected output (Prometheus text format):
# HELP github_runner_status Runner online status (1=online, 0=offline)
# TYPE github_runner_status gauge
github_runner_status{runner_name="runner-1",runner_type="standard"} 1

# HELP github_runner_jobs_total Total jobs executed by status
# TYPE github_runner_jobs_total counter
github_runner_jobs_total{runner_name="runner-1",runner_type="standard",status="success"} 0
github_runner_jobs_total{runner_name="runner-1",runner_type="standard",status="failed"} 0

# HELP github_runner_uptime_seconds Runner uptime in seconds
# TYPE github_runner_uptime_seconds gauge
github_runner_uptime_seconds{runner_name="runner-1",runner_type="standard"} 3600.5

# HELP github_runner_job_duration_seconds Job duration in seconds
# TYPE github_runner_job_duration_seconds histogram
github_runner_job_duration_seconds_bucket{runner_name="runner-1",runner_type="standard",status="success",le="10"} 0
github_runner_job_duration_seconds_bucket{runner_name="runner-1",runner_type="standard",status="success",le="20"} 0
github_runner_job_duration_seconds_bucket{runner_name="runner-1",runner_type="standard",status="success",le="+Inf"} 0
github_runner_job_duration_seconds_sum{runner_name="runner-1",runner_type="standard",status="success"} 0
github_runner_job_duration_seconds_count{runner_name="runner-1",runner_type="standard",status="success"} 0

# Test health endpoint
curl http://localhost:9091/health
# Expected: OK
```

---

### Phase 2: Grafana Dashboard (Week 2)

**Objective:** Create pre-built Grafana dashboard JSON for users to import.

**Tasks:**
- [ ] Design dashboard layout
- [ ] Create dashboard JSON with all panels
- [ ] Test dashboard with sample data
- [ ] Add dashboard variables (runner_name, runner_type filters)
- [ ] Document dashboard installation
- [ ] Create example Prometheus scrape config
- [ ] Write integration guide

**Files to Create:**
- `monitoring/grafana/dashboards/github-runner-dashboard.json`
- `docs/PROMETHEUS_INTEGRATION.md`
- `docs/GRAFANA_DASHBOARD_SETUP.md`

**Dashboard Panels:**

1. **Runner Status Overview** (Stat panel)
   - Query: `github_runner_status`
   - Shows online/offline status per runner

2. **Total Jobs Executed** (Stat panel)
   - Query: `sum(github_runner_jobs_total{status="total"})`

3. **Job Success Rate** (Gauge panel)
   - Query: `(sum(github_runner_jobs_total{status="success"}) / sum(github_runner_jobs_total{status="total"})) * 100`
   - Thresholds: <80% red, 80-95% yellow, >95% green

4. **Jobs per Hour** (Time series panel)
   - Query: `rate(github_runner_jobs_total[1h]) * 3600`

5. **Runner Uptime** (Table panel)
   - Query: `github_runner_uptime_seconds / 3600`
   - Shows uptime in hours

6. **Job Status Distribution** (Pie chart panel)
   - Query: `sum by (status) (github_runner_jobs_total)`

7. **Deployment Frequency** (Stat panel - DORA)
   - Query: `sum(increase(github_runner_jobs_total{status="success"}[24h]))`

8. **Lead Time for Changes** (Gauge panel - DORA)
   - Query: `avg(rate(github_runner_job_duration_seconds_sum[5m]) / rate(github_runner_job_duration_seconds_count[5m])) / 60`
   - Unit: minutes

9. **Change Failure Rate** (Gauge panel - DORA)
   - Query: `(sum(increase(github_runner_jobs_total{status="failed"}[24h])) / sum(increase(github_runner_jobs_total[24h]))) * 100`
   - Thresholds: >15% red, 5-15% yellow, <5% green

10. **Job Duration Trends** (Time series panel)
    - Query: `avg(rate(github_runner_job_duration_seconds_sum[5m]) / rate(github_runner_job_duration_seconds_count[5m]))`

11. **Cache Hit Rates** (Time series panel)
    - Query: `github_runner_cache_hit_rate * 100`
    - Group by cache_type

12. **Active Runners** (Stat panel)
    - Query: `count(github_runner_status == 1)`

**Dashboard Variables:**
- `runner_name`: Dropdown to filter by runner name
- `runner_type`: Dropdown to filter by runner type (standard, chrome, chrome-go)

**Deliverables:**
- [ ] Dashboard JSON file ready for import
- [ ] All 12 panels working
- [ ] Dashboard variables functional
- [ ] Documentation for installation
- [ ] Example Prometheus scrape config

**Testing:**
```bash
# Import dashboard into Grafana
# 1. Open Grafana UI
# 2. Go to Dashboards → Import
# 3. Upload github-runner-dashboard.json
# 4. Select Prometheus datasource
# 5. Click Import
# 6. Verify all panels show data
```

---

## 📚 Documentation Plan

### Files to Create

1. **`docs/PROMETHEUS_INTEGRATION.md`**
   - Prerequisites (Prometheus, Grafana required)
   - Example Prometheus scrape configuration
   - Network requirements (port 9091 access)
   - Troubleshooting scraping issues

2. **`docs/GRAFANA_DASHBOARD_SETUP.md`**
   - Dashboard import steps
   - Panel descriptions
   - Variable usage
   - Customization guide

3. **`README.md` Updates**
   - Add "Monitoring & Metrics" section
   - Link to integration docs
   - Dashboard screenshot

### Example Prometheus Scrape Config

```yaml
# Add to your existing prometheus.yml
scrape_configs:
  - job_name: 'github-runner-standard'
    static_configs:
      - targets: ['runner-1:9091', 'runner-2:9091', 'runner-3:9091']
        labels:
          runner_type: 'standard'

  - job_name: 'github-runner-chrome'
    static_configs:
      - targets: ['chrome-runner-1:9091', 'chrome-runner-2:9091']
        labels:
          runner_type: 'chrome'

  - job_name: 'github-runner-chrome-go'
    static_configs:
      - targets: ['chrome-go-runner-1:9091']
        labels:
          runner_type: 'chrome-go'
```

---

## ✅ Acceptance Criteria

### Functional Requirements
- [ ] Custom metrics endpoint running on port 9091 for all runner types
- [ ] Metrics in valid Prometheus format
- [ ] Grafana dashboard JSON file created
- [ ] All 12 dashboard panels functional
- [ ] Dashboard variables working (runner_name, runner_type)
- [ ] Documentation complete

### Non-Functional Requirements
- [ ] Performance overhead <1% CPU, <50MB RAM per runner
- [ ] Metrics endpoint response time <100ms
- [ ] Metrics update frequency: 30 seconds
- [ ] Dashboard loads in <2 seconds
- [ ] Works with Prometheus 2.x and Grafana 8.x+

### Documentation Requirements
- [ ] Prometheus integration guide
- [ ] Grafana dashboard setup guide
- [ ] README updated
- [ ] Example configurations provided

---

## 📅 Timeline

| Phase | Duration | Deliverables | Status |
|-------|----------|-------------|---------|
| Phase 1: Metrics Endpoint | 1 week | Port 9091 endpoint on all runners | 🚧 In Progress |
| Phase 2: Grafana Dashboard | 1 week | Dashboard JSON + documentation | ⏳ Planned |
| **Total** | **2 weeks** | **Complete** | **10% Done** |

**Start Date:** 2025-11-16  
**Target Completion:** 2025-11-30

---

## 🎁 Expected Benefits

- **Production-Grade**: Official Prometheus client library (battle-tested)
- **Visibility**: Complete insight into runner health and job execution
- **DORA Metrics**: Automated tracking of all 4 key DevOps metrics
- **Performance**: Optimized Go implementation with minimal overhead
- **Easy Integration**: Standard Prometheus metrics endpoint format
- **Time Savings**: Pre-built dashboard saves 4-8 hours of setup time
- **Troubleshooting**: Historical data with histograms for debugging issues
- **Reliability**: Proper metric types (gauges, counters, histograms)

---

## 🚨 Risks & Mitigations

### Risk 1: Port 9091 Conflicts
**Mitigation**: Document port requirements, make port configurable via environment variable

### Risk 2: Netcat Performance
**Mitigation**: Simple HTTP response, pre-generated metrics file, minimal overhead

### Risk 3: Metric Format Compatibility
**Mitigation**: Use standard Prometheus text format specification, test with actual Prometheus

### Risk 4: Bash Script Reliability
**Mitigation**: Error handling with set -euo pipefail, process supervision, container restart policies

---

## 📖 References

- [Prometheus Exposition Formats](https://prometheus.io/docs/instrumenting/exposition_formats/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/naming/)
- [Grafana Dashboard JSON Model](https://grafana.com/docs/grafana/latest/dashboards/json-model/)
- [DORA Metrics](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance)
- [OpenMetrics Specification](https://github.com/OpenObservability/OpenMetrics/blob/main/specification/OpenMetrics.md)
- [Netcat Usage Guide](https://www.computerhope.com/unix/nc.htm)

---

**Last Updated:** 2025-12-18  
**Scope:** Metrics Endpoint + Grafana Dashboard ONLY  
**Status:** 🚧 Phase 1 - In Progress  
**Completion:** 10%
