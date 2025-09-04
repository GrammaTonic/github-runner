#!/bin/bash
# Restore Branch Protection Script
# Restores branch protection after emergency bypass

set -euo pipefail

REPO_OWNER="GrammaTonic"
REPO_NAME="github-runner"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

echo "🔄 Restoring branch protection..."

if [[ -f .emergency-backup-main.json ]]; then
    echo "Restoring main branch protection..."
    gh api --method PUT "/repos/$REPO_OWNER/$REPO_NAME/branches/main/protection" \
        --input .emergency-backup-main.json
    rm .emergency-backup-main.json
fi

if [[ -f .emergency-backup-develop.json ]]; then
    echo "Restoring develop branch protection..."
    gh api --method PUT "/repos/$REPO_OWNER/$REPO_NAME/branches/develop/protection" \
        --input .emergency-backup-develop.json
    rm .emergency-backup-develop.json
fi

echo "✅ Branch protection restored"

# Log restoration
cat >> .emergency-log.txt << EOL
[$TIMESTAMP] PROTECTION RESTORED (User: $(gh api user --jq .login))
EOL
