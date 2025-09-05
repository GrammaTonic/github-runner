#!/bin/bash
set -euo pipefail

# Simple Security Issues Cleanup Script
# Closes automated security issues in batches

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check requirements
if ! command -v gh >/dev/null 2>&1; then
    log_error "GitHub CLI (gh) is required but not installed."
    exit 1
fi

# Configuration
DRY_RUN="${1:-true}"
BATCH_SIZE=20

CLOSE_MESSAGE="🔄 **Security Workflow Migration**

This automated security issue is being closed as part of our migration to GitHub's native Security Advisory workflow.

**New Security Management**:
- Security findings are now in the **Security** tab
- Vulnerability reports are generated as workflow artifacts  
- Clean project management without issue spam

**Find security information**:
- **Security** → **Code scanning** for current findings
- Weekly security workflow artifacts for detailed reports

Thanks for your understanding as we improve our security process!"

log_info "Security Issues Cleanup"
log_info "======================="

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "DRY RUN MODE - No issues will be closed"
    log_info "Run with 'false' parameter to actually close issues"
fi

# Function to get security issue numbers
get_security_issues() {
    gh issue list --label security --state open --limit "$BATCH_SIZE" --json number --jq '.[].number' 2>/dev/null || true
}

# Main processing loop
TOTAL_PROCESSED=0
while true; do
    log_info "Fetching next batch of security issues..."
    
    ISSUE_NUMBERS=$(get_security_issues)
    
    if [[ -z "$ISSUE_NUMBERS" ]]; then
        log_info "No more open security issues found"
        break
    fi
    
    BATCH_COUNT=$(echo "$ISSUE_NUMBERS" | wc -l | tr -d ' ')
    log_info "Processing $BATCH_COUNT issues in this batch"
    
    for ISSUE_NUMBER in $ISSUE_NUMBERS; do
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "Would close issue #$ISSUE_NUMBER"
        else
            log_info "Closing issue #$ISSUE_NUMBER..."
            if gh issue close "$ISSUE_NUMBER" --comment "$CLOSE_MESSAGE" >/dev/null 2>&1; then
                log_success "✓ Closed issue #$ISSUE_NUMBER"
            else
                log_error "✗ Failed to close issue #$ISSUE_NUMBER"
            fi
        fi
        TOTAL_PROCESSED=$((TOTAL_PROCESSED + 1))
    done
    
    # Rate limiting
    if [[ "$DRY_RUN" != "true" ]]; then
        log_info "Waiting 3 seconds for rate limiting..."
        sleep 3
    fi
    
    # Safety break for dry run
    if [[ "$DRY_RUN" == "true" && "$TOTAL_PROCESSED" -ge 100 ]]; then
        log_warning "Dry run stopped after 100 issues (showing sample)"
        break
    fi
done

log_success "Processed $TOTAL_PROCESSED security issues"

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "This was a dry run. To close issues run:"
    log_warning "  ./scripts/cleanup-security-issues-simple.sh false"
else
    log_success "Security issues cleanup completed!"
    log_info "Security findings are now managed through:"
    log_info "  • GitHub Security tab → Code scanning"
    log_info "  • Weekly security workflow artifacts"
fi
