# 管道执行修复说明

## 问题描述

当使用 `curl | bash` 方式运行脚本时，会遇到以下问题：

```bash
curl -fsSL https://example.com/script.sh | bash
```

**问题**：
- 标准输入 (stdin) 被管道占用
- `read` 命令无法从用户获取输入
- 交互式菜单无法正常工作
- 脚本会直接退出或跳过输入提示

## 解决方案

### 技术实现

在 `bootstrap.sh` 的 `main()` 函数中添加了以下代码：

```bash
main() {
    # If stdin is not a terminal (piped from curl), redirect to /dev/tty
    if [[ ! -t 0 ]] && [[ -e /dev/tty ]]; then
        exec < /dev/tty
    fi
    
    # ... rest of the code
}
```

### 工作原理

1. **检测管道输入**：`[[ ! -t 0 ]]` 检查标准输入是否为终端
   - 如果是管道输入（如 `curl | bash`），返回 true
   - 如果是正常终端输入，返回 false

2. **检查 /dev/tty**：`[[ -e /dev/tty ]]` 确保 `/dev/tty` 设备存在
   - `/dev/tty` 是当前终端的设备文件
   - 即使 stdin 被重定向，它仍然可用

3. **重定向标准输入**：`exec < /dev/tty` 将标准输入重定向到终端
   - 这样 `read` 命令就能从用户获取输入了
   - 所有后续的输入操作都会正常工作

## 使用效果

### 修复前

```bash
$ curl -fsSL https://example.com/bootstrap.sh | bash
╔════════════════════════════════════════════════════════════╗
║              Server Toolkit v1.0.0                         ║
╚════════════════════════════════════════════════════════════╝
[INFO] Checking system requirements...
[SUCCESS] System requirements check passed

════════════════════════════════════════════════════════════
  Server Toolkit - Main Menu
════════════════════════════════════════════════════════════
[1] Detect System Information
[2] Backup Current Configuration
...
[0] Exit

Select [0-10]: 
# 脚本直接退出，无法输入
```

### 修复后

```bash
$ curl -fsSL https://example.com/bootstrap.sh | bash
╔════════════════════════════════════════════════════════════╗
║              服务器工具包 v1.0.0                           ║
╚════════════════════════════════════════════════════════════╝
[信息] 检查系统要求...
[成功] 系统要求检查通过

════════════════════════════════════════════════════════════
  服务器工具包 - 主菜单
════════════════════════════════════════════════════════════
[1] 检测系统信息
[2] 备份当前配置
...
[0] 退出

选择 [0-10]: _
# 可以正常输入！
```

## 兼容性

### 支持的场景

✅ **管道执行**
```bash
curl -fsSL https://example.com/bootstrap.sh | bash
```

✅ **进程替换**
```bash
bash <(curl -fsSL https://example.com/bootstrap.sh)
```

✅ **直接执行**
```bash
./bootstrap.sh
```

✅ **Sudo 执行**
```bash
sudo bash bootstrap.sh
```

✅ **带参数执行**
```bash
curl -fsSL https://example.com/bootstrap.sh | bash -s -- --arg1 --arg2
```

### 系统要求

- ✅ Linux（所有主流发行版）
- ✅ macOS
- ✅ BSD 系统
- ✅ WSL (Windows Subsystem for Linux)
- ⚠️ 某些容器环境可能没有 `/dev/tty`（会回退到非交互模式）

## 技术细节

### /dev/tty 是什么？

`/dev/tty` 是一个特殊的设备文件，它总是指向当前进程的控制终端：

- 即使 stdin/stdout/stderr 被重定向，`/dev/tty` 仍然指向原始终端
- 可以用来绕过重定向，直接与用户交互
- 在脚本中常用于需要用户输入的场景

### 为什么不用其他方法？

#### 方法 1：下载后执行（不符合需求）
```bash
curl -fsSL https://example.com/script.sh -o script.sh
bash script.sh
```
- ❌ 需要两步操作
- ❌ 留下临时文件
- ❌ 不符合"一键安装"的需求

#### 方法 2：使用 bash -s（部分有效）
```bash
curl -fsSL https://example.com/script.sh | bash -s
```
- ⚠️ 仍然无法解决 stdin 被占用的问题
- ⚠️ `read` 命令仍然无法工作

#### 方法 3：使用进程替换（语法复杂）
```bash
bash <(curl -fsSL https://example.com/script.sh)
```
- ✅ 可以工作
- ❌ 语法不够简洁
- ❌ 不是所有 shell 都支持

#### 方法 4：重定向到 /dev/tty（最佳）✅
```bash
exec < /dev/tty
```
- ✅ 简单有效
- ✅ 兼容性好
- ✅ 用户体验最佳
- ✅ 支持管道执行

## 错误处理

如果 `/dev/tty` 不可用（如某些容器环境），脚本会：

1. 跳过重定向
2. 继续执行非交互部分
3. 在需要输入时显示友好的错误消息

可以添加更完善的错误处理：

```bash
main() {
    # If stdin is not a terminal (piped from curl), redirect to /dev/tty
    if [[ ! -t 0 ]]; then
        if [[ -e /dev/tty ]]; then
            exec < /dev/tty
        else
            log_warn "Running in non-interactive mode (no /dev/tty)"
            log_info "Please download and run the script directly for interactive mode"
            # 可以提供非交互模式的选项
            exit 1
        fi
    fi
    
    # ... rest of the code
}
```

## 测试

### 测试管道执行
```bash
# 测试中文界面
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | bash

# 测试英文界面
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | TOOLKIT_LANG=en bash

# 测试强制中文
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh | TOOLKIT_LANG=zh bash
```

### 测试进程替换
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh)
```

### 测试直接执行
```bash
curl -fsSL https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh -o bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh
```

## 参考资料

- [Bash Manual - Redirections](https://www.gnu.org/software/bash/manual/html_node/Redirections.html)
- [Advanced Bash-Scripting Guide - /dev and /proc](https://tldp.org/LDP/abs/html/devref1.html)
- [Stack Overflow - Read from stdin in piped script](https://stackoverflow.com/questions/2746553/read-from-file-or-stdin-in-bash)

## 更新历史

- **2024-12-30**: 初始版本
  - 添加 `/dev/tty` 重定向
  - 支持管道执行
  - 保持交互式功能

---

**更新日期**: 2024-12-30  
**版本**: 1.0.1  
**状态**: ✅ 管道执行问题已修复

