#!/usr/bin/env bash
# bootstrap.sh - Server Toolkit Main Entry Point
# Version: 1.0.0
# Description: Modular server management toolkit with on-demand script downloading

set -euo pipefail

# ==================== Configuration ====================

# GitHub repository configuration
REPO_OWNER="${REPO_OWNER:-k3s-forge}"
REPO_NAME="${REPO_NAME:-server-toolkit}"
REPO_BRANCH="${REPO_BRANCH:-main}"
BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}"

# Local configuration
SCRIPT_DIR="/tmp/server-toolkit-$$"
DOWNLOAD_TIMEOUT=30
VERSION="1.0.0"

# Detect language
detect_language() {
    local lang="${LANG:-en_US.UTF-8}"
    case "$lang" in
        zh_CN*|zh_TW*|zh_HK*|zh_SG*)
            echo "zh"
            ;;
        *)
            echo "en"
            ;;
    esac
}

# Set language (can be overridden by environment variable)
TOOLKIT_LANG="${TOOLKIT_LANG:-$(detect_language)}"

# ==================== Colors ====================

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

# ==================== Helper Functions ====================

# Get translated text
msg() {
    local key="$1"
    case "$TOOLKIT_LANG" in
        zh)
            case "$key" in
                "banner_title") echo "服务器工具包 v${VERSION}" ;;
                "banner_subtitle") echo "模块化服务器管理解决方案" ;;
                "main_menu_title") echo "服务器工具包 - 主菜单" ;;
                "pre_reinstall_tools") echo "🔧 重装前工具" ;;
                "post_reinstall_tools") echo "🚀 重装后工具" ;;
                "utilities") echo "📊 实用工具" ;;
                "detect_system") echo "检测系统信息" ;;
                "backup_config") echo "备份当前配置" ;;
                "plan_network") echo "规划网络配置" ;;
                "generate_script") echo "生成重装脚本" ;;
                "base_config") echo "基础配置" ;;
                "network_config") echo "网络配置" ;;
                "system_config") echo "系统配置" ;;
                "k3s_deploy") echo "K3s 部署" ;;
                "view_report") echo "查看部署报告" ;;
                "security_cleanup") echo "安全清理" ;;
                "exit") echo "退出" ;;
                "select") echo "选择" ;;
                "base_config_title") echo "基础配置" ;;
                "setup_ip") echo "配置 IP 地址" ;;
                "setup_hostname") echo "配置主机名" ;;
                "setup_dns") echo "配置 DNS" ;;
                "all_base") echo "全部基础配置" ;;
                "back") echo "返回主菜单" ;;
                "network_config_title") echo "网络配置" ;;
                "setup_tailscale") echo "配置 Tailscale" ;;
                "optimize_network") echo "网络优化" ;;
                "all_network") echo "全部网络配置" ;;
                "system_config_title") echo "系统配置" ;;
                "setup_chrony") echo "配置时间同步 (Chrony)" ;;
                "optimize_system") echo "系统优化" ;;
                "setup_security") echo "安全加固" ;;
                "all_system") echo "全部系统配置" ;;
                "k3s_deploy_title") echo "K3s 部署" ;;
                "deploy_k3s") echo "部署 K3s" ;;
                "setup_upgrade") echo "配置升级控制器" ;;
                "deploy_storage") echo "部署存储 (MinIO/Garage)" ;;
                "full_k3s") echo "完整 K3s 部署" ;;
                "info") echo "[信息]" ;;
                "success") echo "[成功]" ;;
                "warn") echo "[警告]" ;;
                "error") echo "[错误]" ;;
                "checking_requirements") echo "检查系统要求..." ;;
                "requirements_passed") echo "系统要求检查通过" ;;
                "starting_detection") echo "开始系统检测..." ;;
                "starting_backup") echo "开始配置备份..." ;;
                "starting_planning") echo "开始网络规划..." ;;
                "generating_reinstall") echo "生成重装脚本..." ;;
                "downloading") echo "下载中" ;;
                "executing") echo "执行中" ;;
                "completed") echo "完成" ;;
                "failed") echo "失败" ;;
                "cleaning_up") echo "清理临时文件..." ;;
                "cleanup_complete") echo "清理完成" ;;
                "thank_you") echo "感谢使用服务器工具包！" ;;
                "invalid_choice") echo "无效选择。请选择" ;;
                "press_enter") echo "按 Enter 继续..." ;;
                "no_report") echo "未找到部署报告" ;;
                "report_after_deploy") echo "报告将在部署后生成" ;;
                "starting_cleanup") echo "开始安全清理..." ;;
                *) echo "$key" ;;
            esac
            ;;
        *)
            case "$key" in
                "banner_title") echo "Server Toolkit v${VERSION}" ;;
                "banner_subtitle") echo "Modular Server Management Solution" ;;
                "main_menu_title") echo "Server Toolkit - Main Menu" ;;
                "pre_reinstall_tools") echo "🔧 Pre-Reinstall Tools" ;;
                "post_reinstall_tools") echo "🚀 Post-Reinstall Tools" ;;
                "utilities") echo "📊 Utilities" ;;
                "detect_system") echo "Detect System Information" ;;
                "backup_config") echo "Backup Current Configuration" ;;
                "plan_network") echo "Plan Network Configuration" ;;
                "generate_script") echo "Generate Reinstall Script" ;;
                "base_config") echo "Base Configuration" ;;
                "network_config") echo "Network Configuration" ;;
                "system_config") echo "System Configuration" ;;
                "k3s_deploy") echo "K3s Deployment" ;;
                "view_report") echo "View Deployment Report" ;;
                "security_cleanup") echo "Security Cleanup" ;;
                "exit") echo "Exit" ;;
                "select") echo "Select" ;;
                "base_config_title") echo "Base Configuration" ;;
                "setup_ip") echo "Setup IP Addresses" ;;
                "setup_hostname") echo "Setup Hostname" ;;
                "setup_dns") echo "Setup DNS" ;;
                "all_base") echo "All Base Configuration" ;;
                "back") echo "Back to Main Menu" ;;
                "network_config_title") echo "Network Configuration" ;;
                "setup_tailscale") echo "Setup Tailscale" ;;
                "optimize_network") echo "Network Optimization" ;;
                "all_network") echo "All Network Configuration" ;;
                "system_config_title") echo "System Configuration" ;;
                "setup_chrony") echo "Setup Time Sync (Chrony)" ;;
                "optimize_system") echo "System Optimization" ;;
                "setup_security") echo "Security Hardening" ;;
                "all_system") echo "All System Configuration" ;;
                "k3s_deploy_title") echo "K3s Deployment" ;;
                "deploy_k3s") echo "Deploy K3s" ;;
                "setup_upgrade") echo "Setup Upgrade Controller" ;;
                "deploy_storage") echo "Deploy Storage (MinIO/Garage)" ;;
                "full_k3s") echo "Full K3s Deployment" ;;
                "info") echo "[INFO]" ;;
                "success") echo "[SUCCESS]" ;;
                "warn") echo "[WARN]" ;;
                "error") echo "[ERROR]" ;;
                "checking_requirements") echo "Checking system requirements..." ;;
                "requirements_passed") echo "System requirements check passed" ;;
                "starting_detection") echo "Starting system detection..." ;;
                "starting_backup") echo "Starting configuration backup..." ;;
                "starting_planning") echo "Starting network planning..." ;;
                "generating_reinstall") echo "Generating reinstall script..." ;;
                "downloading") echo "Downloading" ;;
                "executing") echo "Executing" ;;
                "completed") echo "Completed" ;;
                "failed") echo "Failed" ;;
                "cleaning_up") echo "Cleaning up temporary files..." ;;
                "cleanup_complete") echo "Cleanup complete" ;;
                "thank_you") echo "Thank you for using Server Toolkit!" ;;
                "invalid_choice") echo "Invalid choice. Please select" ;;
                "press_enter") echo "Press Enter to continue..." ;;
                "no_report") echo "No deployment report found" ;;
                "report_after_deploy") echo "Report will be generated after deployment" ;;
                "starting_cleanup") echo "Starting security cleanup..." ;;
                *) echo "$key" ;;
            esac
            ;;
    esac
}

print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              $(msg 'banner_title')              ║"
    echo "║                                                            ║"
    echo "║        $(msg 'banner_subtitle')        ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${CYAN}$(msg 'info')${NC} $*"
}

log_success() {
    echo -e "${GREEN}$(msg 'success')${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}$(msg 'warn')${NC} $*"
}

log_error() {
    echo -e "${RED}$(msg 'error')${NC} $*" >&2
}

# Check if command exists
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_requirements() {
    log_info "$(msg 'checking_requirements')"
    
    local missing_cmds=()
    
    # Check for curl or wget
    if ! has_cmd curl && ! has_cmd wget; then
        missing_cmds+=("curl or wget")
    fi
    
    # Check for bash version
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        log_error "Bash 4.0+ is required (current: ${BASH_VERSION})"
        exit 1
    fi
    
    if [[ ${#missing_cmds[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_cmds[*]}"
        log_info "Please install them and try again"
        exit 1
    fi
    
    # Check for root or sudo
    if [[ "$(id -u)" -ne 0 ]] && ! has_cmd sudo; then
        log_error "Root privileges or sudo is required"
        exit 1
    fi
    
    log_success "$(msg 'requirements_passed')"
}

# ==================== Download Manager ====================

# Download a script from GitHub
download_script() {
    local script_path="$1"
    local local_path="${SCRIPT_DIR}/${script_path}"
    local url="${BASE_URL}/${script_path}"
    
    # Create directory if needed
    mkdir -p "$(dirname "$local_path")"
    
    log_info "$(msg 'downloading'): ${script_path}"
    
    if has_cmd curl; then
        if curl -fsSL --connect-timeout "$DOWNLOAD_TIMEOUT" "$url" -o "$local_path"; then
            chmod +x "$local_path"
            return 0
        fi
    elif has_cmd wget; then
        if wget -q --timeout="$DOWNLOAD_TIMEOUT" "$url" -O "$local_path"; then
            chmod +x "$local_path"
            return 0
        fi
    fi
    
    log_error "$(msg 'failed'): ${script_path}"
    return 1
}

# Download and execute a script
download_and_run() {
    local script_path="$1"
    shift
    local args=("$@")
    
    if ! download_script "$script_path"; then
        return 1
    fi
    
    local local_path="${SCRIPT_DIR}/${script_path}"
    
    log_info "$(msg 'executing'): ${script_path}"
    
    # Export language setting for child scripts
    export TOOLKIT_LANG
    
    # Execute with sudo if not root
    if [[ "$(id -u)" -eq 0 ]]; then
        bash "$local_path" "${args[@]}"
    else
        sudo TOOLKIT_LANG="$TOOLKIT_LANG" bash "$local_path" "${args[@]}"
    fi
    
    local exit_code=$?
    
    # Cleanup after execution
    rm -f "$local_path"
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "$(msg 'completed'): ${script_path}"
    else
        log_error "$(msg 'failed'): ${script_path} (exit code: $exit_code)"
    fi
    
    return $exit_code
}

# ==================== Menu System ====================

show_main_menu() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $(msg 'main_menu_title')${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}$(msg 'pre_reinstall_tools')${NC}"
    echo "  [1] $(msg 'detect_system')"
    echo "  [2] $(msg 'backup_config')"
    echo "  [3] $(msg 'plan_network')"
    echo "  [4] $(msg 'generate_script')"
    echo ""
    echo -e "${YELLOW}$(msg 'post_reinstall_tools')${NC}"
    echo "  [5] $(msg 'base_config')"
    echo "  [6] $(msg 'network_config')"
    echo "  [7] $(msg 'system_config')"
    echo "  [8] $(msg 'k3s_deploy')"
    echo ""
    echo -e "${BLUE}$(msg 'utilities')${NC}"
    echo "  [9] $(msg 'view_report')"
    echo "  [10] $(msg 'security_cleanup')"
    echo ""
    echo -e "${RED}[0] $(msg 'exit')${NC}"
    echo ""
}

# ==================== Pre-Reinstall Tools ====================

detect_system() {
    log_info "$(msg 'starting_detection')"
    download_and_run "pre-reinstall/detect-system.sh"
}

backup_config() {
    log_info "$(msg 'starting_backup')"
    download_and_run "pre-reinstall/backup-config.sh"
}

plan_network() {
    log_info "$(msg 'starting_planning')"
    download_and_run "pre-reinstall/plan-network.sh"
}

generate_reinstall_script() {
    log_info "$(msg 'generating_reinstall')"
    download_and_run "pre-reinstall/prepare-reinstall.sh"
}

# ==================== Post-Reinstall Tools ====================

base_configuration() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $(msg 'base_config_title')${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  [1] $(msg 'setup_ip')"
    echo "  [2] $(msg 'setup_hostname')"
    echo "  [3] $(msg 'setup_dns')"
    echo "  [4] $(msg 'all_base')"
    echo "  [0] $(msg 'back')"
    echo ""
    read -p "$(msg 'select') [0-4]: " choice
    
    case $choice in
        1) download_and_run "post-reinstall/base/setup-ip.sh" ;;
        2) download_and_run "post-reinstall/base/setup-hostname.sh" ;;
        3) download_and_run "post-reinstall/base/setup-dns.sh" ;;
        4)
            download_and_run "post-reinstall/base/setup-ip.sh"
            download_and_run "post-reinstall/base/setup-hostname.sh"
            download_and_run "post-reinstall/base/setup-dns.sh"
            ;;
        0) return ;;
        *) log_error "$(msg 'invalid_choice')" ;;
    esac
}

network_configuration() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $(msg 'network_config_title')${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  [1] $(msg 'setup_tailscale')"
    echo "  [2] $(msg 'optimize_network')"
    echo "  [3] $(msg 'all_network')"
    echo "  [0] $(msg 'back')"
    echo ""
    read -p "$(msg 'select') [0-3]: " choice
    
    case $choice in
        1) download_and_run "post-reinstall/network/setup-tailscale.sh" ;;
        2) download_and_run "post-reinstall/network/optimize-network.sh" ;;
        3)
            download_and_run "post-reinstall/network/setup-tailscale.sh"
            download_and_run "post-reinstall/network/optimize-network.sh"
            ;;
        0) return ;;
        *) log_error "$(msg 'invalid_choice')" ;;
    esac
}

system_configuration() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $(msg 'system_config_title')${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  [1] $(msg 'setup_chrony')"
    echo "  [2] $(msg 'optimize_system')"
    echo "  [3] $(msg 'setup_security')"
    echo "  [4] $(msg 'all_system')"
    echo "  [0] $(msg 'back')"
    echo ""
    read -p "$(msg 'select') [0-4]: " choice
    
    case $choice in
        1) download_and_run "post-reinstall/system/setup-chrony.sh" ;;
        2) download_and_run "post-reinstall/system/optimize-system.sh" ;;
        3) download_and_run "post-reinstall/system/setup-security.sh" ;;
        4)
            download_and_run "post-reinstall/system/setup-chrony.sh"
            download_and_run "post-reinstall/system/optimize-system.sh"
            download_and_run "post-reinstall/system/setup-security.sh"
            ;;
        0) return ;;
        *) log_error "$(msg 'invalid_choice')" ;;
    esac
}

k3s_deployment() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $(msg 'k3s_deploy_title')${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  [1] $(msg 'deploy_k3s')"
    echo "  [2] $(msg 'setup_upgrade')"
    echo "  [3] $(msg 'deploy_storage')"
    echo "  [4] $(msg 'full_k3s')"
    echo "  [0] $(msg 'back')"
    echo ""
    read -p "$(msg 'select') [0-4]: " choice
    
    case $choice in
        1) download_and_run "post-reinstall/k3s/deploy-k3s.sh" ;;
        2) download_and_run "post-reinstall/k3s/setup-upgrade-controller.sh" ;;
        3) download_and_run "post-reinstall/k3s/deploy-storage.sh" ;;
        4)
            download_and_run "post-reinstall/k3s/deploy-k3s.sh"
            download_and_run "post-reinstall/k3s/setup-upgrade-controller.sh"
            download_and_run "post-reinstall/k3s/deploy-storage.sh"
            ;;
        0) return ;;
        *) log_error "$(msg 'invalid_choice')" ;;
    esac
}

# ==================== Utilities ====================

view_deployment_report() {
    local report_file="/root/server-toolkit-report.txt"
    
    if [[ -f "$report_file" ]]; then
        cat "$report_file"
    else
        log_warn "$(msg 'no_report')"
        log_info "$(msg 'report_after_deploy')"
    fi
}

security_cleanup() {
    log_info "$(msg 'starting_cleanup')"
    download_and_run "utils/cleanup.sh"
}

# ==================== Main Loop ====================

main_loop() {
    while true; do
        show_main_menu
        read -p "$(msg 'select') [0-10]: " choice
        
        case $choice in
            1) detect_system ;;
            2) backup_config ;;
            3) plan_network ;;
            4) generate_reinstall_script ;;
            5) base_configuration ;;
            6) network_configuration ;;
            7) system_configuration ;;
            8) k3s_deployment ;;
            9) view_deployment_report ;;
            10) security_cleanup ;;
            0)
                echo ""
                log_info "$(msg 'thank_you')"
                cleanup_and_exit 0
                ;;
            *)
                log_error "$(msg 'invalid_choice') 0-10."
                ;;
        esac
        
        echo ""
        read -p "$(msg 'press_enter')"
    done
}

# ==================== Cleanup ====================

cleanup_and_exit() {
    local exit_code="${1:-0}"
    
    log_info "$(msg 'cleaning_up')"
    
    # Remove temporary directory
    if [[ -d "$SCRIPT_DIR" ]]; then
        rm -rf "$SCRIPT_DIR"
    fi
    
    log_success "$(msg 'cleanup_complete')"
    exit "$exit_code"
}

# Trap signals for cleanup
trap 'cleanup_and_exit 1' INT TERM

# ==================== Main Entry Point ====================

main() {
    # If stdin is not a terminal (piped from curl), redirect to /dev/tty
    if [[ ! -t 0 ]] && [[ -e /dev/tty ]]; then
        exec < /dev/tty
    fi
    
    # Print banner
    print_banner
    
    # Check requirements
    check_requirements
    
    # Create temporary directory
    mkdir -p "$SCRIPT_DIR"
    
    # Start main loop
    main_loop
}

# Run main function
main "$@"
