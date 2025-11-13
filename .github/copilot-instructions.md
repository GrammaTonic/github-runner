# GitHub Runner - AI Coding Agent Instructions

## Project Overview

This repository is for setting up and managing GitHub Actions self-hosted runners using Docker containers for a single repository. The project focuses on automating containerized runner deployment, configuration, and lifecycle management with Docker and Docker Compose.

## RULES AND STANDARDS
- USE Non interactive gh CLI commands for all GitHub operations
- ALWAYS follow the established development workflow and branch protection rules
- NEVER create .md files in the root directory; all documentation must go in `/docs/` subdirectories
- ALWAYS use the provided scripts for setup, deployment, and validation tasks

## 🚨 CRITICAL WORKFLOW & BRANCH PROTECTION RULES

### Branch Protection Status - ENFORCED

- **`main` branch**: PROTECTED with branch protection rules
- **`develop` branch**: PROTECTED with branch protection rules
- **Direct pushes BLOCKED**: All changes must go through pull requests
- **Review required**: 1 approving review required before merge
- **Status checks required**: CI/CD Pipeline must pass before merge
- **Force pushes BLOCKED**: History integrity preserved
- **Conversation resolution**: All PR comments must be resolved

### Development Workflow - MANDATORY

1. **Start from develop**: Always create feature branches from the integration branch `develop`.
2. **Feature development**: Work on features/fixes in dedicated feature branches created from `develop`.
3. **Pull Request workflow**: Submit PR from feature branch → `develop` for integration and review.
4. **Code review & CI**: Get 1+ approval AND CI/CD Pipeline must pass on feature PRs to `develop`.
5. **Merge to develop**: After approval and green CI, merge to `develop`.
6. **Release process**: Create a PR from `develop` → `main` to promote integrated changes to production.

**CRITICAL**: Direct pushes to `main` and `develop` are blocked by branch protection; promotions must be done via PRs.

### Branch Protection Management

- **Setup script**: `scripts/setup-branch-protection.sh` - Configure protection rules
- **Status check**: `scripts/setup-branch-protection.sh --status` - View current rules
- **Enforcement**: GitHub API enforced, cannot be bypassed without admin override

## 🚨 CRITICAL FILE ORGANIZATION RULES

### Documentation Structure - NEVER CREATE .MD FILES IN ROOT

- **ALL documentation MUST go in `/docs/` subdirectories** - NEVER create .md files in root directory
- **Community files location**: `/docs/community/` (CODE_OF_CONDUCT.md, CONTRIBUTING.md)
- **Security policy location**: `/.github/SECURITY.md` (for GitHub recognition)
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

## Architecture & Key Components - CURRENT IMPLEMENTATION

### Core Components (IMPLEMENTED)

- **Dockerfile & Docker Images**: Custom GitHub runner Docker images with pre-installed tools
- **Docker Compose Configuration**: Separate compose files implemented:
  - `docker-compose.production.yml` - Standard runners
  - `docker-compose.chrome.yml` - Chrome runners with browser support
- **Configuration Management**: Environment variables and volume mounts for runner configuration
- **Health Checks & Monitoring**: Container health monitoring and automatic restart policies
- **CI/CD Pipeline**: Comprehensive testing and deployment automation
- **Branch Protection**: Automated branch protection setup via scripts

### Current Directory Structure

```
├── docker/
│   ├── Dockerfile                     # Main runner image definition
│   ├── Dockerfile.chrome              # Chrome runner image definition
│   ├── docker-compose.production.yml  # Standard runner deployment (IMPLEMENTED)
│   ├── docker-compose.chrome.yml      # Chrome runner deployment (IMPLEMENTED)
│   ├── entrypoint.sh                  # Container startup script (IMPLEMENTED)
│   └── entrypoint-chrome.sh           # Chrome runner startup script (IMPLEMENTED)
├── config/
│   ├── runner.env.example             # Standard runner configuration template
│   ├── chrome-runner.env.example      # Chrome runner configuration template
│   ├── runner.env                     # User's standard runner config (created from template)
│   └── chrome-runner.env              # User's Chrome runner config (optional)
├── scripts/
│   ├── build.sh                       # Image building automation (IMPLEMENTED)
│   ├── build-chrome.sh                # Chrome image building (IMPLEMENTED)
│   ├── deploy.sh                      # Container deployment (IMPLEMENTED)
│   ├── setup-branch-protection.sh     # Branch protection automation (IMPLEMENTED)
│   └── check-docs-structure.sh        # Documentation validation (IMPLEMENTED)
├── cache/                             # Local cache directories (volume mounts)
│   ├── build/                         # Build artifacts and intermediate files
│   ├── deps/                          # Dependencies cache (npm, pip, etc.)
│   └── workspace/                     # Persistent workspace data
├── monitoring/
│   ├── prometheus.yml                 # Monitoring configuration
│   └── grafana/                       # Dashboard configurations
├── tests/                             # Comprehensive test suite
│   ├── unit/                          # Unit tests
│   ├── integration/                   # Integration tests
│   ├── docker/                        # Docker validation tests
│   └── security/                      # Security tests
└── docs/                              # Documentation (organized structure)
    ├── features/                      # Feature specifications
    ├── community/                     # Community guidelines
    ├── releases/                      # Release notes
    └── archive/                       # Legacy documentation
```

│ └── entrypoint-chrome.sh # Chrome runner startup script
├── config/
│ ├── runner.env.example # Standard runner configuration template
│ ├── chrome-runner.env.example # Chrome runner configuration template
│ ├── runner.env # User's standard runner config (created from template)
│ └── chrome-runner.env # User's Chrome runner config (optional)
├── scripts/
│ ├── build.sh # Image building automation
│ ├── deploy.sh # Container deployment
│ └── cleanup.sh # Container cleanup and maintenance
├── cache/ # Local cache directories (volume mounts)
│ ├── build/ # Build artifacts and intermediate files
│ ├── deps/ # Dependencies cache (npm, pip, etc.)
│ └── workspace/ # Persistent workspace data
├── monitoring/
│ └── healthcheck.sh # Container health monitoring
└── docs/ # Setup and operational documentation

````

## Development Workflows

### Branch Strategy

- **`main`**: Production-ready code only. Protected branch requiring PR approval.
- **`develop`**: Active development branch. All work starts here.
- **Feature branches**: Created from `develop` for new features
- **Hotfix branches**: Created from `develop` for urgent fixes

### Initial Setup Commands

```bash
# Clone and setup development environment
git clone <repo-url>
cd github-runner

# Switch to develop branch (integration branch)
git checkout develop
git pull origin develop

# Create feature branch from develop
git checkout -b feature/your-feature-name

# Build the runner Docker image
docker build -t github-runner:latest ./docker

# Tag and push to GitHub Container Registry
docker tag github-runner:latest ghcr.io/grammatonic/github-runner:latest
docker push ghcr.io/grammatonic/github-runner:latest

# Start standard runners
docker compose -f docker/docker-compose.production.yml up -d

# Start Chrome runners
docker compose -f docker/docker-compose.chrome.yml up -d

# Scale runners based on demand and type
docker compose -f docker/docker-compose.production.yml up -d --scale github-runner=3
docker compose -f docker/docker-compose.chrome.yml up -d --scale github-runner-chrome=2
````

## Development Workflows

### Branch Strategy

- **`main`**: Production-ready code only. Protected branch requiring PR approval.
- **`develop`**: Active development branch. Protected branch requiring PR approval.
- **Feature branches**: Created from `develop` for new features
- **Hotfix branches**: Created from `develop` for urgent fixes

### Initial Setup Commands

```bash
# Clone and setup development environment
git clone <repo-url>
cd github-runner

# Switch to develop branch (primary development branch)
git checkout develop
git pull origin develop

# Create feature branch from develop
git checkout -b feature/your-feature-name

# Build the runner Docker image
docker build -t github-runner:latest ./docker

# Tag and push to GitHub Container Registry
docker tag github-runner:latest ghcr.io/grammatonic/github-runner:latest
docker push ghcr.io/grammatonic/github-runner:latest

# Start standard runners
docker compose -f docker/docker-compose.production.yml up -d

# Start Chrome runners
docker compose -f docker/docker-compose.chrome.yml up -d

# Scale runners based on demand and type
docker compose -f docker/docker-compose.production.yml up -d --scale github-runner=3
docker compose -f docker/docker-compose.chrome.yml up -d --scale github-runner-chrome=2
```

## Development Workflows

### Branch Strategy

- **`main`**: Production-ready code only. Protected branch requiring PR approval.
- **`develop`**: Active development branch. Protected branch requiring PR approval.
- **Feature branches**: Created from `develop` for new features
- **Hotfix branches**: Created from `develop` for urgent fixes

### Initial Setup Commands

```bash
# Clone and setup development environment
git clone <repo-url>
cd github-runner

# Switch to develop branch (primary development branch)
git checkout develop
git pull origin develop

# Create feature branch from develop
git checkout -b feature/your-feature-name

# Build the runner Docker image
docker build -t github-runner:latest ./docker

# Tag and push to GitHub Container Registry
docker tag github-runner:latest ghcr.io/grammatonic/github-runner:latest
docker push ghcr.io/grammatonic/github-runner:latest

# Start standard runners
docker compose -f docker/docker-compose.production.yml up -d

# Start Chrome runners
docker compose -f docker/docker-compose.chrome.yml up -d

# Scale runners based on demand and type
docker compose -f docker/docker-compose.production.yml up -d --scale github-runner=3
docker compose -f docker/docker-compose.chrome.yml up -d --scale github-runner-chrome=2
>>>>>>> origin/main
```

### Development Workflow - UPDATED

1. **Start from develop**: Always create feature branches from protected `develop` branch.
2. **Work on features**: Implement features and fixes on feature branches.
3. **Test thoroughly**: Ensure changes work and pass all CI/CD tests.
4. **Create PR to develop**: Submit pull request from feature branch → `develop`.
5. **Code review & CI**: Get 1+ approval AND CI/CD Pipeline must pass (required by branch protection).
6. **Merge to develop**: After approval and green CI, merge to `develop`.
7. **Release process**: Create PR from `develop` → `main` for releases (triggers release validation).

**CRITICAL**: Direct pushes to `main` and `develop` are blocked by branch protection rules.

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

- **Multi-stage Dockerfiles** for different deployment environments
- **Separate compose files** for standard and Chrome runners
- **Health check definitions** in each compose file
- **Local cache volume configuration** for build artifacts and dependencies

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

## Development Guidelines
 
Test runner configurations in isolated environments before production deployment
Implement comprehensive logging for troubleshooting runner issues
Use version pinning for runner software to ensure consistency
Document environment-specific setup requirements clearly
Use the dedicated Chrome runner for web UI tests requiring browser automation
- Test runner configurations in isolated environments before production deployment
- Implement comprehensive logging for troubleshooting runner issues
- Use version pinning for runner software to ensure consistency
- Document environment-specific setup requirements clearly
- Use the dedicated Chrome runner for web UI tests requiring browser automation

## Troubleshooting Common Issues

- Runner registration failures: Check token permissions and API rate limits
- Job execution failures: Verify runner environment and dependency availability
- Network connectivity: Ensure proper firewall and proxy configurations
- Resource constraints: Monitor CPU, memory, and disk usage patterns
- Browser testing issues: Use the dedicated Chrome runner for UI test workloads

## Performance Optimization

### Web UI Testing Performance

- **Dedicated Chrome Runner**: Deployed via `docker-compose.chrome.yml` with Chrome browser optimizations for UI testing
- **Browser Container Isolation**: Chrome runners use separate containers to prevent resource contention with standard runners
- **Headless Browser Configuration**: Pre-configured headless Chrome with optimized flags for CI/CD environments
- **Parallel Test Execution**: Scale Chrome runners horizontally for parallel browser test execution

### Runner Specialization Strategies

- **Standard Runners**: `docker-compose.production.yml` for general building, testing, and deployment tasks
- **Chrome Runners**: `docker-compose.chrome.yml` for specialized browser testing with Chrome, Selenium, Playwright, Cypress
- **Mixed Deployment**: Deploy both runner types simultaneously for comprehensive CI/CD coverage
- **Cache-Optimized**: Both runner types include persistent volume mounts for dependency caching
