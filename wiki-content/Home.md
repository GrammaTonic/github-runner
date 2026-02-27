# Base Image: Ubuntu Resolute (25.10 Pre-release)

This project uses `ubuntu:resolute` for the Chrome runner to ensure compatibility with the latest browser dependencies. CVE mitigation is performed via npm overrides, local installs, and automated Trivy scans. See README and DEPLOYMENT for details.
# GitHub Actions Self-Hosted Runner Wiki

Welcome to the comprehensive documentation for the GitHub Actions Self-Hosted Runner project!

## 🎯 **Latest Updates**

### � **Release v2.2.0 Available** (November 14, 2025)

- **Image Versions**: Standard Runner v2.2.0, Chrome Runner v2.2.0 with npm `tar@7.5.2` override
- **Browser Stack**: Chrome 142.0.7444.162, Playwright 1.55.1, Cypress 13.15.0, Node.js 24.11.1
- **Documentation Sync**: README, changelog, wiki, and release notes fully updated — see [Release Notes v2.2.0](../docs/releases/RELEASE_NOTES_v2.2.0.md)
- **Quality Gates**: Docker validation, security scans, and runner self-tests passing ✅

### �🔒 **Critical Security Improvements** (January 15, 2025)

- **Security Patches**: ✅ VDB-216777/CVE-2020-36632, CVE-2025-9288, CVE-2024-37890 resolved
- **Performance**: Optimized Docker images with comprehensive cache cleaning
- **CI/CD**: Enhanced pipeline reliability with standardized Docker build contexts
- **Monitoring**: Weekly Trivy security scans with automated SARIF reporting

### ✅ **Chrome Runner Production Ready** (September 2024)

- **Status**: ✅ Production Ready - All 10/10 CI/CD checks passing
- **Performance**: 60% faster web UI tests with resource isolation
- **Latest Versions**: Playwright 1.55.1, Cypress 13.15.0 with security patches
- **Documentation**: [Chrome Runner Guide](Chrome-Runner.md)

## 📊 **Current Versions**

| Component                 | Standard Runner | Chrome Runner | Security Status         |
| ------------------------- | --------------- | ------------- | ----------------------- |
| **Image Version**         | v2.2.0          | v2.2.0        | ✅ Latest               |
| **GitHub Actions Runner** | v2.331.0        | v2.331.0      | ✅ Latest               |
| **Node.js**               | -               | 24.11.1       | ✅ Chrome Runner Only   |
| **Playwright**            | -               | 1.55.1        | ✅ Latest               |
| **Cypress**               | -               | 13.15.0       | ✅ Security Patched |

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

## 📝 Documentation Parity & Recent Improvements (2025-11-14)

- Release v2.2.0 documentation refreshed across README, changelog, wiki, and release notes
- npm `tar@7.5.2` override documented for reproducible package installs and security posture
- Chrome runner guidance updated for Playwright 1.55.1, Cypress 13.15.0, and Chrome 142.0.7444.162
- Validation scripts and runner self-tests rerun to confirm Docker image health for release
- Troubleshooting, quick start, and version tables synced with latest component inventory

See [Chrome Runner Guide](Chrome-Runner.md) and [Version Overview](../docs/VERSION_OVERVIEW.md) for full details.

## 📝 Contributing to Documentation

Found something missing or incorrect? We welcome contributions to improve this documentation:

1. Visit the [main repository](https://github.com/GrammaTonic/github-runner)
2. Open an issue or submit a pull request
3. Help us keep the documentation accurate and up-to-date

---

_Last updated: November 14, 2025_
