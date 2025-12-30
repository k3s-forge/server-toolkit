#!/usr/bin/env bash
# optimize-system.sh - System performance optimization
# Optimizes kernel parameters, file descriptors, and system settings

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load common functions and i18n
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

# Sysctl configuration file
SYSCTL_CONF="/etc/sysctl.d/99-server-toolkit.conf"

# Limits configuration file
LIMITS_CONF="/etc/security/limits.d/99-server-toolkit.conf"

# Optimize kernel parameters
optimize_kernel() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "optimizing_system" "Optimizing kernel parameters"
    
    # Backup existing configuration
    if [[ -f "$SYSCTL_CONF" ]]; then
        backup_file "$SYSCTL_CONF"
    fi
    
    # Generate sysctl configuration
    local config=""
    
    config+="# Server Toolkit - Kernel Optimization\n"
    config+="# Generated: $(date)\n"
    config+="\n"
    
    # Network optimizations
    config+="# Network optimizations\n"
    config+="net.core.rmem_max = 134217728\n"
    config+="net.core.wmem_max = 134217728\n"
    config+="net.core.rmem_default = 16777216\n"
    config+="net.core.wmem_default = 16777216\n"
    config+="net.core.optmem_max = 40960\n"
    config+="net.core.netdev_max_backlog = 50000\n"
    config+="net.core.somaxconn = 32768\n"
    config+="\n"
    
    # TCP optimizations
    config+="# TCP optimizations\n"
    config+="net.ipv4.tcp_rmem = 4096 87380 67108864\n"
    config+="net.ipv4.tcp_wmem = 4096 65536 67108864\n"
    config+="net.ipv4.tcp_max_syn_backlog = 8192\n"
    config+="net.ipv4.tcp_slow_start_after_idle = 0\n"
    config+="net.ipv4.tcp_tw_reuse = 1\n"
    config+="net.ipv4.tcp_fin_timeout = 15\n"
    config+="net.ipv4.tcp_keepalive_time = 300\n"
    config+="net.ipv4.tcp_keepalive_probes = 5\n"
    config+="net.ipv4.tcp_keepalive_intvl = 15\n"
    config+="\n"
    
    # Connection tracking
    config+="# Connection tracking\n"
    config+="net.netfilter.nf_conntrack_max = 1000000\n"
    config+="net.netfilter.nf_conntrack_tcp_timeout_established = 86400\n"
    config+="\n"
    
    # File system optimizations
    config+="# File system optimizations\n"
    config+="fs.file-max = 2097152\n"
    config+="fs.inotify.max_user_watches = 524288\n"
    config+="fs.inotify.max_user_instances = 512\n"
    config+="\n"
    
    # Virtual memory optimizations
    config+="# Virtual memory optimizations\n"
    config+="vm.swappiness = 10\n"
    config+="vm.dirty_ratio = 15\n"
    config+="vm.dirty_background_ratio = 5\n"
    config+="vm.max_map_count = 262144\n"
    config+="\n"
    
    # Kernel optimizations
    config+="# Kernel optimizations\n"
    config+="kernel.pid_max = 4194304\n"
    config+="kernel.threads-max = 4194304\n"
    config+="\n"
    
    # Write configuration
    echo -e "$config" | $sudo_cmd tee "$SYSCTL_CONF" > /dev/null
    
    # Apply configuration
    $sudo_cmd sysctl -p "$SYSCTL_CONF" >/dev/null 2>&1 || true
    
    i18n_success "completed" "Kernel optimization"
}

# Optimize file descriptors
optimize_limits() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "info" "Optimizing file descriptor limits"
    
    # Backup existing configuration
    if [[ -f "$LIMITS_CONF" ]]; then
        backup_file "$LIMITS_CONF"
    fi
    
    # Generate limits configuration
    local config=""
    
    config+="# Server Toolkit - File Descriptor Limits\n"
    config+="# Generated: $(date)\n"
    config+="\n"
    
    config+="# Soft limits\n"
    config+="* soft nofile 1048576\n"
    config+="* soft nproc 1048576\n"
    config+="* soft memlock unlimited\n"
    config+="\n"
    
    config+="# Hard limits\n"
    config+="* hard nofile 1048576\n"
    config+="* hard nproc 1048576\n"
    config+="* hard memlock unlimited\n"
    config+="\n"
    
    config+="# Root limits\n"
    config+="root soft nofile 1048576\n"
    config+="root hard nofile 1048576\n"
    config+="root soft nproc 1048576\n"
    config+="root hard nproc 1048576\n"
    
    # Write configuration
    echo -e "$config" | $sudo_cmd tee "$LIMITS_CONF" > /dev/null
    
    i18n_success "completed" "File descriptor optimization"
}

# Optimize swap
optimize_swap() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "info" "Optimizing swap configuration"
    
    # Check if swap exists
    if ! swapon --show | grep -q '/'; then
        i18n_info "info" "No swap configured, skipping"
        return 0
    fi
    
    # Set swappiness
    $sudo_cmd sysctl -w vm.swappiness=10 >/dev/null 2>&1 || true
    
    i18n_success "completed" "Swap optimization"
}

# Disable unnecessary services
disable_unnecessary_services() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "info" "Checking unnecessary services"
    
    # List of services to disable (if not needed)
    local services=(
        "bluetooth"
        "cups"
        "avahi-daemon"
    )
    
    for service in "${services[@]}"; do
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            if ask_yes_no "Disable $service?" "n"; then
                $sudo_cmd systemctl disable "$service" >/dev/null 2>&1 || true
                $sudo_cmd systemctl stop "$service" >/dev/null 2>&1 || true
                i18n_info "info" "Disabled: $service"
            fi
        fi
    done
}

# Enable automatic updates (security only)
enable_auto_updates() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    local os_id
    os_id=$(get_system_info "os")
    
    i18n_info "info" "Configuring automatic security updates"
    
    case "$os_id" in
        ubuntu|debian)
            # Install unattended-upgrades
            if ! dpkg -l | grep -q "^ii  unattended-upgrades "; then
                $sudo_cmd apt-get update -qq
                $sudo_cmd apt-get install -y unattended-upgrades apt-listchanges
            fi
            
            # Configure for security updates only
            local config="/etc/apt/apt.conf.d/50unattended-upgrades"
            if [[ -f "$config" ]]; then
                backup_file "$config"
            fi
            
            # Enable automatic security updates
            $sudo_cmd dpkg-reconfigure -plow unattended-upgrades
            
            i18n_success "completed" "Automatic security updates enabled"
            ;;
        centos|rhel|rocky|almalinux|fedora)
            # Install dnf-automatic or yum-cron
            if has_cmd dnf; then
                if ! dnf list installed dnf-automatic >/dev/null 2>&1; then
                    $sudo_cmd dnf install -y dnf-automatic
                fi
                
                # Configure for security updates only
                local config="/etc/dnf/automatic.conf"
                if [[ -f "$config" ]]; then
                    backup_file "$config"
                    $sudo_cmd sed -i 's/^upgrade_type = .*/upgrade_type = security/' "$config"
                    $sudo_cmd sed -i 's/^apply_updates = .*/apply_updates = yes/' "$config"
                fi
                
                # Enable and start service
                $sudo_cmd systemctl enable --now dnf-automatic.timer
                
                i18n_success "completed" "Automatic security updates enabled"
            else
                if ! yum list installed yum-cron >/dev/null 2>&1; then
                    $sudo_cmd yum install -y yum-cron
                fi
                
                # Configure for security updates only
                local config="/etc/yum/yum-cron.conf"
                if [[ -f "$config" ]]; then
                    backup_file "$config"
                    $sudo_cmd sed -i 's/^update_cmd = .*/update_cmd = security/' "$config"
                    $sudo_cmd sed -i 's/^apply_updates = .*/apply_updates = yes/' "$config"
                fi
                
                # Enable and start service
                $sudo_cmd systemctl enable --now yum-cron
                
                i18n_success "completed" "Automatic security updates enabled"
            fi
            ;;
        *)
            i18n_warn "os_unsupported" "$os_id"
            ;;
    esac
}

# Show system optimization status
show_optimization_status() {
    print_title "$(msg 'optimize_system')"
    
    echo "Kernel Parameters:"
    if [[ -f "$SYSCTL_CONF" ]]; then
        echo "  Configuration: $SYSCTL_CONF"
        echo "  Status: Configured"
    else
        echo "  Status: Not configured"
    fi
    echo ""
    
    echo "File Descriptor Limits:"
    if [[ -f "$LIMITS_CONF" ]]; then
        echo "  Configuration: $LIMITS_CONF"
        echo "  Status: Configured"
        echo "  Current soft limit: $(ulimit -Sn)"
        echo "  Current hard limit: $(ulimit -Hn)"
    else
        echo "  Status: Not configured"
    fi
    echo ""
    
    echo "Swap:"
    if swapon --show | grep -q '/'; then
        echo "  Swappiness: $(cat /proc/sys/vm/swappiness)"
        swapon --show
    else
        echo "  Status: No swap configured"
    fi
    echo ""
    
    echo "Automatic Updates:"
    local os_id
    os_id=$(get_system_info "os")
    case "$os_id" in
        ubuntu|debian)
            if systemctl is-enabled unattended-upgrades >/dev/null 2>&1; then
                echo "  Status: Enabled"
            else
                echo "  Status: Not enabled"
            fi
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if systemctl is-enabled dnf-automatic.timer >/dev/null 2>&1 || systemctl is-enabled yum-cron >/dev/null 2>&1; then
                echo "  Status: Enabled"
            else
                echo "  Status: Not enabled"
            fi
            ;;
        *)
            echo "  Status: Unknown"
            ;;
    esac
    echo ""
}

# Verify optimizations
verify_optimizations() {
    print_title "$(msg 'info') Verifying Optimizations"
    
    local all_ok=true
    
    # Check sysctl
    if [[ -f "$SYSCTL_CONF" ]]; then
        echo "✓ Kernel parameters configured"
    else
        echo "✗ Kernel parameters not configured"
        all_ok=false
    fi
    
    # Check limits
    if [[ -f "$LIMITS_CONF" ]]; then
        echo "✓ File descriptor limits configured"
    else
        echo "✗ File descriptor limits not configured"
        all_ok=false
    fi
    
    # Check key parameters
    local file_max
    file_max=$(cat /proc/sys/fs/file-max)
    if [[ "$file_max" -ge 2097152 ]]; then
        echo "✓ fs.file-max: $file_max"
    else
        echo "✗ fs.file-max: $file_max (should be >= 2097152)"
        all_ok=false
    fi
    
    local swappiness
    swappiness=$(cat /proc/sys/vm/swappiness)
    if [[ "$swappiness" -le 10 ]]; then
        echo "✓ vm.swappiness: $swappiness"
    else
        echo "⚠ vm.swappiness: $swappiness (recommended <= 10)"
    fi
    
    echo ""
    if [[ "$all_ok" == "true" ]]; then
        i18n_success "completed" "All optimizations verified"
    else
        i18n_warn "warning" "Some optimizations need attention"
    fi
}

# Main function
main() {
    local action="${1:-interactive}"
    
    print_title "$(msg 'optimize_system')"
    
    case "$action" in
        kernel)
            i18n_info "starting" "Kernel optimization"
            optimize_kernel
            i18n_success "completed" "Kernel optimization"
            ;;
        limits)
            i18n_info "starting" "File descriptor optimization"
            optimize_limits
            i18n_success "completed" "File descriptor optimization"
            ;;
        swap)
            i18n_info "starting" "Swap optimization"
            optimize_swap
            i18n_success "completed" "Swap optimization"
            ;;
        auto-updates)
            i18n_info "starting" "Automatic updates configuration"
            enable_auto_updates
            i18n_success "completed" "Automatic updates configuration"
            ;;
        all|interactive)
            i18n_info "starting" "System optimization"
            optimize_kernel
            optimize_limits
            optimize_swap
            
            echo ""
            if ask_yes_no "Enable automatic security updates?" "y"; then
                enable_auto_updates
            fi
            
            echo ""
            if ask_yes_no "Check for unnecessary services?" "n"; then
                disable_unnecessary_services
            fi
            
            echo ""
            verify_optimizations
            
            i18n_success "completed" "System optimization"
            
            echo ""
            i18n_info "info" "Note: Some changes require a reboot to take full effect"
            ;;
        status|show)
            show_optimization_status
            ;;
        verify)
            verify_optimizations
            ;;
        *)
            echo "Usage: $0 {kernel|limits|swap|auto-updates|all|status|verify}"
            echo ""
            echo "Actions:"
            echo "  kernel       - Optimize kernel parameters only"
            echo "  limits       - Optimize file descriptor limits only"
            echo "  swap         - Optimize swap configuration only"
            echo "  auto-updates - Enable automatic security updates only"
            echo "  all          - Apply all optimizations (default)"
            echo "  status       - Show optimization status"
            echo "  verify       - Verify optimizations"
            echo ""
            echo "Examples:"
            echo "  $0 all"
            echo "  $0 kernel"
            echo "  $0 status"
            echo "  $0 verify"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
