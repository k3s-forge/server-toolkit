#!/usr/bin/env bash
# bootstrap.sh - Server Toolkit Main Entry Point
# Version: 1.0.0
# Description: Modular server management toolkit with on-demand script downloading

set -euo pipefail

# ==================== Configuration ====================

# GitHub repository configuration
REPO_OWNER="${REPO_OWNER:-YOUR_ORG}"
REPO_NAME="${REPO_NAME:-server-toolkit}"
REPO_BRANCH="${REPO_BRANCH:-main}"
BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}"

# Local configuration
SCRIPT_DIR="/tmp/server-toolkit-$$"
DOWNLOAD_TIMEOUT=30
VERSION="1.0.0"

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

print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║                    Server Toolkit v${VERSION}                  ║"
    echo "║                                                            ║"
    echo "║          Modular Server Management Solution                ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Check if command exists
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
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
    
    log_success "System requirements check passed"
}

# ==================== Download Manager ====================

# Download a script from GitHub
download_script() {
    local script_path="$1"
    local local_path="${SCRIPT_DIR}/${script_path}"
    local url="${BASE_URL}/${script_path}"
    
    # Create directory if needed
    mkdir -p "$(dirname "$local_path")"
    
    log_info "Downloading: ${script_path}"
    
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
    
    log_error "Failed to download: ${script_path}"
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
    
    log_info "Executing: ${script_path}"
    
    # Execute with sudo if not root
    if [[ "$(id -u)" -eq 0 ]]; then
        bash "$local_path" "${args[@]}"
    else
        sudo bash "$local_path" "${args[@]}"
    fi
    
    local exit_code=$?
    
    # Cleanup after execution
    rm -f "$local_path"
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "Completed: ${script_path}"
    else
        log_error "Failed: ${script_path} (exit code: $exit_code)"
    fi
    
    return $exit_code
}

# ==================== Menu System ====================

show_main_menu() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Server Toolkit - Main Menu${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Pre-Reinstall Tools${NC}"
    echo "  [1] Detect System Information"
    echo "  [2] Backup Current Configuration"
    echo "  [3] Plan Network Configuration"
    echo "  [4] Generate Reinstall Script"
    echo ""
    echo -e "${YELLOW}🚀 Post-Reinstall Tools${NC}"
    echo "  [5] Base Configuration"
    echo "  [6] Network Configuration"
    echo "  [7] System Configuration"
    echo "  [8] K3s Deployment"
    echo ""
    echo -e "${BLUE}📊 Utilities${NC}"
    echo "  [9] View Deployment Report"
    echo "  [10] Security Cleanup"
    echo ""
    echo -e "${RED}[0] Exit${NC}"
    echo ""
}

# ==================== Pre-Reinstall Tools ====================

detect_system() {
    log_info "Starting system detection..."
    download_and_run "pre-reinstall/detect-system.sh"
}

backup_config() {
    log_info "Starting configuration backup..."
    download_and_run "pre-reinstall/backup-config.sh"
}

plan_network() {
    log_info "Starting network planning..."
    download_and_run "pre-reinstall/plan-network.sh"
}

generate_reinstall_script() {
    log_info "Generating reinstall script..."
    download_and_run "pre-reinstall/prepare-reinstall.sh"
}

# ==================== Post-Reinstall Tools ====================

base_configuration() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Base Configuration${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  [1] Setup IP Addresses"
    echo "  [2] Setup Hostname"
    echo "  [3] Setup DNS"
    echo "  [4] All Base Configuration"
    echo "  [0] Back to Main Menu"
    echo ""
    read -p "Select [0-4]: " choice
    
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
        *) log_error "Invalid choice" ;;
    esac
}

network_configuration() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Network Configuration${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  [1] Setup Tailscale"
    echo "  [2] Network Optimization"
    echo "  [3] All Network Configuration"
    echo "  [0] Back to Main Menu"
    echo ""
    read -p "Select [0-3]: " choice
    
    case $choice in
        1) download_and_run "post-reinstall/network/setup-tailscale.sh" ;;
        2) download_and_run "post-reinstall/network/optimize-network.sh" ;;
        3)
            download_and_run "post-reinstall/network/setup-tailscale.sh"
            download_and_run "post-reinstall/network/optimize-network.sh"
            ;;
        0) return ;;
        *) log_error "Invalid choice" ;;
    esac
}

system_configuration() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  System Configuration${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  [1] Setup Time Sync (Chrony)"
    echo "  [2] System Optimization"
    echo "  [3] Security Hardening"
    echo "  [4] All System Configuration"
    echo "  [0] Back to Main Menu"
    echo ""
    read -p "Select [0-4]: " choice
    
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
        *) log_error "Invalid choice" ;;
    esac
}

k3s_deployment() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  K3s Deployment${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  [1] Deploy K3s"
    echo "  [2] Setup Upgrade Controller"
    echo "  [3] Deploy Storage (MinIO/Garage)"
    echo "  [4] Full K3s Deployment"
    echo "  [0] Back to Main Menu"
    echo ""
    read -p "Select [0-4]: " choice
    
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
        *) log_error "Invalid choice" ;;
    esac
}

# ==================== Utilities ====================

view_deployment_report() {
    local report_file="/root/server-toolkit-report.txt"
    
    if [[ -f "$report_file" ]]; then
        cat "$report_file"
    else
        log_warn "No deployment report found"
        log_info "Report will be generated after deployment"
    fi
}

security_cleanup() {
    log_info "Starting security cleanup..."
    download_and_run "utils/cleanup.sh"
}

# ==================== Main Loop ====================

main_loop() {
    while true; do
        show_main_menu
        read -p "Select [0-10]: " choice
        
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
                log_info "Thank you for using Server Toolkit!"
                cleanup_and_exit 0
                ;;
            *)
                log_error "Invalid choice. Please select 0-10."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# ==================== Cleanup ====================

cleanup_and_exit() {
    local exit_code="${1:-0}"
    
    log_info "Cleaning up temporary files..."
    
    # Remove temporary directory
    if [[ -d "$SCRIPT_DIR" ]]; then
        rm -rf "$SCRIPT_DIR"
    fi
    
    log_success "Cleanup complete"
    exit "$exit_code"
}

# Trap signals for cleanup
trap 'cleanup_and_exit 1' INT TERM

# ==================== Main Entry Point ====================

main() {
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
