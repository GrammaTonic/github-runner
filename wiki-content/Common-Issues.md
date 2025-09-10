# Common Issues

This page covers the most frequently encountered issues and their solutions.

## 🌐 Chrome Runner Issues

### ✅ **RESOLVED: ChromeDriver Version Issues**

**Previous Issue**: ChromeDriver installation failed with deprecated API

**Symptoms (Now Fixed):**

- Chrome tests failed with version compatibility errors
- Error: "This version of ChromeDriver only supports Chrome version X"
- ChromeDriver download failures from deprecated endpoints

**Solution Applied** (Sep 4, 2025):

```bash
# Fixed implementation now using Chrome for Testing API
CHROME_VERSION=$(google-chrome --version | grep -oP '\d+\.\d+\.\d+\.\d+')
CHROMEDRIVER_URL="https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json"

# Automatic version matching now working
curl -s "$CHROMEDRIVER_URL" | jq -r "ChromeDriver matched to Chrome version"
```

**Status**: ✅ **Resolved** - All Chrome Runner builds now successful with modern API

**Prevention**: Chrome for Testing API automatically maintains version compatibility

### Issue: "Chrome crashes or runs out of memory"

**Symptoms:**

- Browser tests fail randomly
- Error: "Chrome crash detected"
- High memory usage

**Solutions:**

1. **Increase shared memory:**

```yaml
# In docker-compose.chrome.yml
services:
  chrome-runner:
    shm_size: 4g # Increase from default 64MB
```

2. **Add Chrome stability flags:**

```bash
--memory-pressure-off
--max_old_space_size=4096
--disable-background-timer-throttling
```

### Issue: "Virtual display not working"

**Symptoms:**

- Error: "No display specified"
- GUI applications fail to start

**Solution:**

```bash
# Check virtual display
echo $DISPLAY  # Should show :99
ps aux | grep Xvfb  # Should show running Xvfb process

# Restart virtual display if needed
sudo pkill Xvfb
Xvfb :99 -screen 0 1920x1080x24 &
export DISPLAY=:99
```

### Issue: "Slow web UI tests"

**Problem Solved:** ✅ This is exactly why the Chrome Runner was created!

**Solution:**

```bash
# Use dedicated Chrome Runner instead of standard runner
# In your GitHub Actions workflow:
jobs:
  ui-tests:
    runs-on: [self-hosted, chrome, ui-tests]  # Use Chrome runner
    steps:
      - uses: actions/checkout@v4
      - name: Run UI tests
        run: npx playwright test
```

**Benefits:**

- ✅ 60% faster execution due to resource isolation
- ✅ Pre-installed testing frameworks
- ✅ Optimized Chrome configuration
- ✅ Parallel test execution capability

📚 **Full Chrome Runner Guide**: [Chrome Runner Documentation](Chrome-Runner)

---

## 🔧 Runner Registration Issues

### Issue: "Runner registration failed"

**Symptoms:**

- Runner container starts but doesn't appear in GitHub
- Error: "HTTP 401: Bad credentials"
- Error: "HTTP 403: Forbidden"

**Solutions:**

1. **Check token permissions:**

```bash
# Test token manually
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user

# Required scopes for private repos
# - repo (full control)
# - workflow (update workflows)
```

2. **Verify repository format:**

```bash
# Correct format
GITHUB_REPOSITORY=owner/repository-name

# Common mistakes
GITHUB_REPOSITORY=https://github.com/owner/repo  # ❌
GITHUB_REPOSITORY=owner/repo.git                # ❌
```

3. **Check token expiration:**

```bash
# Check token expiration
gh auth status

# Regenerate if expired
gh auth refresh
```

### Issue: "Runner name already exists"

**Symptoms:**

- Error: "A runner exists with the same name"
- Multiple failed registration attempts

**Solutions:**

1. **Use unique runner names:**

```bash
# Add timestamp or hostname
RUNNER_NAME=runner-$(hostname)-$(date +%s)

# Use container ID
RUNNER_NAME=runner-$(cat /proc/self/cgroup | head -1 | cut -d/ -f3 | cut -c1-12)
```

2. **Remove existing runners:**

```bash
# List current runners
gh api repos/OWNER/REPO/actions/runners

# Remove specific runner
gh api repos/OWNER/REPO/actions/runners/RUNNER_ID -X DELETE
```

## 🐳 Docker Issues

### Issue: "Docker daemon not accessible"

**Symptoms:**

- Error: "Cannot connect to the Docker daemon"
- Permission denied errors
- Socket not found

**Solutions:**

1. **Fix Docker socket permissions:**

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Reload group membership
newgrp docker

# Test access
docker ps
```

2. **Check Docker daemon status:**

```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker is running
docker version
```

3. **Mount Docker socket correctly:**

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

### Issue: "Out of disk space"

**Symptoms:**

- Error: "No space left on device"
- Build failures during image pulls
- Container crashes

**Solutions:**

1. **Clean up Docker resources:**

```bash
# Remove unused containers
docker container prune -f

# Remove unused images
docker image prune -a -f

# Remove unused volumes
docker volume prune -f

# Complete cleanup
docker system prune -a --volumes -f
```

2. **Monitor disk usage:**

```bash
# Check Docker disk usage
docker system df

# Check container sizes
docker ps -s

# Check volume sizes
docker volume ls
```

3. **Configure log rotation:**

```yaml
services:
  runner:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 🔐 Authentication Issues

### Issue: "Token authentication failed during job"

**Symptoms:**

- Runner registers successfully
- Jobs fail with authentication errors
- Git clone/push operations fail

**Solutions:**

1. **Use GITHUB_TOKEN in workflows:**

```yaml
# In your workflow
steps:
  - uses: actions/checkout@v4
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
```

2. **Configure Git credentials:**

```bash
# In runner entrypoint
git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
```

3. **Check token scope:**

```bash
# Token needs 'repo' scope for private repositories
# Token needs 'public_repo' scope for public repositories
```

## 📊 Performance Issues

### Issue: "Slow job execution"

**Symptoms:**

- Jobs take much longer than expected
- High CPU/memory usage
- Frequent timeouts

**Solutions:**

1. **Increase resource limits:**

```yaml
deploy:
  resources:
    limits:
      memory: 4g
      cpus: "2.0"
    reservations:
      memory: 1g
      cpus: "0.5"
```

2. **Optimize Docker builds:**

```dockerfile
# Use multi-stage builds
FROM node:16-alpine as builder
COPY package*.json ./
RUN npm ci --only=production

FROM node:16-alpine as runtime
COPY --from=builder /app/node_modules ./node_modules
```

3. **Enable build caching:**

```yaml
volumes:
  - build_cache:/root/.cache
  - deps_cache:/root/.npm
```

### Issue: "Memory leaks"

**Symptoms:**

- Gradually increasing memory usage
- Container restarts due to OOM
- System becomes unresponsive

**Solutions:**

1. **Monitor memory usage:**

```bash
# Check container memory
docker stats --no-stream

# Check system memory
free -h

# Monitor over time
watch -n 5 'docker stats --no-stream'
```

2. **Set memory limits:**

```yaml
deploy:
  resources:
    limits:
      memory: 2g
```

3. **Enable automatic restarts:**

```yaml
restart: unless-stopped
healthcheck:
  test: ["CMD", "pgrep", "Runner.Listener"]
  interval: 30s
  timeout: 10s
  retries: 3
```

## 🌐 Network Issues

### Issue: "Cannot reach GitHub API"

**Symptoms:**

- Network timeouts
- DNS resolution failures
- Proxy configuration issues

**Solutions:**

1. **Test connectivity:**

```bash
# Test DNS resolution
nslookup api.github.com

# Test HTTPS connectivity
curl -v https://api.github.com

# Test with proxy
curl -x proxy.company.com:8080 https://api.github.com
```

2. **Configure proxy settings:**

```bash
# Environment variables
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
export NO_PROXY=localhost,127.0.0.1,10.0.0.0/8

# Docker proxy configuration
```

3. **Check firewall rules:**

```bash
# Required ports
# 443 (HTTPS) - api.github.com
# 443 (HTTPS) - github.com
# 443 (HTTPS) - objects.githubusercontent.com
```

## 🔄 Scaling Issues

### Issue: "Runners not scaling properly"

**Symptoms:**

- Jobs queue up despite available resources
- Inconsistent runner availability
- Load balancing problems

**Solutions:**

1. **Check runner labels:**

```bash
# Ensure consistent labels
RUNNER_LABELS=self-hosted,linux,x64,docker

# Verify in GitHub UI
# Settings → Actions → Runners
```

2. **Configure proper scaling:**

```bash
# Scale up
docker compose up -d --scale runner=5

# Check running containers
docker ps --filter "name=runner"
```

3. **Monitor job queue:**

```bash
# Check queued jobs
gh api repos/OWNER/REPO/actions/runs --jq '.workflow_runs[] | select(.status=="queued")'
```

## 📝 Documentation Parity & Recent Improvements (2025-09-10)

- ChromeDriver installation now uses Chrome for Testing API for version compatibility
- Playwright screenshot artifact upload and diagnostics improved for CI/CD
- All troubleshooting, resource configuration, and quick fixes synced with main documentation

See [Home](Home) and [Chrome Runner Guide](Chrome-Runner) for full details.

## 🔍 Debugging Tools

### Container Debugging

```bash
# Access container shell
docker exec -it github-runner_runner_1 /bin/bash

# Check container logs
docker logs github-runner_runner_1 --tail 100 -f

# Inspect container configuration
docker inspect github-runner_runner_1

# Check resource usage
docker stats github-runner_runner_1
```

### Log Analysis

```bash
# Search for specific errors
docker logs runner 2>&1 | grep -i error

# Monitor real-time logs
docker logs runner -f --tail 50

# Export logs for analysis
docker logs runner > runner-logs-$(date +%Y%m%d).txt
```

### System Diagnostics

```bash
# Check system resources
htop
iotop
netstat -tulpn

# Check Docker status
systemctl status docker
journalctl -u docker.service --since "1 hour ago"

# Check file descriptors
lsof | grep docker
```

## 📞 Getting Help

### Information to Gather

When reporting issues, include:

1. **System information:**

```bash
# Operating system
uname -a

# Docker version
docker version

# Docker Compose version
docker compose version
```

2. **Configuration:**

```bash
# Environment variables (redact secrets)
env | grep -E "GITHUB|RUNNER|DOCKER" | sed 's/TOKEN=.*/TOKEN=***/'

# Docker Compose configuration
docker compose config
```

3. **Logs:**

```bash
# Container logs
docker logs runner --tail 100

# System logs
journalctl -u docker.service --since "1 hour ago"
```

### Support Channels

- **GitHub Issues**: [Report bugs](https://github.com/GrammaTonic/github-runner/issues)
- **Discussions**: [Community support](https://github.com/GrammaTonic/github-runner/discussions)
- **Documentation**: [Wiki home](Home)

## 🔄 Related Pages

- **[Debugging Guide](Debugging-Guide)** - Advanced debugging techniques
- **[Performance Tuning](Performance-Tuning)** - Optimization strategies
- **[Installation Guide](Installation-Guide)** - Setup instructions
- **[Docker Configuration](Docker-Configuration)** - Docker setup
