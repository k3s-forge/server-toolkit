#!/usr/bin/env bash
# common.sh - Common utility functions for Server Toolkit
# Version: 1.0.0

# ==================== Color Definitions ====================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    NC=''
fi

# ==================== Logging Functions ====================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
    fi
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

# ==================== Command Checking ====================

# Check if command exists
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
is_root() {
    [[ "$(id -u)" -eq 0 ]]
}

# Get sudo command prefix
get_sudo() {
    if is_root; then
        echo ""
    elif has_cmd sudo; then
        echo "sudo"
    else
        log_error "Root privileges or sudo command required"
        return 1
    fi
}

# ==================== User Interaction ====================

# Ask yes/no question
ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local ans
    local hint="[Y/n]"
    
    if [[ "$default" =~ ^[Nn]$ ]]; then
        hint="[y/N]"
    fi
    
    while true; do
        read -r -p "$prompt $hint " ans
        
        if [[ -z "$ans" ]]; then
            ans="$default"
        fi
        
        case "$ans" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo])
                return 1
                ;;
            *)
                echo "Please enter y or n"
                ;;
        esac
    done
}

# Wait for user input
wait_for_key() {
    local prompt="${1:-Press any key to continue...}"
    read -r -n 1 -p "$prompt"
    echo
}

# ==================== File Operations ====================

# Check if file exists
file_exists() {
    [[ -f "$1" ]]
}

# Check if directory exists
dir_exists() {
    [[ -d "$1" ]]
}

# Ensure directory exists
ensure_dir() {
    local dir="$1"
    local mode="${2:-755}"
    
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        chmod "$mode" "$dir"
        log_debug "Created directory: $dir"
    fi
}

# Backup file safely
backup_file() {
    local file="$1"
    local backup_dir="${2:-$(dirname "$file")}"
    local timestamp="$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$file" ]]; then
        local backup_file="${backup_dir}/$(basename "$file").backup.${timestamp}"
        cp "$file" "$backup_file"
        log_info "Backed up file: $file -> $backup_file"
    fi
}

# Set file permissions
set_file_permissions() {
    local file="$1"
    local owner="${2:-root:root}"
    local mode="${3:-644}"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    if [[ -f "$file" ]] || [[ -d "$file" ]]; then
        $sudo_cmd chown "$owner" "$file"
        $sudo_cmd chmod "$mode" "$file"
        log_debug "Set permissions: $file ($owner:$mode)"
    fi
}

# ==================== Validation Functions ====================

# Validate IP address
validate_ip() {
    local ip="$1"
    local stat=1
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    
    return $stat
}

# Validate port number
validate_port() {
    local port="$1"
    
    if [[ "$port" =~ ^[0-9]+$ ]] && [[ "$port" -ge 1 ]] && [[ "$port" -le 65535 ]]; then
        return 0
    else
        return 1
    fi
}

# ==================== Network Functions ====================

# Get primary network interface
get_primary_interface() {
    local interface=""
    
    if has_cmd ip; then
        # Method 1: Get from default route
        interface=$(ip route show default 2>/dev/null | head -1 | grep -oP 'dev \K\w+' || echo "")
        
        # Method 2: Get first non-loopback interface
        if [[ -z "$interface" ]]; then
            interface=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -1 | tr -d ' ' || echo "")
        fi
    elif has_cmd netstat; then
        interface=$(netstat -rn 2>/dev/null | awk '/^0.0.0.0/ {print $NF}' | head -1 || echo "")
    elif has_cmd ifconfig; then
        interface=$(ifconfig | grep "^[a-zA-Z]" | grep -v "lo" | head -1 | awk '{print $1}' | tr -d ':' || echo "")
    fi
    
    # Fallback to common interface names
    if [[ -z "$interface" ]]; then
        local common_interfaces=("eth0" "ens3" "ens33" "enp0s3" "wlan0")
        for iface in "${common_interfaces[@]}"; do
            if [[ -d "/sys/class/net/$iface" ]]; then
                interface="$iface"
                break
            fi
        done
    fi
    
    echo "${interface:-unknown}"
}

# Get primary IP address
get_primary_ip() {
    local ip=""
    
    if has_cmd ip; then
        # Method 1: Get source IP from default route
        ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[\d.]+' | head -1 || echo "")
        
        # Method 2: Get from primary interface
        if [[ -z "$ip" ]]; then
            local interface
            interface=$(get_primary_interface)
            if [[ "$interface" != "unknown" ]]; then
                ip=$(ip -4 addr show "$interface" 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1 || echo "")
            fi
        fi
    fi
    
    # Method 3: Use hostname command
    if [[ -z "$ip" ]]; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
    fi
    
    # Ensure not returning loopback address
    if [[ "$ip" =~ ^127\. ]]; then
        ip=""
    fi
    
    echo "${ip:-127.0.0.1}"
}

# Check network connectivity
check_network() {
    local host="${1:-8.8.8.8}"
    local port="${2:-53}"
    local timeout="${3:-5}"
    
    if has_cmd nc; then
        nc -z -w "$timeout" "$host" "$port" >/dev/null 2>&1
    elif has_cmd timeout && has_cmd bash; then
        timeout "$timeout" bash -c "</dev/tcp/$host/$port" >/dev/null 2>&1
    else
        return 1
    fi
}

# Download file
download_file() {
    local url="$1"
    local output="$2"
    local timeout="${3:-30}"
    
    if has_cmd curl; then
        curl -fsSL --connect-timeout "$timeout" -o "$output" "$url"
    elif has_cmd wget; then
        wget --timeout="$timeout" -q -O "$output" "$url"
    else
        log_error "curl or wget command not found"
        return 1
    fi
}

# ==================== System Information ====================

# Get system information
get_system_info() {
    local info_type="$1"
    
    case "$info_type" in
        "os")
            if [[ -f /etc/os-release ]]; then
                grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"'
            else
                echo "unknown"
            fi
            ;;
        "version")
            if [[ -f /etc/os-release ]]; then
                grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"'
            else
                echo "unknown"
            fi
            ;;
        "arch")
            uname -m
            ;;
        "kernel")
            uname -r
            ;;
        "hostname")
            hostname -f 2>/dev/null || hostname
            ;;
        "ip")
            get_primary_ip
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Get CPU cores
get_cpu_cores() {
    nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "1"
}

# Get total memory (GB)
get_total_memory() {
    local mem_kb
    mem_kb=$(grep '^MemTotal:' /proc/meminfo | awk '{print $2}')
    echo $((mem_kb / 1024 / 1024))
}

# Check disk space
check_disk_space() {
    local path="${1:-.}"
    local required="${2:-1000000}"  # 1GB in KB
    
    local available
    available=$(df "$path" | tail -1 | awk '{print $4}')
    
    if [[ "$available" -lt "$required" ]]; then
        log_warn "Insufficient disk space: required ${required}KB, available ${available}KB"
        return 1
    else
        return 0
    fi
}

# Check memory
check_memory() {
    local required="${1:-1000000}"  # 1GB in KB
    
    local available
    available=$(free | grep '^Mem:' | awk '{print $7}')
    
    if [[ "$available" -lt "$required" ]]; then
        log_warn "Insufficient memory: required ${required}KB, available ${available}KB"
        return 1
    else
        return 0
    fi
}

# ==================== Service Management ====================

# Check service status
check_service() {
    local service="$1"
    
    if has_cmd systemctl; then
        systemctl is-active --quiet "$service"
    elif has_cmd service; then
        service "$service" status >/dev/null 2>&1
    else
        return 1
    fi
}

# Start service
start_service() {
    local service="$1"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    if has_cmd systemctl; then
        $sudo_cmd systemctl start "$service"
    elif has_cmd service; then
        $sudo_cmd service "$service" start
    else
        return 1
    fi
}

# Stop service
stop_service() {
    local service="$1"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    if has_cmd systemctl; then
        $sudo_cmd systemctl stop "$service"
    elif has_cmd service; then
        $sudo_cmd service "$service" stop
    else
        return 1
    fi
}

# Enable service
enable_service() {
    local service="$1"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    if has_cmd systemctl; then
        $sudo_cmd systemctl enable "$service"
    else
        return 1
    fi
}

# Reload service
reload_service() {
    local service="$1"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    if has_cmd systemctl; then
        $sudo_cmd systemctl reload "$service"
    elif has_cmd service; then
        $sudo_cmd service "$service" reload
    else
        return 1
    fi
}

# ==================== Package Management ====================

# Install package
install_package() {
    local package="$1"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    local os_id
    os_id=$(get_system_info "os")
    
    case "$os_id" in
        ubuntu|debian)
            if ! dpkg -l | grep -q "^ii  $package "; then
                log_info "Installing package: $package"
                $sudo_cmd apt-get update -qq
                $sudo_cmd apt-get install -y "$package"
            fi
            ;;
        centos|rhel|fedora|rocky|almalinux)
            if has_cmd dnf; then
                if ! dnf list installed "$package" >/dev/null 2>&1; then
                    log_info "Installing package: $package"
                    $sudo_cmd dnf install -y "$package"
                fi
            else
                if ! yum list installed "$package" >/dev/null 2>&1; then
                    log_info "Installing package: $package"
                    $sudo_cmd yum install -y "$package"
                fi
            fi
            ;;
        *)
            log_warn "Unsupported OS: $os_id"
            return 1
            ;;
    esac
}

# ==================== Utility Functions ====================

# Generate random string
generate_random_string() {
    local length="${1:-32}"
    
    if has_cmd openssl; then
        openssl rand -hex "$((length/2))"
    elif has_cmd head && [[ -c /dev/urandom ]]; then
        head -c "$length" /dev/urandom | xxd -p -c "$length"
    else
        date +%s | sha256sum | head -c "$length"
    fi
}

# Calculate file MD5
calculate_md5() {
    local file="$1"
    
    if has_cmd md5sum; then
        md5sum "$file" | awk '{print $1}'
    elif has_cmd md5; then
        md5 -q "$file"
    else
        log_error "MD5 calculation tool not found"
        return 1
    fi
}

# Check if process is running
is_process_running() {
    local process="$1"
    pgrep -f "$process" >/dev/null 2>&1
}

# Wait for process to finish
wait_for_process() {
    local process="$1"
    local timeout="${2:-30}"
    local count=0
    
    while is_process_running "$process" && [[ $count -lt $timeout ]]; do
        sleep 1
        count=$((count + 1))
    done
    
    if is_process_running "$process"; then
        log_warn "Process still running: $process"
        return 1
    else
        return 0
    fi
}

# Create system user
create_system_user() {
    local username="$1"
    local home_dir="$2"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    if ! id "$username" >/dev/null 2>&1; then
        if [[ -n "$home_dir" ]]; then
            $sudo_cmd useradd -r -m -d "$home_dir" -s /bin/bash "$username"
        else
            $sudo_cmd useradd -r -s /bin/false "$username"
        fi
        log_info "Created system user: $username"
    else
        log_debug "User already exists: $username"
    fi
}

# Write configuration file
write_config() {
    local file="$1"
    local content="$2"
    local backup="${3:-true}"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    if [[ "$backup" == "true" ]] && [[ -f "$file" ]]; then
        backup_file "$file"
    fi
    
    echo "$content" | $sudo_cmd tee "$file" > /dev/null
    log_debug "Written config file: $file"
}

# Append to configuration file
append_config() {
    local file="$1"
    local content="$2"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    echo "$content" | $sudo_cmd tee -a "$file" > /dev/null
    log_debug "Appended to config file: $file"
}

# Replace configuration line
replace_config_line() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    if [[ -f "$file" ]]; then
        backup_file "$file"
        $sudo_cmd sed -i "s|$pattern|$replacement|g" "$file"
        log_debug "Replaced config in: $file"
    fi
}

log_debug "Common utility functions loaded"
