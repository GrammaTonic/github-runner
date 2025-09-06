# GitHub Actions Self-Hosted Runner

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/GrammaTonic/github-runner)](https://github.com/GrammaTonic/github-runner/releases/latest)
[![Docker Image](https://img.shields.io/badge/docker-ghcr.io%2Fgrammatonic%2Fgithub--runner-blue)](https://ghcr.io/grammatonic/github-runner)
[![CI/CD Pipeline](https://github.com/GrammaTonic/github-runner/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/GrammaTonic/github-runner/actions/workflows/ci-cd.yml)
[![Chrome Runner](https://img.shields.io/badge/Chrome%20Runner-Production%20Ready-success?style=flat-square&logo=google-chrome)](https://github.com/GrammaTonic/github-runner/wiki/Chrome-Runner)
[![Security](https://img.shields.io/badge/Security-Trivy%20Scanned-success?style=flat-square&logo=security)](https://github.com/GrammaTonic/github-runner/actions/workflows/security-advisories.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive, production-ready GitHub Actions self-hosted runner solution with monitoring, scaling, and security features.

## 📊 Current Versions

| Component                 | Standard Runner  | Chrome Runner    | Status            |
| ------------------------- | ---------------- | ---------------- | ----------------- |
| **Image Version**         | v1.0.1           | v1.0.4           | ✅ Latest         |
| **GitHub Actions Runner** | v2.328.0         | v2.328.0         | ✅ Latest         |
| **Base OS**               | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS | ✅ Supported      |
| **Node.js**               | 20.x             | 20.x             | ✅ Latest LTS     |
| **Python**                | 3.10+            | 3.10+            | ✅ Latest         |
| **Playwright**            | -                | v1.55.0          | ✅ Latest         |
| **Cypress**               | -                | v15.1.0          | ✅ Security Fixed |
| **Chrome**                | -                | Stable           | ✅ Latest         |

> 📋 For detailed version information, see [Version Overview](docs/VERSION_OVERVIEW.md)

## 🔒 Security Status

- ✅ **VDB-216777/CVE-2020-36632**: Flat package vulnerability patched (`flat@5.0.2`)
- ✅ **CVE-2025-9288**: Cypress SHA.js vulnerability patched (`sha.js@2.4.12`)
- ✅ **CVE-2024-37890**: WebSocket DoS vulnerability patched (`ws@8.17.1`)
- ✅ **Trivy Security Scanning**: Automated weekly vulnerability scans
- ✅ **Container Hardening**: Non-root execution, minimal attack surface

## 🚀 Features

- **Containerized Runners**: Docker-based runners with multi-platform support (amd64/arm64)
- **Chrome Runner**: Specialized environment for web UI testing and browser automation
- **Auto-scaling**: Dynamic scaling based on workload demands using Docker Compose
- **Monitoring**: Prometheus metrics and Grafana dashboards for performance tracking
- **Security**: Comprehensive vulnerability scanning, security patches, and container hardening
- **CI/CD Integration**: Automated building, testing, and deployment with GitHub Actions
- **High Availability**: Health checks, automatic restarts, and failover mechanisms
- **Multi-Environment**: Support for dev, staging, and production environments
- **Cache Optimization**: Persistent volume caching for build artifacts and dependencies
- **Security Scanning**: Weekly Trivy scans with automated SARIF reporting

### 🆕 Recent Improvements (January 2025)

- ✅ Applied critical security patches for prototype pollution and DoS vulnerabilities
- ✅ Optimized Docker image sizes with comprehensive cache cleaning
- ✅ Enhanced Chrome Runner with latest Playwright (1.55.0) and Cypress (15.1.0)
- ✅ Standardized Docker build contexts for consistent CI/CD pipeline execution
- ✅ Implemented automated security advisory workflow with Trivy scanning

## 📦 Installation

### Using Git Clone

```bash
git clone https://github.com/GrammaTonic/github-runner.git
cd github-runner
```

### Using GitHub CLI

```bash
gh repo clone GrammaTonic/github-runner
cd github-runner
```

### Using Release Archive

```bash
wget https://github.com/GrammaTonic/github-runner/archive/v1.0.1.tar.gz
tar -xzf v1.0.1.tar.gz
cd github-runner-1.0.1
```

### Using Docker Images

Pre-built Docker images are available for each release:

```bash
# Standard Runner (latest)
docker pull ghcr.io/grammatonic/github-runner:v1.0.1

# Chrome Runner (latest)
docker pull ghcr.io/grammatonic/github-runner-chrome:v1.0.4

# Development versions
docker pull ghcr.io/grammatonic/github-runner:develop
docker pull ghcr.io/grammatonic/github-runner-chrome:develop

# Semantic versioning
docker pull ghcr.io/grammatonic/github-runner:1.0.1
docker pull ghcr.io/grammatonic/github-runner:1.0
docker pull ghcr.io/grammatonic/github-runner:1
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

- **Standard Runner**: General CI/CD with Docker, Node.js, Python
- **Chrome Runner**: UI testing with Chrome, Selenium, Playwright
- **Both Runners**: Deploy both types with separate configurations

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

# Scale runners based on demand
docker compose -f docker/docker-compose.production.yml up -d --scale github-runner=2 --scale github-runner-chrome=1
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

# Switch to develop branch (primary development branch)
git checkout develop
git pull origin develop

# Create feature branch from develop
git checkout -b feature/amazing-feature

# Make changes and test
make test

# Submit pull request to develop branch
```

**Important**: All development work should be done on the `develop` branch. Never work directly on `main`.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- GitHub Actions team for the self-hosted runner API
- Docker community for containerization best practices
- Prometheus and Grafana teams for monitoring solutions

---

⭐ If this project helps you, please consider giving it a star on GitHub!
