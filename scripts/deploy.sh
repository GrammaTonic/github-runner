#!/bin/bash
set -euo pipefail

# GitHub Runner Deployment Script
# Handles deployment, scaling, and management of runner containers

# Configuration
ENTRYPOINT_PATH="${ENTRYPOINT_PATH:-/usr/local/bin/entrypoint.sh}"

# Source runner configuration if available
if [[ -f "config/runner.env" ]]; then
    # shellcheck source=config/runner.env.example
    source config/runner.env
fi

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

# Configuration
COMPOSE_FILE="docker/docker-compose.yml"
DEFAULT_SCALE=1
ENVIRONMENT="production"

# Parse command line arguments
ACTION=""
SCALE=""
ENVIRONMENT_FLAG=""
FORCE=false
NO_BUILD=false
VERBOSE=false

usage() {
    cat << EOF
Usage: $0 ACTION [OPTIONS]

Manage GitHub Actions Runner deployments

ACTIONS:
    start               Start runner containers
    stop                Stop runner containers
    restart             Restart runner containers
    scale               Scale runner containers
    status              Show runner status
    logs                Show runner logs
    cleanup             Clean up stopped containers and unused resources
    update              Update and restart runners
    health              Check runner health

OPTIONS:
    -s, --scale NUM     Number of runner instances (default: ${DEFAULT_SCALE})
    -e, --env ENV       Environment (dev|staging|production) (default: ${ENVIRONMENT})
    -f, --force         Force action without confirmation
    -n, --no-build      Skip building images for update action
    -v, --verbose       Verbose output
    -h, --help          Show this help message

EXAMPLES:
    $0 start                    # Start single runner
    $0 start -s 3               # Start 3 runners
    $0 scale -s 5               # Scale to 5 runners
    $0 stop                     # Stop all runners
    $0 logs runner              # Show logs for runner service
    $0 update -f                # Force update without confirmation
    $0 health                   # Check health of all runners

ENVIRONMENT VARIABLES:
    GITHUB_TOKEN               GitHub Personal Access Token
    GITHUB_REPOSITORY          Target repository (org/repo)
    RUNNER_LABELS              Custom labels for runners
    COMPOSE_FILE               Docker Compose file path

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        start|stop|restart|scale|status|logs|cleanup|update|health)
            ACTION="$1"
            shift
            ;;
        -s|--scale)
            SCALE="$2"
            shift 2
            ;;
        -e|--env)
            ENVIRONMENT_FLAG="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -n|--no-build)
            NO_BUILD=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            export VERBOSE  # Export for potential use by other scripts
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ -z "$ACTION" ]]; then
                log_error "Unknown action: $1"
                usage
                exit 1
            else
                # Additional argument for logs command
                SERVICE="$1"
                shift
            fi
            ;;
    esac
done

# Set environment if provided
if [[ -n "$ENVIRONMENT_FLAG" ]]; then
    ENVIRONMENT="$ENVIRONMENT_FLAG"
fi

# Validate prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker and Docker Compose
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed or not in PATH"
        exit 1
    fi
    
    # Check compose file
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "Docker Compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    
    # Check required environment variables for start action
    if [[ "$ACTION" == "start" || "$ACTION" == "restart" || "$ACTION" == "scale" ]]; then
        if [[ -z "${GITHUB_TOKEN:-}" ]]; then
            log_error "GITHUB_TOKEN environment variable is required"
            log_error "Please set it in config/runner.env or as an environment variable"
            exit 1
        fi
        
        if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
            log_error "GITHUB_REPOSITORY environment variable is required"
            log_error "Please set it in config/runner.env or as an environment variable"
            exit 1
        fi
    fi
    
    log_success "Prerequisites check completed"
}

# Get Docker Compose command
get_compose_cmd() {
    if docker compose version &> /dev/null; then
        echo "docker compose"
    else
        echo "docker-compose"
    fi
}

# Start runners
start_runners() {
    local scale_count="${SCALE:-$DEFAULT_SCALE}"
    
    log_info "Starting GitHub Actions runners..."
    log_info "Environment: $ENVIRONMENT"
    log_info "Scale: $scale_count"
    log_info "Repository: ${GITHUB_REPOSITORY}"
    
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    # Set environment variables for compose
    export COMPOSE_PROJECT_NAME="github-runner-${ENVIRONMENT}"
    
    # Start base runner
    $compose_cmd -f "$COMPOSE_FILE" up -d runner
    
    # Scale if more than 1 instance requested
    if [[ "$scale_count" -gt 1 ]]; then
        log_info "Scaling to $scale_count instances..."
        
        # Enable scale profile and start additional runners
        $compose_cmd -f "$COMPOSE_FILE" --profile scale up -d --scale runner="$scale_count"
    fi
    
    log_success "Runners started successfully"
}

# Stop runners
stop_runners() {
    log_info "Stopping GitHub Actions runners..."
    
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    export COMPOSE_PROJECT_NAME="github-runner-${ENVIRONMENT}"
    
    # Stop all services
    $compose_cmd -f "$COMPOSE_FILE" --profile scale down
    
    log_success "Runners stopped successfully"
}

# Restart runners
restart_runners() {
    log_info "Restarting GitHub Actions runners..."
    stop_runners
    sleep 5
    start_runners
    log_success "Runners restarted successfully"
}

# Scale runners
scale_runners() {
    local scale_count="${SCALE:-$DEFAULT_SCALE}"
    
    log_info "Scaling GitHub Actions runners to $scale_count instances..."
    
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    export COMPOSE_PROJECT_NAME="github-runner-${ENVIRONMENT}"
    
    # Scale the runner service
    if [[ "$scale_count" -eq 1 ]]; then
        # Scale down to single runner
        $compose_cmd -f "$COMPOSE_FILE" up -d --scale runner=1
        $compose_cmd -f "$COMPOSE_FILE" --profile scale stop
    else
        # Scale up
        $compose_cmd -f "$COMPOSE_FILE" --profile scale up -d --scale runner="$scale_count"
    fi
    
    log_success "Runners scaled to $scale_count instances"
}

# Show status
show_status() {
    log_info "GitHub Actions Runner Status"
    
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    export COMPOSE_PROJECT_NAME="github-runner-${ENVIRONMENT}"
    
    # Show compose services status
    $compose_cmd -f "$COMPOSE_FILE" ps
    
    echo ""
    log_info "Container Resource Usage:"
    # Get container names and handle empty result safely
    container_names=$(docker ps --filter "name=github-runner" --format "{{.Names}}" 2>/dev/null || echo "")
    if [[ -n "$container_names" ]]; then
        echo "$container_names" | xargs docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    else
        echo "No GitHub runner containers found"
    fi
}

# Show logs
show_logs() {
    local service="${SERVICE:-runner}"
    
    log_info "Showing logs for service: $service"
    
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    export COMPOSE_PROJECT_NAME="github-runner-${ENVIRONMENT}"
    
    # Follow logs
    $compose_cmd -f "$COMPOSE_FILE" logs -f "$service"
}

# Cleanup resources
cleanup_resources() {
    log_info "Cleaning up Docker resources..."
    
    if [[ "$FORCE" != "true" ]]; then
        echo "This will remove:"
        echo "- Stopped containers"
        echo "- Unused networks"
        echo "- Unused images"
        echo "- Build cache"
        echo ""
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Cleanup cancelled"
            return 0
        fi
    fi
    
    # Clean up Docker resources
    docker container prune -f
    docker network prune -f
    docker image prune -f
    docker builder prune -f
    
    # Remove unused volumes (be careful with this)
    if [[ "$FORCE" == "true" ]]; then
        docker volume prune -f
    fi
    
    log_success "Cleanup completed"
}

# Update runners
update_runners() {
    log_info "Updating GitHub Actions runners..."
    
    if [[ "$FORCE" != "true" ]]; then
        echo "This will:"
        echo "- Stop current runners"
        echo "- Pull/build latest images"
        echo "- Start updated runners"
        echo ""
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Update cancelled"
            return 0
        fi
    fi
    
    # Stop current runners
    stop_runners
    
    # Build new image if not skipped
    if [[ "$NO_BUILD" != "true" ]]; then
        log_info "Building updated image..."
        ./scripts/build.sh
    fi
    
    # Pull latest images
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    export COMPOSE_PROJECT_NAME="github-runner-${ENVIRONMENT}"
    $compose_cmd -f "$COMPOSE_FILE" pull
    
    # Start updated runners
    start_runners
    
    log_success "Update completed"
}

# Health check
health_check() {
    log_info "Checking runner health..."
    
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    export COMPOSE_PROJECT_NAME="github-runner-${ENVIRONMENT}"
    
    # Get running containers
    local containers
    containers=$(docker ps --filter "name=github-runner" --format "{{.Names}}" 2>/dev/null || echo "")
    
    if [[ -z "$containers" ]]; then
        log_warning "No runner containers found"
        return 1
    fi
    
    local healthy=0
    local total=0
    
    for container in $containers; do
        total=$((total + 1))
        
        echo -n "Checking $container... "
        
        health_output=$(docker exec "$container" "$ENTRYPOINT_PATH" health-check 2>&1)
        if docker exec "$container" "$ENTRYPOINT_PATH" health-check >/dev/null 2>&1; then
            echo -e "${GREEN}HEALTHY${NC}"
            healthy=$((healthy + 1))
        else
            echo -e "${RED}UNHEALTHY${NC}"
            echo -e "${YELLOW}Health check output for $container:${NC}"
            # shellcheck disable=SC2001
            echo "$health_output" | sed 's/^/  /'
        fi
    done
    
    echo ""
    log_info "Health Summary: $healthy/$total runners healthy"
    
    if [[ "$healthy" -eq "$total" ]]; then
        log_success "All runners are healthy"
        return 0
    else
        log_warning "Some runners are unhealthy"
        return 1
    fi
}

# Main execution
main() {
    # Validate action
    if [[ -z "$ACTION" ]]; then
        log_error "No action specified"
        usage
        exit 1
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # Execute action
    case "$ACTION" in
        start)
            start_runners
            ;;
        stop)
            stop_runners
            ;;
        restart)
            restart_runners
            ;;
        scale)
            if [[ -z "$SCALE" ]]; then
                log_error "Scale count required. Use -s/--scale option"
                exit 1
            fi
            scale_runners
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        cleanup)
            cleanup_resources
            ;;
        update)
            update_runners
            ;;
        health)
            health_check
            ;;
        *)
            log_error "Unknown action: $ACTION"
            usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
