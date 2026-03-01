---
applyTo: '*'
description: 'Comprehensive pull request template and instructions for copilot-assisted PR creation.'
---


## 📋 Pull Request Description

### 🔀 Merge Strategy

**This repository uses a DUAL merge strategy:**
- **Feature branches → `develop`**: **Squash merge** (one clean commit per feature)
- **`develop` → `main`**: **Regular merge** (preserves shared history, no back-sync needed)

**Why this approach?**
- ✅ **Clean integration branch** - squash merging features into `develop` keeps one commit per feature/fix
- ✅ **No back-sync required** - regular merging `develop` → `main` preserves commit ancestry
- ✅ **Easier rollbacks** - each squashed commit on `develop` represents a complete, logical change
- ✅ **Better release notes** - automated changelog generation from squashed commits on `develop`
- ✅ **Simplified workflow** - no post-merge back-sync step eliminates an entire class of errors
- ✅ **Reduced noise** - no "fix typo" or "address review comments" commits on `develop`
- ✅ **Consistent Dependabot** - auto-merge uses squash strategy for PRs targeting `develop`

**How to Create a PR (Recommended):**
```bash
# Create PR using a markdown file for detailed description
gh pr create --base develop --fill-first --body-file .github/pull_request_template.md

# Or for quick PRs with inline body:
gh pr create --base develop --title "feat: your feature title" --body "Description here"

# For promotion PRs (develop → main):
gh pr create --base main --head develop --title "chore: promote develop to main" --body-file PR_DESCRIPTION.md
```

**How to Merge (Recommended):**
```bash
# Feature branch → develop (SQUASH merge):
gh pr merge <PR_NUMBER> --squash --delete-branch --body "<brief summary>"

# develop → main (REGULAR merge — do NOT squash):
gh pr merge <PR_NUMBER> --merge --body "Promote develop to main"

# Via GitHub Web UI:
# Feature → develop: Click "Squash and merge"
# develop → main:    Click "Merge pull request" (NOT squash)
```

### ⚠️ Pre-Submission Checklist

<!-- CRITICAL: Complete these steps BEFORE creating this PR -->

**Branch Sync Requirements:**
- [ ] I have pulled the latest changes from `main` branch: `git pull origin main`
- [ ] I have pulled the latest changes from `develop` branch: `git pull origin develop`
- [ ] I have rebased my feature branch on the target branch (if applicable)
- [ ] My branch is up-to-date with no merge conflicts

**Quick sync commands:**
```bash
# Fetch all remote branches
git fetch --all

# Update local main branch
git checkout main
git pull origin main

# Update local develop branch
git checkout develop
git pull origin develop

# Return to your feature branch and rebase (if needed)
git checkout <your-feature-branch>
git rebase develop  # or 'main' depending on your target branch
```

**ℹ️ No back-sync needed!** Because `develop` → `main` uses a regular merge (not squash), both branches share the same commit history. There is no divergence after merging.

### Summary

<!-- Provide a brief summary of the changes in this pull request -->

### Type of Change

<!-- Mark the relevant option with an "x" -->

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🔧 Configuration change
- [ ] 🧪 Test improvements
- [ ] 🚀 Performance improvement
- [ ] 🔒 Security enhancement

### Related Issues

<!-- Link to related issues, e.g., "Fixes #123" or "Closes #456" -->

- Fixes #
- Related to #

## 🔄 Changes Made

### Files Modified

<!-- List the key files that were modified -->

- [ ] `file1.ext` - Description of changes
- [ ] `file2.ext` - Description of changes

### Key Changes

<!-- Describe the main changes made -->

1.
2.
3.

## 🧪 Testing

### Testing Performed

<!-- Describe the testing you've done -->

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Docker build successful
- [ ] Chrome runner tested (if applicable)

### Test Coverage

<!-- If applicable, mention test coverage -->

- [ ] New tests added for new functionality
- [ ] Existing tests updated
- [ ] All tests are passing

### Manual Testing Steps

<!-- Provide steps for manual testing -->

1.
2.
3.

## 📸 Screenshots/Demos

<!-- If applicable, add screenshots or demo links -->

## 🔒 Security Considerations

<!-- Address any security implications -->

- [ ] No new security vulnerabilities introduced
- [ ] Secrets/tokens handled appropriately
- [ ] Container security best practices followed

## 📚 Documentation

<!-- Check all that apply -->

- [ ] README.md updated
- [ ] Documentation in `docs/` updated
- [ ] Wiki pages updated
- [ ] Code comments added/updated
- [ ] API documentation updated

## 🚀 Deployment Notes

<!-- Any special deployment considerations -->

- [ ] No deployment changes required
- [ ] Docker image rebuild required
- [ ] Environment variables updated
- [ ] Configuration changes needed

## ✅ Checklist

<!-- Ensure all items are completed before requesting review -->

- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## 🤖 AI Review Request

<!-- Standard reviewer assignment -->

/cc @copilot

---

**Note for Reviewers:**

- Please review the code for functionality, security, and maintainability
- Check that documentation is updated appropriately
- Verify that tests are comprehensive and passing
- Consider the impact on existing workflows and deployments
