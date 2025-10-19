#!/bin/bash
set -euo pipefail

# GitHub Runner Docker Image Build Script
# Automates building, tagging, and pushing runner images

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

# Configuration with defaults
REGISTRY="${DOCKER_REGISTRY:-ghcr.io}"
NAMESPACE="${DOCKER_NAMESPACE:-grammatonic}"
IMAGE_NAME="${IMAGE_NAME:-github-runner}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
RUNNER_VERSION="${RUNNER_VERSION:-2.328.0}"

# Build arguments
BUILD_ARGS=(
	"--build-arg" "RUNNER_VERSION=${RUNNER_VERSION}"
	"--build-arg" "BUILDKIT_INLINE_CACHE=1"
)

# Cache configuration
if [[ "${DOCKER_CACHE_FROM:-}" ]]; then
	BUILD_ARGS+=("--cache-from" "${DOCKER_CACHE_FROM}")
fi

if [[ "${DOCKER_CACHE_TO:-}" ]]; then
	BUILD_ARGS+=("--cache-to" "${DOCKER_CACHE_TO}")
fi

# Parse command line arguments
PUSH=false
MULTI_PLATFORM=false
DEV_MODE=false
NO_CACHE=false
VERBOSE=false

usage() {
	cat <<EOF
Usage: $0 [OPTIONS]

Build GitHub Actions Runner Docker image

OPTIONS:
		-p, --push              Push image to registry after build
		-m, --multi-platform    Build for multiple platforms
		-d, --dev               Development mode (local only, faster build)
		-n, --no-cache          Disable Docker build cache
		-v, --verbose           Verbose output
		-t, --tag TAG           Custom image tag (default: ${IMAGE_TAG})
		-r, --runner-version    Runner version (default: ${RUNNER_VERSION})
		-h, --help              Show this help message

EXAMPLES:
		$0                      # Build local image
		$0 -p                   # Build and push to registry
		$0 -m -p                # Build multi-platform and push
		$0 -d                   # Development build (fast, local only)
		$0 -t v1.0.0 -p         # Build with custom tag and push

ENVIRONMENT VARIABLES:
		DOCKER_REGISTRY         Container registry (default: ghcr.io)
		DOCKER_NAMESPACE        Registry namespace (default: grammatonic)
		IMAGE_NAME              Image name (default: github-runner)
		PLATFORMS               Target platforms for multi-platform builds
		RUNNER_VERSION          GitHub Actions runner version

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-p | --push)
		PUSH=true
		shift
		;;
	-m | --multi-platform)
		MULTI_PLATFORM=true
		shift
		;;
	-d | --dev)
		DEV_MODE=true
		shift
		;;
	-n | --no-cache)
		NO_CACHE=true
		shift
		;;
	-v | --verbose)
		VERBOSE=true
		shift
		;;
	-t | --tag)
		IMAGE_TAG="$2"
		shift 2
		;;
	-r | --runner-version)
		RUNNER_VERSION="$2"
		BUILD_ARGS+=("--build-arg" "RUNNER_VERSION=${RUNNER_VERSION}")
		shift 2
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		log_error "Unknown option: $1"
		usage
		exit 1
		;;
	esac
done

# Construct full image name
FULL_IMAGE_NAME="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG}"

# Validate prerequisites
check_prerequisites() {
	log_info "Checking prerequisites..."

	# Check Docker
	if ! command -v docker &>/dev/null; then
		log_error "Docker is not installed or not in PATH"
		exit 1
	fi

	# Check Docker buildx for multi-platform builds
	if [[ "$MULTI_PLATFORM" == "true" ]]; then
		if ! docker buildx version &>/dev/null; then
			log_error "Docker buildx is required for multi-platform builds"
			exit 1
		fi
	fi

	# Check if logged into registry for push
	if [[ "$PUSH" == "true" ]]; then
		# More reliable registry authentication check using docker pull of a test image
		TEST_IMAGE="${REGISTRY}/alpine:latest"
		if ! docker pull "$TEST_IMAGE" >/dev/null 2>&1; then
			log_warning "Docker registry authentication check failed (unable to pull test image). Attempting login..."
			if ! docker login "${REGISTRY}"; then
				log_error "Failed to login to registry. Use: docker login ${REGISTRY}"
				exit 1
			fi
			# Try pulling again after login
			if ! docker pull "$TEST_IMAGE" >/dev/null 2>&1; then
				log_error "Authentication to registry failed even after login. Please check your credentials."
				exit 1
			fi
		else
			log_info "Docker registry authentication verified (test image pull succeeded)"
		fi
	fi

	# Check if Dockerfile exists
	if [[ ! -f "docker/Dockerfile" ]]; then
		log_error "Dockerfile not found at docker/Dockerfile"
		exit 1
	fi

	log_success "Prerequisites check completed"
}

# Setup buildx for multi-platform builds
setup_buildx() {
	if [[ "$MULTI_PLATFORM" == "true" ]]; then
		log_info "Setting up Docker buildx for multi-platform build..."

		# Create or use existing builder
		if ! docker buildx inspect github-runner-builder &>/dev/null; then
			docker buildx create --name github-runner-builder --use
		else
			docker buildx use github-runner-builder
		fi

		# Bootstrap builder
		docker buildx inspect --bootstrap
		log_success "Buildx setup completed"
	fi
}

# Build the image
build_image() {
	log_info "Building GitHub Actions Runner image..."
	log_info "Image: ${FULL_IMAGE_NAME}"
	log_info "Runner version: ${RUNNER_VERSION}"

	# Prepare build command
	local build_cmd=("docker")

	if [[ "$MULTI_PLATFORM" == "true" ]]; then
		build_cmd+=("buildx" "build")
		if [[ "$PUSH" == "true" ]]; then
			build_cmd+=("--push")
		else
			build_cmd+=("--load")
		fi
		build_cmd+=("--platform" "${PLATFORMS}")
	else
		build_cmd+=("build")
	fi

	# Add build arguments
	build_cmd+=("${BUILD_ARGS[@]}")

	# Add cache options
	if [[ "$NO_CACHE" == "true" ]]; then
		build_cmd+=("--no-cache")
	fi

	# Add tag
	build_cmd+=("--tag" "${FULL_IMAGE_NAME}")

	# Add labels
	build_cmd+=(
		"--label" "org.opencontainers.image.title=GitHub Actions Runner"
		"--label" "org.opencontainers.image.description=Self-hosted GitHub Actions runner with Docker support"
		"--label" "org.opencontainers.image.vendor=GrammaTonic"
		"--label" "org.opencontainers.image.version=${IMAGE_TAG}"
		"--label" "org.opencontainers.image.created=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
		"--label" "runner.version=${RUNNER_VERSION}"
	)

	# Add context
	build_cmd+=("docker/")

	# Execute build
	log_info "Executing: ${build_cmd[*]}"
	if [[ "$VERBOSE" == "true" ]]; then
		"${build_cmd[@]}"
	else
		"${build_cmd[@]}" >/dev/null 2>&1
	fi

	log_success "Image built successfully: ${FULL_IMAGE_NAME}"
}

# Push image (if not using buildx push)
push_image() {
	if [[ "$PUSH" == "true" && "$MULTI_PLATFORM" != "true" ]]; then
		log_info "Pushing image to registry..."
		docker push "${FULL_IMAGE_NAME}"
		log_success "Image pushed successfully: ${FULL_IMAGE_NAME}"
	fi
}

# Run security scan
security_scan() {
	log_info "Running security scan on built image..."

	if command -v trivy &>/dev/null; then
		trivy image --severity HIGH,CRITICAL "${FULL_IMAGE_NAME}"
	elif command -v docker &>/dev/null && docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest --version &>/dev/null; then
		docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
			aquasec/trivy:latest image --severity HIGH,CRITICAL "${FULL_IMAGE_NAME}"
	else
		log_warning "Trivy not available. Skipping security scan."
		log_warning "Install Trivy for security scanning: https://aquasecurity.github.io/trivy/"
	fi
}

# Display build summary
show_summary() {
	log_info "=== Build Summary ==="
	log_info "Image: ${FULL_IMAGE_NAME}"
	log_info "Runner Version: ${RUNNER_VERSION}"
	log_info "Multi-platform: ${MULTI_PLATFORM}"
	log_info "Pushed: ${PUSH}"
	log_info "Development Mode: ${DEV_MODE}"

	if [[ "$MULTI_PLATFORM" == "true" ]]; then
		log_info "Platforms: ${PLATFORMS}"
	fi

	# Show image size
	if [[ "$MULTI_PLATFORM" != "true" ]] && docker image inspect "${FULL_IMAGE_NAME}" &>/dev/null; then
		local size raw_size
		raw_size=$(docker image inspect "${FULL_IMAGE_NAME}" --format='{{.Size}}')
		if command -v numfmt &>/dev/null; then
			size=$(echo "$raw_size" | numfmt --to=iec-i --suffix=B)
		else
			size="${raw_size} bytes"
			log_warning "numfmt not found; showing raw byte size. Install coreutils for human-readable sizes."
		fi
		log_info "Image Size: ${size}"
	fi

	log_success "Build completed successfully!"
}

# Main execution
main() {
	log_info "Starting GitHub Actions Runner image build..."

	# Run checks and setup
	check_prerequisites
	setup_buildx

	# Build the image
	build_image

	# Push if requested and not multi-platform (buildx handles push for multi-platform)
	push_image

	# Run security scan
	if [[ "$DEV_MODE" != "true" ]]; then
		security_scan
	fi

	# Show summary
	show_summary
}

# Execute main function
main "$@"
