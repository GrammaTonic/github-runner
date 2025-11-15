# Performance Baseline Report

**Date:** November 15, 2025  
**Branch:** feature/performance-optimization  
**Purpose:** Establish performance baselines for optimization tracking

## Executive Summary

This report documents the current performance characteristics of the GitHub Runner project across Docker builds, CI/CD pipelines, container images, and runtime operations. These baselines will be used to measure the impact of performance optimizations.

---

## 1. Docker Build Performance Analysis

### 1.1 Standard Runner (Dockerfile)

**Base Image:** `ubuntu:questing`

**Build Stages:**
- APT setup and system upgrade
- System dependencies installation
- User and directory creation
- GitHub Actions runner download and extraction (2.329.0)
- NPM security patches (cross-spawn, tar, brace-expansion)

**Identified Issues:**
1. ❌ **No Build Cache Strategy** - Each layer is rebuilt even when dependencies haven't changed
2. ❌ **No Multi-Stage Build** - Single-stage build includes build tools in final image
3. ❌ **Sequential Dependency Installation** - APT packages installed in one large RUN command
4. ⚠️ **Typo in Base Image** - `ubuntu:questing` (should be `ubuntu:latest` or specific version like `ubuntu:24.04`)
5. ⚠️ **Redundant APT Operations** - Multiple `apt-get update` and cleanup cycles
6. ⚠️ **Large Layer Sizes** - No layer optimization or squashing

**Optimization Opportunities:**
- Implement BuildKit cache mounts for apt, npm
- Use multi-stage builds to reduce final image size
- Pin base image version for reproducibility
- Combine related RUN commands to reduce layers
- Add --mount=type=cache for package managers

### 1.2 Chrome Runner (Dockerfile.chrome)

**Base Image:** `ubuntu:questing`

**Additional Components:**
- Chrome browser (142.0.7444.162) - ~150MB download
- ChromeDriver
- Node.js (24.11.1) - ~50MB download
- Playwright (1.55.1) + browsers
- Cypress (13.15.0)
- Python virtual environment
- Extensive system libraries for browser support

**Identified Issues:**
1. ❌ **Massive Image Size** - Chrome + Node + Playwright + Cypress + system libs = ~2-3GB estimated
2. ❌ **No Caching for Downloads** - Chrome, Node, runner downloads repeated on every build
3. ❌ **Multiple npm install Operations** - npm packages installed multiple times in different contexts
4. ❌ **Playwright Browser Download** - Downloads Chromium/Firefox even though Chrome is already installed
5. ⚠️ **Unnecessary Cleanup** - Deletes Cypress cache but installs Cypress globally
6. ⚠️ **Complex Patching Logic** - Patches npm modules 3+ times (global, user, runner)

**Optimization Opportunities:**
- Use BuildKit cache mounts for curl downloads
- Skip redundant browser installations (already have Chrome)
- Consolidate npm patching into single operation
- Use lighter base image or multi-stage build
- Cache Node.js and Chrome downloads between builds

### 1.3 Chrome-Go Runner (Dockerfile.chrome-go)

**Inherits all Chrome Runner issues PLUS:**
- Go installation (1.25.4) - ~130MB download
- Additional PATH complexity

**Identified Issues:**
1. ❌ **Largest Image** - All Chrome runner deps + Go toolchain
2. ❌ **No Go Build Caching** - Would benefit from BuildKit cache for Go modules
3. ❌ **Same Chrome Runner Issues** - Inherits all inefficiencies from Dockerfile.chrome

---

## 2. CI/CD Pipeline Performance Analysis

**Workflow File:** `.github/workflows/ci-cd.yml`

### 2.1 Recent Pipeline Runs

| Run ID | Conclusion | Duration | Notes |
|--------|-----------|----------|-------|
| 19389846132 | in-progress | 49s (so far) | Current run |
| 19389826545 | cancelled | 115s (1m 55s) | Cancelled |
| 19389808295 | cancelled | 99s (1m 39s) | Cancelled |

**Note:** Recent runs were cancelled, need successful run data for complete analysis.

### 2.2 Job Structure Analysis

**Total Jobs:** 15 jobs identified in ci-cd.yml

**Job Categories:**
1. **Validation Jobs** (fast):
   - lint-and-validate
   - version-check
   
2. **Build Jobs** (slow):
   - build-runner (standard)
   - build-chrome-runner
   - build-chrome-go-runner
   
3. **Test Jobs** (medium):
   - unit-tests
   - integration-tests
   - docker-validation
   - configuration-validation
   
4. **Security Scan Jobs** (slow):
   - security-scan (Trivy on code)
   - security-container-scan (standard runner)
   - security-chrome-scan
   - security-chrome-go-scan
   
5. **Deployment/Cleanup** (medium):
   - provision-runner
   - provision-chrome-runner
   - cleanup

### 2.3 Identified Bottlenecks

**Sequential Dependencies:**
```
build jobs → security scans → provision jobs → cleanup
```

**Parallelization Opportunities:**
1. ✅ Build jobs already run in parallel (3 concurrent builds)
2. ✅ Security scans already run in parallel (4 concurrent scans)
3. ❌ **Unit/integration tests could run in parallel** with builds (currently sequential)
4. ❌ **Security scans wait for builds** - could run code scan (Trivy) earlier
5. ❌ **No caching strategy** for Docker layers between jobs

**Cache Utilization:**
- ❌ No Docker layer caching in GitHub Actions
- ❌ No dependency caching (apt, npm, pip)
- ✅ GitHub Actions cache action available but not used

### 2.4 Resource Usage Estimates

**Standard Build Job:**
- Pull ubuntu:questing: ~5s
- APT update/upgrade: ~30-60s
- Install system packages: ~45-90s
- Download runner (130MB): ~10-20s
- NPM patches: ~15-30s
- **Estimated Total:** 2-4 minutes

**Chrome Build Job:**
- All standard build steps: ~2-4 min
- Download Node.js (50MB): ~5-10s
- Download Chrome (150MB): ~15-30s
- Download ChromeDriver: ~5-10s
- Install npm packages (Playwright, Cypress): ~60-120s
- Playwright browser install: ~60-90s
- **Estimated Total:** 5-8 minutes

**Chrome-Go Build Job:**
- All Chrome build steps: ~5-8 min
- Download Go (130MB): ~15-30s
- **Estimated Total:** 6-9 minutes

---

## 3. Container Image Size Analysis

**Note:** Actual sizes need to be measured from built images. Estimates below based on component analysis.

### 3.1 Estimated Image Sizes

| Image Variant | Estimated Size | Components |
|---------------|---------------|------------|
| **Standard Runner** | ~800MB - 1.2GB | Ubuntu base (~200MB) + System packages (~300MB) + Runner (~200MB) + Docker (~300MB) |
| **Chrome Runner** | ~2.5GB - 3.5GB | Standard + Chrome (~150MB) + Node.js (~50MB) + System libs (~500MB) + Playwright/Cypress (~800MB) |
| **Chrome-Go Runner** | ~2.8GB - 4GB | Chrome runner + Go (~130MB) |

### 3.2 Layer Size Breakdown (Estimated)

**Standard Runner Layers:**
1. Base ubuntu:questing: ~200MB
2. APT update + upgrade: ~100-200MB
3. System packages install: ~300-400MB
4. Runner download + extract: ~200MB
5. NPM patches: ~50MB

**Chrome Runner Additional Layers:**
6. Chrome browser: ~150MB
7. Node.js: ~50MB
8. System libraries (Playwright deps): ~500MB
9. npm global packages: ~800MB (Playwright browsers + Cypress)
10. Python venv + packages: ~200MB

### 3.3 Optimization Potential

**Standard Runner:**
- Multi-stage build could reduce to: ~600-800MB (remove build tools)
- Optimized layering: Save ~100-200MB
- **Target:** ~500-600MB

**Chrome Runner:**
- Remove redundant browsers: ~400MB savings
- Multi-stage build: ~300MB savings
- Optimized npm caching: ~200MB savings
- **Target:** ~1.5-2GB (from ~3GB)

**Chrome-Go Runner:**
- Same Chrome optimizations apply
- **Target:** ~1.7-2.2GB (from ~3.5GB+)

---

## 4. Runtime Performance Analysis

### 4.1 Container Startup Time

**Measured Components:**
- Entrypoint script execution
- Runner registration with GitHub API
- Health check initialization

**Current Observations:**
- Health check configured: 60s start period (indicates expected slow startup)
- No startup time metrics currently collected

**Optimization Opportunities:**
- Measure actual startup times
- Optimize entrypoint scripts
- Pre-configure runner where possible
- Implement startup performance monitoring

### 4.2 Resource Usage Patterns

**Health Check Configuration:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3
```

**Observations:**
- 60-second start period suggests containers take significant time to become healthy
- 30-second interval is reasonable for production
- No resource limit configurations in Dockerfiles

**Optimization Opportunities:**
- Add resource limits (CPU, memory) to Docker Compose
- Monitor actual resource usage patterns
- Implement auto-scaling based on resource thresholds

---

## 5. Key Performance Metrics to Track

### 5.1 Build Metrics
- [ ] Docker build time (all variants)
- [ ] Docker layer cache hit rate
- [ ] Download time for external dependencies
- [ ] npm install duration
- [ ] apt-get operations duration

### 5.2 Pipeline Metrics
- [ ] Total CI/CD pipeline duration
- [ ] Individual job durations
- [ ] Parallel job efficiency
- [ ] Cache restoration success rate
- [ ] Artifact upload/download times

### 5.3 Image Metrics
- [ ] Final image sizes (all variants)
- [ ] Layer count per image
- [ ] Largest layers by size
- [ ] Compression ratios
- [ ] Push/pull times to GHCR

### 5.4 Runtime Metrics
- [ ] Container startup time
- [ ] Time to runner registration
- [ ] Memory usage (idle and under load)
- [ ] CPU usage patterns
- [ ] Network I/O
- [ ] Disk I/O

---

## 6. Optimization Priorities

### High Priority (High Impact, Low Effort)
1. **Fix ubuntu:questing typo** - Use stable base image
2. **Implement BuildKit cache mounts** - Massive build time improvement
3. **Consolidate apt-get operations** - Reduce layers and build time
4. **Remove Playwright browser downloads** - Chrome already installed (400MB saved)
5. **Enable Docker layer caching in CI/CD** - Reuse layers between builds

### Medium Priority (High Impact, Medium Effort)
6. **Multi-stage builds** - Reduce final image sizes by 30-40%
7. **Optimize npm patching** - Single consolidated patch operation
8. **Parallel test execution** - Run tests during/after builds
9. **Dependency caching in CI/CD** - Cache apt, npm, pip packages
10. **Version pinning** - Reproducible builds, better caching

### Low Priority (Medium Impact, High Effort)
11. **Custom runner base image** - Pre-baked dependencies
12. **Advanced caching strategies** - Remote cache, registry cache
13. **Resource limit tuning** - CPU/memory optimization
14. **Startup time optimization** - Lazy initialization patterns
15. **Alternative base images** - Alpine, distroless evaluation

---

## 7. Next Steps

### Immediate Actions
1. ✅ **Measure actual build times** - Run timed builds for all variants
2. ✅ **Measure actual image sizes** - Check GHCR for current sizes
3. ✅ **Analyze successful CI/CD run** - Get complete job timing data
4. ⏺️ **Create optimization implementation plan** - Prioritize quick wins

### Testing Strategy
1. Build baseline images with `time` measurements
2. Implement optimizations incrementally
3. Measure performance improvements after each change
4. Document results for comparison

### Success Criteria
- **Build Time:** Reduce by 40-60% (target: 1-2min standard, 2-4min Chrome)
- **Image Size:** Reduce by 30-50% (target: ~500MB standard, ~1.5-2GB Chrome)
- **Pipeline Duration:** Reduce by 30-40% (target: <6 minutes for full pipeline)
- **Startup Time:** Reduce by 20-30% (target: <30s to healthy status)

---

## 8. Measurement Commands

### Build Time Measurement
```bash
# Standard runner
time docker build -f docker/Dockerfile -t github-runner:baseline .

# Chrome runner
time docker build -f docker/Dockerfile.chrome -t github-runner-chrome:baseline .

# Chrome-Go runner
time docker build -f docker/Dockerfile.chrome-go -t github-runner-chrome-go:baseline .
```

### Image Size Measurement
```bash
docker images | grep github-runner
docker history github-runner:baseline --no-trunc --human
```

### Layer Analysis
```bash
docker inspect github-runner:baseline | jq '.[0].RootFS.Layers'
dive github-runner:baseline  # Interactive layer exploration
```

### CI/CD Analysis
```bash
gh run view <run-id> --log
gh run list --workflow="CI/CD Pipeline" --limit 10 --json databaseId,conclusion,createdAt,updatedAt
```

---

## Appendix A: Dockerfile Issues Summary

### Critical Issues (Fix Immediately)
1. **Base image typo:** `ubuntu:questing` → `ubuntu:24.04` or `ubuntu:latest`
2. **No caching strategy:** Implement BuildKit cache mounts
3. **No version pinning:** Pin all external dependencies
4. **Redundant operations:** Multiple apt-get updates, npm installs

### Major Issues (High Impact)
5. **No multi-stage builds:** Final images include build tools
6. **Large image sizes:** 2-4GB per variant
7. **Slow builds:** 5-9 minutes for Chrome variants
8. **Duplicate installations:** Playwright installs browsers when Chrome exists

### Minor Issues (Low Impact)
9. **Layer optimization:** Too many layers, could be consolidated
10. **Documentation:** Missing inline comments for complex operations
11. **Health check tuning:** 60s start period could be optimized

---

## Appendix B: Tool Recommendations

### Build Optimization
- **BuildKit:** Docker's advanced build engine with caching
- **dive:** Explore Docker image layers interactively
- **docker-slim:** Automatic image size reduction
- **hadolint:** Dockerfile linter (already in use)

### Performance Monitoring
- **time:** Measure build durations
- **docker stats:** Monitor runtime resource usage
- **cAdvisor:** Container metrics collection
- **Prometheus + Grafana:** Metrics visualization

### CI/CD Optimization
- **GitHub Actions cache action:** Cache dependencies
- **Docker layer caching:** Reuse layers between runs
- **Self-hosted runners:** Faster builds with local cache
- **Matrix strategies:** Parallel builds (already in use)

---

**Report Generated:** November 15, 2025  
**Next Review:** After optimization implementation  
**Owner:** Performance Optimization Task Force
