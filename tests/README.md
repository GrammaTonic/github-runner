# Comprehensive Test Suite

This directory contains a robust testing framework designed to prevent regressions and catch issues before they impact production, specifically addressing problems like the `libgconf-2-4` package availability issue.

## 🎯 Purpose

This test suite was created in response to the Docker build failure caused by the obsolete `libgconf-2-4` package in Ubuntu 24.04. It ensures such issues are caught early in the development process and prevents similar regressions.

## 📁 Directory Structure

```
tests/
├── docker/
│   └── validate-packages.sh       # Docker package validation
├── integration/
│   └── comprehensive-tests.sh     # Full integration testing
├── unit/
│   └── package-validation.sh      # Unit tests for package validation
├── run-all-tests.sh              # Master test runner
└── README.md                     # This file
```

## 🧪 Test Suites

### 1. Package Validation Tests (`docker/validate-packages.sh`)

**Purpose:** Validates that all packages in Dockerfiles are available in the target Ubuntu version.

**Features:**

- ✅ Detects obsolete packages (like `libgconf-2-4`)
- ✅ Tests package availability against actual Ubuntu repositories
- ✅ Suggests alternatives for obsolete packages
- ✅ Supports dry-run mode for syntax checking
- ✅ Generates detailed reports

**Usage:**

```bash
# Validate packages against Ubuntu 24.04
./tests/docker/validate-packages.sh

# Dry-run mode (syntax check only)
./tests/docker/validate-packages.sh --dry-run

# Test against different Ubuntu version
./tests/docker/validate-packages.sh --version 22.04
```

**Prevention:** Prevents Docker build failures due to package availability issues.

### 2. Unit Tests (`unit/package-validation.sh`)

**Purpose:** Unit tests for detecting obsolete packages, duplicates, and compatibility issues.

**Features:**

- ✅ Detects known obsolete packages
- ✅ Finds duplicate package installations
- ✅ Checks Ubuntu version compatibility
- ✅ Suggests package alternatives
- ✅ Fast execution (no Docker required)

**Usage:**

```bash
# Run all unit tests
./tests/unit/package-validation.sh

# Test against specific Ubuntu version
./tests/unit/package-validation.sh --version 24.04
```

**Prevention:** Catches package issues during development before CI/CD.

### 3. Integration Tests (`integration/comprehensive-tests.sh`)

**Purpose:** Comprehensive integration testing of Docker builds and container functionality.

**Features:**

- ✅ Full Docker build testing
- ✅ Container functionality validation
- ✅ Chrome runner specific tests
- ✅ Docker Compose validation
- ✅ Configuration file testing
- ✅ Script syntax validation
- ✅ Security baseline checks

**Usage:**

```bash
# Run all integration tests
./tests/integration/comprehensive-tests.sh

# Dry-run mode (skip actual builds)
./tests/integration/comprehensive-tests.sh --dry-run

# Skip cleanup for debugging
./tests/integration/comprehensive-tests.sh --no-cleanup
```

**Prevention:** Validates entire system before deployment.

### 4. Master Test Runner (`run-all-tests.sh`)

**Purpose:** Executes all test suites and generates comprehensive reports.

**Features:**

- ✅ Runs all test suites in sequence
- ✅ Generates comprehensive markdown reports
- ✅ Supports fail-fast mode
- ✅ Detailed logging and error tracking
- ✅ CI/CD integration ready

**Usage:**

```bash
# Run all test suites
./tests/run-all-tests.sh

# Verbose output with detailed logs
./tests/run-all-tests.sh --verbose

# Fail-fast mode (stop on first failure)
./tests/run-all-tests.sh --fail-fast

# Dry-run mode
./tests/run-all-tests.sh --dry-run
```

## 🚨 Issue Prevention

This test suite specifically prevents:

### ✅ Package Availability Issues

- **Problem:** Packages like `libgconf-2-4` no longer available in newer Ubuntu versions
- **Prevention:** Package validation tests check availability before build
- **Detection:** Unit tests detect known obsolete packages

### ✅ Docker Build Failures

- **Problem:** Build failures during package installation
- **Prevention:** Integration tests validate builds before CI/CD
- **Detection:** Comprehensive Docker build testing

### ✅ Duplicate Dependencies

- **Problem:** Same package listed multiple times
- **Prevention:** Unit tests detect duplicates automatically
- **Detection:** Package deduplication validation

### ✅ Security Issues

- **Problem:** Insecure Docker practices or exposed secrets
- **Prevention:** Security validation in integration tests
- **Detection:** Baseline security checks

### ✅ Configuration Errors

- **Problem:** Syntax errors in config files or scripts
- **Prevention:** Configuration validation tests
- **Detection:** Syntax checking for all files

## 🔄 CI/CD Integration

The test suite is integrated into GitHub Actions workflow (`.github/workflows/ci-cd.yml`):

### Package Validation Job

```yaml
test-package-validation:
  name: Package Validation Tests
  runs-on: ubuntu-latest
  steps:
    - name: Run Package Validation Tests
      run: |
        # Runs package validation in dry-run mode
        DRY_RUN=true tests/docker/validate-packages.sh
        # Runs unit tests for obsolete package detection
        tests/unit/package-validation.sh
```

### Comprehensive Testing Job

```yaml
test-comprehensive:
  name: Comprehensive Integration Tests
  strategy:
    matrix:
      test-suite:
        [unit, integration, docker-validation, security, configuration]
  steps:
    - name: Run [Test Suite]
      run: |
        # Executes specific test suite
        TEST_RESULTS_DIR="test-results/${{ matrix.test-suite }}" tests/[script].sh
```

## 📊 Test Results

Test results are organized in the `test-results/` directory:

```
test-results/
├── master.log                    # Master test execution log
├── test-report.md               # Comprehensive test report
├── unit/                        # Unit test results
├── integration/                 # Integration test results
├── docker/                      # Package validation results
├── security/                    # Security test results
└── configuration/               # Configuration test results
```

## 🛠️ Development Workflow

### Before Making Changes

```bash
# Run quick validation
./tests/run-all-tests.sh --dry-run

# Run full test suite
./tests/run-all-tests.sh
```

### After Docker Changes

```bash
# Validate packages specifically
./tests/docker/validate-packages.sh

# Test Docker builds
./tests/integration/comprehensive-tests.sh
```

### Before Committing

```bash
# Run all tests with verbose output
./tests/run-all-tests.sh --verbose

# Check the generated report
cat test-results/test-report.md
```

## 🔧 Configuration

### Environment Variables

| Variable           | Default          | Description                           |
| ------------------ | ---------------- | ------------------------------------- |
| `UBUNTU_VERSION`   | `24.04`          | Ubuntu version for package validation |
| `DRY_RUN`          | `false`          | Skip actual builds, syntax check only |
| `TEST_RESULTS_DIR` | `./test-results` | Directory for test results            |
| `CLEANUP`          | `true`           | Clean up test containers and images   |
| `TIMEOUT`          | `300`            | Build timeout in seconds              |
| `VERBOSE`          | `false`          | Show detailed output                  |
| `FAIL_FAST`        | `false`          | Stop on first test suite failure      |

### Customization

#### Adding New Package Validations

Edit `tests/unit/package-validation.sh` and add to `OBSOLETE_PACKAGES`:

```bash
declare -A OBSOLETE_PACKAGES=(
    ["your-obsolete-package"]="Reason why it's obsolete"
)
```

#### Adding New Integration Tests

Add tests to `tests/integration/comprehensive-tests.sh`:

```bash
test_your_new_feature() {
    start_test "Your New Feature Test"

    # Your test logic here

    if [[ $test_passed ]]; then
        pass_test "Your New Feature Test"
    else
        fail_test "Your New Feature Test" "Reason for failure"
        return 1
    fi
}
```

## 🚀 Quick Start

1. **Make scripts executable:**

   ```bash
   find tests/ -name "*.sh" -type f -exec chmod +x {} \;
   ```

2. **Run quick validation:**

   ```bash
   ./tests/run-all-tests.sh --dry-run
   ```

3. **Run full test suite:**

   ```bash
   ./tests/run-all-tests.sh --verbose
   ```

4. **Check results:**
   ```bash
   cat test-results/test-report.md
   ```

## 📚 Examples

### Detecting the libgconf-2-4 Issue

Before fix:

```bash
$ ./tests/unit/package-validation.sh
[ERROR] OBSOLETE PACKAGE FOUND in Dockerfile.chrome: libgconf-2-4
[ERROR]   Reason: Obsolete since Ubuntu 20.04 - Use GSettings/dconf instead
✗ FAILED: Obsolete Package Detection - Obsolete packages found!
```

After fix:

```bash
$ ./tests/unit/package-validation.sh
[INFO] ✓ PASSED: Obsolete Package Detection - No obsolete packages found
```

### Package Validation Output

```bash
$ ./tests/docker/validate-packages.sh
[INFO] Starting Docker package validation for Ubuntu 24.04
[INFO] Found 2 Dockerfile(s) to validate
[INFO] Processing Dockerfile.chrome...
[INFO] Found 45 packages in Dockerfile.chrome
Testing package: curl
✓ curl - Available
Testing package: wget
✓ wget - Available
[INFO] All packages validated successfully for Dockerfile.chrome
[INFO] ✓ All package validations passed successfully!
```

## 📈 Benefits

1. **Early Detection:** Catch issues during development, not in CI/CD
2. **Comprehensive Coverage:** Tests packages, builds, security, and configuration
3. **Detailed Reporting:** Clear reports help identify and fix issues quickly
4. **CI/CD Integration:** Automatic validation in GitHub Actions
5. **Prevention Focus:** Designed to prevent specific known issues
6. **Developer Friendly:** Easy to run locally with helpful output

## 🔗 Related Issues

- **GitHub Issue #962:** Chrome container startup failures
- **Package Issue:** `libgconf-2-4` not available in Ubuntu 24.04
- **Build Failures:** Docker build exit code 100 during package installation

## 🤝 Contributing

When adding new tests:

1. Follow the established patterns in existing test scripts
2. Add comprehensive error handling and logging
3. Support dry-run mode where applicable
4. Update this README with new test descriptions
5. Test your changes with `./tests/run-all-tests.sh`

## 📞 Support

If tests fail:

1. Check the detailed logs in `test-results/`
2. Review the comprehensive report in `test-results/test-report.md`
3. Run individual test scripts for targeted debugging
4. Use `--verbose` mode for detailed output
5. Use `--dry-run` mode to check syntax without builds
