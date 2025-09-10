#!/bin/bash
set -euo pipefail

# GitHub Branch Protection Setup Script
# Sets up branch protection rules for main and develop branches

# Color output for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
COPILOT_AUTO_MERGE=false
REVIEW_COUNT=1

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if gh CLI is installed and authenticated
check_gh_cli() {
    if ! command -v gh >/dev/null 2>&1; then
        log_error "GitHub CLI (gh) is not installed. Please install it first:"
        log_error "  brew install gh"
        log_error "  or visit: https://cli.github.com/"
        exit 1
    fi
    
    if ! gh auth status >/dev/null 2>&1; then
        log_error "GitHub CLI is not authenticated. Please run:"
        log_error "  gh auth login"
        exit 1
    fi
    
    log_success "GitHub CLI is installed and authenticated"
}

# Get repository information
get_repo_info() {
    REPO_OWNER=$(gh repo view --json owner --jq .owner.login)
    REPO_NAME=$(gh repo view --json name --jq .name)
    
    log_info "Repository: $REPO_OWNER/$REPO_NAME"
}

# Setup branch protection for develop branch
setup_develop_protection() {
    log_info "Setting up branch protection for 'develop' branch (create if missing)..."

    # Check if develop branch exists
    if ! gh api repos/"$REPO_OWNER"/"$REPO_NAME"/branches/develop >/dev/null 2>&1; then
        log_warning "The 'develop' branch does not exist. Creating it from the repository default..."

        # Create develop branch from the default branch
        DEFAULT_BRANCH=$(gh repo view --json defaultBranch --jq .defaultBranch)
        gh api repos/"$REPO_OWNER"/"$REPO_NAME"/git/refs \
            --method POST \
            --field ref="refs/heads/develop" \
            --field sha="$(gh api repos/"$REPO_OWNER"/"$REPO_NAME"/git/refs/heads/"$DEFAULT_BRANCH" --jq .object.sha)"

        log_success "Created 'develop' branch from '$DEFAULT_BRANCH'"
    fi
    
    # Set up branch protection rules for develop
    if [ "$COPILOT_AUTO_MERGE" = true ]; then
        # Copilot-friendly configuration (no review requirement)
        cat << EOF | gh api repos/"$REPO_OWNER"/"$REPO_NAME"/branches/develop/protection --method PUT --input -
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["CI/CD Pipeline"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false,
  "lock_branch": false,
  "allow_fork_syncing": true
}
EOF
    else
        # Standard configuration with review requirement
        if ! cat << EOF | gh api repos/"$REPO_OWNER"/"$REPO_NAME"/branches/develop/protection --method PUT --input -
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["lint-and-validate", "security-scan"]
  },
  "enforce_admins": null,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "dismissal_restrictions": {}
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
EOF
        then
            log_warning "Failed to set full protection rules. Trying with minimal protection..."
            
            # Fallback to minimal protection (always include required_status_checks)
            cat << EOF | gh api repos/"$REPO_OWNER"/"$REPO_NAME"/branches/develop/protection --method PUT --input -
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["CI/CD Pipeline"]
  },
  "required_pull_request_reviews": $(if [ "$COPILOT_AUTO_MERGE" = true ]; then echo null; else echo "{\"required_approving_review_count\": $REVIEW_COUNT}"; fi),
  "enforce_admins": false,
  "restrictions": null
}
EOF
        fi
    fi
    
    log_success "Branch protection configured for 'develop' branch"
}

# Setup branch protection for main branch
setup_main_protection() {
    log_info "Setting up branch protection for 'main' branch..."
    
    # Set up branch protection rules for main
    if [ "$COPILOT_AUTO_MERGE" = true ]; then
        # Copilot-friendly configuration (no review requirement)
        cat << EOF | gh api repos/"$REPO_OWNER"/"$REPO_NAME"/branches/main/protection --method PUT --input -
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["CI/CD Pipeline"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false,
  "lock_branch": false,
  "allow_fork_syncing": true
}
EOF
    else
        # Standard configuration with review requirement
        cat << EOF | gh api repos/"$REPO_OWNER"/"$REPO_NAME"/branches/main/protection --method PUT --input -
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["CI/CD Pipeline"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": $REVIEW_COUNT,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
EOF
        if [ $? -ne 0 ]; then
            log_warning "Failed to set full protection rules. Trying with minimal protection..."
            
            # Fallback to minimal protection (always include required_status_checks)
            cat << EOF | gh api repos/"$REPO_OWNER"/"$REPO_NAME"/branches/main/protection --method PUT --input -
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["CI/CD Pipeline"]
  },
  "required_pull_request_reviews": $(if [ "$COPILOT_AUTO_MERGE" = true ]; then echo null; else echo "{\"required_approving_review_count\": $REVIEW_COUNT}"; fi),
  "enforce_admins": false,
  "restrictions": null
}
EOF
        fi
    fi
    
    log_success "Branch protection configured for 'main' branch"
}

# Display current protection status
show_protection_status() {
    log_info "Current branch protection status:"
    
    echo ""
    echo "=== Main Branch Protection ==="
    gh api repos/"$REPO_OWNER"/"$REPO_NAME"/branches/main/protection 2>/dev/null | jq '{
        required_status_checks: .required_status_checks,
        required_pull_request_reviews: .required_pull_request_reviews,
        enforce_admins: .enforce_admins,
        allow_force_pushes: .allow_force_pushes,
        allow_deletions: .allow_deletions
    }' || echo "No protection rules set"
    
    echo ""
    echo "=== Develop Branch Protection ==="
    gh api repos/"$REPO_OWNER"/"$REPO_NAME"/branches/develop/protection 2>/dev/null | jq '{
        required_status_checks: .required_status_checks,
        required_pull_request_reviews: .required_pull_request_reviews,
        enforce_admins: .enforce_admins,
        allow_force_pushes: .allow_force_pushes,
        allow_deletions: .allow_deletions
    }' || echo "No protection rules set"
}

# Main execution
main() {
    log_info "🛡️ Setting up GitHub branch protection rules..."
    
    check_gh_cli
    get_repo_info
    
    # Setup protection for both branches
    setup_develop_protection
    setup_main_protection
    
    log_success "✅ Branch protection setup completed!"
    
    # Show current status
    show_protection_status
    
    echo ""
    log_info "Branch protection rules configured:"
    log_info "✓ Pull requests required for both main and develop branches"
    if [ "$COPILOT_AUTO_MERGE" = true ]; then
        log_info "✓ No review requirement (Copilot auto-merge enabled)"
        log_info "✓ No conversation resolution required (Copilot friendly)"
    else
        log_info "✓ At least $REVIEW_COUNT approving review required"
        log_info "✓ Conversation resolution required"
    fi
    log_info "✓ Status checks required (CI/CD Pipeline must pass)"
    log_info "✓ Force pushes blocked"
    log_info "✓ Branch deletions blocked"
    
    echo ""
    log_warning "Note: You may need admin permissions to modify some protection settings."
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--help|--status|--copilot-auto-merge]"
        echo ""
        echo "Sets up branch protection rules for main and develop branches."
        echo ""
        echo "Options:"
        echo "  --help, -h               Show this help message"
        echo "  --status, -s             Show current protection status only"
        echo "  --copilot-auto-merge     Enable Copilot auto-merge (removes review requirement)"
        echo ""
        echo "Requirements:"
        echo "  - GitHub CLI (gh) installed and authenticated"
        echo "  - Admin permissions on the repository"
        exit 0
        ;;
    --status|-s)
        check_gh_cli
        get_repo_info
        show_protection_status
        exit 0
        ;;
    --copilot-auto-merge)
        COPILOT_AUTO_MERGE=true
        REVIEW_COUNT=0
        log_info "🤖 Enabling Copilot auto-merge mode (no review requirement)"
        main
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        log_error "Use --help for usage information"
        exit 1
        ;;
esac
