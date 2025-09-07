# Chrome Runner x86 Deployment Guide

## Overview
This guide helps you deploy the GitHub Actions Chrome runner on x86_64 architecture to resolve ARM64 compatibility issues.

## Prerequisites
- **x86_64 system** (Linux/Windows with x86, AWS EC2, Google Cloud, etc.)
- **Docker** installed and running
- **GitHub Personal Access Token** with `repo` scope

## Quick Start

### 1. Configure Environment
```bash
# Copy and edit configuration
cp config/chrome-runner.env.example config/chrome-runner.env

# Edit with your credentials
nano config/chrome-runner.env  # or your preferred editor
```

**Required configuration:**
```bash
GITHUB_TOKEN=ghp_your_actual_token_here
GITHUB_REPOSITORY=your-username/your-repo-name
```

### 2. Deploy Chrome Runner
```bash
# Run the deployment script
./scripts/deploy-chrome-x86.sh
```

### 3. Verify Deployment
```bash
# Check status
./scripts/deploy-chrome-x86.sh status

# View logs
docker logs github-runner-chrome
```

## Manual Deployment (Alternative)

If you prefer manual deployment:

```bash
# Build the image
docker build -f docker/Dockerfile.chrome -t github-runner-chrome:x86 ./docker

# Deploy with docker-compose
docker compose -f docker/docker-compose.chrome.yml --env-file config/chrome-runner.env up -d
```

## Troubleshooting

### Architecture Issues
- Ensure you're running on x86_64 architecture
- Check with: `uname -m` (should return `x86_64`)

### Permission Issues
- The deployment script handles permission fixes automatically
- If manual deployment, ensure config.sh has execute permissions

### GitHub Token Issues
- Verify token has `repo` scope for private repositories
- Check token hasn't expired
- Ensure repository name format is correct: `username/repo-name`

### Docker Issues
- Ensure Docker daemon is running
- Check available disk space
- Verify no port conflicts

## Management Commands

```bash
# Stop runner
./scripts/deploy-chrome-x86.sh stop

# Restart runner
./scripts/deploy-chrome-x86.sh restart

# View status
./scripts/deploy-chrome-x86.sh status
```

## Testing

Once deployed, test with a GitHub Actions workflow:

```yaml
name: Chrome UI Tests
on: [push, pull_request]

jobs:
  ui-tests:
    runs-on: [self-hosted, chrome]
    steps:
      - uses: actions/checkout@v4
      - name: Run Chrome tests
        run: |
          google-chrome --version
          # Your UI testing commands here
```

## Architecture Notes

- **x86_64**: Full Chrome support with all features
- **ARM64**: Limited support (Chrome binaries are x86_64 only)
- **Cross-platform**: Use Docker's buildx for multi-architecture builds

## Support

If you encounter issues:
1. Check the logs: `docker logs github-runner-chrome`
2. Verify configuration in `config/chrome-runner.env`
3. Ensure GitHub token has correct permissions
4. Confirm you're on x86_64 architecture