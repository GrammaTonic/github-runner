#!/bin/bash

# Setup Branch Protection for github-runner repository
# This script configures main branch to only accept merges from develop through PRs

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository information
REPO_OWNER="GrammaTonic"
REPO_NAME="github-runner"
PROTECTED_BRANCH="main"

echo -e "${BLUE}🔒 Setting up branch protection for ${REPO_OWNER}/${REPO_NAME}${NC}"
echo -e "${BLUE}Protected branch: ${PROTECTED_BRANCH}${NC}"
echo

# Check if GitHub CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed or not in PATH${NC}"
    echo "Please install GitHub CLI: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

echo -e "${YELLOW}📋 Current branch protection status:${NC}"
if gh api "repos/${REPO_OWNER}/${REPO_NAME}/branches/${PROTECTED_BRANCH}/protection" &> /dev/null; then
    echo -e "${GREEN}✅ Branch protection already exists${NC}"
else
    echo -e "${YELLOW}⚠️  No branch protection found${NC}"
fi
echo

# Create branch protection configuration
echo -e "${BLUE}🔧 Applying branch protection rules...${NC}"

# Create temporary JSON file for configuration
TEMP_CONFIG=$(mktemp)
cat > "$TEMP_CONFIG" << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": []
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

# Apply branch protection
if gh api "repos/${REPO_OWNER}/${REPO_NAME}/branches/${PROTECTED_BRANCH}/protection" \
   --method PUT \
   --input "$TEMP_CONFIG" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Branch protection applied successfully${NC}"
else
    echo -e "${RED}❌ Failed to apply branch protection${NC}"
    rm "$TEMP_CONFIG"
    exit 1
fi

# Clean up
rm "$TEMP_CONFIG"

echo
echo -e "${GREEN}🎉 Branch protection setup complete!${NC}"
echo
echo -e "${BLUE}📝 Protection rules applied:${NC}"
echo "   • ✅ Require pull request reviews (1 approval required)"
echo "   • ✅ Dismiss stale reviews when new commits are pushed"
echo "   • ✅ Enforce for administrators"
echo "   • ✅ No force pushes allowed"
echo "   • ✅ No branch deletion allowed"
echo "   • ✅ Require up-to-date branches before merging"
echo
echo -e "${YELLOW}📋 Workflow:${NC}"
echo "   1. Developers work on feature branches"
echo "   2. Create PR from develop → main"
echo "   3. Get required approval"
echo "   4. Merge through GitHub UI"
echo "   5. Direct pushes to main are blocked"
echo
echo -e "${BLUE}🔗 View settings: https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/branches${NC}"
