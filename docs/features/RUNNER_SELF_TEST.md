# Runner Self-Test (issue #969)

This document explains how to smoke-test that self-hosted runners (standard and Chrome) accept GitHub Actions jobs and can execute a simple test workflow. All runner images are now based on `ubuntu:questing` (25.10 pre-release) and support the latest GitHub Actions runner version.

What this provides

- A small workflow `.github/workflows/runner-test-job.yml` which is intended to run on a runner labeled `gh-runner-test`.
- A helper script `scripts/runner-self-test.sh` that brings up your runner containers using the existing Docker Compose, waits for the runner to register, dispatches the test workflow, waits for completion, and then tears down the containers.

Quickstart

1. Create a repository runner registration token (Repository Settings → Actions → Runners → Add runner). Export it as `RUNNER_TOKEN`.
2. Ensure you have a GH CLI token in `GH_PAT` with repo and workflow permissions.
3. Set `GH_REPO` to the owner/repo string (for example `GrammaTonic/github-runner`).
4. Run the script (example):

```bash
export GH_REPO=GrammaTonic/github-runner
export GH_PAT=ghp_xxx
export RUNNER_TOKEN=xxxx
./scripts/runner-self-test.sh
```

Notes

- The compose file defaults to `docker/docker-compose.production.yml`. If you use a different compose file, set `COMPOSE_FILE`.
- The workflow runs on label `gh-runner-test`. You can change the label by exporting `RUNNER_LABEL` before running the script.
- This script and workflow are intentionally minimal; extend with browser tests or Playwright runs as needed.

Security

- Keep `GH_PAT` and `RUNNER_TOKEN` secret. The script expects you to provide them and will not persist them.
