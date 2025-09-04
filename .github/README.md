# GitHub Actions CI/CD Workflows

This repository contains a comprehensive set of GitHub Actions workflows for managing GitHub self-hosted runners using Docker containers.

## Workflow Overview

### 1. CI/CD Pipeline (`ci-cd.yml`)

**Triggers:**

- Push to `main` and `develop` branches
- Pull requests to `main` and `develop` branches
- Manual workflow dispatch with configurable options

**Features:**

- **Linting & Validation**: Docker files, shell scripts, and environment files
- **Security Scanning**: Trivy vulnerability scanning and secret detection
- **Docker Build**: Multi-platform container images with caching
- **Testing**: Unit, integration, and configuration tests
- **Deployment**: Staging and production deployments with proper approvals
- **Cleanup**: Automated resource cleanup and reporting

**Security Measures:**

- Least privilege permissions for GITHUB_TOKEN
- Container image vulnerability scanning
- Secret scanning with TruffleHog
- SARIF upload for security events

### 2. Maintenance (`maintenance.yml`)

**Triggers:**

- Scheduled weekly (Mondays at 6 AM UTC)
- Manual workflow dispatch with update type selection

**Features:**

- **Dependency Updates**: Docker base images and GitHub Actions
- **Security Scanning**: Comprehensive dependency vulnerability checks
- **Cleanup**: Old workflow runs and artifacts
- **Health Checks**: Repository health assessment and reporting

### 3. Release Management (`release.yml`)

**Triggers:**

- Git tags matching `v*.*.*` pattern
- Manual workflow dispatch with version and release type

**Features:**

- **Version Validation**: Semantic version format checking
- **Multi-platform Builds**: Linux AMD64 and ARM64 support
- **Container Signing**: Cosign integration for image verification
- **SBOM Generation**: Software Bill of Materials creation
- **Security Validation**: Pre-release vulnerability scanning
- **GitHub Releases**: Automated release creation with changelog

### 4. Monitoring and Health Checks (`monitoring.yml`)

**Triggers:**

- Scheduled every 6 hours
- Manual workflow dispatch with check type selection

**Features:**

- **Infrastructure Health**: Registry connectivity and image availability
- **Security Monitoring**: Continuous vulnerability scanning with issue creation
- **Performance Monitoring**: Repository size and build performance metrics
- **Dependency Monitoring**: Outdated packages and actions tracking
- **Alert Summary**: Comprehensive health scoring and reporting

## Security Best Practices Implemented

### 🔒 Secret Management

- All sensitive data accessed via GitHub Secrets
- Environment-specific secrets for staging and production
- No hardcoded credentials in workflows

### 🛡️ Permissions

- Least privilege principle for GITHUB_TOKEN
- Granular permissions per job
- Security events write access for vulnerability reporting

### 🔍 Vulnerability Scanning

- Filesystem and container image scanning with Trivy
- SARIF format uploads to GitHub Security tab
- Automated issue creation for critical vulnerabilities
- Secret scanning with TruffleHog

### 📦 Container Security

- Multi-stage Docker builds for minimal attack surface
- Image signing with Cosign
- Software Bill of Materials (SBOM) generation
- Multi-platform builds for broader compatibility

## Optimization Features

### ⚡ Performance

- Docker BuildKit with advanced caching
- GitHub Actions cache for dependencies
- Matrix strategies for parallel testing
- Optimized checkout with shallow clones

### 🔄 Reliability

- Comprehensive test matrix (unit, integration, config)
- Health checks and monitoring
- Automated rollback capabilities
- Environment protection rules

### 📊 Observability

- Detailed test reporting and artifacts
- Performance metrics collection
- Health scoring and alerting
- Comprehensive logging

## Usage

### Setting Up Secrets

Required secrets for full functionality:

```bash
# Staging environment
STAGING_GITHUB_TOKEN=<token_for_staging_runner>
STAGING_REPOSITORY=<staging_repo_name>

# Production environment
PROD_GITHUB_TOKEN=<token_for_production_runner>
PROD_REPOSITORY=<production_repo_name>
```

### Manual Deployments

Use workflow dispatch to manually trigger deployments:

1. Go to Actions tab in GitHub
2. Select "CI/CD Pipeline" workflow
3. Click "Run workflow"
4. Configure options:
   - Environment: staging/production
   - Skip tests: true/false
   - Force rebuild: true/false

### Creating Releases

1. **Automated**: Push a git tag with semantic version:

   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Manual**: Use workflow dispatch:
   - Go to "Release Management" workflow
   - Click "Run workflow"
   - Specify version and release type

## Monitoring and Alerts

The monitoring workflow provides:

- **Health Score**: Overall system health percentage
- **Automated Issues**: Critical vulnerability detection
- **Performance Metrics**: Build times and repository statistics
- **Dependency Tracking**: Outdated packages and actions

## Customization

### Environment Configuration

Update environment-specific settings in:

- `config/runner.env` - Runner configuration
- `docker/docker-compose.yml` - Container orchestration
- Workflow environment sections

### Adding New Checks

Extend the monitoring workflow by:

1. Adding new jobs for specific checks
2. Updating the alert summary to include new results
3. Configuring appropriate failure conditions

## Best Practices Compliance

These workflows implement GitHub Actions best practices:

- ✅ Least privilege permissions
- ✅ Pinned action versions
- ✅ Comprehensive security scanning
- ✅ Efficient caching strategies
- ✅ Proper secret management
- ✅ Environment protection
- ✅ Automated testing
- ✅ Performance optimization
- ✅ Observability and monitoring

## Troubleshooting

### Common Issues

1. **Permission Errors**: Check GITHUB_TOKEN permissions in workflow
2. **Cache Misses**: Verify cache key patterns and paths
3. **Deployment Failures**: Review environment protection rules
4. **Security Scan Failures**: Address vulnerabilities before proceeding

### Debug Information

Enable debug logging by setting repository secrets:

- `ACTIONS_STEP_DEBUG=true`
- `ACTIONS_RUNNER_DEBUG=true`

---

For more information about GitHub Actions best practices, see the [GitHub Actions documentation](https://docs.github.com/en/actions).
