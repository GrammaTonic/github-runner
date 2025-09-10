# GitHub Actions Self-Hosted Runner

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/GrammaTonic/github-runner)](https://github.com/GrammaTonic/github-runner/releases/latest)
[![Docker Image](https://img.shields.io/badge/docker-ghcr.io%2Fgrammatonic%2Fgithub--runner-blue)](https://ghcr.io/grammatonic/github-runner)
[![CI/CD Pipeline](https://github.com/GrammaTonic/github-runner/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/GrammaTonic/github-runner/actions/workflows/ci-cd.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive, production-ready GitHub Actions self-hosted runner solution with monitoring, scaling, and security features.

## 🚀 Features

- **Containerized Runners**: Docker-based runners with multi-platform support
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
wget https://github.com/GrammaTonic/github-runner/archive/v1.0.0.tar.gz
tar -xzf v1.0.0.tar.gz
cd github-runner-1.0.0
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
make dev

# Or manually
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

### Cloud Deployment

See `docs/deployment/` for cloud-specific guides:

- AWS ECS/Fargate
- Google Cloud Run
- Azure Container Instances
- Kubernetes

## 📊 Monitoring

### Included Monitoring Stack

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **System Metrics**: Host performance, Docker stats
- **Application Metrics**: Runner status, job execution times
- **Alerts**: Configurable alerting rules

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

### Cleanup

```bash
# Remove stopped containers
docker compose -f docker/docker-compose.yml down

# Full cleanup (removes volumes)
docker compose -f docker/docker-compose.yml down -v
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

**Connection issues:**

```bash
# Check network connectivity
docker exec -it github-runner-runner-1 ping github.com

# Verify firewall settings
```

### Debug Mode

```bash
# Enable debug logging
echo "RUNNER_DEBUG=1" >> config/runner.env

# Restart runners
docker compose logs -f runner
```

### Support

- **Issues**: [GitHub Issues](https://github.com/GrammaTonic/github-runner/issues)
- **Discussions**: [GitHub Discussions](https://github.com/GrammaTonic/github-runner/discussions)
- **Documentation**: [docs/](../docs/)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](../community/CONTRIBUTING.md) for details.

### Development Setup

```bash
# Fork and clone
git clone https://github.com/yourusername/github-runner.git
cd github-runner

# Create feature branch
git checkout -b feature/amazing-feature

# Make changes and test
make test

# Submit pull request
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## 🙏 Acknowledgments

- GitHub Actions team for the self-hosted runner API
- Docker community for containerization best practices
- Prometheus and Grafana teams for monitoring solutions

---

⭐ If this project helps you, please consider giving it a star on GitHub!ate)](https://img.shields.io/github/v/release/GrammaTonic/github-runner)](https://github.com/GrammaTonic/github-runner/releases/latest)
[![Docker Image](https://img.shields.io/badge/docker-ghcr.io%2Fgrammatonic%2Fgithub--runner-blue)](https://ghcr.io/grammatonic/github-runner)
[![CI/CD Pipeline](https://github.com/GrammaTonic/github-runner/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/GrammaTonic/github-runner/actions/workflows/ci-cd.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive, production-ready GitHub Actions self-hosted runner solution with monitoring, scaling, and security features.

## 🚀 Features

- **Containerized Runners**: Docker-based runners with multi-platform support
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
wget https://github.com/GrammaTonic/github-runner/archive/v1.0.0.tar.gz
tar -xzf v1.0.0.tar.gz
cd github-runner-1.0.0
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

## 📋 Prerequisitesub release (latest by date)](https://img.shields.io/github/v/release/GrammaTonic/github-runner)](https://github.com/GrammaTonic/github-runner/releases/latest)

[![Docker Image](https://img.shields.io/badge/docker-ghcr.io%2Fgrammatonic%2Fgithub--runner-blue)](https://ghcr.io/grammatonic/github-runner)
[![CI/CD Pipeline](https://github.com/GrammaTonic/github-runner/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/GrammaTonic/github-runner/actions/workflows/ci-cd.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive, production-ready GitHub Actions self-hosted runner solution with monitoring, scaling, and security features.

## 🚀 Features

- **Containerized Runners**: Docker-based runners with multi-platform support
- **Auto-scaling**: Dynamic scaling based on workload demands
- **Monitoring**: Prometheus metrics and Grafana dashboards
- **Security**: Vulnerability scanning, secret management, and security policies
- **CI/CD Integration**: Automated building, testing, and deployment
- **High Availability**: Health checks, automatic restarts, and failover
- **Multi-Environment**: Support for dev, staging, and production environments

## � Installation

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
wget https://github.com/GrammaTonic/github-runner/archive/v1.0.0.tar.gz
tar -xzf v1.0.0.tar.gz
cd github-runner-1.0.0
```

## �📋 Prerequisites

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
# Start single runner
./scripts/deploy.sh start

# Start multiple runners
./scripts/deploy.sh start -s 3

# Check status
./scripts/deploy.sh status
```

## 🏗️ Architecture

```
github-runner/
├── .github/workflows/     # CI/CD pipelines
├── docker/               # Container configurations
├── scripts/              # Deployment and management scripts
├── config/               # Configuration templates
├── monitoring/           # Prometheus and Grafana setup
├── cache/                # Build and dependency cache
└── docs/                 # Documentation
```

### Components

- **Runner Container**: Ubuntu-based with GitHub Actions runner
- **Monitoring Stack**: Prometheus + Grafana + AlertManager
- **Reverse Proxy**: Nginx for load balancing (optional)
- **Cache Layer**: Redis for build caching (optional)

## 🔧 Configuration

### Environment Variables

| Variable               | Description                    | Default                 | Required |
| ---------------------- | ------------------------------ | ----------------------- | -------- |
| `GITHUB_TOKEN`         | GitHub PAT with repo access    | -                       | ✅       |
| `GITHUB_REPOSITORY`    | Target repository (owner/repo) | -                       | ✅       |
| `RUNNER_LABELS`        | Custom runner labels           | `self-hosted,docker`    | ❌       |
| `RUNNER_NAME_PREFIX`   | Prefix for runner names        | `runner`                | ❌       |
| `RUNNER_WORKDIR`       | Runner work directory          | `/actions-runner/_work` | ❌       |
| `REGISTRATION_TIMEOUT` | Registration timeout (seconds) | `300`                   | ❌       |

### Docker Configuration

Edit `config/docker.env`:

```bash
# Resource limits
RUNNER_MEMORY_LIMIT=4g
RUNNER_CPU_LIMIT=2

# Networking
DOCKER_NETWORK=github-runner-network
EXPOSE_METRICS=true
METRICS_PORT=8080

# Security
DISABLE_AUTO_UPDATE=false
RUNNER_ALLOW_RUNASROOT=false
```

## 🚀 Deployment Options

### Local Development

```bash
# Start with monitoring
./scripts/deploy.sh start -e dev

# View logs
./scripts/deploy.sh logs

# Scale up for testing
./scripts/deploy.sh scale -s 2
```

### Production Deployment

```bash
# Production environment
export ENVIRONMENT=production

# Start with multiple runners
./scripts/deploy.sh start -s 5

# Enable monitoring
docker compose -f docker/docker-compose.yml --profile monitoring up -d
```

### Cloud Deployment

#### AWS EC2

```bash
# User data script
#!/bin/bash
curl -fsSL https://get.docker.com | sh
git clone <repository-url> /opt/github-runner
cd /opt/github-runner
./scripts/deploy.sh start -s 3
```

#### Google Cloud

```bash
# Cloud Run deployment
gcloud run deploy github-runner \
  --image gcr.io/PROJECT/github-runner \
  --platform managed \
  --region us-central1
```

## 📊 Monitoring

### Metrics Dashboards

Access Grafana at `http://localhost:3000` (admin/admin):

- **Runner Status**: Health, registration status, job queue
- **Resource Usage**: CPU, memory, disk, network
- **Job Metrics**: Execution time, success rate, queue length
- **System Metrics**: Host performance, Docker stats

### Key Metrics

- `github_runner_jobs_total`: Total jobs executed
- `github_runner_jobs_duration_seconds`: Job execution time
- `github_runner_registration_status`: Runner registration health
- `container_cpu_usage_seconds_total`: Container CPU usage
- `container_memory_usage_bytes`: Container memory usage

### Alerts

Configure alerts in `monitoring/alerts.yml`:

```yaml
- alert: RunnerDown
  expr: up{job="github-runner"} == 0
  for: 5m
  annotations:
    summary: "GitHub runner is down"

- alert: HighMemoryUsage
  expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.9
  for: 10m
  annotations:
    summary: "High memory usage detected"
```

## 🔒 Security

### Token Management

- Store tokens securely using environment variables
- Rotate tokens regularly (recommended: monthly)
- Use fine-grained personal access tokens when available
- Monitor token usage in GitHub settings

### Container Security

- Runs as non-root user
- Read-only filesystem where possible
- Limited capabilities
- Network isolation
- Vulnerability scanning in CI/CD

### Network Security

```bash
# Firewall rules (example)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw deny 9090/tcp   # Prometheus (internal only)
```

## 🔄 Management Commands

### Deployment Script

```bash
# Available commands
./scripts/deploy.sh start      # Start runners
./scripts/deploy.sh stop       # Stop runners
./scripts/deploy.sh restart    # Restart runners
./scripts/deploy.sh scale -s N # Scale to N runners
./scripts/deploy.sh status     # Show status
./scripts/deploy.sh logs       # Show logs
./scripts/deploy.sh health     # Health check
./scripts/deploy.sh update     # Update runners
./scripts/deploy.sh cleanup    # Clean up resources
```

### Build Script

```bash
# Build runner image
./scripts/build.sh

# Multi-platform build
./scripts/build.sh --platform linux/amd64,linux/arm64

# Build with scanning
./scripts/build.sh --scan
```

## 🐛 Troubleshooting

### Common Issues

#### Runner Registration Fails

```bash
# Check token and repository
./scripts/deploy.sh logs runner

# Verify token permissions
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GITHUB_REPOSITORY
```

#### High Memory Usage

```bash
# Check container stats
docker stats

# Adjust memory limits
# Edit config/docker.env
RUNNER_MEMORY_LIMIT=8g
```

#### Container Won't Start

```bash
# Check container logs
docker logs github-runner-runner-1

# Verify file permissions
ls -la config/runner.env

# Check disk space
df -h
```

### Log Analysis

```bash
# Follow all logs
./scripts/deploy.sh logs

# Filter specific service
docker compose logs -f runner

# Search for errors
docker compose logs | grep -i error

# Export logs for analysis
docker compose logs > runner-logs.txt
```

### Health Checks

```bash
# Manual health check
./scripts/deploy.sh health

# Check runner registration
curl http://localhost:8080/health

# Verify GitHub API connectivity
docker exec -it github-runner-runner-1 \
  curl -s https://api.github.com/repos/$GITHUB_REPOSITORY
```

## 🔄 Updates and Maintenance

### Updating Runners

```bash
# Update with latest GitHub Actions runner
./scripts/deploy.sh update

# Force update without confirmation
./scripts/deploy.sh update -f

# Update without rebuilding
./scripts/deploy.sh update -n
```

### Backup and Recovery

```bash
# Backup configuration
tar -czf runner-backup.tar.gz config/ cache/

# Restore configuration
tar -xzf runner-backup.tar.gz
```

### Maintenance Tasks

```bash
# Clean up old containers and images
./scripts/deploy.sh cleanup

# Prune Docker system
docker system prune -a

# Update dependencies
docker compose pull
```

## 🎯 Performance Tuning

### Resource Optimization

```bash
# Monitor resource usage
docker stats --no-stream

# Adjust CPU limits
# config/docker.env
RUNNER_CPU_LIMIT=4

# Configure memory limits
RUNNER_MEMORY_LIMIT=8g
```

### Scaling Strategies

1. **Horizontal Scaling**: Multiple runner containers
2. **Vertical Scaling**: Increase container resources
3. **Auto-scaling**: Based on queue length or CPU usage
4. **Geographic Distribution**: Deploy in multiple regions

### Cache Optimization

```bash
# Enable build cache
# docker/docker-compose.yml
volumes:
  - ./cache/build:/var/cache/build
  - ./cache/deps:/var/cache/deps
```

## 📚 Advanced Usage

### Custom Runner Images

```dockerfile
# Dockerfile.custom
FROM github-runner:latest

# Install additional tools
RUN apt-get update && apt-get install -y \
    terraform \
    kubectl \
    aws-cli

# Custom configuration
COPY custom-entrypoint.sh /usr/local/bin/
```

### Multi-Repository Setup

```bash
# Deploy for multiple repositories
export GITHUB_REPOSITORY=org/repo1
./scripts/deploy.sh start -s 2

export GITHUB_REPOSITORY=org/repo2
./scripts/deploy.sh start -s 2
```

### Integration with Kubernetes

```yaml
# k8s/deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: github-runner
spec:
  replicas: 3
  selector:
    matchLabels:
      app: github-runner
  template:
    metadata:
      labels:
        app: github-runner
    spec:
      containers:
        - name: runner
          image: github-runner:latest
          env:
            - name: GITHUB_TOKEN
              valueFrom:
                secretKeyRef:
                  name: github-secrets
                  key: token
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/new-feature`
5. Create Pull Request

### Development Setup

```bash
# Install development dependencies
pip install -r requirements-dev.txt

# Run tests
./scripts/test.sh

# Lint code
./scripts/lint.sh
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📖 [Documentation](docs/)
- ⚙️ [GitHub Actions Workflows](.github/WORKFLOWS.md)
- 🐛 [Issue Tracker](https://github.com/GrammaTonic/github-runner/issues)
- 💬 [Discussions](https://github.com/GrammaTonic/github-runner/discussions)

## 🙏 Acknowledgments

- GitHub Actions team for the excellent runner
- Docker community for containerization best practices
- Prometheus and Grafana teams for monitoring tools
- Contributors and testers

---

**Made with ❤️ for the GitHub Actions community**
