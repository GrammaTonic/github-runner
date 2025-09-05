# GitHub Actions Self-Hosted Runner Docker Image
# Multi-stage build for optimized final image

# Build stage - Install dependencies and build tools
FROM ubuntu:24.04 AS builder

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Download and prepare GitHub Actions runner
ARG RUNNER_VERSION="2.328.0"
ARG TARGETPLATFORM

WORKDIR /actions-runner

# Download the appropriate runner based on architecture
RUN case "${TARGETPLATFORM}" in \
    "linux/amd64") RUNNER_ARCH="x64" ;; \
    "linux/arm64") RUNNER_ARCH="arm64" ;; \
    *) echo "Unsupported platform: ${TARGETPLATFORM}" && exit 1 ;; \
    esac \
    && curl -o "actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
    -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
    && tar xzf "actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
    && rm "actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"

# Production stage - Minimal runtime image  
FROM ubuntu:24.04

# Metadata
LABEL maintainer="GrammaTonic"
LABEL description="GitHub Actions Self-Hosted Runner with Docker support"
LABEL version="1.0.1"

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Create runner user
RUN useradd -m -s /bin/bash runner

# Install runtime dependencies
# hadolint ignore=DL3008,DL3015
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core tools
    curl \
    wget \
    unzip \
    tar \
    gzip \
    ca-certificates \
    # Version control
    git \
    git-lfs \
    # Build tools
    build-essential \
    # Python ecosystem
    python3 \
    python3-pip \
    python3-venv \
    # Docker CLI (for Docker-in-Docker scenarios)
    docker.io \
    # Utilities
    jq \
    zip \
    # Network tools
    iputils-ping \
    netcat-openbsd \
    # Process tools
    htop \
    psmisc \
    && rm -rf /var/lib/apt/lists/*

# Set shell with pipefail for safer pipe operations
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Node.js from NodeSource repository (replaces obsolete nodejs package)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install additional tools via pip
# WARNING: Installing multiple cloud provider CLIs (boto3, azure-cli, google-cloud-storage)
# significantly increases image size and attack surface. Consider creating specialized images
# for specific cloud providers or using multi-stage builds to reduce the final image size.
# For minimal installations, remove unused cloud CLIs.
# hadolint ignore=DL3013
RUN python3 -m pip install --no-cache-dir --break-system-packages \
    pyyaml \
    requests \
    boto3 \
    azure-cli \
    google-cloud-storage

# Install additional tools via npm
# hadolint ignore=DL3016
RUN npm install -g \
    @actions/core \
    @actions/github \
    typescript \
    eslint \
    prettier \
    && echo "Applying security fix for flat package vulnerability (VDB-216777)..." \
    && npm install -g flat@5.0.2 --force 2>/dev/null || true \
    && echo "Cleaning npm cache and temporary files..." \
    && npm cache clean --force \
    && rm -rf /tmp/* /var/tmp/* /root/.npm

# Copy runner from builder stage and set up directories
COPY --from=builder /actions-runner /home/runner/actions-runner
RUN chown -R runner:runner /home/runner \
    && mkdir -p /home/runner/work \
    && mkdir -p /home/runner/_work \
    && mkdir -p /home/runner/.cache \
    && chown -R runner:runner /home/runner \
    && usermod -aG docker runner

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Final cleanup to minimize image size
RUN echo "Final cleanup to minimize image size..." \
    && apt-get autoremove -y \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* /var/tmp/* \
    && rm -rf /var/log/* \
    && rm -rf /root/.cache \
    && find /usr/share/doc -type f -delete 2>/dev/null || true \
    && find /usr/share/man -type f -delete 2>/dev/null || true

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "Runner.Listener" || exit 1

# Switch to runner user
USER runner
WORKDIR /home/runner

# Environment variables
ENV RUNNER_WORKDIR=/home/runner/_work
ENV RUNNER_ALLOW_RUNASROOT=false

# Volume mounts for persistence
VOLUME ["/home/runner/_work", "/home/runner/.cache"]

# Expose ports (if needed for debugging)
EXPOSE 8080

# Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
