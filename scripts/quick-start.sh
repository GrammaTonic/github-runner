#!/bin/bash

# GitHub Runner Quick Start Script
# This script helps users deploy GitHub self-hosted runners quickly and safely

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"
DOCKER_DIR="$PROJECT_ROOT/docker"

# Default configuration (will be updated based on runner type selection)
RUNNER_TYPE=""
ENV_FILE=""
ENV_EXAMPLE=""
COMPOSE_FILE=""

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

show_banner() {
    echo ""
    echo -e "${BLUE}🚀 GitHub Runner Quick Start${NC}"
    echo -e "${BLUE}==============================${NC}"
    echo ""
    echo "This script will help you deploy GitHub self-hosted runners"
    echo "in Docker containers for your repository."
    echo ""
}

select_runner_type() {
    log_step "Select runner type..."
    echo ""
    echo "Available runner types:"
    echo "  1) Standard Runner    - General purpose CI/CD runner"
    echo "  2) Chrome Runner      - UI testing with Chrome browser"
    echo "  3) Both Runners       - Deploy both standard and Chrome runners"
    echo ""
    
    while true; do
        read -p "Select runner type [1-3]: " choice
        case $choice in
            1)
                RUNNER_TYPE="standard"
                ENV_FILE="$CONFIG_DIR/runner.env"
                ENV_EXAMPLE="$CONFIG_DIR/runner.env.example"
                COMPOSE_FILE="$DOCKER_DIR/docker-compose.production.yml"
                log_info "Selected: Standard Runner"
                break
                ;;
            2)
                RUNNER_TYPE="chrome"
                ENV_FILE="$CONFIG_DIR/chrome-runner.env"
                ENV_EXAMPLE="$CONFIG_DIR/chrome-runner.env.example"
                COMPOSE_FILE="$DOCKER_DIR/docker-compose.chrome.yml"
                log_info "Selected: Chrome Runner"
                break
                ;;
            3)
                RUNNER_TYPE="both"
                log_info "Selected: Both Runners"
                log_info "Will deploy both standard and Chrome runners"
                break
                ;;
            *)
                log_error "Invalid choice. Please select 1, 2, or 3."
                ;;
        esac
    done
    echo ""
}

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if Docker is installed and running
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed. Please install Docker first:"
        echo "  https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is available
    if ! docker compose version >/dev/null 2>&1; then
        log_error "Docker Compose is not available. Please install Docker Compose:"
        echo "  https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    log_info "✓ Docker is installed and running"
    log_info "✓ Docker Compose is available"
}

setup_environment() {
    log_step "Setting up environment configuration..."
    
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"
    
    if [ "$RUNNER_TYPE" = "both" ]; then
        setup_both_environments
    else
        setup_single_environment
    fi
}

setup_single_environment() {
    # Check if environment file already exists
    if [ -f "$ENV_FILE" ]; then
        log_info "Environment file already exists: $ENV_FILE"
        
        # Ask if user wants to reconfigure
        echo ""
        read -p "Do you want to reconfigure? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Using existing configuration"
            return 0
        fi
    fi
    
    # Copy template if environment file doesn't exist
    if [ ! -f "$ENV_FILE" ]; then
        if [ -f "$ENV_EXAMPLE" ]; then
            cp "$ENV_EXAMPLE" "$ENV_FILE"
            log_info "Created environment file from template"
        else
            log_error "Environment template not found: $ENV_EXAMPLE"
            exit 1
        fi
    fi
    
    configure_runner_environment "$ENV_FILE" "$RUNNER_TYPE"
}

setup_both_environments() {
    log_info "Setting up both standard and Chrome runner environments..."
    
    # Setup standard runner
    local standard_env="$CONFIG_DIR/runner.env"
    local standard_example="$CONFIG_DIR/runner.env.example"
    
    # Setup Chrome runner
    local chrome_env="$CONFIG_DIR/chrome-runner.env"
    local chrome_example="$CONFIG_DIR/chrome-runner.env.example"
    
    # Check if files exist
    local reconfigure=false
    if [ -f "$standard_env" ] || [ -f "$chrome_env" ]; then
        log_info "Environment files already exist"
        echo ""
        read -p "Do you want to reconfigure both runners? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            reconfigure=true
        else
            log_info "Using existing configuration"
            return 0
        fi
    fi
    
    # Copy templates
    if [ ! -f "$standard_env" ] || [ "$reconfigure" = true ]; then
        cp "$standard_example" "$standard_env"
        log_info "Created standard runner environment file"
    fi
    
    if [ ! -f "$chrome_env" ] || [ "$reconfigure" = true ]; then
        cp "$chrome_example" "$chrome_env"
        log_info "Created Chrome runner environment file"
    fi
    
    # Configure both
    configure_runner_environment "$standard_env" "standard"
    configure_runner_environment "$chrome_env" "chrome"
}

configure_runner_environment() {
    local env_file="$1"
    local runner_type="$2"
    
    echo ""
    log_info "Configuring $runner_type runner..."
    echo ""
    
    # GitHub Token (shared)
    if [ -z "${github_token:-}" ]; then
        echo -e "${YELLOW}GitHub Personal Access Token:${NC}"
        echo "Create one at: https://github.com/settings/tokens"
        echo "Required scopes: repo (private) or public_repo (public)"
        echo ""
        read -p "Enter your GitHub token: " -s github_token
        echo ""
        
        if [ -z "$github_token" ]; then
            log_error "GitHub token is required"
            exit 1
        fi
    fi
    
    # GitHub Repository (shared)
    if [ -z "${github_repo:-}" ]; then
        echo ""
        echo -e "${YELLOW}GitHub Repository:${NC}"
        echo "Format: username/repository-name"
        echo "Example: johndoe/my-awesome-project"
        echo ""
        read -p "Enter your repository: " github_repo
        
        if [ -z "$github_repo" ]; then
            log_error "GitHub repository is required"
            exit 1
        fi
        
        # Validate repository format
        if [[ ! "$github_repo" =~ ^[^/]+/[^/]+$ ]]; then
            log_error "Invalid repository format. Use: username/repository-name"
            exit 1
        fi
    fi
    
    # Runner Name (specific to type)
    echo ""
    echo -e "${YELLOW}$runner_type Runner Configuration:${NC}"
    local default_name="docker-runner"
    if [ "$runner_type" = "chrome" ]; then
        default_name="chrome-runner"
    fi
    read -p "Runner name (default: $default_name): " runner_name
    runner_name=${runner_name:-$default_name}
    
    # Update environment file
    log_step "Updating $runner_type environment configuration..."
    
    # Use sed to replace values in the environment file
    sed -i.bak "s/GITHUB_TOKEN=.*/GITHUB_TOKEN=$github_token/" "$env_file"
    sed -i.bak "s|GITHUB_REPOSITORY=.*|GITHUB_REPOSITORY=$github_repo|" "$env_file"
    sed -i.bak "s/RUNNER_NAME=.*/RUNNER_NAME=$runner_name/" "$env_file"
    
    # Remove backup file
    rm -f "$env_file.bak"
    
    log_info "✓ $runner_type environment configured successfully"
}

validate_configuration() {
    log_step "Validating configuration..."
    
    if [ ! -f "$ENV_FILE" ]; then
        log_error "Environment file not found: $ENV_FILE"
        exit 1
    fi
    
    # Source the environment file
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    
    # Validate required variables
    if [ -z "$GITHUB_TOKEN" ] || [ "$GITHUB_TOKEN" = "ghp_your_personal_access_token_here" ]; then
        log_error "GITHUB_TOKEN is not configured properly"
        exit 1
    fi
    
    if [ -z "$GITHUB_REPOSITORY" ] || [ "$GITHUB_REPOSITORY" = "your-username/your-repo-name" ]; then
        log_error "GITHUB_REPOSITORY is not configured properly"
        exit 1
    fi
    
    log_info "✓ Configuration is valid"
    
    # Show configuration summary
    echo ""
    log_info "Configuration Summary:"
    echo "  Repository: $GITHUB_REPOSITORY"
    echo "  Main Runner: $RUNNER_NAME"
    echo "  Chrome Runner: $RUNNER_NAME_CHROME"
    echo ""
}

pull_images() {
    log_step "Pulling latest Docker images..."
    
    cd "$DOCKER_DIR"
    
    # Pull images
    docker compose -f docker-compose.production.yml --env-file "$ENV_FILE" pull
    
    log_info "✓ Docker images updated"
}

deploy_runners() {
    log_step "Deploying GitHub runners..."
    
    cd "$DOCKER_DIR"
    
    if [ "$RUNNER_TYPE" = "both" ]; then
        # Deploy both runners
        log_info "Deploying standard runner..."
        docker compose -f docker-compose.production.yml --env-file "$CONFIG_DIR/runner.env" up -d
        
        log_info "Deploying Chrome runner..."
        docker compose -f docker-compose.chrome.yml --env-file "$CONFIG_DIR/chrome-runner.env" up -d
        
        log_info "✓ Both GitHub runners deployed"
    else
        # Deploy single runner
        docker compose -f "$(basename "$COMPOSE_FILE")" --env-file "$ENV_FILE" up -d
        log_info "✓ $RUNNER_TYPE GitHub runner deployed"
    fi
}

show_status() {
    log_step "Checking deployment status..."
    
    cd "$DOCKER_DIR"
    
    echo ""
    echo -e "${BLUE}📊 Container Status:${NC}"
    
    if [ "$RUNNER_TYPE" = "both" ]; then
        echo "Standard Runner:"
        docker compose -f docker-compose.production.yml ps
        echo ""
        echo "Chrome Runner:"
        docker compose -f docker-compose.chrome.yml ps
        
        GITHUB_REPOSITORY_FROM_ENV=$(grep "GITHUB_REPOSITORY=" "$CONFIG_DIR/runner.env" | cut -d'=' -f2)
        
        echo ""
        echo -e "${BLUE}📋 Next Steps:${NC}"
        echo "1. Check runner registration in your GitHub repository:"
        echo "   https://github.com/$GITHUB_REPOSITORY_FROM_ENV/settings/actions/runners"
        echo ""
        echo "2. View logs:"
        echo "   Standard runner: docker compose -f docker-compose.production.yml logs -f"
        echo "   Chrome runner:   docker compose -f docker-compose.chrome.yml logs -f"
        echo ""
        echo "3. Stop runners:"
        echo "   docker compose -f docker-compose.production.yml down"
        echo "   docker compose -f docker-compose.chrome.yml down"
        echo ""
        echo "4. Restart runners:"
        echo "   docker compose -f docker-compose.production.yml restart"
        echo "   docker compose -f docker-compose.chrome.yml restart"
    else
        docker compose -f "$(basename "$COMPOSE_FILE")" ps
        
        GITHUB_REPOSITORY_FROM_ENV=$(grep "GITHUB_REPOSITORY=" "$ENV_FILE" | cut -d'=' -f2)
        
        echo ""
        echo -e "${BLUE}📋 Next Steps:${NC}"
        echo "1. Check runner registration in your GitHub repository:"
        echo "   https://github.com/$GITHUB_REPOSITORY_FROM_ENV/settings/actions/runners"
        echo ""
        echo "2. View logs:"
        echo "   docker compose -f $(basename "$COMPOSE_FILE") logs -f"
        echo ""
        echo "3. Stop runners:"
        echo "   docker compose -f $(basename "$COMPOSE_FILE") down"
        echo ""
        echo "4. Restart runners:"
        echo "   docker compose -f $(basename "$COMPOSE_FILE") restart"
    fi
    
    echo ""
    
    # Check if containers are healthy
    sleep 10
    log_step "Checking container health..."
    
    if [ "$RUNNER_TYPE" = "both" ]; then
        local healthy_count=0
        if docker compose -f docker-compose.production.yml ps | grep -q "healthy"; then
            ((healthy_count++))
        fi
        if docker compose -f docker-compose.chrome.yml ps | grep -q "healthy"; then
            ((healthy_count++))
        fi
        
        if [ $healthy_count -eq 2 ]; then
            log_info "✅ Both runners appear to be healthy"
        elif [ $healthy_count -eq 1 ]; then
            log_warn "⚠️  One runner is healthy, the other may still be starting up"
        else
            log_warn "⚠️  Runners may still be starting up. Check logs if issues persist."
        fi
    else
        if docker compose -f "$(basename "$COMPOSE_FILE")" ps | grep -q "healthy"; then
            log_info "✅ Runner appears to be healthy"
        else
            log_warn "⚠️  Runner may still be starting up. Check logs if issues persist."
        fi
    fi
}

show_troubleshooting() {
    echo ""
    echo -e "${YELLOW}🔧 Troubleshooting:${NC}"
    echo ""
    echo "If runners don't appear in GitHub:"
    echo "1. Check container logs: docker compose logs github-runner"
    echo "2. Verify your GitHub token has correct permissions"
    echo "3. Ensure repository name format is: username/repository-name"
    echo ""
    echo "If containers keep restarting:"
    echo "1. Check Docker daemon is running"
    echo "2. Verify /var/run/docker.sock permissions"
    echo "3. Check available system resources"
    echo ""
    echo "For more help, see: https://github.com/grammatonic/github-runner/docs"
    echo ""
}

cleanup_on_error() {
    log_error "An error occurred during deployment"
    
    echo ""
    read -p "Would you like to clean up and try again? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_step "Cleaning up..."
        cd "$DOCKER_DIR"
        docker compose -f docker-compose.production.yml down >/dev/null 2>&1 || true
        log_info "Cleanup completed"
    fi
}

main() {
    # Set trap for errors
    trap cleanup_on_error ERR
    
    show_banner
    select_runner_type
    check_prerequisites
    setup_environment
    validate_configuration
    pull_images
    deploy_runners
    show_status
    show_troubleshooting
    
    echo ""
    log_info "🎉 GitHub Runners deployment completed successfully!"
    echo ""
}

# Show help
show_help() {
    cat << EOF
GitHub Runner Quick Start Script

Usage: $0 [OPTIONS]

This script helps you deploy GitHub self-hosted runners in Docker containers.

OPTIONS:
    -h, --help          Show this help message
    --reconfigure       Force reconfiguration of environment
    --pull-only         Only pull latest images, don't deploy
    --status-only       Only show current status

EXAMPLES:
    $0                  # Full deployment with interactive setup
    $0 --reconfigure    # Reconfigure and redeploy
    $0 --status-only    # Check current deployment status

ENVIRONMENT:
    The script uses config/runner.env for configuration.
    Run with --reconfigure to update settings.

EOF
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    --reconfigure)
        rm -f "$ENV_FILE"
        main
        ;;
    --pull-only)
        show_banner
        check_prerequisites
        validate_configuration
        pull_images
        log_info "Images updated successfully"
        ;;
    --status-only)
        show_banner
        check_prerequisites
        show_status
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
