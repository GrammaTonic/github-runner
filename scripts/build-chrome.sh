#!/bin/bash

# Chrome Runner Build Script
# Builds Docker image optimized for web UI testing

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Show usage
usage() {
    cat << EOF
Chrome Runner Build Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -t, --tag           Image tag (default: chrome-latest)
    -r, --registry      Registry (default: ghcr.io)
    -n, --namespace     Registry namespace (default: grammatonic)
    -p, --platforms     Target platforms (default: linux/amd64,linux/arm64)
    -v, --runner-version Runner version (default: 2.328.0)
    --push              Push image to registry
    --no-cache          Build without cache
    --multi-arch        Build multi-architecture image
    -h, --help          Show this help message

EXAMPLES:
    # Basic build
    $0

    # Build and push to registry
    $0 --push

    # Build with custom tag
    $0 --tag chrome-v1.0.0 --push

    # Build multi-architecture
    $0 --multi-arch --push

EOF
}

# Configuration with defaults
REGISTRY="${DOCKER_REGISTRY:-ghcr.io}"
NAMESPACE="${DOCKER_NAMESPACE:-grammatonic}"
IMAGE_NAME="github-runner"
IMAGE_TAG="chrome-latest"
PLATFORMS="linux/amd64,linux/arm64"
RUNNER_VERSION="2.328.0"
PUSH_IMAGE=false
NO_CACHE=false
MULTI_ARCH=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -p|--platforms)
            PLATFORMS="$2"
            shift 2
            ;;
        -v|--runner-version)
            RUNNER_VERSION="$2"
            shift 2
            ;;
        --push)
            PUSH_IMAGE=true
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --multi-arch)
            MULTI_ARCH=true
            shift
            ;;
        -h|--help)
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

# Full image name
FULL_IMAGE_NAME="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG}"

log_info "Chrome Runner Build Configuration:"
log_info "  Registry: ${REGISTRY}"
log_info "  Namespace: ${NAMESPACE}"
log_info "  Image: ${IMAGE_NAME}"
log_info "  Tag: ${IMAGE_TAG}"
log_info "  Full Name: ${FULL_IMAGE_NAME}"
log_info "  Platforms: ${PLATFORMS}"
log_info "  Runner Version: ${RUNNER_VERSION}"
log_info "  Push to Registry: ${PUSH_IMAGE}"
log_info "  Multi-Architecture: ${MULTI_ARCH}"
log_info "  No Cache: ${NO_CACHE}"

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if [[ "$MULTI_ARCH" == true ]]; then
        if ! docker buildx version &> /dev/null; then
            log_error "Docker buildx is required for multi-architecture builds"
            exit 1
        fi
        
        # Create or use existing buildx builder
        if ! docker buildx inspect chrome-builder &> /dev/null; then
            log_info "Creating buildx builder instance..."
            docker buildx create --name chrome-builder --driver docker-container --use
        else
            log_info "Using existing buildx builder..."
            docker buildx use chrome-builder
        fi
    fi
    
    log_success "Prerequisites check passed"
}

# Build the image
build_image() {
    log_info "Building Chrome runner image..."
    
    cd "${PROJECT_ROOT}/docker"
    
    # Build arguments
    BUILD_ARGS=(
        "--build-arg" "RUNNER_VERSION=${RUNNER_VERSION}"
        "--build-arg" "BUILDKIT_INLINE_CACHE=1"
        "--label" "org.opencontainers.image.source=https://github.com/GrammaTonic/github-runner"
        "--label" "org.opencontainers.image.description=GitHub Actions Self-Hosted Chrome Runner"
        "--label" "org.opencontainers.image.version=${IMAGE_TAG}"
        "--label" "runner.type=chrome"
        "--label" "runner.version=${RUNNER_VERSION}"
    )
    
    if [[ "$NO_CACHE" == true ]]; then
        BUILD_ARGS+=("--no-cache")
    fi
    
    if [[ "$MULTI_ARCH" == true ]]; then
        # Multi-architecture build with buildx
        BUILD_ARGS+=(
            "--platform" "${PLATFORMS}"
            "--file" "Dockerfile.chrome"
            "--tag" "${FULL_IMAGE_NAME}"
        )
        
        if [[ "$PUSH_IMAGE" == true ]]; then
            BUILD_ARGS+=("--push")
        else
            BUILD_ARGS+=("--load")
        fi
        
        docker buildx build "${BUILD_ARGS[@]}" .
        
    else
        # Single architecture build
        BUILD_ARGS+=(
            "--file" "Dockerfile.chrome"
            "--tag" "${FULL_IMAGE_NAME}"
        )
        
        docker build "${BUILD_ARGS[@]}" .
        
        if [[ "$PUSH_IMAGE" == true ]]; then
            log_info "Pushing image to registry..."
            docker push "${FULL_IMAGE_NAME}"
        fi
    fi
    
    log_success "Chrome runner image built successfully"
}

# Validate the built image
validate_image() {
    if [[ "$MULTI_ARCH" == true && "$PUSH_IMAGE" == false ]]; then
        log_warning "Skipping validation for multi-arch build without push"
        return
    fi
    
    log_info "Validating Chrome runner image..."
    
    # Test that the image contains required components
    log_info "Checking Chrome installation..."
    if docker run --rm "${FULL_IMAGE_NAME}" google-chrome-stable --version; then
        log_success "Chrome validation passed"
    else
        log_error "Chrome validation failed"
        exit 1
    fi
    
    log_info "Checking ChromeDriver installation..."
    if docker run --rm "${FULL_IMAGE_NAME}" chromedriver --version; then
        log_success "ChromeDriver validation passed"
    else
        log_error "ChromeDriver validation failed"
        exit 1
    fi
    
    log_info "Checking testing frameworks..."
    docker run --rm "${FULL_IMAGE_NAME}" bash -c "
        echo 'Node.js version:' && node --version &&
        echo 'Python version:' && python3 --version &&
        echo 'Playwright:' && npx playwright --version &&
        echo 'Selenium:' && python3 -c 'import selenium; print(selenium.__version__)'
    "
    
    log_success "Image validation completed"
}

# Show build summary
show_summary() {
    log_success "Chrome Runner Build Summary:"
    log_success "  Image: ${FULL_IMAGE_NAME}"
    log_success "  Runner Version: ${RUNNER_VERSION}"
    if [[ "$PUSH_IMAGE" == true ]]; then
        log_success "  Status: Built and pushed to registry"
    else
        log_success "  Status: Built locally"
    fi
    
    echo ""
    log_info "To run the Chrome runner:"
    echo "  docker run -e GITHUB_TOKEN=<token> -e GITHUB_REPOSITORY=<repo> ${FULL_IMAGE_NAME}"
    echo ""
    log_info "Or use Docker Compose:"
    echo "  GITHUB_TOKEN=<token> GITHUB_REPOSITORY=<repo> docker-compose -f docker-compose.chrome.yml up -d"
}

# Main execution
main() {
    log_info "Starting Chrome Runner build process..."
    
    check_prerequisites
    build_image
    validate_image
    show_summary
    
    log_success "Chrome Runner build completed successfully! 🎉"
}

# Run main function
main "$@"
