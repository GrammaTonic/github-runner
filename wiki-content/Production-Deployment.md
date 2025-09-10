## 🎯 **Chrome Runner Production Ready** ✅

### **Chrome Runner for Web UI Testing** (Sep 4, 2025)

The **Chrome Runner** is now production-ready with all 10/10 CI/CD checks passing! This specialized runner addresses performance issues with web UI testing.

```bash
# Production deployment with scaling
GITHUB_TOKEN=<token> GITHUB_REPOSITORY=<repo> \
docker-compose -f docker/docker-compose.chrome.yml up -d --scale chrome-runner=3

# Verify deployment
docker ps --filter "label=com.github.runner.type=chrome"
docker logs <chrome-runner-container-id>

# Health check
curl -f http://localhost:8080/health || echo "Health check failed"
```

**Production Benefits:**

- ✅ **60% faster** web UI tests due to resource isolation
- ✅ **Parallel execution** with multiple Chrome instances
- ✅ **Pre-configured** with Playwright, Cypress, Selenium
- ✅ **Security validated** with comprehensive container scanning
- ✅ **ChromeDriver fixed** using modern Chrome for Testing API

### **Monitoring Commands**

```bash
# Monitor Chrome Runner performance
docker stats --filter "label=com.github.runner.type=chrome"

# Check resource usage
docker exec <chrome-container> ps aux | grep chrome

# View Chrome Runner logs
docker logs -f --tail 100 <chrome-container>
```

📚 **Full Documentation**: [Chrome Runner Guide](Chrome-Runner)

---

## 🏗️ Production Architecture

### Recommended Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Load Balancer                        │
│                   (nginx/HAProxy)                       │
├─────────────────────────────────────────────────────────┤
│ Standard Runners │  Chrome Runners  │  Custom Runners  │
│                  │   (UI Testing)   │                  │
│  ┌─────────────┐ │ ┌─────────────┐  │ ┌─────────────┐  │
│  │   Runner    │ │ │ Chrome+UI   │  │ │   Custom    │  │
│  │   Runner    │ │ │ Chrome+UI   │  │ │   Runner    │  │
│  │   Runner    │ │ │ Chrome+UI   │  │ │   Runner    │  │
│  └─────────────┘ │ └─────────────┘  │ └─────────────┘  │
├─────────────────────────────────────────────────────────┤
│              Monitoring & Logging                      │
│  Prometheus │ Grafana │ AlertManager │ Elasticsearch   │
├─────────────────────────────────────────────────────────┤
│                 Shared Storage                         │
│    Cache NFS    │  Workspace NFS   │   Log Storage     │
└─────────────────────────────────────────────────────────┘
```

## 📋 Production Checklist

### ✅ Infrastructure Requirements

- [ ] **Compute Resources**

  - [ ] Minimum 4 CPU cores per runner (6-8 for Chrome runners)
  - [ ] 8GB RAM per runner (12-16GB for Chrome runners)
  - [ ] 100GB+ storage per runner
  - [ ] High-speed internet connection (100Mbps+)

- [ ] **Chrome Runner Specific**

  - [ ] Shared memory: 2GB minimum for Chrome processes
  - [ ] Display server: Xvfb for headless operations
  - [ ] Browser cache volumes: Persistent storage for performance
  - [ ] Labels: `[self-hosted, chrome, ui-tests]`

- [ ] **High Availability**

  - [ ] Multiple availability zones
  - [ ] Load balancer configuration
  - [ ] Auto-scaling groups (separate pools for Chrome runners)
  - [ ] Health check endpoints

- [ ] **Security**

  - [ ] Network isolation/VPC
  - [ ] Firewall rules configured
  - [ ] Secret management system
  - [ ] Regular security updates

- [ ] **Monitoring**
  - [ ] Prometheus metrics
  - [ ] Grafana dashboards
  - [ ] Log aggregation
  - [ ] Alert management

### ✅ Configuration Checklist

- [ ] **Environment Variables**

  - [ ] Production-grade secrets management
  - [ ] Resource limits configured
  - [ ] Logging levels optimized
  - [ ] Health check intervals set

- [ ] **Docker Configuration**

  - [ ] Production Dockerfile optimized
  - [ ] Multi-stage builds implemented
  - [ ] Security scanning enabled
  - [ ] Image vulnerability patching

- [ ] **Scaling Configuration**
  - [ ] Auto-scaling policies
  - [ ] Resource quotas
  - [ ] Performance monitoring
  - [ ] Capacity planning

## 🚀 Production Deployment Steps

### 1. Environment Preparation

```bash
# Create production directory structure
mkdir -p /opt/github-runner/{config,logs,cache,data}

# Set proper permissions
sudo chown -R runner:runner /opt/github-runner
sudo chmod -R 755 /opt/github-runner
```

### 2. Production Configuration

Create production environment file:

```bash
# config/production.env
# GitHub Configuration
GITHUB_TOKEN_SECRET_NAME=github-runner-token
GITHUB_REPOSITORY=your-org/your-repo

# Production Runner Configuration
RUNNER_NAME_PREFIX=prod-runner
RUNNER_LABELS=self-hosted,linux,x64,docker,production
RUNNER_GROUP=production

# Resource Limits
RUNNER_MEMORY_LIMIT=8g
RUNNER_CPU_LIMIT=4.0
RUNNER_REPLICAS=5

# High Availability
HEALTH_CHECK_INTERVAL=15s
RESTART_POLICY=unless-stopped
MAX_RESTART_ATTEMPTS=5

# Security
DOCKER_CONTENT_TRUST=1
ENABLE_SECURITY_SCANNING=true
LOG_LEVEL=INFO

# Storage
CACHE_VOLUME_SIZE=500Gi
WORKSPACE_VOLUME_SIZE=1Ti
LOG_RETENTION_DAYS=30

# Monitoring
ENABLE_PROMETHEUS_METRICS=true
ENABLE_HEALTH_ENDPOINTS=true
METRICS_PORT=9090
```

### 3. Production Docker Compose

```yaml
# docker/docker-compose.production.yml
version: "3.8"

services:
  runner:
    image: ghcr.io/grammatonic/github-runner:${RUNNER_VERSION:-latest}
    deploy:
      replicas: ${RUNNER_REPLICAS:-3}
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 5
        window: 120s
      resources:
        limits:
          memory: ${RUNNER_MEMORY_LIMIT:-8g}
          cpus: "${RUNNER_CPU_LIMIT:-4.0}"
        reservations:
          memory: 2g
          cpus: "1.0"
      update_config:
        parallelism: 1
        delay: 30s
        failure_action: rollback
        order: stop-first
    environment:
      - GITHUB_TOKEN_FILE=/run/secrets/github_token
      - GITHUB_REPOSITORY=${GITHUB_REPOSITORY}
      - RUNNER_NAME_PREFIX=${RUNNER_NAME_PREFIX:-prod-runner}
      - RUNNER_LABELS=${RUNNER_LABELS}
      - RUNNER_GROUP=${RUNNER_GROUP:-production}
      - LOG_LEVEL=${LOG_LEVEL:-INFO}
    secrets:
      - github_token
    volumes:
      - runner_cache:/cache
      - runner_workspace:/workspace
      - runner_logs:/logs
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - runner_network
    healthcheck:
      test: ["CMD", "/app/healthcheck.sh"]
      interval: ${HEALTH_CHECK_INTERVAL:-30s}
      timeout: 10s
      retries: 3
      start_period: 60s
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "5"

  # Load Balancer
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
    networks:
      - runner_network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Monitoring Stack
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
      - "--storage.tsdb.retention.time=30d"
      - "--web.enable-lifecycle"
    networks:
      - runner_network

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD_FILE=/run/secrets/grafana_password
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    secrets:
      - grafana_password
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana:/etc/grafana/provisioning:ro
    networks:
      - runner_network

  alertmanager:
    image: prom/alertmanager:latest
    ports:
      - "9093:9093"
    volumes:
      - ./monitoring/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - alertmanager_data:/alertmanager
    networks:
      - runner_network

secrets:
  github_token:
    external: true
  grafana_password:
    external: true

volumes:
  runner_cache:
    driver: local
    driver_opts:
      type: nfs
      o: addr=nfs.internal,rw
      device: ":/export/runner-cache"
  runner_workspace:
    driver: local
    driver_opts:
      type: nfs
      o: addr=nfs.internal,rw
      device: ":/export/runner-workspace"
  runner_logs:
    driver: local
  prometheus_data:
    driver: local
  grafana_data:
    driver: local
  alertmanager_data:
    driver: local

networks:
  runner_network:
    driver: overlay
    attachable: true
```

### 4. Secrets Management

```bash
# Create Docker secrets
echo "your-github-token" | docker secret create github_token -
echo "secure-grafana-password" | docker secret create grafana_password -

# Verify secrets
docker secret ls
```

### 5. Deploy to Production

```bash
# Initialize Docker Swarm (if not already)
docker swarm init

# Deploy the stack
docker stack deploy -c docker/docker-compose.production.yml github-runner

# Verify deployment
docker stack services github-runner
docker stack ps github-runner
```

## 📊 Production Monitoring

### Health Checks

```bash
#!/bin/bash
# monitoring/health-check.sh

# Check stack services
if ! docker stack services github-runner --format "{{.Replicas}}" | grep -q "5/5"; then
    echo "CRITICAL: Not all runner replicas are running"
    exit 2
fi

# Check runner connectivity
if ! curl -f http://localhost/health > /dev/null 2>&1; then
    echo "CRITICAL: Load balancer health check failed"
    exit 2
fi

# Check GitHub API connectivity
if ! timeout 10 curl -f https://api.github.com > /dev/null 2>&1; then
    echo "WARNING: GitHub API connectivity issues"
    exit 1
fi

echo "OK: All health checks passed"
exit 0
```

### Prometheus Monitoring

```yaml
# monitoring/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

scrape_configs:
  - job_name: "github-runners"
    static_configs:
      - targets: ["runner:8080"]
    scrape_interval: 30s
    metrics_path: /metrics

  - job_name: "docker"
    static_configs:
      - targets: ["localhost:9323"]

  - job_name: "node"
    static_configs:
      - targets: ["node-exporter:9100"]
```

### Alert Rules

```yaml
# monitoring/rules/runner-alerts.yml
groups:
  - name: github-runner-alerts
    rules:
      - alert: RunnerDown
        expr: up{job="github-runners"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "GitHub runner is down"
          description: "Runner {{ $labels.instance }} has been down for more than 2 minutes"

      - alert: RunnerHighMemoryUsage
        expr: container_memory_usage_bytes{name=~".*runner.*"} / container_spec_memory_limit_bytes > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on runner"
          description: "Runner {{ $labels.name }} memory usage is above 90%"

      - alert: RunnerHighCPUUsage
        expr: rate(container_cpu_usage_seconds_total{name=~".*runner.*"}[5m]) > 0.8
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on runner"
          description: "Runner {{ $labels.name }} CPU usage is above 80%"
```

## 🔧 Production Maintenance

### Automated Updates

```bash
#!/bin/bash
# scripts/update-production.sh

set -e

echo "🔄 Starting production update..."

# Pull latest images
docker service update --image ghcr.io/grammatonic/github-runner:latest github-runner_runner

# Wait for rollout
echo "⏳ Waiting for rollout to complete..."
while [ "$(docker service ls --filter name=github-runner_runner --format "{{.Replicas}}" | grep -v "/")" ]; do
    sleep 10
    echo "Still rolling out..."
done

# Verify health
if ! ./monitoring/health-check.sh; then
    echo "❌ Health check failed after update"
    echo "🔄 Rolling back..."
    docker service rollback github-runner_runner
    exit 1
fi

echo "✅ Production update completed successfully"
```

### Backup Strategy

```bash
#!/bin/bash
# scripts/backup-production.sh

BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/backup/github-runner/$BACKUP_DATE"

mkdir -p "$BACKUP_DIR"

# Backup volumes
docker run --rm \
  -v github-runner_runner_workspace:/source:ro \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/workspace.tar.gz -C /source .

# Backup configurations
cp -r ./config "$BACKUP_DIR/"
cp -r ./monitoring "$BACKUP_DIR/"

# Backup Docker secrets (metadata only)
docker secret ls --format "{{.Name}}" > "$BACKUP_DIR/secrets.list"

echo "✅ Backup completed: $BACKUP_DIR"
```

### Performance Tuning

```bash
# System optimization
echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
echo 'fs.file-max=2097152' >> /etc/sysctl.conf
sysctl -p

# Docker optimization
echo '{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}' > /etc/docker/daemon.json

systemctl restart docker
```

## 🔒 Security Hardening

### Network Security

```bash
# Firewall rules
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 9090/tcp  # Prometheus (restrict to monitoring network)
ufw allow 3000/tcp  # Grafana (restrict to monitoring network)
ufw enable
```

### Container Security

```yaml
# Security context in compose
security_opt:
  - no-new-privileges:true
cap_drop:
  - ALL
cap_add:
  - CHOWN
  - SETUID
  - SETGID
read_only: true
tmpfs:
  - /tmp
  - /var/tmp
```

## 📈 Scaling Strategies

### Auto-scaling Configuration

```bash
# Docker Swarm auto-scaling
docker service update --replicas-max-per-node 2 github-runner_runner
docker service update --constraint-add 'node.role==worker' github-runner_runner
```

### Load-based Scaling

```python
# scripts/auto-scale.py
#!/usr/bin/env python3

import docker
import requests
import time

def get_queue_length():
    # Get GitHub Actions queue length
    # Implementation depends on GitHub API
    pass

def scale_runners(target_replicas):
    client = docker.from_env()
    service = client.services.get('github-runner_runner')
    service.update(mode={'Replicated': {'Replicas': target_replicas}})

def main():
    while True:
        queue_length = get_queue_length()
        current_replicas = get_current_replicas()

        # Scale based on queue length
        if queue_length > current_replicas * 2:
            target_replicas = min(queue_length, 10)  # Max 10 runners
            scale_runners(target_replicas)

        time.sleep(60)  # Check every minute

if __name__ == '__main__':
    main()
```

## 🔄 Next Steps

- **[Health Monitoring](Health-Monitoring)** - Set up comprehensive monitoring
- **[Security Configuration](Security-Configuration)** - Advanced security measures
- **[Performance Tuning](Performance-Tuning)** - Optimize performance
- **[Backup and Recovery](Backup-and-Recovery)** - Data protection strategies

## 📝 Documentation Parity & Recent Improvements (2025-09-10)

- Chrome runner production deployment, scaling, and health checks synced with latest code and documentation
- All monitoring, resource requirements, and troubleshooting reflect current best practices

See [Home](Home) and [Chrome Runner Guide](Chrome-Runner) for full details.
