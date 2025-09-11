# Release Notes v2.1.0

## Highlights
- Chrome runner now uses `ubuntu:questing` (25.10 pre-release) for latest browser and system dependencies.
- CVE mitigation strategy documented: npm overrides, local installs, Trivy scan automation, and audit workflow.
- All images are scanned with Trivy; results saved to `test-results/docker/` for compliance and review.
- Documentation and wiki updated to reflect questing usage and security practices.
- Migration notes for switching to stable Ubuntu LTS for production included in README and DEPLOYMENT docs.

## Security & Compliance
- All app-level dependencies patched using npm overrides and local installs.
- CVEs in npm's internal modules are documented and monitored; not directly fixable but do not impact runner security.
- Trivy scan results are now part of the release audit trail.

## Migration Notes
- For production, use `ubuntu:24.04` and rerun all security scans.
- See [DEPLOYMENT.md](../DEPLOYMENT.md) and [README.md](../../README.md) for details.

## References
- See PR #<PR_NUMBER> or commit <COMMIT_HASH> for full change history.
- For audit and compliance, review Trivy scan outputs in `test-results/docker/`.

---
Release date: 2025-09-11
