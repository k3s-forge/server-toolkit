#!/usr/bin/env bash
# setup-hostname.sh - Hostname configuration tool
# Configures system hostname with optional geo-location based naming

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load common functions and i18n
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

# Generate hostname with geo-location
generate_hostname_with_geo() {
    local prefix="${1:-server}"
    local hostname=""
    
    i18n_info "detect_network" "Geo-location"
    
    # Try to get public IP
    local public_ip=""
    if check_network "8.8.8.8" "53" "3"; then
        public_ip=$(curl -fsSL --connect-timeout 3 --max-time 6 "https://api.ipify.org" 2>/dev/null || echo "")
    fi
    
    if [[ -n "$public_ip" ]]; then
        # Try to get geo-location
        local geo_info
        geo_info=$(curl -fsSL --connect-timeout 3 --max-time 6 \
            "http://ip-api.com/json/$public_ip?fields=status,country,countryCode,region,city" 2>/dev/null || echo "")
        
        if [[ -n "$geo_info" ]] && echo "$geo_info" | grep -q '"status":"success"'; then
            local country_code region city
            country_code=$(echo "$geo_info" | grep -oP '"countryCode":"\K[^"]+' || echo "")
            region=$(echo "$geo_info" | grep -oP '"region":"\K[^"]+' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' || echo "")
            city=$(echo "$geo_info" | grep -oP '"city":"\K[^"]+' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' || echo "")
            
            if [[ -n "$country_code" && -n "$city" ]]; then
                # Format: prefix-countrycode-city-random
                local random_suffix
                random_suffix=$(generate_random_string 8)
                hostname="${prefix}-${country_code,,}-${city}-${random_suffix}"
                
                i18n_success "completed" "Generated hostname with geo-location"
                echo "$hostname"
                return 0
            fi
        fi
    fi
    
    # Fallback: generate simple hostname
    local random_suffix
    random_suffix=$(generate_random_string 8)
    hostname="${prefix}-${random_suffix}"
    
    i18n_warn "network_failed" "Using fallback hostname"
    echo "$hostname"
}

# Validate hostname format
validate_hostname() {
    local hostname="$1"
    
    # Check length (max 63 characters)
    if [[ ${#hostname} -gt 63 ]]; then
        return 1
    fi
    
    # Check format: alphanumeric and hyphens, must start with alphanumeric
    if [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]]; then
        return 1
    fi
    
    return 0
}

# Set system hostname
set_system_hostname() {
    local hostname="$1"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    # Validate hostname
    if ! validate_hostname "$hostname"; then
        i18n_error "failed" "Invalid hostname format: $hostname"
        return 1
    fi
    
    # Get current hostname
    local current_hostname
    current_hostname=$(hostname)
    
    if [[ "$current_hostname" == "$hostname" ]]; then
        i18n_info "file_exists" "Hostname already set: $hostname"
        return 0
    fi
    
    i18n_info "configuring_hostname" "$hostname"
    
    # Set hostname using hostnamectl (preferred)
    if has_cmd hostnamectl; then
        if $sudo_cmd hostnamectl set-hostname "$hostname" 2>/dev/null; then
            i18n_success "hostname_configured" "$hostname"
        else
            i18n_error "failed" "Failed to set hostname using hostnamectl"
            return 1
        fi
    else
        # Fallback: traditional method
        echo "$hostname" | $sudo_cmd tee /etc/hostname >/dev/null
        $sudo_cmd hostname "$hostname"
        i18n_success "hostname_configured" "$hostname"
    fi
    
    # Update /etc/hosts
    update_hosts_file "$hostname"
    
    return 0
}

# Update /etc/hosts file
update_hosts_file() {
    local hostname="$1"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "backup_config" "/etc/hosts"
    
    # Backup /etc/hosts
    $sudo_cmd cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    # Create temporary file
    local temp_hosts
    temp_hosts=$(mktemp)
    
    # Remove existing 127.0.1.1 entries
    grep -v "^127.0.1.1" /etc/hosts > "$temp_hosts" || true
    
    # Add new hostname entry
    echo "127.0.1.1 $hostname" >> "$temp_hosts"
    
    # Replace /etc/hosts
    $sudo_cmd mv "$temp_hosts" /etc/hosts
    
    i18n_success "completed" "Updated /etc/hosts"
}

# Configure hostname interactively
configure_hostname_interactive() {
    echo ""
    echo "$(msg 'setup_hostname')"
    echo ""
    
    # Show current hostname
    local current_hostname
    current_hostname=$(hostname -f 2>/dev/null || hostname)
    echo "$(msg 'info') Current hostname: $current_hostname"
    echo ""
    
    # Ask for hostname type
    echo "Choose hostname configuration:"
    echo "  1) Enter custom hostname"
    echo "  2) Generate hostname with geo-location"
    echo "  3) Keep current hostname"
    echo ""
    
    read -r -p "Select option [1-3]: " choice
    
    case "$choice" in
        1)
            # Custom hostname
            read -r -p "Enter hostname: " custom_hostname
            if [[ -n "$custom_hostname" ]]; then
                set_system_hostname "$custom_hostname"
            else
                i18n_error "failed" "Hostname cannot be empty"
                return 1
            fi
            ;;
        2)
            # Generate with geo-location
            read -r -p "Enter hostname prefix (default: server): " prefix
            prefix="${prefix:-server}"
            
            local generated_hostname
            generated_hostname=$(generate_hostname_with_geo "$prefix")
            
            echo ""
            echo "$(msg 'info') Generated hostname: $generated_hostname"
            echo ""
            
            if ask_yes_no "$(msg 'confirm') Use this hostname?"; then
                set_system_hostname "$generated_hostname"
            else
                i18n_info "skipped" "Hostname configuration cancelled"
                return 0
            fi
            ;;
        3)
            # Keep current
            i18n_info "skipped" "Keeping current hostname: $current_hostname"
            return 0
            ;;
        *)
            i18n_error "failed" "Invalid choice"
            return 1
            ;;
    esac
}

# Configure hostname from parameter
configure_hostname_direct() {
    local hostname="$1"
    
    if [[ -z "$hostname" ]]; then
        i18n_error "failed" "Hostname not specified"
        return 1
    fi
    
    set_system_hostname "$hostname"
}

# Generate and show hostname
generate_hostname_only() {
    local prefix="${1:-server}"
    local hostname
    
    hostname=$(generate_hostname_with_geo "$prefix")
    
    echo ""
    echo "$(msg 'info') Generated hostname: $hostname"
    echo ""
    echo "To set this hostname, run:"
    echo "  $0 set $hostname"
    echo ""
}

# Show current hostname
show_hostname() {
    print_title "$(msg 'setup_hostname')"
    
    local hostname fqdn
    hostname=$(hostname)
    fqdn=$(hostname -f 2>/dev/null || hostname)
    
    echo "Hostname: $hostname"
    echo "FQDN: $fqdn"
    echo ""
    
    # Show /etc/hosts entries
    echo "/etc/hosts entries:"
    grep -E "^127\.(0\.0\.1|0\.1\.1)" /etc/hosts || echo "  None"
    echo ""
}

# Main function
main() {
    local action="${1:-interactive}"
    local hostname="${2:-}"
    
    print_title "$(msg 'setup_hostname')"
    
    case "$action" in
        interactive|config)
            i18n_info "starting" "Hostname configuration"
            configure_hostname_interactive
            i18n_success "completed" "Hostname configuration"
            ;;
        set)
            if [[ -z "$hostname" ]]; then
                i18n_error "failed" "Hostname not specified"
                echo "Usage: $0 set <hostname>"
                exit 1
            fi
            i18n_info "starting" "Hostname configuration"
            configure_hostname_direct "$hostname"
            i18n_success "completed" "Hostname configuration"
            ;;
        generate)
            local prefix="${hostname:-server}"
            generate_hostname_only "$prefix"
            ;;
        show)
            show_hostname
            ;;
        *)
            echo "Usage: $0 {interactive|set|generate|show} [hostname|prefix]"
            echo ""
            echo "Actions:"
            echo "  interactive  - Configure hostname interactively (default)"
            echo "  set          - Set hostname directly"
            echo "  generate     - Generate hostname with geo-location"
            echo "  show         - Show current hostname"
            echo ""
            echo "Examples:"
            echo "  $0 interactive"
            echo "  $0 set my-server"
            echo "  $0 generate server"
            echo "  $0 show"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
