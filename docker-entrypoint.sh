#!/bin/bash
# Docker entrypoint script for GCP Development Container
# Minimal initialization without external dependencies

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[ENTRYPOINT]${NC} $1"; }
log_success() { echo -e "${GREEN}[ENTRYPOINT]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[ENTRYPOINT]${NC} $1"; }
log_error() { echo -e "${RED}[ENTRYPOINT]${NC} $1" >&2; }

# Configuration from environment
WORKSPACE_PATH="${DEV_WORKSPACE:-/app}"
ENVIRONMENT="${ENVIRONMENT:-dev}"

log_info "Starting container initialization..."
log_info "Workspace: $WORKSPACE_PATH"
log_info "Environment: $ENVIRONMENT"

# Function to setup SSH keys from mounted volume
setup_ssh_keys() {
    log_info "Setting up SSH keys..."
    
    local ssh_dir="/home/agent/.ssh"
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    # Check if SSH keys are mounted in workspace
    if [[ -d "$WORKSPACE_PATH/.ssh" ]]; then
        # Copy keys from workspace
        if [[ -f "$WORKSPACE_PATH/.ssh/id_ed25519" ]]; then
            cp "$WORKSPACE_PATH/.ssh/id_ed25519"* "$ssh_dir/" 2>/dev/null || true
            chmod 600 "$ssh_dir/id_ed25519" 2>/dev/null || true
            chmod 644 "$ssh_dir/id_ed25519.pub" 2>/dev/null || true
            log_success "Deployed ed25519 SSH key"
        fi
        
        if [[ -f "$WORKSPACE_PATH/.ssh/id_rsa" ]]; then
            cp "$WORKSPACE_PATH/.ssh/id_rsa"* "$ssh_dir/" 2>/dev/null || true
            chmod 600 "$ssh_dir/id_rsa" 2>/dev/null || true
            chmod 644 "$ssh_dir/id_rsa.pub" 2>/dev/null || true
            log_success "Deployed RSA SSH key"
        fi
    fi
    
    # Add GitHub to known hosts
    ssh-keyscan -t rsa github.com >> "$ssh_dir/known_hosts" 2>/dev/null || true
    log_success "Added GitHub to known hosts"
}

# Function to configure Git
configure_git() {
    log_info "Configuring Git..."
    
    # Set Git to use SSH for GitHub
    git config --global url."git@github.com:".insteadOf "https://github.com/" || true
    
    # Only configure Git user if not already set
    if ! git config --global user.name &>/dev/null; then
        log_info "Git user not configured - will need manual setup"
        log_info "Use: git config --global user.name 'Your Name'"
        log_info "Use: git config --global user.email 'your.email@example.com'"
    else
        local git_user
        git_user=$(git config --global user.name)
        log_success "Git already configured for user: $git_user"
    fi
}

# Function to ensure proper permissions
fix_permissions() {
    log_info "Fixing permissions..."
    
    # Ensure agent owns workspace
    chown -R agent:agent "$WORKSPACE_PATH" 2>/dev/null || true
    
    # Ensure agent owns their home directory
    chown -R agent:agent /home/agent 2>/dev/null || true
    
    log_success "Permissions fixed"
}

# Main initialization
main() {
    log_info "Container initialization starting..."
    
    # Run initialization steps
    setup_ssh_keys
    configure_git
    fix_permissions
    
    log_success "Container initialization complete!"
    log_info "Starting main process..."
    
    # Execute the main command
    exec "$@"
}

# Run main function with all arguments
main "$@"