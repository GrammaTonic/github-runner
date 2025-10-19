#!/bin/bash
set -euo pipefail

# Documentation Structure Validation Script
# Ensures all documentation follows the project structure guidelines

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check for markdown files in root (excluding allowed ones)
check_root_markdown() {
	local allowed_files=("README.md" "README.md.backup")
	local found_violations=()

	# Find all .md files in root
	if ls ./*.md >/dev/null 2>&1; then
		for file in *.md; do
			[[ -f "$file" ]] || continue

			# Check if file is in allowed list
			local is_allowed=false
			for allowed in "${allowed_files[@]}"; do
				if [[ "$file" == "$allowed" ]]; then
					is_allowed=true
					break
				fi
			done

			if [[ "$is_allowed" == false ]]; then
				found_violations+=("$file")
			fi
		done
	fi

	if [[ ${#found_violations[@]} -gt 0 ]]; then
		log_error "Found markdown files in root directory that should be in /docs/:"
		for file in "${found_violations[@]}"; do
			echo "  ❌ $file"

			# Suggest proper location
			case "$file" in
			*"CODE_OF_CONDUCT"* | *"CONTRIBUTING"*)
				echo "     → Should be in: docs/community/$file"
				;;
			*"SECURITY"*)
				echo "     → Should be in: .github/$file (for GitHub recognition)"
				;;
			*"RELEASE"* | *"CHANGELOG"* | *"NOTES"*)
				echo "     → Should be in: docs/releases/$file"
				;;
			*"FEATURE"* | *"CHROME"*)
				echo "     → Should be in: docs/features/$file"
				;;
			*"setup"* | *"guide"* | *"installation"*)
				echo "     → Should be in: docs/guides/$file"
				;;
			*"corrupted"* | *"backup"* | *"old"*)
				echo "     → Should be in: docs/archive/$file"
				;;
			*)
				echo "     → Should be in: docs/ (appropriate subdirectory)"
				;;
			esac
		done
		echo ""
		echo "📖 To fix: mv <file> docs/<category>/"
		return 1
	else
		log_success "No unauthorized markdown files found in root directory"
		return 0
	fi
}

# Check that docs directory structure exists
check_docs_structure() {
	local required_dirs=("docs" "docs/community" "docs/features" "docs/releases" "docs/archive")
	local missing_dirs=()

	for dir in "${required_dirs[@]}"; do
		if [[ ! -d "$dir" ]]; then
			missing_dirs+=("$dir")
		fi
	done

	if [[ ${#missing_dirs[@]} -gt 0 ]]; then
		log_error "Missing required documentation directories:"
		for dir in "${missing_dirs[@]}"; do
			echo "  ❌ $dir"
		done
		echo ""
		echo "📖 To fix: mkdir -p ${missing_dirs[*]}"
		return 1
	else
		log_success "Documentation directory structure is correct"
		return 0
	fi
}

# Check that documentation index exists
check_docs_index() {
	if [[ -f "docs/README.md" ]]; then
		log_success "Documentation index (docs/README.md) exists"
		return 0
	else
		log_error "Documentation index (docs/README.md) is missing"
		echo "     → Create docs/README.md with navigation links"
		return 1
	fi
}

# Auto-fix option
auto_fix() {
	log_warning "Auto-fixing documentation structure..."

	# Create missing directories
	mkdir -p docs/community docs/features docs/releases docs/archive

	# Move files to correct locations
	if ls ./*.md >/dev/null 2>&1; then
		for file in *.md; do
			[[ -f "$file" ]] || continue

			case "$file" in
			"README.md" | "README.md.backup")
				# Keep in root
				;;
			*"CODE_OF_CONDUCT"* | *"CONTRIBUTING"*)
				mv "$file" "docs/community/"
				echo "  📁 Moved $file → docs/community/"
				;;
			*"SECURITY"*)
				mv "$file" ".github/"
				echo "  📁 Moved $file → .github/"
				;;
			*"RELEASE"* | *"CHANGELOG"* | *"NOTES"*)
				mv "$file" "docs/releases/"
				echo "  📁 Moved $file → docs/releases/"
				;;
			*"FEATURE"* | *"CHROME"*)
				mv "$file" "docs/features/"
				echo "  📁 Moved $file → docs/features/"
				;;
			*"corrupted"* | *"backup"* | *"old"*)
				mv "$file" "docs/archive/"
				echo "  📁 Moved $file → docs/archive/"
				;;
			*)
				mv "$file" "docs/"
				echo "  📁 Moved $file → docs/"
				;;
			esac
		done
	fi

	log_success "Auto-fix completed!"
}

# Main validation
main() {
	echo "🔍 Validating documentation structure..."
	echo ""

	# Check for --fix flag
	if [[ "${1:-}" == "--fix" ]]; then
		auto_fix
		echo ""
	fi

	local exit_code=0

	# Run all checks
	check_docs_structure || exit_code=1
	check_docs_index || exit_code=1
	check_root_markdown || exit_code=1

	echo ""
	if [[ $exit_code -eq 0 ]]; then
		log_success "✅ Documentation structure validation passed!"
	else
		log_error "❌ Documentation structure validation failed!"
		echo ""
		echo "📖 Guidelines:"
		echo "  • Keep root directory clean - only README.md allowed"
		echo "  • All documentation goes in /docs/ subdirectories"
		echo "  • Community files: docs/community/"
		echo "  • Feature docs: docs/features/"
		echo "  • Release notes: docs/releases/"
		echo "  • Archived files: docs/archive/"
		echo "  • GitHub templates: .github/ directory only"
		echo ""
		echo "🔧 Run with --fix to automatically organize files:"
		echo "  ./scripts/check-docs-structure.sh --fix"
	fi

	exit $exit_code
}

main "$@"
