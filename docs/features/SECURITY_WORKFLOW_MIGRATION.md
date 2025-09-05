# Security Workflow Migration Guide

This guide helps you transition from the old security-issues workflow to the new security-advisories workflow.

## 🔄 Quick Migration Steps

### 1. Workflow Transition

✅ **Completed**:

- New `security-advisories.yml` workflow created
- Old `security-issues.yml` workflow disabled (renamed to `.disabled`)

### 2. Clean Up Existing Security Issues (Optional)

If you want to clean up existing automated security issues:

```bash
# List existing security issues
gh issue list --label security --limit 100

# Close all automated security issues (review before running!)
gh issue list --label security --json number --jq '.[].number' | \
  xargs -I {} gh issue close {} --comment "Migrating to Security Advisory workflow. See Security tab for current findings."
```

### 3. Update Documentation References

Search for and update any documentation that references:

- Creating security issues manually
- Security issue templates
- Issue-based security workflows

### 4. Team Communication

Inform your team about the change:

```markdown
## 🔒 Security Workflow Update

We've migrated from automated security issues to GitHub's Security tab:

**Old**: Security vulnerabilities created GitHub issues
**New**: Security vulnerabilities appear in the Security tab

**Where to find security findings now**:

- Go to Security tab → Code scanning
- Weekly reports available as workflow artifacts
- Better organization and tracking tools

**Benefits**:

- Clean issues view (no more automated security spam)
- Better vulnerability management tools
- Integration with GitHub's security ecosystem
```

## 📊 Feature Comparison

| Feature                  | Old Workflow             | New Workflow                    |
| ------------------------ | ------------------------ | ------------------------------- |
| **Issue Creation**       | ✅ Created GitHub issues | ❌ No issues created            |
| **Security Tab**         | ❌ Manual SARIF upload   | ✅ Automatic SARIF upload       |
| **Artifact Reports**     | ✅ JSON reports          | ✅ Enhanced reports + summaries |
| **Cleanup Required**     | ✅ Manual issue cleanup  | ✅ Automatic artifact cleanup   |
| **GitHub Integration**   | ❌ Limited               | ✅ Full security ecosystem      |
| **Remediation Tracking** | ❌ Basic issue tracking  | ✅ Advanced security tools      |

## 🛠️ Configuration Migration

### Workflow Parameters

The new workflow supports similar configuration options:

**Old workflow inputs**:

```yaml
min_severity: ["CRITICAL", "HIGH", "MEDIUM", "LOW"]
dry_run: boolean
scan_targets: "filesystem,container,chrome"
```

**New workflow inputs**:

```yaml
severity_filter: ["CRITICAL", "HIGH", "MEDIUM", "LOW"] # Renamed
scan_targets: "filesystem,container,chrome" # Same
# dry_run removed (no issues created anyway)
```

### Schedule

Both workflows use the same schedule:

```yaml
schedule:
  - cron: "0 2 * * 1" # Weekly on Monday at 2 AM UTC
```

## 🔧 Testing the Migration

### 1. Run the New Workflow

```bash
# Trigger a test run
gh workflow run security-advisories.yml --ref feature/security-advisories-workflow
```

### 2. Verify Security Tab Integration

1. Go to your repository's Security tab
2. Navigate to Code scanning
3. Look for the new categories:
   - `filesystem-scan`
   - `container-scan`
   - `chrome-container-scan`

### 3. Check Workflow Artifacts

1. Go to Actions → Security Advisory Management
2. Click on the latest run
3. Download the security report artifacts
4. Verify the summary report format

## 📋 Troubleshooting

### Common Issues

**Problem**: SARIF upload fails

```yaml
- name: Upload to Security tab
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: "trivy-results/filesystem.sarif"
  continue-on-error: true # This prevents workflow failure
```

**Problem**: No vulnerabilities shown in Security tab

- Check workflow run logs for SARIF upload status
- Verify the severity filter isn't too restrictive
- Ensure scan targets are configured correctly

**Problem**: Artifacts not generated

- Check for scan failures in workflow logs
- Verify Docker builds complete successfully
- Ensure trivy-results directory is created

### Rollback Plan

If needed, you can temporarily re-enable the old workflow:

```bash
# Re-enable old workflow
mv .github/workflows/security-issues.yml.disabled .github/workflows/security-issues.yml

# Disable new workflow
mv .github/workflows/security-advisories.yml .github/workflows/security-advisories.yml.disabled
```

## ✅ Migration Checklist

- [ ] New security-advisories.yml workflow created
- [ ] Old security-issues.yml workflow disabled
- [ ] Test run of new workflow completed successfully
- [ ] Security tab shows vulnerability findings
- [ ] Workflow artifacts are generated correctly
- [ ] Team notified of the change
- [ ] Documentation updated
- [ ] Optional: Existing security issues cleaned up

## 🚀 Next Steps

After successful migration:

1. **Monitor Results**: Review weekly security scan summaries
2. **Team Training**: Familiarize team with Security tab features
3. **Process Updates**: Update security response procedures
4. **Integration**: Consider additional GitHub security features

## 📞 Support

If you encounter issues during migration:

1. Check workflow run logs for detailed error messages
2. Verify GitHub permissions for security-events and actions
3. Review the Security Advisory Workflow documentation
4. Test with manual workflow dispatch before relying on scheduled runs

---

**Migration Complete**: Your security workflow now uses GitHub's native security features for better organization and tracking! 🎉
