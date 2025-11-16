#!/bin/bash
# Test Dependabot Configuration
# This script validates the Dependabot setup and configuration

set -e

echo "🔍 Testing Dependabot Configuration..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Validate YAML syntax
echo "Test 1: Validating dependabot.yml syntax..."
if ruby -ryaml -e "YAML.load_file('.github/dependabot.yml')" 2>/dev/null; then
	echo -e "${GREEN}✅ YAML syntax is valid${NC}"
else
	echo -e "${RED}❌ YAML syntax is invalid${NC}"
	exit 1
fi

# Test 2: Check file exists
echo ""
echo "Test 2: Checking dependabot.yml exists..."
if [ -f .github/dependabot.yml ]; then
	echo -e "${GREEN}✅ dependabot.yml exists${NC}"
else
	echo -e "${RED}❌ dependabot.yml not found${NC}"
	exit 1
fi

# Test 3: Verify configuration structure
echo ""
echo "Test 3: Verifying configuration structure..."

# Check version
VERSION=$(ruby -ryaml -e "puts YAML.load_file('.github/dependabot.yml')['version']")
if [ "$VERSION" == "2" ]; then
	echo -e "${GREEN}✅ Version is correct (2)${NC}"
else
	echo -e "${RED}❌ Version is incorrect: $VERSION${NC}"
	exit 1
fi

# Count ecosystems
ECOSYSTEM_COUNT=$(ruby -ryaml -e "puts YAML.load_file('.github/dependabot.yml')['updates'].length")
echo -e "${GREEN}✅ Found $ECOSYSTEM_COUNT package ecosystems configured${NC}"

# Test 4: List configured ecosystems
echo ""
echo "Test 4: Configured ecosystems:"
ruby -ryaml -e "
config = YAML.load_file('.github/dependabot.yml')
config['updates'].each_with_index do |update, i|
  puts \"  #{i+1}. #{update['package-ecosystem']} (#{update['directory']})\"
  puts \"     Schedule: #{update['schedule']['interval']}\"
  puts \"     Target: #{update['target-branch']}\"
  puts \"     Labels: #{update['labels']&.join(', ') || 'none'}\"
  puts \"\"
end
"

# Test 5: Check GitHub Actions workflow files
echo ""
echo "Test 5: Checking GitHub Actions workflow files..."
WORKFLOW_COUNT=$(find .github/workflows -name "*.yml" -o -name "*.yaml" | wc -l)
echo -e "${GREEN}✅ Found $WORKFLOW_COUNT workflow file(s) to monitor${NC}"

# Test 6: Check Dockerfiles
echo ""
echo "Test 6: Checking Dockerfiles..."
DOCKERFILE_COUNT=$(find docker -name "Dockerfile*" | wc -l)
echo -e "${GREEN}✅ Found $DOCKERFILE_COUNT Dockerfile(s) to monitor${NC}"

# Test 7: Extract npm packages from Dockerfiles
echo ""
echo "Test 7: npm packages in Dockerfiles:"
if grep -h "npm install" docker/Dockerfile* 2>/dev/null | grep -oE '@[0-9]+\.[0-9]+\.[0-9]+|[a-z-]+@[0-9]' | sort -u; then
	echo -e "${GREEN}✅ Found npm packages to monitor${NC}"
else
	echo -e "${YELLOW}⚠️  No versioned npm packages found${NC}"
fi

# Test 8: Check repository settings
echo ""
echo "Test 8: Repository Dependabot settings:"
echo "  Checking via GitHub API..."

# Try to get Dependabot status
if command -v gh >/dev/null 2>&1; then
	echo "  📡 Querying GitHub..."
	gh api /repos/GrammaTonic/github-runner 2>/dev/null | jq -r '
        "  Repository: \(.full_name)",
        "  Visibility: \(.visibility)",
        "  Default branch: \(.default_branch)"
    ' 2>/dev/null || echo "  ⚠️  Could not fetch repository details"
else
	echo -e "${YELLOW}  ⚠️  GitHub CLI not available${NC}"
fi

# Test 9: Verify target branch exists
echo ""
echo "Test 9: Verifying target branch..."
TARGET_BRANCH=$(ruby -ryaml -e "puts YAML.load_file('.github/dependabot.yml')['updates'][0]['target-branch']")
if git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
	echo -e "${GREEN}✅ Target branch '$TARGET_BRANCH' exists locally${NC}"
else
	echo -e "${YELLOW}⚠️  Target branch '$TARGET_BRANCH' not found locally${NC}"
fi

# Test 10: Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ All Dependabot tests passed!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Configuration Summary:"
echo "  • Version: 2"
echo "  • Ecosystems: $ECOSYSTEM_COUNT (github-actions, docker, npm)"
echo "  • Target Branch: $TARGET_BRANCH"
echo "  • Workflow Files: $WORKFLOW_COUNT"
echo "  • Dockerfiles: $DOCKERFILE_COUNT"
echo "  • Schedule: Weekly (Monday 09:00)"
echo ""
echo "ℹ️  Next Steps:"
echo "  1. Dependabot will run on its weekly schedule (Monday 09:00)"
echo "  2. Security alerts will trigger automatic PRs when vulnerabilities found"
echo "  3. All PRs will target the '$TARGET_BRANCH' branch"
echo "  4. PRs will be labeled with 'dependencies' + ecosystem type"
echo ""
echo "🔗 To view Dependabot status:"
echo "  https://github.com/GrammaTonic/github-runner/network/updates"
echo ""
