# Internationalization (i18n) Integration Guide

## Overview

Server Toolkit includes complete internationalization support with English as the primary language and Chinese as the translation language. All scripts automatically detect the system language and display messages accordingly.

## Features

- **Auto Language Detection**: Automatically detects system language from `$LANG` environment variable
- **Dual Language Support**: English (primary) and Chinese (translation)
- **Message Key System**: Centralized message management
- **Localized Logging**: All log messages support i18n
- **Easy Integration**: Simple to use in any script

## Language Detection

The system automatically detects the language based on the `$LANG` environment variable:

```bash
# Chinese locales
zh_CN.UTF-8, zh_TW.UTF-8, zh_HK.UTF-8, zh_SG.UTF-8 → Chinese

# All other locales → English (default)
en_US.UTF-8, en_GB.UTF-8, etc. → English
```

## Manual Language Override

You can manually set the language using the `TOOLKIT_LANG` environment variable:

```bash
# Force English
export TOOLKIT_LANG=en
./script.sh

# Force Chinese
export TOOLKIT_LANG=zh
./script.sh
```

## Usage in Scripts

### 1. Load i18n Module

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# Load common functions and i18n
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"
```

### 2. Use Localized Logging Functions

```bash
# Info message
i18n_info "detect_os"
# Output (EN): [INFO] 2024-12-30 10:00:00 - Detecting operating system...
# Output (ZH): [信息] 2024-12-30 10:00:00 - 检测操作系统...

# Success message
i18n_success "completed" "System detection"
# Output (EN): [SUCCESS] 2024-12-30 10:00:00 - Completed System detection
# Output (ZH): [成功] 2024-12-30 10:00:00 - 已完成 System detection

# Warning message
i18n_warn "network_failed"
# Output (EN): [WARNING] 2024-12-30 10:00:00 - Network connectivity failed
# Output (ZH): [警告] 2024-12-30 10:00:00 - 网络连接失败

# Error message
i18n_error "file_not_found" "/path/to/file"
# Output (EN): [ERROR] 2024-12-30 10:00:00 - File not found /path/to/file
# Output (ZH): [错误] 2024-12-30 10:00:00 - 文件未找到 /path/to/file
```

### 3. Get Message by Key

```bash
# Get localized message
message=$(msg "backup_config")
echo "$message"
# Output (EN): Configuration Backup
# Output (ZH): 配置备份

# Use in titles
print_title "$(msg 'system_detection')"
# Output (EN): === System Detection ===
# Output (ZH): === 系统检测 ===
```

### 4. User Interaction

```bash
# Ask yes/no question
if ask_yes_no "$(msg 'confirm')"; then
    echo "$(msg 'yes')"
else
    echo "$(msg 'no')"
fi
```

## Available Message Keys

### Common Messages

| Key | English | Chinese |
|-----|---------|---------|
| `info` | [INFO] | [信息] |
| `success` | [SUCCESS] | [成功] |
| `warning` | [WARNING] | [警告] |
| `error` | [ERROR] | [错误] |
| `debug` | [DEBUG] | [调试] |

### System Detection

| Key | English | Chinese |
|-----|---------|---------|
| `detect_os` | Detecting operating system... | 检测操作系统... |
| `os_detected` | Detected OS | 检测到操作系统 |
| `detect_hardware` | Detecting hardware information... | 检测硬件信息... |
| `detect_network` | Detecting network information... | 检测网络信息... |
| `detect_services` | Detecting system services... | 检测系统服务... |

### Network Operations

| Key | English | Chinese |
|-----|---------|---------|
| `check_network` | Checking network connectivity... | 检查网络连接... |
| `network_ok` | Network connectivity OK | 网络连接正常 |
| `network_failed` | Network connectivity failed | 网络连接失败 |
| `download_file` | Downloading file | 下载文件 |
| `download_success` | Download successful | 下载成功 |
| `download_failed` | Download failed | 下载失败 |

### File Operations

| Key | English | Chinese |
|-----|---------|---------|
| `backup_file` | Backing up file | 备份文件 |
| `create_dir` | Creating directory | 创建目录 |
| `delete_file` | Deleting file | 删除文件 |
| `file_exists` | File already exists | 文件已存在 |
| `file_not_found` | File not found | 文件未找到 |

### Cleanup Operations

| Key | English | Chinese |
|-----|---------|---------|
| `cleanup_env` | Cleaning up environment variables... | 清理环境变量... |
| `cleanup_temp` | Cleaning up temporary files... | 清理临时文件... |
| `cleanup_history` | Cleaning up bash history... | 清理 bash 历史... |
| `cleanup_scripts` | Cleaning up downloaded scripts... | 清理下载的脚本... |
| `cleanup_complete` | Cleanup complete | 清理完成 |

### Pre-Reinstall Operations

| Key | English | Chinese |
|-----|---------|---------|
| `system_detection` | System Detection | 系统检测 |
| `generating_report` | Generating system information report... | 生成系统信息报告... |
| `report_saved` | Report saved to | 报告已保存到 |
| `backup_config` | Configuration Backup | 配置备份 |
| `backing_up` | Backing up configuration... | 备份配置... |
| `backup_complete` | Backup complete | 备份完成 |
| `network_planning` | Network Planning | 网络规划 |
| `planning_network` | Planning network configuration... | 规划网络配置... |
| `plan_complete` | Network plan complete | 网络规划完成 |
| `prepare_reinstall` | Prepare Reinstall | 准备重装 |
| `generating_script` | Generating reinstall script... | 生成重装脚本... |
| `script_generated` | Reinstall script generated | 重装脚本已生成 |

### Post-Reinstall Operations

| Key | English | Chinese |
|-----|---------|---------|
| `setup_ip` | IP Address Setup | IP 地址配置 |
| `configuring_ip` | Configuring IP address... | 配置 IP 地址... |
| `ip_configured` | IP address configured | IP 地址已配置 |
| `setup_hostname` | Hostname Setup | 主机名配置 |
| `configuring_hostname` | Configuring hostname... | 配置主机名... |
| `hostname_configured` | Hostname configured | 主机名已配置 |
| `setup_dns` | DNS Setup | DNS 配置 |
| `configuring_dns` | Configuring DNS... | 配置 DNS... |
| `dns_configured` | DNS configured | DNS 已配置 |

### User Interaction

| Key | English | Chinese |
|-----|---------|---------|
| `press_key` | Press any key to continue... | 按任意键继续... |
| `confirm` | Are you sure? | 确定吗？ |
| `yes` | Yes | 是 |
| `no` | No | 否 |
| `continue` | Continue | 继续 |
| `cancel` | Cancel | 取消 |
| `exit` | Exit | 退出 |

### Status Messages

| Key | English | Chinese |
|-----|---------|---------|
| `starting` | Starting | 开始 |
| `running` | Running | 运行中 |
| `completed` | Completed | 已完成 |
| `failed` | Failed | 失败 |
| `skipped` | Skipped | 已跳过 |

## Adding New Messages

To add new messages, edit `utils/i18n.sh`:

```bash
# Add to MSG_EN array
declare -A MSG_EN=(
    # ... existing messages ...
    ["new_key"]="New English Message"
)

# Add to MSG_ZH array
declare -A MSG_ZH=(
    # ... existing messages ...
    ["new_key"]="新的中文消息"
)
```

## Example Script with i18n

```bash
#!/usr/bin/env bash
# example-script.sh - Example script with i18n support

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load common functions and i18n
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

# Main function
main() {
    # Display title
    print_title "$(msg 'system_detection')"
    
    # Log messages
    i18n_info "starting" "System detection"
    i18n_info "detect_os"
    
    # Perform operations
    local os_id
    os_id=$(get_system_info "os")
    
    # Success message
    i18n_success "os_detected" "$os_id"
    
    # Completion
    i18n_success "completed" "System detection"
}

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## Testing i18n

### Test English Output

```bash
export TOOLKIT_LANG=en
./pre-reinstall/detect-system.sh
```

### Test Chinese Output

```bash
export TOOLKIT_LANG=zh
./pre-reinstall/detect-system.sh
```

### Test Auto Detection

```bash
# Unset language variable to test auto detection
unset TOOLKIT_LANG
./pre-reinstall/detect-system.sh
```

## Best Practices

1. **Always use message keys**: Never hardcode messages in scripts
2. **Keep keys descriptive**: Use clear, descriptive key names
3. **Maintain consistency**: Use the same key for the same message across scripts
4. **Test both languages**: Always test scripts in both English and Chinese
5. **Document new keys**: Add new keys to this documentation

## Benefits

- **User-Friendly**: Users see messages in their preferred language
- **Maintainable**: Centralized message management
- **Consistent**: Same message format across all scripts
- **Extensible**: Easy to add new languages
- **Professional**: Provides a polished user experience

## Future Enhancements

- Add more languages (Japanese, Korean, etc.)
- Support for date/time localization
- Number formatting localization
- Pluralization support
- Context-aware translations

---

**Last Updated**: 2024-12-30  
**Version**: 1.0.0
