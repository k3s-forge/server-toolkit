#!/usr/bin/env bash
# components/hostname/manage.sh - Complete hostname management interface

set -Eeuo pipefail

# Load common header
if [[ -n "${SCRIPT_DIR:-}" ]] && [[ -f "$SCRIPT_DIR/utils/common-header.sh" ]]; then
    source "$SCRIPT_DIR/utils/common-header.sh"
else
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TOOLKIT_ROOT="$(cd "$CURRENT_DIR/../.." && pwd)"
    
    if [[ -f "$TOOLKIT_ROOT/utils/common.sh" ]]; then
        source "$TOOLKIT_ROOT/utils/common.sh"
    fi
    
    if [[ -f "$TOOLKIT_ROOT/utils/i18n.sh" ]]; then
        source "$TOOLKIT_ROOT/utils/i18n.sh"
    fi
fi

# Interactive hostname management
manage_hostname_interactive() {
    echo ""
    echo "=========================================="
    echo "  Hostname Management"
    echo "=========================================="
    echo ""
    
    # Show current hostname
    local current_hostname current_fqdn
    current_hostname=$(hostname)
    current_fqdn=$(hostname -f 2>/dev/null || hostname)
    
    echo "Current Configuration:"
    echo "  Hostname: $current_hostname"
    echo "  FQDN: $current_fqdn"
    echo ""
    
    # Menu
    echo "Choose action:"
    echo "  1) Generate and apply hostname immediately"
    echo "  2) Generate hostname for config code (no apply)"
    echo "  3) Apply custom hostname"
    echo "  4) View current hostname"
    echo "  0) Back"
    echo ""
    
    read -r -p "Select [0-4]: " choice
    
    case "$choice" in
        1)
            # Generate and apply
            echo ""
            echo "Generate and Apply Hostname"
            echo "---------------------------"
            echo ""
            
            local gen_script="$CURRENT_DIR/generate.sh"
            local apply_script="$CURRENT_DIR/apply.sh"
            
            if [[ ! -f "$gen_script" || ! -f "$apply_script" ]]; then
                echo "Error: Required scripts not found" >&2
                return 1
            fi
            
            # Generate
            echo "Generating hostname..."
            local short_name fqdn
            short_name=$(bash "$gen_script" k3s 01)
            
            if [[ -z "$short_name" ]]; then
                echo "Error: Failed to generate hostname" >&2
                return 1
            fi
            
            # Read FQDN from temp file
            if [[ -f /tmp/generated_hostname_fqdn.txt ]]; then
                fqdn=$(cat /tmp/generated_hostname_fqdn.txt)
            else
                fqdn=""
            fi
            
            echo ""
            echo "Generated Hostname:"
            echo "  Short Name (Primary): $short_name"
            if [[ -n "$fqdn" ]]; then
                echo "  FQDN (Alias):         $fqdn"
            fi
            echo ""
            
            # Confirm and apply
            read -r -p "Apply this hostname now? [Y/n]: " confirm
            if [[ "${confirm,,}" != "n" ]]; then
                if [[ -n "$fqdn" ]]; then
                    bash "$apply_script" apply "$short_name" "$fqdn"
                else
                    bash "$apply_script" apply "$short_name"
                fi
                echo ""
                echo "✓ Hostname applied and active"
                echo ""
                echo "Current configuration:"
                bash "$apply_script" show
            else
                echo ""
                echo "Hostname not applied. To apply later:"
                if [[ -n "$fqdn" ]]; then
                    echo "  bash components/hostname/apply.sh apply $short_name $fqdn"
                else
                    echo "  bash components/hostname/apply.sh apply $short_name"
                fi
            fi
            ;;
            
        2)
            # Generate for config code
            echo ""
            echo "Generate Hostname for Config Code"
            echo "----------------------------------"
            echo ""
            
            local gen_script="$CURRENT_DIR/generate.sh"
            
            if [[ ! -f "$gen_script" ]]; then
                echo "Error: Generate script not found" >&2
                return 1
            fi
            
            # Generate
            local short_name fqdn
            short_name=$(bash "$gen_script" k3s 01)
            
            if [[ -z "$short_name" ]]; then
                echo "Error: Failed to generate hostname" >&2
                return 1
            fi
            
            # Read FQDN from temp file
            if [[ -f /tmp/generated_hostname_fqdn.txt ]]; then
                fqdn=$(cat /tmp/generated_hostname_fqdn.txt)
            else
                fqdn=""
            fi
            
            echo ""
            echo "=========================================="
            echo "  Generated Hostname"
            echo "=========================================="
            echo ""
            echo "Short Name: $short_name"
            if [[ -n "$fqdn" ]]; then
                echo "FQDN:       $fqdn"
            fi
            echo ""
            echo "This hostname can be:"
            echo "  1. Added to config code (workflows/export-config.sh)"
            echo "  2. Applied later:"
            if [[ -n "$fqdn" ]]; then
                echo "     bash components/hostname/apply.sh apply $short_name $fqdn"
            else
                echo "     bash components/hostname/apply.sh apply $short_name"
            fi
            echo ""
            ;;
            
        3)
            # Apply custom
            echo ""
            read -r -p "Enter short name to apply: " custom_short
            
            if [[ -z "$custom_short" ]]; then
                echo "Error: Hostname cannot be empty" >&2
                return 1
            fi
            
            read -r -p "Enter FQDN (optional, press Enter to skip): " custom_fqdn
            
            local apply_script="$CURRENT_DIR/apply.sh"
            
            if [[ ! -f "$apply_script" ]]; then
                echo "Error: Apply script not found" >&2
                return 1
            fi
            
            if [[ -n "$custom_fqdn" ]]; then
                bash "$apply_script" apply "$custom_short" "$custom_fqdn"
            else
                bash "$apply_script" apply "$custom_short"
            fi
            ;;
            
        4)
            # View current
            local apply_script="$CURRENT_DIR/apply.sh"
            
            if [[ -f "$apply_script" ]]; then
                bash "$apply_script" show
            else
                echo "Hostname: $current_hostname"
                echo "FQDN: $current_fqdn"
            fi
            ;;
            
        0)
            return 0
            ;;
            
        *)
            echo "Invalid choice" >&2
            return 1
            ;;
    esac
}

# Main function
main() {
    manage_hostname_interactive
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
