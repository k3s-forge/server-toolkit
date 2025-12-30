# Bug Fix: config-codec.sh 函数未加载

## 问题描述

**错误信息**:
```
/tmp/server-toolkit-590965/workflows/export-config.sh: line 43: create_config: command not found
```

**原因**: 
- `workflows/export-config.sh` 和 `workflows/import-config.sh` 依赖 `utils/config-codec.sh` 中的函数
- 当从 `bootstrap.sh` 调用时，使用 `common-header.sh` 加载依赖
- 但 `common-header.sh` 没有加载 `config-codec.sh`

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

## 修复后的文件

- ✅ `utils/common-header.sh` - 添加 config-codec.sh 加载和路径处理

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
```

## 根本原因

工作流脚本（workflows/）是新增的目录结构，之前的 `common-header.sh` 没有处理这个路径。同时 `config-codec.sh` 是配置管理的核心工具，应该在 common-header 中统一加载。

## 预防措施

1. 所有新增的核心工具库都应该在 `common-header.sh` 中加载
2. 新增目录结构时要更新 `common-header.sh` 的路径处理
3. 添加单元测试验证所有工作流的依赖加载

---

**修复日期**: 2024-12-30  
**版本**: 2.0.2  
**状态**: 已修复 ✅
