# GitHub Actions Runner API Reference

## Health Check Endpoint

### GET /health

Returns the current health status of the runner (Chrome or normal).

**Response:**

```json
{
  "status": "healthy",
  "timestamp": "2025-09-10T10:30:00Z",
  "runner_id": "runner-001",
  "registration_status": "registered",
  "last_job": "2025-09-10T10:25:00Z",
  "uptime": 3600,
  "type": "chrome" // or "normal"
}
```

**Status Codes:**

- `200` - Healthy
- `503` - Unhealthy

## Metrics Endpoint

### GET /metrics

Returns Prometheus metrics for monitoring runner health and job execution.

**Key Metrics:**

- `github_runner_jobs_total` - Total jobs executed
- `github_runner_jobs_duration_seconds` - Job execution time
- `github_runner_registration_status` - Registration health (1 = registered, 0 = not registered)
- `github_runner_last_job_timestamp` - Timestamp of last job
- `github_runner_uptime_seconds` - Runner uptime in seconds
- `github_runner_type` - Runner type (chrome/normal)

## Container Labels

All containers include standardized labels:

- `com.github.runner.version` - Runner version
- `com.github.runner.repository` - Target repository
- `com.github.runner.environment` - Environment (dev/staging/production)
- `com.github.runner.created` - Creation timestamp
- `com.github.runner.type` - Runner type (chrome/normal)

## Environment Variables

### Required

- `GITHUB_TOKEN` - GitHub Personal Access Token
- `GITHUB_REPOSITORY` - Target repository (e.g., "owner/repo")
- For Chrome runner: must be run on `linux/amd64` (see docs/chrome-runner.md)

### Optional

- `RUNNER_LABELS`, `RUNNER_NAME`, `RUNNER_GROUP`, `RUNNER_WORKDIR`, `DISPLAY`, `CHROME_FLAGS`, etc. (see config/runner.env.example and config/chrome-runner.env.example)

## Exit Codes

- `0` - Success
- `1` - General error
- `2` - Registration failed
- `3` - Token invalid
- `4` - Repository not found
- `5` - Network error
- `10` - Configuration error
- `20` - Artifact upload error (Playwright screenshot)
