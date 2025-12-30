# Server Toolkit

> A modular, on-demand server management toolkit with pre-reinstall and post-reinstall workflows.

[中文文档](README.zh.md) | [Documentation](docs/README.md)

## Overview

Server Toolkit is a lightweight, modular server management solution that downloads scripts on-demand and cleans up after execution. It's designed for:

- **Pre-Reinstall**: System detection, configuration backup, network planning
- **Post-Reinstall**: Base configuration, network setup, system optimization, K3s deployment

## Key Features

- 🚀 **On-Demand Download** - Scripts are downloaded only when needed
- 🧹 **Auto Cleanup** - Scripts are deleted after execution
- 📦 **Modular Design** - Each script is independent and focused
- 🔒 **Security First** - Automatic cleanup of sensitive information
- 🌐 **Two-Phase Workflow** - Pre-reinstall and post-reinstall separation
- 📊 **Deployment Reports** - Detailed reports of all operations

## Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
```

This command will:
- Download and execute the bootstrap script
- Automatically detect your system language (Chinese/English)
- Display an interactive menu for you to choose operations
- Work correctly even when piped through curl

### Alternative: Download First

```bash
# Download bootstrap script
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh -o bootstrap.sh

# Make it executable
chmod +x bootstrap.sh

# Run
sudo ./bootstrap.sh
```

## Usage

### Main Menu

```
Server Toolkit - Main Menu
════════════════════════════════════════════════════════════

🔧 Pre-Reinstall Tools
  [1] Detect System Information
  [2] Backup Current Configuration
  [3] Plan Network Configuration
  [4] Generate Reinstall Script

🚀 Post-Reinstall Tools
  [5] Base Configuration
  [6] Network Configuration
  [7] System Configuration
  [8] K3s Deployment

[0] Exit
```

### Pre-Reinstall Workflow

1. **Detect System** - Gather system information
2. **Backup Config** - Save current configuration
3. **Plan Network** - Plan IP addresses and hostnames
4. **Generate Script** - Create reinstall automation script

### Post-Reinstall Workflow

1. **Base Config** - IP addresses, hostname, DNS
2. **Network** - Tailscale, network optimization
3. **System** - Time sync, system optimization, security
4. **K3s** - Deploy K3s cluster

## Architecture

```
server-toolkit/
├── bootstrap.sh              # Main entry point (only persistent file)
├── pre-reinstall/           # Pre-reinstall tools
│   ├── detect-system.sh
│   ├── backup-config.sh
│   ├── plan-network.sh
│   └── prepare-reinstall.sh
├── post-reinstall/          # Post-reinstall tools
│   ├── base/
│   │   ├── setup-ip.sh
│   │   ├── setup-hostname.sh
│   │   └── setup-dns.sh
│   ├── network/
│   │   ├── setup-tailscale.sh
│   │   └── optimize-network.sh
│   ├── system/
│   │   ├── setup-chrony.sh
│   │   ├── optimize-system.sh
│   │   └── setup-security.sh
│   └── k3s/
│       ├── deploy-k3s.sh
│       ├── setup-upgrade-controller.sh
│       └── deploy-storage.sh
└── utils/
    ├── common.sh            # Common functions
    ├── download.sh          # Download manager
    └── cleanup.sh           # Cleanup functions
```

## Features

### Pre-Reinstall Tools

- **System Detection**: Comprehensive system information gathering
- **Configuration Backup**: Save all important configurations
- **Network Planning**: Plan IP addresses, hostnames, and network topology
- **Reinstall Script**: Generate automated reinstall script

### Post-Reinstall Tools

#### Base Configuration
- IP address management (IPv4/IPv6)
- Hostname configuration (FQDN with geo-location)
- DNS configuration

#### Network Configuration
- Tailscale zero-trust network
  - DNS management
  - MagicDNS
  - Exit node
  - Subnet routing
- Network optimization (BBR, FQ)

#### System Configuration
- Time synchronization (Chrony)
- System optimization (kernel parameters, file descriptors)
- Security hardening
- SSH optimization

#### K3s Deployment
- K3s cluster deployment
- System Upgrade Controller
- Storage services (MinIO, Garage)
- Automatic maintenance

## Configuration

All configuration is done interactively through the menu system. No configuration files are required.

## Security

- **Automatic Cleanup**: Sensitive information is automatically cleaned up
- **Secure Deletion**: Files are securely deleted using shred
- **History Cleanup**: Bash history is cleaned of sensitive commands
- **Core Dump Disabled**: Core dumps are disabled to prevent memory leaks

## Documentation

- [Documentation Index](docs/README.md) - Complete documentation index
- [I18N Integration Guide](docs/I18N-INTEGRATION.md) - Internationalization guide
- [Project Creation Plan](PROJECT-CREATION-PLAN.md) - Complete project plan
- [Current Status](CURRENT-STATUS.md) - Development status
- [Progress Summary](PROGRESS-SUMMARY.md) - Detailed progress
- [Completion Summary](COMPLETION-SUMMARY.md) - Project completion summary
- [Component Comparison](COMPONENT-COMPARISON.md) - Feature comparison

## Requirements

- Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+, Rocky Linux 8+)
- Bash 4.0+
- curl or wget
- Root or sudo access

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

**Version**: 1.0.0  
**Status**: Production Ready  
**Last Updated**: 2024-12-30
