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

```bash
# Copy configuration template
cp config/runner.env.template config/runner.env

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

```bash
# Start basic runner
docker compose -f docker/docker-compose.yml up -d

# Start with monitoring (recommended)
docker compose -f docker/docker-compose.yml --profile monitoring up -d
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

# Update docker-compose.yml to use custom image
# image: my-github-runner:latest
```

### Multiple Runners

```bash
# Scale to 3 runners
docker compose -f docker/docker-compose.yml up -d --scale runner=3
```

### Production Setup

```bash
# Create production environment file
cp config/runner.env config/production.env

# Configure for production
DOCKER_BUILDKIT=1
COMPOSE_PROJECT_NAME=github-runner-prod
RUNNER_MEMORY_LIMIT=4g
RUNNER_CPU_LIMIT=2.0

# Deploy with production settings
docker compose -f docker/docker-compose.yml --env-file config/production.env up -d
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

## 🔄 Next Steps

After successful installation:

1. **[Quick Start Guide](Quick-Start)** - Run your first workflow
2. **[Docker Configuration](Docker-Configuration)** - Customize Docker setup
3. **[Security Configuration](Security-Configuration)** - Secure your runners
4. **[Production Deployment](Production-Deployment)** - Production checklist

## 📞 Getting Help

- **Issues**: Check [Common Issues](Common-Issues)
- **Documentation**: Browse the [wiki home](Home)
- **Support**: Open an issue on [GitHub](https://github.com/GrammaTonic/github-runner/issues)
