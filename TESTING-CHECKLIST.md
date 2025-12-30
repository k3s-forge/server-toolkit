# 主机名统一功能测试清单

## 测试环境要求

- Linux 系统（Ubuntu/Debian/CentOS/RHEL）
- Bash 4.0+
- curl 命令
- jq 命令（用于配置码测试）
- sudo 权限

## 测试清单

### ✅ 1. 主机名生成测试

**目标**: 验证主机名生成功能正常工作

```bash
# 测试 1.1: 基础生成
cd server-toolkit
bash components/hostname/generate.sh k3s 01

# 预期输出:
# - 显示地理位置检测过程
# - 显示网络类型检测过程
# - 输出短名格式: country-region-network-product-rand8
# - 创建临时文件: /tmp/generated_hostname_short.txt
# - 创建临时文件: /tmp/generated_hostname_fqdn.txt

# 验证:
[ ] 短名格式正确（连字符分隔）
[ ] FQDN 格式正确（点号分隔）
[ ] 国家代码为小写 2 字母
[ ] 随机后缀为 8 位十六进制
[ ] 总长度 <= 63 字符
```

```bash
# 测试 1.2: 检查临时文件
cat /tmp/generated_hostname_short.txt
cat /tmp/generated_hostname_fqdn.txt

# 验证:
[ ] 两个文件都存在
[ ] 短名文件包含连字符格式
[ ] FQDN 文件包含点号格式
```

```bash
# 测试 1.3: 多次生成（验证随机性）
bash components/hostname/generate.sh k3s 01
bash components/hostname/generate.sh k3s 02
bash components/hostname/generate.sh swarm 01

# 验证:
[ ] 每次生成的随机后缀不同
[ ] 产品名称正确反映在主机名中
```

### ✅ 2. 主机名应用测试

**目标**: 验证主机名应用功能正常工作

```bash
# 测试 2.1: 应用短名（无 FQDN）
sudo bash components/hostname/apply.sh apply test-hostname-01

# 预期输出:
# - 显示 "Applying hostname: test-hostname-01"
# - 显示 "✓ Hostname set using hostnamectl"
# - 显示 "✓ /etc/hosts updated"
# - 显示 "✓ Hostname applied successfully"

# 验证:
[ ] hostname 命令返回 test-hostname-01
[ ] /etc/hosts 包含 "127.0.1.1 test-hostname-01"
[ ] /etc/hosts.backup.* 备份文件已创建
```

```bash
# 测试 2.2: 应用短名 + FQDN
sudo bash components/hostname/apply.sh apply test-hostname-02 test.example.com

# 预期输出:
# - 显示 "Applying hostname: test-hostname-02"
# - 显示 "  FQDN alias: test.example.com"
# - 显示成功消息

# 验证:
[ ] hostname 命令返回 test-hostname-02
[ ] /etc/hosts 包含 "127.0.1.1 test-hostname-02 test.example.com"
[ ] hostname -f 可以解析 FQDN
```

```bash
# 测试 2.3: 应用 FQDN（自动转换为短名）
sudo bash components/hostname/apply.sh fqdn jp.13.dual.k3s.a1b2c3d4

# 预期输出:
# - 自动转换 FQDN 为短名
# - 应用短名作为主机名
# - FQDN 作为别名

# 验证:
[ ] hostname 命令返回 jp-13-dual-k3s-a1b2c3d4
[ ] /etc/hosts 包含两种格式
```

```bash
# 测试 2.4: 查看当前主机名
bash components/hostname/apply.sh show

# 预期输出:
# - 显示当前 hostname
# - 显示当前 FQDN
# - 显示 /etc/hosts 相关条目

# 验证:
[ ] 输出格式清晰
[ ] 信息准确
```

### ✅ 3. 主机名管理界面测试

**目标**: 验证交互式管理功能

```bash
# 测试 3.1: 生成并应用
bash components/hostname/manage.sh
# 选择: 1 (Generate and apply hostname immediately)
# 确认: Y (Apply this hostname now)

# 验证:
[ ] 显示生成的短名和 FQDN
[ ] 提示用户确认
[ ] 成功应用主机名
[ ] 显示当前配置
```

```bash
# 测试 3.2: 仅生成（不应用）
bash components/hostname/manage.sh
# 选择: 2 (Generate hostname for config code)

# 验证:
[ ] 显示生成的短名和 FQDN
[ ] 提供应用命令示例
[ ] 不修改系统主机名
```

```bash
# 测试 3.3: 应用自定义主机名
bash components/hostname/manage.sh
# 选择: 3 (Apply custom hostname)
# 输入短名: my-custom-host
# 输入 FQDN: my-custom-host.local

# 验证:
[ ] 接受自定义输入
[ ] 成功应用主机名
```

```bash
# 测试 3.4: 查看当前主机名
bash components/hostname/manage.sh
# 选择: 4 (View current hostname)

# 验证:
[ ] 显示当前配置
[ ] 信息准确
```

### ✅ 4. 配置导出测试

**目标**: 验证配置导出功能

```bash
# 测试 4.1: 导出当前配置
bash workflows/export-config.sh current

# 预期输出:
# - 显示检测到的主机名（短名和 FQDN）
# - 显示网络配置
# - 显示时区
# - 输出 Base64 编码的配置码
# - 保存到文件

# 验证:
[ ] 配置码包含短名和 FQDN
[ ] 配置码可以解码为 JSON
[ ] JSON 包含 hostname.short 字段
[ ] JSON 包含 hostname.fqdn 字段
[ ] 文件已保存到 ~/server-config-*.txt
```

```bash
# 测试 4.2: 验证配置码格式
CONFIG_FILE=$(ls -t ~/server-config-*.txt | head -1)
cat "$CONFIG_FILE" | base64 -d | jq .

# 预期输出:
# {
#   "version": "1.0",
#   "hostname": {
#     "short": "...",
#     "fqdn": "...",
#     "apply": false
#   },
#   ...
# }

# 验证:
[ ] JSON 格式正确
[ ] 包含所有必需字段
[ ] hostname 对象包含 short 和 fqdn
```

### ✅ 5. 配置导入测试

**目标**: 验证配置导入功能

```bash
# 测试 5.1: 交互式导入
bash workflows/import-config.sh interactive
# 粘贴配置码
# 按 Ctrl+D
# 确认: y

# 预期输出:
# - 解码配置成功
# - 显示配置摘要
# - 显示短名和 FQDN
# - 应用主机名

# 验证:
[ ] 配置码解码成功
[ ] 显示短名和 FQDN
[ ] 主机名应用成功
[ ] 使用短名作为系统主机名
```

```bash
# 测试 5.2: 从文件导入
CONFIG_FILE=$(ls -t ~/server-config-*.txt | head -1)
bash workflows/import-config.sh file "$CONFIG_FILE"
# 确认: y

# 验证:
[ ] 从文件读取配置码
[ ] 解码成功
[ ] 应用成功
```

```bash
# 测试 5.3: 命令行导入
CONFIG_CODE=$(cat ~/server-config-*.txt | head -1)
bash workflows/import-config.sh code "$CONFIG_CODE"

# 验证:
[ ] 直接从命令行参数读取
[ ] 解码成功
[ ] 应用成功
```

### ✅ 6. 快速配置测试

**目标**: 验证快速配置工作流

```bash
# 测试 6.1: 完整快速配置
bash workflows/quick-setup.sh
# 配置主机名: y
# 选择: 1 (Generate with geo-location)
# 应用: y
# 网络配置: y
# 时区: n

# 预期输出:
# - 显示当前主机名
# - 生成新主机名（短名和 FQDN）
# - 应用主机名
# - 检测网络配置
# - 显示完成摘要

# 验证:
[ ] 主机名生成成功
[ ] 显示短名和 FQDN
[ ] 主机名应用成功
[ ] 网络检测正常
```

```bash
# 测试 6.2: 自定义主机名
bash workflows/quick-setup.sh
# 配置主机名: y
# 选择: 2 (Enter custom hostname)
# 输入短名: custom-host
# 输入 FQDN: custom.local
# 应用: y

# 验证:
[ ] 接受自定义输入
[ ] 应用成功
```

### ✅ 7. K3s 集成测试

**目标**: 验证与 K3s 的集成

```bash
# 测试 7.1: 应用主机名后安装 K3s
# 先应用主机名
sudo bash components/hostname/apply.sh apply jp-13-dual-k3s-a1b2c3d4

# 安装 K3s
curl -sfL https://get.k3s.io | sh -s -

# 等待 K3s 启动
sleep 30

# 检查节点名
sudo kubectl get nodes

# 预期输出:
# NAME                        STATUS   ROLES                  AGE   VERSION
# jp-13-dual-k3s-a1b2c3d4    Ready    control-plane,master   30s   v1.28.x+k3s1

# 验证:
[ ] 节点名为短名格式
[ ] 节点状态为 Ready
[ ] 无错误或警告
```

```bash
# 测试 7.2: 验证节点标签
sudo kubectl get node jp-13-dual-k3s-a1b2c3d4 -o yaml | grep hostname

# 验证:
[ ] kubernetes.io/hostname 标签为短名
[ ] 无 DNS 相关错误
```

### ✅ 8. 边界情况测试

**目标**: 验证边界情况处理

```bash
# 测试 8.1: 长主机名（接近 63 字符限制）
bash components/hostname/generate.sh very-long-product-name-for-testing 01

# 验证:
[ ] 生成的主机名 <= 63 字符
[ ] 自动截断过长部分
[ ] 无尾部连字符
```

```bash
# 测试 8.2: 特殊字符处理
sudo bash components/hostname/apply.sh apply "test_host@123"

# 预期:
# - 应该拒绝或自动清理特殊字符

# 验证:
[ ] 错误处理正确
[ ] 或自动转换为合规格式
```

```bash
# 测试 8.3: 网络不可用时的行为
# 断开网络连接
bash components/hostname/generate.sh k3s 01

# 验证:
[ ] 使用默认值或缓存
[ ] 不会崩溃
[ ] 提供有意义的错误消息
```

### ✅ 9. 向后兼容性测试

**目标**: 验证与旧版本的兼容性

```bash
# 测试 9.1: 导入旧格式配置码（仅 FQDN）
# 创建旧格式配置
OLD_CONFIG='{"version":"1.0","hostname":{"fqdn":"old.example.com","apply":true}}'
OLD_CODE=$(echo "$OLD_CONFIG" | base64 -w0)

# 导入
echo "$OLD_CODE" | bash workflows/import-config.sh interactive

# 验证:
[ ] 能够解析旧格式
[ ] 自动转换 FQDN 为短名
[ ] 应用成功
```

### ✅ 10. 清理测试

**目标**: 验证自动清理功能

```bash
# 测试 10.1: 正常退出清理
bash bootstrap.sh
# 选择: 0 (Exit)

# 验证:
[ ] 自动执行清理
[ ] 临时文件被删除
[ ] 无错误消息
```

```bash
# 测试 10.2: Ctrl+C 清理
bash bootstrap.sh
# 按 Ctrl+C

# 验证:
[ ] 捕获中断信号
[ ] 执行清理
[ ] 优雅退出
```

## 测试结果记录

### 测试环境

- 操作系统: _______________
- Bash 版本: _______________
- 测试日期: _______________
- 测试人员: _______________

### 测试结果汇总

| 测试项 | 状态 | 备注 |
|--------|------|------|
| 1. 主机名生成 | ⬜ 通过 / ⬜ 失败 | |
| 2. 主机名应用 | ⬜ 通过 / ⬜ 失败 | |
| 3. 管理界面 | ⬜ 通过 / ⬜ 失败 | |
| 4. 配置导出 | ⬜ 通过 / ⬜ 失败 | |
| 5. 配置导入 | ⬜ 通过 / ⬜ 失败 | |
| 6. 快速配置 | ⬜ 通过 / ⬜ 失败 | |
| 7. K3s 集成 | ⬜ 通过 / ⬜ 失败 | |
| 8. 边界情况 | ⬜ 通过 / ⬜ 失败 | |
| 9. 向后兼容 | ⬜ 通过 / ⬜ 失败 | |
| 10. 自动清理 | ⬜ 通过 / ⬜ 失败 | |

### 发现的问题

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

### 改进建议

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

---

**测试完成日期**: _______________  
**总体评估**: ⬜ 通过 / ⬜ 需要修复 / ⬜ 需要重新测试
