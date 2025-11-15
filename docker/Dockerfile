# It includes system setup, user creation, and the GitHub Actions runner installation.
FROM ubuntu:questing

# --- METADATA AND ARGUMENTS ---
LABEL maintainer="GrammaTonic"
LABEL description="Base image for GitHub Actions Self-Hosted Runners"
LABEL version="2.2.0"

# Use TARGETPLATFORM which contains the full OS/architecture string (e.g., linux/amd64)
ARG TARGETPLATFORM
ARG RUNNER_VERSION="2.329.0"
ARG CROSS_SPAWN_VERSION="7.0.6"
ARG TAR_VERSION="7.5.2"
ARG BRACE_EXPANSION_VERSION="2.0.2"
ENV RUNNER_VERSION=${RUNNER_VERSION}
ENV CROSS_SPAWN_VERSION=${CROSS_SPAWN_VERSION}
ENV TAR_VERSION=${TAR_VERSION}
ENV BRACE_EXPANSION_VERSION=${BRACE_EXPANSION_VERSION}

# --- ENVIRONMENT VARIABLES ---
ENV DEBIAN_FRONTEND=noninteractive

# Set SHELL to handle pipe errors correctly
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- SETUP APT FOR DOCKER IMAGES AND UPDATE UBUNTU ---
# Use BuildKit cache mounts for apt to speed up builds
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker \
    && echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache \
    && apt-get update && apt-get upgrade -y

# --- SETUP AS ROOT USER ---
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg git jq libicu-dev python3 python3-pip python3-venv \
    docker.io build-essential iputils-ping

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

RUN --mount=type=cache,target=/tmp/npm-cache,uid=1001,gid=1001 \
    set -e; \
    for NODE_ROOT in /actions-runner/externals/node*/ ; do \
        if [ -x "${NODE_ROOT}bin/node" ] && [ -d "${NODE_ROOT}lib/node_modules/npm" ]; then \
            NPM_DIR="${NODE_ROOT}lib/node_modules/npm"; \
            PATCH_DIR="$(mktemp -d)"; \
            printf '{\n  "name": "runner-patch",\n  "private": true,\n  "version": "1.0.0",\n  "dependencies": {\n    "cross-spawn": "%s",\n    "tar": "%s",\n    "brace-expansion": "%s"\n  }\n}\n' "${CROSS_SPAWN_VERSION}" "${TAR_VERSION}" "${BRACE_EXPANSION_VERSION}" > "${PATCH_DIR}/package.json"; \
            "${NODE_ROOT}bin/node" "${NPM_DIR}/bin/npm-cli.js" install --prefix="${PATCH_DIR}" --omit=dev --cache /tmp/npm-cache; \
            rm -rf "${NPM_DIR}/node_modules/cross-spawn" "${NPM_DIR}/node_modules/tar" "${NPM_DIR}/node_modules/brace-expansion"; \
            cp -a "${PATCH_DIR}/node_modules/." "${NPM_DIR}/node_modules/"; \
            rm -rf "${PATCH_DIR}" "${NPM_DIR}/node_modules/.npm"; \
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