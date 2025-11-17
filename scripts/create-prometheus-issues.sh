#!/bin/bash
set -euo pipefail

# GitHub Issue Creation Script for Prometheus Monitoring Implementation
# Creates 7 phase-based issues from feature-prometheus-monitoring-1.md

echo "🚀 Creating GitHub Issues for Prometheus Monitoring Implementation"
echo "=================================================================="
echo ""

# Phase 1: Custom Metrics Endpoint - Standard Runner
echo "📝 Creating Phase 1 Issue..."
gh issue create \
  --title "[Feature] Phase 1: Custom Metrics Endpoint - Standard Runner" \
  --label "enhancement,monitoring,prometheus,phase-1" \
  --body-file - <<'EOF'
## 📊 Phase 1: Custom Metrics Endpoint - Standard Runner

**Timeline:** Week 1 (2025-11-18 to 2025-11-23)
**Status:** 🚧 Ready to Start
**Goal:** Implement custom metrics endpoint on port 9091 for standard runner type with job tracking and basic metrics

### 🎯 Objectives
- Expose Prometheus metrics on port 9091
- Implement job tracking via `/tmp/jobs.log`
- Create metrics HTTP server using netcat
- Integrate metrics collection into runner lifecycle

### ✅ Tasks (12 Total)

- [ ] **TASK-001**: Create metrics HTTP server script (`/tmp/metrics-server.sh`) using netcat that listens on port 9091 and serves `/tmp/runner_metrics.prom` file in Prometheus text format
- [ ] **TASK-002**: Create metrics collector script (`/tmp/metrics-collector.sh`) that updates metrics every 30 seconds by reading `/tmp/jobs.log` and system stats
- [ ] **TASK-003**: Initialize `/tmp/jobs.log` file in `docker/entrypoint.sh` with touch command before runner starts
- [ ] **TASK-004**: Integrate metrics server and collector into `docker/entrypoint.sh` by adding background process launches
- [ ] **TASK-005**: Add `EXPOSE 9091` directive to `docker/Dockerfile` to document the metrics port
- [ ] **TASK-006**: Update `docker/docker-compose.production.yml` to expose port 9091 with mapping `"9091:9091"`
- [ ] **TASK-007**: Add environment variables `RUNNER_TYPE=standard` and `METRICS_PORT=9091` to compose file
- [ ] **TASK-008**: Build standard runner image with BuildKit: `docker build -t github-runner:metrics-test -f docker/Dockerfile docker/`
- [ ] **TASK-009**: Deploy test runner: `docker-compose -f docker/docker-compose.production.yml up -d`
- [ ] **TASK-010**: Validate metrics endpoint responds: `curl http://localhost:9091/metrics` returns HTTP 200
- [ ] **TASK-011**: Verify metrics update every 30 seconds by observing `github_runner_uptime_seconds` increment
- [ ] **TASK-012**: Test job logging by manually appending to `/tmp/jobs.log` and verifying metrics increment

### 📋 Acceptance Criteria
- ✅ Metrics endpoint responds on port 9091 with valid Prometheus format
- ✅ Metrics include: `github_runner_status`, `github_runner_jobs_total`, `github_runner_uptime_seconds`, `github_runner_info`
- ✅ Metrics update every 30 seconds automatically
- ✅ Job log tracking works correctly
- ✅ All tests pass with <1% CPU overhead

### 🔗 Dependencies
- Technical spike SPIKE-001 (APPROVED) - netcat-based approach validated
- Implementation plan: `/plan/feature-prometheus-monitoring-1.md`

### 📚 References
- [Spike Document](/plan/spike-metrics-collection-approach.md)
- [Implementation Plan](/plan/feature-prometheus-monitoring-1.md)
- [Prometheus Format Spec](https://prometheus.io/docs/instrumenting/exposition_formats/)

---
**Part of:** Prometheus Monitoring Implementation (v2.3.0)
EOF

echo "✅ Phase 1 Issue Created"
echo ""

# Phase 2: Chrome & Chrome-Go Runners
echo "📝 Creating Phase 2 Issue..."
gh issue create \
  --title "[Feature] Phase 2: Custom Metrics Endpoint - Chrome & Chrome-Go Runners" \
  --label "enhancement,monitoring,prometheus,phase-2,chrome" \
  --body-file - <<'EOF'
## 📊 Phase 2: Custom Metrics Endpoint - Chrome & Chrome-Go Runners

**Timeline:** Week 2 (2025-11-23 to 2025-11-30)
**Status:** ⏳ Blocked by Phase 1
**Goal:** Extend metrics endpoint to Chrome and Chrome-Go runner types with identical functionality

### 🎯 Objectives
- Integrate metrics into Chrome runner variant
- Integrate metrics into Chrome-Go runner variant
- Configure unique port mappings to avoid conflicts (9092, 9093)
- Test concurrent multi-runner deployment

### ✅ Tasks (14 Total)

- [ ] **TASK-013**: Integrate metrics server and collector scripts into `docker/entrypoint-chrome.sh`
- [ ] **TASK-014**: Add `EXPOSE 9091` to `docker/Dockerfile.chrome`
- [ ] **TASK-015**: Add `EXPOSE 9091` to `docker/Dockerfile.chrome-go`
- [ ] **TASK-016**: Update `docker/docker-compose.chrome.yml` to expose port 9091 with unique host port mapping `"9092:9091"`
- [ ] **TASK-017**: Update `docker/docker-compose.chrome-go.yml` to expose port 9091 with unique host port mapping `"9093:9091"`
- [ ] **TASK-018**: Add environment variables `RUNNER_TYPE=chrome` and `METRICS_PORT=9091` to chrome compose file
- [ ] **TASK-019**: Add environment variables `RUNNER_TYPE=chrome-go` and `METRICS_PORT=9091` to chrome-go compose file
- [ ] **TASK-020**: Build Chrome runner: `docker build -t github-runner:chrome-metrics-test -f docker/Dockerfile.chrome docker/`
- [ ] **TASK-021**: Build Chrome-Go runner: `docker build -t github-runner:chrome-go-metrics-test -f docker/Dockerfile.chrome-go docker/`
- [ ] **TASK-022**: Deploy Chrome runner: `docker-compose -f docker/docker-compose.chrome.yml up -d`
- [ ] **TASK-023**: Deploy Chrome-Go runner: `docker-compose -f docker/docker-compose.chrome-go.yml up -d`
- [ ] **TASK-024**: Validate Chrome metrics: `curl http://localhost:9092/metrics` returns metrics with `runner_type="chrome"`
- [ ] **TASK-025**: Validate Chrome-Go metrics: `curl http://localhost:9093/metrics` returns metrics with `runner_type="chrome-go"`
- [ ] **TASK-026**: Test concurrent multi-runner deployment with all 3 types and verify unique metrics per runner

### 📋 Acceptance Criteria
- ✅ Chrome runner exposes metrics on port 9092
- ✅ Chrome-Go runner exposes metrics on port 9093
- ✅ All 3 runner types can run concurrently without port conflicts
- ✅ Metrics include correct `runner_type` label for each variant
- ✅ Performance overhead remains <1% CPU per runner

### 🔗 Dependencies
- **BLOCKED BY:** Phase 1 (must complete TASK-001 through TASK-012)

---
**Part of:** Prometheus Monitoring Implementation (v2.3.0)
EOF

echo "✅ Phase 2 Issue Created"
echo ""

# Phase 3: Enhanced Metrics & Job Tracking
echo "📝 Creating Phase 3 Issue..."
gh issue create \
  --title "[Feature] Phase 3: Enhanced Metrics & Job Tracking (DORA)" \
  --label "enhancement,monitoring,prometheus,phase-3,dora-metrics" \
  --body-file - <<'EOF'
## 📊 Phase 3: Enhanced Metrics & Job Tracking (DORA)

**Timeline:** Week 2-3 (2025-11-26 to 2025-12-03)
**Status:** ⏳ Blocked by Phase 2
**Goal:** Add job duration tracking, cache hit rates, and queue time metrics for DORA calculations

### 🎯 Objectives
- Implement job duration histogram with buckets
- Track queue time (job assignment to start)
- Measure cache hit rates (BuildKit, apt, npm)
- Enable DORA metrics calculations

### ✅ Tasks (10 Total)

- [ ] **TASK-027**: Extend `/tmp/jobs.log` format to include: `timestamp,job_id,status,duration_seconds,queue_time_seconds` (CSV format)
- [ ] **TASK-028**: Implement job start/end time tracking by hooking into GitHub Actions runner job lifecycle (via log parsing)
- [ ] **TASK-029**: Update metrics collector to calculate job duration histogram buckets
- [ ] **TASK-030**: Add queue time metric: `github_runner_queue_time_seconds`
- [ ] **TASK-031**: Implement cache hit rate tracking by parsing Docker BuildKit cache logs
- [ ] **TASK-032**: Add cache metrics: `github_runner_cache_hit_rate{cache_type="buildkit|apt|npm"}`
- [ ] **TASK-033**: Update metrics collector script to read cache logs from `/var/log/buildkit.log`
- [ ] **TASK-034**: Test job duration tracking by running actual GitHub Actions workflows
- [ ] **TASK-035**: Validate cache metrics with controlled builds (force cache miss vs cache hit scenarios)
- [ ] **TASK-036**: Document job log format in `docs/features/PROMETHEUS_IMPROVEMENTS.md`

### 📋 Acceptance Criteria
- ✅ Job duration histogram captures p50, p95, p99 durations
- ✅ Queue time accurately reflects time between job assignment and start
- ✅ Cache hit rate metrics track BuildKit, apt, and npm cache performance
- ✅ DORA metrics can be calculated from collected data

### 🔗 Dependencies
- **BLOCKED BY:** Phase 2 (requires metrics infrastructure)

---
**Part of:** Prometheus Monitoring Implementation (v2.3.0)
EOF

echo "✅ Phase 3 Issue Created"
echo ""

# Phase 4: Grafana Dashboards
echo "📝 Creating Phase 4 Issue..."
gh issue create \
  --title "[Feature] Phase 4: Grafana Dashboards" \
  --label "enhancement,monitoring,prometheus,phase-4,grafana,dashboards" \
  --body-file - <<'EOF'
## 📊 Phase 4: Grafana Dashboards

**Timeline:** Week 3-4 (2025-11-30 to 2025-12-10)
**Status:** ⏳ Blocked by Phase 3
**Goal:** Create 4 pre-built Grafana dashboard JSON files for import into user's Grafana instance

### 🎯 Objectives
- Create Runner Overview dashboard (general status and health)
- Create DORA Metrics dashboard (deployment metrics)
- Create Performance Trends dashboard (build times, cache rates)
- Create Job Analysis dashboard (job details and failures)

### ✅ Tasks (10 Total)

- [ ] **TASK-037**: Create `monitoring/grafana/dashboards/runner-overview.json`
- [ ] **TASK-038**: Configure dashboard variables: `runner_name` (multi-select), `runner_type` (multi-select)
- [ ] **TASK-039**: Create `monitoring/grafana/dashboards/dora-metrics.json`
- [ ] **TASK-040**: Create `monitoring/grafana/dashboards/performance-trends.json`
- [ ] **TASK-041**: Create `monitoring/grafana/dashboards/job-analysis.json`
- [ ] **TASK-042**: Add dashboard metadata: title, description, tags, version, refresh interval (15s)
- [ ] **TASK-043**: Test dashboards by importing into local Grafana instance with Prometheus datasource
- [ ] **TASK-044**: Capture screenshots of each dashboard for documentation
- [ ] **TASK-045**: Export final dashboard JSON files with templating variables configured
- [ ] **TASK-046**: Validate all PromQL queries execute in <2 seconds with test data

### 📋 Acceptance Criteria
- ✅ All 4 dashboards import successfully into Grafana v8+
- ✅ Dashboards display real-time data from Prometheus
- ✅ Variables filter panels correctly
- ✅ All PromQL queries execute in <2 seconds
- ✅ Screenshots included in documentation

### 🔗 Dependencies
- **BLOCKED BY:** Phase 3 (requires enhanced metrics)

---
**Part of:** Prometheus Monitoring Implementation (v2.3.0)
EOF

echo "✅ Phase 4 Issue Created"
echo ""

# Phase 5: Documentation & User Guide
echo "📝 Creating Phase 5 Issue..."
gh issue create \
  --title "[Feature] Phase 5: Documentation & User Guide" \
  --label "enhancement,monitoring,prometheus,phase-5,documentation" \
  --body-file - <<'EOF'
## 📊 Phase 5: Documentation & User Guide

**Timeline:** Week 4-5 (2025-12-07 to 2025-12-21)
**Status:** ⏳ Blocked by Phase 4
**Goal:** Provide comprehensive documentation for setup, usage, troubleshooting, and architecture

### 🎯 Objectives
- Create setup guide for Prometheus scraping and Grafana configuration
- Create usage guide with PromQL examples and customization tips
- Create troubleshooting guide for common issues
- Create architecture documentation explaining design decisions
- Update project README with monitoring section

### ✅ Tasks (10 Total)

- [ ] **TASK-047**: Create `docs/features/PROMETHEUS_SETUP.md`
- [ ] **TASK-048**: Create `docs/features/PROMETHEUS_USAGE.md`
- [ ] **TASK-049**: Create `docs/features/PROMETHEUS_TROUBLESHOOTING.md`
- [ ] **TASK-050**: Create `docs/features/PROMETHEUS_ARCHITECTURE.md`
- [ ] **TASK-051**: Update `README.md` with "📊 Monitoring" section
- [ ] **TASK-052**: Update `docs/README.md` with links to all new Prometheus documentation files
- [ ] **TASK-053**: Create example Prometheus scrape configuration YAML snippet in `monitoring/prometheus-scrape-example.yml`
- [ ] **TASK-054**: Document metric definitions in `docs/features/PROMETHEUS_METRICS_REFERENCE.md`
- [ ] **TASK-055**: Add metrics endpoint to API documentation in `docs/API.md` (if applicable)
- [ ] **TASK-056**: Create quickstart guide: `docs/features/PROMETHEUS_QUICKSTART.md`

### 📋 Acceptance Criteria
- ✅ All documentation files created in `/docs/features/` directory
- ✅ Setup guide enables new users to configure monitoring in <15 minutes
- ✅ Troubleshooting guide resolves common issues without external help
- ✅ Architecture documentation explains design decisions clearly
- ✅ README.md updated with monitoring section
- ✅ Example Prometheus scrape config is copy-paste ready

### 🔗 Dependencies
- **BLOCKED BY:** Phase 4 (needs dashboard screenshots)

---
**Part of:** Prometheus Monitoring Implementation (v2.3.0)
EOF

echo "✅ Phase 5 Issue Created"
echo ""

# Phase 6: Testing & Validation
echo "📝 Creating Phase 6 Issue..."
gh issue create \
  --title "[Feature] Phase 6: Testing & Validation" \
  --label "enhancement,monitoring,prometheus,phase-6,testing" \
  --body-file - <<'EOF'
## 📊 Phase 6: Testing & Validation

**Timeline:** Week 5 (2025-12-14 to 2025-12-21)
**Status:** ⏳ Blocked by Phase 5
**Goal:** Validate all functionality, measure performance overhead, and ensure production readiness

### 🎯 Objectives
- Create comprehensive integration tests for metrics endpoint
- Measure performance overhead (CPU, memory, response time)
- Test all runner types under load
- Validate metrics persistence across restarts
- Test multi-runner scaling scenarios
- Security audit for sensitive data exposure

### ✅ Tasks (14 Total)

- [ ] **TASK-057**: Create integration test script `tests/integration/test-metrics-endpoint.sh`
- [ ] **TASK-058**: Create performance test script `tests/integration/test-metrics-performance.sh`
- [ ] **TASK-059**: Test standard runner with metrics under load (10 concurrent jobs)
- [ ] **TASK-060**: Test Chrome runner with metrics under load (5 concurrent browser jobs)
- [ ] **TASK-061**: Test Chrome-Go runner with metrics under load (5 concurrent Go + browser jobs)
- [ ] **TASK-062**: Validate metrics persistence across container restart
- [ ] **TASK-063**: Test scaling scenario: deploy 5 runners simultaneously
- [ ] **TASK-064**: Measure Prometheus storage growth over 7 days with 3 runners
- [ ] **TASK-065**: Validate all Grafana dashboards display data correctly with real runner workloads
- [ ] **TASK-066**: Benchmark dashboard query performance: all panels must load in <2s with 7 days of data
- [ ] **TASK-067**: Security scan: verify no sensitive data in metrics, no new vulnerabilities introduced
- [ ] **TASK-068**: Documentation review: verify all setup steps work for new users (clean install test)
- [ ] **TASK-069**: Update `tests/README.md` with instructions for running metrics integration tests
- [ ] **TASK-070**: Add metrics tests to CI/CD pipeline (`.github/workflows/ci-cd.yml`) if applicable

### 📋 Acceptance Criteria
- ✅ All integration tests pass (HTTP 200, Prometheus format, metrics present)
- ✅ Performance overhead <1% CPU and <50MB memory per runner
- ✅ Metrics endpoint response time <100ms (p95)
- ✅ All runner types tested under realistic load
- ✅ Metrics persist correctly across container restarts
- ✅ Scaling to 5 concurrent runners works without issues
- ✅ No sensitive data exposed in metrics output
- ✅ Documentation validated by clean install test (<15 minutes setup)

### 🔗 Dependencies
- **BLOCKED BY:** Phase 5 (requires complete documentation)

---
**Part of:** Prometheus Monitoring Implementation (v2.3.0)
EOF

echo "✅ Phase 6 Issue Created"
echo ""

# Phase 7: Release Preparation
echo "📝 Creating Phase 7 Issue..."
gh issue create \
  --title "[Feature] Phase 7: Release Preparation (v2.3.0)" \
  --label "enhancement,monitoring,prometheus,phase-7,release" \
  --body-file - <<'EOF'
## 📊 Phase 7: Release Preparation (v2.3.0)

**Timeline:** Week 5 (2025-12-18 to 2025-12-21)
**Status:** ⏳ Blocked by Phase 6
**Goal:** Prepare feature for release, create release notes, and merge to main

### 🎯 Objectives
- Create comprehensive release notes for v2.3.0
- Update VERSION file
- Create pull request from feature branch to develop
- Merge to develop and perform back-sync
- Tag release v2.3.0
- Create GitHub release with dashboard attachments

### ✅ Tasks (10 Total)

- [ ] **TASK-071**: Create release notes in `docs/releases/v2.3.0-prometheus-metrics.md`
- [ ] **TASK-072**: Update `VERSION` file to `2.3.0`
- [ ] **TASK-073**: Create PR from `feature/prometheus-improvements` to `develop`
- [ ] **TASK-074**: Address PR review comments and ensure CI/CD pipeline passes
- [ ] **TASK-075**: Merge PR to `develop` using squash merge strategy
- [ ] **TASK-076**: Perform back-sync from `main` to `develop` after merge (if merging to main)
- [ ] **TASK-077**: Tag release: `git tag -a v2.3.0 -m "Release v2.3.0: Prometheus Metrics & Grafana Dashboards"`
- [ ] **TASK-078**: Push tag: `git push origin v2.3.0`
- [ ] **TASK-079**: Create GitHub release with release notes and dashboard JSON attachments
- [ ] **TASK-080**: Announce feature in project README changelog section

### 📋 Acceptance Criteria
- ✅ Release notes document all features, setup steps, and known issues
- ✅ VERSION file updated to 2.3.0
- ✅ PR created with comprehensive description
- ✅ All CI/CD tests pass
- ✅ PR merged to develop using squash merge
- ✅ Git tag v2.3.0 created and pushed
- ✅ GitHub release created with dashboard JSON files attached
- ✅ README changelog updated with release announcement

### 🔗 Dependencies
- **BLOCKED BY:** Phase 6 (requires all tests passing)
- **COMPLETES:** Prometheus Monitoring Implementation

---
**Part of:** Prometheus Monitoring Implementation (v2.3.0)
**Final Phase** - All 80 tasks complete upon merge
EOF

echo "✅ Phase 7 Issue Created"
echo ""

echo "=================================================================="
echo "✅ SUCCESS: All 7 GitHub Issues Created!"
echo ""
echo "📋 Created Issues:"
echo "  • Phase 1: Custom Metrics Endpoint - Standard Runner (12 tasks)"
echo "  • Phase 2: Chrome & Chrome-Go Runners (14 tasks)"
echo "  • Phase 3: Enhanced Metrics & Job Tracking (10 tasks)"
echo "  • Phase 4: Grafana Dashboards (10 tasks)"
echo "  • Phase 5: Documentation & User Guide (10 tasks)"
echo "  • Phase 6: Testing & Validation (14 tasks)"
echo "  • Phase 7: Release Preparation (10 tasks)"
echo ""
echo "🔗 Next Steps:"
echo "  1. View created issues: gh issue list --label prometheus"
echo "  2. Add to GitHub Project #5: Prometheus Improvements"
echo "  3. Update Issue #1052 with spike findings"
echo "  4. Begin Phase 1 implementation (Week 1: Nov 18-23)"
echo ""
echo "📅 Timeline: 5 weeks (Nov 16 - Dec 21, 2025)"
echo "🎯 Target Release: v2.3.0"
echo "=================================================================="
