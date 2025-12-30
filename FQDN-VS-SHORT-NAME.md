# FQDN vs 短名：使用场景分析

## 快速答案

**推荐：使用短名** ✅

对于 Kubernetes/K3s 环境，**短名是更好的选择**，原因如下：

1. ✅ 完全符合 K8s 标准
2. ✅ 更简洁易读
3. ✅ 避免兼容性问题
4. ✅ 更好的工具支持

## 详细对比

### 格式示例

```bash
FQDN:  jp.13.dual.k3s.a1b2c3d4
短名:  jp-13-dual-k3s-a1b2c3d4
```

### 场景分析

| 场景 | FQDN | 短名 | 推荐 | 原因 |
|------|------|------|------|------|
| **系统 hostname** | ❌ | ✅ | 短名 | 避免点号混淆 |
| **K8s 节点名** | ❌ | ✅ | 短名 | RFC 1123 要求 |
| **DNS 记录** | ✅ | ✅ | 都可以 | 两者都有效 |
| **SSH 连接** | ✅ | ✅ | 短名 | 更简洁 |
| **日志标识** | ❌ | ✅ | 短名 | 避免解析混淆 |
| **监控系统** | ❌ | ✅ | 短名 | 统一标识符 |
| **配置文件** | ❌ | ✅ | 短名 | 避免转义问题 |

## 为什么推荐短名？

### 1. Kubernetes 兼容性 ✅

**问题**：FQDN 包含点号，可能被误解为域名

```bash
# FQDN 作为节点名
kubectl get node jp.13.dual.k3s.a1b2c3d4
# 可能被解析为：
# - 主机名: jp
# - 域名: 13.dual.k3s.a1b2c3d4

# 短名作为节点名
kubectl get node jp-13-dual-k3s-a1b2c3d4
# 清晰明确，无歧义 ✅
```

**Kubernetes 官方建议**：
> Node names should be simple DNS labels without dots

### 2. 工具兼容性 ✅

很多工具对点号有特殊处理：

```bash
# Prometheus 标签
node_cpu_usage{node="jp.13.dual.k3s.a1b2c3d4"}
# 点号可能需要转义

node_cpu_usage{node="jp-13-dual-k3s-a1b2c3d4"}
# 无需转义 ✅

# Grafana 查询
sum by (node) (node_cpu_usage{node=~"jp.*"})
# 正则表达式可能匹配错误

sum by (node) (node_cpu_usage{node=~"jp-.*"})
# 清晰准确 ✅
```

### 3. 可读性 ✅

```bash
# 命令行使用
ssh jp-13-dual-k3s-a1b2c3d4
# vs
ssh jp.13.dual.k3s.a1b2c3d4

# 日志查看
grep "jp-13-dual-k3s-a1b2c3d4" /var/log/syslog
# vs
grep "jp.13.dual.k3s.a1b2c3d4" /var/log/syslog
# 点号可能匹配任意字符（正则）

# 配置文件
hosts:
  - jp-13-dual-k3s-a1b2c3d4  # 清晰 ✅
  - jp.13.dual.k3s.a1b2c3d4  # 可能被误解为 FQDN
```

### 4. 避免 DNS 混淆 ✅

```bash
# FQDN 可能被误解
ping jp.13.dual.k3s.a1b2c3d4
# DNS 可能尝试解析：
# - jp.13.dual.k3s.a1b2c3d4.local
# - jp.13.dual.k3s.a1b2c3d4.cluster.local
# - jp.13.dual.k3s.a1b2c3d4.example.com

# 短名清晰明确
ping jp-13-dual-k3s-a1b2c3d4
# 只会查找这个主机名 ✅
```

## FQDN 的使用场景

### 仅在以下情况使用 FQDN：

#### 1. 外部 DNS 记录

```bash
# 公网 DNS 记录
jp.13.dual.k3s.a1b2c3d4.example.com  A  203.0.113.10

# 内部 DNS 记录
jp.13.dual.k3s.a1b2c3d4.k3s.local   A  10.0.1.10
```

#### 2. 证书 SAN（Subject Alternative Name）

```bash
# TLS 证书
Subject Alternative Names:
  DNS: jp.13.dual.k3s.a1b2c3d4.example.com
  DNS: jp-13-dual-k3s-a1b2c3d4
  DNS: jp-13-dual-k3s-a1b2c3d4.k3s.local
```

#### 3. 文档和记录

```bash
# 服务器清单
Server: jp.13.dual.k3s.a1b2c3d4
Location: Tokyo, Japan
Network: Dual Stack
Purpose: K3s Node
```

## 实际使用建议

### 推荐配置

```bash
# 1. 生成主机名
bash fqdn-reinstall.sh --task generate_hostname

# 2. 读取短名（主要使用）
SHORT_NAME=$(cat generated_hostname_short.txt)
# jp-13-dual-k3s-a1b2c3d4

# 3. 读取 FQDN（备用）
FQDN=$(cat generated_hostname.txt)
# jp.13.dual.k3s.a1b2c3d4

# 4. 设置系统主机名（使用短名）
hostnamectl set-hostname "$SHORT_NAME"

# 5. 配置 /etc/hosts（两者都加）
cat >> /etc/hosts << EOF
127.0.1.1 $SHORT_NAME $FQDN
EOF

# 6. 部署 K3s（使用短名）
curl -sfL https://get.k3s.io | sh -s - --node-name "$SHORT_NAME"

# 7. 配置 DNS（使用 FQDN）
# 在 DNS 服务器添加：
# jp.13.dual.k3s.a1b2c3d4.k3s.local  A  10.0.1.10
```

### /etc/hosts 配置示例

```bash
# 推荐配置（两者都有）
127.0.0.1   localhost
127.0.1.1   jp-13-dual-k3s-a1b2c3d4 jp.13.dual.k3s.a1b2c3d4

# 这样两种方式都能工作：
ping jp-13-dual-k3s-a1b2c3d4  # ✅
ping jp.13.dual.k3s.a1b2c3d4  # ✅
```

## 常见问题

### Q1: hostname 命令返回什么？

```bash
# 设置短名
hostnamectl set-hostname jp-13-dual-k3s-a1b2c3d4

# 查询
hostname
# 输出: jp-13-dual-k3s-a1b2c3d4

hostname -f  # FQDN
# 输出: jp-13-dual-k3s-a1b2c3d4
# 或: jp-13-dual-k3s-a1b2c3d4.k3s.local（如果配置了域名）
```

### Q2: K3s 会使用什么作为节点名？

```bash
# 默认使用系统 hostname
kubectl get nodes
# NAME                        STATUS
# jp-13-dual-k3s-a1b2c3d4    Ready

# 可以显式指定
curl -sfL https://get.k3s.io | sh -s - --node-name jp-13-dual-k3s-a1b2c3d4
```

### Q3: DNS 如何配置？

```bash
# 方式 1: 使用短名（推荐）
jp-13-dual-k3s-a1b2c3d4.k3s.local  A  10.0.1.10

# 方式 2: 使用 FQDN
jp.13.dual.k3s.a1b2c3d4.k3s.local  A  10.0.1.10

# 方式 3: 两者都配置（最佳）
jp-13-dual-k3s-a1b2c3d4.k3s.local  A  10.0.1.10
jp.13.dual.k3s.a1b2c3d4.k3s.local  CNAME  jp-13-dual-k3s-a1b2c3d4.k3s.local
```

### Q4: 已经用了 FQDN，如何迁移？

```bash
# 1. 生成新的短名
SHORT_NAME=$(echo "$FQDN" | tr '.' '-')

# 2. 更新系统主机名
hostnamectl set-hostname "$SHORT_NAME"

# 3. 更新 K3s 节点名（需要重新加入集群）
# 在 master 节点删除旧节点
kubectl delete node "$FQDN"

# 在 worker 节点重新安装
curl -sfL https://get.k3s.io | sh -s - --node-name "$SHORT_NAME"

# 4. 更新所有配置文件中的引用
grep -r "$FQDN" /etc/ | # 查找所有引用
sed -i "s/$FQDN/$SHORT_NAME/g" /path/to/config
```

## 性能对比

### DNS 查询

```bash
# 短名（1 次查询）
dig jp-13-dual-k3s-a1b2c3d4
# 直接返回结果 ✅

# FQDN（可能多次查询）
dig jp.13.dual.k3s.a1b2c3d4
# 1. 查询 jp.13.dual.k3s.a1b2c3d4
# 2. 查询 jp.13.dual.k3s.a1b2c3d4.local
# 3. 查询 jp.13.dual.k3s.a1b2c3d4.cluster.local
# 可能需要多次查询
```

### 字符串匹配

```bash
# 短名（精确匹配）
grep "jp-13-dual-k3s-a1b2c3d4" logfile
# 只匹配完整字符串 ✅

# FQDN（正则匹配）
grep "jp.13.dual.k3s.a1b2c3d4" logfile
# 点号匹配任意字符，可能误匹配
# 需要转义: grep "jp\.13\.dual\.k3s\.a1b2c3d4"
```

## 最佳实践总结

### ✅ 推荐做法

1. **系统 hostname**：使用短名
   ```bash
   hostnamectl set-hostname jp-13-dual-k3s-a1b2c3d4
   ```

2. **K8s 节点名**：使用短名
   ```bash
   curl -sfL https://get.k3s.io | sh -s - --node-name jp-13-dual-k3s-a1b2c3d4
   ```

3. **/etc/hosts**：两者都配置
   ```bash
   127.0.1.1 jp-13-dual-k3s-a1b2c3d4 jp.13.dual.k3s.a1b2c3d4
   ```

4. **DNS 记录**：使用 FQDN 格式
   ```bash
   jp.13.dual.k3s.a1b2c3d4.k3s.local  A  10.0.1.10
   ```

5. **配置文件**：使用短名
   ```yaml
   nodes:
     - name: jp-13-dual-k3s-a1b2c3d4
       ip: 10.0.1.10
   ```

### ❌ 避免做法

1. ❌ 系统 hostname 使用 FQDN
2. ❌ K8s 节点名使用 FQDN
3. ❌ 混用两种格式（在同一配置中）
4. ❌ 在正则表达式中不转义 FQDN 的点号

## 结论

### 明确答案：使用短名 ✅

**理由**：
1. ✅ 完全符合 Kubernetes/K3s 标准
2. ✅ 避免工具兼容性问题
3. ✅ 更简洁、更清晰
4. ✅ 更好的性能（DNS 查询）
5. ✅ 避免正则表达式陷阱
6. ✅ 统一的标识符

**FQDN 仅用于**：
- 外部 DNS 记录
- TLS 证书 SAN
- 文档和清单

**实施建议**：
```bash
# 主要使用短名
SHORT_NAME="jp-13-dual-k3s-a1b2c3d4"

# FQDN 作为别名或备用
FQDN="jp.13.dual.k3s.a1b2c3d4"

# 在 /etc/hosts 中两者都配置
echo "127.0.1.1 $SHORT_NAME $FQDN" >> /etc/hosts
```

这样既保持了兼容性，又获得了短名的所有优势！

---

**推荐**: 短名 ✅  
**原因**: 兼容性、简洁性、标准性  
**例外**: DNS 记录可以使用 FQDN  
**最佳实践**: 短名为主，FQDN 为辅
