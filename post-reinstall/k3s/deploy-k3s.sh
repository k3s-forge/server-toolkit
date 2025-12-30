#!/usr/bin/env bash
# deploy-k3s.sh - K3s cluster deployment
# Deploys K3s with Tailscale integration and comprehensive configuration

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load common functions and i18n
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

# K3s configuration
K3S_VERSION="${K3S_VERSION:-latest}"
K3S_INSTALL_SCRIPT_URL="https://get.k3s.io"
K3S_CONFIG_FILE="${K3S_CONFIG_FILE:-$HOME/.server-toolkit-k3s.conf}"

# Download K3s install script
download_k3s_installer() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "download_file" "K3s installer"
    
    if ! curl -sfL "$K3S_INSTALL_SCRIPT_URL" -o /tmp/k3s-install.sh; then
        i18n_error "download_failed" "K3s installer"
        return 1
    fi
    
    chmod +x /tmp/k3s-install.sh
    i18n_success "download_success" "K3s installer"
}

# Install K3s server
install_k3s_server() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "deploying_k3s" "Installing K3s server"
    
    # Check if already installed
    if has_cmd k3s && systemctl is-active k3s >/dev/null 2>&1; then
        local version
        version=$(k3s --version | head -1 || echo "unknown")
        i18n_info "file_exists" "K3s: $version"
        return 0
    fi
    
    # Build install arguments
    local install_args=""
    
    # Disable Traefik by default
    install_args="--disable traefik"
    
    # Cluster initialization
    install_args="$install_args --cluster-init"
    
    # Kubeconfig permissions
    install_args="$install_args --write-kubeconfig-mode 644"
    
    # Tailscale integration
    if has_cmd tailscale && tailscale status &>/dev/null; then
        local ts_ip
        ts_ip=$(tailscale ip -4 2>/dev/null | head -1)
        if [[ -n "$ts_ip" ]]; then
            i18n_info "info" "Tailscale detected, configuring Flannel"
            install_args="$install_args --flannel-iface tailscale0"
            install_args="$install_args --flannel-mtu 1230"
            install_args="$install_args --bind-address $ts_ip"
            install_args="$install_args --tls-san $ts_ip"
        fi
    fi
    
    # Execute installation
    i18n_info "info" "Installing K3s with: $install_args"
    
    if INSTALL_K3S_VERSION="$K3S_VERSION" INSTALL_K3S_EXEC="server $install_args" $sudo_cmd sh /tmp/k3s-install.sh; then
        i18n_success "completed" "K3s server installation"
    else
        i18n_error "failed" "K3s server installation"
        return 1
    fi
    
    # Wait for service to start
    i18n_info "info" "Waiting for K3s to start..."
    sleep 10
    
    # Verify installation
    if systemctl is-active k3s >/dev/null 2>&1; then
        i18n_success "running" "K3s service"
    else
        i18n_error "failed" "K3s service failed to start"
        return 1
    fi
}

# Install K3s agent
install_k3s_agent() {
    local server_url="$1"
    local token="$2"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "deploying_k3s" "Installing K3s agent"
    
    # Check if already installed
    if has_cmd k3s && systemctl is-active k3s-agent >/dev/null 2>&1; then
        i18n_info "file_exists" "K3s agent already running"
        return 0
    fi
    
    # Build install arguments
    local install_args=""
    
    # Tailscale integration
    if has_cmd tailscale && tailscale status &>/dev/null; then
        local ts_ip
        ts_ip=$(tailscale ip -4 2>/dev/null | head -1)
        if [[ -n "$ts_ip" ]]; then
            i18n_info "info" "Tailscale detected, configuring Flannel"
            install_args="--flannel-iface tailscale0"
            install_args="$install_args --node-ip $ts_ip"
        fi
    fi
    
    # Execute installation
    i18n_info "info" "Joining cluster: $server_url"
    
    if K3S_URL="$server_url" K3S_TOKEN="$token" INSTALL_K3S_VERSION="$K3S_VERSION" INSTALL_K3S_EXEC="agent $install_args" $sudo_cmd sh /tmp/k3s-install.sh; then
        i18n_success "completed" "K3s agent installation"
    else
        i18n_error "failed" "K3s agent installation"
        return 1
    fi
    
    # Wait for service to start
    sleep 10
    
    # Verify installation
    if systemctl is-active k3s-agent >/dev/null 2>&1; then
        i18n_success "running" "K3s agent service"
    else
        i18n_error "failed" "K3s agent service failed to start"
        return 1
    fi
}

# Configure kubectl
configure_kubectl() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "info" "Configuring kubectl"
    
    # Create kubeconfig directory
    mkdir -p "$HOME/.kube"
    
    # Copy kubeconfig
    if [[ -f "/etc/rancher/k3s/k3s.yaml" ]]; then
        $sudo_cmd cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
        $sudo_cmd chown $(id -u):$(id -g) "$HOME/.kube/config"
        chmod 600 "$HOME/.kube/config"
        
        i18n_success "completed" "kubectl configuration"
    else
        i18n_warn "file_not_found" "/etc/rancher/k3s/k3s.yaml"
    fi
}

# Save K3s token
save_k3s_token() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    local token_file="/var/lib/rancher/k3s/server/node-token"
    
    if [[ ! -f "$token_file" ]]; then
        i18n_warn "file_not_found" "$token_file"
        return 0
    fi
    
    local token
    token=$($sudo_cmd cat "$token_file")
    
    # Save to config file
    echo "$token" > "$K3S_CONFIG_FILE"
    chmod 600 "$K3S_CONFIG_FILE"
    
    # Display masked token
    local masked_token="${token:0:10}...${token: -10}"
    i18n_info "info" "Token (masked): $masked_token"
    i18n_success "backup_complete" "$K3S_CONFIG_FILE"
    
    # Generate join command
    local server_ip
    if has_cmd tailscale && tailscale status &>/dev/null; then
        server_ip=$(tailscale ip -4 2>/dev/null | head -1)
    else
        server_ip=$(get_primary_ip)
    fi
    
    echo ""
    echo "$(msg 'info') Join command for agent nodes:"
    echo "  K3S_URL=\"https://$server_ip:6443\" K3S_TOKEN=\"\$(cat $K3S_CONFIG_FILE)\" bash $0 agent"
    echo ""
}

# Show K3s status
show_k3s_status() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    print_title "$(msg 'deploy_k3s')"
    
    if ! has_cmd k3s; then
        echo "K3s: Not installed"
        return 0
    fi
    
    local version
    version=$(k3s --version | head -1 || echo "unknown")
    echo "K3s Version: $version"
    echo ""
    
    # Service status
    if systemctl is-active k3s >/dev/null 2>&1; then
        echo "Service: k3s (server) - Running"
    elif systemctl is-active k3s-agent >/dev/null 2>&1; then
        echo "Service: k3s-agent - Running"
    else
        echo "Service: Not running"
        return 0
    fi
    echo ""
    
    # Cluster nodes
    if [[ -f "/etc/rancher/k3s/k3s.yaml" ]]; then
        echo "Cluster Nodes:"
        $sudo_cmd kubectl get nodes -o wide 2>/dev/null || echo "  Unable to get nodes"
        echo ""
        
        echo "System Pods:"
        $sudo_cmd kubectl get pods -A 2>/dev/null || echo "  Unable to get pods"
    fi
    echo ""
}

# Deploy K3s server interactively
deploy_server_interactive() {
    echo ""
    echo "$(msg 'deploy_k3s') - Server Mode"
    echo ""
    
    # Ask for K3s version
    echo "$(msg 'info') K3s version (default: latest)"
    read -r -p "Enter version (e.g., v1.28.5+k3s1) or press Enter for latest: " version
    K3S_VERSION="${version:-latest}"
    
    # Ask about Tailscale
    if has_cmd tailscale && tailscale status &>/dev/null; then
        echo ""
        echo "$(msg 'info') Tailscale detected"
        if ask_yes_no "Use Tailscale for K3s networking?" "y"; then
            i18n_info "info" "K3s will use Tailscale interface"
        fi
    fi
    
    # Download and install
    download_k3s_installer
    install_k3s_server
    configure_kubectl
    save_k3s_token
    
    # Show status
    echo ""
    show_k3s_status
}

# Deploy K3s agent interactively
deploy_agent_interactive() {
    echo ""
    echo "$(msg 'deploy_k3s') - Agent Mode"
    echo ""
    
    # Ask for server URL
    read -r -p "Enter K3s server URL (e.g., https://192.168.1.10:6443): " server_url
    if [[ -z "$server_url" ]]; then
        i18n_error "failed" "Server URL is required"
        return 1
    fi
    
    # Ask for token
    read -r -p "Enter K3s token: " token
    if [[ -z "$token" ]]; then
        i18n_error "failed" "Token is required"
        return 1
    fi
    
    # Ask for K3s version
    echo ""
    echo "$(msg 'info') K3s version (default: latest)"
    read -r -p "Enter version or press Enter for latest: " version
    K3S_VERSION="${version:-latest}"
    
    # Download and install
    download_k3s_installer
    install_k3s_agent "$server_url" "$token"
    
    # Show status
    echo ""
    show_k3s_status
}

# Main function
main() {
    local action="${1:-interactive}"
    local server_url="${2:-}"
    local token="${3:-}"
    
    print_title "$(msg 'deploy_k3s')"
    
    case "$action" in
        server)
            i18n_info "starting" "K3s server deployment"
            download_k3s_installer
            install_k3s_server
            configure_kubectl
            save_k3s_token
            show_k3s_status
            i18n_success "k3s_deployed" "K3s server"
            ;;
        agent)
            if [[ -z "$server_url" ]] || [[ -z "$token" ]]; then
                deploy_agent_interactive
            else
                i18n_info "starting" "K3s agent deployment"
                download_k3s_installer
                install_k3s_agent "$server_url" "$token"
                show_k3s_status
                i18n_success "k3s_deployed" "K3s agent"
            fi
            ;;
        interactive)
            echo "$(msg 'deploy_k3s')"
            echo ""
            echo "1. Deploy K3s Server (first node)"
            echo "2. Deploy K3s Agent (worker node)"
            echo "3. Show K3s Status"
            echo ""
            read -r -p "Select option [1-3]: " choice
            
            case "$choice" in
                1)
                    deploy_server_interactive
                    ;;
                2)
                    deploy_agent_interactive
                    ;;
                3)
                    show_k3s_status
                    ;;
                *)
                    i18n_error "failed" "Invalid option"
                    exit 1
                    ;;
            esac
            ;;
        status|show)
            show_k3s_status
            ;;
        *)
            echo "Usage: $0 {server|agent|interactive|status} [server-url] [token]"
            echo ""
            echo "Actions:"
            echo "  server       - Deploy K3s server (first node)"
            echo "  agent        - Deploy K3s agent (worker node)"
            echo "  interactive  - Interactive deployment (default)"
            echo "  status       - Show K3s status"
            echo ""
            echo "Examples:"
            echo "  $0 server"
            echo "  $0 agent https://192.168.1.10:6443 K10abc..."
            echo "  $0 interactive"
            echo "  $0 status"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
