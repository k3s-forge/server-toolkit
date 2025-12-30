#!/usr/bin/env bash
# setup-security.sh - Security hardening and SSH optimization
# Configures SSH, firewall, and security settings

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load common functions and i18n
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

# SSH configuration
SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_CONFIG_BACKUP="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"

# Optimize SSH configuration
optimize_ssh() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "configuring_security" "Optimizing SSH configuration"
    
    # Backup existing configuration
    if [[ -f "$SSHD_CONFIG" ]]; then
        $sudo_cmd cp "$SSHD_CONFIG" "$SSHD_CONFIG_BACKUP"
        i18n_info "backup_file" "$SSHD_CONFIG_BACKUP"
    fi
    
    # Apply SSH optimizations
    local changes=(
        "s/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/"
        "s/^#*PasswordAuthentication.*/PasswordAuthentication no/"
        "s/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/"
        "s/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/"
        "s/^#*UsePAM.*/UsePAM yes/"
        "s/^#*X11Forwarding.*/X11Forwarding no/"
        "s/^#*PrintMotd.*/PrintMotd no/"
        "s/^#*TCPKeepAlive.*/TCPKeepAlive yes/"
        "s/^#*ClientAliveInterval.*/ClientAliveInterval 60/"
        "s/^#*ClientAliveCountMax.*/ClientAliveCountMax 3/"
        "s/^#*MaxAuthTries.*/MaxAuthTries 3/"
        "s/^#*MaxSessions.*/MaxSessions 10/"
    )
    
    for change in "${changes[@]}"; do
        $sudo_cmd sed -i "$change" "$SSHD_CONFIG"
    done
    
    # Add additional security settings if not present
    if ! grep -q "^Protocol 2" "$SSHD_CONFIG"; then
        echo "Protocol 2" | $sudo_cmd tee -a "$SSHD_CONFIG" > /dev/null
    fi
    
    if ! grep -q "^PermitEmptyPasswords" "$SSHD_CONFIG"; then
        echo "PermitEmptyPasswords no" | $sudo_cmd tee -a "$SSHD_CONFIG" > /dev/null
    fi
    
    # Test configuration
    if $sudo_cmd sshd -t; then
        # Reload SSH service
        $sudo_cmd systemctl reload sshd || $sudo_cmd systemctl reload ssh
        i18n_success "completed" "SSH optimization"
    else
        i18n_error "failed" "SSH configuration test failed, restoring backup"
        $sudo_cmd cp "$SSHD_CONFIG_BACKUP" "$SSHD_CONFIG"
        return 1
    fi
}

# Configure firewall
configure_firewall() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "info" "Configuring firewall"
    
    # Check if firewall is needed
    if ! ask_yes_no "Configure firewall (ufw)?" "n"; then
        i18n_info "skipped" "Firewall configuration"
        return 0
    fi
    
    # Install ufw if not present
    if ! has_cmd ufw; then
        local os_id
        os_id=$(get_system_info "os")
        
        case "$os_id" in
            ubuntu|debian)
                $sudo_cmd apt-get update -qq
                $sudo_cmd apt-get install -y ufw
                ;;
            *)
                i18n_warn "warning" "ufw not available for $os_id"
                return 0
                ;;
        esac
    fi
    
    # Configure ufw
    i18n_info "info" "Setting up firewall rules"
    
    # Default policies
    $sudo_cmd ufw --force reset
    $sudo_cmd ufw default deny incoming
    $sudo_cmd ufw default allow outgoing
    
    # Allow SSH
    $sudo_cmd ufw allow ssh
    
    # Ask for additional ports
    echo ""
    echo "Common ports to allow:"
    echo "  - 80/tcp (HTTP)"
    echo "  - 443/tcp (HTTPS)"
    echo "  - 6443/tcp (K3s API)"
    echo ""
    
    if ask_yes_no "Allow HTTP (80)?" "n"; then
        $sudo_cmd ufw allow 80/tcp
    fi
    
    if ask_yes_no "Allow HTTPS (443)?" "n"; then
        $sudo_cmd ufw allow 443/tcp
    fi
    
    if ask_yes_no "Allow K3s API (6443)?" "n"; then
        $sudo_cmd ufw allow 6443/tcp
    fi
    
    # Enable firewall
    $sudo_cmd ufw --force enable
    
    i18n_success "completed" "Firewall configuration"
}

# Disable core dumps
disable_core_dumps() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "info" "Disabling core dumps"
    
    # Disable via limits
    local limits_file="/etc/security/limits.d/99-disable-core-dumps.conf"
    echo "* hard core 0" | $sudo_cmd tee "$limits_file" > /dev/null
    
    # Disable via sysctl
    $sudo_cmd sysctl -w kernel.core_pattern="|/bin/false" >/dev/null 2>&1 || true
    
    # Disable via systemd
    if [[ -d /etc/systemd ]]; then
        $sudo_cmd mkdir -p /etc/systemd/coredump.conf.d
        echo -e "[Coredump]\nStorage=none" | $sudo_cmd tee /etc/systemd/coredump.conf.d/disable.conf > /dev/null
    fi
    
    i18n_success "completed" "Core dumps disabled"
}

# Configure fail2ban
configure_fail2ban() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "info" "Configuring fail2ban"
    
    if ! ask_yes_no "Install and configure fail2ban?" "n"; then
        i18n_info "skipped" "fail2ban configuration"
        return 0
    fi
    
    # Install fail2ban
    if ! has_cmd fail2ban-client; then
        local os_id
        os_id=$(get_system_info "os")
        
        case "$os_id" in
            ubuntu|debian)
                $sudo_cmd apt-get update -qq
                $sudo_cmd apt-get install -y fail2ban
                ;;
            centos|rhel|rocky|almalinux|fedora)
                if has_cmd dnf; then
                    $sudo_cmd dnf install -y fail2ban
                else
                    $sudo_cmd yum install -y fail2ban
                fi
                ;;
            *)
                i18n_warn "warning" "fail2ban not available for $os_id"
                return 0
                ;;
        esac
    fi
    
    # Configure fail2ban for SSH
    local jail_local="/etc/fail2ban/jail.local"
    if [[ ! -f "$jail_local" ]]; then
        cat <<EOF | $sudo_cmd tee "$jail_local" > /dev/null
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF
    fi
    
    # Enable and start fail2ban
    $sudo_cmd systemctl enable fail2ban
    $sudo_cmd systemctl restart fail2ban
    
    i18n_success "completed" "fail2ban configuration"
}

# Show security status
show_security_status() {
    print_title "$(msg 'setup_security')"
    
    echo "SSH Configuration:"
    if [[ -f "$SSHD_CONFIG" ]]; then
        echo "  PermitRootLogin: $(grep "^PermitRootLogin" "$SSHD_CONFIG" | awk '{print $2}')"
        echo "  PasswordAuthentication: $(grep "^PasswordAuthentication" "$SSHD_CONFIG" | awk '{print $2}')"
        echo "  PubkeyAuthentication: $(grep "^PubkeyAuthentication" "$SSHD_CONFIG" | awk '{print $2}')"
    fi
    echo ""
    
    echo "Firewall (ufw):"
    if has_cmd ufw; then
        $sudo_cmd ufw status 2>/dev/null || echo "  Status: Not configured"
    else
        echo "  Status: Not installed"
    fi
    echo ""
    
    echo "fail2ban:"
    if has_cmd fail2ban-client; then
        if systemctl is-active fail2ban >/dev/null 2>&1; then
            echo "  Status: Running"
            $sudo_cmd fail2ban-client status 2>/dev/null || true
        else
            echo "  Status: Installed but not running"
        fi
    else
        echo "  Status: Not installed"
    fi
    echo ""
    
    echo "Core Dumps:"
    if [[ -f "/etc/security/limits.d/99-disable-core-dumps.conf" ]]; then
        echo "  Status: Disabled"
    else
        echo "  Status: Not disabled"
    fi
    echo ""
}

# Main function
main() {
    local action="${1:-interactive}"
    
    print_title "$(msg 'setup_security')"
    
    case "$action" in
        ssh)
            i18n_info "starting" "SSH optimization"
            optimize_ssh
            i18n_success "completed" "SSH optimization"
            ;;
        firewall)
            i18n_info "starting" "Firewall configuration"
            configure_firewall
            i18n_success "completed" "Firewall configuration"
            ;;
        fail2ban)
            i18n_info "starting" "fail2ban configuration"
            configure_fail2ban
            i18n_success "completed" "fail2ban configuration"
            ;;
        core-dumps)
            i18n_info "starting" "Disabling core dumps"
            disable_core_dumps
            i18n_success "completed" "Core dumps disabled"
            ;;
        all|interactive)
            i18n_info "starting" "Security hardening"
            
            optimize_ssh
            echo ""
            
            configure_firewall
            echo ""
            
            configure_fail2ban
            echo ""
            
            disable_core_dumps
            echo ""
            
            i18n_success "completed" "Security hardening"
            
            echo ""
            i18n_info "info" "Security hardening complete. Please test SSH access before closing this session!"
            ;;
        status|show)
            show_security_status
            ;;
        *)
            echo "Usage: $0 {ssh|firewall|fail2ban|core-dumps|all|status}"
            echo ""
            echo "Actions:"
            echo "  ssh        - Optimize SSH configuration only"
            echo "  firewall   - Configure firewall only"
            echo "  fail2ban   - Configure fail2ban only"
            echo "  core-dumps - Disable core dumps only"
            echo "  all        - Apply all security hardening (default)"
            echo "  status     - Show security status"
            echo ""
            echo "Examples:"
            echo "  $0 all"
            echo "  $0 ssh"
            echo "  $0 status"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
