# Release Notes v2.2.0

## Highlights
- Standard, Chrome, and Chrome-Go runner images promoted to **v2.2.0** with refreshed metadata and documentation.
- Chrome-based runners ship Chrome **142.0.7444.162**, Playwright **1.55.1**, Cypress **13.15.0**, and Node.js **24.11.1** for parity across UI testing stacks.
- npm override now forces **tar@7.5.2** inside every embedded npm distribution (system install, global install, and runner-embedded copies) to mitigate CVE-2024-47554.
- Documentation, version overview, and wiki content updated for Questing base image guidance, security posture, and release automation workflows.

## Security & Compliance
- `cross-spawn@7.0.6`, `tar@7.5.2`, and `brace-expansion@2.0.2` copied into each npm instance (system/global/embedded).
- Chrome runners continue to install Cypress with SHA.js overrides and remove stale caches between builds.
- Release workflow publishes SBOMs and Trivy SARIF reports for each image variant (`standard`, `chrome`, `chrome-go`).

## Testing
- `./tests/docker/validate-packages.sh`

## References
- See PR #<PR_NUMBER> or commit <COMMIT_HASH> for the full change history.
- Review Trivy scan outputs under `test-results/docker/` for audit records.

---
Release date: 2025-11-14
