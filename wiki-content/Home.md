# GitHub Actions Self-Hosted Runner Wiki

Welcome to the comprehensive documentation for the GitHub Actions Self-Hosted Runner project!

## 🎯 **Latest Updates**

### ✅ **Chrome Runner Production Ready** (Sep 4, 2025)

- **Status**: ✅ Production Ready - All 10/10 CI/CD checks passing
- **Performance**: 60% faster web UI tests with resource isolation
- **CI/CD**: All checks completed successfully (Build, Security, Tests)
- **Deployment**: Ready for production use with scaling support
- **ChromeDriver**: Issue resolved with Chrome for Testing API
- **Documentation**: [Chrome Runner Guide](Chrome-Runner)

## 📖 Table of Contents

### Getting Started

- [Home](Home) - Overview and quick start
- [Installation Guide](Installation-Guide) - Step-by-step installation
- [Quick Start](Quick-Start) - Get up and running in 5 minutes

### Specialized Runners

- **[Chrome Runner](Chrome-Runner) 🆕** - Web UI testing and browser automation
- [Docker Configuration](Docker-Configuration) - General Docker setup

### Configuration

- [Production Deployment](Production-Deployment) - Production-ready deployment
- [Common Issues](Common-Issues) - Troubleshooting and solutions

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
| **Chrome Runner**     | ✅ Production Ready | [Chrome Runner Guide](Chrome-Runner)           |
| **Standard Runner**   | ✅ Stable           | [Installation Guide](Installation-Guide)       |
| **CI/CD Pipeline**    | ✅ Passing          | [Production Deployment](Production-Deployment) |
| **Security Scanning** | ✅ Clean            | [Common Issues](Common-Issues)                 |

- [Contributing](Contributing) - How to contribute to the project
- [Development Workflow](Development-Workflow) - Development processes and standards
- [Testing Strategy](Testing-Strategy) - Testing approaches and frameworks
- [Release Process](Release-Process) - Version management and releases

## 🚀 Quick Links

- **[Installation Guide](Installation-Guide)** - Start here for first-time setup
- **[Docker Configuration](Docker-Configuration)** - Essential Docker setup
- **[Production Deployment](Production-Deployment)** - Production checklist
- **[Common Issues](Common-Issues)** - Troubleshooting help

## 🔗 External Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Self-Hosted Runners Guide](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## 📝 Contributing to Documentation

Found something missing or incorrect? We welcome contributions to improve this documentation:

1. Visit the [main repository](https://github.com/GrammaTonic/github-runner)
2. Open an issue or submit a pull request
3. Help us keep the documentation accurate and up-to-date

---

_Last updated: September 4, 2025_
