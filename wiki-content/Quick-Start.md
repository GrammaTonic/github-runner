# Quick Start

Get your GitHub Actions self-hosted runner up and running in 5 minutes!

## ⚡ Prerequisites

- Docker and Docker Compose installed
- GitHub repository with admin access
- GitHub personal access token

## 🚀 5-Minute Setup

### Step 1: Clone the Repository (30 seconds)

```bash
git clone https://github.com/GrammaTonic/github-runner.git
cd github-runner
```

### Step 2: Configure Environment (2 minutes)

```bash
# Copy configuration template
cp config/runner.env.template config/runner.env

# Edit with your settings
nano config/runner.env
```

**Minimal required configuration:**

```bash
GITHUB_TOKEN=ghp_your_personal_access_token_here
GITHUB_REPOSITORY=your-username/your-repository
```

### Step 3: Deploy Runner (2 minutes)

```bash
# Start the runner
docker compose -f docker/docker-compose.yml up -d

# Check status
docker compose logs runner
```

### Step 4: Verify in GitHub (30 seconds)

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Actions** → **Runners**
3. Your runner should appear as "Online"

## ✅ Test Your Runner

Create a simple workflow to test your runner:

```yaml
# .github/workflows/test-runner.yml
name: Test Self-Hosted Runner

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: self-hosted
    steps:
      - name: Test runner
        run: |
          echo "🎉 Self-hosted runner is working!"
          docker --version
          git --version
```

## 🔧 Common Quick Fixes

### Runner not appearing?

```bash
# Check logs
docker compose logs runner

# Verify token permissions
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
```

### Permission denied errors?

```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Out of space?

```bash
# Clean up Docker
docker system prune -a -f
```

## 🎯 What's Next?

- **[Production Setup](Production-Deployment)** - Scale for production use
- **[Monitoring](Health-Monitoring)** - Add health checks and metrics
- **[Security](Security-Configuration)** - Secure your runners
- **[Troubleshooting](Common-Issues)** - Fix common problems

## 💡 Quick Tips

- **Use unique runner names** to avoid conflicts
- **Set resource limits** to prevent resource exhaustion
- **Enable monitoring** for production deployments
- **Regular cleanup** prevents disk space issues

## 📞 Need Help?

- **[Common Issues](Common-Issues)** - Quick fixes
- **[Installation Guide](Installation-Guide)** - Detailed setup
- **[GitHub Issues](https://github.com/GrammaTonic/github-runner/issues)** - Report problems

---

**⏱️ Total setup time: ~5 minutes**
**🎉 You're ready to run workflows on your self-hosted runner!**
