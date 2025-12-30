#!/usr/bin/env bash
# config-codec.sh - Configuration encoding/decoding utility
# Converts configuration to/from base64-encoded JSON

set -Eeuo pipefail

# ==================== JSON Encoding/Decoding ====================

# Encode configuration to base64 JSON
encode_config() {
    local config_json="$1"
    
    # Validate JSON
    if ! echo "$config_json" | jq empty 2>/dev/null; then
        echo "Error: Invalid JSON" >&2
        return 1
    fi
    
    # Minify and encode
    echo "$config_json" | jq -c . | base64 -w 0
}

# Decode base64 JSON to configuration
decode_config() {
    local config_code="$1"
    
    # Decode and pretty print
    echo "$config_code" | base64 -d | jq .
}

# Create configuration object
create_config() {
    local version="${1:-1.0}"
    
    cat << EOF
{
  "version": "$version",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": {},
  "network": {},
  "system": {}
}
EOF
}

# Add hostname to config
add_hostname_to_config() {
    local config="$1"
    local short="$2"
    local fqdn="${3:-$short}"
    local apply="${4:-false}"
    
    echo "$config" | jq \
        --arg short "$short" \
        --arg fqdn "$fqdn" \
        --arg apply "$apply" \
        '.hostname = {
            "short": $short,
            "fqdn": $fqdn,
            "apply": ($apply == "true")
        }'
}

# Add network to config
add_network_to_config() {
    local config="$1"
    local interface="$2"
    local ip="$3"
    local gateway="$4"
    local dns="$5"
    
    echo "$config" | jq \
        --arg interface "$interface" \
        --arg ip "$ip" \
        --arg gateway "$gateway" \
        --arg dns "$dns" \
        '.network = {
            "interface": $interface,
            "ip": $ip,
            "gateway": $gateway,
            "dns": ($dns | split(" "))
        }'
}

# Add system config
add_system_to_config() {
    local config="$1"
    local timezone="${2:-UTC}"
    local ntp_servers="${3:-}"
    
    echo "$config" | jq \
        --arg timezone "$timezone" \
        --arg ntp "$ntp_servers" \
        '.system = {
            "timezone": $timezone,
            "ntp_servers": ($ntp | split(" "))
        }'
}

# Get value from config
get_config_value() {
    local config="$1"
    local path="$2"
    
    echo "$config" | jq -r "$path"
}

# Export functions
export -f encode_config
export -f decode_config
export -f create_config
export -f add_hostname_to_config
export -f add_network_to_config
export -f add_system_to_config
export -f get_config_value
