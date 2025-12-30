# Server Toolkit (服务器工具包)

> 模块化、按需下载的服务器管理工具包，支持重装前和重装后工作流程。

[English](README.md) | [文档](docs/README.zh.md)

## 概述

Server Toolkit 是一个轻量级、模块化的服务器管理解决方案，按需下载脚本并在执行后自动清理。适用于：

- **重装前**：系统检测、配置备份、网络规划
- **重装后**：基础配置、网络设置、系统优化、K3s 部署

## 核心特性

- 🚀 **按需下载** - 仅在需要时下载脚本
- 🧹 **自动清理** - 执行后自动删除脚本
- 📦 **模块化设计** - 每个脚本独立且专注
- 🔒 **安全优先** - 自动清理敏感信息
- 🌐 **两阶段工作流** - 重装前和重装后分离
- 📊 **部署报告** - 所有操作的详细报告

## 快速开始

### 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
```

### 手动安装

```bash
# 下载 bootstrap 脚本
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh -o bootstrap.sh

# 添加执行权限
chmod +x bootstrap.sh

# 运行
sudo ./bootstrap.sh
```

## 使用方法

### 主菜单

```
Server Toolkit - 主菜单
════════════════════════════════════════════════════════════

🔧 重装前工具
  [1] 检测系统信息
  [2] 备份当前配置
  [3] 规划网络配置
  [4] 生成重装脚本

🚀 重装后工具
  [5] 基础配置
  [6] 网络配置
  [7] 系统配置
  [8] K3s 部署

[0] 退出
```

### 重装前工作流程

1. **检测系统** - 收集系统信息
2. **备份配置** - 保存当前配置
3. **规划网络** - 规划 IP 地址和主机名
4. **生成脚本** - 创建重装自动化脚本

### 重装后工作流程

1. **基础配置** - IP 地址、主机名、DNS
2. **网络配置** - Tailscale、网络优化
3. **系统配置** - 时间同步、系统优化、安全加固
4. **K3s 部署** - 部署 K3s 集群

## 架构

```
server-toolkit/
├── bootstrap.sh              # 主入口（唯一常驻文件）
├── pre-reinstall/           # 重装前工具
│   ├── detect-system.sh
│   ├── backup-config.sh
│   ├── plan-network.sh
│   └── prepare-reinstall.sh
├── post-reinstall/          # 重装后工具
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
    ├── common.sh            # 通用函数
    ├── download.sh          # 下载管理器
    └── cleanup.sh           # 清理函数
```

## 功能特性

### 重装前工具

- **系统检测**：全面的系统信息收集
- **配置备份**：保存所有重要配置
- **网络规划**：规划 IP 地址、主机名和网络拓扑
- **重装脚本**：生成自动化重装脚本

### 重装后工具

#### 基础配置
- IP 地址管理（IPv4/IPv6）
- 主机名配置（带地理位置的 FQDN）
- DNS 配置

#### 网络配置
- Tailscale 零信任网络
  - DNS 管理
  - MagicDNS
  - 出口节点
  - 子网路由
- 网络优化（BBR、FQ）

#### 系统配置
- 时间同步（Chrony）
- 系统优化（内核参数、文件描述符）
- 安全加固
- SSH 优化

#### K3s 部署
- K3s 集群部署
- System Upgrade Controller
- 存储服务（MinIO、Garage）
- 自动维护

## 配置

所有配置通过菜单系统交互完成，无需配置文件。

## 安全性

- **自动清理**：敏感信息自动清理
- **安全删除**：使用 shred 安全删除文件
- **历史清理**：清理 Bash 历史中的敏感命令
- **禁用 Core Dump**：禁用核心转储防止内存泄露

## 文档

- [架构说明](docs/ARCHITECTURE.zh.md)
- [重装前指南](docs/PRE-REINSTALL.zh.md)
- [重装后指南](docs/POST-REINSTALL.zh.md)
- [API 参考](docs/API.zh.md)
- [贡献指南](CONTRIBUTING.zh.md)

## 系统要求

- Linux（Ubuntu 20.04+、Debian 11+、CentOS 8+、Rocky Linux 8+）
- Bash 4.0+
- curl 或 wget
- Root 或 sudo 权限

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 贡献

欢迎贡献！请阅读 [CONTRIBUTING.zh.md](CONTRIBUTING.zh.md) 了解详情。

## 支持

- 文档：[docs/](docs/)
- 问题反馈：[GitHub Issues](https://github.com/k3s-forge/server-toolkit/issues)
- 讨论：[GitHub Discussions](https://github.com/k3s-forge/server-toolkit/discussions)

## 致谢

基于 k3s-setup 项目进行了重大增强和重构。

---

**版本**：1.0.0  
**状态**：生产就绪  
**最后更新**：2024-12-30
