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
- **Lifecycle**: Created from `develop`, merged back to `develop` via pull request. After validation in `develop`, integration is promoted to `main` with a PR from `develop` → `main`.

### 🐛 Hotfix Branches (`hotfix/*`)

- **Purpose**: Critical production fixes
- **Protection Level**: Emergency bypass available
- **Naming**: `hotfix/description` or `hotfix/cve-number`
- **Lifecycle**: Created from `main`, merged to both `main` and `develop`

## Branch Protection Rules

### Main Branch Protection

```yaml
Required Status Checks:
  - CI/CD Pipeline

Pull Request Reviews:
  - Required reviewers: 1
  - Dismiss stale reviews: Yes
  - Require code owner reviews: No
  - Require review of last push: No

Additional Restrictions:
  - Linear history required: No
  - Force pushes: Blocked
  - Deletions: Blocked
  - Admin enforcement: Yes
  - Conversation resolution: Required
```

> ℹ️ The setup script attempts to apply the configuration above. If GitHub rejects some settings, it gracefully falls back to requiring the `CI/CD Pipeline` status check and one approving review without admin enforcement.

### Develop Branch Protection

```yaml
Required Status Checks:
  - lint-and-validate
  - security-scan

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

```bash
# Start from develop (feature branches should be created from the integration branch)
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

# Create pull request to develop (feature PR)
gh pr create --base develop --title "feat: add monitoring dashboard" --body "..."
```

### 2. Release Process

```bash
# Promote integration branch to main (maintainers)
git checkout develop
git pull origin develop

# Create PR to promote develop -> main after validation
gh pr create --base main --head develop --title "chore: promote develop -> main" --body "Promote integration branch to main after validation"

# After approval and merge, tag the release on main
git checkout main
git pull origin main
git tag v1.2.0
git push origin v1.2.0
```

### 3. Hotfix Process

````bash
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

## After merge to main
Always sync `develop` with `main` after hotfixes so the integration branch remains up to date:

```bash
# Sync integration branch with main
git checkout develop
git pull origin develop
git merge main
git push origin develop
```

````

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

### Review Process

1. **Automated Checks**: CI/CD workflows run automatically

## Environment Management

### Staging Environment

- **Trigger**: Push to `main` branch (or `develop` if your team uses it)
- **Purpose**: Feature testing and integration validation
- **Access**: Development team
- **Trigger**: Push to `main` branch
- **Purpose**: Live GitHub runner deployment
- **Access**: Operations team with manual approval

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

   # Check your repository permissions

   ```

   ```

2. **Branch Protection Conflicts**
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
