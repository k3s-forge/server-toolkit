#!/usr/bin/env bash
# workflows/quick-setup.sh - Quick configuration without reinstall

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
fi

# Quick setup wizard
quick_setup_wizard() {
    echo ""
    echo "=========================================="
    echo "  Quick Setup Wizard"
    echo "=========================================="
    echo ""
    echo "This wizard will help you configure your server"
    echo "without reinstalling the operating system."
    echo ""
    
    # Step 1: Hostname
    echo "Step 1: Hostname Configuration"
    echo "------------------------------"
    echo ""
    
    local current_hostname
    current_hostname=$(hostname -f 2>/dev/null || hostname)
    echo "Current hostname: $current_hostname"
    echo ""
    
    read -r -p "Configure hostname? [y/N]: " config_hostname
    
    local new_hostname=""
    local new_fqdn=""
    if [[ "${config_hostname,,}" == "y" ]]; then
        echo ""
        echo "Choose hostname configuration:"
        echo "  1) Generate with geo-location"
        echo "  2) Enter custom hostname"
        echo "  3) Keep current"
        echo ""
        
        read -r -p "Select [1-3]: " hostname_choice
        
        case "$hostname_choice" in
            1)
                local gen_script="$TOOLKIT_ROOT/components/hostname/generate.sh"
                if [[ -f "$gen_script" ]]; then
                    echo ""
                    echo "Generating hostname with geo-location..."
                    new_hostname=$(bash "$gen_script" k3s 01)
                    
                    # Read FQDN from temp file
                    if [[ -f /tmp/generated_hostname_fqdn.txt ]]; then
                        new_fqdn=$(cat /tmp/generated_hostname_fqdn.txt)
                    fi
                    
                    echo ""
                    echo "Generated hostname:"
                    echo "  Short Name: $new_hostname"
                    if [[ -n "$new_fqdn" ]]; then
                        echo "  FQDN:       $new_fqdn"
                    fi
                fi
                ;;
            2)
                read -r -p "Enter short name: " new_hostname
                read -r -p "Enter FQDN (optional, press Enter to skip): " new_fqdn
                ;;
            3)
                new_hostname="$current_hostname"
                ;;
        esac
        
        if [[ -n "$new_hostname" && "$new_hostname" != "$current_hostname" ]]; then
            echo ""
            read -r -p "Apply hostname now? [Y/n]: " apply_now
            if [[ "${apply_now,,}" != "n" ]]; then
                local apply_script="$TOOLKIT_ROOT/components/hostname/apply.sh"
                if [[ -f "$apply_script" ]]; then
                    if [[ -n "$new_fqdn" ]]; then
                        bash "$apply_script" apply "$new_hostname" "$new_fqdn"
                    else
                        bash "$apply_script" apply "$new_hostname"
                    fi
                    echo "✓ Hostname applied"
                fi
            fi
        fi
    fi
    
    echo ""
    
    # Step 2: Network
    echo "Step 2: Network Configuration"
    echo "------------------------------"
    echo ""
    
    local detect_script="$TOOLKIT_ROOT/components/network/detect.sh"
    if [[ -f "$detect_script" ]]; then
        bash "$detect_script" human
    fi
    
    echo ""
    read -r -p "Network configuration looks good? [Y/n]: " network_ok
    
    if [[ "${network_ok,,}" == "n" ]]; then
        echo ""
        echo "⚠ Network reconfiguration requires manual intervention"
        echo "  Use: workflows/export-config.sh to create config code"
        echo "  Then: workflows/import-config.sh to apply"
    fi
    
    echo ""
    
    # Step 3: System Settings
    echo "Step 3: System Settings"
    echo "-----------------------"
    echo ""
    
    local current_tz
    current_tz=$(timedatectl show -p Timezone --value 2>/dev/null || echo "unknown")
    echo "Current timezone: $current_tz"
    echo ""
    
    read -r -p "Change timezone? [y/N]: " change_tz
    if [[ "${change_tz,,}" == "y" ]]; then
        read -r -p "Enter timezone (e.g., Asia/Hong_Kong): " new_tz
        if [[ -n "$new_tz" ]]; then
            if sudo timedatectl set-timezone "$new_tz" 2>/dev/null; then
                echo "✓ Timezone set to: $new_tz"
            else
                echo "✗ Failed to set timezone"
            fi
        fi
    fi
    
    echo ""
    
    # Summary
    echo "=========================================="
    echo "  Quick Setup Complete"
    echo "=========================================="
    echo ""
    echo "Configuration Summary:"
    echo "  Hostname: $(hostname -f 2>/dev/null || hostname)"
    echo "  Timezone: $(timedatectl show -p Timezone --value 2>/dev/null || echo 'unknown')"
    echo ""
    echo "Next steps:"
    echo "  - Export configuration: workflows/export-config.sh"
    echo "  - Configure additional services from main menu"
    echo ""
}

# Main function
main() {
    quick_setup_wizard
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
