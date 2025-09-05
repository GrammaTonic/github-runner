# GitHub Runner - AI Coding Agent Instructions

## Project Overview

This repository is for setting up and managing GitHub Actions self-hosted runners using Docker containers for a single repository. The project focuses on automating containerized runner deployment, configuration, and lifecycle management with Docker and Docker Compose.

## 🚨 CRITICAL FILE ORGANIZATION RULES

### Documentation Structure - NEVER CREATE .MD FILES IN ROOT

- **ALL documentation MUST go in `/docs/` subdirectories** - NEVER create .md files in root directory
- **Community files location**: `/docs/community/` (CODE_OF_CONDUCT.md, CONTRIBUTING.md, SECURITY.md)
- **Feature documentation**: `/docs/features/` (feature specs, implementation docs)
- **Release notes**: `/docs/releases/` (changelogs, release documentation)
- **Archive old files**: `/docs/archive/` (deprecated or backup files)
- **GitHub templates ONLY**: `.github/` directory (pull_request_template.md, issue templates)

### Root Directory Rules - KEEP CLEAN

- **Only essential files allowed in root**: README.md, LICENSE, package files, configuration files
- **No documentation in root**: Always use `/docs/` subdirectories with proper categorization
- **No feature specs in root**: Use `/docs/features/` directory
- **No community files in root**: Use `/docs/community/` directory

### Validation

- Run `scripts/check-docs-structure.sh` to validate file organization
- Use `--fix` flag to automatically organize misplaced files
- This script should be run before any commits to ensure compliance

## Architecture & Key Components

### Core Components (to be implemented)

- **Dockerfile & Docker Images**: Custom GitHub runner Docker images with pre-installed tools
- **Docker Compose Configuration**: Multi-container setups for runner orchestration
- **Configuration Management**: Environment variables and volume mounts for runner configuration
- **Health Checks & Monitoring**: Container health monitoring and automatic restart policies
- **Scaling Scripts**: Docker Compose scaling based on repository job demand

### Expected Directory Structure

```
├── docker/
│   ├── Dockerfile              # Main runner image definition
│   ├── docker-compose.yml      # Container orchestration
│   └── entrypoint.sh          # Container startup script
├── config/
│   ├── runner.env             # Environment variables
│   └── docker.env             # Docker-specific configuration
├── scripts/
│   ├── build.sh               # Image building automation
│   ├── deploy.sh              # Container deployment
│   └── cleanup.sh             # Container cleanup and maintenance
├── cache/                     # Local cache directories (volume mounts)
│   ├── build/                 # Build artifacts and intermediate files
│   ├── deps/                  # Dependencies cache (npm, pip, etc.)
│   └── workspace/             # Persistent workspace data
├── monitoring/
│   └── healthcheck.sh         # Container health monitoring
└── docs/                      # Setup and operational documentation
```

## Development Workflows

### Initial Setup Commands

```bash
# Clone and setup development environment
git clone <repo-url>
cd github-runner

# Build the runner Docker image
docker build -t github-runner:latest ./docker

# Tag and push to GitHub Container Registry
docker tag github-runner:latest ghcr.io/grammatonic/github-runner:latest
docker push ghcr.io/grammatonic/github-runner:latest

# Start runners with Docker Compose
docker-compose up -d

# Scale runners based on demand
docker-compose up -d --scale runner=3
```

### Common Operations

- **Runner Registration**: Docker entrypoint scripts handle GitHub API token management and single repository runner registration
- **Container Scaling**: Use Docker Compose scaling based on repository job demand
- **Image Updates**: Rebuild and redeploy containers for runner software updates
- **Log Management**: Centralized logging with Docker logging drivers for repository-specific workflows
- **Cache Management**: Local volume-based caching for build artifacts, dependencies, and workspace data

## Project-Specific Conventions

### Technology Stack

This project is built entirely on Docker technology:

- **Docker Engine**: Core containerization platform
- **Docker Compose**: Multi-container application orchestration
- **Docker Images**: Custom GitHub runner images with pre-installed tools
- **Docker Volumes**: Persistent storage for configuration and workspace data
- **Docker Networks**: Container communication and isolation

### Runner Type

- **Local Caching**: Persistent volumes for build artifacts, dependencies, and workspace caching
- **Volume-Based Cache**: Docker volumes replace GitHub Actions cache for faster builds
- **Persistent Workspaces**: Shared workspace data across container restarts

### Security Practices

- Store GitHub tokens using Docker secrets or secure environment variable injection
- Use non-root users in Docker containers with minimal required permissions
- Implement container image vulnerability scanning in CI/CD pipeline
- Regular base image updates and security patches

### Configuration Management

- Use Docker environment files (.env) for environment-specific settings
- Volume mounts for persistent configuration and workspace data
- Multi-stage Dockerfiles for different deployment environments
- Health check definitions in docker-compose.yml
- Local cache volume configuration for build artifacts and dependencies

### Runner Lifecycle

- Container restart policies for automatic recovery
- Graceful container shutdown with proper signal handling
- Health monitoring with Docker healthcheck commands

## Integration Points

### GitHub API

- Runner registration and management endpoints
- Webhook handling for job notifications
- Repository access control and token management

### Infrastructure Dependencies

- Docker Engine and Docker Compose for container orchestration
- GitHub Container Registry (ghcr.io) for custom runner image distribution
- Docker-native monitoring tools (Docker stats, cAdvisor, Portainer)

### CI/CD Integration

- Self-testing runner configurations
- Automated deployment pipelines for runner updates
- Integration with existing organizational CI/CD workflows

## Key Files to Understand

- Configuration templates in `config/` directory
- Main setup scripts in `scripts/` directory
- Docker configurations for containerized deployments
- Infrastructure code for automated provisioning

## Development Guidelines

- Test runner configurations in isolated environments before production deployment
- Implement comprehensive logging for troubleshooting runner issues
- Use version pinning for runner software to ensure consistency
- Document environment-specific setup requirements clearly
- Consider dedicated Chrome runner if web UI tests remain slow

## Troubleshooting Common Issues

- Runner registration failures: Check token permissions and API rate limits
- Job execution failures: Verify runner environment and dependency availability
- Network connectivity: Ensure proper firewall and proxy configurations
- Resource constraints: Monitor CPU, memory, and disk usage patterns
- Performance optimization: Consider dedicated Chrome runner if web UI tests remain slow

## Performance Optimization

### Web UI Testing Performance

- **Dedicated Chrome Runner**: If web UI tests (Selenium, Playwright, Cypress) are slow, consider deploying a dedicated runner with Chrome browser optimizations
- **Browser Container Isolation**: Use separate Docker containers for browser-heavy workloads to prevent resource contention
- **Headless Browser Configuration**: Configure headless Chrome with optimized flags for CI/CD environments
- **Parallel Test Execution**: Scale Chrome runners horizontally for parallel browser test execution

### Runner Specialization Strategies

- **General Purpose Runners**: Standard runners for building, testing, and deployment tasks
- **Browser Test Runners**: Specialized runners with Chrome, Firefox, and browser testing tools pre-installed
- **Build-Heavy Runners**: High-CPU runners for compilation-intensive workloads
- **Cache-Optimized Runners**: Runners with persistent volume mounts for dependency caching
