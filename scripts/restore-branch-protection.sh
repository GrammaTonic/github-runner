#!/bin/bash
# Restore Branch Protection Script
# Restores branch protection after emergency bypass

set -euo pipefail

REPO_OWNER="GrammaTonic"
REPO_NAME="github-runner"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Look for backup files in secure backup directory
BACKUP_DIR="${BACKUP_DIR:-./emergency-backups}"

echo "🔄 Restoring branch protection..."

if [[ -f "$BACKUP_DIR/.emergency-backup-main.json" ]]; then
    echo "Restoring main branch protection..."
    # Validate backup file contains valid JSON and expected protection structure
    if jq empty "$BACKUP_DIR/.emergency-backup-main.json" 2>/dev/null && \
       [[ "$(jq -r 'type' "$BACKUP_DIR/.emergency-backup-main.json" 2>/dev/null)" == "object" ]] && \
       jq -e '.required_status_checks // .enforce_admins // .restrictions // .required_pull_request_reviews' "$BACKUP_DIR/.emergency-backup-main.json" >/dev/null 2>&1; then
        gh api --method PUT "/repos/$REPO_OWNER/$REPO_NAME/branches/main/protection" \
            --input "$BACKUP_DIR/.emergency-backup-main.json"
        rm "$BACKUP_DIR/.emergency-backup-main.json"
        echo "✅ Main branch protection restored"
    else
        echo "ERROR: Invalid backup file for main branch protection or missing expected configuration"
        echo "Backup file should contain branch protection configuration with required_status_checks, enforce_admins, restrictions, or required_pull_request_reviews"
        exit 1
    fi
fi

if [[ -f "$BACKUP_DIR/.emergency-backup-develop.json" ]]; then
    echo "Restoring develop branch protection..."
    # Validate backup file contains valid JSON and expected protection structure
    if jq empty "$BACKUP_DIR/.emergency-backup-develop.json" 2>/dev/null && \
       [[ "$(jq -r 'type' "$BACKUP_DIR/.emergency-backup-develop.json" 2>/dev/null)" == "object" ]] && \
       jq -e '.required_status_checks // .enforce_admins // .restrictions // .required_pull_request_reviews' "$BACKUP_DIR/.emergency-backup-develop.json" >/dev/null 2>&1; then
        gh api --method PUT "/repos/$REPO_OWNER/$REPO_NAME/branches/develop/protection" \
            --input "$BACKUP_DIR/.emergency-backup-develop.json"
        rm "$BACKUP_DIR/.emergency-backup-develop.json"
        echo "✅ Develop branch protection restored"
    else
        echo "ERROR: Invalid backup file for develop branch protection or missing expected configuration"
        echo "Backup file should contain branch protection configuration with required_status_checks, enforce_admins, restrictions, or required_pull_request_reviews"
        exit 1
    fi
fi

echo "✅ Branch protection restored"

# Log restoration
cat >> .emergency-log.txt << EOL
[$TIMESTAMP] PROTECTION RESTORED (User: $(gh api user --jq .login))
EOL
