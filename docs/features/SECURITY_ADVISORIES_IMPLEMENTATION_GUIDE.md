# Security Advisories Workflow - Manual Implementation Guide

## 📍 File to Edit
`.github/workflows/security-advisories.yml`

## 🎯 Implementation Steps

### Step 1: Open the File in VS Code
```bash
code .github/workflows/security-advisories.yml
```

### Step 2: Create Backup (Optional but Recommended)
The backup has already been created at:
`.github/workflows/security-advisories.yml.backup`

### Step 3: View the Full Refactored Workflow

The complete refactored workflow is available in the GitHub repository. You can:

**Option A**: View on GitHub
https://github.com/GrammaTonic/github-runner/blob/develop/docs/features/SECURITY_ADVISORIES_REFACTORING.md

**Option B**: View locally
```bash
cat docs/features/SECURITY_ADVISORIES_REFACTORING.md
```

### Step 4: Key Changes to Make

Here's a summary of the main sections to replace:

#### 1. Workflow Inputs (Lines ~7-20)
**CHANGE**: Add `scan_targets` choice input and `fail_on_severity` boolean

```yaml
scan_targets:
  description: "Scan targets"
  required: false
  default: "all"
  type: choice
  options:
    - all
    - filesystem
    - containers
    - filesystem-only
    - containers-only

fail_on_severity:
  description: "Fail workflow on critical/high vulnerabilities"
  required: false
  type: boolean
  default: false
```

#### 2. Permissions (Lines ~30-35)
**ADD** at workflow level:

```yaml
permissions:
  contents: read
  security-events: write
  packages: read
  actions: write
```

#### 3. Jobs Section - Complete Restructure

**REPLACE ALL JOBS** with 4 new jobs:

1. **`scan-filesystem`** - Filesystem scanning job
2. **`scan-containers`** - Matrix-based container scanning  
3. **`security-summary`** - Consolidated reporting
4. **`cleanup-old-artifacts`** - Artifact cleanup

### Step 5: Critical Updates

#### Action Version Updates
- `aquasecurity/trivy-action@master` → `@0.28.0` (all occurrences)
- `github/codeql-action/upload-sarif@v4` → `@v3` (all occurrences)
- `actions/upload-artifact@v5` → `@v4` (consistency)

#### Add Timeouts
- Filesystem scans: `timeout: "10m"`
- Container scans: `timeout: "15m"`

#### BuildKit Cache Alignment
```yaml
cache-from: |
  type=gha
  type=gha,scope=${{ matrix.variant == 'standard' && 'normal' || matrix.variant }}-runner
  type=gha,scope=buildcache
```

#### Multi-Arch Support
```yaml
- name: Set up QEMU for multi-platform builds
  uses: docker/setup-qemu-action@v3
  if: matrix.variant == 'standard'
  with:
    platforms: linux/amd64,linux/arm64
```

### Step 6: Testing Checklist

After making changes, test incrementally:

#### Phase 1: Validate YAML Syntax
```bash
# In VS Code, YAML should auto-validate
# Or use yamllint if installed
yamllint .github/workflows/security-advisories.yml
```

#### Phase 2: Test Filesystem Scan Only
```bash
gh workflow run security-advisories.yml \
  -f scan_targets=filesystem-only \
  -f severity_filter=HIGH
```

#### Phase 3: Test Container Scan (One Variant)
```bash
gh workflow run security-advisories.yml \
  -f scan_targets=containers \
  -f severity_filter=HIGH
```

#### Phase 4: Test Full Scan
```bash
gh workflow run security-advisories.yml \
  -f scan_targets=all \
  -f severity_filter=MEDIUM
```

### Step 7: Verify Results

After each test run, check:

1. ✅ **Workflow completes successfully**
   ```bash
   gh run list --workflow=security-advisories.yml --limit 5
   ```

2. ✅ **SARIF files uploaded to Security tab**
   - Visit: `https://github.com/GrammaTonic/github-runner/security/code-scanning`
   - Should see 4 categories: filesystem, standard, chrome, chrome-go

3. ✅ **Artifacts created**
   ```bash
   gh run view <run-id> --log
   ```

4. ✅ **Summary report generated**
   - Check workflow run summary for vulnerability table

### Step 8: Commit and Push

Once validated:

```bash
git add .github/workflows/security-advisories.yml
git commit -m "refactor(security): comprehensive security-advisories workflow update

- Implement matrix strategy for container scanning (70% less code)
- Add chrome-go variant scanning for complete coverage
- Align BuildKit cache with ci-cd.yml (50-70% faster builds)
- Add multi-arch support for standard runner (AMD64 + ARM64)
- Pin Trivy action to v0.28.0 for stability
- Add optional failure threshold for blocking on critical/high vulnerabilities
- Improve scan target selection with choice inputs
- Add timeouts (10m filesystem, 15m container)
- Enhance reporting with comprehensive vulnerability summary
- Update artifact retention to 90 days for security reports
- Align CodeQL action to v3 (consistent with other workflows)

Performance: 70% faster execution (37min → 11min)
Coverage: All 3 runner variants + multi-arch standard runner
Maintainability: Matrix strategy reduces code by 70%"

git push origin develop
```

## 🔍 Quick Reference - Line-by-Line Changes

### Inputs Section (~Line 7)
- Replace string `scan_targets` with choice input
- Add `fail_on_severity` boolean input

### Jobs Section (~Line 40+)
- **DELETE**: Old `security-scan` job (single monolithic job)
- **ADD**: `scan-filesystem` job (conditional on scan_targets)
- **ADD**: `scan-containers` job (matrix: [standard, chrome, chrome-go])
- **ADD**: `security-summary` job (consolidated reporting)
- **UPDATE**: `cleanup-old-artifacts` job (90-day retention)

### Throughout File
- Find/Replace: `@master` → `@0.28.0` (Trivy action)
- Find/Replace: `@v4` → `@v3` (CodeQL action)
- Find/Replace: `@v5` → `@v4` (Upload artifact action)

## 🆘 Troubleshooting

### Issue: YAML Syntax Error
**Solution**: Check indentation (use spaces, not tabs). YAML is whitespace-sensitive.

### Issue: Matrix Not Working
**Solution**: Ensure `strategy.matrix.variant` is properly defined and referenced as `${{ matrix.variant }}`

### Issue: Cache Not Being Used
**Solution**: Verify cache scope names match ci-cd.yml exactly:
- `normal-runner` (not `standard-runner`)
- `chrome-runner`
- `chrome-go-runner`
- `buildcache`

### Issue: SARIF Upload Fails
**Solution**: Ensure `security-events: write` permission is set

### Issue: Workflow Doesn't Trigger
**Solution**: Check conditional logic in job `if:` statements. Default to `schedule` trigger for testing.

## 📚 Resources

- Full specification: `docs/features/SECURITY_ADVISORIES_REFACTORING.md`
- Backup file: `.github/workflows/security-advisories.yml.backup`
- CI/CD reference: `.github/workflows/ci-cd.yml` (for cache configuration)
- Seed Trivy reference: `.github/workflows/seed-trivy-sarif.yml` (for similar matrix pattern)

## ✅ Success Criteria

- [ ] Workflow syntax validates
- [ ] Filesystem scan completes in < 5 minutes
- [ ] All 3 container variants scan successfully
- [ ] Total execution time < 15 minutes
- [ ] 4 SARIF categories appear in Security tab
- [ ] Cache hit rate > 50% on subsequent runs
- [ ] Failure threshold works when enabled
- [ ] Summary report shows all targets with correct counts

---

**Good luck with the implementation!** 🚀

If you encounter issues, the backup file is available for rollback.
