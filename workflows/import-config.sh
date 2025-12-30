#!/usr/bin/env bash
# workflows/import-config.sh - Import configuration from config code

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

# Import configuration from code
import_config() {
    local config_code="$1"
    local dry_run="${2:-false}"
    
    echo "Decoding configuration..."
    
    # Decode config
    local config
    if ! config=$(decode_config "$config_code" 2>/dev/null); then
        echo "Error: Invalid configuration code" >&2
        return 1
    fi
    
    echo "✓ Configuration decoded successfully"
    echo ""
    
    # Display configuration
    echo "=========================================="
    echo "  Configuration Summary"
    echo "=========================================="
    echo ""
    echo "$config" | jq .
    echo ""
    
    # Extract values
    local hostname_short hostname_fqdn hostname_apply
    hostname_short=$(echo "$config" | jq -r '.hostname.short // empty')
    hostname_fqdn=$(echo "$config" | jq -r '.hostname.fqdn // empty')
    hostname_apply=$(echo "$config" | jq -r '.hostname.apply // false')
    
    local net_interface net_ip net_gateway net_dns
    net_interface=$(echo "$config" | jq -r '.network.interface // empty')
    net_ip=$(echo "$config" | jq -r '.network.ip // empty')
    net_gateway=$(echo "$config" | jq -r '.network.gateway // empty')
    net_dns=$(echo "$config" | jq -r '.network.dns[]? // empty' | tr '\n' ' ')
    
    local sys_timezone
    sys_timezone=$(echo "$config" | jq -r '.system.timezone // "UTC"')
    
    if [[ "$dry_run" == "true" ]]; then
        echo "Dry run mode - no changes will be made"
        echo ""
        return 0
    fi
    
    # Apply configuration
    echo "=========================================="
    echo "  Applying Configuration"
    echo "=========================================="
    echo ""
    
    # Apply hostname
    if [[ -n "$hostname_short" && "$hostname_apply" == "true" ]]; then
        echo "Applying hostname:"
        echo "  Short Name: $hostname_short"
        if [[ -n "$hostname_fqdn" && "$hostname_fqdn" != "$hostname_short" ]]; then
            echo "  FQDN Alias: $hostname_fqdn"
        fi
        
        local apply_script="$TOOLKIT_ROOT/components/hostname/apply.sh"
        if [[ -f "$apply_script" ]]; then
            if [[ -n "$hostname_fqdn" && "$hostname_fqdn" != "$hostname_short" ]]; then
                if bash "$apply_script" apply "$hostname_short" "$hostname_fqdn"; then
                    echo "✓ Hostname applied"
                else
                    echo "✗ Failed to apply hostname" >&2
                fi
            else
                if bash "$apply_script" apply "$hostname_short"; then
                    echo "✓ Hostname applied"
                else
                    echo "✗ Failed to apply hostname" >&2
                fi
            fi
        else
            echo "✗ Hostname apply script not found" >&2
        fi
        echo ""
    elif [[ -n "$hostname_short" ]]; then
        echo "Hostname configured but not set to apply:"
        echo "  Short Name: $hostname_short"
        if [[ -n "$hostname_fqdn" && "$hostname_fqdn" != "$hostname_short" ]]; then
            echo "  FQDN:       $hostname_fqdn"
            echo "  To apply manually: bash components/hostname/apply.sh apply $hostname_short $hostname_fqdn"
        else
            echo "  To apply manually: bash components/hostname/apply.sh apply $hostname_short"
        fi
        echo ""
    fi
    
    # Apply network (if configured)
    if [[ -n "$net_interface" && -n "$net_ip" ]]; then
        echo "Network configuration detected:"
        echo "  Interface: $net_interface"
        echo "  IP: $net_ip"
        echo "  Gateway: $net_gateway"
        echo "  DNS: $net_dns"
        echo ""
        echo "⚠ Network configuration requires manual application"
        echo "  This is to prevent accidental network disconnection"
        echo ""
        
        # Save network config for manual application
        local net_config_file="${HOME}/network-config-$(date +%Y%m%d_%H%M%S).sh"
        cat > "$net_config_file" << EOF
#!/usr/bin/env bash
# Network configuration script
# Generated from config code

# Interface: $net_interface
# IP: $net_ip
# Gateway: $net_gateway
# DNS: $net_dns

# Apply IP address
ip addr flush dev $net_interface
ip addr add $net_ip dev $net_interface
ip link set $net_interface up

# Apply gateway
ip route add default via $net_gateway

# Apply DNS
cat > /etc/resolv.conf << DNS_EOF
$(for dns in $net_dns; do echo "nameserver $dns"; done)
DNS_EOF

echo "Network configuration applied"
EOF
        chmod +x "$net_config_file"
        echo "Network configuration script saved to: $net_config_file"
        echo "Review and run manually: sudo bash $net_config_file"
        echo ""
    fi
    
    # Apply timezone
    if [[ -n "$sys_timezone" ]]; then
        echo "Setting timezone: $sys_timezone"
        if command -v timedatectl >/dev/null 2>&1; then
            if sudo timedatectl set-timezone "$sys_timezone" 2>/dev/null; then
                echo "✓ Timezone set"
            else
                echo "✗ Failed to set timezone" >&2
            fi
        else
            echo "⚠ timedatectl not available, skipping timezone"
        fi
        echo ""
    fi
    
    echo "=========================================="
    echo "  Import Complete"
    echo "=========================================="
    echo ""
}

# Interactive import
import_interactive() {
    echo ""
    echo "=========================================="
    echo "  Import Configuration"
    echo "=========================================="
    echo ""
    echo "Paste your configuration code below:"
    echo "(Press Ctrl+D when done)"
    echo ""
    
    # Read config code from stdin
    local config_code
    config_code=$(cat)
    
    if [[ -z "$config_code" ]]; then
        echo "Error: No configuration code provided" >&2
        return 1
    fi
    
    echo ""
    
    # Preview configuration
    import_config "$config_code" "true"
    
    # Confirm
    read -r -p "Apply this configuration? [y/N]: " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        echo "Import cancelled"
        return 0
    fi
    
    echo ""
    
    # Apply configuration
    import_config "$config_code" "false"
}

# Import from file
import_from_file() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi
    
    local config_code
    config_code=$(cat "$file")
    
    if [[ -z "$config_code" ]]; then
        echo "Error: Empty configuration file" >&2
        return 1
    fi
    
    # Preview
    echo "Configuration from file: $file"
    echo ""
    import_config "$config_code" "true"
    
    # Confirm
    read -r -p "Apply this configuration? [y/N]: " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        echo "Import cancelled"
        return 0
    fi
    
    echo ""
    
    # Apply
    import_config "$config_code" "false"
}

# Main function
main() {
    local mode="${1:-interactive}"
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    case "$mode" in
        interactive)
            import_interactive
            ;;
        file)
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 file <config-file>" >&2
                exit 1
            fi
            import_from_file "$2"
            ;;
        code)
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 code <config-code>" >&2
                exit 1
            fi
            import_config "$2" "false"
            ;;
        *)
            echo "Usage: $0 {interactive|file|code} [argument]"
            echo ""
            echo "Modes:"
            echo "  interactive       - Paste config code interactively (default)"
            echo "  file <file>       - Import from file"
            echo "  code <code>       - Import from command line"
            echo ""
            echo "Examples:"
            echo "  $0 interactive"
            echo "  $0 file ~/server-config.txt"
            echo "  $0 code 'eyJ2ZXJzaW9uIjoiMS4wIi...'"
            exit 1
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
