# Phase 2 Testing & Deployment Guide

## Overview

This guide covers testing and deploying the Chrome and Chrome-Go runner variants with Prometheus metrics endpoints (Phase 2 of Issue #1060).

## Prerequisites

- Docker Engine with BuildKit support
- Docker Compose v2+
- GitHub repository access token with `repo` scope
- At least 4GB RAM available
- Ports 9092 and 9093 available (for metrics endpoints)

## Quick Start

### 1. Build Images (TASK-020, TASK-021)

#### Build Chrome Runner
```bash
cd /home/runner/work/github-runner/github-runner
DOCKER_BUILDKIT=1 docker build \
  -t github-runner:chrome-metrics-test \
  -f docker/Dockerfile.chrome \
  docker/
```

#### Build Chrome-Go Runner
```bash
DOCKER_BUILDKIT=1 docker build \
  -t github-runner:chrome-go-metrics-test \
  -f docker/Dockerfile.chrome-go \
  docker/
```

### 2. Deploy Runners (TASK-022, TASK-023)

#### Configure Environment

Create or update your environment file:

```bash
# For Chrome runner
cat > config/chrome-runner.env << 'EOF'
GITHUB_TOKEN=<your-github-pat>
GITHUB_REPOSITORY=<owner/repo>
RUNNER_NAME=chrome-test-runner
RUNNER_TYPE=chrome
METRICS_PORT=9091
METRICS_UPDATE_INTERVAL=30
EOF

# For Chrome-Go runner
cat > config/chrome-go-runner.env << 'EOF'
GITHUB_TOKEN=<your-github-pat>
GITHUB_REPOSITORY=<owner/repo>
RUNNER_NAME=chrome-go-test-runner
RUNNER_TYPE=chrome-go
METRICS_PORT=9091
METRICS_UPDATE_INTERVAL=30
EOF
```

#### Deploy Chrome Runner
```bash
docker-compose -f docker/docker-compose.chrome.yml up -d
```

#### Deploy Chrome-Go Runner
```bash
docker-compose -f docker/docker-compose.chrome-go.yml up -d
```

### 3. Validate Metrics (TASK-024, TASK-025, TASK-026)

#### Run Automated Tests
```bash
./tests/integration/test-phase2-metrics.sh
```

#### Manual Validation

**Chrome Runner (Port 9092):**
```bash
# Check metrics endpoint
curl http://localhost:9092/metrics

# Verify runner type
curl -s http://localhost:9092/metrics | grep runner_type
# Expected: runner_type="chrome"

# Check all required metrics are present
curl -s http://localhost:9092/metrics | grep -E "(github_runner_status|github_runner_info|github_runner_uptime_seconds|github_runner_jobs_total|github_runner_last_update_timestamp)"
```

**Chrome-Go Runner (Port 9093):**
```bash
# Check metrics endpoint
curl http://localhost:9093/metrics

# Verify runner type
curl -s http://localhost:9093/metrics | grep runner_type
# Expected: runner_type="chrome-go"

# Check all required metrics are present
curl -s http://localhost:9093/metrics | grep -E "(github_runner_status|github_runner_info|github_runner_uptime_seconds|github_runner_jobs_total|github_runner_last_update_timestamp)"
```

**Concurrent Deployment Test:**
```bash
# Verify both runners are accessible
curl -sf http://localhost:9092/metrics > /dev/null && echo "✓ Chrome runner accessible"
curl -sf http://localhost:9093/metrics > /dev/null && echo "✓ Chrome-Go runner accessible"

# Verify no port conflicts
echo "Chrome runner type: $(curl -s http://localhost:9092/metrics | grep -o 'runner_type="[^"]*"')"
echo "Chrome-Go runner type: $(curl -s http://localhost:9093/metrics | grep -o 'runner_type="[^"]*"')"
```

## Monitoring Integration

### Prometheus Configuration

Add these scrape targets to your Prometheus configuration:

```yaml
scrape_configs:
  # Standard runner (from Phase 1)
  - job_name: 'github-runner-standard'
    static_configs:
      - targets: ['localhost:9091']
    scrape_interval: 30s

  # Chrome runner (Phase 2)
  - job_name: 'github-runner-chrome'
    static_configs:
      - targets: ['localhost:9092']
    scrape_interval: 30s

  # Chrome-Go runner (Phase 2)
  - job_name: 'github-runner-chrome-go'
    static_configs:
      - targets: ['localhost:9093']
    scrape_interval: 30s
```

### Grafana Dashboard Queries

**All Runners by Type:**
```promql
github_runner_status{runner_type=~"standard|chrome|chrome-go"}
```

**Chrome Runner Uptime:**
```promql
github_runner_uptime_seconds{runner_type="chrome"}
```

**Chrome-Go Runner Jobs:**
```promql
github_runner_jobs_total{runner_type="chrome-go"}
```

## Troubleshooting

### Metrics Endpoint Not Responding

**Check Container Logs:**
```bash
# Chrome runner
docker logs github-runner-chrome

# Chrome-Go runner
docker logs github-runner-chrome-go
```

**Verify Metrics Processes:**
```bash
# Chrome runner
docker exec github-runner-chrome ps aux | grep metrics

# Chrome-Go runner
docker exec github-runner-chrome-go ps aux | grep metrics
```

**Check Metrics Files:**
```bash
# Chrome runner
docker exec github-runner-chrome cat /tmp/runner_metrics.prom

# Chrome-Go runner
docker exec github-runner-chrome-go cat /tmp/runner_metrics.prom
```

### Port Already in Use

If ports 9092 or 9093 are already in use, you can change the host port mapping in the docker-compose files:

```yaml
# docker-compose.chrome.yml
ports:
  - "9094:9091"  # Change 9092 to 9094

# docker-compose.chrome-go.yml
ports:
  - "9095:9091"  # Change 9093 to 9095
```

### Container Won't Start

**Check Resource Availability:**
```bash
docker stats --no-stream
```

Chrome runners require:
- 2GB RAM
- 1.0 CPU
- 2GB shared memory

**Verify Environment Variables:**
```bash
docker exec github-runner-chrome env | grep -E "(GITHUB_|RUNNER_|METRICS_)"
```

## Performance Validation

### CPU Usage
```bash
docker stats github-runner-chrome github-runner-chrome-go --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

Expected:
- CPU: <1% per runner (metrics overhead)
- Memory: ~15-20MB for metrics services

### Metrics Update Frequency

```bash
# Monitor uptime metric over 60 seconds
watch -n 30 "curl -s http://localhost:9092/metrics | grep github_runner_uptime_seconds"
```

Expected: Uptime should increase by ~30 seconds every 30 seconds

## Cleanup

### Stop Runners
```bash
# Stop Chrome runner
docker-compose -f docker/docker-compose.chrome.yml down

# Stop Chrome-Go runner
docker-compose -f docker/docker-compose.chrome-go.yml down
```

### Remove Volumes (optional)
```bash
# Remove Chrome runner volumes
docker volume rm chrome-cache chrome-config chrome-cache-npm chrome-cache-pip chrome-jobs-log

# Remove Chrome-Go runner volumes
docker volume rm chrome-go-cache chrome-go-config chrome-go-cache-npm chrome-go-cache-pip chrome-go-cache-go chrome-go-jobs-log
```

### Remove Images
```bash
docker rmi github-runner:chrome-metrics-test
docker rmi github-runner:chrome-go-metrics-test
```

## Success Criteria Checklist

- [ ] Chrome runner exposes metrics on port 9092
- [ ] Chrome-Go runner exposes metrics on port 9093
- [ ] All 3 runner types can run concurrently without port conflicts
- [ ] Metrics include correct `runner_type` label for each variant
- [ ] Performance overhead remains <1% CPU per runner
- [ ] All 5 required metrics present for each runner type
- [ ] Metrics update every 30 seconds
- [ ] Job log tracking works correctly

## Related Documentation

- Phase 1 Implementation: PR #1066
- Issue #1060: Phase 2 Requirements
- Metrics Scripts: `docker/metrics-server.sh`, `docker/metrics-collector.sh`

## Support

For issues or questions:
1. Check container logs first
2. Verify all prerequisites are met
3. Review troubleshooting section above
4. Open an issue on GitHub with logs attached
