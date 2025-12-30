# Server Toolkit Documentation

Welcome to the Server Toolkit documentation!

## 📚 Documentation Index

### Getting Started
- [English README](../README.md) - Project overview and quick start
- [中文文档](../README.zh.md) - 项目概述和快速开始

### Project Information
- [Project Creation Plan](../PROJECT-CREATION-PLAN.md) - Complete project plan and file structure
- [Current Status](../CURRENT-STATUS.md) - Real-time development status
- [Progress Summary](../PROGRESS-SUMMARY.md) - Detailed progress report
- [Completion Summary](../COMPLETION-SUMMARY.md) - Project completion summary
- [Component Comparison](../COMPONENT-COMPARISON.md) - Comparison with k3s-setup and swarm-setup

### Technical Guides
- [Internationalization Integration](I18N-INTEGRATION.md) - Complete i18n guide with examples

## 🎯 Quick Links

### For Users
- **Quick Start**: See [README.md](../README.md#quick-start)
- **Pre-Reinstall Tools**: See [README.md](../README.md#pre-reinstall-tools)
- **Post-Reinstall Tools**: See [README.md](../README.md#post-reinstall-tools)

### For Developers
- **Project Structure**: See [PROJECT-CREATION-PLAN.md](../PROJECT-CREATION-PLAN.md#file-structure)
- **Migration Strategy**: See [PROJECT-CREATION-PLAN.md](../PROJECT-CREATION-PLAN.md#migration-strategy)
- **i18n Integration**: See [I18N-INTEGRATION.md](I18N-INTEGRATION.md)
- **Component Comparison**: See [COMPONENT-COMPARISON.md](../COMPONENT-COMPARISON.md)

## 📖 Documentation by Category

### Architecture
- [Project Creation Plan](../PROJECT-CREATION-PLAN.md) - Complete architecture and design
- [Component Comparison](../COMPONENT-COMPARISON.md) - Feature comparison across projects
- [README.md](../README.md) - Architecture overview

### Usage Guides
- [README.md](../README.md) - Basic usage
- [README.zh.md](../README.zh.md) - 基本使用方法
- [Completion Summary](../COMPLETION-SUMMARY.md) - Complete feature list

### Development Guides
- [I18N Integration](I18N-INTEGRATION.md) - How to add i18n support to scripts
- [Current Status](../CURRENT-STATUS.md) - What's done and what's next

### Reference
- [Progress Summary](../PROGRESS-SUMMARY.md) - Detailed component list and status

## 🌍 Language Support

All documentation is available in:
- **English** (Primary language)
- **中文** (Chinese translation)

Scripts automatically detect your system language and display messages accordingly.

## 🔧 Tools Documentation

### Utility Functions
- **common.sh**: Common utility functions for all scripts
- **cleanup.sh**: Security cleanup utilities
- **download.sh**: Download manager with retry logic
- **i18n.sh**: Internationalization support

### Pre-Reinstall Tools
- **detect-system.sh**: System detection and information gathering
- **backup-config.sh**: Configuration backup before reinstall
- **plan-network.sh**: Network configuration planning
- **prepare-reinstall.sh**: Generate automated reinstall script

### Post-Reinstall Tools
- **base/**: Basic system configuration (IP, hostname, DNS)
- **network/**: Network configuration (Tailscale, optimization)
- **system/**: System configuration (Chrony, optimization, security)
- **k3s/**: K3s deployment and management

## 📝 Contributing to Documentation

When adding new documentation:

1. **Use Markdown**: All documentation should be in Markdown format
2. **Bilingual**: Provide both English and Chinese versions
3. **Clear Structure**: Use clear headings and sections
4. **Code Examples**: Include practical code examples
5. **Update Index**: Update this README.md with links to new docs

## 🔗 External Resources

- **GitHub Repository**: https://github.com/k3s-forge/server-toolkit
- **Issue Tracker**: https://github.com/k3s-forge/server-toolkit/issues
- **Discussions**: https://github.com/k3s-forge/server-toolkit/discussions

## 📞 Support

If you need help:

1. Check the relevant documentation
2. Search existing issues
3. Create a new issue with details
4. Join our discussions

---

**Last Updated**: 2024-12-30  
**Version**: 1.0.0
