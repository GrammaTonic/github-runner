# Installation Guide

This guide will walk you through installing and setting up GitHub Actions Self-Hosted Runner step by step.

## 📋 Prerequisites

Before starting, ensure you have:

- Docker Engine 20.10+ installed
- Docker Compose 2.0+ installed
- Git installed
- GitHub repository admin access
- At least 2GB free disk space
- Internet connectivity

## 🔧 System Requirements

### Minimum Requirements

- **CPU**: 1 vCPU
- **Memory**: 2GB RAM
- **Disk**: 10GB free space
- **OS**: Linux (Ubuntu 20.04+), macOS, or Windows with WSL2

### Recommended Requirements

- **CPU**: 2+ vCPUs
- **Memory**: 4GB+ RAM
- **Disk**: 50GB+ free space (for build caches)
- **Network**: Stable internet connection (1Mbps+)

## 🚀 Quick Installation

### 1. Clone the Repository

```bash
# Using Git
git clone https://github.com/GrammaTonic/github-runner.git
cd github-runner

# Using GitHub CLI
gh repo clone GrammaTonic/github-runner
cd github-runner
```

### 2. Configure Environment

# Copy configuration example
 # Copy the example environment file into a working runner.env before editing
# Copy configuration example
cp config/runner.env.example config/runner.env

# Edit configuration
nano config/runner.env
```

Required environment variables:

```bash
# GitHub Configuration
GITHUB_TOKEN=ghp_your_token_here
GITHUB_REPOSITORY=owner/repo-name
RUNNER_NAME=my-runner-01

# Runner Configuration
RUNNER_LABELS=self-hosted,docker,linux
RUNNER_GROUP=default
```

### 3. Set Up GitHub Token

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token with permissions:
   - `repo` (for private repositories)
   - `workflow` (to access Actions)
3. Copy token to `GITHUB_TOKEN` in `config/runner.env`

### 4. Deploy Runners

Choose your runner type:

```bash
# Deploy standard runners (most common)
docker compose -f docker/docker-compose.production.yml up -d

# Deploy Chrome runners for UI testing
docker compose -f docker/docker-compose.chrome.yml up -d

# Deploy both types (advanced)
docker compose -f docker/docker-compose.production.yml up -d
docker compose -f docker/docker-compose.chrome.yml up -d
```

### 5. Verify Installation

```bash
# Check runner status
docker compose logs runner

# Verify in GitHub
# Go to Settings → Actions → Runners in your repository
```

## 🔧 Advanced Installation

### Custom Docker Build

```bash
# Build custom image
docker build -t my-github-runner ./docker

# Update compose files to use custom image
# In docker-compose.production.yml: image: my-github-runner:latest
```

### Multiple Runners

```bash
# Scale standard runners
docker compose -f docker/docker-compose.production.yml up -d --scale github-runner=3

# Scale Chrome runners
docker compose -f docker/docker-compose.chrome.yml up -d --scale github-runner-chrome=2
```

### Production Setup

```bash
# Create production environment file
cp config/runner.env.example config/production.env

# Configure for production
DOCKER_BUILDKIT=1
COMPOSE_PROJECT_NAME=github-runner-prod

# Deploy with production settings
docker compose -f docker/docker-compose.production.yml --env-file config/production.env up -d
```

## 🛠️ Configuration Options

### Runner Configuration

| Variable            | Description                    | Default            | Required |
| ------------------- | ------------------------------ | ------------------ | -------- |
| `GITHUB_TOKEN`      | GitHub personal access token   | -                  | ✅       |
| `GITHUB_REPOSITORY` | Target repository (owner/name) | -                  | ✅       |
| `RUNNER_NAME`       | Unique runner identifier       | hostname           | ❌       |
| `RUNNER_LABELS`     | Comma-separated labels         | self-hosted,docker | ❌       |
| `RUNNER_GROUP`      | Runner group name              | default            | ❌       |
| `RUNNER_WORK_DIR`   | Working directory              | /workspace         | ❌       |

### Docker Configuration

| Variable               | Description             | Default               |
| ---------------------- | ----------------------- | --------------------- |
| `RUNNER_MEMORY_LIMIT`  | Memory limit per runner | 2g                    |
| `RUNNER_CPU_LIMIT`     | CPU limit per runner    | 1.0                   |
| `DOCKER_NETWORK`       | Docker network name     | github-runner-network |
| `COMPOSE_PROJECT_NAME` | Docker Compose project  | github-runner         |

## 🔍 Troubleshooting Installation

### Common Issues

**Docker not found:**

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

**Permission denied:**

```bash
# Fix permissions
sudo chown -R $USER:$USER /var/run/docker.sock
```

**Token authentication failed:**

- Verify token has correct permissions
- Check repository name format (owner/repo)
- Ensure token hasn't expired

**Runner not appearing:**

```bash
# Check logs
docker compose logs runner

# Verify network connectivity
curl -s https://api.github.com/user
```

## 📝 Documentation Parity & Recent Improvements (2025-09-10)

- Installation guide, environment configuration, and runner setup synced with latest code and documentation
- Chrome runner and standard runner quick start instructions updated for diagnostics and health checks
- All troubleshooting and setup steps reflect current best practices

See [Home](Home.md) and [Chrome Runner Guide](Chrome-Runner.md) for full details.

## 🔄 Next Steps

After successful installation:

1. **[Quick Start Guide](Quick-Start.md)** - Run your first workflow
2. **[Docker Configuration](Docker-Configuration.md)** - Customize Docker setup

<!-- Security Configuration doc not available. Link removed for CI/CD compliance. -->
4. **[Production Deployment](Production-Deployment.md)** - Production checklist

## 📞 Getting Help

- **Issues**: Check [Common Issues](Common-Issues.md)
- **Documentation**: Browse the [wiki home](Home.md)
- **Support**: Open an issue on [GitHub](https://github.com/GrammaTonic/github-runner/issues)
