---
goal: Add Runner Job Acceptance Simulation (Mock/Stop Mode) Feature
version: 1.0
date_created: 2025-09-07
last_updated: 2025-09-07
owner: GrammaTonic
status: "Planned"
tags: [feature, runner, simulation, ci-cd, testing]
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

This plan introduces a simulation (mock/stop) mode for the GitHub runner, allowing it to register and simulate job acceptance without executing real jobs or making live API calls. The feature supports safe CI/CD validation, local development, and troubleshooting.

## 1. Requirements & Constraints

- **REQ-001**: Add a toggle (e.g., `RUNNER_TEST_MODE=true`) to enable simulation mode.
- **REQ-002**: In simulation mode, runner must log “Job accepted (mock)” at intervals and avoid real job execution/API calls.
- **REQ-003**: Real mode must remain unchanged.
- **REQ-004**: Integrate simulation mode with CI/CD pipeline for automated testing.
- **REQ-005**: Provide clear documentation for usage.
- **SEC-001**: Ensure no sensitive data is exposed in logs during simulation.
- **CON-001**: Must not interfere with production runner operation.
- **GUD-001**: Use environment variable for easy toggling.
- **PAT-001**: Use entrypoint script logic for simulation branching.

## 2. Implementation Steps

### Implementation Phase 1

- GOAL-001: Add simulation toggle and mock logic to runner entrypoint.

| Task     | Description                                                        | Completed | Date |
| -------- | ------------------------------------------------------------------ | --------- | ---- |
| TASK-001 | Define `RUNNER_TEST_MODE` env variable in config and compose files |           |      |
| TASK-002 | Update entrypoint.sh to check for simulation mode                  |           |      |
| TASK-003 | Implement mock registration and job acceptance loop                |           |      |
| TASK-004 | Ensure no real API calls or job execution in mock mode             |           |      |

### Implementation Phase 2

- GOAL-002: Integrate simulation mode with CI/CD and document feature.

| Task     | Description                                               | Completed | Date |
| -------- | --------------------------------------------------------- | --------- | ---- |
| TASK-005 | Add simulation mode to CI/CD pipeline jobs for validation |           |      |
| TASK-006 | Validate runner logs and status in mock mode              |           |      |
| TASK-007 | Document simulation mode usage and limitations            |           |      |
| TASK-008 | Test switching between real and mock modes                |           |      |

## 3. Alternatives

- **ALT-001**: Use a separate mock runner binary (not chosen for simplicity).
- **ALT-002**: Simulate via external test harness (less integrated, more complex).

## 4. Dependencies

- **DEP-001**: Existing runner entrypoint scripts.
- **DEP-002**: Docker Compose and environment config files.
- **DEP-003**: CI/CD pipeline configuration.

## 5. Files

- **FILE-001**: `docker/entrypoint.sh` (main runner entrypoint)
- **FILE-002**: `docker/entrypoint-chrome.sh` (chrome runner entrypoint)
- **FILE-003**: `config/runner.env.example` (env template)
- **FILE-004**: `docker/docker-compose.production.yml` (compose config)
- **FILE-005**: `.github/workflows/ci-cd.yml` (pipeline config)
- **FILE-006**: `docs/features/RUNNER_SELF_TEST.md` (feature documentation)

## 6. Testing

- **TEST-001**: Start runner in mock mode, verify registration and “Job accepted (mock)” logs.
- **TEST-002**: Ensure no real jobs or API calls in mock mode.
- **TEST-003**: CI/CD job to validate mock mode output.
- **TEST-004**: Switch between real and mock modes, verify correct behavior.

## 7. Risks & Assumptions

- **RISK-001**: Mock mode may mask real integration issues if not used carefully.
- **RISK-002**: Incorrect toggling could affect production runners.
- **ASSUMPTION-001**: Developers and CI/CD maintainers will use mock mode only for testing.

## 8. Related Specifications / Further Reading

- [Feature: RUNNER_SELF_TEST.md](../docs/features/RUNNER_SELF_TEST.md)
- [GitHub Actions Runner Docs](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
- [CI/CD Pipeline Best Practices](../docs/features/DEVELOPMENT_WORKFLOW.md)

---

[Project Board](https://github.com/users/GrammaTonic/projects/4)
