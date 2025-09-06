# Branch Strategy and Development Workflow

This document outlines the branch strategy and development workflow for the GitHub Runner project.

## 🌿 Branch Structure

### Primary Branches

#### `main` Branch

- **Purpose**: Production-ready code only
- **Protection**: Fully protected with branch protection rules
- **Access**: No direct pushes allowed - only through approved PRs
- **Deployment**: Automatically deploys to production environments
- **Stability**: Should always be stable and deployable

#### `develop` Branch (Integration)

- **Purpose**: Integration branch for feature work and testing
- **Access**: Feature branches target `develop` via PRs
- **Testing**: CI/CD runs full test suite on `develop` for integration validation
- **Integration**: Aggregates feature work prior to promotion to `main`

### Supporting Branches

#### Feature Branches

- **Naming**: `feature/feature-name` or `feature/issue-number-description`
  -- **Source**: Created from `develop`
  -- **Target**: Merged back to `develop` via PR
- **Lifecycle**: Deleted after successful merge
- **Purpose**: Develop new features, enhancements, or improvements

#### Hotfix Branches

- **Naming**: `hotfix/issue-description` or `hotfix/issue-number`
- **Source**: Created from `main` (hotfixes are applied directly to production branch)
- **Target**: Merged to `main` via PR, then `main` → `develop` to keep integration branch in sync
- **Purpose**: Critical bug fixes that need immediate attention

## 🔄 Development Workflow

### 1. Starting New Work

```bash
# Always start from develop for regular feature work
git checkout develop
git pull origin develop

# Create your working branch
git checkout -b feature/your-feature-name
# or for hotfixes (branch from main):
# git checkout -b hotfix/critical-fix main
```

### 2. During Development

```bash
git commit -m "feat: implement new feature"
# Make your changes
git add .
git commit -m "feat: implement new feature"

# Keep your branch updated with develop
git checkout develop
git pull origin develop
git checkout feature/your-feature-name
git merge develop  # or rebase if preferred
```

### 3. Submitting Changes

```bash
# Push your branch
git push origin feature/your-feature-name

# Create PR: feature/your-feature-name → develop
# Get code review and approval
# Merge through GitHub UI
```

### 4. Release Process

```bash
# When ready for release, create PR: develop → main (maintainers) or tag a release from main
# This triggers production deployment after approval
```

## 🛡️ Branch Protection Rules

### Main Branch Protection

- ✅ Require pull request reviews (1 approval minimum)
- ✅ Dismiss stale reviews when new commits are pushed
- ✅ Enforce for administrators
- ✅ Require branches to be up to date before merging
- ✅ No force pushes allowed
- ✅ No direct pushes allowed

### Develop Branch (Recommended)

- ✅ Require pull request reviews
- ✅ Require status checks to pass
- ✅ Allow force pushes with lease (for maintainers)

## 📋 Workflow Examples

### Adding a New Feature

```bash
# 1. Start from develop
git checkout develop
git pull origin develop

# 2. Create feature branch
git checkout -b feature/chrome-runner-optimization

# 3. Develop and commit
git add .
git commit -m "feat: optimize Chrome runner memory usage"

# 4. Push and create PR
git push origin feature/chrome-runner-optimization
# Create PR: feature/chrome-runner-optimization → develop

# 5. After approval and merge, delete branch
git branch -d feature/chrome-runner-optimization
```

### Hotfix Process

```bash
# 1. Start from develop (even for hotfixes)
git checkout develop
git pull origin develop

# 2. Create hotfix branch
git checkout -b hotfix/security-vulnerability-fix

# 3. Fix the issue
git add .
git commit -m "fix: resolve security vulnerability CVE-2023-XXXX"

# 4. Push and create urgent PR
git push origin hotfix/security-vulnerability-fix
# Create PR: hotfix/security-vulnerability-fix → develop

# 5. After merge to develop, create release PR
# Create PR: develop → main (for immediate release)
```

### Release Process

```bash
# 1. Ensure develop is ready for release
git checkout develop
git pull origin develop

# 2. Run final tests
npm test  # or your test command

# 3. Create release PR
# Create PR: develop → main

# 4. After approval and merge:
# - Production deployment triggers automatically
# - Create git tag for the release
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin v1.2.0
```

## ❌ What NOT to Do

- ❌ **Never work directly on `main`** - Always work on feature branches created from `develop` and merge to `develop` via PR
- ❌ **Never force push to `main`** - It's protected anyway
- ❌ **Never merge to `main` without PR** - Branch protection prevents this; use `develop` → `main` PRs for promotion
- ✅ **Feature branches should be created from `develop` and kept up-to-date with `develop`**
- ❌ **Never bypass code review** - All changes must go through PR process

## ✅ Best Practices

- ✅ **Use descriptive branch names** - `feature/add-prometheus-metrics` not `feature/metrics`
- ✅ **Keep branches focused** - One feature/fix per branch
- ✅ **Write clear commit messages** - Follow conventional commits format
- ✅ **Test before pushing** - Run tests locally before creating PR
- ✅ **Keep PRs small** - Easier to review and less likely to have conflicts
- ✅ **Update branch regularly** - Merge/rebase from `main` frequently
- ✅ **Delete merged branches** - Keep repository clean

## 🔍 Monitoring and Maintenance

### Branch Health

- Monitor `develop` branch for:
  - CI/CD pipeline success
  - Code quality metrics
  - Security scan results
  - Test coverage

### Release Readiness

- `develop` should always be in a releasable state
- Regular cleanup of stale branches
- Periodic security updates and dependency management

## 📞 Support

For questions about the development workflow:

- Check the [Contributing Guide](../community/CONTRIBUTING.md)
- Open a [Discussion](https://github.com/GrammaTonic/github-runner/discussions)
- Contact maintainers through GitHub issues

---

This workflow ensures code quality, stability, and enables smooth collaboration while maintaining a production-ready `main` branch at all times.
