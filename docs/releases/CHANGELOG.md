# Changelog

## [Unreleased]
- Pending items

## [v2.2.0] - 2025-11-14
- Promote standard, Chrome, and Chrome-Go runner images to **v2.2.0**.
- Force `tar@7.5.2`, `cross-spawn@7.0.6`, and `brace-expansion@2.0.2` into every npm distribution (system, global, embedded) to mitigate CVE-2024-47554 and related advisories.
- Update Chrome runner stacks to Chrome **142.0.7444.162**, Playwright **1.55.1**, Cypress **13.15.0**, and Node.js **24.11.1**.
- Refresh documentation, version overview, and wiki pages for Questing base image guidance and release automation workflow parity.

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
