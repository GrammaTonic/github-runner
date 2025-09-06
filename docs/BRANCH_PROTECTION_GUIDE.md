# Branch Protection and Git Workflow Guide

This guide explains the branch protection setup and recommended Git workflow for the GitHub Runner repository.

## Branch Structure

### 🌟 Main Branch (`main`)

- **Purpose**: Production-ready code
- **Protection Level**: Maximum security
- **Deployment**: Automatic to production (with approvals)
- **Access**: Restricted to maintainers via pull requests only

### 🚀 Develop Branch (`develop`)

- **Purpose**: Integration branch for new features
- **Protection Level**: Standard security
- **Deployment**: Automatic to staging environment
- **Access**: Team members via pull requests

### 🔧 Feature Branches (`feature/*`)

- **Purpose**: Individual feature development
- **Protection Level**: None (developer managed)
- **Naming**: `feature/description` or `feature/ticket-number`
- **Lifecycle**: Created from `develop`, merged back to `develop`

### 🐛 Hotfix Branches (`hotfix/*`)

- **Purpose**: Critical production fixes
- **Protection Level**: Emergency bypass available
- **Naming**: `hotfix/description` or `hotfix/cve-number`
- **Lifecycle**: Created from `main`, merged to both `main` and `develop`

## Branch Protection Rules

### Main Branch Protection

```yaml
Required Status Checks:
  - Lint and Validate
  - Security Scanning
  - Build Docker Images
  - Test Runner Configuration (unit)
  - Test Runner Configuration (integration)
  - Test Runner Configuration (config)
  - Container Security Scan

Pull Request Reviews:
  - Required reviewers: 1
  - Dismiss stale reviews: Yes
  - Require code owner reviews: Yes
  - Require review of last push: Yes

Additional Restrictions:
  - Linear history required: Yes
  - Force pushes: Blocked
  - Deletions: Blocked
  - Admin enforcement: Yes
  - Conversation resolution: Required
```

### Develop Branch Protection

```yaml
Required Status Checks:
  - Lint and Validate
  - Security Scanning
  - Build Docker Images
  - Test Runner Configuration (unit)
  - Test Runner Configuration (integration)

Pull Request Reviews:
  - Required reviewers: 1
  - Dismiss stale reviews: Yes
  - Require code owner reviews: No
  - Require review of last push: No

Additional Restrictions:
  - Linear history required: No
  - Force pushes: Blocked
  - Deletions: Blocked
  - Admin enforcement: No
  - Conversation resolution: Required
```

## Git Workflow

### 1. Feature Development

```bash
# Start from develop branch
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/add-monitoring-dashboard

# Make changes and commit
git add .
git commit -m "feat: add monitoring dashboard for runner health

- Add Grafana dashboard configuration
- Include Prometheus metrics collection
- Update documentation"

# Push feature branch
git push origin feature/add-monitoring-dashboard

# Create pull request to develop branch
gh pr create --base develop --title "feat: add monitoring dashboard" --body "..."
```

### 2. Release Process

```bash
# From develop branch, create release
git checkout develop
git pull origin develop

# All features are tested in staging, ready for production
git checkout main
git pull origin main

# Create pull request from develop to main
gh pr create --base main --head develop --title "Release v1.2.0" --body "..."

# After approval and merge, tag the release
git checkout main
git pull origin main
git tag v1.2.0
git push origin v1.2.0
```

### 3. Hotfix Process

```bash
# Create hotfix from main
git checkout main
git pull origin main
git checkout -b hotfix/security-vulnerability-fix

# Make critical fix
git add .
git commit -m "fix: patch critical security vulnerability CVE-2024-XXXX"

# Push hotfix
git push origin hotfix/security-vulnerability-fix

# Create PR to main (emergency bypass if needed)
gh pr create --base main --title "HOTFIX: Security vulnerability patch" --body "..."

# After merge to main, also merge to develop
git checkout develop
git pull origin develop
git merge main
git push origin develop
```

## Emergency Procedures

### Emergency Branch Protection Bypass

For critical production incidents, you can temporarily disable branch protection via GitHub's web interface:

```bash
# 1. Go to GitHub repository settings
# 2. Navigate to Branches → main → Edit
# 3. Temporarily disable "Restrict pushes that create files"
# 4. Make emergency fix directly to main
git checkout main
git add .
git commit -m "emergency: critical security patch"
git push origin main

# 5. Re-enable branch protection in GitHub settings immediately
```

### Rollback Procedures

```bash
# Quick rollback using Git revert
git checkout main
git revert HEAD
git push origin main

# Or rollback to specific commit
git checkout main
git revert <commit-hash>
git push origin main
```

## Code Review Guidelines

### Required for All Pull Requests

1. **Code Quality**

   - Follows coding standards
   - Includes appropriate tests
   - Documentation updated
   - No security vulnerabilities

2. **CI/CD Integration**

   - All workflow checks pass
   - Security scans clean
   - Build successful
   - Tests passing

3. **Security Review**
   - No hardcoded secrets
   - Proper permission scoping
   - Vulnerability scan results reviewed
   - Dependencies up to date

### Review Process

1. **Automated Checks**: CI/CD workflows run automatically
2. **Code Owner Review**: Required for critical paths
3. **Security Review**: For security-related changes
4. **Final Approval**: Minimum required reviewers approve
5. **Merge**: Squash and merge to maintain clean history

## Environment Management

### Staging Environment

- **Trigger**: Push to `develop` branch
- **Purpose**: Feature testing and integration validation
- **Access**: Development team
- **Data**: Sanitized production data or test data

### Production Environment

- **Trigger**: Push to `main` branch
- **Purpose**: Live GitHub runner deployment
- **Access**: Operations team with manual approval
- **Data**: Live production data
- **Monitoring**: 24/7 monitoring and alerting

## Monitoring and Compliance

### Branch Protection Monitoring

The monitoring workflow checks:

- Branch protection rules are active
- Required status checks are enforced
- Code review requirements are met
- Emergency bypass usage is logged

### Compliance Reporting

- All changes tracked in audit log
- Emergency actions logged with justification
- Regular security scans and vulnerability reports
- Automated compliance checks in CI/CD

## Troubleshooting

### Common Issues

1. **CI Checks Failing**

   ```bash
   # Check workflow status
   gh run list --branch feature/your-branch

   # View specific workflow run
   gh run view <run-id>
   ```

2. **Permission Denied**

   ```bash
   # Check your repository permissions
   gh api repos/GrammaTonic/github-runner/collaborators/$(gh api user --jq .login)
   ```

3. **Branch Protection Conflicts**
   ```bash
   # View current protection rules
   gh api repos/GrammaTonic/github-runner/branches/main/protection
   ```

### Getting Help

- Check workflow logs in GitHub Actions tab
- Review CI/CD pipeline documentation
- Contact repository maintainers
- Use emergency procedures for critical issues

---

**Remember**: These protection rules ensure code quality, security, and stability. Always follow the established workflow and only use emergency procedures for genuine critical situations.
