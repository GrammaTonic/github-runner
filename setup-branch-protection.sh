#!/bin/bash
set -euo pipefail

# GitHub Repository Branch Protection Setup Script
# This script configures branch protection rules for the github-runner repository
# following security best practices and CI/CD workflow requirements

# Configuration
REPO_OWNER="GrammaTonic"
REPO_NAME="github-runner"
GITHUB_API_URL="https://api.github.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if GitHub CLI is installed and authenticated
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed. Please install it first:"
        log_info "  brew install gh  # macOS"
        log_info "  See https://cli.github.com/ for other platforms"
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated. Please run:"
        log_info "  gh auth login"
        exit 1
    fi

    log_success "GitHub CLI is installed and authenticated"
}

# Function to create branch protection rule
create_branch_protection() {
    local branch_name="$1"
    local protection_config="$2"
    
    log_info "Setting up branch protection for: $branch_name"
    
    # Use GitHub CLI to set branch protection
    if gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/$REPO_OWNER/$REPO_NAME/branches/$branch_name/protection" \
        --input - <<< "$protection_config"; then
        log_success "Branch protection configured for $branch_name"
    else
        log_error "Failed to configure branch protection for $branch_name"
        return 1
    fi
}

# Main branch protection configuration
setup_main_branch_protection() {
    log_info "Configuring protection for main branch..."
    
    local main_protection='{
        "required_status_checks": {
            "strict": true,
            "checks": [
                {"context": "Lint and Validate"},
                {"context": "Security Scanning"},
                {"context": "Build Docker Images"},
                {"context": "Test Runner Configuration (unit)"},
                {"context": "Test Runner Configuration (integration)"},
                {"context": "Test Runner Configuration (config)"},
                {"context": "Container Security Scan"}
            ]
        },
        "enforce_admins": true,
        "required_pull_request_reviews": {
            "required_approving_review_count": 1,
            "dismiss_stale_reviews": true,
            "require_code_owner_reviews": true,
            "require_last_push_approval": true
        },
        "restrictions": null,
        "required_linear_history": true,
        "allow_force_pushes": false,
        "allow_deletions": false,
        "block_creations": false,
        "required_conversation_resolution": true,
        "lock_branch": false,
        "allow_fork_syncing": true
    }'
    
    create_branch_protection "main" "$main_protection"
}

# Develop branch protection configuration
setup_develop_branch_protection() {
    log_info "Configuring protection for develop branch..."
    
    local develop_protection='{
        "required_status_checks": {
            "strict": true,
            "checks": [
                {"context": "Lint and Validate"},
                {"context": "Security Scanning"},
                {"context": "Build Docker Images"},
                {"context": "Test Runner Configuration (unit)"},
                {"context": "Test Runner Configuration (integration)"}
            ]
        },
        "enforce_admins": false,
        "required_pull_request_reviews": {
            "required_approving_review_count": 1,
            "dismiss_stale_reviews": true,
            "require_code_owner_reviews": false,
            "require_last_push_approval": false
        },
        "restrictions": null,
        "required_linear_history": false,
        "allow_force_pushes": false,
        "allow_deletions": false,
        "block_creations": false,
        "required_conversation_resolution": true,
        "lock_branch": false,
        "allow_fork_syncing": true
    }'
    
    create_branch_protection "develop" "$develop_protection"
}

# Create CODEOWNERS file for required code reviews
setup_codeowners() {
    log_info "Setting up CODEOWNERS file..."
    
    cat > .github/CODEOWNERS << 'EOF'
# GitHub Runner Repository Code Owners
# These users will be automatically requested for review when someone opens a pull request

# Global ownership - all files require review from repository maintainers
* @GrammaTonic

# CI/CD Workflows require DevOps team review
/.github/workflows/ @GrammaTonic
/.github/instructions/ @GrammaTonic

# Docker and deployment files require infrastructure team review
/docker/ @GrammaTonic
/scripts/ @GrammaTonic
/config/ @GrammaTonic

# Security-related files require security team review
/security/ @GrammaTonic
*.security.yml @GrammaTonic

# Documentation requires technical writing review
*.md @GrammaTonic
/docs/ @GrammaTonic
EOF

    log_success "CODEOWNERS file created"
}

# Create branch protection bypass script for emergencies
create_emergency_bypass_script() {
    log_info "Creating emergency bypass script..."
    
    cat > scripts/emergency-bypass.sh << 'EOF'
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

# Backup current protection settings
echo "Backing up current protection settings..."
gh api "/repos/$REPO_OWNER/$REPO_NAME/branches/main/protection" > .emergency-backup-main.json
gh api "/repos/$REPO_OWNER/$REPO_NAME/branches/develop/protection" > .emergency-backup-develop.json

# Disable protection temporarily
echo "Disabling branch protection..."
gh api --method DELETE "/repos/$REPO_OWNER/$REPO_NAME/branches/main/protection"
gh api --method DELETE "/repos/$REPO_OWNER/$REPO_NAME/branches/develop/protection"

echo "✅ Branch protection disabled"
echo "⚠️  REMEMBER TO RE-ENABLE PROTECTION AFTER EMERGENCY FIX"
echo "⚠️  Run: ./scripts/restore-branch-protection.sh"

# Log emergency action
cat >> .emergency-log.txt << EOL
[$TIMESTAMP] EMERGENCY BYPASS: $REASON (User: $(gh api user --jq .login))
EOL
EOF

    chmod +x scripts/emergency-bypass.sh
    log_success "Emergency bypass script created"
}

# Create protection restoration script
create_restore_protection_script() {
    log_info "Creating protection restoration script..."
    
    cat > scripts/restore-branch-protection.sh << 'EOF'
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
EOF

    chmod +x scripts/restore-branch-protection.sh
    log_success "Protection restoration script created"
}

# Set up repository security settings
setup_repository_security() {
    log_info "Configuring repository security settings..."
    
    # Enable vulnerability alerts
    gh api --method PUT "/repos/$REPO_OWNER/$REPO_NAME/vulnerability-alerts" || log_warning "Could not enable vulnerability alerts"
    
    # Enable dependency graph
    gh api --method PUT "/repos/$REPO_OWNER/$REPO_NAME/automated-security-fixes" || log_warning "Could not enable automated security fixes"
    
    # Configure repository security settings
    local security_config='{
        "security_and_analysis": {
            "secret_scanning": {
                "status": "enabled"
            },
            "secret_scanning_push_protection": {
                "status": "enabled"
            }
        }
    }'
    
    gh api --method PATCH "/repos/$REPO_OWNER/$REPO_NAME" \
        --input - <<< "$security_config" || log_warning "Could not configure some security settings"
    
    log_success "Repository security settings configured"
}

# Set up GitHub Environments
setup_environments() {
    log_info "Setting up GitHub Environments..."
    
    # Staging environment
    local staging_config='{
        "wait_timer": 0,
        "reviewers": [],
        "deployment_branch_policy": {
            "protected_branches": false,
            "custom_branch_policies": true
        }
    }'
    
    gh api --method PUT "/repos/$REPO_OWNER/$REPO_NAME/environments/staging" \
        --input - <<< "$staging_config" || log_warning "Could not create staging environment"
    
    # Production environment with required reviewers
    local production_config='{
        "wait_timer": 5,
        "reviewers": [
            {
                "type": "User",
                "id": null
            }
        ],
        "deployment_branch_policy": {
            "protected_branches": true,
            "custom_branch_policies": false
        }
    }'
    
    gh api --method PUT "/repos/$REPO_OWNER/$REPO_NAME/environments/production" \
        --input - <<< "$production_config" || log_warning "Could not create production environment"
    
    log_success "GitHub Environments configured"
}

# Validate setup
validate_setup() {
    log_info "Validating branch protection setup..."
    
    # Check main branch protection
    if gh api "/repos/$REPO_OWNER/$REPO_NAME/branches/main/protection" &> /dev/null; then
        log_success "Main branch protection is active"
    else
        log_error "Main branch protection validation failed"
        return 1
    fi
    
    # Check develop branch protection
    if gh api "/repos/$REPO_OWNER/$REPO_NAME/branches/develop/protection" &> /dev/null; then
        log_success "Develop branch protection is active"
    else
        log_error "Develop branch protection validation failed"
        return 1
    fi
    
    # Check CODEOWNERS file
    if [[ -f .github/CODEOWNERS ]]; then
        log_success "CODEOWNERS file exists"
    else
        log_warning "CODEOWNERS file not found"
    fi
    
    log_success "Branch protection setup validation completed"
}

# Display setup summary
show_summary() {
    echo ""
    log_info "=== Branch Protection Setup Summary ==="
    echo ""
    echo "📋 Configured Branches:"
    echo "  • main: Full protection with 1 required reviewer"
    echo "  • develop: Basic protection with 1 required reviewer"
    echo ""
    echo "🔒 Security Features:"
    echo "  • Required status checks from CI/CD workflows"
    echo "  • Required pull request reviews"
    echo "  • Code owner reviews required (main branch)"
    echo "  • Dismiss stale reviews"
    echo "  • Required conversation resolution"
    echo "  • Linear history required (main branch)"
    echo "  • Force pushes blocked"
    echo "  • Branch deletions blocked"
    echo ""
    echo "🏗️ Environments:"
    echo "  • staging: Automatic deployment for develop/main"
    echo "  • production: Manual approval required"
    echo ""
    echo "🚨 Emergency Tools:"
    echo "  • scripts/emergency-bypass.sh - Temporary protection bypass"
    echo "  • scripts/restore-branch-protection.sh - Restore protection"
    echo ""
    echo "📝 Next Steps:"
    echo "  1. Review and adjust protection settings if needed"
    echo "  2. Add team members to repository"
    echo "  3. Update CODEOWNERS with appropriate reviewers"
    echo "  4. Test the CI/CD workflows"
    echo "  5. Configure environment secrets for deployments"
    echo ""
}

# Main execution
main() {
    log_info "Starting GitHub Runner Repository Branch Protection Setup"
    echo ""
    
    # Create scripts directory if it doesn't exist
    mkdir -p scripts
    
    # Check prerequisites
    check_gh_cli
    
    # Setup branch protection
    setup_main_branch_protection
    setup_develop_branch_protection
    
    # Setup supporting files and scripts
    setup_codeowners
    create_emergency_bypass_script
    create_restore_protection_script
    
    # Configure repository security
    setup_repository_security
    setup_environments
    
    # Validate everything is working
    validate_setup
    
    # Show summary
    show_summary
    
    log_success "Branch protection setup completed successfully!"
}

# Run main function
main "$@"
