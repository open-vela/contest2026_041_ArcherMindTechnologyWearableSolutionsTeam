# AI老年健康守护系统 — 服务器后台部署指南

## 部署环境选择

### 推荐方案：Linux 服务器（生产环境）

| 发行版 | 最低版本 | 推荐版本 |
|--------|---------|---------|
| Ubuntu Server | 20.04 LTS | **22.04 LTS** / 24.04 LTS |
| Debian | 11 (Bullseye) | 12 (Bookworm) |
| CentOS / Rocky | 7.9 | 8.x / 9.x |
| Alibaba Cloud Linux | 2.0 | 3.0 |

**推荐配置**：

| 场景 | CPU | 内存 | 磁盘 | 预估费用/月 |
|------|-----|------|------|:----:|
| **最低（开发测试）** | 2 核 | 4 GB | 40 GB SSD | ~¥60 |
| **推荐（50设备）** | 4 核 | 8 GB | 100 GB SSD | ~¥150 |
| **标准（200设备）** | 8 核 | 16 GB | 200 GB SSD | ~¥400 |
| **高配（500+设备）** | 16 核 | 32 GB | 500 GB SSD | ~¥1200 |

### Windows 是否可行？

**✅ 可以**，但需注意以下限制：

| 维度 | Windows Docker Desktop | Linux 原生 Docker |
|------|----------------------|-------------------|
| **性能** | WSL2 虚拟化层损耗 ~15% | 原生，零损耗 |
| **稳定性** | 偶尔需重启 Docker | 极高（7x24 无问题） |
| **内存占用** | Docker Desktop 自身 ~2GB | 仅容器占用 |
| **许可** | 商用需 Docker 付费订阅 | 完全免费开源 |
| **自动化** | 开机自启需配置 | systemd 原生支持 |
| **适合场景** | 本地开发、演示、小规模测试 | **生产环境** |

> **结论**：Windows 非常适合开发调试和演示，但如果要用于生产环境跑真实设备，强烈建议 Linux。

---

## 🚀 一键部署

### Windows（PowerShell 脚本）

```powershell
# 1. 确保已安装 Docker Desktop 并正在运行
#    下载: https://www.docker.com/products/docker-desktop/

# 2. 打开 PowerShell，进入项目目录
cd .\backend

# 3. 运行一键部署脚本
.\deploy\setup.ps1

# 或者直接用 .bat 双击运行:
# 双击 deploy\setup.bat
```

脚本会自动完成：
1. ✅ 环境检测（Docker/内存/磁盘/端口冲突）
2. ✅ 生成 .env 配置文件
3. ✅ 拉取基础镜像 + 编译 Go 微服务
4. ✅ 启动所有 12 个容器
5. ✅ 健康检查 + 管理员登录验证
6. ✅ 创建桌面快捷方式

---

### Linux（Bash 脚本）

```bash
# 1. SSH 登录服务器，克隆项目
cd /opt
# (将项目代码拷贝到此处)

# 2. 进入目录，赋予执行权限
cd backend
chmod +x deploy/setup.sh

# 3. 一键部署（推荐用 sudo）
sudo ./deploy/setup.sh
```

脚本会自动完成：
1. ✅ 检测系统环境
2. ✅ **自动安装 Docker**（如果未安装）+ Docker Compose Plugin
3. ✅ 端口冲突检测
4. ✅ 生成 .env + 随机 JWT 密钥
5. ✅ 拉取镜像 + 编译微服务
6. ✅ 启动服务 + 健康检查
7. ✅ **注册 systemd 开机自启动**
8. ✅ 防火墙端口放行提醒

### 部署脚本命令速查

| 命令 | Windows | Linux |
|------|---------|-------|
| 完整部署 | `.\deploy\setup.ps1` | `sudo ./deploy/setup.sh` |
| 查看状态 | `.\deploy\setup.ps1 status` | `./deploy/setup.sh status` |
| 查看日志 | `.\deploy\setup.ps1 logs` | `./deploy/setup.sh logs` |
| 停止服务 | `.\deploy\setup.ps1 stop` | `./deploy/setup.sh stop` |
| 重启服务 | `.\deploy\setup.ps1 restart` | `./deploy/setup.sh restart` |
| 更新代码 | — | `./deploy/setup.sh update` |
| 完全卸载 | `.\deploy\setup.ps1 uninstall` | `./deploy/setup.sh uninstall` |

---

## 📋 部署后验证

### 1. 健康检查

```bash
curl http://localhost/health
```

预期响应：
```json
{
  "code": 0,
  "data": {
    "status": "healthy",
    "services": {
      "mysql": "UP",
      "redis": "UP",
      "user-service": "UP",
      "device-service": "UP",
      "...": "..."
    }
  }
}
```

### 2. 管理员登录

```bash
curl -X POST http://localhost/v1/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Admin@2026"}'
```

### 3. 浏览器访问

打开浏览器访问：
- **管理后台**：http://localhost  （或服务器 IP）
- **EMQX 面板**：http://localhost:18083 （默认 admin/public）

---

## 🔧 手动部署（不依赖脚本）

如果自动化脚本有问题，可以手动执行：

```bash
# 1. 创建配置
cp .env.example .env
# 编辑 .env 修改密码

# 2. 启动基础服务
docker compose -f deploy/docker-compose.yml up -d mysql redis emqx

# 3. 等待就绪（约 30 秒）
sleep 30

# 4. 构建微服务镜像
docker compose -f deploy/docker-compose.yml build

# 5. 启动全部服务
docker compose -f deploy/docker-compose.yml up -d

# 6. 验证
curl http://localhost/health
```

---

## 🛡️ 生产环境 Checklist

部署到生产环境前请完成以下步骤：

- [ ] **修改 JWT Secret**：编辑 `.env` 中的 `JWT_SECRET`，使用 `openssl rand -hex 32` 生成
- [ ] **修改数据库密码**：编辑 `.env` 中的 `MYSQL_ROOT_PASSWORD`
- [ ] **修改默认管理员密码**：部署后立即登录后台修改
- [ ] **配置 HTTPS**：替换 `deploy/nginx.conf` 中的 SSL 证书路径
- [ ] **配置 IP 白名单**：在 `configs/config.yaml` 中设置 `security.ip_whitelist`
- [ ] **防火墙规则**：仅开放 80/443（Web）和 1883（MQTT），其他端口仅本机访问
- [ ] **日志收集**：接入 ELK/Loki + Prometheus + Grafana
- [ ] **数据库备份**：设置 MySQL 定时备份（mysqldump + cron）
- [ ] **资源限制**：在 `docker-compose.yml` 中为每个服务设置 `deploy.resources.limits`
- [ ] **Docker 日志轮转**：配置 `/etc/docker/daemon.json` 限制容器日志大小

---

## 🌐 云平台推荐

| 平台 | 适用场景 | 优势 |
|------|---------|------|
| **腾讯云 CVM** | 国内首选 | 内网互通、EMQX 镜像加速 |
| **阿里云 ECS** | 通用 | 生态完善、文档丰富 |
| **华为云 ECS** | 政企 | 安全合规 |
| **AWS EC2** | 海外 | 全球节点、免费套餐 |

> 选择云服务器时建议选靠近目标用户的地域（如华南→广州、华东→上海）。

---

## 🔌 手表端连接配置

手表端 MQTT 连接参数：

```
Broker:  tcp://<服务器公网IP>:1883
TLS:     tls://<服务器公网IP>:8883  (生产环境必须)
认证:    X.509 客户端证书（在 EMQX 管理面板中签发）
```

> ⚠️ 务必在云服务器安全组/防火墙中放行 **1883**（MQTT）和 **8883**（MQTT over TLS）端口。

---

## ❓ 常见问题

### 1. Docker 镜像构建失败（国内网络）

```bash
# 配置 Docker 镜像加速器（阿里云/腾讯云）
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com",
    "https://registry.cn-hangzhou.aliyuncs.com"
  ]
}
EOF
sudo systemctl restart docker
```

### 2. 端口被占用

```bash
# Linux: 查看端口占用
sudo ss -tlnp | grep ":80 "

# Windows: 查看端口占用
netstat -ano | findstr ":80 "

# 修改 docker-compose.yml 中的端口映射后重新部署
```

### 3. MySQL 初始化失败

```bash
# 查看 MySQL 日志
docker logs ehc-mysql

# 手动执行迁移
docker exec -i ehc-mysql mysql -uroot -p${MYSQL_ROOT_PASSWORD} < migrations/001_init.sql
```

### 4. Windows Docker Desktop 启动后自动关机

- 确保 BIOS 中开启了虚拟化（Intel VT-x / AMD SVM）
- 确保 WSL2 已正确安装：`wsl --install`
- Docker Desktop → Settings → Resources → 限制内存为 4GB

### 5. 服务器重启后服务没有自动启动（Linux）

```bash
# 检查 systemd 服务
systemctl status ehc-elderly-health

# 手动启用
sudo systemctl enable ehc-elderly-health

# Docker 容器重启策略
# docker-compose.yml 中已配置 restart: always
docker compose -f deploy/docker-compose.yml up -d
```
