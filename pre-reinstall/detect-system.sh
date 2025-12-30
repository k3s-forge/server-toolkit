#!/usr/bin/env bash
# detect-system.sh - System detection and information gathering
# Migrated from k3s-setup/scripts/system-info.sh

set -Eeuo pipefail

# Load common header (handles both standalone and bootstrap execution)
if [[ -n "${SCRIPT_DIR:-}" ]] && [[ -f "$SCRIPT_DIR/utils/common-header.sh" ]]; then
    source "$SCRIPT_DIR/utils/common-header.sh"
else
    # Fallback for standalone execution
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TOOLKIT_ROOT="$(dirname "$CURRENT_DIR")"
    
    if [[ -f "$TOOLKIT_ROOT/utils/common.sh" ]]; then
        source "$TOOLKIT_ROOT/utils/common.sh"
    else
        echo "Error: common.sh not found"
        exit 1
    fi
    
    if [[ -f "$TOOLKIT_ROOT/utils/i18n.sh" ]]; then
        source "$TOOLKIT_ROOT/utils/i18n.sh"
    fi
fi

# Detect operating system
detect_os() {
    local os_id="" os_version="" os_name=""
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        os_id="$ID"
        os_version="${VERSION_ID:-unknown}"
        os_name="$PRETTY_NAME"
    elif has_cmd lsb_release; then
        os_id=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        os_version=$(lsb_release -sr)
        os_name=$(lsb_release -sd)
    else
        os_id="unknown"
        os_version="unknown"
        os_name="Unknown Operating System"
    fi
    
    echo "os_id='$os_id'"
    echo "os_version='$os_version'"
    echo "os_name='$os_name'"
}

# Detect package manager
detect_package_manager() {
    local pm=""
    
    if has_cmd apt-get; then
        pm="apt"
    elif has_cmd dnf; then
        pm="dnf"
    elif has_cmd yum; then
        pm="yum"
    elif has_cmd apk; then
        pm="apk"
    elif has_cmd pacman; then
        pm="pacman"
    elif has_cmd zypper; then
        pm="zypper"
    else
        pm="unknown"
    fi
    
    echo "package_manager='$pm'"
}

# Detect system architecture
detect_architecture() {
    local arch=""
    arch=$(uname -m)
    
    case "$arch" in
        x86_64|amd64)
            arch="amd64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        armv7l|armhf)
            arch="armhf"
            ;;
        *)
            arch="$arch"
            ;;
    esac
    
    echo "architecture='$arch'"
}

# Detect hardware information
detect_hardware() {
    local memory_gb cpu_cores disk_size_gb disk_type
    
    # Memory (GB)
    if [[ -f /proc/meminfo ]]; then
        local memory_kb
        memory_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        memory_gb=$((memory_kb / 1024 / 1024))
    else
        memory_gb="unknown"
    fi
    
    # CPU cores
    if [[ -f /proc/cpuinfo ]]; then
        cpu_cores=$(grep -c "^processor" /proc/cpuinfo)
    else
        cpu_cores="unknown"
    fi
    
    # Disk size (GB)
    disk_size_gb=$(df --output=size / 2>/dev/null | tail -n1 | awk '{print int($1/1024/1024)}')
    
    # Disk type
    local root_device
    root_device=$(df --output=source / | tail -n1 | sed 's/[0-9]*$//')
    if [[ -e "/sys/block/$(basename "$root_device")/queue/rotational" ]]; then
        if [[ "$(cat "/sys/block/$(basename "$root_device")/queue/rotational")" == "0" ]]; then
            disk_type="ssd"
        else
            disk_type="hdd"
        fi
    else
        disk_type="unknown"
    fi
    
    echo "memory_gb='$memory_gb'"
    echo "cpu_cores='$cpu_cores'"
    echo "disk_size_gb='$disk_size_gb'"
    echo "disk_type='$disk_type'"
}

# Detect network information
detect_network() {
    local primary_interface primary_ip public_ip
    
    # Get primary network interface
    primary_interface=$(get_primary_interface)
    primary_ip=$(get_primary_ip)
    
    # Get public IP (if possible)
    if check_network "8.8.8.8" "53" "3"; then
        public_ip=$(curl -fsSL --connect-timeout 3 --max-time 6 "https://api.ipify.org" 2>/dev/null || echo "unknown")
    else
        public_ip="unknown"
    fi
    
    echo "primary_interface='${primary_interface:-unknown}'"
    echo "primary_ip='${primary_ip:-unknown}'"
    echo "public_ip='${public_ip:-unknown}'"
}

# Detect all IP addresses
detect_all_ip_addresses() {
    exec 3>&1
    exec 1>&2
    
    local all_ipv4=() all_ipv6=() interface_ips=()
    
    log_info "Detecting all system IP addresses..."
    
    # Get all active network interfaces
    local interfaces
    if has_cmd ip; then
        interfaces=$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -v lo | head -10)
    elif has_cmd ifconfig; then
        interfaces=$(ifconfig 2>/dev/null | grep "^[a-zA-Z]" | awk '{print $1}' | grep -v lo | head -10)
    else
        log_warn "Cannot detect network interfaces"
        exec 1>&3
        return 1
    fi
    
    # Iterate through each interface to collect IP addresses
    for interface in $interfaces; do
        [[ "$interface" =~ ^(lo|docker|br-|veth) ]] && continue
        
        local ipv4_addrs=() ipv6_addrs=()
        
        if has_cmd ip; then
            while IFS= read -r line; do
                [[ -n "$line" ]] && ipv4_addrs+=("$line")
            done < <(ip -4 addr show "$interface" 2>/dev/null | grep -oP 'inet \K[\d.]+' || true)
            
            while IFS= read -r line; do
                [[ -n "$line" ]] && ipv6_addrs+=("$line")
            done < <(ip -6 addr show "$interface" 2>/dev/null | grep -oP 'inet6 \K[a-f0-9:]+' | grep -v '^fe80:' || true)
        elif has_cmd ifconfig; then
            while IFS= read -r line; do
                [[ -n "$line" ]] && ipv4_addrs+=("$line")
            done < <(ifconfig "$interface" 2>/dev/null | grep -oP 'inet \K[\d.]+' || true)
            
            while IFS= read -r line; do
                [[ -n "$line" ]] && ipv6_addrs+=("$line")
            done < <(ifconfig "$interface" 2>/dev/null | grep -oP 'inet6 \K[a-f0-9:]+' | grep -v '^fe80:' || true)
        fi
        
        if [[ ${#ipv4_addrs[@]} -gt 0 || ${#ipv6_addrs[@]} -gt 0 ]]; then
            local interface_info="${interface}|${ipv4_addrs[*]}|${ipv6_addrs[*]}"
            interface_ips+=("$interface_info")
            
            for ip in "${ipv4_addrs[@]}"; do
                [[ "$ip" =~ ^(127\.|169\.254\.) ]] && continue
                all_ipv4+=("$ip")
            done
            
            for ip in "${ipv6_addrs[@]}"; do
                [[ "$ip" =~ ^(::1|fe80:) ]] && continue
                all_ipv6+=("$ip")
            done
        fi
    done
    
    log_info "Found IPv4 addresses: ${#all_ipv4[@]}"
    for ip in "${all_ipv4[@]}"; do
        log_info "  IPv4: $ip"
    done
    
    log_info "Found IPv6 addresses: ${#all_ipv6[@]}"
    for ip in "${all_ipv6[@]}"; do
        log_info "  IPv6: $ip"
    done
    
    exec 1>&3
    echo "all_ipv4_addresses='${all_ipv4[*]}'"
    echo "all_ipv6_addresses='${all_ipv6[*]}'"
    echo "interface_ip_mapping='${interface_ips[*]}'"
}

# Detect virtualization environment
detect_virtualization() {
    local virt_type=""
    
    if has_cmd systemd-detect-virt; then
        virt_type=$(systemd-detect-virt 2>/dev/null || echo "none")
    elif [[ -f /proc/cpuinfo ]]; then
        if grep -q "hypervisor" /proc/cpuinfo; then
            virt_type="vm"
        else
            virt_type="none"
        fi
    else
        virt_type="unknown"
    fi
    
    echo "virtualization='$virt_type'"
}

# Detect container runtime
detect_container_runtime() {
    local docker_version="" containerd_version=""
    
    if has_cmd docker; then
        docker_version=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo "unknown")
    else
        docker_version="not_installed"
    fi
    
    if has_cmd containerd; then
        containerd_version=$(containerd --version 2>/dev/null | awk '{print $3}' || echo "unknown")
    else
        containerd_version="not_installed"
    fi
    
    echo "docker_version='${docker_version}'"
    echo "containerd_version='${containerd_version}'"
}

# Detect system services
detect_services() {
    local services=("chronyd" "chrony" "docker" "containerd" "tailscaled" "sshd" "ssh" "k3s")
    local active_services=()
    
    for service in "${services[@]}"; do
        if check_service "$service" 2>/dev/null; then
            active_services+=("$service")
        fi
    done
    
    echo "active_services='${active_services[*]}'"
}

# Generate system information report
generate_system_report() {
    local report_file="${1:-system-info.txt}"
    
    log_info "Generating system information report: $report_file"
    
    {
        echo "=== Server Toolkit - System Information Report ==="
        echo "Generated: $(date)"
        echo ""
        
        echo "=== Operating System ==="
        detect_os
        detect_package_manager
        detect_architecture
        echo ""
        
        echo "=== Hardware ==="
        detect_hardware
        echo ""
        
        echo "=== Network ==="
        detect_network
        echo ""
        
        echo "=== All IP Addresses ==="
        detect_all_ip_addresses
        echo ""
        
        echo "=== Virtualization ==="
        detect_virtualization
        echo ""
        
        echo "=== Container Runtime ==="
        detect_container_runtime
        echo ""
        
        echo "=== System Services ==="
        detect_services
        echo ""
        
        echo "=== Disk Usage ==="
        df -h / 2>/dev/null || echo "Cannot get disk information"
        echo ""
        
        echo "=== Memory Usage ==="
        free -h 2>/dev/null || echo "Cannot get memory information"
        echo ""
        
        echo "=== System Load ==="
        uptime 2>/dev/null || echo "Cannot get load information"
        echo ""
        
        echo "=== Network Interfaces ==="
        ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "Cannot get network interface information"
        echo ""
        
        echo "=== Kernel Information ==="
        uname -a 2>/dev/null || echo "Cannot get kernel information"
        
    } > "$report_file"
    
    log_info "System information report saved to: $report_file"
}

# Check network connectivity
check_network_connectivity() {
    log_info "Checking network connectivity..."
    
    local test_sites=("8.8.8.8:53" "1.1.1.1:53" "github.com:443")
    local failed_count=0
    
    for site in "${test_sites[@]}"; do
        local host port
        IFS=':' read -r host port <<< "$site"
        
        if check_network "$host" "$port" "5"; then
            log_info "✓ Connected to $site successfully"
        else
            log_warn "✗ Failed to connect to $site"
            failed_count=$((failed_count + 1))
        fi
    done
    
    if [ $failed_count -gt 2 ]; then
        log_warn "Network connectivity may have issues"
        return 1
    fi
    
    log_info "Network connectivity check complete"
    return 0
}

# Main function
main() {
    local output_file="${1:-system-info.txt}"
    
    log_info "Starting system detection..."
    
    # Check network connectivity
    check_network_connectivity || log_warn "Network connectivity has issues, some features may be limited"
    
    # Get operating system information
    local os_info
    os_info=$(detect_os)
    eval "$os_info"
    
    # Get package manager information
    local pm_info
    pm_info=$(detect_package_manager)
    eval "$pm_info"
    
    log_info "Detected OS: ${os_name:-Unknown}"
    log_info "Package manager: ${package_manager:-unknown}"
    
    # Generate system information report
    generate_system_report "$output_file"
    
    log_info "✅ System detection complete"
    log_info "Report saved to: $output_file"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
