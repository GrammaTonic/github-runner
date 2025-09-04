#!/bin/bash
# Emergency Branch Protection Bypass Script
# USE ONLY IN CRITICAL PRODUCTION INCIDENTS
# This script temporarily disables branch protection for emergency fixes

set -euo pipefail

REPO_OWNER="GrammaTonic"
REPO_NAME="github-runner"

# Check if reason is provided
if [[ $# -eq 0 ]]; then
    echo "ERROR: Emergency reason required"
    echo "Usage: $0 'Reason for emergency bypass'"
    echo "Example: $0 'Critical security patch for CVE-2024-XXXX'"
    exit 1
fi

REASON="$1"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

echo "⚠️  EMERGENCY BRANCH PROTECTION BYPASS ⚠️"
echo "Reason: $REASON"
echo "Time: $TIMESTAMP"
echo "User: $(gh api user --jq .login)"

# Create secure backup directory
BACKUP_DIR="${BACKUP_DIR:-./emergency-backups}"
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

# Backup current protection settings
echo "Backing up current protection settings to $BACKUP_DIR..."
gh api "/repos/$REPO_OWNER/$REPO_NAME/branches/main/protection" > "$BACKUP_DIR/.emergency-backup-main.json" || true
gh api "/repos/$REPO_OWNER/$REPO_NAME/branches/develop/protection" > "$BACKUP_DIR/.emergency-backup-develop.json" || true

# Disable protection temporarily
echo "Disabling branch protection..."
gh api --method DELETE "/repos/$REPO_OWNER/$REPO_NAME/branches/main/protection" || true
gh api --method DELETE "/repos/$REPO_OWNER/$REPO_NAME/branches/develop/protection" || true

echo "✅ Branch protection disabled"
echo "⚠️  REMEMBER TO RE-ENABLE PROTECTION AFTER EMERGENCY FIX"
echo "⚠️  Run: ./scripts/restore-branch-protection.sh"

# Log emergency action
cat >> .emergency-log.txt << EOL
[$TIMESTAMP] EMERGENCY BYPASS: $REASON (User: $(gh api user --jq .login))
EOL
