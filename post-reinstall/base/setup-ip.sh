#!/usr/bin/env bash
# setup-ip.sh - IP address configuration tool
# Configures IPv4 and IPv6 addresses on network interfaces

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load common functions and i18n
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

# Configuration
IP_CONFIG_FILE="${IP_CONFIG_FILE:-$HOME/.server-toolkit-ip.conf}"

# Detect network backend
detect_network_backend() {
    local backend="unknown"
    
    # Check for netplan
    if compgen -G "/etc/netplan/*.yaml" >/dev/null 2>&1; then
        backend="netplan"
    # Check for NetworkManager
    elif has_cmd nmcli && nmcli -t -f RUNNING general 2>/dev/null | grep -qi running; then
        backend="networkmanager"
    # Check for systemd-networkd
    elif systemctl is-active systemd-networkd >/dev/null 2>&1; then
        backend="systemd-networkd"
    # Check for ifcfg (RHEL/CentOS)
    elif ls /etc/sysconfig/network-scripts/ifcfg-* >/dev/null 2>&1; then
        backend="ifcfg"
    fi
    
    echo "$backend"
}

# Get primary interface
get_target_interface() {
    local interface=""
    
    # Try to get from default route
    if has_cmd ip; then
        interface=$(ip route show default 2>/dev/null | head -1 | grep -oP 'dev \K\w+' || echo "")
    fi
    
    # Fallback to first non-loopback interface
    if [[ -z "$interface" ]]; then
        interface=$(ip -o link show | awk -F': ' '$2!="lo"{print $2; exit}')
    fi
    
    echo "$interface"
}

# Add IPv4 address
add_ipv4_address() {
    local interface="$1"
    local ip_address="$2"
    local prefix="${3:-24}"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    # Check if IP already exists
    if ip -4 addr show dev "$interface" | grep -qw "$ip_address"; then
        i18n_info "file_exists" "IPv4: $ip_address"
        return 0
    fi
    
    i18n_info "configuring_ip" "IPv4: $ip_address/$prefix"
    
    # Add IP address
    if $sudo_cmd ip -4 addr add "$ip_address/$prefix" dev "$interface" 2>/dev/null; then
        i18n_success "ip_configured" "IPv4: $ip_address/$prefix"
        return 0
    else
        i18n_error "failed" "Failed to add IPv4: $ip_address/$prefix"
        return 1
    fi
}

# Add IPv6 address
add_ipv6_address() {
    local interface="$1"
    local ip_address="$2"
    local prefix="${3:-64}"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    # Check if IP already exists
    if ip -6 addr show dev "$interface" | grep -qw "$ip_address"; then
        i18n_info "file_exists" "IPv6: $ip_address"
        return 0
    fi
    
    i18n_info "configuring_ip" "IPv6: $ip_address/$prefix"
    
    # Add IP address
    if $sudo_cmd ip -6 addr add "$ip_address/$prefix" dev "$interface" 2>/dev/null; then
        i18n_success "ip_configured" "IPv6: $ip_address/$prefix"
        return 0
    else
        i18n_error "failed" "Failed to add IPv6: $ip_address/$prefix"
        return 1
    fi
}

# Remove IPv4 address
remove_ipv4_address() {
    local interface="$1"
    local ip_address="$2"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    # Get full CIDR from system
    local cidr
    cidr=$(ip -4 addr show dev "$interface" | grep -oP "inet \K$ip_address/[0-9]+" | head -1)
    
    if [[ -z "$cidr" ]]; then
        i18n_warn "file_not_found" "IPv4: $ip_address"
        return 0
    fi
    
    i18n_info "delete_file" "IPv4: $cidr"
    
    if $sudo_cmd ip -4 addr del "$cidr" dev "$interface" 2>/dev/null; then
        i18n_success "completed" "Removed IPv4: $cidr"
        return 0
    else
        i18n_error "failed" "Failed to remove IPv4: $cidr"
        return 1
    fi
}

# Configure IP addresses interactively
configure_ip_interactive() {
    local interface
    interface=$(get_target_interface)
    
    if [[ -z "$interface" ]]; then
        i18n_error "failed" "Cannot detect network interface"
        return 1
    fi
    
    i18n_info "detect_network" "Interface: $interface"
    
    # Show current IP addresses
    echo ""
    echo "$(msg 'info') Current IPv4 addresses:"
    ip -4 addr show dev "$interface" | grep -oP 'inet \K[\d.]+/\d+' || echo "  None"
    echo ""
    echo "$(msg 'info') Current IPv6 addresses:"
    ip -6 addr show dev "$interface" | grep -oP 'inet6 \K[a-f0-9:]+/\d+' | grep -v '^fe80:' || echo "  None"
    echo ""
    
    # Ask for IPv4 addresses
    echo "$(msg 'setup_ip') - IPv4"
    read -r -p "Enter IPv4 addresses (comma-separated, or press Enter to skip): " ipv4_input
    
    if [[ -n "$ipv4_input" ]]; then
        IFS=',' read -ra ipv4_array <<< "$ipv4_input"
        for ip in "${ipv4_array[@]}"; do
            ip=$(echo "$ip" | tr -d ' ')
            [[ -z "$ip" ]] && continue
            
            # Parse IP and prefix
            if [[ "$ip" =~ ^([0-9.]+)/([0-9]+)$ ]]; then
                add_ipv4_address "$interface" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
            else
                add_ipv4_address "$interface" "$ip" "24"
            fi
        done
    fi
    
    # Ask for IPv6 addresses
    echo ""
    echo "$(msg 'setup_ip') - IPv6"
    read -r -p "Enter IPv6 addresses (comma-separated, or press Enter to skip): " ipv6_input
    
    if [[ -n "$ipv6_input" ]]; then
        IFS=',' read -ra ipv6_array <<< "$ipv6_input"
        for ip in "${ipv6_array[@]}"; do
            ip=$(echo "$ip" | tr -d ' ')
            [[ -z "$ip" ]] && continue
            
            # Parse IP and prefix
            if [[ "$ip" =~ ^([a-f0-9:]+)/([0-9]+)$ ]]; then
                add_ipv6_address "$interface" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
            else
                add_ipv6_address "$interface" "$ip" "64"
            fi
        done
    fi
    
    # Save configuration
    save_ip_configuration "$interface"
}

# Configure IP addresses from file
configure_ip_from_file() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        i18n_error "file_not_found" "$config_file"
        return 1
    fi
    
    i18n_info "backup_config" "Loading from $config_file"
    
    # Source configuration file
    source "$config_file"
    
    local interface="${INTERFACE:-$(get_target_interface)}"
    
    # Configure IPv4 addresses
    if [[ -n "${IPV4_ADDRESSES:-}" ]]; then
        IFS=',' read -ra ipv4_array <<< "$IPV4_ADDRESSES"
        for ip in "${ipv4_array[@]}"; do
            [[ -z "$ip" ]] && continue
            if [[ "$ip" =~ ^([0-9.]+)/([0-9]+)$ ]]; then
                add_ipv4_address "$interface" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
            else
                add_ipv4_address "$interface" "$ip" "${IPV4_PREFIX:-24}"
            fi
        done
    fi
    
    # Configure IPv6 addresses
    if [[ -n "${IPV6_ADDRESSES:-}" ]]; then
        IFS=',' read -ra ipv6_array <<< "$IPV6_ADDRESSES"
        for ip in "${ipv6_array[@]}"; do
            [[ -z "$ip" ]] && continue
            if [[ "$ip" =~ ^([a-f0-9:]+)/([0-9]+)$ ]]; then
                add_ipv6_address "$interface" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
            else
                add_ipv6_address "$interface" "$ip" "${IPV6_PREFIX:-64}"
            fi
        done
    fi
}

# Save IP configuration
save_ip_configuration() {
    local interface="$1"
    
    i18n_info "backup_config" "Saving to $IP_CONFIG_FILE"
    
    {
        echo "# IP Configuration"
        echo "# Generated: $(date)"
        echo ""
        echo "INTERFACE=\"$interface\""
        echo ""
        echo "# IPv4 Addresses (comma-separated)"
        local ipv4_list
        ipv4_list=$(ip -4 addr show dev "$interface" | grep -oP 'inet \K[\d.]+/\d+' | tr '\n' ',' | sed 's/,$//')
        echo "IPV4_ADDRESSES=\"$ipv4_list\""
        echo "IPV4_PREFIX=\"24\""
        echo ""
        echo "# IPv6 Addresses (comma-separated)"
        local ipv6_list
        ipv6_list=$(ip -6 addr show dev "$interface" | grep -oP 'inet6 \K[a-f0-9:]+/\d+' | grep -v '^fe80:' | tr '\n' ',' | sed 's/,$//')
        echo "IPV6_ADDRESSES=\"$ipv6_list\""
        echo "IPV6_PREFIX=\"64\""
    } > "$IP_CONFIG_FILE"
    
    i18n_success "backup_complete" "$IP_CONFIG_FILE"
}

# Show current IP configuration
show_ip_configuration() {
    local interface
    interface=$(get_target_interface)
    
    print_title "$(msg 'setup_ip')"
    
    echo "$(msg 'info') Interface: $interface"
    echo ""
    
    echo "IPv4 Addresses:"
    ip -4 addr show dev "$interface" | grep -oP 'inet \K[\d.]+/\d+' || echo "  None"
    echo ""
    
    echo "IPv6 Addresses:"
    ip -6 addr show dev "$interface" | grep -oP 'inet6 \K[a-f0-9:]+/\d+' | grep -v '^fe80:' || echo "  None"
    echo ""
    
    # Show network backend
    local backend
    backend=$(detect_network_backend)
    echo "Network Backend: $backend"
    echo ""
}

# Main function
main() {
    local action="${1:-interactive}"
    local config_file="${2:-}"
    
    print_title "$(msg 'setup_ip')"
    
    case "$action" in
        interactive|config)
            i18n_info "starting" "IP address configuration"
            configure_ip_interactive
            i18n_success "completed" "IP address configuration"
            ;;
        from-file)
            if [[ -z "$config_file" ]]; then
                i18n_error "failed" "Configuration file not specified"
                echo "Usage: $0 from-file <config-file>"
                exit 1
            fi
            i18n_info "starting" "IP address configuration from file"
            configure_ip_from_file "$config_file"
            i18n_success "completed" "IP address configuration"
            ;;
        show)
            show_ip_configuration
            ;;
        *)
            echo "Usage: $0 {interactive|from-file|show} [config-file]"
            echo ""
            echo "Actions:"
            echo "  interactive  - Configure IP addresses interactively (default)"
            echo "  from-file    - Configure from configuration file"
            echo "  show         - Show current IP configuration"
            echo ""
            echo "Examples:"
            echo "  $0 interactive"
            echo "  $0 from-file /path/to/ip-config.conf"
            echo "  $0 show"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
