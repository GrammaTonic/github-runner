# Security and CVE Mitigation

 The runner images use `ubuntu:questing` (25.10 pre-release) for the latest browser and system dependencies.
 All dependencies are scanned with Trivy after build and container startup; results are saved to `test-results/docker/` for audit and compliance.
 CVEs in npm's internal modules are documented and monitored; all app-level dependencies are patched using npm overrides and local installs.
 For production, switch to a stable Ubuntu LTS base and rerun all security scans as documented in README and release notes.

# Audit and Compliance

- All Trivy scan results are saved to `test-results/docker/` for review.
- Document any known CVEs and their risk profile in `/docs/security/`.
- **Warning:** Chrome runner image only supports `linux/amd64`. Do not deploy on ARM hosts.

# Deployment Guide

## Production Deployment Checklist

### Pre-deployment

- [ ] GitHub PAT created with appropriate permissions
- [ ] Repository settings configured for self-hosted runners
- [ ] Server resources allocated (CPU, Memory, Storage)
- [ ] Network security configured (firewall rules, VPN access)
- [ ] Monitoring infrastructure prepared
- [ ] Backup strategy defined

### Security Configuration

- [ ] Token stored securely (environment variables, secrets management)
- [ ] Container runs as non-root user
- [ ] Network isolation configured
- [ ] Resource limits applied
- [ ] Vulnerability scanning enabled
- [ ] Log aggregation configured

### Deployment Steps

1. **Server Preparation**

   ```bash
   # Update system
   sudo apt update && sudo apt upgrade -y

   # Install Docker
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker $USER

   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

2. **Application Deployment**

   ```bash
   # Clone repository
   git clone <repository-url> /opt/github-runner
   cd /opt/github-runner

   # Configure environment
  cp config/runner.env.example config/runner.env
   # Edit config/runner.env with production values

   # Start runners
  ./scripts/quick-start.sh
   ```

3. **Monitoring Setup**

   ```bash
   # Start monitoring stack
   docker compose -f docker/docker-compose.yml --profile monitoring up -d

   # Verify dashboards
   curl -f http://localhost:3000/api/health
   ```

### Post-deployment

- [ ] Verify runner registration in GitHub
- [ ] Test job execution
- [ ] Configure alerts
- [ ] Document access procedures
- [ ] Schedule maintenance windows

## Cloud Deployment

### AWS EC2

#### Launch Configuration

```bash
# User Data Script
#!/bin/bash
yum update -y
amazon-linux-extras install docker
service docker start
usermod -a -G docker ec2-user

# Install GitHub runner
cd /opt
git clone <repository-url> github-runner
cd github-runner
chmod +x scripts/*.sh

# Configure and start
echo "GITHUB_TOKEN=${GITHUB_TOKEN}" > config/runner.env
echo "GITHUB_REPOSITORY=${GITHUB_REPOSITORY}" >> config/runner.env
./scripts/deploy.sh start -s 2
```

#### Auto Scaling Group

```yaml
# cloudformation.yml
Resources:
  LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateName: github-runner-template
      LaunchTemplateData:
        InstanceType: t3.medium
        ImageId: ami-0abcdef1234567890
        UserData:
          Fn::Base64: !Sub |
            #!/bin/bash
            # Runner setup script here
```

### Google Cloud Platform

#### Compute Engine

```bash
# Create instance template
gcloud compute instance-templates create github-runner-template \
  --machine-type=e2-medium \
  --image-family=ubuntu-2004-lts \
  --image-project=ubuntu-os-cloud \
  --metadata-from-file startup-script=startup.sh

# Create managed instance group
gcloud compute instance-groups managed create github-runner-group \
  --template=github-runner-template \
  --size=3 \
  --zone=us-central1-a
```

#### Cloud Run

```yaml
# cloudbuild.yml
steps:
  - name: "gcr.io/cloud-builders/docker"
    args: ["build", "-t", "gcr.io/$PROJECT_ID/github-runner", "."]
  - name: "gcr.io/cloud-builders/docker"
    args: ["push", "gcr.io/$PROJECT_ID/github-runner"]
  - name: "gcr.io/cloud-builders/gcloud"
    args:
      - "run"
      - "deploy"
      - "github-runner"
      - "--image=gcr.io/$PROJECT_ID/github-runner"
      - "--platform=managed"
      - "--region=us-central1"
```

### Azure Container Instances

```bash
# Deploy container group
az container create \
  --resource-group myResourceGroup \
  --name github-runner \
  --image myregistry.azurecr.io/github-runner:latest \
  --environment-variables \
    GITHUB_TOKEN=$GITHUB_TOKEN \
    GITHUB_REPOSITORY=$GITHUB_REPOSITORY \
  --restart-policy Always \
  --cpu 2 \
  --memory 4
```

## Kubernetes Deployment

### Namespace Setup

```yaml
# namespace.yml
apiVersion: v1
kind: Namespace
metadata:
  name: github-runner
```

### Secret Management

```yaml
# secrets.yml
apiVersion: v1
kind: Secret
metadata:
  name: github-secrets
  namespace: github-runner
type: Opaque
data:
  token: <base64-encoded-token>
  repository: <base64-encoded-repo>
```

### Deployment

```yaml
# deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: github-runner
  namespace: github-runner
spec:
  replicas: 3
  selector:
    matchLabels:
      app: github-runner
  template:
    metadata:
      labels:
        app: github-runner
    spec:
      containers:
        - name: runner
          image: github-runner:latest
          env:
            - name: GITHUB_TOKEN
              valueFrom:
                secretKeyRef:
                  name: github-secrets
                  key: token
            - name: GITHUB_REPOSITORY
              valueFrom:
                secretKeyRef:
                  name: github-secrets
                  key: repository
          resources:
            requests:
              memory: "2Gi"
              cpu: "1"
            limits:
              memory: "4Gi"
              cpu: "2"
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
```

### Horizontal Pod Autoscaler

```yaml
# hpa.yml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
              # Warning: Chrome runner image only supports `linux/amd64`. ARM builds are blocked at build time.
  name: github-runner-hpa
  namespace: github-runner
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: github-runner
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

## Load Balancing

### nginx Configuration

```nginx
# nginx.conf
upstream github_runners {
    server runner1:8080;
    server runner2:8080;
    server runner3:8080;
}

server {
    listen 80;
    location /health {
        proxy_pass http://github_runners;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### HAProxy Configuration

```
# haproxy.cfg
global
    daemon

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend github_runner_frontend
    bind *:80
    default_backend github_runner_backend

backend github_runner_backend
    balance roundrobin
    option httpchk GET /health
    server runner1 runner1:8080 check
    server runner2 runner2:8080 check
    server runner3 runner3:8080 check
```

## Monitoring and Alerting

### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

scrape_configs:
  - job_name: "github-runner"
    static_configs:
      - targets: ["runner1:8080", "runner2:8080", "runner3:8080"]
    scrape_interval: 30s
    metrics_path: /metrics
```

### Alert Rules

```yaml
# alerts.yml
groups:
  - name: github-runner
    rules:
      - alert: RunnerDown
        expr: up{job="github-runner"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "GitHub runner {{ $labels.instance }} is down"
          description: "Runner has been down for more than 5 minutes"

      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) * 100 > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for more than 10 minutes"
```

## Disaster Recovery

### Backup Strategy

```bash
#!/bin/bash
# backup.sh

# Backup configuration
tar -czf "backup-$(date +%Y%m%d).tar.gz" \
  config/ \
  docker/docker-compose.yml \
  monitoring/

# Upload to cloud storage
aws s3 cp "backup-$(date +%Y%m%d).tar.gz" s3://backup-bucket/github-runner/
```

### Recovery Procedure

```bash
#!/bin/bash
# recovery.sh

# Download latest backup
aws s3 cp s3://backup-bucket/github-runner/backup-latest.tar.gz .

# Extract and restore
tar -xzf backup-latest.tar.gz

# Restart services
./scripts/deploy.sh restart -f
```

## Maintenance

### Update Procedure

```bash
# 1. Backup current state
./scripts/deploy.sh stop
tar -czf "backup-$(date +%Y%m%d).tar.gz" config/

# 2. Update code
git pull origin main

# 3. Update and restart
./scripts/deploy.sh update -f

# 4. Verify
./scripts/deploy.sh health
```

### Log Rotation

```bash
# logrotate configuration
/var/log/github-runner/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 runner runner
    postrotate
        docker compose -f /opt/github-runner/docker/docker-compose.yml restart
    endscript
}
```
