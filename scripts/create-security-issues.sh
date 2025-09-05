#!/bin/bash
set -euo pipefail

# Trivy Security Issue Creator
# Parses Trivy scan results and creates GitHub issues for vulnerabilities

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_OWNER="${GITHUB_REPOSITORY_OWNER:-GrammaTonic}"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-github-runner}"
TRIVY_RESULTS_DIR="${TRIVY_RESULTS_DIR:-./trivy-results}"
MIN_SEVERITY="${MIN_SEVERITY:-MEDIUM}"
DRY_RUN="${DRY_RUN:-false}"

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

# Check requirements
check_requirements() {
    local missing_tools=()
    
    if ! command -v gh >/dev/null 2>&1; then
        missing_tools+=("gh (GitHub CLI)")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_tools+=("jq")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        echo "Install with:"
        echo "  - GitHub CLI: https://cli.github.com/"
        echo "  - jq: https://stedolan.github.io/jq/"
        exit 1
    fi
}

# Convert severity to priority
severity_to_priority() {
    local severity="$1"
    case "$severity" in
        "CRITICAL") echo "P0 - Critical (Fix immediately)" ;;
        "HIGH") echo "P1 - High (Fix within 1 week)" ;;
        "MEDIUM") echo "P2 - Medium (Fix within 1 month)" ;;
        "LOW"|"UNKNOWN") echo "P3 - Low (Fix when convenient)" ;;
        *) echo "P2 - Medium (Fix within 1 month)" ;;
    esac
}

# Check if issue already exists
issue_exists() {
    local cve_id="$1"
    local package="$2"
    
    # Search for existing issues with the CVE ID or package vulnerability
    if [[ -n "$cve_id" && "$cve_id" != "null" ]]; then
        gh issue list --repo "$REPO_OWNER/$REPO_NAME" --search "$cve_id in:title" --json number --jq 'length' 2>/dev/null || echo "0"
    else
        gh issue list --repo "$REPO_OWNER/$REPO_NAME" --search "$package vulnerability" --json number --jq 'length' 2>/dev/null || echo "0"
    fi
}

# Create security issue from vulnerability data
create_security_issue() {
    local vuln_data="$1"
    local scan_target="$2"
    
    # Extract vulnerability details
    local cve_id
    local severity
    local pkg_name
    local installed_version
    local fixed_version
    local title
    local description
    
    cve_id=$(echo "$vuln_data" | jq -r '.VulnerabilityID // "N/A"')
    severity=$(echo "$vuln_data" | jq -r '.Severity // "UNKNOWN"')
    pkg_name=$(echo "$vuln_data" | jq -r '.PkgName // "unknown"')
    installed_version=$(echo "$vuln_data" | jq -r '.InstalledVersion // "unknown"')
    fixed_version=$(echo "$vuln_data" | jq -r '.FixedVersion // "N/A"')
    title=$(echo "$vuln_data" | jq -r '.Title // "Unknown vulnerability"')
    description=$(echo "$vuln_data" | jq -r '.Description // "No description available"')
    
    # Skip if below minimum severity
    case "$severity" in
        "CRITICAL") severity_num=4 ;;
        "HIGH") severity_num=3 ;;
        "MEDIUM") severity_num=2 ;;
        "LOW") severity_num=1 ;;
        *) severity_num=0 ;;
    esac
    
    case "$MIN_SEVERITY" in
        "CRITICAL") min_severity_num=4 ;;
        "HIGH") min_severity_num=3 ;;
        "MEDIUM") min_severity_num=2 ;;
        "LOW") min_severity_num=1 ;;
        *) min_severity_num=0 ;;
    esac
    
    if [[ $severity_num -lt $min_severity_num ]]; then
        log_info "Skipping $cve_id ($severity) - below minimum severity threshold"
        return 0
    fi
    
    # Check if issue already exists
    local existing_count
    existing_count=$(issue_exists "$cve_id" "$pkg_name")
    if [[ "$existing_count" -gt 0 ]]; then
        log_warning "Issue for $cve_id already exists, skipping"
        return 0
    fi
    
    # Create issue title
    local issue_title="[Security]: $severity vulnerability in $pkg_name"
    if [[ "$cve_id" != "N/A" && "$cve_id" != "null" ]]; then
        issue_title="[Security]: $cve_id - $severity vulnerability in $pkg_name"
    fi
    
    # Create issue body
    local priority
    priority=$(severity_to_priority "$severity")
    local issue_body="## 🔒 Security Vulnerability Report

**Severity:** $severity  
**Package:** $pkg_name  
**Current Version:** $installed_version  
**Fixed Version:** $fixed_version  
**Scan Target:** $scan_target  
**CVE ID:** $cve_id  

### Description
$description

### Vulnerability Details
$title

### Remediation
"
    
    if [[ "$fixed_version" != "N/A" && "$fixed_version" != "null" ]]; then
        issue_body+="Update $pkg_name from version $installed_version to $fixed_version or later."
    else
        issue_body+="No fix available yet. Monitor for updates to $pkg_name."
    fi
    
    issue_body+="

### Trivy Scan Output
\`\`\`
Package: $pkg_name
Installed Version: $installed_version
Fixed Version: $fixed_version
Severity: $severity
CVE ID: $cve_id
Title: $title
\`\`\`

### Priority
$priority

---
*This issue was automatically created from Trivy security scan results.*
*Scan Target: $scan_target*
*Scan Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')*"
    
    # Create the issue
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would create issue:"
        echo "Title: $issue_title"
        echo "Labels: security,vulnerability,trivy,$severity"
        echo "Body length: ${#issue_body} characters"
        echo ""
    else
        log_info "Creating issue for $cve_id ($severity)"
        
        local labels
        labels="security,vulnerability,trivy,$(echo "$severity" | tr '[:upper:]' '[:lower:]')"
        
        if gh issue create \
            --repo "$REPO_OWNER/$REPO_NAME" \
            --title "$issue_title" \
            --body "$issue_body" \
            --label "$labels" >/dev/null 2>&1; then
            log_success "Created issue for $cve_id"
        else
            log_error "Failed to create issue for $cve_id"
        fi
    fi
}

# Process Trivy JSON results
process_trivy_json() {
    local json_file="$1"
    local scan_target="$2"
    
    if [[ ! -f "$json_file" ]]; then
        log_warning "Trivy results file not found: $json_file"
        return 1
    fi
    
    log_info "Processing Trivy results from: $json_file"
    log_info "Scan target: $scan_target"
    
    # Extract vulnerabilities from JSON
    local vuln_count
    vuln_count=$(jq -r '[.Results[]?.Vulnerabilities[]?] | length' "$json_file" 2>/dev/null || echo "0")
    
    if [[ "$vuln_count" -eq 0 ]]; then
        log_success "No vulnerabilities found in $json_file"
        return 0
    fi
    
    log_info "Found $vuln_count vulnerabilities in $json_file"
    
    # Process each vulnerability
    jq -c '.Results[]?.Vulnerabilities[]?' "$json_file" 2>/dev/null | while read -r vuln_data; do
        if [[ -n "$vuln_data" ]]; then
            create_security_issue "$vuln_data" "$scan_target"
        fi
    done
}

# Main function
main() {
    log_info "Trivy Security Issue Creator"
    log_info "Repository: $REPO_OWNER/$REPO_NAME"
    log_info "Minimum Severity: $MIN_SEVERITY"
    log_info "Dry Run: $DRY_RUN"
    echo ""
    
    check_requirements
    
    # Process different scan result files
    local processed_files=0
    
    # Filesystem scan results
    if [[ -f "$TRIVY_RESULTS_DIR/trivy-results.json" ]]; then
        process_trivy_json "$TRIVY_RESULTS_DIR/trivy-results.json" "Filesystem scan"
        ((processed_files++))
    fi
    
    # Container scan results
    if [[ -f "$TRIVY_RESULTS_DIR/trivy-container-results.json" ]]; then
        process_trivy_json "$TRIVY_RESULTS_DIR/trivy-container-results.json" "Standard Runner Container"
        ((processed_files++))
    fi
    
    # Chrome container scan results
    if [[ -f "$TRIVY_RESULTS_DIR/trivy-chrome-results.json" ]]; then
        process_trivy_json "$TRIVY_RESULTS_DIR/trivy-chrome-results.json" "Chrome Runner Container"
        ((processed_files++))
    fi
    
    # Check for any JSON files in the directory
    if [[ $processed_files -eq 0 ]]; then
        log_warning "No Trivy result files found in $TRIVY_RESULTS_DIR"
        echo "Expected files:"
        echo "  - trivy-results.json (filesystem scan)"
        echo "  - trivy-container-results.json (container scan)"
        echo "  - trivy-chrome-results.json (Chrome container scan)"
        echo ""
        echo "You can also specify custom location with TRIVY_RESULTS_DIR env var"
    else
        log_success "Processed $processed_files Trivy result files"
    fi
}

# Show usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Environment Variables:"
    echo "  GITHUB_REPOSITORY_OWNER  Repository owner (default: GrammaTonic)"
    echo "  GITHUB_REPOSITORY_NAME   Repository name (default: github-runner)"
    echo "  TRIVY_RESULTS_DIR        Directory with Trivy JSON results (default: ./trivy-results)"
    echo "  MIN_SEVERITY             Minimum severity to process (default: MEDIUM)"
    echo "  DRY_RUN                  Don't create issues, just show what would be created (default: false)"
    echo ""
    echo "Examples:"
    echo "  # Process results with default settings"
    echo "  $0"
    echo ""
    echo "  # Dry run to see what would be created"
    echo "  DRY_RUN=true $0"
    echo ""
    echo "  # Only process CRITICAL and HIGH severity"
    echo "  MIN_SEVERITY=HIGH $0"
    echo ""
    echo "  # Use custom results directory"
    echo "  TRIVY_RESULTS_DIR=/path/to/results $0"
}

# Handle arguments
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

# Run main function
main "$@"
