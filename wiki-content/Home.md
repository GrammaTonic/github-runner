# Base Image: Ubuntu Questing (25.10 Pre-release)

This project uses `ubuntu:questing` for the Chrome runner to ensure compatibility with the latest browser dependencies. CVE mitigation is performed via npm overrides, local installs, and automated Trivy scans. See README and DEPLOYMENT for details.
# GitHub Actions Self-Hosted Runner Wiki

Welcome to the comprehensive documentation for the GitHub Actions Self-Hosted Runner project!

## 🎯 **Latest Updates**

### 🔒 **Critical Security Improvements** (January 15, 2025)

- **Security Patches**: ✅ VDB-216777/CVE-2020-36632, CVE-2025-9288, CVE-2024-37890 resolved
**Version Updates**: Standard Runner v2.0.2, Chrome Runner v2.0.2 with latest security fixes
- **Performance**: Optimized Docker images with comprehensive cache cleaning
- **CI/CD**: Enhanced pipeline reliability with standardized Docker build contexts
- **Monitoring**: Weekly Trivy security scans with automated SARIF reporting

### ✅ **Chrome Runner Production Ready** (September 2024)

- **Status**: ✅ Production Ready - All 10/10 CI/CD checks passing
- **Performance**: 60% faster web UI tests with resource isolation
- **Latest Versions**: Playwright 1.55.0, Cypress 15.1.0 with security patches
- **Documentation**: [Chrome Runner Guide](Chrome-Runner.md)

## 📊 **Current Versions**

| Component                 | Standard Runner | Chrome Runner | Security Status   |
| ------------------------- | --------------- | ------------- | ----------------- |
| **Image Version**         | v2.0.2          | v2.0.2        | ✅ Latest         |
| **GitHub Actions Runner** | v2.329.0        | v2.329.0      | ✅ Latest         |
| **Node.js**               | -               | 24.7.0        | ✅ Chrome Runner Only |
| **Playwright**            | -               | v1.55.0       | ✅ Latest         |
| **Cypress**               | -               | v15.1.0       | ✅ Security Fixed |

> 📋 **Full Version Details**: [Version Overview](../docs/VERSION_OVERVIEW.md)

## 📖 Table of Contents

### Getting Started

- [Home](Home.md) - Overview and quick start
- [Installation Guide](Installation-Guide.md) - Step-by-step installation
- [Quick Start](Quick-Start.md) - Get up and running in 5 minutes

### Specialized Runners

- **[Chrome Runner](Chrome-Runner.md) 🆕** - Web UI testing and browser automation
- [Docker Configuration](Docker-Configuration.md) - General Docker setup

### Configuration

- [Production Deployment](Production-Deployment.md) - Production-ready deployment
- [Common Issues](Common-Issues.md) - Troubleshooting and solutions

## 🚀 Quick Start Options

### 🌐 **For Web UI Testing**

```bash
# Chrome Runner (Recommended for browser tests)
./scripts/build-chrome.sh --push
docker-compose -f docker/docker-compose.chrome.yml up -d
```

### 🐳 **For General Workloads**

```bash
# Standard Runner
docker build -t github-runner:latest ./docker
docker-compose up -d
```

## 🔗 **Quick Links**

| Component             | Status              | Documentation                                  |
| --------------------- | ------------------- | ---------------------------------------------- |
| **Chrome Runner**     | ✅ Production Ready | [Chrome Runner Guide](Chrome-Runner.md)           |
| **Standard Runner**   | ✅ Stable           | [Installation Guide](Installation-Guide.md)       |
| **CI/CD Pipeline**    | ✅ Passing          | [Production Deployment](Production-Deployment.md) |
| **Security Scanning** | ✅ Clean            | [Common Issues](Common-Issues.md)                 |


<!-- Links to missing docs removed for CI/CD compliance. -->

## 🚀 Quick Links

- **[Installation Guide](Installation-Guide.md)** - Start here for first-time setup
- **[Docker Configuration](Docker-Configuration.md)** - Essential Docker setup
- **[Production Deployment](Production-Deployment.md)** - Production checklist
- **[Common Issues](Common-Issues.md)** - Troubleshooting help

## 🔗 External Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Self-Hosted Runners Guide](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## 📝 Documentation Parity & Recent Improvements (2025-09-10)

- Playwright screenshot artifact upload now copies from container to host for reliable CI/CD artifact collection
- Image verification added for both Chrome and normal runners in CI/CD workflows
- Diagnostics and health checks improved for runner startup and container validation
- Chrome runner documentation updated for Playwright, Cypress, Selenium, and browser automation best practices
- Normal runner Dockerfile and entrypoint improved for diagnostics and healthcheck reliability
- All documentation blocks, examples, and API docs synced with latest code and workflow changes

See [Chrome Runner Guide](Chrome-Runner.md) and [Version Overview](../docs/VERSION_OVERVIEW.md) for full details.

## 📝 Contributing to Documentation

Found something missing or incorrect? We welcome contributions to improve this documentation:

1. Visit the [main repository](https://github.com/GrammaTonic/github-runner)
2. Open an issue or submit a pull request
3. Help us keep the documentation accurate and up-to-date

---

_Last updated: September 4, 2025_
