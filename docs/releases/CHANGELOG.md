# Changelog

## [Unreleased]

## [v2.6.0] - 2026-03-02

### Prometheus Monitoring (Phases 2–6)

- **Phase 2**: Fix Chrome and Chrome-Go metrics gaps — ensure all three runner variants expose identical Prometheus metric families (#1135).
- **Phase 3**: Add DORA metrics and job lifecycle tracking — `job-started.sh`, `job-completed.sh` hooks, job duration histograms, queue-time gauges (#1136).
- **Phase 4**: Split mega-dashboard into 4 standalone Grafana dashboards — Runner Overview, Job Performance, Cache Efficiency, DORA Metrics (#1137).
- **Phase 5**: Add Prometheus monitoring user documentation and wiki pages (#1139).
- **Phase 6**: Comprehensive test suite — 6 integration test scripts (149 assertions) covering endpoint format, performance, persistence, scaling, security, and docs validation. CI/CD pipeline integration and shellcheck compliance (#1140).

### Security

- Improve `security-advisories.yml` workflow logic and coverage (#1134).

## [v2.5.0] - 2026-03-01

- Bump GitHub Actions runner to **2.332.0**.
- Optimize CI/CD pipeline for speed and cost — faster builds, reduced runner minutes (#1111).
- Fix critical and high priority security workflow optimizations (#1112).
- Improve maintenance workflow reliability, cache cleanup, and issue automation (#1115).
- Switch to dual merge strategy — squash to develop, regular merge to main (#1119).
- Replace push trigger with `workflow_run` in seed-trivy-sarif workflow (#1118).
- Strip trailing whitespace across YAML workflow files for yamllint compliance.
- Streamline PR template and copilot instructions for dual merge workflow.

## [v2.4.0] - 2026-03-01

- Update Node.js to **24.14.0** (LTS Krypton) in Chrome and Chrome-Go runners.
- Update npm to **11.11.0** in Chrome and Chrome-Go runners.
- Update Go to **1.26.1** in Chrome-Go runner.
- Update Playwright to **1.58.2** and `@playwright/test` to **1.58.2** in Chrome and Chrome-Go runners.
- Update Cypress to **15.11.0** in Chrome and Chrome-Go runners.
- Update security package overrides: `tar@7.5.9`, `brace-expansion@5.0.4`, `@isaacs/brace-expansion@5.0.1`, `glob@13.0.6`, `minimatch@10.2.4`, `diff@8.0.3`.
- Bump Chrome for Testing to **146.0.7680.31** in Chrome and Chrome-Go runners.
- Configure Playwright to use system Chrome binary via `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH`.
- Switch base image to **ubuntu:resolute** (25.10) across all Dockerfiles for latest browser dependencies.
- Patch nested `node-gyp` and `@tufjs/models` sub-modules to remediate CVEs.
- Bump GitHub Actions runner to **2.331.0**.
- Fix CI/CD Trivy scanner installation to use apt repository instead of broken wget download.
- Pin `trivy-action` to `0.34.1` for stability.

## [v2.2.0] - 2025-11-14

- Promote standard, Chrome, and Chrome-Go runner images to **v2.2.0**.
- Force `tar@7.5.2`, `cross-spawn@7.0.6`, and `brace-expansion@2.0.2` into every npm distribution (system, global, embedded) to mitigate CVE-2024-47554 and related advisories.
- Update Chrome runner stacks to Chrome **142.0.7444.162**, Playwright **1.55.1**, Cypress **13.15.0**, and Node.js **24.11.1**.
- Refresh documentation, version overview, and wiki pages for Resolute base image guidance and release automation workflow parity.

## v1.1.1 - 2025-01-15

- All documentation blocks, README, CHANGELOG, API docs, and wiki pages synced with latest code, runner, and workflow changes
- Playwright screenshot artifact upload now copies from container to host for reliable CI/CD artifact collection
- Image verification added for both Chrome and normal runners in CI/CD workflows
- Diagnostics and health checks improved for runner startup and container validation
- Chrome runner documentation updated for Playwright, Cypress, Selenium, and browser automation best practices
- ChromeDriver installation now uses Chrome for Testing API for version compatibility
- All documentation blocks, examples, and API docs synced with latest code and workflow changes
- Fixed Chrome Runner Cypress SHA.js vulnerability

- README.md: Added documentation parity summary and recent improvements
- docs/README.md: Updated file organization, content guidelines, and parity notes
- docs/API.md: Updated health check, metrics, container labels, environment variables, and exit codes
- wiki-content/Home.md: Added documentation parity and recent improvements summary
- wiki-content/Chrome-Runner.md: Synced Playwright artifact upload, diagnostics, health checks, and image verification
- wiki-content/Docker-Configuration.md: Updated for diagnostics, health checks, and image verification
- wiki-content/Installation-Guide.md: Synced installation, environment configuration, and runner setup
- wiki-content/Quick-Start.md: Updated quick start, runner configuration, and troubleshooting
- wiki-content/Common-Issues.md: Synced ChromeDriver, Playwright, and troubleshooting improvements
- wiki-content/Production-Deployment.md: Updated production deployment, scaling, and health checks
- .github/copilot-instructions.md: Synced with latest workflow and runner changes

## v1.1.0 - 2024-11-05

- No runtime changes. Documentation only.
- Please review and merge for release documentation parity.
- Initial release notes
