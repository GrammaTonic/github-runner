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

Returns Prometheus-formatted metrics for monitoring runner health and job execution.

**Port:** 9091 (container port). Host port mappings: 9091 (standard), 9092 (chrome), 9093 (chrome-go).

**Content-Type:** `text/plain; version=0.0.4; charset=utf-8`

**Metrics Exposed:**

| Metric | Type | Description |
|---|---|---|
| `github_runner_status` | gauge | Runner status (1=online, 0=offline) |
| `github_runner_info` | gauge | Runner metadata (name, type, version) |
| `github_runner_uptime_seconds` | counter | Runner uptime in seconds |
| `github_runner_jobs_total` | counter | Total jobs by status (total, success, failed) |
| `github_runner_job_duration_seconds` | histogram | Job duration distribution (buckets: 60s–3600s) |
| `github_runner_queue_time_seconds` | gauge | Average queue wait time (last 100 jobs) |
| `github_runner_cache_hit_rate` | gauge | Cache hit rate by type (stubbed at 0) |
| `github_runner_last_update_timestamp` | gauge | Unix timestamp of last metrics update |

All metrics carry `runner_name` and `runner_type` labels.

For full metric definitions, see [Metrics Reference](features/PROMETHEUS_METRICS_REFERENCE.md).
For PromQL query examples, see [Usage Guide](features/PROMETHEUS_USAGE.md).

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
