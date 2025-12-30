#!/usr/bin/env bash
# cleanup.sh - Security cleanup utilities
# Migrated from k3s-setup/utils/security-cleanup.sh

set -Eeuo pipefail

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Cleanup sensitive environment variables
cleanup_sensitive_env() {
    echo "Cleaning up sensitive environment variables..."
    
    # K3s related
    unset K3S_TOKEN 2>/dev/null || true
    unset K3S_AGENT_TOKEN 2>/dev/null || true
    unset K3S_SERVER_URL 2>/dev/null || true
    
    # Tailscale related
    unset TAILSCALE_AUTH_KEY 2>/dev/null || true
    unset TAILSCALE_API_KEY 2>/dev/null || true
    
    # SSH related
    unset SSH_PUBLIC_KEY 2>/dev/null || true
    unset ROOT_PASSWORD 2>/dev/null || true
    unset SSH_USER_PASSWORD 2>/dev/null || true
    
    # Clean all environment variables containing sensitive keywords
    local sensitive_patterns=("PASSWORD" "TOKEN" "KEY" "SECRET" "AUTH")
    
    for pattern in "${sensitive_patterns[@]}"; do
        local vars=$(env | grep -i "$pattern" | cut -d= -f1 || true)
        for var in $vars; do
            unset "$var" 2>/dev/null || true
        done
    done
    
    echo "✓ Sensitive environment variables cleaned"
}

# Cleanup temporary files
cleanup_temp_files() {
    echo "Cleaning up temporary files..."
    
    local temp_patterns=(
        "/tmp/k3s-*"
        "/tmp/tailscale-*"
        "/tmp/bootstrap-*"
        "/tmp/chrony-*"
        "/tmp/system-*"
        "/tmp/server-toolkit-*"
    )
    
    for pattern in "${temp_patterns[@]}"; do
        if ls $pattern >/dev/null 2>&1; then
            rm -f $pattern 2>/dev/null || true
            echo "  ✓ Deleted: $pattern"
        fi
    done
    
    echo "✓ Temporary files cleaned"
}

# Cleanup bash history with sensitive commands
cleanup_bash_history() {
    echo "Cleaning up bash history with sensitive commands..."
    
    local history_file="${HOME}/.bash_history"
    
    if [ ! -f "$history_file" ]; then
        echo "  ⏭️  History file does not exist, skipping"
        return 0
    fi
    
    # Backup history file
    cp "$history_file" "${history_file}.bak" 2>/dev/null || true
    
    # Sensitive keywords list
    local sensitive_keywords=(
        "K3S_TOKEN"
        "K3S_AGENT_TOKEN"
        "TAILSCALE_AUTH_KEY"
        "TAILSCALE_API_KEY"
        "SSH_PUBLIC_KEY"
        "PASSWORD"
        "SECRET"
        "export.*TOKEN"
        "export.*KEY"
        "export.*PASSWORD"
        "curl.*token="
        "curl.*key="
    )
    
    # Create temporary file
    local temp_file=$(mktemp)
    
    # Filter sensitive commands
    cp "$history_file" "$temp_file"
    
    for keyword in "${sensitive_keywords[@]}"; do
        sed -i "/$keyword/d" "$temp_file" 2>/dev/null || true
    done
    
    # Replace original file
    mv "$temp_file" "$history_file"
    
    echo "✓ Bash history cleaned"
    echo "  Backup file: ${history_file}.bak"
}

# Securely delete file (using shred)
secure_delete_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    echo "Securely deleting: $file"
    
    # Check if shred command is available
    if command -v shred >/dev/null 2>&1; then
        # Use shred: 3 random overwrites + 1 zero fill + delete
        shred -vfuz -n 3 "$file" 2>/dev/null || rm -f "$file"
        echo "  ✓ Securely deleted using shred"
    else
        # Manual overwrite
        local file_size=$(stat -c%s "$file" 2>/dev/null || echo "1048576")
        
        # Random data overwrite
        dd if=/dev/urandom of="$file" bs=1 count="$file_size" 2>/dev/null || true
        
        # Zero fill overwrite
        dd if=/dev/zero of="$file" bs=1 count="$file_size" 2>/dev/null || true
        
        # Delete file
        rm -f "$file"
        
        echo "  ✓ Manually overwritten and deleted"
    fi
}

# Cleanup sensitive files
cleanup_sensitive_files() {
    echo "Cleaning up sensitive files..."
    
    local sensitive_files=(
        "/tmp/k3s-token.txt"
        "/tmp/tailscale-key.txt"
        "/tmp/ssh-key.txt"
        "/root/.env"
        "/root/.env.backup"
    )
    
    for file in "${sensitive_files[@]}"; do
        if [ -f "$file" ]; then
            secure_delete_file "$file"
        fi
    done
    
    echo "✓ Sensitive files cleaned"
}

# Cleanup downloaded scripts
cleanup_downloaded_scripts() {
    echo "Cleaning up downloaded scripts..."
    
    local script_dir="/tmp/server-toolkit-scripts"
    
    if [ -d "$script_dir" ]; then
        rm -rf "$script_dir"
        echo "  ✓ Deleted: $script_dir"
    fi
    
    # Cleanup individually downloaded scripts
    local script_patterns=(
        "/tmp/*-setup.sh"
        "/tmp/*-manager.sh"
        "/tmp/*-optimization.sh"
        "/tmp/detect-*.sh"
        "/tmp/backup-*.sh"
        "/tmp/plan-*.sh"
        "/tmp/prepare-*.sh"
        "/tmp/deploy-*.sh"
    )
    
    for pattern in "${script_patterns[@]}"; do
        if ls $pattern >/dev/null 2>&1; then
            rm -f $pattern 2>/dev/null || true
            echo "  ✓ Deleted: $pattern"
        fi
    done
    
    echo "✓ Downloaded scripts cleaned"
}

# Disable core dump
disable_core_dump() {
    echo "Disabling core dump..."
    
    # Set ulimit
    ulimit -c 0 2>/dev/null || true
    
    # Persistent configuration
    if [ -f /etc/security/limits.conf ]; then
        if ! grep -q "* hard core 0" /etc/security/limits.conf; then
            echo "* hard core 0" >> /etc/security/limits.conf
            echo "  ✓ Added to /etc/security/limits.conf"
        fi
    fi
    
    # Disable systemd-coredump
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active systemd-coredump >/dev/null 2>&1; then
            systemctl stop systemd-coredump 2>/dev/null || true
            systemctl disable systemd-coredump 2>/dev/null || true
            echo "  ✓ Disabled systemd-coredump"
        fi
    fi
    
    echo "✓ Core dump disabled"
}

# Full security cleanup
full_security_cleanup() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Security Cleanup${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # 1. Cleanup sensitive environment variables
    cleanup_sensitive_env
    echo ""
    
    # 2. Cleanup temporary files
    cleanup_temp_files
    echo ""
    
    # 3. Cleanup bash history
    if [ "${DISABLE_HISTORY:-0}" != "1" ]; then
        cleanup_bash_history
        echo ""
    fi
    
    # 4. Cleanup sensitive files
    cleanup_sensitive_files
    echo ""
    
    # 5. Cleanup downloaded scripts
    cleanup_downloaded_scripts
    echo ""
    
    # 6. Disable core dump
    disable_core_dump
    echo ""
    
    echo -e "${GREEN}✓ Security cleanup complete${NC}"
    echo ""
    echo "Cleaned items:"
    echo "  ✓ Sensitive environment variables"
    echo "  ✓ Temporary files"
    echo "  ✓ Bash history with sensitive commands"
    echo "  ✓ Sensitive files (securely deleted)"
    echo "  ✓ Downloaded scripts"
    echo "  ✓ Core dump"
    echo ""
}

# Quick cleanup (only environment variables and temporary files)
quick_cleanup() {
    cleanup_sensitive_env
    cleanup_temp_files
    echo "✓ Quick cleanup complete"
}

# Main function
main() {
    local cleanup_type="${1:-full}"
    
    case "$cleanup_type" in
        full)
            full_security_cleanup
            ;;
        quick)
            quick_cleanup
            ;;
        env)
            cleanup_sensitive_env
            ;;
        temp)
            cleanup_temp_files
            ;;
        history)
            cleanup_bash_history
            ;;
        scripts)
            cleanup_downloaded_scripts
            ;;
        *)
            echo "Usage: $0 {full|quick|env|temp|history|scripts}"
            echo ""
            echo "Cleanup types:"
            echo "  full     - Full security cleanup (default)"
            echo "  quick    - Quick cleanup (env + temp)"
            echo "  env      - Cleanup environment variables only"
            echo "  temp     - Cleanup temporary files only"
            echo "  history  - Cleanup bash history only"
            echo "  scripts  - Cleanup downloaded scripts only"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
