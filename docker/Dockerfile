# It includes system setup, user creation, and the GitHub Actions runner installation.
FROM ubuntu:questing

# --- METADATA AND ARGUMENTS ---
LABEL maintainer="GrammaTonic"
LABEL description="Base image for GitHub Actions Self-Hosted Runners"
LABEL version="2.0.9"

# Use TARGETPLATFORM which contains the full OS/architecture string (e.g., linux/amd64)
ARG TARGETPLATFORM
ARG RUNNER_VERSION="2.329.0"
ARG CROSS_SPAWN_VERSION="7.0.6"
ENV RUNNER_VERSION=${RUNNER_VERSION}
ENV CROSS_SPAWN_VERSION=${CROSS_SPAWN_VERSION}

# --- ENVIRONMENT VARIABLES ---
ENV DEBIAN_FRONTEND=noninteractive

# Set SHELL to handle pipe errors correctly
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- SETUP APT FOR DOCKER IMAGES AND UP DATE UBUNTU ---
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker \
    && echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker \
    && apt-get update && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# --- SETUP AS ROOT USER ---
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg git jq libicu-dev python3 python3-pip python3-venv \
    docker.io build-essential iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# --- USER AND DIRECTORIES ---
RUN useradd -m -s /bin/bash runner \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p /home/runner/workspace /actions-runner \
    && chown -R runner:runner /home/runner /actions-runner
# --- INSTALL GITHUB ACTIONS RUNNER ---

# Keep RUNNER_VERSION available in this stage
ARG RUNNER_VERSION
USER runner
WORKDIR /actions-runner
RUN set -e; \
        url="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"; \
        for i in 1 2 3; do \
            echo "Downloading GitHub Actions Runner v${RUNNER_VERSION} (attempt $i)..."; \
            if curl -fSL -o actions-runner.tar.gz "$url"; then break; fi; \
            echo "Download failed, retrying in 3s..."; sleep 3; \
        done; \
        tar xzf "./actions-runner.tar.gz"; \
        rm "./actions-runner.tar.gz"

RUN set -e; \
        for NODE_ROOT in /actions-runner/externals/node*/ ; do \
            if [ -x "${NODE_ROOT}bin/node" ] && [ -d "${NODE_ROOT}lib/node_modules/npm" ]; then \
                NPM_DIR="${NODE_ROOT}lib/node_modules/npm"; \
                rm -rf "${NPM_DIR}/node_modules/cross-spawn"; \
                "${NODE_ROOT}bin/node" "${NPM_DIR}/bin/npm-cli.js" install cross-spawn@${CROSS_SPAWN_VERSION} --omit=dev --no-save --cache /tmp/npm-cache; \
                rm -rf "${NPM_DIR}/node_modules/.npm" /tmp/npm-cache; \
            fi; \
        done
WORKDIR /home/runner

# Copy the dedicated entrypoint
COPY --chown=runner:runner entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh


# Final image runs as unprivileged runner user.
USER runner
WORKDIR /home/runner

# --- HEALTHCHECK AND ENTRYPOINT ---
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "Runner.Listener" > /dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]