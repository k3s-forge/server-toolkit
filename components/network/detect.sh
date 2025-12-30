#!/usr/bin/env bash
# components/network/detect.sh - Detect network configuration

set -Eeuo pipefail

# Load common functions
if [[ -n "${SCRIPT_DIR:-}" ]] && [[ -f "$SCRIPT_DIR/utils/common.sh" ]]; then
    source "$SCRIPT_DIR/utils/common.sh"
else
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TOOLKIT_ROOT="$(cd "$CURRENT_DIR/../.." && pwd)"
    
    if [[ -f "$TOOLKIT_ROOT/utils/common.sh" ]]; then
        source "$TOOLKIT_ROOT/utils/common.sh"
    fi
fi

# Detect primary network interface
detect_interface() {
    local interface=""
    
    if command -v ip >/dev/null 2>&1; then
        # Method 1: Get from default route
        interface=$(ip route show default 2>/dev/null | head -1 | grep -oP 'dev \K\w+' || echo "")
        
        # Method 2: Get first non-loopback interface
        if [[ -z "$interface" ]]; then
            interface=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -1 | tr -d ' ' || echo "")
        fi
    fi
    
    # Fallback to common interface names
    if [[ -z "$interface" ]]; then
        local common_interfaces=("eth0" "ens3" "ens33" "enp0s3" "ens18")
        for iface in "${common_interfaces[@]}"; do
            if [[ -d "/sys/class/net/$iface" ]]; then
                interface="$iface"
                break
            fi
        done
    fi
    
    echo "${interface:-unknown}"
}

# Detect IP address
detect_ip() {
    local interface="${1:-}"
    local ip=""
    
    if command -v ip >/dev/null 2>&1; then
        if [[ -n "$interface" && "$interface" != "unknown" ]]; then
            # Get IP from specific interface
            ip=$(ip -4 addr show "$interface" 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1 || echo "")
        else
            # Get source IP from default route
            ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[\d.]+' | head -1 || echo "")
        fi
    fi
    
    # Fallback: use hostname command
    if [[ -z "$ip" ]]; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
    fi
    
    # Ensure not returning loopback
    if [[ "$ip" =~ ^127\. ]]; then
        ip=""
    fi
    
    echo "${ip:-unknown}"
}

# Detect netmask/CIDR
detect_netmask() {
    local interface="${1:-}"
    local netmask=""
    
    if [[ -z "$interface" || "$interface" == "unknown" ]]; then
        echo "24"
        return
    fi
    
    if command -v ip >/dev/null 2>&1; then
        # Get CIDR notation
        netmask=$(ip -4 addr show "$interface" 2>/dev/null | grep -oP 'inet [\d.]+/\K\d+' | head -1 || echo "")
    fi
    
    echo "${netmask:-24}"
}

# Detect gateway
detect_gateway() {
    local gateway=""
    
    if command -v ip >/dev/null 2>&1; then
        gateway=$(ip route show default 2>/dev/null | grep -oP 'via \K[\d.]+' | head -1 || echo "")
    elif command -v netstat >/dev/null 2>&1; then
        gateway=$(netstat -rn 2>/dev/null | awk '/^0.0.0.0/ {print $2}' | head -1 || echo "")
    fi
    
    echo "${gateway:-unknown}"
}

# Detect DNS servers
detect_dns() {
    local dns_servers=""
    
    if [[ -f /etc/resolv.conf ]]; then
        dns_servers=$(grep "^nameserver" /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//')
    fi
    
    # Fallback to common DNS
    if [[ -z "$dns_servers" ]]; then
        dns_servers="8.8.8.8 8.8.4.4"
    fi
    
    echo "$dns_servers"
}

# Detect all network interfaces
detect_all_interfaces() {
    if command -v ip >/dev/null 2>&1; then
        ip -o link show | awk -F': ' '{print $2}' | grep -v lo
    else
        ls /sys/class/net/ | grep -v lo
    fi
}

# Get interface MAC address
get_mac_address() {
    local interface="$1"
    
    if [[ -f "/sys/class/net/$interface/address" ]]; then
        cat "/sys/class/net/$interface/address"
    else
        echo "unknown"
    fi
}

# Detect complete network configuration
detect_all() {
    local interface gateway ip netmask dns mac
    
    interface=$(detect_interface)
    ip=$(detect_ip "$interface")
    netmask=$(detect_netmask "$interface")
    gateway=$(detect_gateway)
    dns=$(detect_dns)
    mac=$(get_mac_address "$interface")
    
    cat << EOF
{
  "interface": "$interface",
  "ip": "$ip",
  "netmask": "$netmask",
  "cidr": "$ip/$netmask",
  "gateway": "$gateway",
  "dns": "$dns",
  "mac": "$mac"
}
EOF
}

# Output in different formats
output_json() {
    detect_all
}

output_env() {
    local interface gateway ip netmask dns mac
    
    interface=$(detect_interface)
    ip=$(detect_ip "$interface")
    netmask=$(detect_netmask "$interface")
    gateway=$(detect_gateway)
    dns=$(detect_dns)
    mac=$(get_mac_address "$interface")
    
    cat << EOF
NETWORK_INTERFACE="$interface"
NETWORK_IP="$ip"
NETWORK_NETMASK="$netmask"
NETWORK_CIDR="$ip/$netmask"
NETWORK_GATEWAY="$gateway"
NETWORK_DNS="$dns"
NETWORK_MAC="$mac"
EOF
}

output_human() {
    local interface gateway ip netmask dns mac
    
    interface=$(detect_interface)
    ip=$(detect_ip "$interface")
    netmask=$(detect_netmask "$interface")
    gateway=$(detect_gateway)
    dns=$(detect_dns)
    mac=$(get_mac_address "$interface")
    
    echo "Network Configuration:"
    echo "  Interface: $interface"
    echo "  IP Address: $ip/$netmask"
    echo "  Gateway: $gateway"
    echo "  DNS Servers: $dns"
    echo "  MAC Address: $mac"
}

# Main function
main() {
    local format="${1:-human}"
    
    case "$format" in
        json)
            output_json
            ;;
        env)
            output_env
            ;;
        human)
            output_human
            ;;
        interface)
            detect_interface
            ;;
        ip)
            detect_ip "$(detect_interface)"
            ;;
        gateway)
            detect_gateway
            ;;
        dns)
            detect_dns
            ;;
        *)
            echo "Usage: $0 {json|env|human|interface|ip|gateway|dns}"
            echo ""
            echo "Formats:"
            echo "  json      - Output as JSON"
            echo "  env       - Output as environment variables"
            echo "  human     - Human-readable format (default)"
            echo "  interface - Only interface name"
            echo "  ip        - Only IP address"
            echo "  gateway   - Only gateway"
            echo "  dns       - Only DNS servers"
            exit 1
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
