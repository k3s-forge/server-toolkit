# Server Toolkit v2.0 - 最终决策

## 核心决策

### ✅ 使用短名作为主机名

**格式**：`country-region-network-type-product-rand8`  
**示例**：`jp-13-dual-k3s-a1b2c3d4`

## 实施方案

### 1. 主机名生成

采用 **swarm-setup 的 fqdn-reinstall.sh 设计**：

```bash
# 生成两种格式
FQDN:  jp.13.dual.k3s.a1b2c3d4        # 保存到 generated_hostname.txt
短名:  jp-13-dual-k3s-a1b2c3d4        # 保存到 generated_hostname_short.txt
```

### 2. 主机名应用

**默认使用短名**：

```bash
# 读取短名
SHORT_NAME=$(cat generated_hostname_short.txt)

# 设置系统主机名
hostnamectl set-hostname "$SHORT_NAME"

# 更新 /etc/hosts（两者都配置）
cat >> /etc/hosts << EOF
127.0.1.1 $SHORT_NAME $(cat generated_hostname.txt)
EOF
```

### 3. 配置码格式

```json
{
  "version": "1.0",
  "hostname": {
    "short": "jp-13-dual-k3s-a1b2c3d4",
    "fqdn": "jp.13.dual.k3s.a1b2c3d4",
    "apply": true
  }
}
```

## 修正清单

### ✅ 已完成

1. **自动安全清理**
   - 使用 trap 捕获所有退出信号
   - 自动执行清理，无需手动
   - 从菜单移除安全清理选项

### 🔄 待实施

2. **主机名生成统一**
   - 集成 swarm-setup 的 fqdn-reinstall.sh 逻辑
   - 默认使用短名作为主机名
   - FQDN 作为备用/别名

## 实施步骤

### 步骤 1: 集成主机名生成逻辑

将 `swarm-setup/fqdn-reinstall.sh` 的核心函数集成到 `components/hostname/generate.sh`：

**需要集成的函数**：
- `slugify_label()` - 合规化标签
- `rand8_hex()` - 生成随机 8 位
- `region_to_code()` - 区域短码映射
- `netprobe_json()` - 网络类型探测
- 地理信息并发获取逻辑

**生成格式**：
```bash
# 组件
country_iso="jp"           # 国家代码（小写）
region_name="13"           # 区域短码
final_type="dual"          # 网络类型
merchant="k3s"             # 产品名称
rand8="a1b2c3d4"          # 随机 8 位

# FQDN（用点号连接）
FQDN="jp.13.dual.k3s.a1b2c3d4"

# 短名（用连字符连接）
SHORT_NAME="jp-13-dual-k3s-a1b2c3d4"
```

### 步骤 2: 更新应用逻辑

修改 `components/hostname/apply.sh`：

```bash
apply_hostname() {
    local hostname="$1"
    local fqdn="${2:-}"  # 可选的 FQDN
    
    # 设置短名作为系统主机名
    hostnamectl set-hostname "$hostname"
    
    # 更新 /etc/hosts
    if [[ -n "$fqdn" ]]; then
        # 两者都配置
        echo "127.0.1.1 $hostname $fqdn" >> /etc/hosts
    else
        echo "127.0.1.1 $hostname" >> /etc/hosts
    fi
}
```

### 步骤 3: 更新管理界面

修改 `components/hostname/manage.sh`：

```bash
manage_hostname_interactive() {
    # 生成主机名
    local short_name fqdn
    short_name=$(bash generate.sh geo k3s 01)
    fqdn=$(echo "$short_name" | tr '-' '.')
    
    echo "生成的主机名："
    echo "  短名（推荐）: $short_name"
    echo "  FQDN（备用）: $fqdn"
    echo ""
    
    # 选择应用方式
    echo "选择操作："
    echo "  1) 立即应用短名"
    echo "  2) 保存到配置码"
    echo "  3) 取消"
    
    read -r -p "选择 [1-3]: " choice
    
    case "$choice" in
        1)
            bash apply.sh "$short_name" "$fqdn"
            echo "✓ 主机名已应用: $short_name"
            ;;
        2)
            echo "$short_name" > /tmp/hostname_short.txt
            echo "$fqdn" > /tmp/hostname_fqdn.txt
            echo "✓ 已保存，可用于配置码"
            ;;
        3)
            echo "已取消"
            ;;
    esac
}
```

### 步骤 4: 更新工作流

修改 `workflows/export-config.sh` 和 `workflows/import-config.sh`：

**导出**：
```bash
# 导出时包含两种格式
config=$(add_hostname_to_config "$config" "$short_name" "$fqdn" "true")
```

**导入**：
```bash
# 导入时优先使用短名
local short_name fqdn
short_name=$(echo "$config" | jq -r '.hostname.short')
fqdn=$(echo "$config" | jq -r '.hostname.fqdn')

# 应用短名
bash components/hostname/apply.sh "$short_name" "$fqdn"
```

## 用户体验

### 交互流程

```
用户: 运行主机名管理
系统: 生成主机名...

      检测地理位置: 日本 东京
      检测网络类型: Dual Stack
      
      生成的主机名：
        短名（推荐）: jp-13-dual-k3s-a1b2c3d4
        FQDN（备用）: jp.13.dual.k3s.a1b2c3d4
      
      选择操作：
        1) 立即应用短名
        2) 保存到配置码
        3) 取消
      
用户: 选择 1

系统: ✓ 主机名已应用: jp-13-dual-k3s-a1b2c3d4
      ✓ /etc/hosts 已更新
      
      当前配置：
        hostname: jp-13-dual-k3s-a1b2c3d4
        hostname -f: jp-13-dual-k3s-a1b2c3d4
        
      可以使用以下方式访问：
        - ssh jp-13-dual-k3s-a1b2c3d4
        - ping jp-13-dual-k3s-a1b2c3d4
        - ping jp.13.dual.k3s.a1b2c3d4 (别名)
```

## 兼容性

### 向后兼容

- ✅ 旧的 FQDN 格式仍然可以作为别名使用
- ✅ 配置码同时包含短名和 FQDN
- ✅ 用户可以选择使用哪种格式

### K8s/K3s 兼容

```bash
# K3s 自动使用系统主机名
curl -sfL https://get.k3s.io | sh -s -

# 验证节点名
kubectl get nodes
# NAME                        STATUS
# jp-13-dual-k3s-a1b2c3d4    Ready  ✅
```

## 文档更新

需要更新的文档：

1. ✅ `FINAL-DECISION.md` - 本文档
2. ✅ `FQDN-VS-SHORT-NAME.md` - 对比分析
3. ✅ `K8S-HOSTNAME-COMPLIANCE.md` - 合规性验证
4. ✅ `FIXES-SUMMARY.md` - 修正总结
5. 🔄 `README.md` - 更新说明
6. 🔄 `QUICK-START-V2.md` - 更新示例
7. 🔄 `ARCHITECTURE.md` - 更新架构说明

## 测试计划

### 测试用例

1. **生成测试**
   ```bash
   # 测试短名生成
   bash components/hostname/generate.sh geo k3s 01
   # 预期: jp-13-dual-k3s-a1b2c3d4
   ```

2. **应用测试**
   ```bash
   # 测试短名应用
   bash components/hostname/apply.sh jp-13-dual-k3s-a1b2c3d4
   # 验证: hostname 返回短名
   ```

3. **配置码测试**
   ```bash
   # 测试导出
   bash workflows/export-config.sh
   # 验证: 配置码包含 short 和 fqdn
   
   # 测试导入
   bash workflows/import-config.sh
   # 验证: 应用短名到系统
   ```

4. **K3s 集成测试**
   ```bash
   # 部署 K3s
   curl -sfL https://get.k3s.io | sh -s -
   
   # 验证节点名
   kubectl get nodes
   # 预期: 节点名为短名格式
   ```

## 时间表

### 第一阶段（立即）✅
- [x] 自动安全清理
- [x] 决策文档
- [x] 合规性验证

### 第二阶段（下一步）🔄
- [ ] 集成 swarm-setup 主机名生成逻辑
- [ ] 更新应用和管理脚本
- [ ] 更新工作流
- [ ] 测试验证

### 第三阶段（完善）📋
- [ ] 更新所有文档
- [ ] 添加示例和教程
- [ ] 用户反馈收集

## 总结

### 核心决策 ✅

**使用短名作为主机名**：`jp-13-dual-k3s-a1b2c3d4`

### 理由

1. ✅ 完全符合 Kubernetes/K3s 标准
2. ✅ 更好的工具兼容性
3. ✅ 更简洁清晰
4. ✅ 避免 DNS 混淆
5. ✅ 更好的性能

### 实施方式

- **主要使用**：短名
- **备用别名**：FQDN
- **配置码**：同时包含两者
- **K8s 节点名**：短名

### 下一步

1. 集成 swarm-setup 的主机名生成逻辑
2. 更新所有相关脚本
3. 完善文档和示例
4. 测试验证

---

**决策日期**: 2024-12-30  
**版本**: 2.0.1  
**状态**: 已确认 ✅  
**实施**: 进行中 🔄
