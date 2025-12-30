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
                "config_management") echo "配置管理" ;;
                "import_config") echo "导入配置码" ;;
                "export_config") echo "导出配置码" ;;
                "quick_setup") echo "快速配置" ;;
                "components") echo "独立组件" ;;
                "hostname_mgmt") echo "主机名管理" ;;
                "network_config") echo "网络配置" ;;
                "system_config") echo "系统配置" ;;
                "k3s_section") echo "K3s 部署" ;;
                "k3s_deploy") echo "部署 K3s" ;;
                "utilities") echo "实用工具" ;;
                "view_config") echo "查看配置" ;;
                "security_cleanup") echo "安全清理" ;;
                "advanced") echo "高级功能" ;;
                "reinstall_prep") echo "重装准备" ;;
                "exit") echo "退出" ;;
                "select") echo "选择" ;;
                "cancel") echo "取消" ;;
                "confirm") echo "确认" ;;
                "back") echo "返回主菜单" ;;
                "prepare_wizard") echo "重装准备向导" ;;
                "reinstall_os") echo "生成重装脚本" ;;
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
                "downloading_utils") echo "下载工具脚本..." ;;
                "failed_download_utils") echo "工具脚本下载失败" ;;
                "utils_ready") echo "工具脚本准备就绪" ;;
                *) echo "$key" ;;
            esac
            ;;
        *)
            case "$key" in
                "banner_title") echo "Server Toolkit v${VERSION}" ;;
                "banner_subtitle") echo "Modular Server Management Solution" ;;
                "main_menu_title") echo "Server Toolkit - Main Menu" ;;
                "config_management") echo "Configuration Management" ;;
                "import_config") echo "Import Config Code" ;;
                "export_config") echo "Export Config Code" ;;
                "quick_setup") echo "Quick Setup" ;;
                "components") echo "Components" ;;
                "hostname_mgmt") echo "Hostname Management" ;;
                "network_config") echo "Network Configuration" ;;
                "system_config") echo "System Configuration" ;;
                "k3s_section") echo "K3s Deployment" ;;
                "k3s_deploy") echo "Deploy K3s" ;;
                "utilities") echo "Utilities" ;;
                "view_config") echo "View Configuration" ;;
                "security_cleanup") echo "Security Cleanup" ;;
                "advanced") echo "Advanced" ;;
                "reinstall_prep") echo "Reinstall Preparation" ;;
                "exit") echo "Exit" ;;
                "select") echo "Select" ;;
                "cancel") echo "Cancel" ;;
                "confirm") echo "Confirm" ;;
                "back") echo "Back to Main Menu" ;;
                "prepare_wizard") echo "Preparation Wizard" ;;
                "reinstall_os") echo "Generate Reinstall Script" ;;
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
                "downloading_utils") echo "Downloading utility scripts..." ;;
                "failed_download_utils") echo "Failed to download utility scripts" ;;
                "utils_ready") echo "Utility scripts ready" ;;
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
    
    # Export environment variables for child scripts
    export TOOLKIT_LANG
    export SCRIPT_DIR
    export BASE_URL
    export REPO_OWNER
    export REPO_NAME
    export REPO_BRANCH
    
    # Execute with sudo if not root
    if [[ "$(id -u)" -eq 0 ]]; then
        bash "$local_path" "${args[@]}"
    else
        sudo -E bash "$local_path" "${args[@]}"
    fi
    
    local exit_code=$?
    
    # Cleanup after execution (but keep utils)
    if [[ "$script_path" != utils/* ]]; then
        rm -f "$local_path"
    fi
    
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
    echo -e "${YELLOW}🔧 $(msg 'config_management')${NC}"
    echo "  [1] $(msg 'import_config')"
    echo "  [2] $(msg 'export_config')"
    echo "  [3] $(msg 'quick_setup')"
    echo ""
    echo -e "${YELLOW}⚙️  $(msg 'components')${NC}"
    echo "  [4] $(msg 'hostname_mgmt')"
    echo "  [5] $(msg 'network_config')"
    echo "  [6] $(msg 'system_config')"
    echo ""
    echo -e "${BLUE}🚀 $(msg 'k3s_section')${NC}"
    echo "  [7] $(msg 'k3s_deploy')"
    echo ""
    echo -e "${BLUE}📊 $(msg 'utilities')${NC}"
    echo "  [8] $(msg 'view_config')"
    echo ""
    echo -e "${CYAN}💾 $(msg 'advanced')${NC}"
    echo "  [9] $(msg 'reinstall_prep')"
    echo ""
    echo -e "${RED}[0] $(msg 'exit')${NC}"
    echo ""
    echo -e "${CYAN}💡 提示: 安全清理将在退出时自动执行${NC}"
    echo ""
}

# ==================== Configuration Management ====================

import_config_code() {
    log_info "$(msg 'import_config')"
    download_and_run "workflows/import-config.sh" "interactive"
}

export_config_code() {
    log_info "$(msg 'export_config')"
    download_and_run "workflows/export-config.sh" "current"
}

quick_setup() {
    log_info "$(msg 'quick_setup')"
    download_and_run "workflows/quick-setup.sh"
}

# ==================== Components ====================

hostname_management() {
    log_info "$(msg 'hostname_mgmt')"
    # Download component scripts
    download_script "components/hostname/generate.sh"
    download_script "components/hostname/apply.sh"
    download_and_run "components/hostname/manage.sh"
}

view_configuration() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Current Configuration${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Show hostname
    echo "Hostname:"
    echo "  Short: $(hostname)"
    echo "  FQDN: $(hostname -f 2>/dev/null || hostname)"
    echo ""
    
    # Show network
    echo "Network:"
    if download_script "components/network/detect.sh"; then
        bash "${SCRIPT_DIR}/components/network/detect.sh" human
    fi
    echo ""
    
    # Show system
    echo "System:"
    echo "  OS: $(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo 'Unknown')"
    echo "  Kernel: $(uname -r)"
    echo "  Timezone: $(timedatectl show -p Timezone --value 2>/dev/null || echo 'Unknown')"
    echo ""
}

reinstall_preparation() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Reinstall Preparation${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  [1] $(msg 'prepare_wizard')"
    echo "  [2] $(msg 'reinstall_os')"
    echo "  [0] $(msg 'back')"
    echo ""
    read -p "$(msg 'select') [0-2]: " choice
    
    case $choice in
        1) download_and_run "pre-reinstall/prepare-wizard.sh" ;;
        2) download_and_run "pre-reinstall/reinstall-os.sh" ;;
        0) return ;;
        *) log_error "$(msg 'invalid_choice')" ;;
    esac
}

# ==================== Pre-Reinstall Tools ====================

prepare_wizard() {
    i18n_info "starting" "Preparation wizard"
    download_and_run "pre-reinstall/prepare-wizard.sh"
}

reinstall_os() {
    i18n_info "starting" "OS reinstall script generation"
    download_and_run "pre-reinstall/reinstall-os.sh"
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

# ==================== Main Loop ====================

main_loop() {
    while true; do
        show_main_menu
        read -p "$(msg 'select') [0-9]: " choice
        
        case $choice in
            1) import_config_code ;;
            2) export_config_code ;;
            3) quick_setup ;;
            4) hostname_management ;;
            5) network_configuration ;;
            6) system_configuration ;;
            7) k3s_deployment ;;
            8) view_configuration ;;
            9) reinstall_preparation ;;
            0)
                echo ""
                log_info "$(msg 'thank_you')"
                cleanup_and_exit 0
                ;;
            *)
                log_error "$(msg 'invalid_choice') 0-9."
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
    
    # Auto security cleanup (always run)
    log_info "执行安全清理..."
    if download_script "utils/cleanup.sh"; then
        bash "${SCRIPT_DIR}/utils/cleanup.sh" >/dev/null 2>&1 || true
    fi
    
    log_success "$(msg 'cleanup_complete')"
    
    # Remove trap to avoid recursive call
    trap - INT TERM EXIT
    
    exit "$exit_code"
}

# Trap signals for cleanup
trap 'cleanup_and_exit 1' INT TERM EXIT

# ==================== Main Entry Point ====================

# ==================== Language Selection ====================

select_language() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Language Selection / 语言选择${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  [1] English"
    echo "  [2] 中文"
    echo ""
    read -p "Select language / 选择语言 [1-2]: " lang_choice
    
    case $lang_choice in
        1)
            TOOLKIT_LANG="en"
            ;;
        2)
            TOOLKIT_LANG="zh"
            ;;
        *)
            # Default to auto-detect
            TOOLKIT_LANG=$(detect_language)
            ;;
    esac
    
    export TOOLKIT_LANG
}

# ==================== Dependency Management ====================

# Download utility scripts (common.sh, i18n.sh, common-header.sh)
download_utils() {
    log_info "$(msg 'downloading_utils')"
    
    # Download common.sh
    if ! download_script "utils/common.sh"; then
        log_error "$(msg 'failed_download_utils')"
        return 1
    fi
    
    # Download i18n.sh
    if ! download_script "utils/i18n.sh"; then
        log_error "$(msg 'failed_download_utils')"
        return 1
    fi
    
    # Download common-header.sh
    if ! download_script "utils/common-header.sh"; then
        log_error "$(msg 'failed_download_utils')"
        return 1
    fi
    
    log_success "$(msg 'utils_ready')"
    return 0
}

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
    
    # Language selection (interactive)
    select_language
    
    # Download utility scripts first
    download_utils || exit 1
    
    # Start main loop
    main_loop
}

# Run main function
main "$@"
