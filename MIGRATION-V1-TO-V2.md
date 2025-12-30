# Migration Guide: v1.0 to v2.0

## Overview

Server Toolkit v2.0 introduces a completely new architecture. This guide helps you understand the changes and migrate smoothly.

## What Changed?

### Architecture

**v1.0**: Reinstall-centric workflow
```
Pre-Reinstall → Reinstall → Post-Reinstall
```

**v2.0**: Component-based architecture
```
Components ← Workflows → Configuration as Code
```

### Menu Structure

**v1.0 Menu**:
```
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

📊 Utilities
  [9] View Deployment Report
  [10] Security Cleanup
```

**v2.0 Menu**:
```
🔧 Configuration Management
  [1] Import Config Code
  [2] Export Config Code
  [3] Quick Setup

⚙️  Components
  [4] Hostname Management
  [5] Network Configuration
  [6] System Configuration

🚀 K3s Deployment
  [7] Deploy K3s

📊 Utilities
  [8] View Configuration
  [9] Security Cleanup

💾 Advanced
  [10] Reinstall Preparation
```

## Feature Mapping

### v1.0 → v2.0 Equivalents

| v1.0 Feature | v2.0 Equivalent | Notes |
|--------------|-----------------|-------|
| Detect System Information | [8] View Configuration | Enhanced with more details |
| Backup Current Configuration | [2] Export Config Code | Now uses config codes |
| Plan Network Configuration | [3] Quick Setup | Interactive wizard |
| Generate Reinstall Script | [10] Reinstall Preparation | Moved to advanced |
| Base Configuration | [4] Hostname Management | Now component-based |
| Network Configuration | [5] Network Configuration | Enhanced detection |
| System Configuration | [6] System Configuration | Same functionality |
| K3s Deployment | [7] Deploy K3s | Same functionality |
| View Deployment Report | [8] View Configuration | Real-time view |
| Security Cleanup | [9] Security Cleanup | Same functionality |

## Migration Scenarios

### Scenario 1: Regular User (No Custom Scripts)

**Action Required**: None! Just use the new menu.

**Recommended Steps**:
1. Run bootstrap as usual
2. Explore new menu structure
3. Try [2] Export Config Code to backup current config
4. Familiarize with [3] Quick Setup for future servers

**Benefits**:
- More flexible workflows
- Configuration backup as code
- Better for non-reinstall scenarios

### Scenario 2: Using Pre-Reinstall Workflow

**v1.0 Workflow**:
```bash
[1] Detect System Information
[2] Backup Current Configuration
[3] Plan Network Configuration
[4] Generate Reinstall Script
```

**v2.0 Equivalent**:
```bash
[10] Reinstall Preparation
# Or use new approach:
[2] Export Config Code
```

**Migration**:
- Old workflow still available in [10] Reinstall Preparation
- New approach: Export config code, reinstall, import config code
- More flexible and portable

### Scenario 3: Using Post-Reinstall Workflow

**v1.0 Workflow**:
```bash
[5] Base Configuration
  → Setup IP, Hostname, DNS
[6] Network Configuration
  → Tailscale, Optimization
[7] System Configuration
  → Chrony, Optimization, Security
[8] K3s Deployment
```

**v2.0 Equivalent**:
```bash
[1] Import Config Code (if you have one)
# Or
[3] Quick Setup
# Then
[5] Network Configuration
[6] System Configuration
[7] Deploy K3s
```

**Migration**:
- Same functionality, better organization
- Can now import pre-saved configuration
- Quick Setup wizard for common tasks

### Scenario 4: Custom Scripts Using Components

**v1.0 Approach**:
```bash
# Download and run specific scripts
curl -fsSL .../post-reinstall/base/setup-hostname.sh | bash
```

**v2.0 Approach**:
```bash
# Use components
curl -fsSL .../components/hostname/generate.sh -o generate.sh
bash generate.sh geo server 01

curl -fsSL .../components/hostname/apply.sh -o apply.sh
bash apply.sh apply server-hongkong-hk-01
```

**Migration**:
- Components are more focused and reusable
- Better separation of concerns
- Can be composed into custom workflows

## New Features in v2.0

### 1. Configuration as Code

**What**: Export/import configuration as base64-encoded JSON

**Why**: 
- Portable across servers
- Version controllable
- Easy to share and backup

**How to Use**:
```bash
# Export
[2] Export Config Code
# Copy the config code

# Import on another server
[1] Import Config Code
# Paste the config code
```

### 2. Quick Setup Workflow

**What**: Configure server without reinstalling OS

**Why**:
- Many VPS don't need reinstall
- Faster configuration
- Less risky

**How to Use**:
```bash
[3] Quick Setup
# Follow interactive prompts
```

### 3. Hostname Management

**What**: Generate K3s-compliant hostnames

**Why**:
- Ensures RFC 1123 compliance
- Multiple generation methods
- Can apply immediately or save for later

**How to Use**:
```bash
[4] Hostname Management
# Choose generation method
# Apply immediately or save for config code
```

### 4. Component Independence

**What**: Each component can be used standalone

**Why**:
- Maximum flexibility
- Easy to integrate into custom workflows
- Better for automation

**How to Use**:
```bash
# Download component
curl -fsSL .../components/hostname/generate.sh -o generate.sh

# Use directly
bash generate.sh geo server 01
```

## Breaking Changes

### None for Regular Users

If you're using the interactive menu, there are **no breaking changes**. The menu structure is different, but all functionality is preserved.

### For Custom Scripts

If you have custom scripts that call specific components:

**Old Path**:
```bash
post-reinstall/base/setup-hostname.sh
```

**New Path**:
```bash
components/hostname/manage.sh
# Or more specific:
components/hostname/generate.sh
components/hostname/apply.sh
```

**Migration**:
- Update paths in your scripts
- Consider using new component structure
- Old paths still work but may be deprecated in future

## Recommended Migration Path

### Step 1: Backup Current Configuration

```bash
# Run v2.0 bootstrap
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash

# Export current config
[2] Export Config Code

# Save the config code securely
```

### Step 2: Familiarize with New Menu

```bash
# Explore new menu structure
# Try [8] View Configuration
# Try [4] Hostname Management
```

### Step 3: Test New Workflows

```bash
# On a test server
[1] Import Config Code
# Paste your saved config code
# Verify it works as expected
```

### Step 4: Update Custom Scripts (if any)

```bash
# Update component paths
# Test thoroughly
# Update documentation
```

### Step 5: Adopt New Practices

```bash
# Use [2] Export Config Code regularly
# Use [3] Quick Setup for new servers
# Use [1] Import Config Code for cloning
```

## FAQ

### Q: Will my old scripts still work?

**A**: Yes! Old pre-reinstall and post-reinstall scripts are still available through [10] Reinstall Preparation and the component menus.

### Q: Do I need to reinstall to use v2.0?

**A**: No! v2.0 works great without reinstalling. Use [3] Quick Setup or [2] Export Config Code.

### Q: What happens to my existing configuration?

**A**: Nothing changes automatically. Your configuration remains intact. Use [2] Export Config Code to backup.

### Q: Can I still use the old workflow?

**A**: Yes! The old reinstall workflow is available in [10] Reinstall Preparation.

### Q: What if I don't want to use config codes?

**A**: No problem! You can still use the interactive menus as before. Config codes are optional.

### Q: How do I generate K3s-compliant hostnames?

**A**: Use [4] Hostname Management. It ensures RFC 1123 compliance automatically.

### Q: Can I use components in my own scripts?

**A**: Yes! Components are designed to be used standalone. Download and use them directly.

### Q: What if I find a bug?

**A**: Please report it on [GitHub Issues](https://github.com/k3s-forge/server-toolkit/issues).

## Benefits of Migrating

### 1. More Flexible

- Not centered around reinstall
- Works for any scenario
- Better for modern workflows

### 2. More Portable

- Configuration as code
- Easy to clone configurations
- Version controllable

### 3. More Maintainable

- Clear component structure
- Easy to understand
- Easy to extend

### 4. More Powerful

- K3s-compliant hostnames
- Better network detection
- Enhanced workflows

### 5. Future-Proof

- Solid foundation for new features
- Plugin system planned
- API server planned

## Getting Help

### Documentation

- [Quick Start Guide](QUICK-START-V2.md) - Get started quickly
- [Architecture Documentation](ARCHITECTURE.md) - Detailed architecture
- [Implementation Summary](V2-IMPLEMENTATION-SUMMARY.md) - What was built

### Support

- [GitHub Issues](https://github.com/k3s-forge/server-toolkit/issues) - Bug reports
- [GitHub Discussions](https://github.com/k3s-forge/server-toolkit/discussions) - Questions

### Community

- Share your config codes (without sensitive data)
- Contribute components
- Report bugs and suggest features

## Conclusion

Server Toolkit v2.0 is a major upgrade that provides:

✅ **Better flexibility** - Works for all scenarios  
✅ **Better portability** - Configuration as code  
✅ **Better maintainability** - Clear component structure  
✅ **Better compliance** - K3s-compliant hostnames  
✅ **Better future** - Solid foundation for enhancements  

**Migration is smooth and optional**. Old workflows still work, but new workflows provide significant benefits.

**Recommended**: Start using [2] Export Config Code to backup your configurations, then explore new features at your own pace.

---

**Version**: 2.0.0  
**Migration Difficulty**: Easy  
**Breaking Changes**: None for regular users  
**Recommended**: Yes!
