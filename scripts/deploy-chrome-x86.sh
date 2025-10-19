#!/bin/bash

# Chrome Runner x86 Deployment Script
# Deploys GitHub Actions Chrome runner on x86 architecture

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running on x86
check_architecture() {
	log_info "Checking system architecture..."
	ARCH=$(uname -m)
	if [[ "$ARCH" != "x86_64" ]]; then
		log_error "This script requires x86_64 architecture. Current: $ARCH"
		log_info "Please run this on an x86_64 system (Linux/Windows with x86, AWS EC2, etc.)"
		exit 1
	fi
	log_success "Architecture check passed: $ARCH"
}

# Check prerequisites
check_prerequisites() {
	log_info "Checking prerequisites..."

	if ! command -v docker >/dev/null 2>&1; then
		log_error "Docker is not installed. Please install Docker first."
		exit 1
	fi

	if ! docker info >/dev/null 2>&1; then
		log_error "Docker daemon is not running. Please start Docker."
		exit 1
	fi

	log_success "Prerequisites check passed"
}

# Validate configuration
validate_config() {
	log_info "Validating configuration..."

	CONFIG_FILE="config/chrome-runner.env"
	if [[ ! -f "$CONFIG_FILE" ]]; then
		log_error "Configuration file not found: $CONFIG_FILE"
		log_info "Run: cp config/chrome-runner.env.example config/chrome-runner.env"
		exit 1
	fi

	# Check required variables
	# shellcheck disable=SC1090
	source "$CONFIG_FILE"

	if [[ -z "${GITHUB_TOKEN:-}" ]] || [[ "$GITHUB_TOKEN" == "ghp_your_personal_access_token_here" ]]; then
		log_error "GITHUB_TOKEN not configured in $CONFIG_FILE"
		exit 1
	fi

	if [[ -z "${GITHUB_REPOSITORY:-}" ]] || [[ "$GITHUB_REPOSITORY" == "your-username/your-repo-name" ]]; then
		log_error "GITHUB_REPOSITORY not configured in $CONFIG_FILE"
		exit 1
	fi

	log_success "Configuration validation passed"
}

# Build Chrome runner image
build_image() {
	log_info "Building Chrome runner image for x86..."

	# Temporarily restore architecture check for production
	sed -i "s/# RUN if \[ \"\$TARGETARCH\" != \"amd64\" \]; then/RUN if [ \"\$TARGETARCH\" != \"amd64\" ]; then/" docker/Dockerfile.chrome
	sed -i 's/# fi/fi/' docker/Dockerfile.chrome

	# Restore Chrome version check
	sed -i 's/|| echo "Chrome version check skipped on ARM64"//' docker/Dockerfile.chrome

	docker build -f docker/Dockerfile.chrome -t github-runner-chrome:x86 ./docker

	log_success "Chrome runner image built successfully"
}

# Deploy Chrome runner
deploy_runner() {
	log_info "Deploying Chrome runner..."

	# Create networks and volumes
	docker network create runner-network 2>/dev/null || true

	# Start the runner
	docker compose -f docker/docker-compose.chrome.yml --env-file config/chrome-runner.env up -d

	log_success "Chrome runner deployed successfully"
}

# Show status
show_status() {
	log_info "Checking runner status..."

	echo ""
	echo "=== Chrome Runner Status ==="
	docker ps --filter "name=github-runner-chrome" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

	echo ""
	echo "=== Runner Logs (last 10 lines) ==="
	docker logs github-runner-chrome --tail 10 2>/dev/null || echo "No logs available yet"

	echo ""
	log_success "Status check complete"
}

# Main deployment
main() {
	echo ""
	echo -e "${BLUE}🚀 Chrome Runner x86 Deployment${NC}"
	echo -e "${BLUE}==============================${NC}"
	echo ""

	check_architecture
	check_prerequisites
	validate_config
	build_image
	deploy_runner
	show_status

	echo ""
	log_success "🎉 Chrome Runner deployment completed!"
	echo ""
	echo "Next steps:"
	echo "1. Check GitHub repository Settings > Actions > Runners"
	echo "2. Your Chrome runner should appear as online"
	echo "3. Test with a workflow that uses Chrome/browser testing"
	echo ""
}

# Handle command line arguments
case "${1:-}" in
"status")
	show_status
	;;
"stop")
	log_info "Stopping Chrome runner..."
	docker compose -f docker/docker-compose.chrome.yml down
	log_success "Chrome runner stopped"
	;;
"restart")
	log_info "Restarting Chrome runner..."
	docker compose -f docker/docker-compose.chrome.yml restart
	show_status
	;;
*)
	main
	;;
esac
