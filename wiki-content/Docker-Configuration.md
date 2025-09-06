# Docker Configuration

Complete guide to configuring Docker and Docker Compose for GitHub Actions self-hosted runners.

## 🐳 Docker Architecture

### Container Structure

```
┌─────────────────────────────────────────┐
│               Load Balancer             │
├─────────────────────────────────────────┤
│  Runner 1   │  Runner 2   │  Runner 3  │
├─────────────────────────────────────────┤
│          Monitoring Stack              │
│  Prometheus │  Grafana   │  AlertMgr   │
├─────────────────────────────────────────┤
│           Shared Volumes               │
│   Cache    │  Workspace  │   Logs     │
└─────────────────────────────────────────┘
```

## 📁 Docker Compose Configuration

### Separate Architecture

The project uses separate Docker Compose files for different runner types:

```yaml
# docker/docker-compose.production.yml - Standard runners
services:
  github-runner:
    image: ghcr.io/grammatonic/github-runner:latest
    container_name: github-runner-main
    # ... configuration for standard CI/CD

# docker/docker-compose.chrome.yml - Chrome runners
services:
  github-runner-chrome:
    image: ghcr.io/grammatonic/github-runner:chrome-latest
    container_name: github-runner-chrome
    # ... configuration for UI testing
```

### Basic Setup

```yaml
# Standard runner deployment
services:
  github-runner:
    build:
      context: .
      dockerfile: Dockerfile
    image: ghcr.io/grammatonic/github-runner:latest
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - GITHUB_REPOSITORY=${GITHUB_REPOSITORY}
      - RUNNER_NAME=${RUNNER_NAME:-runner}
      - RUNNER_LABELS=${RUNNER_LABELS:-self-hosted,docker}
    volumes:
      - runner_workspace:/workspace
      - runner_cache:/cache
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: ${RUNNER_MEMORY_LIMIT:-2g}
          cpus: "${RUNNER_CPU_LIMIT:-1.0}"
        reservations:
          memory: 512m
          cpus: "0.25"

volumes:
  runner_workspace:
    driver: local
  runner_cache:
    driver: local

networks:
  default:
    name: ${DOCKER_NETWORK:-github-runner-network}
```

### Production Configuration

```yaml
# docker/docker-compose.prod.yml
version: "3.8"

services:
  github-runner:
    extends:
      file: docker-compose.production.yml
      service: github-runner
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
      resources:
        limits:
          memory: 4g
          cpus: "2.0"
    healthcheck:
      test: ["CMD", "/app/healthcheck.sh"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Monitoring services
  prometheus:
    image: prom/prometheus:latest
    profiles: ["monitoring"]
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
      - "--web.console.libraries=/etc/prometheus/console_libraries"
      - "--web.console.templates=/etc/prometheus/consoles"
      - "--web.enable-lifecycle"

  grafana:
    image: grafana/grafana:latest
    profiles: ["monitoring"]
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD:-admin}
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards:ro
      - ./monitoring/grafana/datasources:/etc/grafana/provisioning/datasources:ro

volumes:
  prometheus_data:
  grafana_data:
```

## 🏗️ Dockerfile Optimization

### Multi-Stage Build

```dockerfile
# docker/Dockerfile
FROM ubuntu:22.04 as base

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    git \
    wget \
    unzip \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# GitHub Actions Runner stage
FROM base as runner

ARG RUNNER_VERSION=2.328.0
ARG TARGETPLATFORM

# Create runner user
RUN useradd -m -s /bin/bash runner

# Download and install GitHub Actions runner
WORKDIR /actions-runner
RUN curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Install dependencies
RUN ./bin/installdependencies.sh

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set ownership
RUN chown -R runner:runner /actions-runner

USER runner
WORKDIR /actions-runner

ENTRYPOINT ["/entrypoint.sh"]
```

### Optimized Dockerfile

```dockerfile
# Production-optimized version
FROM ubuntu:22.04 as builder

# Build tools and dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Download runner
ARG RUNNER_VERSION=2.328.0
WORKDIR /tmp
RUN curl -o actions-runner.tar.gz \
    -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

FROM ubuntu:22.04 as runtime

# Runtime dependencies only
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    git \
    docker.io \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create runner user
RUN useradd -m -s /bin/bash runner

# Copy runner from builder
WORKDIR /actions-runner
COPY --from=builder /tmp/actions-runner.tar.gz .
RUN tar xzf actions-runner.tar.gz && rm actions-runner.tar.gz

# Install runner dependencies
RUN ./bin/installdependencies.sh

# Security hardening
RUN chown -R runner:runner /actions-runner \
    && chmod -R 755 /actions-runner

USER runner
```

## 🔧 Environment Configuration

### Development Environment

```bash
# Environment variables for development
export DOCKER_BUILDKIT=1
export COMPOSE_PROJECT_NAME=github-runner-dev

# Use development compose file with lower resource limits
docker compose -f docker/docker-compose.production.yml up -d
```

### Production Environment

```bash
# Environment variables for production
export DOCKER_BUILDKIT=1
export COMPOSE_PROJECT_NAME=github-runner-prod

# Deploy production runners
docker compose -f docker/docker-compose.production.yml up -d
```

## 📊 Volume Management

### Cache Strategy

```yaml
volumes:
  # Build cache
  build_cache:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/runner-cache/build

  # Dependencies cache
  deps_cache:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/runner-cache/deps

  # Workspace persistence
  workspace:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/runner-workspace
```

### Backup Configuration

```bash
# scripts/backup-volumes.sh
#!/bin/bash

BACKUP_DIR="/backup/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup volumes
docker run --rm \
  -v github-runner_runner_workspace:/source:ro \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/workspace.tar.gz -C /source .

docker run --rm \
  -v github-runner_runner_cache:/source:ro \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/cache.tar.gz -C /source .
```

## 🌐 Network Configuration

### Custom Network Setup

```yaml
networks:
  frontend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
  backend:
    driver: bridge
    internal: true
    ipam:
      config:
        - subnet: 172.21.0.0/24

services:
  runner:
    networks:
      - frontend
      - backend

  prometheus:
    networks:
      - backend
```

### Load Balancer Configuration

```yaml
# nginx load balancer
nginx:
  image: nginx:alpine
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    - ./nginx/ssl:/etc/ssl/certs:ro
  depends_on:
    - runner
```

## 🔍 Health Checks

### Runner Health Check

```bash
#!/bin/bash
# docker/healthcheck.sh

# Check if runner process is running
if ! pgrep -f "Runner.Listener" > /dev/null; then
    echo "Runner process not found"
    exit 1
fi

# Check if runner can connect to GitHub
if ! curl -s -f https://api.github.com/user > /dev/null 2>&1; then
    echo "Cannot connect to GitHub API"
    exit 1
fi

# Check disk space
DISK_USAGE=$(df /workspace | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo "Disk usage too high: ${DISK_USAGE}%"
    exit 1
fi

echo "Health check passed"
exit 0
```

### Docker Compose Health Check

```yaml
healthcheck:
  test: ["CMD", "/app/healthcheck.sh"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

## 🚀 Performance Optimization

### Build Cache Optimization

```dockerfile
# Use BuildKit cache mounts
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y \
    build-essential \
    python3-dev
```

### Resource Monitoring

```bash
# Monitor resource usage
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Container resource limits
docker inspect runner | jq '.[0].HostConfig.Memory'
docker inspect runner | jq '.[0].HostConfig.CpuQuota'
```

## 🔄 Next Steps

- **[Production Deployment](Production-Deployment)** - Production readiness
- **[Health Monitoring](Health-Monitoring)** - Monitoring setup
- **[Scaling and Load Balancing](Scaling-and-Load-Balancing)** - Scaling strategies
- **[Security Configuration](Security-Configuration)** - Security hardening
