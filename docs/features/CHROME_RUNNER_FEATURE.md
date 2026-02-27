- **Architecture Enforcement**: Chrome runner image only supports `linux/amd64` (x86_64). ARM builds are blocked at build time. Base image is now `ubuntu:resolute` (25.10 pre-release) for latest browser support.

# Chrome Runner Feature Branch

## 🚀 Feature Overview

This feature branch implements a **specialized Chrome runner** for GitHub Actions self-hosted runners, optimized for web UI testing and browser automation.

## 📁 Files Added/Modified

### New Files Created

1. **`docker/Dockerfile.chrome`** - Specialized Docker image for Chrome testing

   - Pre-installed Chrome, ChromeDriver, Node.js, Python
   - Optimized for headless browser testing
   - Includes Playwright, Cypress, and Selenium frameworks

2. **`docker/entrypoint-chrome.sh`** - Chrome runner entrypoint script

   - Chrome environment setup and validation
   - Virtual display (Xvfb) configuration
   - Performance optimizations for CI/CD

3. **`docker/docker-compose.chrome.yml`** - Docker Compose for Chrome runners

   - Resource limits (4GB RAM, 2 CPUs)
   - Persistent volumes for caching
   - Health checks and auto-restart policies

4. **`scripts/build-chrome.sh`** - Chrome runner build automation

   - Multi-architecture support (amd64/arm64)
   - Registry push automation
   - Image validation and testing

5. **`config/chrome-runner.env.example`** - Environment configuration template

   - Chrome-specific environment variables
   - Performance tuning parameters
   - Testing framework configurations

6. **`../../docs/chrome-runner.md`** - Comprehensive documentation
   - Quick start guide
   - Testing framework examples
   - Troubleshooting and optimization tips

### Modified Files

1. **`../../.github/workflows/ci-cd.yml`** - Enhanced CI/CD pipeline

   - Added `build-chrome` job for Chrome runner builds
   - Added `security-chrome-scan` for Chrome image security scanning
   - Added `chrome-runner` test matrix for validation
   - Updated deployment dependencies

2. **`.github/copilot-instructions.md`** - Enhanced with Chrome runner guidance
   - Performance optimization strategies
   - Web UI testing recommendations
   - Browser container isolation techniques

## 🎯 Key Features Implemented

### Browser Testing Ready

- ✅ **Google Chrome Stable** with latest security updates
- ✅ **ChromeDriver** automatically matched to Chrome version
- ✅ **Virtual Display (Xvfb)** for headless GUI applications
- ✅ **Optimized Chrome flags** for CI/CD performance

### Testing Frameworks

- ✅ **Playwright** - Microsoft's modern browser automation
- ✅ **Cypress** - JavaScript end-to-end testing framework
- ✅ **Selenium** - Industry standard web automation
- ✅ **Node.js 20** - For npm-based testing tools
- ✅ **Python 3** - For Python-based testing frameworks

### Performance Optimizations

- ✅ **Resource Limits** - 4GB memory, 2 CPU cores by default
- ✅ **Shared Memory** - 2GB for Chrome processes
- ✅ **Cache Volumes** - Persistent storage for dependencies
- ✅ **Multi-instance Scaling** - Parallel test execution

### CI/CD Integration

- ✅ **Automated Builds** - Multi-architecture Docker images
- ✅ **Security Scanning** - Trivy vulnerability scans
- ✅ **Testing Pipeline** - Validation of Chrome environment
- ✅ **Registry Publishing** - GitHub Container Registry

## 🔧 Quick Start Commands

### Build Chrome Runner

```bash
# Build locally
./scripts/build-chrome.sh

# Build and push to registry
./scripts/build-chrome.sh --push

# Build multi-architecture
./scripts/build-chrome.sh --multi-arch --push
```

### Run Chrome Runner

```bash
# With Docker Compose
GITHUB_TOKEN=<token> GITHUB_REPOSITORY=<repo> \
docker-compose -f docker/docker-compose.chrome.yml up -d

# Scale to multiple runners
docker-compose -f docker/docker-compose.chrome.yml up -d --scale chrome-runner=3

# With Docker CLI
docker run -d --shm-size=2g \
  -e GITHUB_TOKEN=<token> \
  -e GITHUB_REPOSITORY=<repo> \
  ghcr.io/grammatonic/github-runner:chrome-latest
```

### Use in GitHub Actions

```yaml
jobs:
        run: npx playwright test
```
 
- ✅ **Chrome Dockerfile validation** - Docker build syntax checks
- ✅ **Docker Compose validation** - Configuration file validation
- ✅ **Build script testing** - Shell script syntax validation
- ✅ **Environment template validation** - Required variables check
- ✅ **Security scanning** - Container vulnerability assessment

### Manual Testing Performed

- ✅ **Chrome installation verification** - Browser starts correctly
- ✅ **ChromeDriver compatibility** - Driver matches Chrome version
- ✅ **Testing framework availability** - Playwright, Cypress, Selenium work
- ✅ **Virtual display functionality** - Xvfb runs headless applications
- ✅ **Resource limits** - Memory and CPU constraints enforced

## 🔒 Security Enhancements

- ✅ **Non-root user execution** - Chrome runs as unprivileged `runner` user
- ✅ **Container security scanning** - Trivy scans for vulnerabilities
- ✅ **Minimal attack surface** - Only essential packages installed
- ✅ **Seccomp profile** - Required for Chrome sandboxing
- ✅ **Resource constraints** - Memory and CPU limits prevent abuse

## 📈 Performance Benchmarks

### Resource Usage

- **Base Image Size**: ~2.5GB (optimized multi-stage build)
- **Memory Usage**: 1-4GB depending on test complexity
- **CPU Usage**: 1-2 cores for typical browser testing
- **Startup Time**: ~30-60 seconds (including Chrome validation)

### Scaling Capabilities

- **Horizontal Scaling**: Supports multiple parallel runners
- **Test Parallelization**: Each runner can execute tests independently
- **Cache Efficiency**: Persistent volumes reduce dependency download time
- **Resource Isolation**: Containers prevent test interference

## 🚀 Deployment Strategy

### Development Environment

```bash
# Quick local testing
./scripts/build-chrome.sh
docker-compose -f docker/docker-compose.chrome.yml up -d
```

### Production Environment

```bash
# Multi-architecture build and push
./scripts/build-chrome.sh --multi-arch --push

# Deploy with monitoring
docker-compose -f docker/docker-compose.chrome.yml up -d --scale chrome-runner=5
```

## 📝 Next Steps

1. **Merge to develop** - Integrate Chrome runner with main codebase
2. **Production testing** - Validate with real web UI test suites
3. **Performance tuning** - Optimize resource allocation based on usage
4. **Documentation updates** - Update wiki with Chrome runner examples
5. **Monitoring integration** - Add Chrome-specific health checks

## 🔗 Related Documentation

- [Chrome Runner Documentation](../../docs/chrome-runner.md)
- [Main Project README](../README.md)
- [Docker Configuration Guide](../../wiki-content/Docker-Configuration.md)
- [CI/CD Pipeline Documentation](../../.github/workflows/ci-cd.yml)

---

**Branch Status**: ✅ Ready for review and merge
**Testing Status**: ✅ All automated tests passing
**Documentation Status**: ✅ Complete with examples
**Security Status**: ✅ Vulnerability scans clean
