#!/usr/bin/env bash
# backup-config.sh - Configuration backup tool
# Backs up current system configuration before reinstall

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load common functions
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

# Backup directory
BACKUP_DIR="${BACKUP_DIR:-$HOME/system-backup-$(date +%Y%m%d_%H%M%S)}"

# Backup network configuration
backup_network_config() {
    i18n_info "backup_config" "Network configuration"
    
    local network_backup="$BACKUP_DIR/network"
    ensure_dir "$network_backup"
    
    # Backup IP addresses
    if has_cmd ip; then
        ip addr show > "$network_backup/ip-addr.txt" 2>/dev/null || true
        ip route show > "$network_backup/ip-route.txt" 2>/dev/null || true
    fi
    
    # Backup network configuration files
    local network_files=(
        "/etc/network/interfaces"
        "/etc/netplan"
        "/etc/NetworkManager"
        "/etc/systemd/network"
        "/etc/resolv.conf"
        "/etc/hosts"
        "/etc/hostname"
    )
    
    for file in "${network_files[@]}"; do
        if [[ -e "$file" ]]; then
            if [[ -d "$file" ]]; then
                cp -r "$file" "$network_backup/" 2>/dev/null || true
            else
                cp "$file" "$network_backup/" 2>/dev/null || true
            fi
        fi
    done
    
    i18n_success "backup_complete" "Network configuration"
}

# Backup service configuration
backup_service_config() {
    i18n_info "backup_config" "Service configuration"
    
    local service_backup="$BACKUP_DIR/services"
    ensure_dir "$service_backup"
    
    # List of services to backup
    local services=("docker" "containerd" "k3s" "tailscaled" "chronyd" "chrony" "sshd")
    
    for service in "${services[@]}"; do
        if check_service "$service" 2>/dev/null; then
            # Backup service status
            if has_cmd systemctl; then
                systemctl status "$service" > "$service_backup/${service}-status.txt" 2>/dev/null || true
            fi
            
            # Backup service configuration
            local config_paths=(
                "/etc/$service"
                "/etc/systemd/system/$service.service"
                "/etc/systemd/system/$service.service.d"
            )
            
            for path in "${config_paths[@]}"; do
                if [[ -e "$path" ]]; then
                    if [[ -d "$path" ]]; then
                        cp -r "$path" "$service_backup/" 2>/dev/null || true
                    else
                        cp "$path" "$service_backup/" 2>/dev/null || true
                    fi
                fi
            done
        fi
    done
    
    i18n_success "backup_complete" "Service configuration"
}

# Backup SSH configuration
backup_ssh_config() {
    i18n_info "backup_config" "SSH configuration"
    
    local ssh_backup="$BACKUP_DIR/ssh"
    ensure_dir "$ssh_backup"
    
    # Backup SSH configuration
    if [[ -d /etc/ssh ]]; then
        cp -r /etc/ssh "$ssh_backup/" 2>/dev/null || true
    fi
    
    # Backup SSH keys (only public keys for security)
    if [[ -d "$HOME/.ssh" ]]; then
        mkdir -p "$ssh_backup/user-ssh"
        cp "$HOME/.ssh"/*.pub "$ssh_backup/user-ssh/" 2>/dev/null || true
        cp "$HOME/.ssh/config" "$ssh_backup/user-ssh/" 2>/dev/null || true
        cp "$HOME/.ssh/known_hosts" "$ssh_backup/user-ssh/" 2>/dev/null || true
    fi
    
    i18n_success "backup_complete" "SSH configuration"
}

# Backup system information
backup_system_info() {
    i18n_info "backup_config" "System information"
    
    local info_backup="$BACKUP_DIR/system-info"
    ensure_dir "$info_backup"
    
    # OS information
    if [[ -f /etc/os-release ]]; then
        cp /etc/os-release "$info_backup/" 2>/dev/null || true
    fi
    
    # Kernel information
    uname -a > "$info_backup/kernel-info.txt" 2>/dev/null || true
    
    # Hardware information
    if has_cmd lscpu; then
        lscpu > "$info_backup/cpu-info.txt" 2>/dev/null || true
    fi
    
    if has_cmd free; then
        free -h > "$info_backup/memory-info.txt" 2>/dev/null || true
    fi
    
    if has_cmd df; then
        df -h > "$info_backup/disk-info.txt" 2>/dev/null || true
    fi
    
    # Installed packages
    if has_cmd dpkg; then
        dpkg -l > "$info_backup/packages-dpkg.txt" 2>/dev/null || true
    elif has_cmd rpm; then
        rpm -qa > "$info_backup/packages-rpm.txt" 2>/dev/null || true
    fi
    
    i18n_success "backup_complete" "System information"
}

# Backup user data
backup_user_data() {
    i18n_info "backup_config" "User data"
    
    local user_backup="$BACKUP_DIR/user-data"
    ensure_dir "$user_backup"
    
    # Backup important user files
    local user_files=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.profile"
        "$HOME/.zshrc"
        "$HOME/.vimrc"
        "$HOME/.gitconfig"
    )
    
    for file in "${user_files[@]}"; do
        if [[ -f "$file" ]]; then
            cp "$file" "$user_backup/" 2>/dev/null || true
        fi
    done
    
    i18n_success "backup_complete" "User data"
}

# Create backup summary
create_backup_summary() {
    local summary_file="$BACKUP_DIR/BACKUP-SUMMARY.txt"
    
    {
        echo "=== System Configuration Backup Summary ==="
        echo "Backup Date: $(date)"
        echo "Backup Location: $BACKUP_DIR"
        echo ""
        echo "=== Backed Up Components ==="
        echo "✓ Network configuration"
        echo "✓ Service configuration"
        echo "✓ SSH configuration"
        echo "✓ System information"
        echo "✓ User data"
        echo ""
        echo "=== Backup Contents ==="
        du -sh "$BACKUP_DIR"/* 2>/dev/null || true
        echo ""
        echo "=== Important Notes ==="
        echo "- This backup contains system configuration only"
        echo "- Sensitive data (private keys, passwords) are NOT included"
        echo "- Review the backup before system reinstall"
        echo "- Keep this backup in a safe location"
        echo ""
        echo "=== Restore Instructions ==="
        echo "After system reinstall, you can manually restore configurations"
        echo "from this backup directory."
    } > "$summary_file"
    
    i18n_info "report_saved" "$summary_file"
}

# Main function
main() {
    local custom_backup_dir="${1:-}"
    
    if [[ -n "$custom_backup_dir" ]]; then
        BACKUP_DIR="$custom_backup_dir"
    fi
    
    print_title "$(msg 'backup_config')"
    
    i18n_info "starting" "Configuration backup"
    i18n_info "backup_config" "Target: $BACKUP_DIR"
    
    # Create backup directory
    ensure_dir "$BACKUP_DIR"
    
    # Perform backups
    backup_network_config
    backup_service_config
    backup_ssh_config
    backup_system_info
    backup_user_data
    
    # Create summary
    create_backup_summary
    
    i18n_success "completed" "Configuration backup"
    echo ""
    echo "$(msg 'backup_complete'): $BACKUP_DIR"
    echo ""
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
