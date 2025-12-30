#!/usr/bin/env bash
# optimize-network.sh - Network performance optimization
# Enables BBR congestion control and network tuning

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load common functions and i18n
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

# Check kernel version for BBR support
check_bbr_support() {
    local kernel_version
    kernel_version=$(uname -r | cut -d. -f1-2)
    local major minor
    major=$(echo "$kernel_version" | cut -d. -f1)
    minor=$(echo "$kernel_version" | cut -d. -f2)
    
    if [[ $major -lt 4 ]] || [[ $major -eq 4 && $minor -lt 9 ]]; then
        return 1
    fi
    
    return 0
}

# Enable BBR congestion control
enable_bbr() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "optimizing_network" "BBR congestion control"
    
    # Check kernel support
    if ! check_bbr_support; then
        local kernel_version
        kernel_version=$(uname -r)
        i18n_warn "failed" "Kernel $kernel_version does not support BBR (requires 4.9+)"
        return 1
    fi
    
    # Create sysctl configuration
    $sudo_cmd tee /etc/sysctl.d/99-bbr.conf > /dev/null << 'EOF'
# BBR Congestion Control Algorithm
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# Network Buffer Optimization
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728

# TCP Optimization
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1

# Connection Tracking
net.netfilter.nf_conntrack_max = 1048576
net.nf_conntrack_max = 1048576

# IPv6 Optimization
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
EOF
    
    # Apply configuration
    $sudo_cmd sysctl --system >/dev/null 2>&1
    
    i18n_success "network_optimized" "BBR enabled"
}

# Enable network forwarding
enable_forwarding() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "optimizing_network" "IP forwarding"
    
    # Create sysctl configuration
    $sudo_cmd tee /etc/sysctl.d/99-forwarding.conf > /dev/null << 'EOF'
# IP Forwarding
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
EOF
    
    # Apply configuration
    $sudo_cmd sysctl --system >/dev/null 2>&1
    
    i18n_success "network_optimized" "IP forwarding enabled"
}

# Optimize network interface
optimize_interface() {
    local interface="${1:-}"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    if [[ -z "$interface" ]]; then
        interface=$(get_primary_interface)
    fi
    
    if [[ -z "$interface" || "$interface" == "unknown" ]]; then
        i18n_warn "failed" "Cannot detect network interface"
        return 1
    fi
    
    i18n_info "optimizing_network" "Interface: $interface"
    
    # Check if ethtool is available
    if ! has_cmd ethtool; then
        i18n_info "info" "Installing ethtool"
        install_package ethtool || true
    fi
    
    if has_cmd ethtool; then
        # Enable GRO (Generic Receive Offload)
        $sudo_cmd ethtool -K "$interface" gro on 2>/dev/null || true
        
        # Enable UDP GRO forwarding (for Tailscale/WireGuard)
        $sudo_cmd ethtool -K "$interface" rx-udp-gro-forwarding on 2>/dev/null || true
        
        # Enable TSO (TCP Segmentation Offload)
        $sudo_cmd ethtool -K "$interface" tso on 2>/dev/null || true
        
        # Enable GSO (Generic Segmentation Offload)
        $sudo_cmd ethtool -K "$interface" gso on 2>/dev/null || true
        
        i18n_success "network_optimized" "Interface $interface optimized"
    fi
}

# Create systemd service for persistent interface optimization
create_interface_optimization_service() {
    local interface="$1"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "create_dir" "Systemd service for interface optimization"
    
    # Create service template
    $sudo_cmd tee /etc/systemd/system/network-optimize@.service > /dev/null << 'EOF'
[Unit]
Description=Network optimization for %i
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ethtool -K %i gro on
ExecStart=/usr/sbin/ethtool -K %i rx-udp-gro-forwarding on
ExecStart=/usr/sbin/ethtool -K %i tso on
ExecStart=/usr/sbin/ethtool -K %i gso on
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable service for interface
    $sudo_cmd systemctl daemon-reload
    $sudo_cmd systemctl enable "network-optimize@$interface" --now 2>/dev/null || true
    
    i18n_success "completed" "Systemd service created"
}

# Verify network optimization
verify_optimization() {
    i18n_info "info" "Verifying network optimization"
    
    echo ""
    echo "Current Configuration:"
    echo ""
    
    # Check BBR
    local qdisc cc
    qdisc=$(sysctl net.core.default_qdisc 2>/dev/null | awk '{print $3}' || echo "unknown")
    cc=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}' || echo "unknown")
    
    echo "Queue Discipline: $qdisc"
    echo "Congestion Control: $cc"
    
    if [[ "$qdisc" == "fq" && "$cc" == "bbr" ]]; then
        echo "  ✓ BBR and FQ enabled"
    else
        echo "  ✗ BBR or FQ not enabled"
    fi
    echo ""
    
    # Check forwarding
    local ipv4_forward ipv6_forward
    ipv4_forward=$(sysctl net.ipv4.ip_forward 2>/dev/null | awk '{print $3}' || echo "0")
    ipv6_forward=$(sysctl net.ipv6.conf.all.forwarding 2>/dev/null | awk '{print $3}' || echo "0")
    
    echo "IPv4 Forwarding: $ipv4_forward"
    echo "IPv6 Forwarding: $ipv6_forward"
    echo ""
    
    # Show available congestion control algorithms
    if [[ -f /proc/sys/net/ipv4/tcp_available_congestion_control ]]; then
        local available
        available=$(cat /proc/sys/net/ipv4/tcp_available_congestion_control)
        echo "Available Congestion Control: $available"
    fi
    echo ""
}

# Optimize network interactively
optimize_network_interactive() {
    echo ""
    echo "$(msg 'optimize_network')"
    echo ""
    
    # Show current status
    verify_optimization
    
    # Ask for optimizations
    echo "Select optimizations to apply:"
    echo ""
    
    local enable_bbr_opt="false"
    if ask_yes_no "Enable BBR congestion control?"; then
        enable_bbr_opt="true"
    fi
    
    local enable_forward_opt="false"
    if ask_yes_no "Enable IP forwarding?"; then
        enable_forward_opt="true"
    fi
    
    local optimize_iface_opt="false"
    local interface=""
    if ask_yes_no "Optimize network interface?"; then
        optimize_iface_opt="true"
        interface=$(get_primary_interface)
        echo "$(msg 'info') Detected interface: $interface"
        read -r -p "Use this interface? [Y/n] " confirm
        if [[ "$confirm" =~ ^[Nn]$ ]]; then
            read -r -p "Enter interface name: " interface
        fi
    fi
    
    # Apply optimizations
    echo ""
    i18n_info "starting" "Network optimization"
    
    if [[ "$enable_bbr_opt" == "true" ]]; then
        enable_bbr
    fi
    
    if [[ "$enable_forward_opt" == "true" ]]; then
        enable_forwarding
    fi
    
    if [[ "$optimize_iface_opt" == "true" && -n "$interface" ]]; then
        optimize_interface "$interface"
        
        if ask_yes_no "Create persistent optimization service?"; then
            create_interface_optimization_service "$interface"
        fi
    fi
    
    echo ""
    i18n_success "completed" "Network optimization"
    echo ""
    
    # Show results
    verify_optimization
}

# Apply all optimizations
optimize_all() {
    local interface="${1:-}"
    
    i18n_info "starting" "Full network optimization"
    
    # Enable BBR
    enable_bbr || i18n_warn "failed" "BBR optimization failed"
    
    # Enable forwarding
    enable_forwarding
    
    # Optimize interface
    if [[ -z "$interface" ]]; then
        interface=$(get_primary_interface)
    fi
    
    if [[ -n "$interface" && "$interface" != "unknown" ]]; then
        optimize_interface "$interface"
        create_interface_optimization_service "$interface"
    fi
    
    i18n_success "completed" "Full network optimization"
}

# Main function
main() {
    local action="${1:-interactive}"
    local interface="${2:-}"
    
    print_title "$(msg 'optimize_network')"
    
    case "$action" in
        interactive)
            optimize_network_interactive
            ;;
        all)
            optimize_all "$interface"
            verify_optimization
            ;;
        bbr)
            i18n_info "starting" "BBR optimization"
            enable_bbr
            verify_optimization
            i18n_success "completed" "BBR optimization"
            ;;
        forwarding)
            i18n_info "starting" "IP forwarding"
            enable_forwarding
            verify_optimization
            i18n_success "completed" "IP forwarding"
            ;;
        interface)
            if [[ -z "$interface" ]]; then
                interface=$(get_primary_interface)
            fi
            i18n_info "starting" "Interface optimization"
            optimize_interface "$interface"
            create_interface_optimization_service "$interface"
            i18n_success "completed" "Interface optimization"
            ;;
        verify|show)
            verify_optimization
            ;;
        *)
            echo "Usage: $0 {interactive|all|bbr|forwarding|interface|verify} [interface]"
            echo ""
            echo "Actions:"
            echo "  interactive  - Optimize network interactively (default)"
            echo "  all          - Apply all optimizations"
            echo "  bbr          - Enable BBR congestion control only"
            echo "  forwarding   - Enable IP forwarding only"
            echo "  interface    - Optimize network interface only"
            echo "  verify       - Verify current optimization status"
            echo ""
            echo "Examples:"
            echo "  $0 interactive"
            echo "  $0 all"
            echo "  $0 bbr"
            echo "  $0 interface eth0"
            echo "  $0 verify"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
