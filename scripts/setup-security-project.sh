#!/bin/bash
set -euo pipefail

# Security Project Setup Script
# Sets up GitHub project for security vulnerability management

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

# Check if GitHub CLI is installed and authenticated
check_gh_cli() {
	if ! command -v gh >/dev/null 2>&1; then
		log_error "GitHub CLI (gh) is not installed"
		echo "Install it from: https://cli.github.com/"
		exit 1
	fi

	if ! gh auth status >/dev/null 2>&1; then
		log_error "GitHub CLI is not authenticated"
		echo "Run: gh auth login"
		exit 1
	fi

	log_success "GitHub CLI is ready"
}

# Create GitHub project
create_project() {
	local repo_owner="${1:-GrammaTonic}"
	local repo_name="${2:-github-runner}"

	log_info "Creating GitHub project for security vulnerability management"

	# Check if project already exists
	if gh project list --owner "$repo_owner" --format json | jq -r '.[].title' | grep -q "Security Vulnerability Management" 2>/dev/null; then
		log_warning "Project 'Security Vulnerability Management' already exists"
		return 0
	fi

	# Create the project
	if gh project create \
		--owner "$repo_owner" \
		--title "Security Vulnerability Management" \
		--body "Track and manage security vulnerabilities found by Trivy scanner" \
		--format json >/tmp/project.json 2>/dev/null; then

		local project_url
		project_url=$(jq -r '.url' /tmp/project.json)
		log_success "Created project: $project_url"

		# Store project number for later use
		local project_number
		project_number=$(jq -r '.number' /tmp/project.json)
		echo "$project_number" >.security-project-number

		return 0
	else
		log_error "Failed to create GitHub project"
		return 1
	fi
}

# Add custom fields to project
add_project_fields() {
	local repo_owner="${1:-GrammaTonic}"
	local project_number

	if [[ -f .security-project-number ]]; then
		project_number=$(cat .security-project-number)
	else
		log_error "Project number not found. Run create_project first."
		return 1
	fi

	log_info "Adding custom fields to project"

	# Note: Custom fields API is still in beta, may need manual setup
	log_warning "Custom fields may need to be added manually in the GitHub UI:"
	echo "  1. Go to your project settings"
	echo "  2. Add these custom fields:"
	echo "     - CVE ID (text)"
	echo "     - Severity (single select: Critical, High, Medium, Low)"
	echo "     - Priority (single select: P0, P1, P2, P3)"
	echo "     - Component (single select: Container, Chrome, Filesystem, Dependencies)"
	echo "     - Discovery Date (date)"
	echo "     - Target Fix Date (date)"
}

# Create project views
create_project_views() {
	log_info "Project views to create manually:"
	echo "  1. Triage View - Filter: label:needs-triage"
	echo "  2. Critical/High Priority - Filter: label:critical,high"
	echo "  3. In Progress - Filter: status:in-progress"
	echo "  4. By Component - Group by: Component field"
}

# Test the security issue creation script
test_security_script() {
	log_info "Testing security issue creation script"

	# Create test directory and dummy results
	mkdir -p trivy-results

	# Create a test Trivy result file
	cat >trivy-results/test-results.json <<'EOF'
{
  "Results": [
    {
      "Target": "test-target",
      "Vulnerabilities": [
        {
          "VulnerabilityID": "CVE-2024-TEST",
          "Severity": "HIGH",
          "PkgName": "test-package",
          "InstalledVersion": "1.0.0",
          "FixedVersion": "1.0.1",
          "Title": "Test vulnerability for demo",
          "Description": "This is a test vulnerability created by the setup script"
        }
      ]
    }
  ]
}
EOF

	log_info "Running security script in dry-run mode"
	DRY_RUN=true ./docs/archive/scripts/create-security-issues.sh || {
		log_error "Security script test failed"
		return 1
	}

	# Clean up test files
	rm -rf trivy-results

	log_success "Security script test completed"
}

# Main setup function
main() {
	echo "🔒 Security Vulnerability Management Project Setup"
	echo "================================================="
	echo ""

	local repo_owner="${1:-GrammaTonic}"
	local repo_name="${2:-github-runner}"

	log_info "Repository: $repo_owner/$repo_name"
	echo ""

	# Run setup steps
	check_gh_cli

	if create_project "$repo_owner" "$repo_name"; then
		add_project_fields "$repo_owner"
		create_project_views
	fi

	echo ""
	test_security_script

	echo ""
	log_success "Security project setup completed!"
	echo ""
	echo "📋 Next Steps:"
	echo "1. Visit your GitHub project to configure custom fields"
	echo "2. Set up project views for better organization"
	echo "3. Run a test scan: gh workflow run security-issues.yml"
	echo "4. Review the security management documentation:"
	echo "   docs/features/security-management-project.md"
	echo ""
	echo "🔧 Manual Commands:"
	echo "# Test security script (dry run)"
	echo "DRY_RUN=true ./docs/archive/scripts/create-security-issues.sh"
	echo ""
	echo "# Run security workflow manually"
	echo "gh workflow run security-issues.yml"
	echo ""
	echo "# Create test security issue"
	echo "gh issue create --template security_vulnerability.yml"
}

# Show usage
usage() {
	echo "Usage: $0 [REPO_OWNER] [REPO_NAME]"
	echo ""
	echo "Arguments:"
	echo "  REPO_OWNER    GitHub repository owner (default: GrammaTonic)"
	echo "  REPO_NAME     GitHub repository name (default: github-runner)"
	echo ""
	echo "Examples:"
	echo "  $0                                    # Use default repo"
	echo "  $0 myorg myrepo                       # Use custom repo"
}

# Handle help argument
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	usage
	exit 0
fi

# Run main function
main "$@"
