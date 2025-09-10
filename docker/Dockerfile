# hadolint ignore=DL3002
# --- BASE IMAGE ---
# This is the common base for all runner types.
# It includes system setup, user creation, and the GitHub Actions runner installation.
FROM ubuntu:22.04 AS base

# --- METADATA AND ARGUMENTS ---
LABEL maintainer="GrammaTonic"
LABEL description="Base image for GitHub Actions Self-Hosted Runners"

# Use TARGETPLATFORM which contains the full OS/architecture string (e.g., linux/amd64)
ARG TARGETPLATFORM
ARG RUNNER_VERSION="2.328.0"

# --- ENVIRONMENT VARIABLES ---
ENV DEBIAN_FRONTEND=noninteractive

# Set SHELL to handle pipe errors correctly
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- SETUP AS ROOT USER ---

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates gnupg git jq libicu-dev python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

# --- USER AND DIRECTORIES ---
RUN useradd -m -s /bin/bash runner \
    && usermod -aG sudo runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p /home/runner/workspace /actions-runner \
    && chown -R runner:runner /home/runner /actions-runner

# --- GITHUB ACTIONS RUNNER (MULTI-STAGE) ---
FROM base AS builder
## hadolint ignore=DL3002
USER root
WORKDIR /tmp

# Download the correct runner for the architecture using TARGETPLATFORM
RUN case "${TARGETPLATFORM}" in \
      "linux/amd64") RUNNER_ARCH="x64" ;; \
      "linux/arm64") RUNNER_ARCH="arm64" ;; \
      *) echo "Unsupported platform: ${TARGETPLATFORM}" && exit 1 ;; \
    esac \
    && curl -o "actions-runner.tar.gz" -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
    && tar xzf "./actions-runner.tar.gz" \
    && rm "./actions-runner.tar.gz"


# --- FINAL BASE IMAGE CONSTRUCTION ---
FROM base
COPY --from=builder --chown=runner:runner /tmp /actions-runner

# Install Docker and other general-purpose tools as root
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        docker.io \
        build-essential \
        iputils-ping \
        && usermod -aG docker runner \
        && rm -rf /var/lib/apt/lists/*

# Copy the dedicated entrypoint
COPY --chown=runner:runner entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to runner for final image
USER runner
WORKDIR /home/runner

# --- HEALTHCHECK AND ENTRYPOINT ---
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "Runner.Listener" > /dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]