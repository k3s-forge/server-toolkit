#!/usr/bin/env bash
# download.sh - Download manager for server-toolkit
# Handles script downloading with retry logic and timeout

set -Eeuo pipefail

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Default configuration
readonly DEFAULT_TIMEOUT=30
readonly DEFAULT_MAX_RETRIES=3
readonly DEFAULT_RETRY_DELAY=2

# GitHub repository configuration
REPO_OWNER="${REPO_OWNER:-YOUR_ORG}"
REPO_NAME="${REPO_NAME:-server-toolkit}"
REPO_BRANCH="${REPO_BRANCH:-main}"

# Download timeout
DOWNLOAD_TIMEOUT="${DOWNLOAD_TIMEOUT:-$DEFAULT_TIMEOUT}"

# Check if command exists
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Download file with timeout and retry
download_file() {
    local url="$1"
    local output="$2"
    local timeout="${3:-$DOWNLOAD_TIMEOUT}"
    local max_retries="${4:-$DEFAULT_MAX_RETRIES}"
    local retry_delay="${5:-$DEFAULT_RETRY_DELAY}"
    
    local attempt=1
    
    while [ $attempt -le $max_retries ]; do
        log_info "Downloading (attempt $attempt/$max_retries): $url"
        
        # Try curl first
        if has_cmd curl; then
            if curl -fsSL --connect-timeout "$timeout" --max-time "$((timeout * 2))" \
                -o "$output" "$url" 2>/dev/null; then
                log_info "✓ Download successful"
                return 0
            fi
        # Try wget as fallback
        elif has_cmd wget; then
            if wget --timeout="$timeout" --tries=1 -q -O "$output" "$url" 2>/dev/null; then
                log_info "✓ Download successful"
                return 0
            fi
        else
            log_error "Neither curl nor wget is available"
            return 1
        fi
        
        log_warn "Download failed (attempt $attempt/$max_retries)"
        
        if [ $attempt -lt $max_retries ]; then
            log_info "Retrying in ${retry_delay}s..."
            sleep "$retry_delay"
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "Download failed after $max_retries attempts"
    return 1
}

# Download script from GitHub
download_script() {
    local script_path="$1"
    local output_file="${2:-/tmp/$(basename "$script_path")}"
    
    local url="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}/${script_path}"
    
    log_info "Downloading script: $script_path"
    
    if download_file "$url" "$output_file"; then
        chmod +x "$output_file"
        log_info "✓ Script ready: $output_file"
        echo "$output_file"
        return 0
    else
        log_error "Failed to download script: $script_path"
        return 1
    fi
}

# Download and execute script
download_and_execute() {
    local script_path="$1"
    shift
    local args=("$@")
    
    local temp_script="/tmp/server-toolkit-$(basename "$script_path")"
    
    if download_script "$script_path" "$temp_script"; then
        log_info "Executing: $temp_script ${args[*]}"
        
        if bash "$temp_script" "${args[@]}"; then
            log_info "✓ Script executed successfully"
            rm -f "$temp_script"
            return 0
        else
            local exit_code=$?
            log_error "Script execution failed with exit code: $exit_code"
            rm -f "$temp_script"
            return $exit_code
        fi
    else
        return 1
    fi
}

# Download multiple scripts
download_scripts() {
    local -a script_paths=("$@")
    local -a downloaded_files=()
    local failed=0
    
    for script_path in "${script_paths[@]}"; do
        local output_file="/tmp/server-toolkit-$(basename "$script_path")"
        
        if download_script "$script_path" "$output_file"; then
            downloaded_files+=("$output_file")
        else
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -gt 0 ]; then
        log_warn "$failed script(s) failed to download"
    fi
    
    if [ ${#downloaded_files[@]} -gt 0 ]; then
        echo "${downloaded_files[@]}"
        return 0
    else
        return 1
    fi
}

# Verify script checksum (if available)
verify_checksum() {
    local file="$1"
    local expected_checksum="$2"
    
    if [ -z "$expected_checksum" ]; then
        log_warn "No checksum provided, skipping verification"
        return 0
    fi
    
    if ! has_cmd sha256sum; then
        log_warn "sha256sum not available, skipping verification"
        return 0
    fi
    
    local actual_checksum=$(sha256sum "$file" | awk '{print $1}')
    
    if [ "$actual_checksum" = "$expected_checksum" ]; then
        log_info "✓ Checksum verified"
        return 0
    else
        log_error "Checksum mismatch!"
        log_error "Expected: $expected_checksum"
        log_error "Actual:   $actual_checksum"
        return 1
    fi
}

# Download with checksum verification
download_with_checksum() {
    local url="$1"
    local output="$2"
    local checksum="$3"
    
    if download_file "$url" "$output"; then
        if verify_checksum "$output" "$checksum"; then
            return 0
        else
            rm -f "$output"
            return 1
        fi
    else
        return 1
    fi
}

# Test download capability
test_download() {
    log_info "Testing download capability..."
    
    # Test with a small file
    local test_url="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}/README.md"
    local test_file="/tmp/server-toolkit-test-download"
    
    if download_file "$test_url" "$test_file" 10 1; then
        rm -f "$test_file"
        log_info "✓ Download test successful"
        return 0
    else
        log_error "Download test failed"
        return 1
    fi
}

# Main function
main() {
    local action="${1:-}"
    
    case "$action" in
        download)
            shift
            download_script "$@"
            ;;
        execute)
            shift
            download_and_execute "$@"
            ;;
        multiple)
            shift
            download_scripts "$@"
            ;;
        test)
            test_download
            ;;
        *)
            echo "Usage: $0 {download|execute|multiple|test} [args...]"
            echo ""
            echo "Actions:"
            echo "  download <script_path> [output_file]"
            echo "    Download a script from GitHub"
            echo ""
            echo "  execute <script_path> [args...]"
            echo "    Download and execute a script"
            echo ""
            echo "  multiple <script_path1> <script_path2> ..."
            echo "    Download multiple scripts"
            echo ""
            echo "  test"
            echo "    Test download capability"
            echo ""
            echo "Environment variables:"
            echo "  REPO_OWNER       - GitHub repository owner (default: YOUR_ORG)"
            echo "  REPO_NAME        - GitHub repository name (default: server-toolkit)"
            echo "  REPO_BRANCH      - GitHub branch (default: main)"
            echo "  DOWNLOAD_TIMEOUT - Download timeout in seconds (default: 30)"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
