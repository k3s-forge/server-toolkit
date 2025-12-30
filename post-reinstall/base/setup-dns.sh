#!/usr/bin/env bash
# setup-dns.sh - DNS configuration tool
# Configures DNS servers and search domains

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load common functions and i18n
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

# Common DNS servers
declare -A DNS_SERVERS=(
    ["google"]="8.8.8.8,8.8.4.4"
    ["cloudflare"]="1.1.1.1,1.0.0.1"
    ["quad9"]="9.9.9.9,149.112.112.112"
    ["opendns"]="208.67.222.222,208.67.220.220"
)

# Detect DNS management system
detect_dns_system() {
    local system="unknown"
    
    # Check for systemd-resolved
    if systemctl is-active systemd-resolved >/dev/null 2>&1; then
        system="systemd-resolved"
    # Check for NetworkManager
    elif has_cmd nmcli && nmcli -t -f RUNNING general 2>/dev/null | grep -qi running; then
        system="networkmanager"
    # Check for resolvconf
    elif has_cmd resolvconf; then
        system="resolvconf"
    # Traditional /etc/resolv.conf
    elif [[ -f /etc/resolv.conf ]] && [[ ! -L /etc/resolv.conf ]]; then
        system="resolv.conf"
    fi
    
    echo "$system"
}

# Configure DNS using systemd-resolved
configure_dns_systemd_resolved() {
    local dns_servers="$1"
    local search_domains="${2:-}"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "configuring_dns" "systemd-resolved"
    
    # Create resolved.conf.d directory if not exists
    $sudo_cmd mkdir -p /etc/systemd/resolved.conf.d
    
    # Create DNS configuration
    local config_file="/etc/systemd/resolved.conf.d/dns.conf"
    
    {
        echo "[Resolve]"
        echo "DNS=$dns_servers"
        [[ -n "$search_domains" ]] && echo "Domains=$search_domains"
        echo "FallbackDNS=8.8.8.8 1.1.1.1"
        echo "DNSSEC=allow-downgrade"
        echo "DNSOverTLS=opportunistic"
    } | $sudo_cmd tee "$config_file" >/dev/null
    
    # Restart systemd-resolved
    $sudo_cmd systemctl restart systemd-resolved
    
    i18n_success "dns_configured" "systemd-resolved"
}

# Configure DNS using NetworkManager
configure_dns_networkmanager() {
    local dns_servers="$1"
    local search_domains="${2:-}"
    
    i18n_info "configuring_dns" "NetworkManager"
    
    # Get active connection
    local connection
    connection=$(nmcli -t -f NAME connection show --active | head -1)
    
    if [[ -z "$connection" ]]; then
        i18n_error "failed" "No active NetworkManager connection"
        return 1
    fi
    
    # Set DNS servers
    IFS=',' read -ra dns_array <<< "$dns_servers"
    nmcli connection modify "$connection" ipv4.dns "${dns_array[*]}"
    nmcli connection modify "$connection" ipv4.ignore-auto-dns yes
    
    # Set search domains
    if [[ -n "$search_domains" ]]; then
        IFS=',' read -ra domain_array <<< "$search_domains"
        nmcli connection modify "$connection" ipv4.dns-search "${domain_array[*]}"
    fi
    
    # Restart connection
    nmcli connection down "$connection" >/dev/null 2>&1 || true
    nmcli connection up "$connection" >/dev/null 2>&1
    
    i18n_success "dns_configured" "NetworkManager"
}

# Configure DNS using /etc/resolv.conf
configure_dns_resolv_conf() {
    local dns_servers="$1"
    local search_domains="${2:-}"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "configuring_dns" "/etc/resolv.conf"
    
    # Backup resolv.conf
    $sudo_cmd cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    # Create new resolv.conf
    {
        [[ -n "$search_domains" ]] && echo "search $search_domains"
        IFS=',' read -ra dns_array <<< "$dns_servers"
        for dns in "${dns_array[@]}"; do
            echo "nameserver $dns"
        done
    } | $sudo_cmd tee /etc/resolv.conf >/dev/null
    
    # Make it immutable (optional)
    if has_cmd chattr; then
        $sudo_cmd chattr +i /etc/resolv.conf 2>/dev/null || true
    fi
    
    i18n_success "dns_configured" "/etc/resolv.conf"
}

# Configure DNS interactively
configure_dns_interactive() {
    echo ""
    echo "$(msg 'setup_dns')"
    echo ""
    
    # Show current DNS servers
    echo "$(msg 'info') Current DNS servers:"
    if [[ -f /etc/resolv.conf ]]; then
        grep "^nameserver" /etc/resolv.conf || echo "  None"
    fi
    echo ""
    
    # Show DNS system
    local dns_system
    dns_system=$(detect_dns_system)
    echo "$(msg 'info') DNS management system: $dns_system"
    echo ""
    
    # Ask for DNS provider
    echo "Choose DNS provider:"
    echo "  1) Google DNS (8.8.8.8, 8.8.4.4)"
    echo "  2) Cloudflare DNS (1.1.1.1, 1.0.0.1)"
    echo "  3) Quad9 DNS (9.9.9.9, 149.112.112.112)"
    echo "  4) OpenDNS (208.67.222.222, 208.67.220.220)"
    echo "  5) Custom DNS servers"
    echo "  6) Keep current DNS"
    echo ""
    
    read -r -p "Select option [1-6]: " choice
    
    local dns_servers=""
    
    case "$choice" in
        1) dns_servers="${DNS_SERVERS[google]}" ;;
        2) dns_servers="${DNS_SERVERS[cloudflare]}" ;;
        3) dns_servers="${DNS_SERVERS[quad9]}" ;;
        4) dns_servers="${DNS_SERVERS[opendns]}" ;;
        5)
            read -r -p "Enter DNS servers (comma-separated): " dns_servers
            if [[ -z "$dns_servers" ]]; then
                i18n_error "failed" "DNS servers cannot be empty"
                return 1
            fi
            ;;
        6)
            i18n_info "skipped" "Keeping current DNS configuration"
            return 0
            ;;
        *)
            i18n_error "failed" "Invalid choice"
            return 1
            ;;
    esac
    
    # Ask for search domains
    echo ""
    read -r -p "Enter search domains (comma-separated, or press Enter to skip): " search_domains
    
    # Configure DNS based on system
    case "$dns_system" in
        systemd-resolved)
            configure_dns_systemd_resolved "$dns_servers" "$search_domains"
            ;;
        networkmanager)
            configure_dns_networkmanager "$dns_servers" "$search_domains"
            ;;
        *)
            configure_dns_resolv_conf "$dns_servers" "$search_domains"
            ;;
    esac
}

# Configure DNS from parameters
configure_dns_direct() {
    local dns_servers="$1"
    local search_domains="${2:-}"
    
    if [[ -z "$dns_servers" ]]; then
        i18n_error "failed" "DNS servers not specified"
        return 1
    fi
    
    local dns_system
    dns_system=$(detect_dns_system)
    
    i18n_info "configuring_dns" "DNS system: $dns_system"
    
    case "$dns_system" in
        systemd-resolved)
            configure_dns_systemd_resolved "$dns_servers" "$search_domains"
            ;;
        networkmanager)
            configure_dns_networkmanager "$dns_servers" "$search_domains"
            ;;
        *)
            configure_dns_resolv_conf "$dns_servers" "$search_domains"
            ;;
    esac
}

# Show current DNS configuration
show_dns_configuration() {
    print_title "$(msg 'setup_dns')"
    
    local dns_system
    dns_system=$(detect_dns_system)
    
    echo "DNS Management System: $dns_system"
    echo ""
    
    echo "Current DNS Servers:"
    if [[ -f /etc/resolv.conf ]]; then
        grep "^nameserver" /etc/resolv.conf || echo "  None"
    fi
    echo ""
    
    echo "Search Domains:"
    if [[ -f /etc/resolv.conf ]]; then
        grep "^search" /etc/resolv.conf || echo "  None"
    fi
    echo ""
    
    # Test DNS resolution
    echo "Testing DNS resolution:"
    if host google.com >/dev/null 2>&1; then
        echo "  ✓ DNS resolution working"
    else
        echo "  ✗ DNS resolution failed"
    fi
    echo ""
}

# Main function
main() {
    local action="${1:-interactive}"
    local dns_servers="${2:-}"
    local search_domains="${3:-}"
    
    print_title "$(msg 'setup_dns')"
    
    case "$action" in
        interactive|config)
            i18n_info "starting" "DNS configuration"
            configure_dns_interactive
            i18n_success "completed" "DNS configuration"
            ;;
        set)
            if [[ -z "$dns_servers" ]]; then
                i18n_error "failed" "DNS servers not specified"
                echo "Usage: $0 set <dns-servers> [search-domains]"
                echo "Example: $0 set 8.8.8.8,8.8.4.4 example.com,local"
                exit 1
            fi
            i18n_info "starting" "DNS configuration"
            configure_dns_direct "$dns_servers" "$search_domains"
            i18n_success "completed" "DNS configuration"
            ;;
        show)
            show_dns_configuration
            ;;
        *)
            echo "Usage: $0 {interactive|set|show} [dns-servers] [search-domains]"
            echo ""
            echo "Actions:"
            echo "  interactive  - Configure DNS interactively (default)"
            echo "  set          - Set DNS servers directly"
            echo "  show         - Show current DNS configuration"
            echo ""
            echo "Examples:"
            echo "  $0 interactive"
            echo "  $0 set 8.8.8.8,8.8.4.4"
            echo "  $0 set 1.1.1.1,1.0.0.1 example.com,local"
            echo "  $0 show"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
