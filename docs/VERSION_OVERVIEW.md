# Version Overview - GitHub Runner Docker Images

## Overview

This document provides a comprehensive overview of all software versions, dependencies, and security patches used in the GitHub Runner Docker images.

## Docker Images

### 1. Standard Runner (`docker/Dockerfile`)

- **Image Version**: 1.0.1
- **Base Image**: `ubuntu:22.04`
- **Purpose**: General-purpose GitHub Actions runner with development tools
- **Target Architectures**: `linux/amd64`, `linux/arm64`

### 2. Chrome Runner (`docker/Dockerfile.chrome`)

- **Image Version**: 1.0.4
- **Base Image**: `ubuntu:22.04`
- **Purpose**: Chrome-optimized runner for web UI testing and browser automation
- **Target Architectures**: `linux/amd64`, `linux/arm64`

## Core Components

### GitHub Actions Runner

- **Version**: `2.328.0`
- **Source**: GitHub official releases
- **Download URL**: `https://github.com/actions/runner/releases/download/v2.328.0/`
- **Security Status**: ✅ Latest stable version

### Operating System

- **Base OS**: Ubuntu 22.04 LTS (Jammy Jellyfish)
- **Architecture Support**: Multi-architecture (amd64, arm64)
- **Kernel Version**: Linux kernel 5.15+
- **Security Updates**: Applied via `apt-get update` during build

## Runtime Dependencies

### System Packages (Both Images)

| Package           | Version                            | Purpose                |
| ----------------- | ---------------------------------- | ---------------------- |
| `nodejs`          | System default (Node.js ecosystem) | JavaScript runtime     |
| `npm`             | Latest available                   | Package manager        |
| `python3`         | 3.10+ (Ubuntu 22.04 default)       | Python runtime         |
| `python3-pip`     | Latest available                   | Python package manager |
| `git`             | Latest available                   | Version control        |
| `git-lfs`         | Latest available                   | Large file support     |
| `docker.io`       | Latest available                   | Docker CLI             |
| `curl`            | Latest available                   | HTTP client            |
| `jq`              | Latest available                   | JSON processor         |
| `build-essential` | Latest available                   | Compilation tools      |

### Node.js Ecosystem

#### Standard Runner

| Package           | Version   | Security Status                                  |
| ----------------- | --------- | ------------------------------------------------ |
| `@actions/core`   | Latest    | ✅ Official GitHub package                       |
| `@actions/github` | Latest    | ✅ Official GitHub package                       |
| `typescript`      | Latest    | ✅ Microsoft maintained                          |
| `eslint`          | Latest    | ✅ Community standard                            |
| `prettier`        | Latest    | ✅ Code formatter                                |
| `flat`            | **5.0.2** | ✅ **Security Fix** (VDB-216777, CVE-2020-36632) |

#### Chrome Runner

| Package            | Version    | Security Status                                  |
| ------------------ | ---------- | ------------------------------------------------ |
| `playwright`       | **1.55.0** | ✅ Latest stable                                 |
| `cypress`          | **15.1.0** | ✅ **Security Fix** (CVE-2025-9288)              |
| `@playwright/test` | **1.55.0** | ✅ Test framework                                |
| `flat`             | **5.0.2**  | ✅ **Security Fix** (VDB-216777, CVE-2020-36632) |
| `sha.js`           | **2.4.12** | ✅ **Security Fix** (CVE-2025-9288)              |
| `ws`               | **8.17.1** | ✅ **Security Fix** (CVE-2024-37890)             |

### Python Ecosystem

#### Standard Runner

| Package                | Version | Purpose          |
| ---------------------- | ------- | ---------------- |
| `pyyaml`               | Latest  | YAML processing  |
| `requests`             | Latest  | HTTP library     |
| `boto3`                | Latest  | AWS SDK          |
| `azure-cli`            | Latest  | Azure CLI        |
| `google-cloud-storage` | Latest  | Google Cloud SDK |

#### Chrome Runner

| Package             | Version | Purpose              |
| ------------------- | ------- | -------------------- |
| `selenium`          | Latest  | Browser automation   |
| `pytest`            | Latest  | Testing framework    |
| `pytest-selenium`   | Latest  | Selenium integration |
| `webdriver-manager` | Latest  | WebDriver management |

## Browser and Testing Tools (Chrome Runner Only)

### Google Chrome

- **Version**: Stable channel (latest)
- **Installation**: Official Google repository
- **GPG Key**: Verified from `dl.google.com`
- **Binary Path**: `/usr/bin/google-chrome-stable`

### ChromeDriver

- **Version**: Auto-matched to Chrome version
- **Installation**: Via dedicated `install-chromedriver.sh` script
- **Management**: Automatic version detection and installation

### Browser Dependencies

| Package              | Purpose                    |
| -------------------- | -------------------------- |
| `libnss3`            | Network Security Services  |
| `libatk-bridge2.0-0` | Accessibility toolkit      |
| `libdrm2`            | Direct Rendering Manager   |
| `libxcomposite1`     | X11 Composite extension    |
| `libgbm1`            | Generic Buffer Management  |
| `libxss1`            | X11 Screen Saver extension |
| `libasound2t64`      | ALSA sound library         |
| `libgtk-3-0`         | GTK+ 3.0 GUI toolkit       |

### Fonts and Display

| Package                  | Purpose                             |
| ------------------------ | ----------------------------------- |
| `fonts-liberation`       | Liberation fonts                    |
| `fonts-noto-color-emoji` | Color emoji support                 |
| `fonts-noto-cjk`         | CJK (Chinese/Japanese/Korean) fonts |
| `xvfb`                   | Virtual display server              |

## Security Patches Applied

### Critical Vulnerabilities Fixed

#### VDB-216777 / CVE-2020-36632

- **Package**: `flat` (JavaScript flattening utility)
- **Vulnerability**: Prototype pollution vulnerability
- **Fix Applied**: Upgraded to `flat@5.0.2`
- **Status**: ✅ **RESOLVED**
- **Applied In**: Both Docker images

#### CVE-2025-9288

- **Package**: `sha.js` (JavaScript SHA implementation)
- **Vulnerability**: Cryptographic weakness in Cypress dependency
- **Fix Applied**:
  - Upgraded Cypress to `15.1.0+`
  - Force-installed `sha.js@2.4.12`
- **Status**: ✅ **RESOLVED**
- **Applied In**: Chrome Runner only

#### CVE-2024-37890

- **Package**: `ws` (WebSocket library)
- **Vulnerability**: Denial of Service vulnerability
- **Fix Applied**: Force-installed `ws@8.17.1`
- **Status**: ✅ **RESOLVED**
- **Applied In**: Chrome Runner only

## Build Optimizations

### Multi-Stage Builds

- **Strategy**: Standard Runner uses multi-stage build pattern
- **Builder Stage**: Downloads and extracts GitHub Actions runner
- **Runtime Stage**: Copies runner and installs dependencies
- **Benefit**: Reduced image size and improved security

### Cache Management

- **APT Cache**: Cleaned after package installation (`rm -rf /var/lib/apt/lists/*`)
- **NPM Cache**: Cleaned after package installation (`npm cache clean --force`)
- **Temporary Files**: Comprehensive cleanup of `/tmp/*`, `/var/tmp/*`
- **Documentation**: Removed `/usr/share/doc` and `/usr/share/man` to reduce size

### Security Hardening

- **Non-Root User**: Both images run as `runner` user (UID 1000)
- **Sudo Access**: Configured for GitHub Actions requirements
- **Docker Group**: Runner user added to docker group for Docker-in-Docker
- **File Permissions**: Proper ownership and permissions on all directories

## Health Checks

### Standard Runner

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "Runner.Listener" || exit 1
```

### Chrome Runner

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "Runner.Listener" > /dev/null || exit 1
```

## Environment Configuration

### Standard Runner Environment

- `RUNNER_WORKDIR=/home/runner/_work`
- `RUNNER_ALLOW_RUNASROOT=false`
- `DEBIAN_FRONTEND=noninteractive`

### Chrome Runner Environment

- `CHROME_BIN=/usr/bin/google-chrome-stable`
- `DISPLAY=:99`
- `DEBIAN_FRONTEND=noninteractive`

## Volume Mounts

### Standard Runner

- `/home/runner/_work` - Persistent workspace
- `/home/runner/.cache` - Build and dependency cache

### Chrome Runner

- `/home/runner/.cache` - Browser and test cache
- `/home/runner/workspace` - Test workspace

## Network Configuration

### Exposed Ports

- **Standard Runner**: Port 8080 (debugging/monitoring)
- **Chrome Runner**: No ports exposed (testing focused)

## Update Policy

### Automated Updates

- **Base OS**: Updated during build via `apt-get update`
- **System Packages**: Latest available versions from Ubuntu repositories
- **GitHub Runner**: Pinned to specific version for stability

### Manual Updates Required

- **GitHub Runner Version**: Update `RUNNER_VERSION` ARG in Dockerfiles
- **Testing Frameworks**: Update specific versions in package installation commands
- **Security Patches**: Applied as needed for known vulnerabilities

## Version History

### Recent Changes

- **2025-01-15**: Applied VDB-216777/CVE-2020-36632 flat package security fix
- **2025-01-15**: Added comprehensive security patches for Chrome Runner
- **2025-01-15**: Implemented comprehensive cache cleaning strategy
- **2025-01-15**: Standardized Docker build contexts across workflows

### Next Planned Updates

- Monitor for new GitHub Actions runner releases
- Regular security scanning with Trivy
- Dependency updates based on security advisories
- Performance optimization based on usage patterns

## Verification Commands

### Check Installed Versions

```bash
# GitHub Actions Runner version
cd /actions-runner && cat .runner

# Node.js and NPM versions
node --version && npm --version

# Python version
python3 --version && pip3 --version

# Chrome version (Chrome Runner only)
google-chrome-stable --version

# Testing framework versions (Chrome Runner only)
npx playwright --version
npx cypress --version
```

### Security Audit

```bash
# NPM security audit
npm audit

# Python security check
pip3 list --outdated

# System package status
apt list --upgradable
```

---

**Last Updated**: January 15, 2025  
**Document Version**: 1.0  
**Maintainer**: GrammaTonic
