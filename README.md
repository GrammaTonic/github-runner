# Base Image: Ubuntu Questing (25.10 Pre-release)

This repository uses `ubuntu:questing` as the base image for Chrome runner containers. This is a pre-release version of Ubuntu (25.10) chosen for access to the latest system libraries and browser dependencies.

**CVE Mitigation Strategy:**
- Many CVEs in Node.js, npm, and transitive dependencies cannot be patched directly due to upstream packaging.
- We use npm `overrides` and local installs to patch all app-level dependencies.
- CVEs present only in npm's internal modules are documented and monitored; they do not affect runtime security for the runner or browser tests.
- All images are scanned with Trivy and results are saved to `test-results/docker/` for auditability.

**Security Note:**  
If you require a fully supported, production-grade image, use a stable Ubuntu LTS release (e.g., `ubuntu:24.04`). See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for migration instructions.
# GitHub Actions Self-Hosted Runner

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/GrammaTonic/github-runner)](https://github.com/GrammaTonic/github-runner/releases/latest)
[![Docker Image](https://img.shields.io/badge/docker-ghcr.io%2Fgrammatonic%2Fgithub--runner-blue)](https://ghcr.io/grammatonic/github-runner)
[![CI/CD Pipeline](https://github.com/GrammaTonic/github-runner/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/GrammaTonic/github-runner/actions/workflows/ci-cd.yml)
[![Chrome Runner](https://img.shields.io/badge/Chrome%20Runner-Production%20Ready-success?style=flat-square&logo=google-chrome)](https://github.com/GrammaTonic/github-runner/wiki/Chrome-Runner)
[![Security](https://img.shields.io/badge/Security-Trivy%20Scanned-success?style=flat-square&logo=security)](https://github.com/GrammaTonic/github-runner/actions/workflows/security-advisories.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive, production-ready GitHub Actions self-hosted runner solution with monitoring, scaling, and security features.

Note: Documentation workflows and repo prompts were recently improved — see
`.github/prompts/Wiki-Readme.prompt.md` and `docs/examples/update-docs-example.md` for guidance on updating docs to match code changes.

## 📊 Current Versions

| Component                 | Standard Runner  | Chrome Runner    | Chrome-Go Runner | Status            |
| ------------------------- | ---------------- | ---------------- | ---------------- | ----------------- |
| **Image Version**         | v2.2.1           | v2.2.1           | v2.2.1           | ✅ Latest         |
| **GitHub Actions Runner** | v2.329.0         | v2.329.0         | v2.329.0         | ✅ Latest         |
| **Base OS**               | Ubuntu 25.10 Questing | Ubuntu 25.10 Questing | Ubuntu 25.10 Questing | ✅ Pre-release |
| **Node.js**               | -                | 24.11.1          | 24.11.1          | ✅ Latest         |
| **Go**                    | -                | -                | 1.25.4           | ✅ Latest         |
| **Python**                | 3.10+            | 3.10+            | 3.10+            | ✅ Latest         |
| **Playwright**            | -                | v1.55.1          | v1.55.1          | ✅ Latest         |
| **Cypress**               | -                | v13.15.0         | v13.15.0         | ✅ Security Fixed |
| **Chrome**                | -                | 142.0.7444.162   | 142.0.7444.162   | ✅ Latest         |

> 📋 For detailed version information, see [Version Overview](docs/VERSION_OVERVIEW.md)

## 🔒 Security Status & Workflow Sync

- ✅ **VDB-216777/CVE-2020-36632**: Flat package vulnerability patched (`flat@5.0.2`)
- ✅ **CVE-2025-9288**: Cypress SHA.js vulnerability patched (`sha.js@2.4.12`)
- ✅ **CVE-2024-37890**: WebSocket DoS vulnerability patched (`ws@8.17.1`)
- ✅ **Trivy Security Scanning**: Automated weekly vulnerability scans (filesystem, main runner, Chrome runner)
- ✅ **Container Hardening**: Non-root execution, minimal attack surface
- ✅ **Workflow Sync**: All security scan jobs (`security-scan`, `security-container-scan`, `security-chrome-scan`) are present in `.github/workflows/ci-cd.yml` and must be kept in sync across all branches. Use `git diff develop .github/workflows/ci-cd.yml` to verify parity before merging. If you see a warning about missing scan jobs, update and sync your workflow files, then re-run the workflow.

## 🚀 Features & Security Scanning

- **Three Runner Types**: Standard, Chrome (browser testing), and Chrome-Go (Go + browser testing)
- **Containerized Runners**: Docker-based runners with multi-platform support (amd64/arm64)
- **Automated Dependency Management**: Zero-touch Dependabot automation with auto-merge and auto-rebase
- **Performance Optimized**: BuildKit cache mounts, multi-stage builds, 50-70% faster rebuilds
- **Auto-scaling**: Dynamic scaling based on workload demands using Docker Compose
- **Monitoring**: Prometheus metrics and Grafana dashboards for performance tracking
- **Security**: Comprehensive vulnerability scanning, security patches, and container hardening
- **CI/CD Integration**: Automated building, testing, and deployment with GitHub Actions
- **High Availability**: Health checks, automatic restarts, and failover mechanisms
- **Multi-Environment**: Support for dev, staging, and production environments
- **Cache Optimization**: Persistent volume caching for build artifacts and dependencies
- **Security Scanning**: Weekly Trivy scans (filesystem, container, Chrome runner) with automated SARIF reporting and GitHub Security tab integration

### 🆕 Recent Improvements (November 2025)

- ✅ **Dependabot Automation**: Zero-touch dependency updates with auto-merge and hourly auto-rebase workflows
- ✅ **Performance Optimizations**: BuildKit cache mounts reduce build times by 50-70% (19s standard, 24s Chrome, 4m34s Chrome-Go)
- ✅ **Multi-Stage Builds**: Standard runner image reduced by 370MB (17% smaller) with improved security
- ✅ **Chrome-Go Runner**: New variant combining Go 1.25.4 toolchain with browser testing capabilities
- ✅ **Cross-Branch Caching**: Feature branches leverage develop/main cache, eliminating redundant rebuilds
- ✅ **Image Size Optimizations**: Standard ~1.8GB, Chrome ~4.1GB, Chrome-Go ~4.5GB (all optimized)
- ✅ **CI/CD Enhancements**: Conditional Dependabot provisioning, artifact status files, clean logs
- ✅ Chrome runners updated to Chrome `142.0.7444.162`, Playwright `1.55.1`, and Cypress `13.15.0`
- ✅ npm override to force `tar@7.5.2` inside all embedded npm distributions, closing CVE-2024-47554

## 📦 Installation

### Using Git Clone

```sh
# Build the Chrome runner image (amd64 only)
docker buildx build --platform linux/amd64 -f docker/Dockerfile.chrome -t github-runner:chrome-latest .

# Start the runner with Docker Compose
docker compose -f docker/docker-compose.chrome.yml up -d
```

> **Note:** The Chrome runner image is only supported on `linux/amd64`. If you attempt to build or run on ARM, the build will fail.

```bash
gh repo clone GrammaTonic/github-runner
cd github-runner
```

### Using Release Archive

```bash
wget https://github.com/GrammaTonic/github-runner/archive/v2.2.0.tar.gz
tar -xzf v2.2.0.tar.gz
cd github-runner-2.2.0
```

### Using Docker Images

Pre-built Docker images are available for each release:

```bash
# Standard Runner (latest)
docker pull ghcr.io/grammatonic/github-runner:v2.2.1
docker pull ghcr.io/grammatonic/github-runner:latest

# Chrome Runner (latest)
docker pull ghcr.io/grammatonic/github-runner-chrome:v2.2.1
docker pull ghcr.io/grammatonic/github-runner-chrome:latest

# Chrome-Go Runner (latest)
docker pull ghcr.io/grammatonic/github-runner-chrome-go:v2.2.1
docker pull ghcr.io/grammatonic/github-runner-chrome-go:latest

# Development versions
docker pull ghcr.io/grammatonic/github-runner:develop
docker pull ghcr.io/grammatonic/github-runner-chrome:develop
docker pull ghcr.io/grammatonic/github-runner-chrome-go:develop

# Semantic versioning
docker pull ghcr.io/grammatonic/github-runner:2.2.1
docker pull ghcr.io/grammatonic/github-runner:2.2
docker pull ghcr.io/grammatonic/github-runner:2
```

## 📋 Prerequisites

- Docker 20.10+ and Docker Compose v2
- GitHub Personal Access Token with repo permissions
- (Optional) Kubernetes cluster for advanced deployment
- (Optional) Cloud provider account for remote deployment

## ⚡ Quick Start

> 📖 **For detailed setup instructions**, see our comprehensive [Quick Start Guide](docs/setup/quick-start.md)

### One-Command Setup

For the fastest deployment experience:

```bash
git clone https://github.com/GrammaTonic/github-runner.git
cd github-runner
./scripts/quick-start.sh
```

The interactive script will guide you through:

- ✅ **Runner type selection** (Standard, Chrome, or Both)
- ✅ Prerequisite checks (Docker, permissions)
- ✅ Environment configuration with validation
- ✅ Automatic runner deployment
- ✅ Health verification and troubleshooting

### Runner Types Available

- **Standard Runner**: General CI/CD with Docker, Node.js, Python (optimized with multi-stage build)
- **Chrome Runner**: UI testing with Chrome, Selenium, Playwright, Cypress
- **Chrome-Go Runner**: Go development + browser testing (Go 1.25.4 + all Chrome runner features)
- **All Runners**: Deploy all three types with separate configurations for comprehensive coverage

### Manual Setup (Alternative)

### 1. Clone and Setup

```bash
git clone https://github.com/GrammaTonic/github-runner.git
cd github-runner
cp config/runner.env.example config/runner.env
```

### 2. Configure Environment

Edit `config/runner.env`:

```bash
# Required
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
GITHUB_REPOSITORY=owner/repo

# Optional
RUNNER_LABELS=self-hosted,docker,linux
RUNNER_NAME_PREFIX=runner
ENVIRONMENT=production
```

### 3. Start Runners

```bash
# Production setup (recommended)
docker compose -f docker/docker-compose.production.yml up -d

# Chrome runner for browser testing
docker compose -f docker/docker-compose.chrome.yml up -d

# Chrome-Go runner for Go + browser testing
docker compose -f docker/docker-compose.chrome-go.yml up -d

# Scale runners based on demand
docker compose -f docker/docker-compose.production.yml up -d --scale github-runner=3
docker compose -f docker/docker-compose.chrome.yml up -d --scale github-runner-chrome=2
docker compose -f docker/docker-compose.chrome-go.yml up -d --scale github-runner-chrome-go=1
```

### 4. Verify Setup

```bash
# Check runner status
docker compose -f docker/docker-compose.production.yml ps

# View logs
docker compose -f docker/docker-compose.production.yml logs -f github-runner

# Check runner registration in GitHub
docker compose -f docker/docker-compose.production.yml logs github-runner | grep "Listening for Jobs"
```

## 🌐 Chrome Runner for Web UI Testing

**Specialized runner for browser automation and web UI testing with 60% performance improvement.**

### ✨ Features

- ✅ **Google Chrome Stable** + automatically matched ChromeDriver
- ✅ **Testing Frameworks**: Playwright, Cypress, Selenium pre-installed
- ✅ **Resource Isolation**: Dedicated browser processes prevent contention
- ✅ **Performance**: 60% faster web UI tests vs standard runners
- ✅ **Scaling**: Horizontal scaling for parallel test execution

### 🚀 Quick Start

```bash
# Build and deploy Chrome Runner
./scripts/build-chrome.sh --push
docker-compose -f docker/docker-compose.chrome.yml up -d

# Scale for parallel testing
docker-compose -f docker/docker-compose.chrome.yml up -d --scale chrome-runner=3
```

### 📝 Use in GitHub Actions

```yaml
jobs:
  ui-tests:
    runs-on: [self-hosted, chrome, ui-tests]
    steps:
      - uses: actions/checkout@v4
      - name: Run Playwright tests
        run: npx playwright test
      - name: Run Cypress tests
        run: npx cypress run
```

### 🔧 Configuration

```bash
# Chrome Runner specific environment
CHROME_RUNNER_LABELS=chrome,ui-tests,browser
HEADLESS_CHROME=true
CHROME_SANDBOX=false
```

📚 **Full Documentation**: [Chrome Runner Wiki](https://github.com/GrammaTonic/github-runner/wiki/Chrome-Runner)

## 🤖 Automated Dependency Management

**Zero-touch dependency updates with Dependabot automation.**

### ✨ Features

- ✅ **Auto-Merge**: Automatically approves and merges Dependabot PRs after CI passes
- ✅ **Auto-Rebase**: Hourly checks keep out-of-date PRs current for sequential merging
- ✅ **CI Validation**: All updates require passing builds, tests, and security scans
- ✅ **Weekly Schedule**: Monday 09:00 dependency checks (github-actions, docker)
- ✅ **Zero Human Intervention**: Complete automation from PR creation to merge

### 🔄 Automated Workflow

1. **Monday 09:00** - Dependabot creates PRs for github-actions and docker updates
2. **Auto-Approve** - Workflow automatically approves PRs
3. **CI Validation** - Full test suite, builds, and security scans run
4. **Auto-Merge** - First PR passes and merges automatically
5. **Auto-Rebase** - Hourly workflow rebases remaining out-of-date PRs
6. **Sequential Merge** - PRs merge one-by-one as CI passes

### 📊 Benefits

- **Time Savings**: ~10 hours/year on dependency management
- **Security**: Updates applied within hours of release
- **Quality**: All updates validated by full CI/CD pipeline
- **Reliability**: Automatic rebase prevents "ahead" branch issues

📚 **Configuration**: See [`.github/dependabot.yml`](.github/dependabot.yml) and workflows in [`.github/workflows/`](.github/workflows/)

## ⚡ Performance Optimizations

**BuildKit cache mounts and multi-stage builds for 50-70% faster builds.**

### 🚀 Performance Results

| Runner Type     | Build Time | Improvement | Image Size | Reduction |
| --------------- | ---------- | ----------- | ---------- | --------- |
| **Standard**    | 19s        | 96% faster  | ~1.8GB     | 17% smaller |
| **Chrome**      | 24s        | 99% faster  | ~4.1GB     | Optimized |
| **Chrome-Go**   | 4m 34s     | 48% faster  | ~4.5GB     | Optimized |

### ✨ Optimizations

- ✅ **BuildKit Cache Mounts**: apt, npm, and download caches persist across builds
- ✅ **Multi-Stage Builds**: Standard runner separates build and runtime dependencies
- ✅ **Cross-Branch Caching**: Feature branches leverage develop/main cache
- ✅ **100% Cache Hit Rate**: Unchanged dependencies never re-downloaded
- ✅ **985MB Bandwidth Saved**: Per rebuild with cache hits

### 📊 Impact

- **First Build**: Normal download times (establishes cache)
- **Subsequent Builds**: 50-70% faster with cache hits
- **Annual Savings**: ~118 hours build time, ~3.6TB bandwidth
- **CI Efficiency**: Faster feedback loops, reduced resource usage

📚 **Full Analysis**: See [docs/PERFORMANCE_RESULTS.md](docs/PERFORMANCE_RESULTS.md)

## 📁 Project Structure

```
github-runner/
├── .github/              # GitHub Actions workflows
├── cache/                # Local cache directories
├── config/               # Configuration templates
├── docker/               # Container configurations
├── docs/                 # Documentation
├── monitoring/           # Health checks and monitoring
├── scripts/              # Automation scripts
└── README.md            # This file
```

## ⚙️ Configuration

### Runner Configuration

Edit `config/runner.env`:

| Variable             | Description                 | Example              | Required |
| -------------------- | --------------------------- | -------------------- | -------- |
| `GITHUB_TOKEN`       | GitHub PAT with repo access | `ghp_xxxxxxxxxxxx`   | ✅       |
| `GITHUB_REPOSITORY`  | Target repository           | `owner/repo`         | ✅       |
| `RUNNER_NAME_PREFIX` | Prefix for runner names     | `runner`             | ❌       |
| `RUNNER_LABELS`      | Custom runner labels        | `self-hosted,docker` | ❌       |
| `ENVIRONMENT`        | Environment designation     | `production`         | ❌       |

### Build Configuration

The build system uses environment variables or defaults:

```bash
# Override registry settings if needed
export DOCKER_REGISTRY=ghcr.io
export DOCKER_NAMESPACE=grammatonic

# Build with custom settings
./scripts/build.sh --push
```

## 🚀 Deployment

### Local Development

```bash
# Start with basic configuration (choose runner type)
docker compose -f docker/docker-compose.production.yml up -d
```

### Production Deployment

```bash
# Install Docker (if needed)
curl -fsSL https://get.docker.com | sh

# Clone and configure
git clone https://github.com/GrammaTonic/github-runner.git
cd github-runner
cp config/runner.env.example config/runner.env
# Edit config/runner.env with your settings

# Deploy standard runners
docker compose -f docker/docker-compose.production.yml up -d

# Or deploy Chrome runners for UI testing
docker compose -f docker/docker-compose.chrome.yml up -d
```

## 📊 Monitoring

### Health Checks

```bash
# Check runner health
curl http://localhost:8080/health

# Prometheus metrics
curl http://localhost:9090/metrics

# Grafana dashboard
open http://localhost:3000
```

## 🔧 Maintenance

### Scaling

```bash
# Scale up
docker compose -f docker/docker-compose.yml up -d --scale runner=5

# Scale down
docker compose -f docker/docker-compose.yml up -d --scale runner=1
```

### Updates

```bash
# Pull latest images
docker compose -f docker/docker-compose.yml pull

# Restart services
docker compose -f docker/docker-compose.yml up -d
```

## 🐛 Troubleshooting

### Common Issues

**Runner not appearing in GitHub:**

```bash
# Check logs
docker compose logs runner

# Verify token permissions
# Token needs 'repo' scope for private repos
```

**High resource usage:**

```bash
# Monitor resources
docker stats

# Adjust compose file resource limits if needed
# Edit docker/docker-compose.production.yml or docker/docker-compose.chrome.yml
```

### Debug Mode

```bash
# Enable debug logging
echo "RUNNER_DEBUG=1" >> config/runner.env

# Restart runners
docker compose logs -f runner
```

## 🔒 Security

This project includes comprehensive security scanning and monitoring:

### Automated Security Scanning

- **Weekly Vulnerability Scans**: Automated Trivy scans every Monday
- **Multi-Target Analysis**: Filesystem, container, and Chrome runner scanning
- **GitHub Security Integration**: Results uploaded to Security tab (not cluttering issues)
- **SARIF Format**: Rich vulnerability data with remediation guidance

### Security Features

- **Container Security**: Regular base image updates and vulnerability patches
- **Dependency Scanning**: Automated detection of vulnerable packages
- **Secret Management**: Secure token handling and environment isolation
- **Security Policies**: Defined security standards and response procedures

### Viewing Security Results

1. **Security Tab**: Go to repository's Security tab → Code scanning
2. **Workflow Artifacts**: Download detailed reports from Actions → Security Advisory Management
3. **Weekly Summaries**: Automated summary reports with priority actions

### Security Documentation

- 📋 [Security Advisory Workflow](docs/features/SECURITY_ADVISORY_WORKFLOW.md)
- 🔄 [Security Migration Guide](docs/features/SECURITY_WORKFLOW_MIGRATION.md)
- 🛡️ [Security Policy](.github/SECURITY.md)

**Note**: Security vulnerabilities are managed through GitHub's Security tab, not through GitHub Issues, keeping your project issues clean and organized.

## 🆘 Support

- 📖 [Documentation](docs/)
- 📊 [Version Overview](docs/VERSION_OVERVIEW.md) - Comprehensive version tracking and security status
- ⚙️ [GitHub Actions Workflows](.github/WORKFLOWS.md)
- 🐛 [Issue Tracker](https://github.com/GrammaTonic/github-runner/issues)
- 💬 [Discussions](https://github.com/GrammaTonic/github-runner/discussions)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](docs/community/CONTRIBUTING.md) for details.

### Development Setup

```bash
# Fork and clone
git clone https://github.com/yourusername/github-runner.git
cd github-runner

# Switch to develop branch (integration branch)
git checkout develop
git pull origin develop

# Create feature branch from develop
git checkout -b feature/amazing-feature

# Make changes and test
make test

# Submit pull request to develop branch
```

**Important**: All regular development work should be done on feature branches created from `develop` and merged into `develop` via pull requests. Never commit directly to `main`. Hotfixes may be created from `main` when necessary and must be merged back into `develop` afterwards.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- GitHub Actions team for the self-hosted runner API
- Docker community for containerization best practices
- Prometheus and Grafana teams for monitoring solutions

---

⭐ If this project helps you, please consider giving it a star on GitHub!

# Test commit to trigger CI/CD

# Documentation Parity Update (2025-09-10)

## 📝 Recent Improvements

- Playwright screenshot artifact upload now copies from container to host for reliable CI/CD artifact collection
- Image verification added for both Chrome and normal runners in CI/CD workflows
- Diagnostics and health checks improved for runner startup and container validation
- Chrome runner documentation updated for Playwright, Cypress, Selenium, and browser automation best practices
- Normal runner Dockerfile and entrypoint improved for diagnostics and healthcheck reliability
- All documentation blocks, examples, and API docs synced with latest code and workflow changes

See [docs/README.md](docs/README.md) and [docs/chrome-runner.md](docs/chrome-runner.md) for full details.
