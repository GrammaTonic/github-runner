# Multi-stage build for GitHub Actions Self-Hosted Runner
# Stage 1: Builder - Download and prepare runner with build tools
FROM ubuntu:questing AS builder

# --- METADATA AND ARGUMENTS ---
ARG TARGETPLATFORM
ARG RUNNER_VERSION="2.329.0"
ARG CROSS_SPAWN_VERSION="7.0.6"
ARG TAR_VERSION="7.5.2"
ARG BRACE_EXPANSION_VERSION="2.0.2"

# --- ENVIRONMENT VARIABLES ---
ENV DEBIAN_FRONTEND=noninteractive

# Set SHELL to handle pipe errors correctly
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- SETUP APT AND INSTALL BUILD DEPENDENCIES ---
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker \
    && echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache \
    && apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends curl ca-certificates

# --- CREATE RUNNER USER FOR BUILD STAGE ---
RUN useradd -m -s /bin/bash -u 1001 runner

# --- DOWNLOAD AND EXTRACT GITHUB ACTIONS RUNNER ---
USER runner
WORKDIR /actions-runner
# Use BuildKit cache for GitHub Actions runner download
RUN --mount=type=cache,target=/tmp/downloads,uid=1001,gid=1001 \
    set -e; \
    url="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"; \
    cache_file="/tmp/downloads/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"; \
    if [ ! -f "$cache_file" ]; then \
        for i in 1 2 3; do \
            echo "Downloading GitHub Actions Runner v${RUNNER_VERSION} (attempt $i)..."; \
            if curl -fSL -o "$cache_file" "$url"; then break; fi; \
            echo "Download failed, retrying in 3s..."; sleep 3; \
        done; \
    else \
        echo "Using cached GitHub Actions Runner v${RUNNER_VERSION}"; \
    fi; \
    tar xzf "$cache_file"

# --- PATCH EMBEDDED NODE DISTRIBUTIONS IN BUILDER ---
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

# Stage 2: Runtime - Minimal image with only runtime dependencies
FROM ubuntu:questing AS runtime

# --- METADATA ---
LABEL maintainer="GrammaTonic"
LABEL description="Multi-stage GitHub Actions Self-Hosted Runner (optimized)"
LABEL version="2.2.0"

# --- ARGUMENTS FOR RUNTIME ---
ARG RUNNER_VERSION="2.329.0"
ARG CROSS_SPAWN_VERSION="7.0.6"
ARG TAR_VERSION="7.5.2"
ARG BRACE_EXPANSION_VERSION="2.0.2"

ENV RUNNER_VERSION=${RUNNER_VERSION}
ENV CROSS_SPAWN_VERSION=${CROSS_SPAWN_VERSION}
ENV TAR_VERSION=${TAR_VERSION}
ENV BRACE_EXPANSION_VERSION=${BRACE_EXPANSION_VERSION}
ENV DEBIAN_FRONTEND=noninteractive

# Set SHELL to handle pipe errors correctly
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- SETUP APT AND INSTALL RUNTIME DEPENDENCIES ONLY ---
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker \
    && echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache \
    && apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    ca-certificates git jq libicu-dev python3 python3-pip python3-venv \
    docker.io iputils-ping procps

# --- USER AND DIRECTORIES ---
RUN useradd -m -s /bin/bash -u 1001 runner \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p /home/runner/workspace /actions-runner \
    && chown -R runner:runner /home/runner /actions-runner

# --- COPY RUNNER FROM BUILDER STAGE ---
USER runner
WORKDIR /actions-runner
COPY --from=builder --chown=runner:runner /actions-runner /actions-runner
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