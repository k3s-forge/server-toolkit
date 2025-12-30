# Server Toolkit v2.0 - Quick Start Guide

## What's New in v2.0?

Server Toolkit v2.0 introduces a **completely decoupled architecture**:

- ✅ **No longer centered around "reinstall"** - works great for any VPS
- ✅ **Configuration as Code** - export/import configs as base64 codes
- ✅ **Atomic Components** - use hostname, network, system tools independently
- ✅ **Flexible Workflows** - quick setup, config export/import, or full reinstall prep
- ✅ **K3s Compliant** - hostname generation follows RFC 1123 standards

## Installation

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
```

### Language Selection

The script will prompt you to select language on first run:
- English
- 中文 (Chinese)

Or set explicitly:
```bash
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | TOOLKIT_LANG=zh bash
```

## Common Tasks

### 1. Configure a New VPS (No Reinstall)

```bash
# Run toolkit
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash

# Select: [3] Quick Setup
# Follow prompts to configure:
#   - Hostname (with geo-location)
#   - Network verification
#   - Timezone
```

**Result**: Server configured and ready to use

### 2. Generate K3s-Compliant Hostname

```bash
# Run toolkit
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash

# Select: [4] Hostname Management
# Choose generation method:
#   1) With geo-location (e.g., server-hongkong-hk-01)
#   2) Simple sequence (e.g., server-01)
#   3) Random suffix (e.g., server-a1b2c3d4)
#   4) Custom hostname

# Then choose:
#   - Apply immediately
#   - Save for config code
```

**Result**: K3s-compliant hostname generated and optionally applied

### 3. Export Configuration (Backup)

```bash
# Run toolkit
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash

# Select: [2] Export Config Code
# Copy the displayed config code
# Save to secure location
```

**Result**: Base64-encoded config code you can paste anywhere

**Example Config Code**:
```
eyJ2ZXJzaW9uIjoiMS4wIiwidGltZXN0YW1wIjoiMjAyNC0xMi0zMFQxMjowMDowMFoiLCJob3N0bmFtZSI6eyJzaG9ydCI6InNlcnZlcjAxIiwiZnFkbiI6InNlcnZlcjAxLmszcy5sb2NhbCIsImFwcGx5Ijp0cnVlfSwibmV0d29yayI6eyJpbnRlcmZhY2UiOiJldGgwIiwiaXAiOiIxOTIuMTY4LjEuMTAwLzI0IiwiZ2F0ZXdheSI6IjE5Mi4xNjguMS4xIiwiZG5zIjpbIjguOC44LjgiLCI4LjguNC40Il19LCJzeXN0ZW0iOnsidGltZXpvbmUiOiJVVEMiLCJudHBfc2VydmVycyI6W119fQ==
```

### 4. Import Configuration (Restore/Clone)

```bash
# Run toolkit
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash

# Select: [1] Import Config Code
# Paste your config code
# Review configuration
# Confirm to apply
```

**Result**: Server configured from config code

### 5. Clone Configuration to Multiple Servers

```bash
# On source server - export config
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
# Select [2] Export Config Code
# Copy the config code

# On each target server - import config
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
# Select [1] Import Config Code
# Paste the config code
```

**Result**: Identical configuration across multiple servers

### 6. Prepare for OS Reinstall (Optional)

```bash
# Before reinstall
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash

# Select: [10] Reinstall Preparation
# This generates:
#   - Restore script
#   - Backup information
#   - Config code

# Save all generated files

# After reinstall, run restore script:
bash restore-config-*.sh

# Or import config code:
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
# Select [1] Import Config Code
```

**Result**: Easy recovery after OS reinstall

### 7. View Current Configuration

```bash
# Run toolkit
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash

# Select: [8] View Configuration
```

**Result**: Display current hostname, network, and system settings

### 8. Deploy K3s

```bash
# Run toolkit
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash

# Select: [7] Deploy K3s
# Follow submenu for:
#   - K3s deployment
#   - Upgrade controller
#   - Storage (MinIO/Garage)
```

**Result**: K3s cluster deployed and configured

## Menu Overview

```
🔧 Configuration Management
  [1] Import Config Code    - Restore from config code
  [2] Export Config Code    - Backup current config
  [3] Quick Setup           - Configure new VPS

⚙️  Components
  [4] Hostname Management   - Generate/apply hostname
  [5] Network Configuration - Configure network
  [6] System Configuration  - System optimization

🚀 K3s Deployment
  [7] Deploy K3s            - Deploy K3s cluster

📊 Utilities
  [8] View Configuration    - Show current config
  [9] Security Cleanup      - Clean sensitive data

💾 Advanced
  [10] Reinstall Preparation - Prepare for OS reinstall
```

## Configuration Code Format

Config codes are base64-encoded JSON:

**Decoded JSON**:
```json
{
  "version": "1.0",
  "timestamp": "2024-12-30T12:00:00Z",
  "hostname": {
    "short": "server01",
    "fqdn": "server01.k3s.local",
    "apply": true
  },
  "network": {
    "interface": "eth0",
    "ip": "192.168.1.100/24",
    "gateway": "192.168.1.1",
    "dns": ["8.8.8.8", "8.8.4.4"]
  },
  "system": {
    "timezone": "UTC",
    "ntp_servers": []
  }
}
```

**Encoded** (for copy/paste):
```
eyJ2ZXJzaW9uIjoiMS4wIiwidGltZXN0YW1wIjoiMjAyNC0xMi0zMFQxMjowMDowMFoiLCJob3N0bmFtZSI6eyJzaG9ydCI6InNlcnZlcjAxIiwiZnFkbiI6InNlcnZlcjAxLmszcy5sb2NhbCIsImFwcGx5Ijp0cnVlfSwibmV0d29yayI6eyJpbnRlcmZhY2UiOiJldGgwIiwiaXAiOiIxOTIuMTY4LjEuMTAwLzI0IiwiZ2F0ZXdheSI6IjE5Mi4xNjguMS4xIiwiZG5zIjpbIjguOC44LjgiLCI4LjguNC40Il19LCJzeXN0ZW0iOnsidGltZXpvbmUiOiJVVEMiLCJudHBfc2VydmVycyI6W119fQ==
```

## Hostname Generation

### K3s Compliance

Generated hostnames follow RFC 1123 and K3s requirements:
- ✅ Lowercase only
- ✅ Alphanumeric and hyphens
- ✅ Start/end with alphanumeric
- ✅ Maximum 63 characters
- ✅ No consecutive hyphens

### Generation Methods

1. **Geo-location**: `server-hongkong-hk-01`
   - Detects location from IP
   - Format: `prefix-city-country-sequence`

2. **Simple**: `server-01`
   - Format: `prefix-sequence`

3. **Random**: `server-a1b2c3d4`
   - Format: `prefix-random`

4. **Custom**: User input with automatic sanitization

## Use Cases

### Use Case 1: New VPS Setup

**Scenario**: Just got a new VPS, want to configure it quickly

**Steps**:
1. Run toolkit
2. Select [3] Quick Setup
3. Configure hostname, verify network, set timezone
4. Select [2] Export Config Code (backup)
5. Done!

### Use Case 2: Standardized Deployment

**Scenario**: Deploy 10 identical servers

**Steps**:
1. Configure first server using Quick Setup
2. Export config code
3. Modify config code for each server (change hostname/IP)
4. Import config code on each server
5. Done!

### Use Case 3: Disaster Recovery

**Scenario**: Server crashed, need to restore

**Steps**:
1. Had exported config code before (good practice!)
2. Get new server
3. Import config code
4. Restore data from backups
5. Done!

### Use Case 4: OS Upgrade

**Scenario**: Want to reinstall OS with newer version

**Steps**:
1. Run Reinstall Preparation [10]
2. Save restore script and config code
3. Reinstall OS
4. Run restore script or import config code
5. Done!

## Tips & Best Practices

1. **Always Export Config**: Before major changes, export config code
2. **Store Config Codes Securely**: They contain sensitive information
3. **Use Geo-location Hostnames**: Easier to identify servers
4. **Test Import First**: Use dry-run mode to preview changes
5. **Regular Backups**: Export config codes periodically

## Troubleshooting

### Config Code Invalid

**Problem**: "Invalid configuration code" error

**Solution**:
- Ensure complete code was copied (no truncation)
- Check for extra spaces or newlines
- Verify base64 encoding

### Hostname Not Applied

**Problem**: Hostname generated but not applied

**Solution**:
- Check if you selected "apply immediately"
- Manually apply: `bash components/hostname/apply.sh apply <hostname>`
- Verify root/sudo access

### Network Configuration Not Applied

**Problem**: Network config in code but not applied

**Solution**:
- Network changes require manual review (safety)
- Check generated network script in home directory
- Review and run manually: `sudo bash network-config-*.sh`

### jq Not Found

**Problem**: "jq is required but not installed"

**Solution**:
```bash
# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq
```

## Advanced Usage

### Standalone Component Usage

Download and use components directly:

```bash
# Generate hostname
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/components/hostname/generate.sh -o generate.sh
bash generate.sh geo server 01

# Detect network
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/components/network/detect.sh -o detect.sh
bash detect.sh json
```

### Custom Workflows

Create your own workflows using components:

```bash
#!/bin/bash
# my-workflow.sh

# Generate hostname
hostname=$(bash components/hostname/generate.sh geo myapp 01)

# Apply hostname
bash components/hostname/apply.sh apply "$hostname"

# Export config
bash workflows/export-config.sh current
```

## Getting Help

- **Documentation**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **Issues**: [GitHub Issues](https://github.com/k3s-forge/server-toolkit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/k3s-forge/server-toolkit/discussions)

## What's Next?

After basic configuration:

1. **Deploy K3s**: Use option [7] to deploy K3s cluster
2. **System Optimization**: Use option [6] for system tuning
3. **Network Setup**: Configure Tailscale, optimize network
4. **Security**: Run security cleanup regularly

---

**Version**: 2.0.0  
**Last Updated**: 2024-12-30  
**Architecture**: Decoupled Components
