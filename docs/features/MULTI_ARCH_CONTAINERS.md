# Multi-Architecture Container Support Feature

## Status: 🚧 In Development

**Created:** 2025-11-16  
**Feature Branch:** `feature/multi-arch-containers`  
**Target Release:** v2.3.0  
**Priority:** High

---

## 📋 Executive Summary

Implement multi-architecture container image support for GitHub Actions self-hosted runners, enabling deployment on both AMD64 (x86_64) and ARM64 (aarch64) platforms. This will support diverse infrastructure including Apple Silicon Macs, AWS Graviton instances, Raspberry Pi clusters, and traditional x86 servers.

**What's Included:**
- ✅ Multi-architecture Docker builds (linux/amd64, linux/arm64)
- ✅ GitHub Actions workflow for automated multi-arch builds
- ✅ Docker Buildx configuration with QEMU emulation
- ✅ Manifest lists for automatic architecture selection
- ✅ Testing on both architectures
- ✅ Documentation for deployment on ARM platforms

**Out of Scope:**
- ❌ Windows containers
- ❌ macOS containers
- ❌ Other architectures (s390x, ppc64le, riscv64)

---

## 🎯 Objectives

### Primary Goals
1. **Cross-Platform Support**: Enable runner deployment on AMD64 and ARM64 Linux hosts
2. **Automated Builds**: Multi-arch builds via GitHub Actions CI/CD
3. **Performance**: Native performance on ARM platforms (no emulation overhead)
4. **Compatibility**: Maintain 100% feature parity across architectures
5. **Easy Deployment**: Automatic architecture detection via Docker manifest

### Success Criteria
- [ ] Docker images built for both linux/amd64 and linux/arm64
- [ ] All 3 runner variants support multi-arch (standard, Chrome, Chrome-Go)
- [ ] CI/CD pipeline builds and tests both architectures
- [ ] Images published to GitHub Container Registry with manifest lists
- [ ] Documentation for ARM deployment (AWS Graviton, Raspberry Pi, etc.)
- [ ] Performance benchmarks showing native ARM performance
- [ ] Zero breaking changes for existing AMD64 deployments

---

## 🏗️ Architecture

### Current State (AMD64 Only)

```
┌─────────────────────────────────────────────────────────────┐
│                    Current Architecture                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  GitHub Actions CI/CD                                        │
│         │                                                     │
│         ├──> Build Docker Image (linux/amd64)                │
│         │                                                     │
│         └──> Push to ghcr.io/grammatonic/github-runner:tag   │
│                                                               │
│  Deployment:                                                 │
│         Pull image on AMD64 host ✅                          │
│         Pull image on ARM64 host ❌ (fails or emulated)      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Proposed Multi-Arch Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│              Multi-Architecture Build & Deploy                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  GitHub Actions CI/CD (ubuntu-latest runner)                        │
│         │                                                             │
│         ├──> Setup Docker Buildx with QEMU                          │
│         │         │                                                   │
│         │         ├──> Install QEMU static binaries                  │
│         │         └──> Create buildx builder with multi-platform     │
│         │                                                             │
│         ├──> Build Multi-Arch Images                                │
│         │         │                                                   │
│         │         ├──> Build linux/amd64 (native)                   │
│         │         │     - Fast build on x86 runner                   │
│         │         │                                                   │
│         │         └──> Build linux/arm64 (emulated via QEMU)        │
│         │               - Slower build but validates ARM             │
│         │                                                             │
│         └──> Create Manifest List & Push                            │
│                   │                                                   │
│                   └──> ghcr.io/grammatonic/github-runner:tag         │
│                             │                                         │
│                             ├──> AMD64 image digest                  │
│                             └──> ARM64 image digest                  │
│                                                                       │
│  Deployment (Automatic Architecture Selection):                     │
│         │                                                             │
│         ├──> AMD64 host pulls AMD64 image ✅                        │
│         └──> ARM64 host pulls ARM64 image ✅                        │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Components

#### 1. Docker Buildx with QEMU
- **Purpose**: Enable cross-platform builds on GitHub Actions runners
- **Technology**: Docker Buildx, QEMU static binaries
- **Build Strategy**: Native AMD64 build, emulated ARM64 build
- **Alternative**: Use GitHub's ARM runners when available (faster)

#### 2. Multi-Stage Dockerfiles (Architecture-Aware)
- **Base Images**: Multi-arch Ubuntu 24.04 (supports both platforms)
- **Dependencies**: Architecture-specific package selection
- **Binary Downloads**: Conditional URLs based on `TARGETPLATFORM`
- **Node.js**: Use official multi-arch Node.js binaries
- **Chrome**: Use Google Chrome for ARM64 (available since Chrome 93)
- **Go**: Use official Go ARM64 binaries for Chrome-Go variant

#### 3. GitHub Actions Workflow Updates
- **Builder Setup**: Configure buildx with platforms
- **Build Command**: `docker buildx build --platform linux/amd64,linux/arm64`
- **Push Strategy**: Create and push manifest list
- **Testing**: Test images on both architectures (emulated or native)

#### 4. Image Manifest Lists
- **Format**: OCI/Docker manifest list
- **Contents**: References to architecture-specific images
- **Automatic Selection**: Docker pulls correct image for host architecture
- **Tags**: Same tag points to different digests per architecture

---

## 🚀 Implementation Plan

### Phase 1: Infrastructure Setup (Week 1)

**Objective:** Configure build infrastructure for multi-arch support.

**Tasks:**
- [ ] Research base image multi-arch support (Ubuntu 24.04)
- [ ] Update Dockerfiles with `ARG TARGETPLATFORM` and `ARG TARGETARCH`
- [ ] Add architecture-specific dependency installation logic
- [ ] Configure Docker Buildx in CI/CD workflow
- [ ] Set up QEMU for ARM64 emulation
- [ ] Test basic multi-arch build locally

**Files to Modify:**
- `.github/workflows/ci-cd.yml` - Add buildx setup
- `docker/Dockerfile` - Add multi-arch support
- `docker/Dockerfile.chrome` - Add multi-arch support
- `docker/Dockerfile.chrome-go` - Add multi-arch support

**Example Dockerfile Changes:**
```dockerfile
# Before (AMD64 only)
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y curl

# After (Multi-arch)
FROM ubuntu:24.04

# Buildx provides these automatically
ARG TARGETPLATFORM
ARG TARGETARCH

RUN apt-get update && apt-get install -y curl

# Architecture-specific downloads
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        ARCH="x64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        ARCH="arm64"; \
    fi && \
    curl -fsSL "https://example.com/download-${ARCH}" -o /tmp/binary
```

**Example Workflow Changes:**
```yaml
# .github/workflows/ci-cd.yml
- name: Set up QEMU
  uses: docker/setup-qemu-action@v3

- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3

- name: Build and push multi-arch image
  uses: docker/build-push-action@v5
  with:
    context: ./docker
    file: ./docker/Dockerfile
    platforms: linux/amd64,linux/arm64
    push: true
    tags: ghcr.io/grammatonic/github-runner:latest
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

---

### Phase 2: Dockerfile Updates (Week 1-2)

**Objective:** Update all Dockerfiles to support multi-architecture builds.

**Standard Runner (`docker/Dockerfile`):**

**Key Changes:**
- [ ] Use multi-arch base image (ubuntu:24.04 already supports both)
- [ ] Add `TARGETPLATFORM` and `TARGETARCH` args
- [ ] Update Node.js download for architecture detection
- [ ] Update GitHub Runner download for architecture detection
- [ ] Test on both architectures

**Architecture-Specific Downloads:**
```dockerfile
# GitHub Actions Runner
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        RUNNER_ARCH="x64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        RUNNER_ARCH="arm64"; \
    fi && \
    curl -fsSL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
        -o actions-runner.tar.gz

# Node.js (if needed)
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        NODE_ARCH="x64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        NODE_ARCH="arm64"; \
    fi && \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" \
        -o node.tar.xz
```

**Chrome Runner (`docker/Dockerfile.chrome`):**

**Key Changes:**
- [ ] Chrome for ARM64 (available since Chrome 93+)
- [ ] Playwright ARM64 support
- [ ] Architecture-specific Chrome download
- [ ] Test Chrome browser functionality on ARM64

**Chrome ARM64 Installation:**
```dockerfile
# Google Chrome (supports ARM64 since Chrome 93)
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        CHROME_DEB="google-chrome-stable_current_amd64.deb"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        CHROME_DEB="google-chrome-stable_current_arm64.deb"; \
    fi && \
    curl -fsSL "https://dl.google.com/linux/direct/${CHROME_DEB}" -o /tmp/chrome.deb && \
    apt-get install -y /tmp/chrome.deb && \
    rm /tmp/chrome.deb
```

**Chrome-Go Runner (`docker/Dockerfile.chrome-go`):**

**Key Changes:**
- [ ] Go ARM64 binaries (official support available)
- [ ] Chrome ARM64 (same as Chrome runner)
- [ ] Test Go compilation on ARM64

**Go ARM64 Installation:**
```dockerfile
# Go toolchain
ARG GO_VERSION=1.25.4
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        GO_ARCH="amd64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        GO_ARCH="arm64"; \
    fi && \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" \
        -o go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz
```

---

### Phase 3: CI/CD Pipeline Updates (Week 2)

**Objective:** Automate multi-arch builds in GitHub Actions.

**Tasks:**
- [ ] Update workflow to use `docker/setup-qemu-action@v3`
- [ ] Update workflow to use `docker/setup-buildx-action@v3`
- [ ] Add platform specification to build steps
- [ ] Update caching strategy for multi-arch builds
- [ ] Add architecture-specific testing
- [ ] Update release workflow for multi-arch manifests

**Workflow Structure:**
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  build-multi-arch:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        runner-type: [standard, chrome, chrome-go]
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3
        with:
          platforms: linux/amd64,linux/arm64
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
        with:
          driver-opts: |
            image=moby/buildkit:latest
      
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push ${{ matrix.runner-type }} (multi-arch)
        uses: docker/build-push-action@v5
        with:
          context: ./docker
          file: ./docker/Dockerfile${{ matrix.runner-type == 'standard' && '' || format('.{0}', matrix.runner-type) }}
          platforms: linux/amd64,linux/arm64
          push: ${{ github.event_name != 'pull_request' }}
          tags: |
            ghcr.io/grammatonic/github-runner-${{ matrix.runner-type }}:latest
            ghcr.io/grammatonic/github-runner-${{ matrix.runner-type }}:${{ github.sha }}
          cache-from: type=gha,scope=buildcache-${{ matrix.runner-type }}
          cache-to: type=gha,mode=max,scope=buildcache-${{ matrix.runner-type }}
          provenance: false  # Disable provenance to avoid manifest issues
```

**Build Time Expectations:**
- AMD64 build: ~3-5 minutes (native)
- ARM64 build: ~15-25 minutes (emulated via QEMU)
- Total build time: ~20-30 minutes per variant
- Parallel builds: 3 variants × 2 architectures = ~30 minutes total

**Optimization Strategies:**
- Use GitHub Actions cache for layer caching
- Consider ARM64 GitHub runners when available (faster native builds)
- Parallelize builds across runner types
- Use BuildKit cache mounts for dependencies

---

### Phase 4: Testing & Validation (Week 2-3)

**Objective:** Validate multi-arch images work correctly on both platforms.

**Tasks:**
- [ ] Create test workflow for ARM64 validation
- [ ] Test standard runner on emulated ARM64
- [ ] Test Chrome runner on emulated ARM64 (browser functionality)
- [ ] Test Chrome-Go runner on emulated ARM64 (Go compilation)
- [ ] Performance benchmarking (AMD64 vs ARM64)
- [ ] Documentation of architecture-specific quirks

**Testing Strategy:**

**Emulated Testing (GitHub Actions):**
```yaml
- name: Test ARM64 image (emulated)
  run: |
    docker run --rm --platform linux/arm64 \
      -e RUNNER_NAME=test-arm64 \
      -e RUNNER_TYPE=standard \
      ghcr.io/grammatonic/github-runner:latest \
      --version
```

**Native ARM64 Testing (if available):**
- AWS Graviton EC2 instances (t4g, c7g, r7g families)
- Azure ARM-based VMs (Dpsv5, Epsv5 series)
- Raspberry Pi 4/5 (hobbyist testing)
- Apple Silicon Mac with Docker Desktop (local testing)

**Test Cases:**
- [ ] Runner registration and startup
- [ ] Job execution (simple workflow)
- [ ] Docker-in-Docker functionality
- [ ] Chrome browser automation (Chrome variants)
- [ ] Go compilation (Chrome-Go variant)
- [ ] Network connectivity
- [ ] Volume mounts and file I/O
- [ ] Memory and CPU usage comparison

---

### Phase 5: Documentation & Deployment (Week 3)

**Objective:** Document multi-arch support and deployment patterns.

**Tasks:**
- [ ] Update README with multi-arch information
- [ ] Create ARM deployment guide
- [ ] Document AWS Graviton deployment
- [ ] Document Raspberry Pi deployment
- [ ] Add architecture detection to deployment scripts
- [ ] Update troubleshooting guide

**Documentation Files:**
- [ ] `docs/MULTI_ARCH_DEPLOYMENT.md` - Comprehensive deployment guide
- [ ] `docs/ARM64_PLATFORMS.md` - Platform-specific guides
- [ ] `docs/PERFORMANCE_ARM64.md` - Performance benchmarks
- [ ] Update `README.md` - Add multi-arch badges and notes
- [ ] Update `docs/DEPLOYMENT.md` - Add architecture selection

**Example Documentation:**
```markdown
## Multi-Architecture Support

The GitHub Actions runner images support both AMD64 (x86_64) and ARM64 (aarch64) architectures:

### Automatic Architecture Detection

Docker automatically pulls the correct image for your host architecture:

```bash
# On AMD64 host - pulls AMD64 image
docker pull ghcr.io/grammatonic/github-runner:latest

# On ARM64 host - pulls ARM64 image
docker pull ghcr.io/grammatonic/github-runner:latest
```

### Explicit Architecture Selection

Force a specific architecture:

```bash
# Force AMD64 (may use emulation on ARM64)
docker pull --platform linux/amd64 ghcr.io/grammatonic/github-runner:latest

# Force ARM64 (may use emulation on AMD64)
docker pull --platform linux/arm64 ghcr.io/grammatonic/github-runner:latest
```

### Supported Platforms

- **AWS Graviton**: EC2 instances (t4g, c7g, r7g families)
- **Azure ARM**: Dpsv5, Epsv5 VM series
- **Raspberry Pi**: Pi 4/5 with 64-bit OS
- **Apple Silicon**: M1/M2/M3 Macs with Docker Desktop
- **Oracle Cloud**: Ampere A1 instances (ARM-based)
```

---

## 📊 Expected Benefits

### Performance
- **Native ARM64 Performance**: No emulation overhead on ARM hosts
- **Cost Savings**: AWS Graviton instances are ~20% cheaper than x86
- **Energy Efficiency**: ARM64 typically more power-efficient

### Compatibility
- **Broader Platform Support**: Run on x86 and ARM infrastructure
- **Future-Proof**: Trend towards ARM in cloud (Graviton, Azure Cobalt)
- **Developer Experience**: Support for Apple Silicon developers

### Operational
- **Simplified Management**: Single image tag, automatic architecture selection
- **No Code Changes**: Existing deployments continue to work
- **Flexible Infrastructure**: Choose architecture based on workload

---

## 🚨 Risks & Mitigations

### Risk 1: Build Time Increase
**Impact:** ARM64 emulated builds are 3-5x slower than native  
**Mitigation:** 
- Use GitHub Actions cache aggressively
- Consider GitHub ARM runners when available
- Parallelize builds

### Risk 2: Architecture-Specific Bugs
**Impact:** Different behavior on AMD64 vs ARM64  
**Mitigation:**
- Comprehensive testing on both architectures
- Monitor production deployments
- Quick rollback capability

### Risk 3: Dependency Availability
**Impact:** Some packages may not have ARM64 versions  
**Mitigation:**
- Audit all dependencies before implementation
- Test builds early in development
- Document any ARM64 limitations

### Risk 4: Image Size Increase
**Impact:** Manifest lists may increase registry storage  
**Mitigation:**
- Images are stored separately, not duplicated
- Total size is sum of both architectures
- Use layer caching to minimize duplication

---

## 🎯 Acceptance Criteria

- [ ] All 3 runner variants build successfully for linux/amd64 and linux/arm64
- [ ] Images published to ghcr.io with manifest lists
- [ ] Automatic architecture selection works (tested on both platforms)
- [ ] CI/CD pipeline builds and tests multi-arch images
- [ ] Build time < 30 minutes for all variants (parallel)
- [ ] ARM64 images are functionally equivalent to AMD64
- [ ] Documentation complete with deployment examples
- [ ] Performance benchmarks published
- [ ] Zero breaking changes for existing AMD64 users
- [ ] All tests pass on both architectures

---

## 📖 References

- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [Multi-platform Images Guide](https://docs.docker.com/build/building/multi-platform/)
- [GitHub Actions: Build and Push Docker Images](https://github.com/marketplace/actions/build-and-push-docker-images)
- [QEMU User Emulation](https://www.qemu.org/docs/master/user/main.html)
- [AWS Graviton](https://aws.amazon.com/ec2/graviton/)
- [GitHub Actions Runner ARM64 Support](https://github.com/actions/runner/issues/688)
- [Chrome ARM64 Availability](https://support.google.com/chrome/a/answer/7100626)

---

## 📝 Implementation Notes

### Platform Detection in Dockerfiles

Use `TARGETPLATFORM` and `TARGETARCH` build args:

```dockerfile
ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETOS
ARG TARGETVARIANT

# Example: Download architecture-specific binary
RUN case ${TARGETARCH} in \
        "amd64")  ARCH="x64"    ;; \
        "arm64")  ARCH="arm64"  ;; \
        "arm")    ARCH="armv7l" ;; \
        *)        echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    curl -fsSL "https://example.com/download-${ARCH}" -o /tmp/binary
```

### GitHub Actions Runner Platform Support

GitHub Actions runner supports ARM64 since v2.285.0:
- Download: `actions-runner-linux-arm64-${VERSION}.tar.gz`
- Full feature parity with AMD64
- Official support from GitHub

### Known Limitations

**Chrome Runner:**
- Chrome ARM64 requires Chrome 93+ (currently available)
- Playwright has ARM64 support
- Performance may differ slightly between architectures

**Chrome-Go Runner:**
- Go has full ARM64 support since Go 1.5
- Cross-compilation works the same on both platforms
- No known limitations

---

**Last Updated:** 2025-11-16  
**Status:** Planning Phase  
**Estimated Completion:** 3 weeks
