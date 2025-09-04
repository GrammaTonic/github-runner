# GitHub Actions Runner API Reference

## Health Check Endpoint

### GET /health

Returns the current health status of the runner.

**Response:**

```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "runner_id": "runner-001",
  "registration_status": "registered",
  "last_job": "2024-01-15T10:25:00Z",
  "uptime": 3600
}
```

**Status Codes:**

- `200` - Healthy
- `503` - Unhealthy

## Metrics Endpoint

### GET /metrics

Returns Prometheus metrics for monitoring.

**Key Metrics:**

- `github_runner_jobs_total` - Total jobs executed
- `github_runner_jobs_duration_seconds` - Job execution time
- `github_runner_registration_status` - Registration health (1 = registered, 0 = not registered)
- `github_runner_last_job_timestamp` - Timestamp of last job
- `github_runner_uptime_seconds` - Runner uptime in seconds

## Container Labels

All containers include standardized labels:

- `com.github.runner.version` - Runner version
- `com.github.runner.repository` - Target repository
- `com.github.runner.environment` - Environment (dev/staging/production)
- `com.github.runner.created` - Creation timestamp

## Environment Variables

### Required

- `GITHUB_TOKEN` - GitHub Personal Access Token
- `GITHUB_REPOSITORY` - Target repository (owner/repo format)

### Optional

- `RUNNER_LABELS` - Comma-separated list of custom labels
- `RUNNER_NAME_PREFIX` - Prefix for runner names (default: "runner")
- `RUNNER_WORKDIR` - Working directory (default: "/actions-runner/\_work")
- `REGISTRATION_TIMEOUT` - Registration timeout in seconds (default: 300)
- `RUNNER_ALLOW_RUNASROOT` - Allow running as root (default: false)

## Exit Codes

- `0` - Success
- `1` - General error
- `2` - Registration failed
- `3` - Token invalid
- `4` - Repository not found
- `5` - Network error
- `10` - Configuration error
