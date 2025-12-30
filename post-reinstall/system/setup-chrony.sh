#!/usr/bin/env bash
# setup-chrony.sh - Chrony time synchronization setup
# Installs and configures Chrony for accurate time synchronization

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load common functions and i18n
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

# Chrony configuration
CHRONY_CONFIG_FILE="/etc/chrony/chrony.conf"
CHRONY_SERVICE="chronyd"

# Detect OS-specific paths
detect_chrony_paths() {
    local os_id
    os_id=$(get_system_info "os")
    
    case "$os_id" in
        ubuntu|debian)
            CHRONY_CONFIG_FILE="/etc/chrony/chrony.conf"
            CHRONY_SERVICE="chrony"
            ;;
        centos|rhel|rocky|almalinux|fedora)
            CHRONY_CONFIG_FILE="/etc/chrony.conf"
            CHRONY_SERVICE="chronyd"
            ;;
        *)
            CHRONY_CONFIG_FILE="/etc/chrony.conf"
            CHRONY_SERVICE="chronyd"
            ;;
    esac
}

# Install Chrony
install_chrony() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    # Check if already installed
    if has_cmd chronyc; then
        local version
        version=$(chronyc -v 2>&1 | head -1 || echo "unknown")
        i18n_info "file_exists" "Chrony: $version"
        return 0
    fi
    
    i18n_info "installing_chrony"
    
    # Detect OS
    local os_id
    os_id=$(get_system_info "os")
    
    case "$os_id" in
        ubuntu|debian)
            $sudo_cmd apt-get update -qq
            $sudo_cmd apt-get install -y chrony
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if has_cmd dnf; then
                $sudo_cmd dnf install -y chrony
            else
                $sudo_cmd yum install -y chrony
            fi
            ;;
        *)
            i18n_error "os_unsupported" "$os_id"
            return 1
            ;;
    esac
    
    # Verify installation
    if has_cmd chronyc; then
        local version
        version=$(chronyc -v 2>&1 | head -1 || echo "unknown")
        i18n_success "chrony_installed" "$version"
    else
        i18n_error "failed" "Chrony installation failed"
        return 1
    fi
}

# Configure Chrony
configure_chrony() {
    local ntp_servers="${1:-}"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "configuring_dns" "Configuring Chrony"
    
    # Backup existing configuration
    if [[ -f "$CHRONY_CONFIG_FILE" ]]; then
        backup_file "$CHRONY_CONFIG_FILE"
    fi
    
    # Generate configuration
    local config=""
    
    # NTP servers
    if [[ -n "$ntp_servers" ]]; then
        i18n_info "info" "Using custom NTP servers: $ntp_servers"
        IFS=',' read -ra servers <<< "$ntp_servers"
        for server in "${servers[@]}"; do
            server=$(echo "$server" | tr -d ' ')
            config+="server $server iburst\n"
        done
    else
        # Default NTP servers (geo-distributed)
        config+="# NTP servers\n"
        config+="pool 2.pool.ntp.org iburst\n"
        config+="pool time.cloudflare.com iburst\n"
        config+="pool time.google.com iburst\n"
    fi
    
    config+="\n"
    
    # Drift file
    config+="# Drift file\n"
    config+="driftfile /var/lib/chrony/drift\n"
    config+="\n"
    
    # Allow NTP client access from local network
    config+="# Allow NTP client access from local network\n"
    config+="allow 192.168.0.0/16\n"
    config+="allow 10.0.0.0/8\n"
    config+="allow 172.16.0.0/12\n"
    config+="\n"
    
    # Serve time even if not synchronized
    config+="# Serve time even if not synchronized\n"
    config+="local stratum 10\n"
    config+="\n"
    
    # Record the rate at which the system clock gains/losses time
    config+="# Record the rate at which the system clock gains/losses time\n"
    config+="rtcsync\n"
    config+="\n"
    
    # Step the system clock instead of slewing if adjustment is larger than 1 second
    config+="# Step the system clock if adjustment is larger than 1 second\n"
    config+="makestep 1.0 3\n"
    config+="\n"
    
    # Enable kernel synchronization of the real-time clock (RTC)
    config+="# Enable kernel synchronization of the real-time clock\n"
    config+="rtconutc\n"
    config+="\n"
    
    # Log files
    config+="# Log files\n"
    config+="logdir /var/log/chrony\n"
    config+="log measurements statistics tracking\n"
    
    # Write configuration
    echo -e "$config" | $sudo_cmd tee "$CHRONY_CONFIG_FILE" > /dev/null
    
    i18n_success "completed" "Chrony configuration"
}

# Start Chrony service
start_chrony_service() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "starting" "Chrony service"
    
    # Enable and start service
    $sudo_cmd systemctl enable "$CHRONY_SERVICE"
    $sudo_cmd systemctl restart "$CHRONY_SERVICE"
    
    # Wait for service to start
    sleep 2
    
    # Check service status
    if ! systemctl is-active "$CHRONY_SERVICE" >/dev/null 2>&1; then
        i18n_error "failed" "Chrony service failed to start"
        return 1
    fi
    
    i18n_success "running" "Chrony service"
}

# Configure timezone
configure_timezone() {
    local timezone="${1:-}"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    if [[ -z "$timezone" ]]; then
        # Auto-detect timezone
        if [[ -f /etc/timezone ]]; then
            timezone=$(cat /etc/timezone)
        elif [[ -L /etc/localtime ]]; then
            timezone=$(readlink /etc/localtime | sed 's|/usr/share/zoneinfo/||')
        else
            timezone="UTC"
        fi
    fi
    
    i18n_info "info" "Setting timezone: $timezone"
    
    # Set timezone
    if has_cmd timedatectl; then
        $sudo_cmd timedatectl set-timezone "$timezone"
    else
        $sudo_cmd ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
    fi
    
    i18n_success "completed" "Timezone configuration"
}

# Show Chrony status
show_chrony_status() {
    print_title "$(msg 'setup_chrony')"
    
    if ! has_cmd chronyc; then
        echo "Chrony: Not installed"
        return 0
    fi
    
    local version
    version=$(chronyc -v 2>&1 | head -1 || echo "unknown")
    echo "Chrony Version: $version"
    echo ""
    
    if systemctl is-active "$CHRONY_SERVICE" >/dev/null 2>&1; then
        echo "Service Status: Running"
        echo ""
        
        echo "Tracking:"
        chronyc tracking 2>/dev/null || echo "  Not available"
        echo ""
        
        echo "Sources:"
        chronyc sources 2>/dev/null || echo "  Not available"
        echo ""
        
        echo "Source Stats:"
        chronyc sourcestats 2>/dev/null || echo "  Not available"
    else
        echo "Service Status: Not running"
    fi
    echo ""
}

# Configure Chrony interactively
configure_chrony_interactive() {
    echo ""
    echo "$(msg 'setup_chrony')"
    echo ""
    
    # Ask for NTP servers
    echo "$(msg 'info') Default NTP servers:"
    echo "  - 2.pool.ntp.org"
    echo "  - time.cloudflare.com"
    echo "  - time.google.com"
    echo ""
    
    local ntp_servers=""
    if ask_yes_no "Use custom NTP servers?" "n"; then
        read -r -p "Enter NTP servers (comma-separated): " ntp_servers
    fi
    
    # Ask for timezone
    echo ""
    local current_tz
    if [[ -f /etc/timezone ]]; then
        current_tz=$(cat /etc/timezone)
    elif [[ -L /etc/localtime ]]; then
        current_tz=$(readlink /etc/localtime | sed 's|/usr/share/zoneinfo/||')
    else
        current_tz="UTC"
    fi
    
    echo "$(msg 'info') Current timezone: $current_tz"
    local timezone="$current_tz"
    if ask_yes_no "Change timezone?" "n"; then
        read -r -p "Enter timezone (e.g., Asia/Shanghai, America/New_York): " timezone
    fi
    
    # Configure Chrony
    configure_chrony "$ntp_servers"
    configure_timezone "$timezone"
    start_chrony_service
}

# Main function
main() {
    local action="${1:-interactive}"
    local ntp_servers="${2:-}"
    local timezone="${3:-}"
    
    print_title "$(msg 'setup_chrony')"
    
    # Detect OS-specific paths
    detect_chrony_paths
    
    case "$action" in
        install)
            i18n_info "starting" "Chrony installation"
            install_chrony
            i18n_success "completed" "Chrony installation"
            ;;
        interactive|config)
            i18n_info "starting" "Chrony configuration"
            install_chrony
            configure_chrony_interactive
            i18n_success "completed" "Chrony configuration"
            ;;
        auto)
            i18n_info "starting" "Chrony setup (auto)"
            install_chrony
            configure_chrony "$ntp_servers"
            if [[ -n "$timezone" ]]; then
                configure_timezone "$timezone"
            fi
            start_chrony_service
            i18n_success "completed" "Chrony setup"
            ;;
        status|show)
            show_chrony_status
            ;;
        *)
            echo "Usage: $0 {install|interactive|auto|status} [ntp-servers] [timezone]"
            echo ""
            echo "Actions:"
            echo "  install      - Install Chrony only"
            echo "  interactive  - Install and configure interactively (default)"
            echo "  auto         - Install and configure automatically"
            echo "  status       - Show Chrony status"
            echo ""
            echo "Examples:"
            echo "  $0 install"
            echo "  $0 interactive"
            echo "  $0 auto \"time1.google.com,time2.google.com\" \"Asia/Shanghai\""
            echo "  $0 status"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
