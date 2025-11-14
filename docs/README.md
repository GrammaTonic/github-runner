# GitHub Runner Documentation

This directory contains all project documentation organized by category. All documentation blocks, examples, and API docs are now synced with the latest code and workflow changes (as of 2025-11-14).

## 🛠️ Automated Documentation Validation

All documentation and wiki changes are now automatically checked for outdated references and broken links via the `.github/workflows/docs-validation.yml` workflow. Please ensure your updates pass these checks before merging.

For details, see [docs-validation.yml](../.github/workflows/docs-validation.yml).

## 📁 Directory Structure

docs/
```

├── community/          # Community health files
│   ├── CODE_OF_CONDUCT.md
│   ├── CONTRIBUTING.md
│   └── SECURITY.md
├── features/           # Feature documentation
│   ├── CHROME_RUNNER_FEATURE.md
│   ├── AUTOMATED_STAGING_RUNNER_FEATURE.md
│   ├── DEVELOPMENT_WORKFLOW.md
│   ├── RUNNER_SELF_TEST.md
│   ├── SECURITY_ADVISORY_WORKFLOW.md
│   └── USER_DEPLOYMENT_EXPERIENCE.md
├── releases/           # Release notes and changelogs
│   ├── CHANGELOG.md
│   ├── RELEASE_NOTES_v1.1.0.md
│   ├── RELEASE_NOTES_v1.1.1.md
│   ├── RELEASE_NOTES_v2.0.2.md
│   └── RELEASE_NOTES_v2.1.0.md
├── archive/            # Archived or deprecated documentation
│   ├── README_corrupted.md
│   └── CRITICAL_SECURITY_FIXES_2025.md
├── setup/              # Setup guides
│   └── quick-start.md
├── API.md              # API reference
├── DEPLOYMENT.md       # Production deployment instructions
├── SETUP_SUMMARY.md    # Quick setup instructions
├── VERSION_OVERVIEW.md # Version tracking
└── README.md           # This file
```
## 🔗 Quick Links

### Community

- [Code of Conduct](community/CODE_OF_CONDUCT.md) - Community behavior guidelines
- [Contributing Guidelines](community/CONTRIBUTING.md) - How to contribute to the project
- [Security Policy](../.github/SECURITY.md) - Security vulnerability reporting


### Features
- [Chrome Runner Feature](features/CHROME_RUNNER_FEATURE.md) - Specialized Chrome runner implementation
- [Automated Staging Runner](features/AUTOMATED_STAGING_RUNNER_FEATURE.md) - Staging runner bridge and job acceptance
- [Development Workflow](features/DEVELOPMENT_WORKFLOW.md) - Branching and PR strategy
- [Runner Self-Test](features/RUNNER_SELF_TEST.md) - Automated runner validation


### Releases
- [Changelog](releases/CHANGELOG.md) - Full release history
- [Release Notes v2.2.0](releases/RELEASE_NOTES_v2.2.0.md) - Latest release information
- [Release Notes v2.1.0](releases/RELEASE_NOTES_v2.1.0.md)
- [Release Notes v2.0.2](releases/RELEASE_NOTES_v2.0.2.md)
- [Release Notes v1.1.1](releases/RELEASE_NOTES_v1.1.1.md)
- [Release Notes v1.1.0](releases/RELEASE_NOTES_v1.1.0.md)


### Main Documentation
- [Project README](../README.md) - Main project documentation
- [Setup Guide](setup/quick-start.md) - Quick setup instructions
- [API Documentation](API.md) - API reference
- [Deployment Guide](DEPLOYMENT.md) - Production deployment instructions
- [Version Overview](VERSION_OVERVIEW.md) - Component and image versions
- [Chrome Runner Architecture Enforcement](features/CHROME_RUNNER_FEATURE.md) - Details on amd64-only support

## 📝 Documentation Guidelines


### File Organization Rules
- All documentation must be placed in `/docs/` subdirectories (never in root)
- Feature specs: `/docs/features/`
- Community files: `/docs/community/`
- Release notes: `/docs/releases/`
- Archive: `/docs/archive/`
- API docs: `/docs/API.md`
- Main README: `/README.md` (root)
- Setup guides: `/docs/setup/`

### Naming Conventions

- Use descriptive filenames
- Follow feature or page-based naming for test and example files

### Content Guidelines

- Include clear headings and navigation
- Sync documentation blocks and examples with code changes
- Document all major workflow, runner, and CI/CD improvements


### Architecture Enforcement
- Chrome runner image only supports `linux/amd64` (x86_64). Builds on ARM (Apple Silicon) will fail with a clear error.

### Security Scanning
- Automated Trivy scans for filesystem, container, and Chrome runner images
- Security scan jobs and workflow files are kept in sync across branches

### Recent Improvements
- Critical security patches for prototype pollution and DoS vulnerabilities
- Optimized Docker image sizes and cache cleaning
- Enhanced Chrome Runner with latest Playwright, Cypress, and Chrome
- Standardized Docker build contexts for CI/CD
- Automated security advisory workflow

**📋 Note**: This structure helps maintain a clean root directory while keeping documentation organized and easily discoverable.
