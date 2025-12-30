# Server Toolkit 文档索引

## 📚 核心文档

### 用户文档

| 文档 | 说明 | 用途 |
|------|------|------|
| [README.md](README.md) | 项目主文档（英文） | 项目介绍、快速开始 |
| [README.zh.md](README.zh.md) | 项目主文档（中文） | 中文用户指南 |
| [QUICK-START-V2.md](QUICK-START-V2.md) | 快速开始指南 | 新用户入门 |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 架构设计文档 | 了解系统架构 |
| [MIGRATION-V1-TO-V2.md](MIGRATION-V1-TO-V2.md) | 迁移指南 | 从 v1 升级到 v2 |
| [REINSTALL-SCRIPT-GUIDE.md](REINSTALL-SCRIPT-GUIDE.md) | 重装脚本指南 | 系统重装功能说明 |

### 技术文档

| 文档 | 说明 | 用途 |
|------|------|------|
| [STATUS.md](STATUS.md) | 项目状态 | 当前实施状态和待办事项 |
| [TESTING-CHECKLIST.md](TESTING-CHECKLIST.md) | 测试清单 | 功能测试指南 |
| [COMPLETION-SUMMARY-V2.md](COMPLETION-SUMMARY-V2.md) | 完成总结 | v2.0.2 实施总结 |

### 决策文档

| 文档 | 说明 | 用途 |
|------|------|------|
| [FINAL-DECISION.md](FINAL-DECISION.md) | 最终决策 | 核心设计决策记录 |
| [K8S-HOSTNAME-COMPLIANCE.md](K8S-HOSTNAME-COMPLIANCE.md) | K8s 合规性 | 主机名标准验证 |
| [FQDN-VS-SHORT-NAME.md](FQDN-VS-SHORT-NAME.md) | 格式对比 | FQDN vs 短名分析 |
| [HOSTNAME-UNIFICATION-COMPLETE.md](HOSTNAME-UNIFICATION-COMPLETE.md) | 主机名统一 | 主机名实施详情 |

## 📂 目录结构

```
server-toolkit/
├── bootstrap.sh                    # 主入口脚本
│
├── components/                     # 原子化组件
│   ├── hostname/                   # 主机名管理
│   │   ├── generate.sh            # 生成主机名
│   │   ├── apply.sh               # 应用主机名
│   │   └── manage.sh              # 交互式管理
│   └── network/                    # 网络配置
│       └── detect.sh              # 网络检测
│
├── workflows/                      # 工作流
│   ├── quick-setup.sh             # 快速配置
│   ├── export-config.sh           # 导出配置码
│   └── import-config.sh           # 导入配置码
│
├── utils/                          # 工具库
│   ├── common-header.sh           # 通用头文件
│   ├── i18n.sh                    # 国际化
│   ├── config-codec.sh            # 配置编解码
│   ├── cleanup.sh                 # 安全清理
│   └── download.sh                # 下载工具
│
├── pre-reinstall/                  # 重装前准备
│   ├── detect-system.sh           # 系统检测
│   ├── backup-config.sh           # 配置备份
│   ├── plan-network.sh            # 网络规划
│   ├── prepare-reinstall.sh       # 准备重装
│   ├── prepare-wizard.sh          # 准备向导
│   └── reinstall-os.sh            # 系统重装
│
├── post-reinstall/                 # 重装后配置
│   ├── base/                      # 基础配置
│   │   ├── setup-hostname.sh     # 主机名配置
│   │   ├── setup-ip.sh           # IP 配置
│   │   └── setup-dns.sh          # DNS 配置
│   ├── network/                   # 网络配置
│   │   ├── optimize-network.sh   # 网络优化
│   │   └── setup-tailscale.sh    # Tailscale 配置
│   ├── system/                    # 系统配置
│   │   ├── setup-security.sh     # 安全配置
│   │   ├── setup-chrony.sh       # 时间同步
│   │   └── optimize-system.sh    # 系统优化
│   └── k3s/                       # K3s 配置
│       ├── deploy-k3s.sh         # 部署 K3s
│       ├── deploy-storage.sh     # 存储配置
│       └── setup-upgrade-controller.sh  # 升级控制器
│
└── docs/                           # 文档目录
    └── README.md                  # 文档说明
```

## 🎯 快速导航

### 我想...

- **开始使用** → [QUICK-START-V2.md](QUICK-START-V2.md)
- **了解架构** → [ARCHITECTURE.md](ARCHITECTURE.md)
- **从 v1 迁移** → [MIGRATION-V1-TO-V2.md](MIGRATION-V1-TO-V2.md)
- **查看状态** → [STATUS.md](STATUS.md)
- **测试功能** → [TESTING-CHECKLIST.md](TESTING-CHECKLIST.md)
- **了解主机名** → [HOSTNAME-UNIFICATION-COMPLETE.md](HOSTNAME-UNIFICATION-COMPLETE.md)
- **查看决策** → [FINAL-DECISION.md](FINAL-DECISION.md)

## 📝 文档维护

### 保留原则

- ✅ 用户需要的文档（README、快速开始、指南）
- ✅ 技术参考文档（架构、状态、测试）
- ✅ 重要决策记录（最终决策、合规性验证）
- ❌ 临时开发记录（已删除）
- ❌ 重复的总结文档（已删除）
- ❌ 过程性更新记录（已删除）

### 已清理的文档

以下临时文档已被删除（内容已整合到保留文档中）：

- `COMPLETION-SUMMARY.md` → 已被 `COMPLETION-SUMMARY-V2.md` 替代
- `LANGUAGE-SELECTION-UPDATE.md` → 临时更新记录
- `COMPONENT-COMPARISON.md` → 已整合到 `ARCHITECTURE.md`
- `FIXES-SUMMARY.md` → 已整合到 `STATUS.md`
- `I18N-UPDATE.md` → 临时更新记录
- `PROJECT-VERIFICATION.md` → 临时验证记录
- `GITHUB-LINKS-UPDATE.md` → 临时更新记录
- `V2-FIXES.md` → 已整合到其他文档
- `V2-IMPLEMENTATION-SUMMARY.md` → 已被新版本替代
- `CURRENT-STATUS.md` → 已被 `STATUS.md` 替代
- `PROGRESS-SUMMARY.md` → 已被 `STATUS.md` 替代
- `PROJECT-CREATION-PLAN.md` → 已完成的计划文档
- `PIPE-FIX.md` → 临时修复记录
- `FINAL-UPDATE-SUMMARY.md` → 已整合到其他文档
- `MENU-SIMPLIFICATION.md` → 已整合到 `STATUS.md`
- `IMPLEMENTATION-COMPLETE.md` → 已被新版本替代

## 🔄 版本历史

- **v2.0.2** (2024-12-30) - 主机名统一实施完成
- **v2.0.1** (2024-12-30) - 自动安全清理实施
- **v2.0.0** (2024-12-29) - 完全解耦架构重构

---

**最后更新**: 2024-12-30  
**维护者**: Server Toolkit Team
