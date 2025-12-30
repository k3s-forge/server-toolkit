# Bug Fix: config-codec.sh 函数未加载

## 问题描述

**错误信息**:
```
/tmp/server-toolkit-590965/workflows/export-config.sh: line 43: create_config: command not found
```

**原因**: 
1. `workflows/export-config.sh` 和 `workflows/import-config.sh` 依赖 `utils/config-codec.sh` 中的函数
2. 当从 `bootstrap.sh` 调用时，使用 `common-header.sh` 加载依赖
3. `common-header.sh` 没有加载 `config-codec.sh`
4. **关键问题**: `bootstrap.sh` 的 `download_and_run()` 只下载指定脚本，不会自动下载依赖

## 修复内容

### 1. 更新 common-header.sh

**添加 config-codec.sh 加载**:
```bash
# Load config-codec functions
if [[ -f "$TOOLKIT_ROOT/utils/config-codec.sh" ]]; then
    source "$TOOLKIT_ROOT/utils/config-codec.sh"
fi
```

**添加目录路径处理**:
```bash
*/workflows)
    TOOLKIT_ROOT="$(dirname "$CURRENT_SCRIPT_DIR")"
    ;;
*/components/*)
    TOOLKIT_ROOT="$(dirname "$(dirname "$CURRENT_SCRIPT_DIR")")"
    ;;
```

### 2. 更新 bootstrap.sh

**在调用工作流前下载依赖**:

```bash
import_config_code() {
    log_info "$(msg 'import_config')"
    # Download dependencies
    download_script "utils/config-codec.sh"
    download_and_run "workflows/import-config.sh" "interactive"
}

export_config_code() {
    log_info "$(msg 'export_config')"
    # Download dependencies
    download_script "utils/config-codec.sh"
    download_and_run "workflows/export-config.sh" "current"
}

quick_setup() {
    log_info "$(msg 'quick_setup')"
    # Download dependencies
    download_script "utils/config-codec.sh"
    download_script "components/hostname/generate.sh"
    download_script "components/hostname/apply.sh"
    download_script "components/network/detect.sh"
    download_and_run "workflows/quick-setup.sh"
}
```

## 修复后的文件

- ✅ `utils/common-header.sh` - 添加 config-codec.sh 加载和路径处理
- ✅ `bootstrap.sh` - 在调用工作流前下载依赖

## 影响的功能

修复后以下功能可以正常工作：

1. **配置导出** (`workflows/export-config.sh`)
   - `create_config()` - 创建配置对象
   - `add_hostname_to_config()` - 添加主机名
   - `add_network_to_config()` - 添加网络配置
   - `add_system_to_config()` - 添加系统配置
   - `encode_config()` - 编码为 Base64

2. **配置导入** (`workflows/import-config.sh`)
   - `decode_config()` - 解码 Base64 配置码
   - 应用配置到系统

3. **快速配置** (`workflows/quick-setup.sh`)
   - 完整的配置向导流程

## 测试验证

```bash
# 测试配置导出
bash bootstrap.sh
# 选择: [2] 导出配置码
# 预期: 成功生成配置码

# 测试配置导入
bash bootstrap.sh
# 选择: [1] 导入配置码
# 粘贴配置码
# 预期: 成功解码和应用

# 测试快速配置
bash bootstrap.sh
# 选择: [3] 快速配置
# 预期: 向导正常运行
```

## 根本原因

1. **架构问题**: 工作流脚本（workflows/）是新增的目录结构，`common-header.sh` 没有处理这个路径
2. **依赖管理问题**: `bootstrap.sh` 的 `download_and_run()` 函数设计为只下载单个脚本，不会自动解析和下载依赖
3. **加载顺序问题**: `config-codec.sh` 是配置管理的核心工具，应该在 common-header 中统一加载，但之前被遗漏了

## 解决方案

采用双重保障策略：

1. **静态加载**: 在 `common-header.sh` 中加载 `config-codec.sh`（适用于本地执行）
2. **显式下载**: 在 `bootstrap.sh` 中调用工作流前显式下载依赖（适用于远程下载执行）

这样无论是本地执行还是通过 bootstrap.sh 远程下载执行，都能正确加载依赖。

## 预防措施

1. 所有新增的核心工具库都应该在 `common-header.sh` 中加载
2. 新增目录结构时要更新 `common-header.sh` 的路径处理
3. 在 `bootstrap.sh` 中调用脚本前，显式下载所有依赖
4. 考虑实现自动依赖解析机制
5. 添加单元测试验证所有工作流的依赖加载

---

**修复日期**: 2024-12-30  
**版本**: 2.0.2  
**状态**: 已修复 ✅
