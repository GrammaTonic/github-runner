# Quick Start Guide

Deploy GitHub self-hosted runners in Docker containers in under 5 minutes.

## 🚀 One-Command Setup

```bash
git clone https://github.com/grammatonic/github-runner.git
cd github-runner
./scripts/quick-start.sh
```

**That's it!** The script will guide you through the setup interactively.

---

## 📋 Prerequisites

Before starting, ensure you have:

- **Docker installed and running** ([Get Docker](https://docs.docker.com/get-docker/))
- **GitHub Personal Access Token** ([Create Token](https://github.com/settings/tokens))
- **Repository where you want to add runners**

### GitHub Token Permissions

Your token needs these scopes:

- **`repo`** (for private repositories)
- **`public_repo`** (for public repositories only)

---

## 🎯 Quick Setup Methods

### Method 1: Interactive Script (Recommended)

```bash
./scripts/quick-start.sh
```

The script will:

1. ✅ Check prerequisites
2. ✅ Create configuration interactively
3. ✅ Pull latest Docker images
4. ✅ Deploy runners
5. ✅ Show status and next steps

### Method 2: Manual Configuration

1. **Copy environment template:**

   ```bash
   cp config/runner.env.example config/runner.env
   ```

2. **Edit configuration:**

   ```bash
   nano config/runner.env
   ```

   Set your values:

   ```bash
   GITHUB_TOKEN=ghp_your_actual_token_here
   GITHUB_REPOSITORY=your-username/your-repo-name
   ```

3. **Deploy runners:**
   ```bash
   cd docker
   docker compose -f docker-compose.production.yml --env-file ../config/runner.env up -d
   ```

---

## ⚙️ Configuration Options

### Basic Configuration

| Variable             | Required | Description           | Example              |
| -------------------- | -------- | --------------------- | -------------------- |
| `GITHUB_TOKEN`       | ✅       | Personal access token | `ghp_abc123...`      |
| `GITHUB_REPOSITORY`  | ✅       | Repository name       | `johndoe/my-project` |
| `RUNNER_NAME`        | ❌       | Main runner name      | `docker-runner`      |
| `RUNNER_NAME_CHROME` | ❌       | Chrome runner name    | `chrome-runner`      |

### Advanced Configuration

```bash
# Runner Labels (affects job assignment)
RUNNER_LABELS=docker,self-hosted,linux,production

# Ephemeral runners (auto-remove after jobs)
RUNNER_EPHEMERAL=true

# Runner group (for organizations)
RUNNER_GROUP=production-runners

# Resource limits
CHROME_MEMORY_LIMIT=2g
RUNNER_CPU_LIMIT=1.0
```

---

## 🔍 Verification

### 1. Check Container Status

```bash
cd docker
docker compose -f docker-compose.production.yml ps
```

Expected output:

```
NAME                    IMAGE                                  STATUS
github-runner-chrome    ghcr.io/...github-runner:chrome       Up 2 minutes (healthy)
github-runner-main      ghcr.io/...github-runner:latest       Up 2 minutes (healthy)
```

### 2. Check GitHub Registration

Visit your repository's runner settings:

```
https://github.com/YOUR-USERNAME/YOUR-REPO/settings/actions/runners
```

You should see your runners listed as "Idle" (ready for jobs).

### 3. View Logs

```bash
# All logs
docker compose -f docker-compose.production.yml logs

# Follow logs in real-time
docker compose -f docker-compose.production.yml logs -f

# Specific runner logs
docker compose -f docker-compose.production.yml logs github-runner-main
```

---

## 🛠️ Management Commands

### Start Runners

```bash
cd docker
docker compose -f docker-compose.production.yml up -d
```

### Stop Runners

```bash
docker compose -f docker-compose.production.yml down
```

### Restart Runners

```bash
docker compose -f docker-compose.production.yml restart
```

### Update Images

```bash
docker compose -f docker-compose.production.yml pull
docker compose -f docker-compose.production.yml up -d
```

### View Resource Usage

```bash
docker stats
```

---

## 🔧 Troubleshooting

### Runners Don't Appear in GitHub

**Symptoms:** Containers are running but runners don't show in GitHub

**Solutions:**

1. **Check token permissions:**

   ```bash
   # Test token access
   curl -H "Authorization: token $GITHUB_TOKEN" \
        https://api.github.com/repos/your-username/your-repo
   ```

2. **Verify repository name format:**

   ```bash
   # Correct format: username/repository-name
   GITHUB_REPOSITORY=johndoe/my-awesome-project
   ```

3. **Check container logs:**
   ```bash
   docker compose logs github-runner-main
   ```

### Containers Keep Restarting

**Symptoms:** `docker ps` shows containers constantly restarting

**Solutions:**

1. **Check Docker daemon:**

   ```bash
   docker info
   ```

2. **Verify permissions:**

   ```bash
   ls -la /var/run/docker.sock
   # Should be accessible to docker group
   ```

3. **Check system resources:**
   ```bash
   docker system df
   free -h
   ```

### Permission Denied Errors

**Symptoms:** "Permission denied" when starting containers

**Solutions:**

1. **Add user to docker group:**

   ```bash
   sudo usermod -aG docker $USER
   # Then logout and login again
   ```

2. **Check Docker socket permissions:**
   ```bash
   sudo chmod 666 /var/run/docker.sock
   ```

### Chrome Runner Issues

**Symptoms:** Chrome runner fails or UI tests don't work

**Solutions:**

1. **Increase memory limit:**

   ```bash
   # In config/runner.env
   CHROME_MEMORY_LIMIT=4g
   ```

2. **Check Chrome flags:**

   ```bash
   CHROME_FLAGS=--headless --no-sandbox --disable-dev-shm-usage
   ```

3. **Verify shared memory:**
   ```bash
   docker exec github-runner-chrome df -h /dev/shm
   ```

---

## 💡 Use Cases & Examples

### Personal Project

```bash
GITHUB_TOKEN=ghp_abc123...
GITHUB_REPOSITORY=johndoe/my-blog
RUNNER_NAME=personal-runner
RUNNER_LABELS=docker,self-hosted,personal
```

### Team Development

```bash
GITHUB_REPOSITORY=myteam/backend-api
RUNNER_NAME=team-backend-runner
RUNNER_LABELS=docker,backend,self-hosted,development
RUNNER_GROUP=development-team
```

### Production Deployment

```bash
GITHUB_REPOSITORY=company/production-app
RUNNER_NAME=prod-runner
RUNNER_LABELS=docker,production,self-hosted,secure
RUNNER_EPHEMERAL=true
RUNNER_GROUP=production-runners
```

### UI Testing Setup

```bash
RUNNER_NAME_CHROME=ui-test-runner
RUNNER_LABELS_CHROME=chrome,ui-tests,selenium,playwright
CHROME_FLAGS=--headless --window-size=1920,1080 --no-sandbox
```

---

## 🔒 Security Best Practices

### 1. Token Management

- Use tokens with minimal required permissions
- Rotate tokens regularly
- Never commit tokens to version control
- Consider using GitHub App authentication for organizations

### 2. Runner Security

- Use ephemeral runners for sensitive workflows: `RUNNER_EPHEMERAL=true`
- Regularly update Docker images
- Monitor runner usage and logs
- Implement network restrictions if needed

### 3. Container Security

- Run containers as non-root users (already configured)
- Keep Docker daemon updated
- Use resource limits to prevent abuse
- Monitor container activity

---

## 📚 Next Steps

After successful deployment:

1. **Test your setup:** Create a simple workflow in your repository
2. **Customize labels:** Adjust `RUNNER_LABELS` to match your needs
3. **Scale up:** Add more runners by modifying the Docker Compose configuration
4. **Monitor:** Set up logging and monitoring for production use
5. **Automate:** Consider using the provided scripts in your CI/CD pipeline

---

## 🆘 Getting Help

- **Documentation:** [Full documentation](../README.md)
- **Issues:** [GitHub Issues](https://github.com/grammatonic/github-runner/issues)
- **Discussions:** [GitHub Discussions](https://github.com/grammatonic/github-runner/discussions)

---

**🎉 You're ready to use GitHub self-hosted runners!**

The runners will automatically pick up jobs from your repository's workflows. Check your repository's Actions tab to see them in action.
