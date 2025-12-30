#!/usr/bin/env bash
# workflows/export-config.sh - Export system configuration as config code

set -Eeuo pipefail

# Load common header
if [[ -n "${SCRIPT_DIR:-}" ]] && [[ -f "$SCRIPT_DIR/utils/common-header.sh" ]]; then
    source "$SCRIPT_DIR/utils/common-header.sh"
else
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TOOLKIT_ROOT="$(cd "$CURRENT_DIR/.." && pwd)"
    
    if [[ -f "$TOOLKIT_ROOT/utils/common.sh" ]]; then
        source "$TOOLKIT_ROOT/utils/common.sh"
    fi
    
    if [[ -f "$TOOLKIT_ROOT/utils/i18n.sh" ]]; then
        source "$TOOLKIT_ROOT/utils/i18n.sh"
    fi
    
    if [[ -f "$TOOLKIT_ROOT/utils/config-codec.sh" ]]; then
        source "$TOOLKIT_ROOT/utils/config-codec.sh"
    fi
fi

# Check for jq
check_dependencies() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed" >&2
        echo "Install: apt-get install jq  or  yum install jq" >&2
        return 1
    fi
    return 0
}

# Detect and export current configuration
export_current_config() {
    echo "Detecting current system configuration..."
    echo ""
    
    # Create base config
    local config
    config=$(create_config "1.0")
    
    # Detect hostname
    local hostname_short hostname_fqdn
    hostname_short=$(hostname -s 2>/dev/null || hostname)
    hostname_fqdn=$(hostname -f 2>/dev/null || hostname)
    
    echo "Hostname:"
    echo "  Short: $hostname_short"
    echo "  FQDN:  $hostname_fqdn"
    
    # Add hostname to config
    config=$(add_hostname_to_config "$config" "$hostname_short" "$hostname_fqdn" "false")
    
    # Detect network
    local network_script="$TOOLKIT_ROOT/components/network/detect.sh"
    if [[ -f "$network_script" ]]; then
        local net_info
        net_info=$(bash "$network_script" json)
        
        local interface ip gateway dns
        interface=$(echo "$net_info" | jq -r '.interface')
        ip=$(echo "$net_info" | jq -r '.cidr')
        gateway=$(echo "$net_info" | jq -r '.gateway')
        dns=$(echo "$net_info" | jq -r '.dns')
        
        echo "Network: $ip via $gateway"
        
        # Add network to config
        config=$(add_network_to_config "$config" "$interface" "$ip" "$gateway" "$dns")
    fi
    
    # Detect system settings
    local timezone
    timezone=$(timedatectl show -p Timezone --value 2>/dev/null || echo "UTC")
    
    echo "Timezone: $timezone"
    
    # Add system to config
    config=$(add_system_to_config "$config" "$timezone" "")
    
    echo ""
    echo "Configuration detected successfully"
    echo ""
    
    # Encode to config code
    local config_code
    config_code=$(encode_config "$config")
    
    echo "=========================================="
    echo "  Configuration Code"
    echo "=========================================="
    echo ""
    echo "$config_code"
    echo ""
    echo "=========================================="
    echo ""
    echo "Save this code to restore configuration later."
    echo "To import: Run workflows/import-config.sh"
    echo ""
    
    # Save to file
    local output_file="${HOME}/server-config-$(date +%Y%m%d_%H%M%S).txt"
    echo "$config_code" > "$output_file"
    echo "Configuration code saved to: $output_file"
    echo ""
}

# Export with custom values
export_custom_config() {
    echo "Custom Configuration Export"
    echo ""
    
    # Create base config
    local config
    config=$(create_config "1.0")
    
    # Hostname
    read -r -p "Enter hostname (short): " hostname_short
    read -r -p "Enter FQDN (or press Enter to use short name): " hostname_fqdn
    hostname_fqdn="${hostname_fqdn:-$hostname_short}"
    
    read -r -p "Apply hostname immediately after import? [y/N]: " apply_hostname
    apply_hostname="${apply_hostname,,}"
    [[ "$apply_hostname" == "y" ]] && apply_hostname="true" || apply_hostname="false"
    
    config=$(add_hostname_to_config "$config" "$hostname_short" "$hostname_fqdn" "$apply_hostname")
    
    # Network
    echo ""
    read -r -p "Configure network? [y/N]: " configure_network
    if [[ "${configure_network,,}" == "y" ]]; then
        read -r -p "Network interface: " interface
        read -r -p "IP address (with CIDR, e.g., 192.168.1.100/24): " ip
        read -r -p "Gateway: " gateway
        read -r -p "DNS servers (space-separated): " dns
        
        config=$(add_network_to_config "$config" "$interface" "$ip" "$gateway" "$dns")
    fi
    
    # System
    echo ""
    read -r -p "Timezone (default: UTC): " timezone
    timezone="${timezone:-UTC}"
    
    config=$(add_system_to_config "$config" "$timezone" "")
    
    # Encode
    local config_code
    config_code=$(encode_config "$config")
    
    echo ""
    echo "=========================================="
    echo "  Configuration Code"
    echo "=========================================="
    echo ""
    echo "$config_code"
    echo ""
    echo "=========================================="
    echo ""
    
    # Save to file
    local output_file="${HOME}/server-config-$(date +%Y%m%d_%H%M%S).txt"
    echo "$config_code" > "$output_file"
    echo "Configuration code saved to: $output_file"
    echo ""
}

# Main function
main() {
    local mode="${1:-current}"
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    echo ""
    echo "=========================================="
    echo "  Export Configuration"
    echo "=========================================="
    echo ""
    
    case "$mode" in
        current)
            export_current_config
            ;;
        custom)
            export_custom_config
            ;;
        *)
            echo "Usage: $0 {current|custom}"
            echo ""
            echo "Modes:"
            echo "  current  - Export current system configuration (default)"
            echo "  custom   - Create custom configuration interactively"
            exit 1
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
