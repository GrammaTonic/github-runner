---
goal: Implement Prometheus Metrics Endpoint and Grafana Dashboard for GitHub Actions Self-Hosted Runners
version: 1.0
date_created: 2025-11-16
last_updated: 2025-11-16
owner: Development Team
status: 'In progress'
tags: ['feature', 'monitoring', 'prometheus', 'grafana', 'metrics', 'observability']
---

# Introduction

![Status: In progress](https://img.shields.io/badge/status-In_progress-yellow)

This implementation plan provides a fully executable roadmap for adding Prometheus metrics endpoint and Grafana dashboard capabilities to the GitHub Actions self-hosted runner infrastructure. The plan focuses on custom runner-specific metrics exposed on port 9091, with pre-built Grafana dashboards for visualization. This assumes external Prometheus and Grafana infrastructure already exists (user-provided).

**Scope:** Custom metrics endpoint + Grafana dashboard JSON files (assumes external Prometheus/Grafana servers)

**Out of Scope:** Prometheus server deployment, Grafana server deployment, Alertmanager configuration (future phases)

**Target Release:** v2.3.0  
**Timeline:** 5 weeks (2025-11-16 to 2025-12-21)

## 1. Requirements & Constraints

### Functional Requirements

- **REQ-001**: Expose custom metrics endpoint on port 9091 for all runner types (standard, Chrome, Chrome-Go)
- **REQ-002**: Metrics must be in Prometheus text format (OpenMetrics compatible)
- **REQ-003**: Metrics update frequency must be 30 seconds
- **REQ-004**: Track runner status, job counts, job duration, uptime, and cache hit rates
- **REQ-005**: Provide 4 pre-built Grafana dashboard JSON files for import
- **REQ-006**: Calculate and display DORA metrics (Deployment Frequency, Lead Time, Change Failure Rate)
- **REQ-007**: Support multiple concurrent runners with unique identifiers
- **REQ-008**: Metrics must persist across container restarts via job logging

### Non-Functional Requirements

- **NFR-001**: Metrics collection overhead must be <1% CPU per runner
- **NFR-002**: Metrics collection memory overhead must be <50MB per runner
- **NFR-003**: Metrics endpoint response time must be <100ms
- **NFR-004**: Dashboard query execution time must be <2 seconds
- **NFR-005**: Setup time for new users must be <15 minutes
- **NFR-006**: Zero downtime deployment of metrics collection

### Security Requirements

- **SEC-001**: Metrics endpoint must not expose sensitive data (tokens, credentials)
- **SEC-002**: Metrics endpoint must be accessible only via container network (not externally exposed by default)
- **SEC-003**: No new security vulnerabilities introduced in metrics collection code

### Constraints

- **CON-001**: Must use bash scripting (no additional language runtimes like Python/Node.js/Go)
- **CON-002**: Must use netcat (nc) for HTTP server (lightweight, already available in base image)
- **CON-003**: Cannot modify GitHub Actions runner binary or core functionality
- **CON-004**: Must maintain compatibility with existing Docker Compose configurations
- **CON-005**: Must work with ubuntu:questing base image (25.10)
- **CON-006**: External Prometheus server is user-provided (not included in this project)
- **CON-007**: External Grafana server is user-provided (not included in this project)

### Guidelines

- **GUD-001**: Follow existing project structure (`/docker`, `/monitoring`, `/docs`)
- **GUD-002**: Use conventional commit messages (e.g., `feat: add metrics endpoint`)
- **GUD-003**: All documentation must go in `/docs/` subdirectories (never root)
- **GUD-004**: All files must be organized according to `.github/copilot-instructions.md` standards
- **GUD-005**: Use BuildKit cache optimizations where applicable
- **GUD-006**: Provide comprehensive documentation with examples and troubleshooting

### Patterns to Follow

- **PAT-001**: Use entrypoint script pattern for initialization (`docker/entrypoint.sh`, `docker/entrypoint-chrome.sh`)
- **PAT-002**: Use environment variables for configuration (`RUNNER_NAME`, `RUNNER_TYPE`, `METRICS_PORT`)
- **PAT-003**: Use volume mounts for persistent data (`/tmp/jobs.log`)
- **PAT-004**: Use health checks in Docker Compose for service monitoring
- **PAT-005**: Use multi-stage Dockerfile builds for optimization (where applicable)

## 2. Implementation Steps

### Implementation Phase 1: Custom Metrics Endpoint - Standard Runner

**Timeline:** Week 1 (2025-11-16 to 2025-11-23)  
**Status:** 🚧 In Progress

- **GOAL-001**: Implement custom metrics endpoint on port 9091 for standard runner type with job tracking and basic metrics

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Create metrics HTTP server script (`/tmp/metrics-server.sh`) using netcat that listens on port 9091 and serves `/tmp/runner_metrics.prom` file in Prometheus text format | | |
| TASK-002 | Create metrics collector script (`/tmp/metrics-collector.sh`) that updates metrics every 30 seconds by reading `/tmp/jobs.log` and system stats, generating Prometheus metrics: `github_runner_status`, `github_runner_jobs_total{status="success|failed|total"}`, `github_runner_uptime_seconds`, `github_runner_info` | | |
| TASK-003 | Initialize `/tmp/jobs.log` file in `docker/entrypoint.sh` with touch command before runner starts | | |
| TASK-004 | Integrate metrics server and collector into `docker/entrypoint.sh` by adding background process launches after runner configuration and before runner start command | | |
| TASK-005 | Add `EXPOSE 9091` directive to `docker/Dockerfile` to document the metrics port | | |
| TASK-006 | Update `docker/docker-compose.production.yml` to expose port 9091 with mapping `"9091:9091"` in ports section | | |
| TASK-007 | Add environment variables `RUNNER_TYPE=standard` and `METRICS_PORT=9091` to `docker/docker-compose.production.yml` | | |
| TASK-008 | Build standard runner image with BuildKit: `docker build -t github-runner:metrics-test -f docker/Dockerfile docker/` | | |
| TASK-009 | Deploy test runner: `docker-compose -f docker/docker-compose.production.yml up -d` | | |
| TASK-010 | Validate metrics endpoint responds: `curl http://localhost:9091/metrics` should return Prometheus-formatted metrics with HTTP 200 | | |
| TASK-011 | Verify metrics update every 30 seconds by observing `github_runner_uptime_seconds` increment | | |
| TASK-012 | Test job logging by manually appending to `/tmp/jobs.log` and verifying `github_runner_jobs_total` increments | | |

### Implementation Phase 2: Custom Metrics Endpoint - Chrome & Chrome-Go Runners

**Timeline:** Week 2 (2025-11-23 to 2025-11-30)  
**Status:** ⏳ Planned

- **GOAL-002**: Extend metrics endpoint to Chrome and Chrome-Go runner types with identical functionality

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-013 | Integrate metrics server and collector scripts into `docker/entrypoint-chrome.sh` (identical to TASK-004 but for Chrome entrypoint) | | |
| TASK-014 | Add `EXPOSE 9091` to `docker/Dockerfile.chrome` | | |
| TASK-015 | Add `EXPOSE 9091` to `docker/Dockerfile.chrome-go` | | |
| TASK-016 | Update `docker/docker-compose.chrome.yml` to expose port 9091 with unique host port mapping `"9092:9091"` to avoid conflicts with standard runner | | |
| TASK-017 | Update `docker/docker-compose.chrome-go.yml` to expose port 9091 with unique host port mapping `"9093:9091"` | | |
| TASK-018 | Add environment variables `RUNNER_TYPE=chrome` and `METRICS_PORT=9091` to `docker/docker-compose.chrome.yml` | | |
| TASK-019 | Add environment variables `RUNNER_TYPE=chrome-go` and `METRICS_PORT=9091` to `docker/docker-compose.chrome-go.yml` | | |
| TASK-020 | Build Chrome runner: `docker build -t github-runner:chrome-metrics-test -f docker/Dockerfile.chrome docker/` | | |
| TASK-021 | Build Chrome-Go runner: `docker build -t github-runner:chrome-go-metrics-test -f docker/Dockerfile.chrome-go docker/` | | |
| TASK-022 | Deploy Chrome runner: `docker-compose -f docker/docker-compose.chrome.yml up -d` | | |
| TASK-023 | Deploy Chrome-Go runner: `docker-compose -f docker/docker-compose.chrome-go.yml up -d` | | |
| TASK-024 | Validate Chrome metrics: `curl http://localhost:9092/metrics` returns metrics with `runner_type="chrome"` | | |
| TASK-025 | Validate Chrome-Go metrics: `curl http://localhost:9093/metrics` returns metrics with `runner_type="chrome-go"` | | |
| TASK-026 | Test concurrent multi-runner deployment with all 3 types and verify unique metrics per runner | | |

### Implementation Phase 3: Enhanced Metrics & Job Tracking

**Timeline:** Week 2-3 (2025-11-26 to 2025-12-03)  
**Status:** ⏳ Planned

- **GOAL-003**: Add job duration tracking, cache hit rates, and queue time metrics for DORA calculations

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-027 | Extend `/tmp/jobs.log` format to include: `timestamp,job_id,status,duration_seconds,queue_time_seconds` (CSV format) | | |
| TASK-028 | Implement job start/end time tracking by hooking into GitHub Actions runner job lifecycle (via log parsing of runner output) | | |
| TASK-029 | Update metrics collector to calculate job duration histogram buckets: `github_runner_job_duration_seconds_bucket{le="60|300|600|1800|3600"}`, `github_runner_job_duration_seconds_sum`, `github_runner_job_duration_seconds_count` | | |
| TASK-030 | Add queue time metric: `github_runner_queue_time_seconds` (time from job assignment to job start) | | |
| TASK-031 | Implement cache hit rate tracking by parsing Docker BuildKit cache logs for `CACHED` vs `cache miss` entries | | |
| TASK-032 | Add cache metrics: `github_runner_cache_hit_rate{cache_type="buildkit|apt|npm"}` (percentage 0.0-1.0) | | |
| TASK-033 | Update metrics collector script to read cache logs from `/var/log/buildkit.log` (or appropriate location) | | |
| TASK-034 | Test job duration tracking by running actual GitHub Actions workflows and verifying histogram data | | |
| TASK-035 | Validate cache metrics with controlled builds (force cache miss vs cache hit scenarios) | | |
| TASK-036 | Document job log format in `docs/features/PROMETHEUS_IMPROVEMENTS.md` under "Metrics Collection" section | | |

### Implementation Phase 4: Grafana Dashboards

**Timeline:** Week 3-4 (2025-11-30 to 2025-12-10)  
**Status:** ⏳ Planned

- **GOAL-004**: Create 4 pre-built Grafana dashboard JSON files for import into user's Grafana instance

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-037 | Create `monitoring/grafana/dashboards/runner-overview.json` with panels: Runner Status (stat), Total Jobs (stat), Success Rate (gauge), Jobs per Hour (graph), Runner Uptime (table), Job Status Distribution (pie), Active Runners (stat) | | |
| TASK-038 | Configure dashboard variables: `runner_name` (multi-select from `github_runner_info`), `runner_type` (multi-select: standard, chrome, chrome-go) | | |
| TASK-039 | Create `monitoring/grafana/dashboards/dora-metrics.json` with panels: Deployment Frequency (stat: `sum(increase(github_runner_jobs_total{status="success"}[24h]))`), Lead Time (gauge: avg job duration), Change Failure Rate (gauge: failed/total * 100), Deployment Frequency Trend (graph), Lead Time Trend (graph), Failure Rate Trend (graph) | | |
| TASK-040 | Create `monitoring/grafana/dashboards/performance-trends.json` with panels: Build Time Trends (graph: p50/p95/p99 job duration), Cache Hit Rate (graph: by cache type), Job Queue Depth (graph: pending jobs), Runner Load Distribution (heatmap), Error Rate (graph: failed jobs/hour) | | |
| TASK-041 | Create `monitoring/grafana/dashboards/job-analysis.json` with panels: Job Duration Histogram (heatmap), Jobs by Status (bar chart), Top 10 Longest Jobs (table), Recent Failures (table with job ID, duration, timestamp), Job Success/Failure Timeline (graph) | | |
| TASK-042 | Add dashboard metadata: title, description, tags, version, refresh interval (15s), time range (last 24h) | | |
| TASK-043 | Test dashboards by importing into local Grafana instance with Prometheus datasource | | |
| TASK-044 | Capture screenshots of each dashboard for documentation | | |
| TASK-045 | Export final dashboard JSON files with templating variables configured | | |
| TASK-046 | Validate all PromQL queries execute in <2 seconds with test data | | |

### Implementation Phase 5: Documentation & User Guide

**Timeline:** Week 4-5 (2025-12-07 to 2025-12-21)  
**Status:** ⏳ Planned

- **GOAL-005**: Provide comprehensive documentation for setup, usage, troubleshooting, and architecture

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-047 | Create `docs/features/PROMETHEUS_SETUP.md` with sections: Prerequisites (external Prometheus/Grafana), Prometheus scrape config example (scraping port 9091), Grafana datasource setup, Dashboard import instructions, Verification steps, Troubleshooting common setup issues | | |
| TASK-048 | Create `docs/features/PROMETHEUS_USAGE.md` with sections: Accessing metrics endpoint, Understanding metric types, Writing custom PromQL queries, Customizing dashboards, Setting up alerts (future), Best practices for metrics retention | | |
| TASK-049 | Create `docs/features/PROMETHEUS_TROUBLESHOOTING.md` with sections: Metrics endpoint not responding (check port exposure, container logs), Metrics not updating (check collector script, logs), Dashboard showing "No Data" (verify Prometheus scraping, datasource config), High memory usage (adjust retention, scrape interval), Performance optimization tips | | |
| TASK-050 | Create `docs/features/PROMETHEUS_ARCHITECTURE.md` with sections: System architecture diagram, Component descriptions (metrics server, collector, HTTP endpoint), Data flow (collector → file → HTTP server → Prometheus), Metric naming conventions, Design decisions (bash + netcat rationale), Scalability considerations (horizontal runner scaling) | | |
| TASK-051 | Update `README.md` with "📊 Monitoring" section linking to setup guide and architecture docs | | |
| TASK-052 | Update `docs/README.md` with links to all new Prometheus documentation files | | |
| TASK-053 | Create example Prometheus scrape configuration YAML snippet in `monitoring/prometheus-scrape-example.yml` | | |
| TASK-054 | Document metric definitions with descriptions, types (gauge/counter/histogram), and example values in `docs/features/PROMETHEUS_METRICS_REFERENCE.md` | | |
| TASK-055 | Add metrics endpoint to API documentation in `docs/API.md` (if applicable) | | |
| TASK-056 | Create quickstart guide: `docs/features/PROMETHEUS_QUICKSTART.md` with 5-minute setup instructions | | |

### Implementation Phase 6: Testing & Validation

**Timeline:** Week 5 (2025-12-14 to 2025-12-21)  
**Status:** ⏳ Planned

- **GOAL-006**: Validate all functionality, measure performance overhead, and ensure production readiness

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-057 | Create integration test script `tests/integration/test-metrics-endpoint.sh` that validates: endpoint returns HTTP 200, metrics are Prometheus-formatted, all expected metrics are present, metrics update over time | | |
| TASK-058 | Create performance test script `tests/integration/test-metrics-performance.sh` that measures: CPU overhead (<1%), memory overhead (<50MB), response time (<100ms), metrics collection interval accuracy (30s ±2s) | | |
| TASK-059 | Test standard runner with metrics under load (10 concurrent jobs) and verify metrics accuracy | | |
| TASK-060 | Test Chrome runner with metrics under load (5 concurrent browser jobs) and verify metrics accuracy | | |
| TASK-061 | Test Chrome-Go runner with metrics under load (5 concurrent Go + browser jobs) and verify metrics accuracy | | |
| TASK-062 | Validate metrics persistence across container restart: stop container, restart, verify job counts maintained via `/tmp/jobs.log` volume mount | | |
| TASK-063 | Test scaling scenario: deploy 5 runners simultaneously, verify unique metrics per runner, check Prometheus can scrape all targets | | |
| TASK-064 | Measure Prometheus storage growth over 7 days with 3 runners and estimate monthly storage requirements | | |
| TASK-065 | Validate all Grafana dashboards display data correctly with real runner workloads | | |
| TASK-066 | Benchmark dashboard query performance: all panels must load in <2s with 7 days of data | | |
| TASK-067 | Security scan: verify no sensitive data in metrics, no new vulnerabilities introduced | | |
| TASK-068 | Documentation review: verify all setup steps work for new users (clean install test) | | |
| TASK-069 | Update `tests/README.md` with instructions for running metrics integration tests | | |
| TASK-070 | Add metrics tests to CI/CD pipeline (`.github/workflows/ci-cd.yml`) if applicable | | |

### Implementation Phase 7: Release Preparation

**Timeline:** Week 5 (2025-12-18 to 2025-12-21)  
**Status:** ⏳ Planned

- **GOAL-007**: Prepare feature for release, create release notes, and merge to main

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-071 | Create release notes in `docs/releases/v2.3.0-prometheus-metrics.md` with sections: Overview, New Features, Setup Instructions, Breaking Changes (none), Known Issues, Upgrade Path | | |
| TASK-072 | Update `VERSION` file to `2.3.0` | | |
| TASK-073 | Create PR from `feature/prometheus-improvements` to `develop` with comprehensive description using `.github/pull_request_template.md` | | |
| TASK-074 | Address PR review comments and ensure CI/CD pipeline passes | | |
| TASK-075 | Merge PR to `develop` using squash merge strategy | | |
| TASK-076 | Perform back-sync from `main` to `develop` after merge (if merging to main) | | |
| TASK-077 | Tag release: `git tag -a v2.3.0 -m "Release v2.3.0: Prometheus Metrics & Grafana Dashboards"` | | |
| TASK-078 | Push tag: `git push origin v2.3.0` | | |
| TASK-079 | Create GitHub release with release notes and dashboard JSON attachments | | |
| TASK-080 | Announce feature in project README changelog section | | |

## 3. Alternatives

### Alternative Approaches Considered

- **ALT-001**: **Use Prometheus Node Exporter + cAdvisor only** - Rejected because it doesn't provide runner-specific application metrics (job counts, success rate, DORA metrics). System metrics are important but insufficient for runner observability.

- **ALT-002**: **Use Python/Node.js HTTP server for metrics endpoint** - Rejected due to CON-001 (bash-only constraint). Would add runtime dependencies and increase image size. Bash + netcat is lighter and sufficient for simple HTTP responses.

- **ALT-003**: **Use GitHub Actions built-in monitoring** - Rejected because GitHub Actions SaaS monitoring doesn't extend to self-hosted runners' internal metrics. We need custom metrics for DORA calculations and cache performance.

- **ALT-004**: **Deploy Prometheus + Grafana as part of this project** - Rejected to reduce scope (CON-006, CON-007). Users may already have monitoring infrastructure. This approach allows integration with existing setups.

- **ALT-005**: **Use StatsD + Graphite instead of Prometheus** - Rejected because Prometheus is the industry standard for Kubernetes/container environments, has better querying (PromQL), and integrates seamlessly with Grafana.

- **ALT-006**: **Real-time metrics streaming via WebSockets** - Rejected due to complexity and performance overhead. 30-second polling is sufficient for monitoring use cases and reduces resource consumption.

- **ALT-007**: **Store metrics in database instead of log files** - Rejected to avoid external dependencies (databases). File-based logging is simpler, requires no additional infrastructure, and can be volume-mounted for persistence.

## 4. Dependencies

### External Dependencies

- **DEP-001**: **External Prometheus server** - User must provide and configure Prometheus to scrape runners on port 9091. Example scrape config will be provided in documentation.

- **DEP-002**: **External Grafana instance** - User must provide Grafana with Prometheus datasource configured. Dashboard JSON files will be provided for import.

- **DEP-003**: **Docker Engine** - Required for containerized runner deployment (existing dependency).

- **DEP-004**: **Docker Compose** - Required for orchestration (existing dependency).

- **DEP-005**: **netcat (nc)** - Required for HTTP server. Already available in ubuntu:questing base image.

### Internal Dependencies

- **DEP-006**: **docker/entrypoint.sh** - Metrics integration depends on entrypoint script structure (existing file, will be modified).

- **DEP-007**: **docker/entrypoint-chrome.sh** - Chrome metrics depend on Chrome entrypoint script (existing file, will be modified).

- **DEP-008**: **Docker Compose files** - Port exposure depends on compose configurations (existing files, will be modified).

- **DEP-009**: **Dockerfiles** - EXPOSE directives depend on Dockerfile structure (existing files, will be modified).

- **DEP-010**: **GitHub Actions Runner Binary** - Job tracking depends on runner log output format. Changes to runner binary may require log parsing updates.

### Build Dependencies

- **DEP-011**: **BuildKit** - Required for cache mount optimizations (existing build system dependency).

- **DEP-012**: **bash** - Required for metrics scripts (available in base image).

## 5. Files

### Files to Create

- **FILE-001**: `/plan/feature-prometheus-monitoring-1.md` - This implementation plan document (AI-executable)

- **FILE-002**: `monitoring/grafana/dashboards/runner-overview.json` - Grafana dashboard for runner status and job overview

- **FILE-003**: `monitoring/grafana/dashboards/dora-metrics.json` - Grafana dashboard for DORA metrics visualization

- **FILE-004**: `monitoring/grafana/dashboards/performance-trends.json` - Grafana dashboard for performance analysis

- **FILE-005**: `monitoring/grafana/dashboards/job-analysis.json` - Grafana dashboard for detailed job analysis

- **FILE-006**: `monitoring/prometheus-scrape-example.yml` - Example Prometheus scrape configuration

- **FILE-007**: `docs/features/PROMETHEUS_SETUP.md` - Setup and installation guide

- **FILE-008**: `docs/features/PROMETHEUS_USAGE.md` - Usage guide with examples

- **FILE-009**: `docs/features/PROMETHEUS_TROUBLESHOOTING.md` - Troubleshooting guide

- **FILE-010**: `docs/features/PROMETHEUS_ARCHITECTURE.md` - Architecture and design documentation

- **FILE-011**: `docs/features/PROMETHEUS_METRICS_REFERENCE.md` - Metrics definitions and examples

- **FILE-012**: `docs/features/PROMETHEUS_QUICKSTART.md` - 5-minute quickstart guide

- **FILE-013**: `docs/releases/v2.3.0-prometheus-metrics.md` - Release notes for v2.3.0

- **FILE-014**: `tests/integration/test-metrics-endpoint.sh` - Integration test for metrics endpoint

- **FILE-015**: `tests/integration/test-metrics-performance.sh` - Performance test for metrics collection

### Files to Modify

- **FILE-016**: `docker/entrypoint.sh` - Add metrics server and collector background processes

- **FILE-017**: `docker/entrypoint-chrome.sh` - Add metrics server and collector (Chrome variant)

- **FILE-018**: `docker/Dockerfile` - Add EXPOSE 9091 directive

- **FILE-019**: `docker/Dockerfile.chrome` - Add EXPOSE 9091 directive

- **FILE-020**: `docker/Dockerfile.chrome-go` - Add EXPOSE 9091 directive

- **FILE-021**: `docker/docker-compose.production.yml` - Add port mapping 9091:9091 and environment variables

- **FILE-022**: `docker/docker-compose.chrome.yml` - Add port mapping 9092:9091 and environment variables

- **FILE-023**: `docker/docker-compose.chrome-go.yml` - Add port mapping 9093:9091 and environment variables

- **FILE-024**: `README.md` - Add Monitoring section with links to documentation

- **FILE-025**: `docs/README.md` - Add links to Prometheus documentation

- **FILE-026**: `docs/features/PROMETHEUS_IMPROVEMENTS.md` - Update with implementation progress (existing feature spec)

- **FILE-027**: `VERSION` - Update to 2.3.0

- **FILE-028**: `tests/README.md` - Add metrics test instructions

- **FILE-029**: `.github/workflows/ci-cd.yml` - Add metrics tests to pipeline (optional)

## 6. Testing

### Unit Tests

- **TEST-001**: **Metrics Server Script** - Test that `/tmp/metrics-server.sh` responds to HTTP requests on port 9091 with HTTP 200 and valid Prometheus format. Mock netcat with controlled input/output.

- **TEST-002**: **Metrics Collector Script** - Test that `/tmp/metrics-collector.sh` correctly parses `/tmp/jobs.log` and generates accurate Prometheus metrics. Use fixture job log with known counts.

- **TEST-003**: **Job Log Parsing** - Test CSV parsing logic with various job log formats (success, failed, different durations). Verify correct counter increments.

- **TEST-004**: **Metric Format Validation** - Test that generated metrics conform to Prometheus text format specification (correct HELP, TYPE, metric names, labels, values).

### Integration Tests

- **TEST-005**: **End-to-End Metrics Collection** - Deploy runner with metrics enabled, run real GitHub Actions job, verify metrics reflect actual job execution. Validate: `github_runner_jobs_total` increments, `github_runner_job_duration_seconds` updates, `github_runner_status` shows online.

- **TEST-006**: **Multi-Runner Metrics** - Deploy 3 concurrent runners (standard, chrome, chrome-go), verify each exposes unique metrics on different ports with correct `runner_name` and `runner_type` labels.

- **TEST-007**: **Metrics Persistence** - Stop runner container, verify `/tmp/jobs.log` persists via volume mount, restart container, verify job counts maintained across restart.

- **TEST-008**: **Prometheus Scraping** - Configure Prometheus to scrape test runners, verify targets are up, metrics are ingested, queries return expected data.

- **TEST-009**: **Grafana Dashboard Integration** - Import dashboard JSON into Grafana, connect to Prometheus datasource, verify all panels display data without errors, test variable filters.

### Performance Tests

- **TEST-010**: **CPU Overhead Measurement** - Measure runner CPU usage with and without metrics collection over 1-hour period. Verify overhead <1% (e.g., 50% → 50.5% CPU usage).

- **TEST-011**: **Memory Overhead Measurement** - Measure runner memory usage with and without metrics collection. Verify overhead <50MB (use `docker stats` command).

- **TEST-012**: **Metrics Endpoint Response Time** - Benchmark HTTP response time for `GET /metrics` request. Verify p95 <100ms over 1000 requests.

- **TEST-013**: **Metrics Update Frequency** - Measure actual metrics update interval. Verify 30s ±2s by observing `github_runner_uptime_seconds` timestamps.

- **TEST-014**: **Dashboard Query Performance** - Benchmark all Grafana dashboard queries with 7 days of data (simulated). Verify all panels load in <2s.

### Security Tests

- **TEST-015**: **Sensitive Data Exposure** - Audit all exposed metrics to ensure no tokens, credentials, or sensitive environment variables are included. Scan metric output for patterns like `GITHUB_TOKEN`, `PAT`, `password`.

- **TEST-016**: **Container Vulnerability Scan** - Run Trivy/Grype scan on updated Docker images to ensure no new vulnerabilities introduced by metrics scripts.

- **TEST-017**: **Network Port Exposure** - Verify port 9091 is only exposed to container network by default (not `0.0.0.0:9091` unless explicitly configured by user).

### User Acceptance Tests

- **TEST-018**: **Setup Documentation Validation** - New user follows `PROMETHEUS_SETUP.md` step-by-step on clean system. Measure time to complete setup. Verify <15 minutes and successful metrics collection.

- **TEST-019**: **Dashboard Usability** - Non-technical user imports Grafana dashboards and interprets visualizations. Verify dashboards answer key questions: "Are runners healthy?", "How many jobs succeeded?", "What's our deployment frequency?".

- **TEST-020**: **Troubleshooting Guide Effectiveness** - Intentionally introduce common issues (port conflict, missing scrape config, wrong datasource). Verify troubleshooting guide resolves issues without external help.

## 7. Risks & Assumptions

### Risks

- **RISK-001**: **Netcat Availability** - Risk: `nc` command may not be available or have different syntax on some base images. Mitigation: Verify `nc` is installed in ubuntu:questing base image. Document netcat installation if needed. Consider `socat` as fallback.

- **RISK-002**: **Log Parsing Brittleness** - Risk: GitHub Actions runner log format changes could break job tracking. Mitigation: Use defensive parsing with error handling. Document log format dependencies. Provide fallback to basic metrics if parsing fails.

- **RISK-003**: **Port Conflicts** - Risk: Port 9091 may be used by other services. Mitigation: Make port configurable via `METRICS_PORT` environment variable. Document port conflict resolution in troubleshooting guide.

- **RISK-004**: **Performance Degradation** - Risk: Metrics collection may exceed 1% CPU overhead under high load. Mitigation: Benchmark under realistic workloads. Provide option to disable metrics via environment variable. Optimize collector script.

- **RISK-005**: **Storage Growth** - Risk: `/tmp/jobs.log` may grow unbounded over time. Mitigation: Implement log rotation (keep last 10,000 jobs). Document cleanup procedure. Consider using circular buffer.

- **RISK-006**: **Dashboard Compatibility** - Risk: Grafana version differences may cause dashboard JSON import failures. Mitigation: Test dashboards on Grafana v8, v9, v10. Document minimum required version. Use stable dashboard schema.

- **RISK-007**: **User Configuration Errors** - Risk: Users may misconfigure Prometheus scrape targets or Grafana datasource. Mitigation: Provide detailed examples with copy-paste configurations. Add troubleshooting section for common errors. Provide validation script.

### Assumptions

- **ASSUMPTION-001**: **External Prometheus Exists** - Assumes users have access to a Prometheus server they can configure. If not, recommend Prometheus deployment as prerequisite in documentation.

- **ASSUMPTION-002**: **External Grafana Exists** - Assumes users have Grafana instance with permissions to import dashboards and add datasources. If not, recommend Grafana deployment in documentation.

- **ASSUMPTION-003**: **Network Connectivity** - Assumes Prometheus server can reach runner containers on port 9091 (same Docker network or routable network). Document network configuration requirements.

- **ASSUMPTION-004**: **Runner Job Logs Accessible** - Assumes GitHub Actions runner outputs logs to stdout/stderr that can be parsed. If runner binary changes log format, parsing may break.

- **ASSUMPTION-005**: **Bash Availability** - Assumes bash 4+ is available in ubuntu:questing base image for script execution.

- **ASSUMPTION-006**: **Container Restart Tolerance** - Assumes users accept brief metrics gaps during container restarts (30-60 seconds).

- **ASSUMPTION-007**: **No Multi-Architecture Yet** - Assumes initial implementation is x86_64 only. ARM64 support requires testing netcat compatibility (future enhancement).

- **ASSUMPTION-008**: **Persistent Volumes** - Assumes users mount `/tmp/jobs.log` as volume for persistence. Document volume mount requirement in setup guide.

## 8. Related Specifications / Further Reading

### Internal Documentation

- [PROMETHEUS_IMPROVEMENTS.md](/Users/grammatonic/Git/github-runner/docs/features/PROMETHEUS_IMPROVEMENTS.md) - Original feature specification (scope, objectives, timeline)
- [Performance Optimization Instructions](/Users/grammatonic/Git/github-runner/.github/instructions/performance-optimization.instructions.md) - Performance guidelines for metrics overhead validation
- [DevOps Core Principles](/Users/grammatonic/Git/github-runner/.github/instructions/devops-core-principles.instructions.md) - CALMS framework and DORA metrics background
- [Containerization Best Practices](/Users/grammatonic/Git/github-runner/.github/instructions/containerization-docker-best-practices.instructions.md) - Docker optimization guidelines

### External Resources

- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/) - Official Prometheus documentation
- [Prometheus Exposition Formats](https://prometheus.io/docs/instrumenting/exposition_formats/) - Metric format specification
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/best-practices/) - Dashboard design guidelines
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/) - Query language reference
- [DORA Metrics Guide](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance) - DORA metrics definitions and best practices
- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners) - Official runner documentation
- [Netcat Tutorial](https://www.varonis.com/blog/netcat-commands) - Netcat HTTP server examples
- [OpenMetrics Specification](https://github.com/OpenObservability/OpenMetrics/blob/main/specification/OpenMetrics.md) - Prometheus-compatible metric format

### Related GitHub Issues/PRs

- (To be added as PRs are created during implementation)
