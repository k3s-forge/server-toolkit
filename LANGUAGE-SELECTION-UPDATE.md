# 语言选择和依赖修复更新

## 更新日期
**日期**: 2024-12-30  
**版本**: 1.0.2

## 🎯 更新内容

### 1. 交互式语言选择 ✅

现在启动时会显示语言选择菜单：

```
════════════════════════════════════════════════════════════
  Language Selection / 语言选择
════════════════════════════════════════════════════════════

  [1] English
  [2] 中文

Select language / 选择语言 [1-2]: _
```

**特点**：
- ✅ 启动时交互式选择语言
- ✅ 支持中文和英文
- ✅ 如果不选择，自动检测系统语言
- ✅ 选择后整个会话都使用该语言

### 2. 依赖脚本自动下载 ✅

修复了 "common.sh not found" 错误：

**问题**：
- 子脚本需要 `common.sh` 和 `i18n.sh`
- 但这些文件没有被提前下载
- 导致执行失败

**解决方案**：
- 在主菜单显示前自动下载工具脚本
- 下载 `common.sh`、`i18n.sh`、`common-header.sh`
- 工具脚本在整个会话期间保留
- 其他脚本执行后自动删除

### 3. 脚本加载机制改进 ✅

创建了 `utils/common-header.sh` 统一处理脚本加载：

```bash
# Load common header (handles both standalone and bootstrap execution)
if [[ -n "${SCRIPT_DIR:-}" ]] && [[ -f "$SCRIPT_DIR/utils/common-header.sh" ]]; then
    source "$SCRIPT_DIR/utils/common-header.sh"
else
    # Fallback for standalone execution
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TOOLKIT_ROOT="$(dirname "$CURRENT_DIR")"
    
    if [[ -f "$TOOLKIT_ROOT/utils/common.sh" ]]; then
        source "$TOOLKIT_ROOT/utils/common.sh"
    else
        echo "Error: common.sh not found"
        exit 1
    fi
    
    if [[ -f "$TOOLKIT_ROOT/utils/i18n.sh" ]]; then
        source "$TOOLKIT_ROOT/utils/i18n.sh"
    fi
fi
```

**优点**：
- ✅ 支持从 bootstrap.sh 执行
- ✅ 支持独立执行
- ✅ 自动检测脚本位置
- ✅ 统一的错误处理

## 📋 完整的启动流程

### 新的启动流程

```
1. 下载 bootstrap.sh
   ↓
2. 显示 Banner
   ↓
3. 检查系统要求
   ↓
4. 创建临时目录
   ↓
5. 语言选择菜单 ← 新增！
   ↓
6. 下载工具脚本 ← 新增！
   - common.sh
   - i18n.sh
   - common-header.sh
   ↓
7. 显示主菜单
   ↓
8. 用户选择操作
   ↓
9. 下载并执行对应脚本
   ↓
10. 清理（保留工具脚本）
```

### 旧的启动流程（有问题）

```
1. 下载 bootstrap.sh
   ↓
2. 显示 Banner
   ↓
3. 检查系统要求
   ↓
4. 创建临时目录
   ↓
5. 显示主菜单
   ↓
6. 用户选择操作
   ↓
7. 下载并执行脚本
   ↓
8. ❌ 错误：common.sh not found
```

## 🚀 使用示例

### 示例 1：一键安装（自动语言选择）

```bash
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash
```

**流程**：
```
╔════════════════════════════════════════════════════════════╗
║              Server Toolkit v1.0.2                         ║
╚════════════════════════════════════════════════════════════╝

[INFO] Checking system requirements...
[SUCCESS] System requirements check passed

════════════════════════════════════════════════════════════
  Language Selection / 语言选择
════════════════════════════════════════════════════════════

  [1] English
  [2] 中文

Select language / 选择语言 [1-2]: 2

[信息] 下载工具脚本...
[成功] 工具脚本准备就绪

════════════════════════════════════════════════════════════
  服务器工具包 - 主菜单
════════════════════════════════════════════════════════════

🔧 重装前工具
  [1] 检测系统信息
  ...
```

### 示例 2：强制使用中文（跳过语言选择）

```bash
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | TOOLKIT_LANG=zh bash
```

**注意**：如果设置了 `TOOLKIT_LANG` 环境变量，会跳过语言选择菜单。

### 示例 3：强制使用英文

```bash
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | TOOLKIT_LANG=en bash
```

## 🔧 技术细节

### 语言选择函数

```bash
select_language() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Language Selection / 语言选择${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  [1] English"
    echo "  [2] 中文"
    echo ""
    read -p "Select language / 选择语言 [1-2]: " lang_choice
    
    case $lang_choice in
        1)
            TOOLKIT_LANG="en"
            ;;
        2)
            TOOLKIT_LANG="zh"
            ;;
        *)
            # Default to auto-detect
            TOOLKIT_LANG=$(detect_language)
            ;;
    esac
    
    export TOOLKIT_LANG
}
```

### 工具脚本下载函数

```bash
download_utils() {
    log_info "$(msg 'downloading_utils')"
    
    # Download common.sh
    if ! download_script "utils/common.sh"; then
        log_error "$(msg 'failed_download_utils')"
        return 1
    fi
    
    # Download i18n.sh
    if ! download_script "utils/i18n.sh"; then
        log_error "$(msg 'failed_download_utils')"
        return 1
    fi
    
    # Download common-header.sh
    if ! download_script "utils/common-header.sh"; then
        log_error "$(msg 'failed_download_utils')"
        return 1
    fi
    
    log_success "$(msg 'utils_ready')"
    return 0
}
```

### 环境变量导出

```bash
# Export environment variables for child scripts
export TOOLKIT_LANG
export SCRIPT_DIR
export BASE_URL
export REPO_OWNER
export REPO_NAME
export REPO_BRANCH
```

### 清理策略

```bash
# Cleanup after execution (but keep utils)
if [[ "$script_path" != utils/* ]]; then
    rm -f "$local_path"
fi
```

**说明**：
- 工具脚本（utils/*）在整个会话期间保留
- 其他脚本执行后立即删除
- 退出时清理所有临时文件

## 📊 文件变更

### 新增文件
- ✅ `utils/common-header.sh` - 统一的脚本加载头部

### 修改文件
- ✅ `bootstrap.sh` - 添加语言选择和工具下载
- ✅ `pre-reinstall/detect-system.sh` - 使用新的加载机制

### 待更新文件（可选）
其他子脚本也可以更新使用 `common-header.sh`，但当前的实现已经可以工作了。

## ✅ 测试清单

### 功能测试
- ✅ 语言选择菜单显示
- ✅ 选择英文后界面为英文
- ✅ 选择中文后界面为中文
- ✅ 不选择时自动检测语言
- ✅ 工具脚本自动下载
- ✅ 子脚本能找到 common.sh
- ✅ 子脚本能找到 i18n.sh
- ✅ 脚本执行成功
- ✅ 清理机制正常

### 执行方式测试
- ✅ curl | bash
- ✅ curl | TOOLKIT_LANG=zh bash
- ✅ curl | TOOLKIT_LANG=en bash
- ✅ 直接执行
- ✅ sudo 执行

## 🐛 已修复的问题

### 问题 1：common.sh not found
**症状**：
```
[信息] 执行中: pre-reinstall/detect-system.sh
Error: common.sh not found
```

**原因**：
- 子脚本需要 common.sh
- 但 common.sh 没有被下载

**修复**：
- 在主菜单前下载所有工具脚本
- 工具脚本在会话期间保留

### 问题 2：语言不能交互选择
**症状**：
- 只能通过环境变量设置语言
- 不够用户友好

**修复**：
- 添加交互式语言选择菜单
- 启动时第一步就选择语言

### 问题 3：环境变量没有传递
**症状**：
- 子脚本无法访问 SCRIPT_DIR
- 子脚本无法访问 TOOLKIT_LANG

**修复**：
- 使用 `sudo -E` 保留环境变量
- 显式导出所有需要的变量

## 📚 相关文档

- [I18N-UPDATE.md](I18N-UPDATE.md) - 国际化更新说明
- [PIPE-FIX.md](PIPE-FIX.md) - 管道执行修复说明
- [FINAL-UPDATE-SUMMARY.md](FINAL-UPDATE-SUMMARY.md) - 最终更新总结

## 🎉 总结

**v1.0.2 更新完成！**

### 主要改进
1. ✅ **交互式语言选择** - 用户友好的语言选择菜单
2. ✅ **自动依赖下载** - 修复 common.sh not found 错误
3. ✅ **统一加载机制** - common-header.sh 简化脚本开发

### 用户体验提升
- 启动时可以选择语言
- 不再出现 "common.sh not found" 错误
- 所有功能正常工作
- 完全支持 curl | bash 一键安装

---

**更新完成日期**: 2024-12-30  
**项目版本**: 1.0.2  
**状态**: ✅ 所有问题已修复

