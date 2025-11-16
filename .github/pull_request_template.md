## 📋 Pull Request Description

### 🔀 Merge Strategy

**This repository uses SQUASH MERGE as the standard merge strategy.**

**Why Squash Merge?**
- ✅ **Clean, linear commit history** on `main` branch - easier to understand project evolution
- ✅ **One commit per feature/fix** - easier rollbacks and cherry-picking
- ✅ **Better release notes** - automated changelog generation from squashed commits
- ✅ **Simplified CI/CD** - cleaner git history for automated release processes
- ✅ **Consistent with Dependabot** - auto-merge configuration uses squash strategy
- ✅ **Reduced noise** - no "fix typo" or "address review comments" commits in main
- ✅ **Easier bisecting** - each commit represents a complete, logical change

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
# Via GitHub CLI (recommended - ensures squash merge):
gh pr merge <PR_NUMBER> --squash --delete-branch --body "Squash merge: <brief summary>"

# Via GitHub Web UI:
# 1. Click "Squash and merge" button (NOT "Merge pull request" or "Rebase and merge")
# 2. Edit the commit message if needed
# 3. Confirm the merge
# 4. Delete the branch
```

**⚠️ CRITICAL: After squash merging to `main`, you MUST back-sync `develop`** (see Post-Merge Back-Sync section below).

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

**Post-Merge Back-Sync (CRITICAL after squash merging to main):**

**⚠️ MANDATORY STEP - DO NOT SKIP THIS!**

**Why is this needed?**
When you squash merge a PR from `develop` to `main`, the individual commits from `develop` are condensed into a single commit on `main`. This causes `develop` to appear "ahead" of `main` in git history, even though the code is identical. The back-sync merge resolves this divergence and prevents:
- ❌ Incorrect "X commits ahead" status on `develop`
- ❌ Merge conflicts on subsequent PRs
- ❌ CI/CD pipeline confusion
- ❌ Duplicate commits in future merges

**When to perform back-sync:**
- ✅ **ALWAYS** after merging a promotion PR (`develop` → `main`) with squash merge
- ✅ **ALWAYS** after merging any PR directly to `main` with squash merge
- ✅ **IMMEDIATELY** after the squash merge completes (don't wait!)
- ❌ NOT needed when merging feature branches to `develop` (develop will be promoted later)

**How to perform back-sync:**
```bash
# Step 1: Ensure your local branches are up-to-date
git fetch --all

# Step 2: Switch to develop and pull latest
git checkout develop
git pull origin develop

# Step 3: Merge main back into develop (creates a merge commit)
git merge main -m "chore: sync develop with main after squash merge"

# Step 4: Push the back-sync to remote
git push origin develop

# This ensures develop stays in sync with main after squash merges
# The merge commit preserves the development history in develop
# while keeping main's linear squashed history
```

**Alternative (using GitHub CLI):**
```bash
# Create a back-sync PR (for teams requiring PR workflow)
git checkout develop
git pull origin develop
git checkout -b chore/backsync-main-to-develop
git merge main -m "chore: sync develop with main after squash merge"
git push origin chore/backsync-main-to-develop
gh pr create --base develop --head chore/backsync-main-to-develop \
  --title "chore: back-sync main to develop after squash merge" \
  --body "Automatic back-sync after squash merging to main. This prevents 'ahead' status."
gh pr merge --merge --delete-branch  # Use regular merge, not squash!
```

**Verification:**
```bash
# After back-sync, these commands should show no differences:
git diff main..develop  # Should be empty (no code differences)
git log --oneline main..develop  # Should only show merge commits (no unique commits)

# Check branch status (should show "up to date"):
git checkout develop
git status
# Should NOT say "Your branch is ahead of 'origin/develop'"
```

**Troubleshooting:**
```bash
# If you forgot to back-sync and now have conflicts:
git checkout develop
git pull origin develop
git fetch origin main
git merge origin/main -m "chore: late back-sync after squash merge"
# Resolve any conflicts, then:
git push origin develop
```

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
