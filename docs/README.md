# GitHub Runner Documentation

This directory contains all project documentation organized by category. All documentation blocks, examples, and API docs are now synced with the latest code and workflow changes (as of 2025-09-10).

## 📁 Directory Structure

```
docs/
├── community/          # Community health files
│   ├── CODE_OF_CONDUCT.md
│   ├── CONTRIBUTING.md
│   └── SECURITY.md
├── features/           # Feature documentation
│   └── CHROME_RUNNER_FEATURE.md
├── releases/           # Release notes and changelogs
│   └── RELEASE_NOTES_v1.1.0.md
├── archive/            # Archived or deprecated documentation
│   └── README_corrupted.md
└── README.md           # This file
```

## 🔗 Quick Links

### Community

- [Code of Conduct](community/CODE_OF_CONDUCT.md) - Community behavior guidelines
- [Contributing Guidelines](community/CONTRIBUTING.md) - How to contribute to the project
- [Security Policy](../.github/SECURITY.md) - Security vulnerability reporting

### Features

- [Chrome Runner Feature](features/CHROME_RUNNER_FEATURE.md) - Specialized Chrome runner implementation

### Releases

- [Release Notes v1.1.0](releases/RELEASE_NOTES_v1.1.0.md) - Latest release information

### Main Documentation

- [Project README](../README.md) - Main project documentation
- [Setup Guide](../docs/SETUP_SUMMARY.md) - Quick setup instructions
- [API Documentation](API.md) - API reference
- [Deployment Guide](DEPLOYMENT.md) - Production deployment instructions
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

### Naming Conventions

- Use descriptive filenames
- Follow feature or page-based naming for test and example files

### Content Guidelines

- Include clear headings and navigation
- Sync documentation blocks and examples with code changes
- Document all major workflow, runner, and CI/CD improvements

**📋 Note**: This structure helps maintain a clean root directory while keeping documentation organized and easily discoverable.
