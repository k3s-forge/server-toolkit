# 国际化更新说明

## 更新日期
**日期**: 2024-12-30  
**版本**: 1.0.1

## 更新内容

### bootstrap.sh 完整中文支持

`bootstrap.sh` 现在已经完全支持中文界面！

## 功能特性

### 1. 自动语言检测
系统会自动检测您的系统语言：
- 中文系统（zh_CN, zh_TW, zh_HK, zh_SG）→ 自动显示中文界面
- 其他系统 → 显示英文界面

### 2. 手动切换语言
您可以通过环境变量手动指定语言：

```bash
# 使用中文
export TOOLKIT_LANG=zh
./bootstrap.sh

# 使用英文
export TOOLKIT_LANG=en
./bootstrap.sh
```

### 3. 完整的中文菜单

#### 主菜单（中文）
```
════════════════════════════════════════════════════════════
  服务器工具包 - 主菜单
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

📊 实用工具
  [9] 查看部署报告
  [10] 安全清理

[0] 退出
```

#### 主菜单（英文）
```
════════════════════════════════════════════════════════════
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

📊 Utilities
  [9] View Deployment Report
  [10] Security Cleanup

[0] Exit
```

### 4. 所有子菜单都支持中文

#### 基础配置菜单
- 中文：配置 IP 地址、配置主机名、配置 DNS、全部基础配置
- 英文：Setup IP Addresses、Setup Hostname、Setup DNS、All Base Configuration

#### 网络配置菜单
- 中文：配置 Tailscale、网络优化、全部网络配置
- 英文：Setup Tailscale、Network Optimization、All Network Configuration

#### 系统配置菜单
- 中文：配置时间同步 (Chrony)、系统优化、安全加固、全部系统配置
- 英文：Setup Time Sync (Chrony)、System Optimization、Security Hardening、All System Configuration

#### K3s 部署菜单
- 中文：部署 K3s、配置升级控制器、部署存储 (MinIO/Garage)、完整 K3s 部署
- 英文：Deploy K3s、Setup Upgrade Controller、Deploy Storage (MinIO/Garage)、Full K3s Deployment

### 5. 所有日志消息都支持中文

#### 信息消息
- 中文：[信息]、[成功]、[警告]、[错误]
- 英文：[INFO]、[SUCCESS]、[WARN]、[ERROR]

#### 操作消息
- 中文：检查系统要求...、下载中、执行中、完成、失败
- 英文：Checking system requirements...、Downloading、Executing、Completed、Failed

#### 交互消息
- 中文：选择、返回主菜单、按 Enter 继续...、无效选择
- 英文：Select、Back to Main Menu、Press Enter to continue...、Invalid choice

## 使用示例

### 示例 1：自动检测（中文系统）
```bash
# 在中文系统上运行，自动显示中文
./bootstrap.sh
```

### 示例 2：强制使用中文
```bash
# 即使在英文系统上，也显示中文
export TOOLKIT_LANG=zh
./bootstrap.sh
```

### 示例 3：强制使用英文
```bash
# 即使在中文系统上，也显示英文
export TOOLKIT_LANG=en
./bootstrap.sh
```

### 示例 4：一次性指定语言
```bash
# 不设置环境变量，直接运行
TOOLKIT_LANG=zh ./bootstrap.sh
```

## 技术实现

### 语言检测函数
```bash
detect_language() {
    local lang="${LANG:-en_US.UTF-8}"
    case "$lang" in
        zh_CN*|zh_TW*|zh_HK*|zh_SG*)
            echo "zh"
            ;;
        *)
            echo "en"
            ;;
    esac
}

# 设置语言（可通过环境变量覆盖）
TOOLKIT_LANG="${TOOLKIT_LANG:-$(detect_language)}"
```

### 消息翻译函数
```bash
msg() {
    local key="$1"
    case "$TOOLKIT_LANG" in
        zh)
            case "$key" in
                "main_menu_title") echo "服务器工具包 - 主菜单" ;;
                "detect_system") echo "检测系统信息" ;;
                # ... 更多翻译
            esac
            ;;
        *)
            case "$key" in
                "main_menu_title") echo "Server Toolkit - Main Menu" ;;
                "detect_system") echo "Detect System Information" ;;
                # ... 更多翻译
            esac
            ;;
    esac
}
```

### 使用翻译
```bash
# 在菜单中使用
echo "  [1] $(msg 'detect_system')"

# 在日志中使用
log_info "$(msg 'checking_requirements')"

# 在提示中使用
read -p "$(msg 'select') [0-10]: " choice
```

## 支持的语言

### 当前支持
- ✅ 英文 (en) - 主语言
- ✅ 中文 (zh) - 完整翻译

### 未来计划
- ⏳ 日文 (ja)
- ⏳ 韩文 (ko)
- ⏳ 法文 (fr)
- ⏳ 德文 (de)
- ⏳ 西班牙文 (es)

## 翻译的消息键

### 菜单相关（20+ 个）
- banner_title, banner_subtitle
- main_menu_title
- pre_reinstall_tools, post_reinstall_tools, utilities
- detect_system, backup_config, plan_network, generate_script
- base_config, network_config, system_config, k3s_deploy
- view_report, security_cleanup
- exit, select, back

### 子菜单相关（20+ 个）
- base_config_title, network_config_title, system_config_title, k3s_deploy_title
- setup_ip, setup_hostname, setup_dns, all_base
- setup_tailscale, optimize_network, all_network
- setup_chrony, optimize_system, setup_security, all_system
- deploy_k3s, setup_upgrade, deploy_storage, full_k3s

### 日志相关（20+ 个）
- info, success, warn, error
- checking_requirements, requirements_passed
- starting_detection, starting_backup, starting_planning, generating_reinstall
- downloading, executing, completed, failed
- cleaning_up, cleanup_complete
- thank_you, invalid_choice, press_enter
- no_report, report_after_deploy, starting_cleanup

## 注意事项

1. **环境变量优先级**
   - 环境变量 `TOOLKIT_LANG` 优先于自动检测
   - 如果未设置，则自动检测系统语言

2. **子脚本语言传递**
   - `TOOLKIT_LANG` 会自动传递给所有子脚本
   - 确保所有子脚本都支持 i18n

3. **Banner 对齐**
   - 中文字符宽度不同，Banner 可能需要调整
   - 当前版本已经优化了对齐

4. **Emoji 支持**
   - 菜单中使用了 Emoji（🔧🚀📊）
   - 确保终端支持 UTF-8 和 Emoji 显示

## 测试

### 测试中文显示
```bash
# 方法 1：设置环境变量
export TOOLKIT_LANG=zh
./bootstrap.sh

# 方法 2：临时设置
TOOLKIT_LANG=zh ./bootstrap.sh

# 方法 3：修改系统语言（临时）
export LANG=zh_CN.UTF-8
./bootstrap.sh
```

### 测试英文显示
```bash
# 方法 1：设置环境变量
export TOOLKIT_LANG=en
./bootstrap.sh

# 方法 2：临时设置
TOOLKIT_LANG=en ./bootstrap.sh

# 方法 3：修改系统语言（临时）
export LANG=en_US.UTF-8
./bootstrap.sh
```

## 更新历史

- **2024-12-30**: 初始版本，完整的中英文支持
  - 添加语言自动检测
  - 添加 50+ 翻译消息键
  - 所有菜单和日志都支持中文
  - 支持手动切换语言

---

**更新完成日期**: 2024-12-30  
**项目版本**: 1.0.1  
**状态**: ✅ 完整中文支持已实现

