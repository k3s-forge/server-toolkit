#!/usr/bin/env bash
# setup-tailscale.sh - Tailscale zero-trust network setup
# Installs and configures Tailscale VPN

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load common functions and i18n
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

# Tailscale configuration
TAILSCALE_CONFIG_FILE="${TAILSCALE_CONFIG_FILE:-$HOME/.server-toolkit-tailscale.conf}"

# Install Tailscale
install_tailscale() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    # Check if already installed
    if has_cmd tailscale; then
        local version
        version=$(tailscale version | head -1 || echo "unknown")
        i18n_info "file_exists" "Tailscale: $version"
        return 0
    fi
    
    i18n_info "installing_tailscale"
    
    # Detect OS
    local os_id
    os_id=$(get_system_info "os")
    
    case "$os_id" in
        ubuntu|debian)
            # Add Tailscale repository
            curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | \
                $sudo_cmd tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
            curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | \
                $sudo_cmd tee /etc/apt/sources.list.d/tailscale.list >/dev/null
            
            # Install
            $sudo_cmd apt-get update -qq
            $sudo_cmd apt-get install -y tailscale
            ;;
        centos|rhel|rocky|almalinux|fedora)
            # Add Tailscale repository
            $sudo_cmd dnf config-manager --add-repo https://pkgs.tailscale.com/stable/rhel/9/tailscale.repo 2>/dev/null || \
                $sudo_cmd yum-config-manager --add-repo https://pkgs.tailscale.com/stable/rhel/9/tailscale.repo
            
            # Install
            if has_cmd dnf; then
                $sudo_cmd dnf install -y tailscale
            else
                $sudo_cmd yum install -y tailscale
            fi
            ;;
        *)
            # Use universal install script
            i18n_info "download_file" "Tailscale install script"
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
    esac
    
    # Verify installation
    if has_cmd tailscale; then
        local version
        version=$(tailscale version | head -1 || echo "unknown")
        i18n_success "tailscale_installed" "$version"
    else
        i18n_error "failed" "Tailscale installation failed"
        return 1
    fi
}

# Start Tailscale service
start_tailscale_service() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "starting" "Tailscale service"
    
    # Enable and start service
    $sudo_cmd systemctl enable --now tailscaled
    
    # Check service status
    if ! systemctl is-active tailscaled >/dev/null 2>&1; then
        i18n_error "failed" "Tailscaled service failed to start"
        return 1
    fi
    
    i18n_success "running" "Tailscaled service"
}

# Connect to Tailscale network
connect_tailscale() {
    local auth_key="$1"
    local hostname="${2:-$(hostname)}"
    local accept_routes="${3:-false}"
    local accept_dns="${4:-false}"
    local advertise_exit="${5:-false}"
    local advertise_routes="${6:-}"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "configuring_dns" "Connecting to Tailscale network"
    
    # Build connection command
    local connect_cmd="$sudo_cmd tailscale up --authkey=$auth_key --hostname=$hostname"
    
    # Add optional flags
    if [[ "$accept_routes" == "true" ]]; then
        connect_cmd="$connect_cmd --accept-routes"
        i18n_info "info" "Accepting subnet routes"
    fi
    
    if [[ "$accept_dns" == "true" ]]; then
        connect_cmd="$connect_cmd --accept-dns"
        i18n_info "info" "Accepting DNS configuration"
    fi
    
    if [[ "$advertise_exit" == "true" ]]; then
        connect_cmd="$connect_cmd --advertise-exit-node"
        i18n_info "info" "Advertising as exit node"
    fi
    
    if [[ -n "$advertise_routes" ]]; then
        connect_cmd="$connect_cmd --advertise-routes=$advertise_routes"
        i18n_info "info" "Advertising routes: $advertise_routes"
    fi
    
    # Execute connection
    if eval "$connect_cmd"; then
        i18n_success "completed" "Connected to Tailscale network"
    else
        i18n_error "failed" "Failed to connect to Tailscale network"
        return 1
    fi
}

# Configure Tailscale interactively
configure_tailscale_interactive() {
    echo ""
    echo "$(msg 'setup_tailscale')"
    echo ""
    
    # Check if already connected
    if tailscale status >/dev/null 2>&1; then
        echo "$(msg 'info') Tailscale is already connected"
        tailscale status
        echo ""
        
        if ! ask_yes_no "$(msg 'confirm') Reconfigure Tailscale?"; then
            i18n_info "skipped" "Tailscale configuration"
            return 0
        fi
    fi
    
    # Ask for auth key
    echo "$(msg 'info') You need a Tailscale auth key"
    echo "Get it from: https://login.tailscale.com/admin/settings/keys"
    echo ""
    read -r -p "Enter Tailscale auth key: " auth_key
    
    if [[ -z "$auth_key" ]]; then
        i18n_error "failed" "Auth key cannot be empty"
        return 1
    fi
    
    # Ask for hostname
    local default_hostname
    default_hostname=$(hostname)
    read -r -p "Enter hostname (default: $default_hostname): " hostname
    hostname="${hostname:-$default_hostname}"
    
    # Ask for options
    echo ""
    echo "Tailscale Options:"
    echo ""
    
    local accept_routes="false"
    if ask_yes_no "Accept subnet routes?"; then
        accept_routes="true"
    fi
    
    local accept_dns="false"
    if ask_yes_no "Accept DNS configuration?"; then
        accept_dns="true"
    fi
    
    local advertise_exit="false"
    if ask_yes_no "Advertise as exit node?"; then
        advertise_exit="true"
    fi
    
    local advertise_routes=""
    if ask_yes_no "Advertise subnet routes?"; then
        read -r -p "Enter routes (comma-separated, e.g., 192.168.1.0/24,10.0.0.0/8): " advertise_routes
    fi
    
    # Connect to Tailscale
    connect_tailscale "$auth_key" "$hostname" "$accept_routes" "$accept_dns" "$advertise_exit" "$advertise_routes"
    
    # Save configuration
    save_tailscale_configuration "$hostname" "$accept_routes" "$accept_dns" "$advertise_exit" "$advertise_routes"
}

# Configure Tailscale from file
configure_tailscale_from_file() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        i18n_error "file_not_found" "$config_file"
        return 1
    fi
    
    i18n_info "backup_config" "Loading from $config_file"
    
    # Source configuration file
    source "$config_file"
    
    # Connect to Tailscale
    connect_tailscale \
        "${TAILSCALE_AUTH_KEY}" \
        "${TAILSCALE_HOSTNAME:-$(hostname)}" \
        "${TAILSCALE_ACCEPT_ROUTES:-false}" \
        "${TAILSCALE_ACCEPT_DNS:-false}" \
        "${TAILSCALE_ADVERTISE_EXIT:-false}" \
        "${TAILSCALE_ADVERTISE_ROUTES:-}"
}

# Save Tailscale configuration
save_tailscale_configuration() {
    local hostname="$1"
    local accept_routes="$2"
    local accept_dns="$3"
    local advertise_exit="$4"
    local advertise_routes="$5"
    
    i18n_info "backup_config" "Saving to $TAILSCALE_CONFIG_FILE"
    
    {
        echo "# Tailscale Configuration"
        echo "# Generated: $(date)"
        echo ""
        echo "# Note: Auth key is not saved for security reasons"
        echo "# TAILSCALE_AUTH_KEY=\"your-auth-key-here\""
        echo ""
        echo "TAILSCALE_HOSTNAME=\"$hostname\""
        echo "TAILSCALE_ACCEPT_ROUTES=\"$accept_routes\""
        echo "TAILSCALE_ACCEPT_DNS=\"$accept_dns\""
        echo "TAILSCALE_ADVERTISE_EXIT=\"$advertise_exit\""
        echo "TAILSCALE_ADVERTISE_ROUTES=\"$advertise_routes\""
    } > "$TAILSCALE_CONFIG_FILE"
    
    i18n_success "backup_complete" "$TAILSCALE_CONFIG_FILE"
}

# Show Tailscale status
show_tailscale_status() {
    print_title "$(msg 'setup_tailscale')"
    
    if ! has_cmd tailscale; then
        echo "Tailscale: Not installed"
        return 0
    fi
    
    local version
    version=$(tailscale version | head -1 || echo "unknown")
    echo "Tailscale Version: $version"
    echo ""
    
    if tailscale status >/dev/null 2>&1; then
        echo "Status:"
        tailscale status
        echo ""
        
        echo "IP Addresses:"
        tailscale ip -4 2>/dev/null || echo "  IPv4: Not available"
        tailscale ip -6 2>/dev/null || echo "  IPv6: Not available"
    else
        echo "Status: Not connected"
    fi
    echo ""
}

# Disconnect from Tailscale
disconnect_tailscale() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "info" "Disconnecting from Tailscale"
    
    if $sudo_cmd tailscale down; then
        i18n_success "completed" "Disconnected from Tailscale"
    else
        i18n_error "failed" "Failed to disconnect"
        return 1
    fi
}

# Main function
main() {
    local action="${1:-interactive}"
    local config_file="${2:-}"
    
    print_title "$(msg 'setup_tailscale')"
    
    case "$action" in
        install)
            i18n_info "starting" "Tailscale installation"
            install_tailscale
            start_tailscale_service
            i18n_success "completed" "Tailscale installation"
            ;;
        interactive|config)
            i18n_info "starting" "Tailscale configuration"
            install_tailscale
            start_tailscale_service
            configure_tailscale_interactive
            i18n_success "completed" "Tailscale configuration"
            ;;
        from-file)
            if [[ -z "$config_file" ]]; then
                i18n_error "failed" "Configuration file not specified"
                echo "Usage: $0 from-file <config-file>"
                exit 1
            fi
            i18n_info "starting" "Tailscale configuration from file"
            install_tailscale
            start_tailscale_service
            configure_tailscale_from_file "$config_file"
            i18n_success "completed" "Tailscale configuration"
            ;;
        status|show)
            show_tailscale_status
            ;;
        disconnect|down)
            disconnect_tailscale
            ;;
        *)
            echo "Usage: $0 {install|interactive|from-file|status|disconnect} [config-file]"
            echo ""
            echo "Actions:"
            echo "  install      - Install Tailscale only"
            echo "  interactive  - Install and configure interactively (default)"
            echo "  from-file    - Configure from configuration file"
            echo "  status       - Show Tailscale status"
            echo "  disconnect   - Disconnect from Tailscale network"
            echo ""
            echo "Examples:"
            echo "  $0 install"
            echo "  $0 interactive"
            echo "  $0 from-file /path/to/tailscale-config.conf"
            echo "  $0 status"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
