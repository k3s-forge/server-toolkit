#!/usr/bin/env bash
# i18n.sh - Internationalization support for Server Toolkit
# Supports English (primary) and Chinese (translation)

set -Eeuo pipefail

# Auto-detect system language
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

# English messages (primary language)
declare -A MSG_EN=(
    # Common
    ["info"]="[INFO]"
    ["success"]="[SUCCESS]"
    ["warning"]="[WARNING]"
    ["error"]="[ERROR]"
    ["debug"]="[DEBUG]"
    
    # Permission
    ["check_root"]="Checking root permission..."
    ["need_root"]="Root permission required"
    ["use_sudo"]="Please use: sudo bash"
    
    # System detection
    ["detect_os"]="Detecting operating system..."
    ["os_detected"]="Detected OS"
    ["os_unsupported"]="Unsupported operating system"
    ["detect_hardware"]="Detecting hardware information..."
    ["detect_network"]="Detecting network information..."
    ["detect_services"]="Detecting system services..."
    
    # Network
    ["check_network"]="Checking network connectivity..."
    ["network_ok"]="Network connectivity OK"
    ["network_failed"]="Network connectivity failed"
    ["download_file"]="Downloading file"
    ["download_success"]="Download successful"
    ["download_failed"]="Download failed"
    
    # File operations
    ["backup_file"]="Backing up file"
    ["create_dir"]="Creating directory"
    ["delete_file"]="Deleting file"
    ["file_exists"]="File already exists"
    ["file_not_found"]="File not found"
    
    # Cleanup
    ["cleanup_env"]="Cleaning up environment variables..."
    ["cleanup_temp"]="Cleaning up temporary files..."
    ["cleanup_history"]="Cleaning up bash history..."
    ["cleanup_scripts"]="Cleaning up downloaded scripts..."
    ["cleanup_complete"]="Cleanup complete"
    
    # Pre-reinstall
    ["system_detection"]="System Detection"
    ["generating_report"]="Generating system information report..."
    ["report_saved"]="Report saved to"
    ["backup_config"]="Configuration Backup"
    ["backing_up"]="Backing up configuration..."
    ["backup_complete"]="Backup complete"
    ["network_planning"]="Network Planning"
    ["planning_network"]="Planning network configuration..."
    ["plan_complete"]="Network plan complete"
    ["prepare_reinstall"]="Prepare Reinstall"
    ["generating_script"]="Generating reinstall script..."
    ["script_generated"]="Reinstall script generated"
    
    # Post-reinstall
    ["setup_ip"]="IP Address Setup"
    ["configuring_ip"]="Configuring IP address..."
    ["ip_configured"]="IP address configured"
    ["setup_hostname"]="Hostname Setup"
    ["configuring_hostname"]="Configuring hostname..."
    ["hostname_configured"]="Hostname configured"
    ["setup_dns"]="DNS Setup"
    ["configuring_dns"]="Configuring DNS..."
    ["dns_configured"]="DNS configured"
    ["setup_tailscale"]="Tailscale Setup"
    ["installing_tailscale"]="Installing Tailscale..."
    ["tailscale_installed"]="Tailscale installed"
    ["setup_chrony"]="Chrony Setup"
    ["installing_chrony"]="Installing Chrony..."
    ["chrony_installed"]="Chrony installed"
    ["optimize_network"]="Network Optimization"
    ["optimizing_network"]="Optimizing network..."
    ["network_optimized"]="Network optimized"
    ["optimize_system"]="System Optimization"
    ["optimizing_system"]="Optimizing system..."
    ["system_optimized"]="System optimized"
    ["setup_security"]="Security Setup"
    ["configuring_security"]="Configuring security..."
    ["security_configured"]="Security configured"
    ["deploy_k3s"]="K3s Deployment"
    ["deploying_k3s"]="Deploying K3s..."
    ["k3s_deployed"]="K3s deployed"
    
    # User interaction
    ["press_key"]="Press any key to continue..."
    ["confirm"]="Are you sure?"
    ["yes"]="Yes"
    ["no"]="No"
    ["continue"]="Continue"
    ["cancel"]="Cancel"
    ["exit"]="Exit"
    
    # Status
    ["starting"]="Starting"
    ["running"]="Running"
    ["completed"]="Completed"
    ["failed"]="Failed"
    ["skipped"]="Skipped"
)

# Chinese messages (translation)
declare -A MSG_ZH=(
    # 通用
    ["info"]="[信息]"
    ["success"]="[成功]"
    ["warning"]="[警告]"
    ["error"]="[错误]"
    ["debug"]="[调试]"
    
    # 权限
    ["check_root"]="检查 root 权限..."
    ["need_root"]="需要 root 权限"
    ["use_sudo"]="请使用: sudo bash"
    
    # 系统检测
    ["detect_os"]="检测操作系统..."
    ["os_detected"]="检测到操作系统"
    ["os_unsupported"]="不支持的操作系统"
    ["detect_hardware"]="检测硬件信息..."
    ["detect_network"]="检测网络信息..."
    ["detect_services"]="检测系统服务..."
    
    # 网络
    ["check_network"]="检查网络连接..."
    ["network_ok"]="网络连接正常"
    ["network_failed"]="网络连接失败"
    ["download_file"]="下载文件"
    ["download_success"]="下载成功"
    ["download_failed"]="下载失败"
    
    # 文件操作
    ["backup_file"]="备份文件"
    ["create_dir"]="创建目录"
    ["delete_file"]="删除文件"
    ["file_exists"]="文件已存在"
    ["file_not_found"]="文件未找到"
    
    # 清理
    ["cleanup_env"]="清理环境变量..."
    ["cleanup_temp"]="清理临时文件..."
    ["cleanup_history"]="清理 bash 历史..."
    ["cleanup_scripts"]="清理下载的脚本..."
    ["cleanup_complete"]="清理完成"
    
    # 重装前
    ["system_detection"]="系统检测"
    ["generating_report"]="生成系统信息报告..."
    ["report_saved"]="报告已保存到"
    ["backup_config"]="配置备份"
    ["backing_up"]="备份配置..."
    ["backup_complete"]="备份完成"
    ["network_planning"]="网络规划"
    ["planning_network"]="规划网络配置..."
    ["plan_complete"]="网络规划完成"
    ["prepare_reinstall"]="准备重装"
    ["generating_script"]="生成重装脚本..."
    ["script_generated"]="重装脚本已生成"
    
    # 重装后
    ["setup_ip"]="IP 地址配置"
    ["configuring_ip"]="配置 IP 地址..."
    ["ip_configured"]="IP 地址已配置"
    ["setup_hostname"]="主机名配置"
    ["configuring_hostname"]="配置主机名..."
    ["hostname_configured"]="主机名已配置"
    ["setup_dns"]="DNS 配置"
    ["configuring_dns"]="配置 DNS..."
    ["dns_configured"]="DNS 已配置"
    ["setup_tailscale"]="Tailscale 配置"
    ["installing_tailscale"]="安装 Tailscale..."
    ["tailscale_installed"]="Tailscale 已安装"
    ["setup_chrony"]="Chrony 配置"
    ["installing_chrony"]="安装 Chrony..."
    ["chrony_installed"]="Chrony 已安装"
    ["optimize_network"]="网络优化"
    ["optimizing_network"]="优化网络..."
    ["network_optimized"]="网络已优化"
    ["optimize_system"]="系统优化"
    ["optimizing_system"]="优化系统..."
    ["system_optimized"]="系统已优化"
    ["setup_security"]="安全配置"
    ["configuring_security"]="配置安全..."
    ["security_configured"]="安全已配置"
    ["deploy_k3s"]="K3s 部署"
    ["deploying_k3s"]="部署 K3s..."
    ["k3s_deployed"]="K3s 已部署"
    
    # 用户交互
    ["press_key"]="按任意键继续..."
    ["confirm"]="确定吗？"
    ["yes"]="是"
    ["no"]="否"
    ["continue"]="继续"
    ["cancel"]="取消"
    ["exit"]="退出"
    
    # 状态
    ["starting"]="开始"
    ["running"]="运行中"
    ["completed"]="已完成"
    ["failed"]="失败"
    ["skipped"]="已跳过"
)

# Get message by key
msg() {
    local key="$1"
    
    if [[ "$TOOLKIT_LANG" == "zh" ]]; then
        echo "${MSG_ZH[$key]:-$key}"
    else
        echo "${MSG_EN[$key]:-$key}"
    fi
}

# Print functions with i18n support
i18n_info() {
    local key="$1"
    shift
    echo -e "${GREEN}$(msg 'info')${NC} $(date '+%Y-%m-%d %H:%M:%S') - $(msg "$key") $*"
}

i18n_success() {
    local key="$1"
    shift
    echo -e "${GREEN}$(msg 'success')${NC} $(date '+%Y-%m-%d %H:%M:%S') - $(msg "$key") $*"
}

i18n_warn() {
    local key="$1"
    shift
    echo -e "${YELLOW}$(msg 'warning')${NC} $(date '+%Y-%m-%d %H:%M:%S') - $(msg "$key") $*" >&2
}

i18n_error() {
    local key="$1"
    shift
    echo -e "${RED}$(msg 'error')${NC} $(date '+%Y-%m-%d %H:%M:%S') - $(msg "$key") $*" >&2
}

i18n_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        local key="$1"
        shift
        echo -e "${BLUE}$(msg 'debug')${NC} $(date '+%Y-%m-%d %H:%M:%S') - $(msg "$key") $*" >&2
    fi
}

# Print separator
print_separator() {
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
}

# Print title
print_title() {
    local title="$1"
    echo ""
    print_separator
    echo -e "${CYAN}  $title${NC}"
    print_separator
    echo ""
}

# Export functions for use in other scripts
export -f msg
export -f i18n_info
export -f i18n_success
export -f i18n_warn
export -f i18n_error
export -f i18n_debug
export -f print_separator
export -f print_title
export TOOLKIT_LANG

# Color codes (if not already defined)
if [[ -z "${GREEN:-}" ]]; then
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
    export RED GREEN YELLOW BLUE CYAN NC
fi
