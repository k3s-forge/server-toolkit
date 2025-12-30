# Server Toolkit v2.0

> A decoupled, component-based server management toolkit with configuration as code.

[中文文档](README.zh.md) | [Quick Start](QUICK-START-V2.md) | [Architecture](ARCHITECTURE.md)

## Overview

Server Toolkit v2.0 is a completely redesigned server management solution with a decoupled architecture. No longer centered around "reinstall" - it works great for any VPS scenario.

**Perfect for**:
- 🆕 **New VPS Setup** - Quick configuration without reinstall
- 📋 **Configuration Cloning** - Export/import configs across servers
- 🔄 **OS Reinstall** - Backup and restore configuration easily
- 🎯 **Standardized Deployment** - Use config codes for consistency

## Key Features

- 🧩 **Decoupled Components** - Use hostname, network, system tools independently
- 📝 **Configuration as Code** - Export/import configs as base64 JSON
- �  **Flexible Workflows** - Quick setup, config management, or full reinstall prep
- ✅ **K3s Compliant** - Hostname generation follows RFC 1123 standards
- 🌐 **Multi-Language** - English and Chinese support
- 🔒 **Security First** - Automatic cleanup of sensitive information

## Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
```

The script will:
- Automatically detect your system language (Chinese/English)
- Prompt for language selection
- Display an interactive menu
- Work correctly even when piped through curl

### Common Tasks

**Configure a new VPS (no reinstall needed)**:
```bash
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
# Select [3] Quick Setup
```

**Export configuration for backup**:
```bash
# Select [2] Export Config Code
# Copy and save the config code
```

**Import configuration on another server**:
```bash
# Select [1] Import Config Code
# Paste your config code
```

**Generate K3s-compliant hostname**:
```bash
# Select [4] Hostname Management
# Choose generation method
```

See [QUICK-START-V2.md](QUICK-START-V2.md) for detailed examples.

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

## Configuration as Code

Export your server configuration as a portable config code:

```json
{
  "version": "1.0",
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
    "timezone": "UTC"
  }
}
```

Encoded as base64 for easy copy/paste. Import on any server to replicate configuration.

## Architecture

Server Toolkit v2.0 uses a decoupled, component-based architecture:

```
bootstrap.sh (Main Entry)
    │
    ├── components/          # Atomic components
    │   ├── hostname/        # Generate/apply hostname
    │   ├── network/         # Detect/configure network
    │   └── system/          # System configuration
    │
    ├── workflows/           # Composed workflows
    │   ├── quick-setup.sh   # Quick configuration
    │   ├── export-config.sh # Export config code
    │   └── import-config.sh # Import config code
    │
    └── utils/               # Utility functions
        ├── common.sh        # Common functions
        ├── i18n.sh          # Internationalization
        └── config-codec.sh  # Config encoding/decoding
```

**Key Principles**:
- **Decoupled**: Each component is independent
- **Composable**: Components can be combined into workflows
- **Reusable**: Use components standalone or through workflows
- **Flexible**: Supports both reinstall and non-reinstall scenarios

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed documentation.

## Use Cases

### 1. New VPS Setup (No Reinstall)

Perfect for when you just got a new VPS and want to configure it quickly:

```bash
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
# Select [3] Quick Setup
# Configure hostname, network, timezone
# Select [2] Export Config Code (backup)
```

### 2. Clone Configuration Across Servers

Standardize configuration across multiple servers:

```bash
# On source server
# Select [2] Export Config Code
# Copy the config code

# On each target server
# Select [1] Import Config Code
# Paste the config code
```

### 3. Disaster Recovery

Restore configuration after server failure:

```bash
# Before disaster (good practice)
# Select [2] Export Config Code regularly

# After getting new server
# Select [1] Import Config Code
# Restore from backup
```

### 4. OS Reinstall

Prepare for and recover from OS reinstallation:

```bash
# Before reinstall
# Select [10] Reinstall Preparation
# Save restore script and config code

# After reinstall
bash restore-config-*.sh
# Or import config code
```

## Components

### Hostname Management

Generate K3s-compliant hostnames (RFC 1123):
- **Geo-location based**: `server-hongkong-hk-01`
- **Simple sequence**: `server-01`
- **Random suffix**: `server-a1b2c3d4`
- **Custom input**: With automatic sanitization

Features:
- Lowercase only, alphanumeric and hyphens
- Maximum 63 characters
- Apply immediately or save for config code

### Network Configuration

- Detect current network configuration
- Configure IP addresses, gateway, DNS
- Network optimization (BBR, FQ)
- Tailscale zero-trust network

### System Configuration

- Time synchronization (Chrony)
- System optimization (kernel parameters)
- Security hardening
- SSH optimization

### K3s Deployment

- K3s cluster deployment
- System Upgrade Controller
- Storage services (MinIO, Garage)
- Automatic maintenance

## Configuration

All configuration is done through:
1. **Interactive menus** - User-friendly prompts
2. **Config codes** - Import/export as base64 JSON
3. **Quick setup** - Guided wizard for common tasks

No manual configuration files required.

## Security

- **Automatic Cleanup**: Sensitive information is automatically cleaned up
- **Secure Deletion**: Files are securely deleted using shred
- **History Cleanup**: Bash history is cleaned of sensitive commands
- **Core Dump Disabled**: Core dumps are disabled to prevent memory leaks

## Documentation

- [Quick Start Guide](QUICK-START-V2.md) - Get started quickly with common tasks
- [Architecture Documentation](ARCHITECTURE.md) - Detailed architecture and design
- [Reinstall Script Guide](REINSTALL-SCRIPT-GUIDE.md) - OS reinstallation guide
- [Documentation Index](docs/README.md) - Complete documentation index

## Requirements

- **Operating System**: Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+, Rocky Linux 8+)
- **Shell**: Bash 4.0+
- **Network**: curl or wget
- **Privileges**: Root or sudo access
- **Optional**: jq (for config code features)

## License

MIT License

Copyright (c) 2024 K3s Forge

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

For major changes, please open an issue first to discuss what you would like to change.

## Support

- Documentation: [docs/](docs/)
- Issues: [GitHub Issues](https://github.com/k3s-forge/server-toolkit/issues)
- Discussions: [GitHub Discussions](https://github.com/k3s-forge/server-toolkit/discussions)

## Acknowledgments

Based on the k3s-setup project with significant enhancements and refactoring.

---

**Version**: 2.0.0  
**Architecture**: Decoupled Components  
**Status**: Production Ready  
**Last Updated**: 2024-12-30
