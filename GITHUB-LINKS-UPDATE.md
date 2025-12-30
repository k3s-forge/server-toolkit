# GitHub 链接更新记录

## 更新日期
**日期**: 2024-12-30  
**版本**: 1.0.0

## 更新内容

所有文档和脚本中的 GitHub 仓库链接已更新为：
**https://github.com/k3s-forge/server-toolkit**

## 更新的文件列表

### 核心脚本
1. ✅ `bootstrap.sh` - 主入口脚本
   - `REPO_OWNER` 默认值: `k3s-forge`

2. ✅ `utils/download.sh` - 下载管理器
   - `REPO_OWNER` 默认值: `k3s-forge`
   - 帮助信息中的示例

### 文档文件
3. ✅ `README.md` - 英文主文档
   - 快速开始命令
   - 手动安装命令
   - GitHub Issues 链接
   - GitHub Discussions 链接

4. ✅ `README.zh.md` - 中文主文档
   - 快速开始命令
   - 手动安装命令
   - GitHub Issues 链接
   - GitHub Discussions 链接

5. ✅ `docs/README.md` - 文档索引
   - GitHub Repository 链接
   - Issue Tracker 链接
   - Discussions 链接

6. ✅ `CURRENT-STATUS.md` - 当前状态
   - 配置示例中的 `REPO_OWNER`

7. ✅ `COMPLETION-SUMMARY.md` - 完成总结
   - 快速开始命令

8. ✅ `pre-reinstall/prepare-reinstall.sh` - 重装准备脚本
   - 生成的重装指南中的下载命令
   - 支持链接

## 更新的链接类型

### 1. 原始文件下载链接
```bash
# 旧链接
https://raw.githubusercontent.com/YOUR_ORG/server-toolkit/main/bootstrap.sh

# 新链接
https://raw.githubusercontent.com/k3s-forge/server-toolkit/main/bootstrap.sh
```

### 2. GitHub 仓库链接
```
# 旧链接
https://github.com/YOUR_ORG/server-toolkit

# 新链接
https://github.com/k3s-forge/server-toolkit
```

### 3. Issues 链接
```
# 旧链接
https://github.com/YOUR_ORG/server-toolkit/issues

# 新链接
https://github.com/k3s-forge/server-toolkit/issues
```

### 4. Discussions 链接
```
# 旧链接
https://github.com/YOUR_ORG/server-toolkit/discussions

# 新链接
https://github.com/k3s-forge/server-toolkit/discussions
```

### 5. 环境变量默认值
```bash
# 旧值
REPO_OWNER="${REPO_OWNER:-YOUR_ORG}"

# 新值
REPO_OWNER="${REPO_OWNER:-k3s-forge}"
```

## 验证结果

### ✅ 所有 YOUR_ORG 已替换
- 搜索结果: 0 个匹配项
- 状态: ✅ 完成

### ✅ k3s-forge 链接已生效
- 更新的文件: 8 个
- 更新的链接: 15+ 处
- 状态: ✅ 完成

## 使用方法

### 快速开始（一键安装）
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
./bootstrap.sh
```

### 自定义仓库（可选）
如果你 fork 了项目，可以通过环境变量指定自己的仓库：

```bash
export REPO_OWNER="your-username"
export REPO_NAME="server-toolkit"
export REPO_BRANCH="main"

./bootstrap.sh
```

## 相关链接

- **GitHub 仓库**: https://github.com/k3s-forge/server-toolkit
- **问题反馈**: https://github.com/k3s-forge/server-toolkit/issues
- **讨论区**: https://github.com/k3s-forge/server-toolkit/discussions
- **文档**: https://github.com/k3s-forge/server-toolkit/tree/main/docs

## 注意事项

1. **环境变量优先级**
   - 脚本会优先使用环境变量中设置的 `REPO_OWNER`
   - 如果未设置，则使用默认值 `k3s-forge`

2. **分支选择**
   - 默认使用 `main` 分支
   - 可通过 `REPO_BRANCH` 环境变量指定其他分支

3. **网络要求**
   - 需要能够访问 GitHub
   - 需要能够访问 raw.githubusercontent.com

## 更新历史

- **2024-12-30**: 初始更新，将所有链接从 `YOUR_ORG` 更新为 `k3s-forge`

---

**更新完成日期**: 2024-12-30  
**项目版本**: 1.0.0  
**状态**: ✅ 所有链接已更新
