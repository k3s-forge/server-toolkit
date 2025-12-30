#!/usr/bin/env bash
# plan-network.sh - Network planning tool
# Plans network configuration for new system

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load common functions
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

# Plan file
PLAN_FILE="${PLAN_FILE:-$HOME/network-plan-$(date +%Y%m%d_%H%M%S).txt}"

# Detect current network configuration
detect_current_network() {
    i18n_info "detect_network"
    
    local primary_interface primary_ip
    primary_interface=$(get_primary_interface)
    primary_ip=$(get_primary_ip)
    
    echo "primary_interface='$primary_interface'"
    echo "primary_ip='$primary_ip'"
}

# Plan IP addresses
plan_ip_addresses() {
    i18n_info "planning_network" "IP addresses"
    
    local plan_section=""
    
    # Get current IP configuration
    local primary_interface primary_ip
    primary_interface=$(get_primary_interface)
    primary_ip=$(get_primary_ip)
    
    plan_section+="=== IP Address Configuration ===\n"
    plan_section+="Current Interface: $primary_interface\n"
    plan_section+="Current IP: $primary_ip\n"
    plan_section+="\n"
    
    # Get all IP addresses
    if has_cmd ip; then
        plan_section+="All IPv4 Addresses:\n"
        ip -4 addr show | grep -oP 'inet \K[\d.]+/\d+' | while read -r addr; do
            plan_section+="  - $addr\n"
        done
        plan_section+="\n"
        
        plan_section+="All IPv6 Addresses:\n"
        ip -6 addr show | grep -oP 'inet6 \K[a-f0-9:]+/\d+' | grep -v '^fe80:' | while read -r addr; do
            plan_section+="  - $addr\n"
        done
        plan_section+="\n"
    fi
    
    # Recommendations
    plan_section+="Recommendations:\n"
    plan_section+="  - Keep current IP: $primary_ip\n"
    plan_section+="  - Or assign new static IP\n"
    plan_section+="  - Configure gateway and DNS\n"
    plan_section+="\n"
    
    echo -e "$plan_section"
}

# Plan hostname
plan_hostname() {
    i18n_info "planning_network" "Hostname"
    
    local plan_section=""
    local current_hostname
    current_hostname=$(hostname -f 2>/dev/null || hostname)
    
    plan_section+="=== Hostname Configuration ===\n"
    plan_section+="Current Hostname: $current_hostname\n"
    plan_section+="\n"
    
    # Generate suggested hostname with geo-location
    local suggested_hostname=""
    
    # Try to get public IP for geo-location
    if check_network "8.8.8.8" "53" "3"; then
        local public_ip
        public_ip=$(curl -fsSL --connect-timeout 3 --max-time 6 "https://api.ipify.org" 2>/dev/null || echo "")
        
        if [[ -n "$public_ip" ]]; then
            # Try to get geo-location
            local geo_info
            geo_info=$(curl -fsSL --connect-timeout 3 --max-time 6 "http://ip-api.com/json/$public_ip?fields=status,country,countryCode,region,city" 2>/dev/null || echo "")
            
            if [[ -n "$geo_info" ]] && echo "$geo_info" | grep -q '"status":"success"'; then
                local country_code region city
                country_code=$(echo "$geo_info" | grep -oP '"countryCode":"\K[^"]+' || echo "")
                region=$(echo "$geo_info" | grep -oP '"region":"\K[^"]+' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' || echo "")
                city=$(echo "$geo_info" | grep -oP '"city":"\K[^"]+' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' || echo "")
                
                if [[ -n "$country_code" && -n "$city" ]]; then
                    suggested_hostname="server-${country_code,,}-${city}-$(date +%s | tail -c 5)"
                fi
            fi
        fi
    fi
    
    if [[ -z "$suggested_hostname" ]]; then
        suggested_hostname="server-$(date +%s | tail -c 8)"
    fi
    
    plan_section+="Suggested Hostname: $suggested_hostname\n"
    plan_section+="\n"
    plan_section+="Hostname Format:\n"
    plan_section+="  - Use lowercase letters, numbers, and hyphens\n"
    plan_section+="  - Start with a letter\n"
    plan_section+="  - Maximum 63 characters\n"
    plan_section+="\n"
    
    echo -e "$plan_section"
}

# Plan DNS configuration
plan_dns() {
    i18n_info "planning_network" "DNS"
    
    local plan_section=""
    
    plan_section+="=== DNS Configuration ===\n"
    
    # Current DNS servers
    if [[ -f /etc/resolv.conf ]]; then
        plan_section+="Current DNS Servers:\n"
        grep "^nameserver" /etc/resolv.conf | while read -r line; do
            plan_section+="  - $line\n"
        done
        plan_section+="\n"
    fi
    
    # Recommended DNS servers
    plan_section+="Recommended DNS Servers:\n"
    plan_section+="  Public DNS:\n"
    plan_section+="    - Google: 8.8.8.8, 8.8.4.4\n"
    plan_section+="    - Cloudflare: 1.1.1.1, 1.0.0.1\n"
    plan_section+="    - Quad9: 9.9.9.9, 149.112.112.112\n"
    plan_section+="  Or use your ISP's DNS servers\n"
    plan_section+="\n"
    
    echo -e "$plan_section"
}

# Plan network topology
plan_topology() {
    i18n_info "planning_network" "Network topology"
    
    local plan_section=""
    
    plan_section+="=== Network Topology ===\n"
    
    # Get default gateway
    if has_cmd ip; then
        local gateway
        gateway=$(ip route show default | grep -oP 'via \K[\d.]+' | head -1 || echo "unknown")
        plan_section+="Default Gateway: $gateway\n"
    fi
    
    # Get network interfaces
    plan_section+="\nNetwork Interfaces:\n"
    if has_cmd ip; then
        ip -o link show | awk -F': ' '{print $2}' | grep -v lo | while read -r iface; do
            local state
            state=$(ip link show "$iface" | grep -oP 'state \K\w+' || echo "unknown")
            plan_section+="  - $iface (state: $state)\n"
        done
    fi
    plan_section+="\n"
    
    # Recommendations
    plan_section+="Recommendations:\n"
    plan_section+="  - Use static IP for servers\n"
    plan_section+="  - Configure firewall rules\n"
    plan_section+="  - Consider using Tailscale for secure networking\n"
    plan_section+="\n"
    
    echo -e "$plan_section"
}

# Create network plan
create_network_plan() {
    {
        echo "=== Network Configuration Plan ==="
        echo "Generated: $(date)"
        echo ""
        
        plan_ip_addresses
        plan_hostname
        plan_dns
        plan_topology
        
        echo "=== Next Steps ==="
        echo "1. Review this network plan"
        echo "2. Prepare network configuration parameters"
        echo "3. Use post-reinstall tools to apply configuration"
        echo ""
        echo "=== Post-Reinstall Tools ==="
        echo "- setup-ip.sh: Configure IP addresses"
        echo "- setup-hostname.sh: Configure hostname"
        echo "- setup-dns.sh: Configure DNS servers"
        echo "- setup-tailscale.sh: Setup Tailscale (optional)"
        echo ""
    } > "$PLAN_FILE"
    
    i18n_info "report_saved" "$PLAN_FILE"
}

# Main function
main() {
    local custom_plan_file="${1:-}"
    
    if [[ -n "$custom_plan_file" ]]; then
        PLAN_FILE="$custom_plan_file"
    fi
    
    print_title "$(msg 'network_planning')"
    
    i18n_info "starting" "Network planning"
    
    # Create network plan
    create_network_plan
    
    # Display plan
    cat "$PLAN_FILE"
    
    i18n_success "plan_complete"
    echo ""
    echo "$(msg 'report_saved'): $PLAN_FILE"
    echo ""
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
