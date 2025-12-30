#!/usr/bin/env bash
# components/hostname/apply.sh - Apply hostname to system

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

# Apply hostname to system (short name + optional FQDN)
apply_hostname() {
    local short_name="$1"
    local fqdn="${2:-}"  # Optional FQDN
    local sudo_cmd
    
    # Get sudo command
    if [[ "$(id -u)" -eq 0 ]]; then
        sudo_cmd=""
    elif command -v sudo >/dev/null 2>&1; then
        sudo_cmd="sudo"
    else
        echo "Error: Root privileges required" >&2
        return 1
    fi
    
    echo "Applying hostname: $short_name"
    if [[ -n "$fqdn" ]]; then
        echo "  FQDN alias: $fqdn"
    fi
    
    # Set hostname using hostnamectl (preferred)
    if command -v hostnamectl >/dev/null 2>&1; then
        if $sudo_cmd hostnamectl set-hostname "$short_name" 2>/dev/null; then
            echo "✓ Hostname set using hostnamectl"
        else
            echo "Error: Failed to set hostname using hostnamectl" >&2
            return 1
        fi
    else
        # Fallback: traditional method
        echo "$short_name" | $sudo_cmd tee /etc/hostname >/dev/null
        $sudo_cmd hostname "$short_name"
        echo "✓ Hostname set using traditional method"
    fi
    
    # Update /etc/hosts
    update_hosts_file "$short_name" "$fqdn" "$sudo_cmd"
    
    echo "✓ Hostname applied successfully: $short_name"
    return 0
}

# Update /etc/hosts file
update_hosts_file() {
    local short_name="$1"
    local fqdn="$2"
    local sudo_cmd="$3"
    
    echo "Updating /etc/hosts..."
    
    # Backup /etc/hosts
    $sudo_cmd cp /etc/hosts "/etc/hosts.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # Create temporary file
    local temp_hosts
    temp_hosts=$(mktemp)
    
    # Remove existing 127.0.1.1 entries
    grep -v "^127.0.1.1" /etc/hosts > "$temp_hosts" 2>/dev/null || true
    
    # Add new hostname entry (short name + FQDN alias)
    if [[ -n "$fqdn" && "$fqdn" != "$short_name" ]]; then
        echo "127.0.1.1 $short_name $fqdn" >> "$temp_hosts"
    else
        echo "127.0.1.1 $short_name" >> "$temp_hosts"
    fi
    
    # Replace /etc/hosts
    $sudo_cmd mv "$temp_hosts" /etc/hosts
    
    echo "✓ /etc/hosts updated"
}

# Apply FQDN (convert to short name format)
apply_fqdn() {
    local fqdn="$1"
    
    # Convert FQDN to short name (replace dots with hyphens)
    local short_name="${fqdn//./-}"
    
    # Apply with both formats
    apply_hostname "$short_name" "$fqdn"
    
    echo "✓ FQDN applied as alias: $fqdn"
    echo "✓ Primary hostname: $short_name"
}

# Show current hostname
show_current() {
    echo "Current hostname configuration:"
    echo ""
    echo "Hostname: $(hostname)"
    echo "FQDN: $(hostname -f 2>/dev/null || hostname)"
    echo ""
    echo "/etc/hosts entries:"
    grep -E "^127\.(0\.0\.1|0\.1\.1)" /etc/hosts 2>/dev/null || echo "  None"
}

# Main function
main() {
    local action="${1:-}"
    
    if [[ -z "$action" ]]; then
        echo "Usage: $0 {apply|fqdn|show} <hostname>"
        echo ""
        echo "Actions:"
        echo "  apply <hostname>  - Apply hostname to system"
        echo "  fqdn <fqdn>       - Apply FQDN to system"
        echo "  show              - Show current hostname"
        echo ""
        echo "Examples:"
        echo "  $0 apply server-01"
        echo "  $0 fqdn server-01.k3s.local"
        echo "  $0 show"
        exit 1
    fi
    
    case "$action" in
        apply)
            if [[ $# -lt 2 ]]; then
                echo "Error: Hostname not specified" >&2
                echo "Usage: $0 apply <short-name> [fqdn]" >&2
                exit 1
            fi
            local short_name="$2"
            local fqdn="${3:-}"
            apply_hostname "$short_name" "$fqdn"
            ;;
        fqdn)
            if [[ $# -lt 2 ]]; then
                echo "Error: FQDN not specified" >&2
                echo "Usage: $0 fqdn <fqdn>" >&2
                exit 1
            fi
            apply_fqdn "$2"
            ;;
        show)
            show_current
            ;;
        *)
            echo "Error: Unknown action: $action" >&2
            exit 1
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
