# Server Toolkit - Decoupled Architecture

## Overview

Server Toolkit has been redesigned with a completely decoupled, component-based architecture. All functionality is independent and can be used standalone or composed together.

## Design Principles

1. **Complete Decoupling**: No functionality is centered around "reinstall" - each component serves a specific purpose
2. **Atomic Components**: Each component is self-contained and can be used independently
3. **Configuration as Code**: Configuration can be exported/imported as base64-encoded JSON
4. **Composability**: Components can be combined into workflows
5. **Flexibility**: Supports both reinstall and non-reinstall scenarios

## Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                    bootstrap.sh                         │
│              (Main Entry Point & Menu)                  │
└─────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼────────┐ ┌──────▼──────┐ ┌────────▼────────┐
│   Workflows    │ │  Components │ │    Utilities    │
│   (Compose)    │ │   (Atomic)  │ │   (Support)     │
└────────────────┘ └─────────────┘ └─────────────────┘
```

## Directory Structure

```
server-toolkit/
├── bootstrap.sh              # Main entry point
├── components/               # Atomic components
│   ├── hostname/
│   │   ├── generate.sh      # Generate K3s-compliant hostname
│   │   ├── apply.sh         # Apply hostname to system
│   │   └── manage.sh        # Interactive management
│   ├── network/
│   │   ├── detect.sh        # Detect network configuration
│   │   ├── apply.sh         # Apply network configuration
│   │   └── validate.sh      # Validate network settings
│   ├── config/
│   │   ├── export.sh        # Export configuration
│   │   └── import.sh        # Import configuration
│   └── system/
│       ├── detect.sh        # Detect system information
│       └── optimize.sh      # System optimization
├── workflows/                # Composed workflows
│   ├── quick-setup.sh       # Quick configuration (no reinstall)
│   ├── export-config.sh     # Export configuration code
│   ├── import-config.sh     # Import configuration code
│   └── reinstall-prep.sh    # Reinstall preparation (optional)
├── utils/                    # Utility functions
│   ├── common.sh            # Common functions
│   ├── i18n.sh              # Internationalization
│   ├── config-codec.sh      # Configuration encoding/decoding
│   └── common-header.sh     # Script loader
├── pre-reinstall/           # Legacy reinstall tools (optional)
└── post-reinstall/          # Legacy post-reinstall tools (optional)
```

## Components

### Hostname Component

**Location**: `components/hostname/`

**Purpose**: Generate and manage K3s-compliant hostnames (RFC 1123)

**Scripts**:
- `generate.sh` - Generate hostname with various methods
  - Geo-location based (e.g., `server-hongkong-hk-01`)
  - Simple sequence (e.g., `server-01`)
  - Random suffix (e.g., `server-a1b2c3d4`)
  - Custom input with sanitization
- `apply.sh` - Apply hostname to system
  - Set hostname using hostnamectl
  - Update /etc/hosts
  - Support FQDN
- `manage.sh` - Interactive management interface
  - Generate and apply immediately
  - Generate for config code (no apply)
  - Apply custom hostname

**Usage**:
```bash
# Generate hostname
bash components/hostname/generate.sh geo server 01

# Apply hostname
bash components/hostname/apply.sh apply server-hongkong-hk-01

# Interactive management
bash components/hostname/manage.sh
```

**K3s Compliance**:
- Lowercase only
- Alphanumeric and hyphens
- Must start/end with alphanumeric
- Maximum 63 characters
- No consecutive hyphens

### Network Component

**Location**: `components/network/`

**Purpose**: Detect and manage network configuration

**Scripts**:
- `detect.sh` - Detect network configuration
  - Interface name
  - IP address and netmask
  - Gateway
  - DNS servers
  - MAC address
  - Output formats: JSON, env, human

**Usage**:
```bash
# Detect network (human-readable)
bash components/network/detect.sh human

# Get JSON output
bash components/network/detect.sh json

# Get specific value
bash components/network/detect.sh ip
```

### Configuration Codec

**Location**: `utils/config-codec.sh`

**Purpose**: Encode/decode configuration as base64 JSON

**Format**:
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

**Encoded**: Base64-encoded minified JSON for easy copy/paste

## Workflows

### Quick Setup Workflow

**Location**: `workflows/quick-setup.sh`

**Purpose**: Configure server without reinstalling OS

**Steps**:
1. Hostname configuration (optional)
2. Network verification
3. System settings (timezone, etc.)

**Use Case**: New VPS that doesn't need OS reinstall

### Export Configuration Workflow

**Location**: `workflows/export-config.sh`

**Purpose**: Export current configuration as config code

**Modes**:
- `current` - Export current system configuration
- `custom` - Create custom configuration interactively

**Output**: Base64-encoded JSON config code

### Import Configuration Workflow

**Location**: `workflows/import-config.sh`

**Purpose**: Import configuration from config code

**Modes**:
- `interactive` - Paste config code interactively
- `file` - Import from file
- `code` - Import from command line

**Features**:
- Preview before applying
- Dry-run mode
- Selective application (hostname, network, system)

### Reinstall Preparation Workflow

**Location**: `workflows/reinstall-prep.sh` (or use legacy `pre-reinstall/`)

**Purpose**: Prepare for OS reinstallation (optional)

**Steps**:
1. Detect system information
2. Generate restore script
3. Create backup information

## Menu Structure

```
Server Toolkit - Main Menu
════════════════════════════════════════════════════════════

🔧 Configuration Management
  [1] Import Config Code    - Paste config code, auto-configure
  [2] Export Config Code    - Generate config code, save backup
  [3] Quick Setup           - Interactive setup (no reinstall)

⚙️  Components
  [4] Hostname Management   - Generate/apply hostname
  [5] Network Configuration - IP/gateway/DNS
  [6] System Configuration  - Time sync/optimize/security

🚀 K3s Deployment
  [7] Deploy K3s

📊 Utilities
  [8] View Configuration    - Show current config
  [9] Security Cleanup      - Clean sensitive data

💾 Advanced
  [10] Reinstall Preparation - For OS reinstall scenarios

[0] Exit
```

## Usage Scenarios

### Scenario 1: New VPS (No Reinstall)

```bash
# Run bootstrap
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash

# Select option 3: Quick Setup
# Follow interactive prompts to configure hostname, network, system

# Or use option 4 to manage hostname separately
# Then option 2 to export config code for backup
```

### Scenario 2: Clone Configuration

```bash
# On source server
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
# Select option 2: Export Config Code
# Copy the config code

# On target server
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
# Select option 1: Import Config Code
# Paste the config code
```

### Scenario 3: OS Reinstall

```bash
# Before reinstall
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
# Select option 10: Reinstall Preparation
# Save generated restore script and config code

# After reinstall
# Run restore script or import config code
bash restore-config-*.sh
# Or
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
# Select option 1: Import Config Code
```

### Scenario 4: Standalone Component Usage

```bash
# Download and use components directly
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/components/hostname/generate.sh -o generate.sh
bash generate.sh geo server 01

# Or through bootstrap (auto-downloads)
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
# Select option 4: Hostname Management
```

## Component Independence

Each component can be:

1. **Used Standalone**: Download and run directly
2. **Called by Workflows**: Composed into larger workflows
3. **Integrated into Config Code**: Configuration exported/imported
4. **Used Multiple Times**: No side effects, idempotent

## Configuration Code Benefits

1. **Portable**: Copy/paste between servers
2. **Version Controlled**: Store in git
3. **Auditable**: Human-readable JSON (when decoded)
4. **Composable**: Merge multiple configs
5. **Selective**: Apply only what you need

## Migration from Old Architecture

Old structure (reinstall-centric):
```
pre-reinstall/
  ├── detect-system.sh
  ├── backup-config.sh
  └── prepare-reinstall.sh
post-reinstall/
  ├── base/
  ├── network/
  └── system/
```

New structure (decoupled):
```
components/          # Atomic, reusable
  ├── hostname/
  ├── network/
  └── system/
workflows/           # Composed
  ├── quick-setup.sh
  ├── export-config.sh
  └── import-config.sh
```

**Key Differences**:
- Old: Centered around reinstall workflow
- New: Independent components, flexible workflows
- Old: Sequential, rigid
- New: Composable, flexible
- Old: Limited reusability
- New: Maximum reusability

## Future Extensions

The decoupled architecture makes it easy to add:

1. **New Components**:
   - Storage configuration
   - Firewall management
   - User management
   - Service deployment

2. **New Workflows**:
   - Multi-server orchestration
   - Disaster recovery
   - Compliance checking
   - Automated testing

3. **New Integrations**:
   - Ansible playbooks
   - Terraform modules
   - CI/CD pipelines
   - Monitoring systems

## Best Practices

1. **Use Config Codes**: Export configuration before major changes
2. **Test in Dry-Run**: Preview changes before applying
3. **Validate Hostnames**: Use generate.sh to ensure K3s compliance
4. **Backup Regularly**: Export config codes periodically
5. **Document Custom Configs**: Add comments in JSON before encoding

## Dependencies

- **Required**: bash 4.0+, curl or wget
- **Optional**: jq (for config code features)
- **Recommended**: sudo, systemd

## Security

- Config codes contain sensitive information (IPs, hostnames)
- Store config codes securely
- Use security cleanup after operations
- Review generated scripts before execution

---

**Version**: 2.0.0  
**Architecture**: Decoupled Components  
**Last Updated**: 2024-12-30
