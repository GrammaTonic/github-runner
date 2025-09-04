# Chrome Runner Documentation

## Overview

The Chrome Runner is a specialized GitHub Actions self-hosted runner optimized for web UI testing and browser automation. It comes pre-installed with Chrome, ChromeDriver, and popular testing frameworks like Playwright, Cypress, and Selenium.

## Features

### 🌐 **Browser Testing Ready**

- **Google Chrome Stable** - Latest stable version with security updates
- **ChromeDriver** - Automatically matched to Chrome version
- **Headless Mode** - Optimized for CI/CD environments
- **Virtual Display (Xvfb)** - For GUI applications in containerized environments

### 🧪 **Testing Frameworks Included**

- **Playwright** - Microsoft's modern browser automation
- **Cypress** - JavaScript end-to-end testing framework
- **Selenium** - Industry standard web automation
- **Node.js 20** - For npm-based testing tools
- **Python 3** - For Python-based testing frameworks

### ⚡ **Performance Optimized**

- **Resource Limits** - 4GB memory, 2 CPU cores by default
- **Shared Memory** - 2GB for Chrome processes
- **Cache Volumes** - Persistent storage for browser data and dependencies
- **Multi-instance Scaling** - Run multiple runners for parallel testing

## Quick Start

### 1. Build the Chrome Runner Image

```bash
# Build locally
./scripts/build-chrome.sh

# Build and push to registry
./scripts/build-chrome.sh --push

# Build multi-architecture
./scripts/build-chrome.sh --multi-arch --push
```

### 2. Configure Environment

```bash
# Copy example configuration
cp config/chrome-runner.env.example config/chrome-runner.env

# Edit configuration
vi config/chrome-runner.env
```

Required environment variables:

- `GITHUB_TOKEN` - Personal access token with repo permissions
- `GITHUB_REPOSITORY` - Target repository (e.g., "owner/repo")

### 3. Run with Docker Compose

```bash
# Start single Chrome runner
GITHUB_TOKEN=<token> GITHUB_REPOSITORY=<repo> \
docker-compose -f docker/docker-compose.chrome.yml up -d

# Scale to multiple runners
GITHUB_TOKEN=<token> GITHUB_REPOSITORY=<repo> \
docker-compose -f docker/docker-compose.chrome.yml up -d --scale chrome-runner=3
```

### 4. Run with Docker

```bash
docker run -d \
  --name github-chrome-runner \
  --shm-size=2g \
  -e GITHUB_TOKEN=<your_token> \
  -e GITHUB_REPOSITORY=<your_repo> \
  -e RUNNER_LABELS=chrome,ui-tests,selenium,playwright \
  ghcr.io/grammatonic/github-runner:chrome-latest
```

## Usage in GitHub Actions

### Targeting Chrome Runners

Use specific labels to target Chrome runners in your workflow:

```yaml
name: Web UI Tests

on: [push, pull_request]

jobs:
  ui-tests:
    runs-on: [self-hosted, chrome, ui-tests]

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Run Playwright tests
        run: npx playwright test
        env:
          CI: true
```

### Available Runner Labels

The Chrome runner automatically registers with these labels:

- `chrome` - Chrome browser available
- `ui-tests` - Optimized for UI testing
- `selenium` - Selenium WebDriver ready
- `playwright` - Playwright framework ready
- `cypress` - Cypress framework ready
- `headless` - Headless browser mode
- `browser-testing` - General browser testing

## Testing Framework Examples

### Playwright

```javascript
// playwright.config.js
module.exports = {
  use: {
    // Use the pre-installed Chrome
    channel: "chrome",
    headless: true,
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
};
```

### Selenium (Python)

```python
# test_example.py
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

def test_chrome_selenium():
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")

    driver = webdriver.Chrome(options=chrome_options)
    driver.get("https://example.com")
    assert "Example" in driver.title
    driver.quit()
```

### Cypress

```javascript
// cypress.config.js
module.exports = {
  e2e: {
    baseUrl: "http://localhost:3000",
    video: true,
    screenshotOnRunFailure: true,
    browser: "chrome",
    chromeWebSecurity: false,
  },
};
```

## Configuration Options

### Environment Variables

| Variable            | Description                  | Default                                                         |
| ------------------- | ---------------------------- | --------------------------------------------------------------- |
| `GITHUB_TOKEN`      | GitHub personal access token | **Required**                                                    |
| `GITHUB_REPOSITORY` | Target repository            | **Required**                                                    |
| `RUNNER_NAME`       | Runner instance name         | `chrome-runner-{hostname}`                                      |
| `RUNNER_LABELS`     | Comma-separated labels       | `chrome,ui-tests,selenium,playwright,cypress`                   |
| `RUNNER_GROUP`      | Runner group name            | `chrome-runners`                                                |
| `CHROME_FLAGS`      | Chrome browser flags         | `--headless --no-sandbox --disable-dev-shm-usage --disable-gpu` |
| `DISPLAY`           | Virtual display number       | `:99`                                                           |
| `NODE_OPTIONS`      | Node.js memory options       | `--max-old-space-size=4096`                                     |

### Resource Limits

```yaml
# docker-compose.chrome.yml
deploy:
  resources:
    limits:
      memory: 4G
      cpus: "2"
    reservations:
      memory: 2G
      cpus: "1"
```

### Volume Mounts

- `chrome-workspace` - Persistent workspace directory
- `chrome-cache` - Browser cache and temporary files
- `playwright-browsers` - Playwright browser binaries
- `chrome-user-data` - Chrome user profile data

## Troubleshooting

### Common Issues

**Chrome fails to start:**

```bash
# Check if runner has sufficient shared memory
docker run --shm-size=2g ...

# Verify Chrome flags
--no-sandbox --disable-dev-shm-usage --disable-gpu
```

**Tests timeout:**

```bash
# Increase memory limits
NODE_OPTIONS=--max-old-space-size=8192

# Adjust browser timeout settings
BROWSER_TIMEOUT=60000
```

**Permission denied errors:**

```bash
# Ensure proper security context
security_opt:
  - seccomp:unconfined
```

### Debug Mode

Run the container interactively for debugging:

```bash
docker run -it --rm \
  --shm-size=2g \
  -e GITHUB_TOKEN=<token> \
  -e GITHUB_REPOSITORY=<repo> \
  ghcr.io/grammatonic/github-runner:chrome-latest \
  bash
```

### Health Checks

The Chrome runner includes health checks to monitor runner status:

```bash
# Check runner process
docker exec <container> pgrep -f "Runner.Listener"

# View runner logs
docker logs <container>

# Check Chrome availability
docker exec <container> google-chrome-stable --version
```

## Performance Optimization

### Multiple Runners

Scale Chrome runners for parallel test execution:

```bash
# Scale to 5 runners
docker-compose -f docker/docker-compose.chrome.yml up -d --scale chrome-runner=5
```

### Resource Allocation

Adjust resources based on test complexity:

```yaml
# For heavy UI tests
deploy:
  resources:
    limits:
      memory: 8G
      cpus: "4"
```

### Browser Caching

Utilize persistent volumes for faster test execution:

```yaml
volumes:
  - playwright-browsers:/home/runner/.cache/ms-playwright
  - chrome-cache:/home/runner/.cache
```

## Security Considerations

- Use dedicated GitHub tokens with minimal required permissions
- Regularly update base images for security patches
- Monitor runner logs for suspicious activity
- Use runner groups to isolate Chrome runners from general runners

## CI/CD Integration

The Chrome runner integrates seamlessly with the existing CI/CD pipeline:

- **Automated Builds** - Built and pushed via GitHub Actions
- **Version Tagging** - Tagged with Chrome and runner versions
- **Multi-Architecture** - Supports both amd64 and arm64
- **Registry Integration** - Published to GitHub Container Registry

For more information, see the main [GitHub Runner Documentation](../README.md).
