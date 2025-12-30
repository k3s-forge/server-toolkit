#!/usr/bin/env bash
# components/hostname/generate.sh - Generate K3s-compliant hostname
# Based on swarm-setup/fqdn-reinstall.sh design
# Format: country-region-network-type-product-rand8
# Example: jp-13-dual-k3s-a1b2c3d4

set -Eeuo pipefail

# Load common header
if [[ -n "${SCRIPT_DIR:-}" ]] && [[ -f "$SCRIPT_DIR/utils/common-header.sh" ]]; then
    source "$SCRIPT_DIR/utils/common-header.sh"
else
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TOOLKIT_ROOT="$(cd "$CURRENT_DIR/../.." && pwd)"
    
    if [[ -f "$TOOLKIT_ROOT/utils/common.sh" ]]; then
        source "$TOOLKIT_ROOT/utils/common.sh"
    fi
    
    if [[ -f "$TOOLKIT_ROOT/utils/i18n.sh" ]]; then
        source "$TOOLKIT_ROOT/utils/i18n.sh"
    fi
fi

# ==================== Core Functions ====================

# Slugify label to RFC 1123 compliant format
slugify_label() {
    local s="$1"
    # Convert to lowercase
    s="$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]')"
    # Replace non-allowed characters with hyphen
    s="$(printf '%s' "$s" | sed 's/[^a-z0-9-][^a-z0-9-]*/-/g')"
    # Collapse multiple hyphens
    s="$(printf '%s' "$s" | sed 's/-\{2,\}/-/g')"
    # Remove leading/trailing hyphens
    s="$(printf '%s' "$s" | sed 's/^-\+//; s/-\+$//')"
    # Default to "unknown" if empty
    if [[ -z "$s" ]]; then s="unknown"; fi
    # Limit to 63 characters
    if ((${#s} > 63)); then s="${s:0:63}"; fi
    # Remove trailing hyphen after truncation
    while [[ "$s" == *- ]]; do s="${s%-}"; done
    printf '%s' "$s"
}

# Generate random 8-character hex string
rand8_hex() {
    local out=""
    # Try urandom first
    if [[ -c /dev/urandom ]]; then
        out="$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c 8 || true)"
    fi
    # Fallback to timestamp-based
    if [[ -z "$out" || ${#out} -lt 8 ]]; then
        out="$(date +%s | sha256sum 2>/dev/null | head -c 8 || echo "12345678")"
    fi
    printf '%s' "$out"
}

# Map region name to short code
region_to_code() {
    local country="$1"
    local name_raw="$2"
    local n
    n="$(printf '%s' "$name_raw" | tr '[:upper:]' '[:lower:]')"
    
    case "$country" in
        us)
            case "$n" in
                california|los-angeles|la|san-francisco|sf|ca) echo "ca"; return ;;
                new-york|newyork|nyc|ny) echo "ny"; return ;;
                texas|tx) echo "tx"; return ;;
                washington|wa) echo "wa"; return ;;
            esac
            ;;
        cn)
            case "$n" in
                beijing|bei-jing|bj) echo "bj"; return ;;
                shanghai|shang-hai|sh) echo "sh"; return ;;
                guangzhou|guang-zhou|gz) echo "gz"; return ;;
                shenzhen|shen-zhen|sz) echo "sz"; return ;;
            esac
            ;;
        jp)
            case "$n" in
                tokyo|tyo|tokyo-to) echo "13"; return ;;  # JP-13
                osaka|osa) echo "27"; return ;;  # JP-27
            esac
            ;;
        gb)
            case "$n" in
                london|ldn|england) echo "lon"; return ;;
            esac
            ;;
        de)
            case "$n" in
                frankfurt|fra) echo "fra"; return ;;
                berlin|ber) echo "ber"; return ;;
            esac
            ;;
        sg)
            case "$n" in
                singapore|sgp) echo "sgp"; return ;;
            esac
            ;;
        hk)
            case "$n" in
                hong-kong|hongkong|hk) echo "hk"; return ;;
            esac
            ;;
    esac
    
    echo ""
}

# Detect network type (simplified version)
detect_network_type() {
    local has_v4=false has_v6=false
    
    # Check IPv4
    if command -v curl >/dev/null 2>&1; then
        if curl -4s --connect-timeout 2 --max-time 3 https://api.ipify.org >/dev/null 2>&1; then
            has_v4=true
        fi
    fi
    
    # Check IPv6
    if command -v curl >/dev/null 2>&1; then
        if curl -6s --connect-timeout 2 --max-time 3 https://api64.ipify.org >/dev/null 2>&1; then
            has_v6=true
        fi
    fi
    
    # Determine type
    if $has_v4 && $has_v6; then
        echo "dual"
    elif $has_v4; then
        echo "v4"
    elif $has_v6; then
        echo "v6"
    else
        echo "unknown"
    fi
}

# Get geo-location with concurrent API requests and voting
get_geo_location() {
    local tmpdir="/tmp/geo_$$"
    mkdir -p "$tmpdir"
    
    # Concurrent API requests (background jobs)
    if command -v curl >/dev/null 2>&1; then
        timeout 4 curl -fsSL https://ifconfig.co/json > "$tmpdir/ifconfig.json" 2>/dev/null &
        timeout 4 curl -fsSL https://ipapi.co/json > "$tmpdir/ipapi.json" 2>/dev/null &
        timeout 4 curl -fsSL https://ipinfo.io/json > "$tmpdir/ipinfo.json" 2>/dev/null &
        timeout 4 curl -fsSL http://ip-api.com/json > "$tmpdir/ipapi2.json" 2>/dev/null &
        timeout 4 curl -fsSL https://ipwhois.app/json/ > "$tmpdir/ipwhois.json" 2>/dev/null &
        
        # Wait for all requests (max 5 seconds)
        sleep 5
    fi
    
    # Vote for most common results
    declare -A country_votes region_votes
    local total_responses=0
    
    # Parse ifconfig.co
    if [[ -s "$tmpdir/ifconfig.json" ]]; then
        local c_iso r_name
        c_iso="$(sed -n 's/.*"country_iso"[[:space:]]*:[[:space:]]*"\([A-Z][A-Z]\)".*/\1/p' "$tmpdir/ifconfig.json" 2>/dev/null | head -n1)"
        r_name="$(sed -n 's/.*"region_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$tmpdir/ifconfig.json" 2>/dev/null | head -n1)"
        if [[ -n "$c_iso" && "$c_iso" != "null" ]]; then
            country_votes["$c_iso"]=$((${country_votes["$c_iso"]:-0} + 1))
            total_responses=$((total_responses + 1))
        fi
        if [[ -n "$r_name" && "$r_name" != "null" ]]; then
            region_votes["$r_name"]=$((${region_votes["$r_name"]:-0} + 1))
        fi
    fi
    
    # Parse ipapi.co
    if [[ -s "$tmpdir/ipapi.json" ]]; then
        local c_iso r_name
        c_iso="$(sed -n 's/.*"country"[[:space:]]*:[[:space:]]*"\([A-Z][A-Z]\)".*/\1/p' "$tmpdir/ipapi.json" 2>/dev/null | head -n1)"
        r_name="$(sed -n 's/.*"region"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$tmpdir/ipapi.json" 2>/dev/null | head -n1)"
        if [[ -n "$c_iso" && "$c_iso" != "null" ]]; then
            country_votes["$c_iso"]=$((${country_votes["$c_iso"]:-0} + 1))
            total_responses=$((total_responses + 1))
        fi
        if [[ -n "$r_name" && "$r_name" != "null" ]]; then
            region_votes["$r_name"]=$((${region_votes["$r_name"]:-0} + 1))
        fi
    fi
    
    # Parse ipinfo.io
    if [[ -s "$tmpdir/ipinfo.json" ]]; then
        local c_iso r_name
        c_iso="$(sed -n 's/.*"country"[[:space:]]*:[[:space:]]*"\([A-Z][A-Z]\)".*/\1/p' "$tmpdir/ipinfo.json" 2>/dev/null | head -n1)"
        r_name="$(sed -n 's/.*"region"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$tmpdir/ipinfo.json" 2>/dev/null | head -n1)"
        if [[ -n "$c_iso" && "$c_iso" != "null" ]]; then
            country_votes["$c_iso"]=$((${country_votes["$c_iso"]:-0} + 1))
            total_responses=$((total_responses + 1))
        fi
        if [[ -n "$r_name" && "$r_name" != "null" ]]; then
            region_votes["$r_name"]=$((${region_votes["$r_name"]:-0} + 1))
        fi
    fi
    
    # Parse ip-api.com
    if [[ -s "$tmpdir/ipapi2.json" ]]; then
        local c_iso r_name
        c_iso="$(sed -n 's/.*"countryCode"[[:space:]]*:[[:space:]]*"\([A-Z][A-Z]\)".*/\1/p' "$tmpdir/ipapi2.json" 2>/dev/null | head -n1)"
        r_name="$(sed -n 's/.*"regionName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$tmpdir/ipapi2.json" 2>/dev/null | head -n1)"
        if [[ -n "$c_iso" && "$c_iso" != "null" ]]; then
            country_votes["$c_iso"]=$((${country_votes["$c_iso"]:-0} + 1))
            total_responses=$((total_responses + 1))
        fi
        if [[ -n "$r_name" && "$r_name" != "null" ]]; then
            region_votes["$r_name"]=$((${region_votes["$r_name"]:-0} + 1))
        fi
    fi
    
    # Parse ipwhois.app
    if [[ -s "$tmpdir/ipwhois.json" ]]; then
        local c_iso r_name
        c_iso="$(sed -n 's/.*"country_code"[[:space:]]*:[[:space:]]*"\([A-Z][A-Z]\)".*/\1/p' "$tmpdir/ipwhois.json" 2>/dev/null | head -n1)"
        r_name="$(sed -n 's/.*"region"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$tmpdir/ipwhois.json" 2>/dev/null | head -n1)"
        if [[ -n "$c_iso" && "$c_iso" != "null" ]]; then
            country_votes["$c_iso"]=$((${country_votes["$c_iso"]:-0} + 1))
            total_responses=$((total_responses + 1))
        fi
        if [[ -n "$r_name" && "$r_name" != "null" ]]; then
            region_votes["$r_name"]=$((${region_votes["$r_name"]:-0} + 1))
        fi
    fi
    
    # Select most voted results
    local country_iso="" region_name=""
    local max_country_votes=0 max_region_votes=0
    
    for key in "${!country_votes[@]}"; do
        if [[ ${country_votes["$key"]} -gt $max_country_votes ]]; then
            max_country_votes=${country_votes["$key"]}
            country_iso="$key"
        fi
    done
    
    for key in "${!region_votes[@]}"; do
        if [[ ${region_votes["$key"]} -gt $max_region_votes ]]; then
            max_region_votes=${region_votes["$key"]}
            region_name="$key"
        fi
    done
    
    # Cleanup
    rm -rf "$tmpdir" 2>/dev/null || true
    
    # Output JSON
    printf '{"country":"%s","region":"%s","responses":%d}\n' \
        "${country_iso:-XX}" "${region_name:-unknown}" "$total_responses"
}

# ==================== Main Generation Function ====================

generate_hostname() {
    local product="${1:-k3s}"
    local sequence="${2:-01}"
    
    echo "正在生成主机名..." >&2
    
    # Get geo-location
    echo "检测地理位置..." >&2
    local geo_json
    geo_json=$(get_geo_location)
    
    local country_iso region_name
    country_iso="$(echo "$geo_json" | sed -n 's/.*"country":"\([^"]*\)".*/\1/p')"
    region_name="$(echo "$geo_json" | sed -n 's/.*"region":"\([^"]*\)".*/\1/p')"
    
    # Normalize country code
    country_iso="${country_iso,,}"
    if [[ ! "$country_iso" =~ ^[a-z]{2}$ ]]; then
        country_iso="xx"
    fi
    
    # Slugify and map region
    region_name="$(slugify_label "$region_name")"
    [[ -z "$region_name" ]] && region_name="unknown"
    
    local region_code
    region_code="$(region_to_code "$country_iso" "$region_name")"
    if [[ -n "$region_code" ]]; then
        region_name="$region_code"
    fi
    
    # Detect network type
    echo "检测网络类型..." >&2
    local net_type
    net_type="$(detect_network_type)"
    net_type="$(slugify_label "$net_type")"
    
    # Slugify product name
    product="$(slugify_label "$product")"
    
    # Generate random suffix
    local rand8
    rand8="$(rand8_hex)"
    
    # Build FQDN (with dots)
    local fqdn="${country_iso}.${region_name}.${net_type}.${product}.${rand8}"
    
    # Ensure FQDN length <= 253
    if ((${#fqdn} > 253)); then
        local over=$((${#fqdn} - 253))
        if ((${#product} > over)); then
            product="${product:0:$((${#product} - over))}"
            while [[ "$product" == *- ]]; do product="${product%-}"; done
        fi
        fqdn="${country_iso}.${region_name}.${net_type}.${product}.${rand8}"
    fi
    
    # Build short name (with hyphens)
    local short_name="${country_iso}-${region_name}-${net_type}-${product}-${rand8}"
    
    # Ensure short name length <= 63
    if ((${#short_name} > 63)); then
        local over=$((${#short_name} - 63))
        if ((${#product} > over)); then
            product="${product:0:$((${#product} - over))}"
            while [[ "$product" == *- ]]; do product="${product%-}"; done
        elif ((${#region_name} > over)); then
            region_name="${region_name:0:$((${#region_name} - over))}"
            while [[ "$region_name" == *- ]]; do region_name="${region_name%-}"; done
        fi
        short_name="${country_iso}-${region_name}-${net_type}-${product}-${rand8}"
        
        # Final check
        if ((${#short_name} > 63)); then
            short_name="${short_name:0:63}"
            while [[ "$short_name" == *- ]]; do short_name="${short_name%-}"; done
        fi
    fi
    
    # Output results
    echo "" >&2
    echo "生成完成！" >&2
    echo "  短名（推荐）: $short_name" >&2
    echo "  FQDN（备用）: $fqdn" >&2
    echo "" >&2
    
    # Return short name (primary)
    echo "$short_name"
    
    # Save both formats
    echo "$short_name" > /tmp/generated_hostname_short.txt 2>/dev/null || true
    echo "$fqdn" > /tmp/generated_hostname_fqdn.txt 2>/dev/null || true
}

# ==================== CLI Interface ====================

show_usage() {
    cat << EOF
用法: $0 [product] [sequence]

参数:
  product   - 产品名称（默认: k3s）
  sequence  - 序列号（默认: 01）

示例:
  $0                    # 使用默认值
  $0 k3s 01            # 指定产品和序列
  $0 swarm 02          # Docker Swarm 节点

生成格式:
  短名: country-region-network-product-rand8
  示例: jp-13-dual-k3s-a1b2c3d4

输出:
  标准输出: 短名（用于主机名）
  文件: /tmp/generated_hostname_short.txt
  文件: /tmp/generated_hostname_fqdn.txt
EOF
}

main() {
    local product="${1:-k3s}"
    local sequence="${2:-01}"
    
    if [[ "$product" == "-h" || "$product" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    generate_hostname "$product" "$sequence"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
