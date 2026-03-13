#!/bin/bash
# Unit Test: Configuration File Validation Empty Directory
# Verifies that test_configuration_files correctly fails when no configs are present

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-./test-results/unit}"
mkdir -p "$TEST_RESULTS_DIR"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Temporary resources to be cleaned up
TEMP_TEST_SCRIPT=$(mktemp)
MOCK_CONFIG_DIR=$(mktemp -d)
TEMP_BASE=$(mktemp -d)

cleanup_temp() {
	rm -f "$TEMP_TEST_SCRIPT"
	rm -rf "$MOCK_CONFIG_DIR"
	rm -rf "$TEMP_BASE"
}
trap cleanup_temp EXIT

# Source the comprehensive tests but override the execution
# We create a temporary script that sources the functions without running main
# Remove the main call and cleanup trap to avoid side effects
sed -e '/^main "\$@"/d' -e 's/^trap cleanup EXIT/# trap cleanup EXIT/' tests/integration/comprehensive-tests.sh > "$TEMP_TEST_SCRIPT"

# Create a temporary directory structure to trick $(dirname "$0")/../../config
mkdir -p "$TEMP_BASE/a/b"
ln -s "$MOCK_CONFIG_DIR" "$TEMP_BASE/config"

# Create a dummy script to source and run the function
DUMMY_SCRIPT="$TEMP_BASE/a/b/dummy.sh"
cat <<EOF > "$DUMMY_SCRIPT"
#!/bin/bash
source "$TEMP_TEST_SCRIPT"
# We need to make sure dirname \$0 works as expected inside the function
test_configuration_files
EOF
chmod +x "$DUMMY_SCRIPT"

log_info "Testing test_configuration_files with empty directory..."

# Run the dummy script
# If it succeeds (returns 0), the test failed (because it should catch the empty directory)
if "$DUMMY_SCRIPT" > "$TEST_RESULTS_DIR/test-config-empty.log" 2>&1; then
	log_error "✗ test_configuration_files PASSED when it should have FAILED (empty directory)"
	exit 1
else
	log_info "✓ test_configuration_files correctly FAILED when no config files were found"
	exit 0
fi
