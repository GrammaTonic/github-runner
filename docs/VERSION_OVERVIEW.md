# Version Overview - GitHub Runner Docker Images

## Overview

This document provides a comprehensive overview of all software versions, dependencies, and security patches used in the GitHub Runner Docker images.

## Docker Images

### 1. Standard Runner (`docker/Dockerfile`)

**Image Version**: v2.2.0
**Base Image**: `ubuntu:questing` (25.10 Pre-release)
**Purpose**: General-purpose GitHub Actions runner with development tools
**Target Architectures**: `linux/amd64` only

### 2. Chrome Runner (`docker/Dockerfile.chrome`)

**Image Version**: v2.2.0
**Base Image**: `ubuntu:questing` (25.10 Pre-release)
**Purpose**: Chrome-optimized runner for web UI testing and browser automation
**Target Architectures**: `linux/amd64` only (ARM builds are blocked for Chrome runner)

## Core Components

### GitHub Actions Runner

- **Version**: `2.329.0`
- **Source**: GitHub official releases
- **Download URL**: `https://github.com/actions/runner/releases/download/v2.329.0/`
- **Security Status**: ✅ Latest stable version

### Operating System

**Base OS**: Ubuntu 25.1sss0 Questing (Pre-release)
**Architecture Support**: amd64 only for Chrome Runner; Standard Runner is amd64
**Kernel Version**: Linux kernel 6.10+
- **Security Updates**: Applied via `apt-get update` during build

## Runtime Dependencies

### System Packages (Both Images)

| Package           | Version                            | Purpose                |
| ----------------- | ---------------------------------- | ---------------------- |
| `nodejs`          | 24.11.1 (Chrome Runner only)       | JavaScript runtime     |
| `npm`             | Latest available                   | Package manager        |
| `python3`         | 3.10+ (Ubuntu 25.10 default)       | Python runtime         |
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
| `playwright`       | **1.55.1** | ✅ Latest stable                                 |
| `cypress`          | **13.15.0** | ✅ **Security Fix** (CVE-2025-9288)              |
| `@playwright/test` | **1.55.1** | ✅ Test framework                                |
| `flat`             | **5.0.2**  | ✅ **Security Fix** (VDB-216777, CVE-2020-36632) |
| `sha.js`           | **2.4.12** | ✅ **Security Fix** (CVE-2025-9288)              |
| `ws`               | **8.17.1** | ✅ **Security Fix** (CVE-2024-37890)             |
| `nodejs`           | **24.11.1** | ✅ Latest LTS for Chrome Runner                  |

### Python Ecosystem

#### Standard Runner

| Package                | Version | Purpose          |
| ---------------------- | ------- | ---------------- |
| `pyyaml`               | Latest  | YAML processing  |
| `requests`             | Latest  | HTTP library     |
| `boto3`                | Latest  | AWS SDK          |
| `azure-cli`            | Latest  | Azure CLI        |
| `google-cloud-storage` | Latest  | Google Cloud SDK |
| `python3`              | 3.10+   | Python runtime   |

#### Chrome Runner

| Package             | Version | Purpose              |
| ------------------- | ------- | -------------------- |
| `selenium`          | Latest  | Browser automation   |
| `pytest`            | Latest  | Testing framework    |
| `pytest-selenium`   | Latest  | Selenium integration |
| `webdriver-manager` | Latest  | WebDriver management |

## Browser and Testing Tools (Chrome Runner Only)

### Google Chrome

- **Version**: 142.0.7444.162 (Stable channel)
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
| `libasound2t64`      | ALSA sound library (Ubuntu 24.04) |
| `libgtk-3-0`         | GTK+ 3.0 GUI toolkit       |

### Fonts and Display

| Package                  | Purpose                             |
| ------------------------ | ----------------------------------- |
| `fonts-liberation`       | Liberation fonts                    |
| `fonts-noto-color-emoji` | Color emoji support                 |
| `fonts-noto-cjk`         | CJK (Chinese/Japanese/Korean) fonts |
| `xvfb`                   | Virtual display server (Ubuntu 24.04) |

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
  - Upgraded Cypress to `13.15.0`
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


### Standard Runner Health Check

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD pgrep -f "Runner.Listener" || exit 1
```


### Chrome Runner Health Check

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD pgrep -f "Runner.Listener" > /dev/null || exit 1
```

## Environment Configuration


### Standard Runner Environment Variables

- `RUNNER_WORKDIR=/home/runner/_work`
- `RUNNER_ALLOW_RUNASROOT=false`
- `DEBIAN_FRONTEND=noninteractive`


### Chrome Runner Environment Variables

- `CHROME_BIN=/usr/bin/google-chrome-stable`
- `DISPLAY=:99`
- `DEBIAN_FRONTEND=noninteractive`

## Volume Mounts


### Standard Runner Volume Mounts

- `/home/runner/_work` - Persistent workspace
- `/home/runner/.cache` - Build and dependency cache


### Chrome Runner Volume Mounts

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

- **2025-11-14**: Release v2.2.0 with npm `tar@7.5.2` override, Chrome 142.0.7444.162, Playwright 1.55.1, Cypress 13.15.0, and refreshed Questing-based documentation.
- **2025-09-14**: Updated to Ubuntu 25.10 Questing, image version v2.0.9, Chrome 142.0.7444.162, Playwright 1.55.0, Cypress 15.1.0, Node.js 24.11.1 (Chrome Runner only), and architecture enforcement (amd64 only)
- **2025-09-10**: Extensive documentation update for Ubuntu 24.04 LTS, image version v2.0.2, Node.js 24.11.1 (Chrome Runner only), and architecture enforcement (amd64 only)
- **2025-01-15**: Applied VDB-216777/CVE-2020-36632 flat package security fix
- **2025-01-15**: Added comprehensive security patches for Chrome Runner
- **2025-01-15**: Implemented comprehensive cache cleaning strategy
- **2025-01-15**: Standardized Docker build contexts across workflows

### Next Planned Updates

- Monitor for new GitHub Actions runner releases
- Regular security scanning with Trivy
- Dependency updates based on security advisories
- Performance optimization based on usage patterns

---

**Last Updated**: November 14, 2025 (Synced with code and workflows)
**Document Version**: 2.0  
**Maintainer**: GrammaTonic
