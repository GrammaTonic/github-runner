#!/bin/bash
set -euo pipefail

# Security Issues Cleanup Script
# Closes all automated security issues and migrates to Security Advisory workflow

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if GitHub CLI is available
if ! command -v gh >/dev/null 2>&1; then
    log_error "GitHub CLI (gh) is required but not installed."
    exit 1
fi

# Configuration
DRY_RUN="${1:-false}"
BATCH_SIZE=50
CLOSE_MESSAGE="🔄 **Security Workflow Migration**

This automated security issue is being closed as part of our migration to GitHub's native Security Advisory workflow.

**New Security Management**:
- Security findings are now available in the **Security** tab
- Comprehensive vulnerability reports are generated as workflow artifacts
- No more issue spam - clean project management

**Where to find security information**:
- Navigate to **Security** → **Code scanning** for current findings
- Check weekly security workflow artifacts for detailed reports
- Security advisories are managed through GitHub's Security tab

Thank you for your understanding as we improve our security management process!"

log_info "Security Issues Cleanup Script"
log_info "=============================="

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "DRY RUN MODE - No issues will be closed"
fi

# Get total count of security issues - use a simpler approach
log_info "Counting open security issues..."
ISSUE_COUNT_OUTPUT=$(gh issue list --label security --state open --limit 1000 2>/dev/null | head -1)
if [[ "$ISSUE_COUNT_OUTPUT" =~ Showing\ ([0-9]+)\ of\ ([0-9]+) ]]; then
    TOTAL_ISSUES=${BASH_REMATCH[2]}
else
    # Fallback: try to get actual count via JSON
    JSON_OUTPUT=$(gh issue list --label security --state open --limit 1000 --json number 2>/dev/null || echo "[]")
    TOTAL_ISSUES=$(echo "$JSON_OUTPUT" | jq '. | length' 2>/dev/null || echo "0")
fi

log_info "Found $TOTAL_ISSUES open security issues to process"

if [[ $TOTAL_ISSUES -eq 0 ]]; then
    log_success "No security issues found to close"
    exit 0
fi

# Process issues in batches
PROCESSED=0
while [[ $PROCESSED -lt $TOTAL_ISSUES ]]; do
    log_info "Processing batch starting at issue $((PROCESSED + 1))..."
    
    # Get next batch of issue numbers
    ISSUE_NUMBERS=$(gh issue list --label security --state open --limit $BATCH_SIZE --json number --jq '.[].number')
    
    if [[ -z "$ISSUE_NUMBERS" ]]; then
        log_info "No more issues to process"
        break
    fi
    
    # Close each issue in the batch
    for ISSUE_NUMBER in $ISSUE_NUMBERS; do
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "Would close issue #$ISSUE_NUMBER"
        else
            log_info "Closing issue #$ISSUE_NUMBER..."
            if gh issue close "$ISSUE_NUMBER" --comment "$CLOSE_MESSAGE" >/dev/null 2>&1; then
                log_success "Closed issue #$ISSUE_NUMBER"
            else
                log_error "Failed to close issue #$ISSUE_NUMBER"
            fi
        fi
        PROCESSED=$((PROCESSED + 1))
    done
    
    # Add a small delay to be respectful to GitHub API
    if [[ "$DRY_RUN" != "true" ]]; then
        sleep 2
    fi
done

log_success "Processed $PROCESSED security issues"

if [[ "$DRY_RUN" != "true" ]]; then
    log_info "Cleanup completed! Security findings are now managed through:"
    log_info "  • GitHub Security tab → Code scanning"
    log_info "  • Weekly security workflow artifacts"
    log_info "  • Security advisories (when applicable)"
else
    log_warning "This was a dry run. To actually close issues, run:"
    log_warning "  ./scripts/cleanup-security-issues.sh false"
fi
