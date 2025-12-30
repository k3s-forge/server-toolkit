# Server Toolkit - Project Creation Plan

## Overview

This document outlines the complete file structure and creation plan for the Server Toolkit project.

## Project Status

- ✅ Core files created
- ⏳ Component scripts to be created
- ⏳ Documentation to be created
- ⏳ Examples and tests to be created

## File Structure

```
server-toolkit/
├── bootstrap.sh                      ✅ Main entry point
├── README.md                         ✅ English documentation
├── README.zh.md                      ✅ Chinese documentation
├── LICENSE                           ⏳ MIT License
├── CONTRIBUTING.md                   ⏳ Contribution guidelines
├── CONTRIBUTING.zh.md                ⏳ Chinese contribution guidelines
├── CHANGELOG.md                      ⏳ Version history
├── .gitignore                        ⏳ Git ignore rules
│
├── pre-reinstall/                    # Pre-reinstall tools
│   ├── detect-system.sh              ⏳ System detection
│   ├── backup-config.sh              ⏳ Configuration backup
│   ├── plan-network.sh               ⏳ Network planning
│   └── prepare-reinstall.sh          ⏳ Reinstall preparation
│
├── post-reinstall/                   # Post-reinstall tools
│   ├── base/                         # Base configuration
│   │   ├── setup-ip.sh               ⏳ IP address setup
│   │   ├── setup-hostname.sh         ⏳ Hostname setup
│   │   └── setup-dns.sh              ⏳ DNS setup
│   │
│   ├── network/                      # Network configuration
│   │   ├── setup-tailscale.sh        ⏳ Tailscale setup
│   │   └── optimize-network.sh       ⏳ Network optimization
│   │
│   ├── system/                       # System configuration
│   │   ├── setup-chrony.sh           ⏳ Time synchronization
│   │   ├── optimize-system.sh        ⏳ System optimization
│   │   └── setup-security.sh         ⏳ Security hardening
│   │
│   └── k3s/                          # K3s deployment
│       ├── deploy-k3s.sh             ⏳ K3s deployment
│       ├── setup-upgrade-controller.sh ⏳ Upgrade controller
│       └── deploy-storage.sh         ⏳ Storage deployment
│
├── utils/                            # Utility functions
│   ├── common.sh                     ⏳ Common functions
│   ├── download.sh                   ⏳ Download manager
│   ├── cleanup.sh                    ⏳ Cleanup functions
│   ├── api-helpers.sh                ⏳ API helpers
│   ├── ip-manager.sh                 ⏳ IP management
│   ├── system-reinstall.sh           ⏳ System reinstall
│   └── deployment-report.sh          ⏳ Report generation
│
├── config/                           # Configuration templates
│   ├── chrony.conf                   ⏳ Chrony configuration
│   └── sshd_config.template          ⏳ SSH configuration
│
├── manifests/                        # Kubernetes manifests
│   ├── system-upgrade-controller.yaml ⏳ SUC deployment
│   ├── k3s-upgrade-plan.yaml         ⏳ K3s upgrade plan
│   ├── system-maintenance-plans.yaml ⏳ Maintenance plans
│   ├── maintenance-cronjobs.yaml     ⏳ Maintenance cronjobs
│   ├── minio-deployment.yaml         ⏳ MinIO deployment
│   └── garage-deployment.yaml        ⏳ Garage deployment
│
├── docs/                             # Documentation
│   ├── README.md                     ⏳ Documentation index
│   ├── README.zh.md                  ⏳ Chinese documentation index
│   ├── ARCHITECTURE.md               ⏳ Architecture documentation
│   ├── ARCHITECTURE.zh.md            ⏳ Chinese architecture
│   ├── PRE-REINSTALL.md              ⏳ Pre-reinstall guide
│   ├── PRE-REINSTALL.zh.md           ⏳ Chinese pre-reinstall guide
│   ├── POST-REINSTALL.md             ⏳ Post-reinstall guide
│   ├── POST-REINSTALL.zh.md          ⏳ Chinese post-reinstall guide
│   ├── API.md                        ⏳ API reference
│   ├── API.zh.md                     ⏳ Chinese API reference
│   ├── SECURITY.md                   ⏳ Security documentation
│   ├── SECURITY.zh.md                ⏳ Chinese security documentation
│   └── TROUBLESHOOTING.md            ⏳ Troubleshooting guide
│
├── examples/                         # Usage examples
│   ├── README.md                     ⏳ Examples index
│   ├── pre-reinstall-workflow.sh     ⏳ Pre-reinstall example
│   ├── post-reinstall-workflow.sh    ⏳ Post-reinstall example
│   └── full-deployment.sh            ⏳ Full deployment example
│
├── tests/                            # Test scripts
│   ├── test-download.sh              ⏳ Download test
│   ├── test-cleanup.sh               ⏳ Cleanup test
│   └── test-integration.sh           ⏳ Integration test
│
└── .github/                          # GitHub configuration
    ├── workflows/
    │   ├── shellcheck.yml            ⏳ ShellCheck workflow
    │   └── test.yml                  ⏳ Test workflow
    └── ISSUE_TEMPLATE/
        ├── bug_report.md             ⏳ Bug report template
        └── feature_request.md        ⏳ Feature request template
```

## Component Details

### Pre-Reinstall Tools

#### 1. detect-system.sh
**Source**: k3s-setup/scripts/system-info.sh
**Purpose**: Comprehensive system information gathering
**Features**:
- OS detection
- Hardware information
- Network configuration
- Service status
- Security information

#### 2. backup-config.sh
**Source**: k3s-setup/bootstrap.sh (save_system_config function)
**Purpose**: Backup current system configuration
**Features**:
- IP addresses backup
- Hostname backup
- Network configuration backup
- Service configuration backup

#### 3. plan-network.sh
**Source**: k3s-setup/utils/ip-manager.sh + hostname-manager.sh
**Purpose**: Plan network configuration for new system
**Features**:
- IP address planning
- Hostname generation (FQDN with geo-location)
- Network topology planning

#### 4. prepare-reinstall.sh
**Source**: k3s-setup/utils/system-reinstall.sh
**Purpose**: Generate automated reinstall script
**Features**:
- Generate reinstall command
- Include all configurations
- Provide recovery instructions

### Post-Reinstall Tools

#### Base Configuration

##### setup-ip.sh
**Source**: k3s-setup/utils/ip-manager.sh
**Purpose**: Configure IP addresses
**Features**:
- IPv4/IPv6 configuration
- Multiple IP support
- Network backend detection (NetworkManager/systemd-networkd)
- Persistent configuration

##### setup-hostname.sh
**Source**: k3s-setup/scripts/hostname-manager.sh
**Purpose**: Configure hostname
**Features**:
- FQDN generation with geo-location
- Custom hostname support
- Persistent configuration

##### setup-dns.sh
**Source**: New (based on k3s-setup network configuration)
**Purpose**: Configure DNS
**Features**:
- DNS server configuration
- Search domain configuration
- systemd-resolved integration

#### Network Configuration

##### setup-tailscale.sh
**Source**: k3s-setup/scripts/tailscale-setup.sh
**Purpose**: Setup Tailscale zero-trust network
**Features**:
- Tailscale installation
- Network configuration
- DNS management
- MagicDNS
- Exit node
- Subnet routing

##### optimize-network.sh
**Source**: k3s-setup/scripts/network-optimization.sh
**Purpose**: Optimize network performance
**Features**:
- BBR congestion control
- FQ queue discipline
- TCP parameter tuning
- UDP GRO optimization

#### System Configuration

##### setup-chrony.sh
**Source**: k3s-setup/scripts/chrony-setup.sh
**Purpose**: Setup time synchronization
**Features**:
- Chrony installation
- NTP server configuration
- Timezone configuration

##### optimize-system.sh
**Source**: k3s-setup/scripts/system-optimization.sh
**Purpose**: Optimize system performance
**Features**:
- Kernel parameter tuning
- File descriptor limits
- Memory management
- Swap configuration

##### setup-security.sh
**Source**: k3s-setup/scripts/ssh-optimization.sh + security features
**Purpose**: Security hardening
**Features**:
- SSH optimization
- Firewall configuration
- Core dump disable
- History cleanup
- Automatic security updates

#### K3s Deployment

##### deploy-k3s.sh
**Source**: k3s-setup/scripts/k3s-setup.sh
**Purpose**: Deploy K3s cluster
**Features**:
- K3s installation
- Cluster initialization
- Node joining
- Flannel configuration
- Tailscale integration

##### setup-upgrade-controller.sh
**Source**: k3s-setup/scripts/deploy-system-upgrade-controller.sh
**Purpose**: Setup System Upgrade Controller
**Features**:
- SUC deployment
- Upgrade plan configuration
- Maintenance plan configuration

##### deploy-storage.sh
**Source**: k3s-setup manifests (minio, garage)
**Purpose**: Deploy storage services
**Features**:
- MinIO deployment
- Garage deployment
- Storage configuration

### Utility Functions

#### common.sh
**Source**: k3s-setup/utils/api-helpers.sh + bootstrap.sh functions
**Purpose**: Common utility functions
**Features**:
- Logging functions
- System detection
- Command checking
- Network testing

#### download.sh
**Source**: New (based on bootstrap.sh download logic)
**Purpose**: Download management
**Features**:
- Script downloading
- Retry logic
- Timeout handling
- Checksum verification

#### cleanup.sh
**Source**: k3s-setup/utils/security-cleanup.sh
**Purpose**: Cleanup functions
**Features**:
- Sensitive data cleanup
- Temporary file cleanup
- History cleanup
- Secure file deletion

#### api-helpers.sh
**Source**: k3s-setup/utils/api-helpers.sh
**Purpose**: API helper functions
**Features**:
- Tailscale API
- Geo-location API
- HTTP request helpers

#### ip-manager.sh
**Source**: k3s-setup/utils/ip-manager.sh
**Purpose**: IP address management
**Features**:
- IP configuration
- Network backend detection
- Persistent configuration

#### system-reinstall.sh
**Source**: k3s-setup/utils/system-reinstall.sh
**Purpose**: System reinstall utilities
**Features**:
- Reinstall script generation
- Configuration preservation

#### deployment-report.sh
**Source**: k3s-setup/utils/deployment-report.sh
**Purpose**: Deployment report generation
**Features**:
- Detailed report generation
- Configuration summary
- Next steps recommendations

## Migration Strategy

### Phase 1: Core Infrastructure (Priority 1)
1. ✅ bootstrap.sh - Main entry point
2. ✅ README files - Documentation
3. ⏳ utils/common.sh - Common functions
4. ⏳ utils/download.sh - Download manager
5. ⏳ utils/cleanup.sh - Cleanup functions

### Phase 2: Pre-Reinstall Tools (Priority 2)
1. ⏳ pre-reinstall/detect-system.sh
2. ⏳ pre-reinstall/backup-config.sh
3. ⏳ pre-reinstall/plan-network.sh
4. ⏳ pre-reinstall/prepare-reinstall.sh

### Phase 3: Post-Reinstall Base (Priority 3)
1. ⏳ post-reinstall/base/setup-ip.sh
2. ⏳ post-reinstall/base/setup-hostname.sh
3. ⏳ post-reinstall/base/setup-dns.sh

### Phase 4: Post-Reinstall Network (Priority 4)
1. ⏳ post-reinstall/network/setup-tailscale.sh
2. ⏳ post-reinstall/network/optimize-network.sh

### Phase 5: Post-Reinstall System (Priority 5)
1. ⏳ post-reinstall/system/setup-chrony.sh
2. ⏳ post-reinstall/system/optimize-system.sh
3. ⏳ post-reinstall/system/setup-security.sh

### Phase 6: K3s Deployment (Priority 6)
1. ⏳ post-reinstall/k3s/deploy-k3s.sh
2. ⏳ post-reinstall/k3s/setup-upgrade-controller.sh
3. ⏳ post-reinstall/k3s/deploy-storage.sh

### Phase 7: Documentation (Priority 7)
1. ⏳ docs/ARCHITECTURE.md
2. ⏳ docs/PRE-REINSTALL.md
3. ⏳ docs/POST-REINSTALL.md
4. ⏳ docs/API.md
5. ⏳ docs/SECURITY.md

### Phase 8: Examples and Tests (Priority 8)
1. ⏳ examples/
2. ⏳ tests/
3. ⏳ .github/workflows/

## Key Differences from k3s-setup

1. **Language**: English primary, Chinese translation
2. **Architecture**: On-demand download, auto cleanup
3. **Structure**: Two-phase workflow (pre/post reinstall)
4. **Modularity**: Each script is completely independent
5. **Simplicity**: Only bootstrap.sh is persistent

## Next Steps

1. Create utility functions (common.sh, download.sh, cleanup.sh)
2. Create pre-reinstall tools
3. Create post-reinstall tools
4. Create documentation
5. Create examples and tests
6. Test complete workflow

## Estimated Timeline

- Phase 1-3: 2-3 hours
- Phase 4-6: 3-4 hours
- Phase 7-8: 2-3 hours
- **Total**: 7-10 hours

## Notes

- All scripts must be self-contained
- All scripts must handle cleanup
- All scripts must provide clear output
- All scripts must support non-interactive mode
- All documentation must be bilingual (EN/ZH)
