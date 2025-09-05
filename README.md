# GitHub Actions Self-Hosted Runner

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/GrammaTonic/github-runner)](https://github.com/GrammaTonic/github-runner/releases/latest)
[![Docker Image](https://img.shields.io/badge/docker-ghcr.io%2Fgrammatonic%2Fgithub--runner-blue)](https://ghcr.io/grammatonic/github-runner)
[![CI/CD Pipeline](https://github.com/GrammaTonic/github-runner/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/GrammaTonic/github-runner/actions/workflows/ci-cd.yml)
[![Chrome Runner](https://img.shields.io/badge/Chrome%20Runner-Production%20Ready-success?style=flat-square&logo=google-chrome)](https://github.com/GrammaTonic/github-runner/wiki/Chrome-Runner)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive, production-ready GitHub Actions self-hosted runner solution with monitoring, scaling, and security features.

## 🚀 Features

- **Containerized Runners**: Docker-based runners with multi-platform support
- **Chrome Runner**: Specialized environment for web UI testing and browser automation
- **Auto-scaling**: Dynamic scaling based on workload demands
- **Monitoring**: Prometheus metrics and Grafana dashboards
- **Security**: Vulnerability scanning, secret management, and security policies
- **CI/CD Integration**: Automated building, testing, and deployment
- **High Availability**: Health checks, automatic restarts, and failover
- **Multi-Environment**: Support for dev, staging, and production environments

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
# Latest release (recommended)
docker pull ghcr.io/grammatonic/github-runner:v1.0.1

# Specific version
docker pull ghcr.io/grammatonic/github-runner:v1.0.0

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

### 1. Clone and Setup

```bash
git clone https://github.com/GrammaTonic/github-runner.git
cd github-runner
cp config/runner.env.template config/runner.env
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
# Basic setup (development)
docker compose -f docker/docker-compose.yml up -d

# With monitoring (recommended)
docker compose -f docker/docker-compose.yml --profile monitoring up -d

# Scale runners
docker compose -f docker/docker-compose.yml up -d --scale runner=3
```

### 4. Verify Setup

```bash
# Check runner status
docker compose -f docker/docker-compose.yml ps

# View logs
docker compose -f docker/docker-compose.yml logs -f runner
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

### Docker Configuration

Edit `config/docker.env`:

```bash
# Container Settings
COMPOSE_PROJECT_NAME=github-runner
DOCKER_BUILDKIT=1

# Network Configuration
DOCKER_NETWORK=github-runner-network

# Resource Limits
RUNNER_MEMORY_LIMIT=2g
RUNNER_CPU_LIMIT=1.0
```

## 🚀 Deployment

### Local Development

```bash
# Start with basic configuration
docker compose -f docker/docker-compose.yml up -d
```

### Production Deployment

```bash
# Install Docker (if needed)
curl -fsSL https://get.docker.com | sh

# Clone and configure
git clone https://github.com/GrammaTonic/github-runner.git
cd github-runner
cp config/runner.env.template config/runner.env
# Edit config/runner.env with your settings

# Deploy with monitoring
docker compose -f docker/docker-compose.yml --profile monitoring up -d
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

# Edit config/docker.env
RUNNER_MEMORY_LIMIT=1g
RUNNER_CPU_LIMIT=0.5
```

### Debug Mode

```bash
# Enable debug logging
echo "RUNNER_DEBUG=1" >> config/runner.env

# Restart runners
docker compose logs -f runner
```

## 🆘 Support

- 📖 [Documentation](docs/)
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
