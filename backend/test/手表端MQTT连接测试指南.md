# AI 老年健康守护系统 — 手表端 MQTT 连接测试指南

> 版本：v1.0 | 日期：2026-06-24 | 适用项目：`outputs/backend`

---

## 目录

1. [测试架构概览](#1-测试架构概览)
2. [前置准备](#2-前置准备)
3. [方案一：MQTTX 可视化工具测试](#3-方案一mqttx-可视化工具测试)
4. [方案二：Python 自动化模拟器](#4-方案二python-自动化模拟器)
5. [方案三：mosquitto 命令行测试](#5-方案三mosquitto-命令行测试)
6. [MQTT Topic 完整参考](#6-mqtt-topic-完整参考)
7. [完整端到端测试流程](#7-完整端到端测试流程)
8. [预期行为与验证点](#8-预期行为与验证点)
9. [故障排查](#9-故障排查)

---

## 1. 测试架构概览

```
┌─────────────────┐     MQTT      ┌─────────────────┐     HTTP      ┌─────────────────┐
│   手表模拟器     │ ──────────→ │    EMQX Broker  │ ──────────→ │  后端微服务      │
│  (Python/MQTTX)│ ←────────── │   localhost:1883 │ ←────────── │  (device/vital/ │
└─────────────────┘   上行Topic  └─────────────────┘   下行Topic  │   alarm-service)│
                                                                 └─────────────────┘
                                                                        │
                                                                        ▼
                                                                 ┌─────────────────┐
                                                                 │  MySQL 数据库   │
                                                                 │  (vital_signs, │
                                                                 │   alarms 表)    │
                                                                 └─────────────────┘
                                                                        │
                                                                        ▼
                                                                 ┌─────────────────┐
                                                                 │  前端管理台      │
                                                                 │  (实时报警推送) │
                                                                 └─────────────────┘
```

### 核心 Topic 一览

| 方向 | Topic 格式 | 说明 |
|------|------------|------|
| **上行**（手表→服务器） | `watch/vital/{device_id}` | 体征数据上报 |
| | `watch/alarm/{device_id}` | 报警上报（SOS/跌倒/异常体征） |
| | `watch/signin/{device_id}` | 签到上报 |
| | `watch/heartbeat/{device_id}` | 心跳保活（每分钟） |
| | `watch/position/{device_id}` | 位置上报（GPS/基站） |
| | `watch/sleep/{device_id}` | 睡眠数据上报 |
| | `watch/online/{device_id}` | 上线通知 |
| | `watch/offline/{device_id}` | 离线通知 |
| | `watch/batch/{device_id}` | 批量历史数据补传 |
| **下行**（服务器→手表） | `server/alarm/{device_id}` | 报警确认/处理指令 |
| | `server/upgrade/{device_id}` | OTA 升级指令 |
| | `server/config/{device_id}` | 配置下发（采集频率等） |

---

## 2. 前置准备

### 2.1 启动后端服务

```bash
cd outputs/backend/deploy

# 启动所有服务（MySQL + Redis + EMQX + 微服务）
docker compose up -d

# 确认所有服务正常运行
docker compose ps

# 查看 EMQX 日志
docker logs -f ehc-emqx
```

### 2.2 验证 EMQX 可用

打开浏览器访问 EMQX Dashboard：

```
URL:      http://localhost:18083
用户名:  admin
密码:    public
```

在 Dashboard → **Clients** 页面，应该能看到一个空列表（表示 EMQX 正常运行，等待设备连接）。

### 2.3 准备测试设备 ID

模拟器使用的 `device_id` 必须与数据库中 `devices` 表的记录一致。

查看已有设备：
```bash
docker exec -it ehc-mysql mysql -uroot -proot123456 \
  -e "SELECT id, device_id, device_type, elderly_id, status FROM elderly_health.devices;"
```

如需插入测试设备：
```sql
INSERT INTO devices (device_id, device_type, elderly_id, bind_status, status)
VALUES ('EH-TEST-001', 'EH-Pro', 1, 'bound', 'offline');
```

---

## 3. 方案一：MQTTX 可视化工具测试

### 3.1 安装 MQTTX

下载地址：<https://mqttx.app/zh/>

支持 Windows / macOS / Linux，安装后打开即可。

### 3.2 建立连接

点击 **+ New Connection**，填写：

| 字段 | 值 |
|------|-----|
| Name | Watch-Simulator |
| Host | localhost |
| Port | 1883 |
| Client ID | `watch_EH-TEST-001` |
| Protocol | mqtt:// |
| Username | （留空，设备认证由业务层处理） |

点击 **Connect**。

### 3.3 订阅下行 Topic

连接成功后，点击 **New Subscription**，依次添加：

```
server/alarm/EH-TEST-001
server/upgrade/EH-TEST-001
server/config/EH-TEST-001
```

### 3.4 发送上行消息（模拟手表）

在底部消息框中，选择 **Publish**，依次测试：

#### 📈 上报体征数据

```
Topic: watch/vital/EH-TEST-001
Payload (JSON):
{
  "elderly_id": "1",
  "heart_rate": 85,
  "blood_pressure_sys": 135,
  "blood_pressure_dia": 82,
  "spo2": 97,
  "temperature": 36.8,
  "timestamp": 1719234000
}
```

#### 🚨 模拟 SOS 报警

```
Topic: watch/alarm/EH-TEST-001
Payload (JSON):
{
  "elderly_id": "1",
  "alarm_type": "sos",
  "location": {"lat": 31.210, "lng": 121.545},
  "timestamp": 1719234000
}
```

#### ✅ 模拟签到

```
Topic: watch/signin/EH-TEST-001
Payload (JSON):
{
  "elderly_id": "1",
  "signin_time": "08:30",
  "timestamp": 1719234000
}
```

#### 💓 心跳保活

```
Topic: watch/heartbeat/EH-TEST-001
Payload (JSON):
{"device_id": "EH-TEST-001", "battery": 78, "timestamp": 1719234000}
```

#### 📍 位置上报

```
Topic: watch/position/EH-TEST-001
Payload (JSON):
{
  "elderly_id": "1",
  "lat": 31.210,
  "lng": 121.545,
  "accuracy": 10,
  "timestamp": 1719234000
}
```

### 3.5 验证结果

在 EMQX Dashboard → **Clients** 中，可以看到 `watch_EH-TEST-001` 已连接。

在后端日志中（`docker logs -f ehc-device-service`），可以看到收到的 MQTT 消息。

在 MySQL 中查询：
```sql
SELECT * FROM vital_signs ORDER BY id DESC LIMIT 5;
SELECT * FROM alarms ORDER BY id DESC LIMIT 5;
```

---

## 4. 方案二：Python 自动化模拟器

### 4.1 安装依赖

```bash
pip install paho-mqtt
```

### 4.2 运行模拟器

已提供完整脚本 `outputs/backend/test/watch_simulator.py`，运行方式：

```bash
# 基础运行（默认连接 localhost:1883）
python watch_simulator.py

# 指定设备 ID 和 EMQX 地址
python watch_simulator.py --device-id EH-TEST-001 --broker 192.168.1.100 --elderly-id 1

# 批量模拟（同时模拟 10 台设备）
python watch_simulator.py --batch 10

# 自动触发 SOS 报警（运行 60 秒后触发）
python watch_simulator.py --sos-delay 60
```

### 4.3 脚本功能说明

| 功能 | 说明 |
|------|------|
| 自动上线/下线通知 | 连接时发 `watch/online`，断开时发 `watch/offline` |
| 定时体征上报 | 每 30 秒上报一次模拟体征数据 |
| 心跳保活 | 每 60 秒发送一次心跳 |
| SOS 模拟 | 支持 `--sos-delay` 参数，延迟触发 SOS 报警 |
| 批量模拟 | `--batch N` 同时模拟 N 台设备 |
| 下行指令监听 | 自动订阅 `server/#` 并打印收到的指令 |

---

## 5. 方案三：mosquitto 命令行测试

### 5.1 安装 mosquitto（如未安装）

```bash
# Ubuntu / Debian
sudo apt install -y mosquitto mosquitto-clients

# macOS
brew install mosquitto

# Windows: 下载 https://mosquitto.org/download/
```

### 5.2 订阅下行指令（接收服务器推送）

```bash
# 新开终端，监听所有该设备的下行 Topic
mosquitto_sub -h localhost -p 1883 \
  -t "server/alarm/EH-TEST-001" \
  -t "server/upgrade/EH-TEST-001" \
  -t "server/config/EH-TEST-001" \
  -v
```

### 5.3 发送上行消息

#### 上报体征
```bash
mosquitto_pub -h localhost -p 1883 \
  -t "watch/vital/EH-TEST-001" \
  -m '{"elderly_id":"1","heart_rate":85,"blood_pressure_sys":135,"blood_pressure_dia":82,"spo2":97,"temperature":36.8,"timestamp":1719234000}'
```

#### 触发 SOS 报警
```bash
mosquitto_pub -h localhost -p 1883 \
  -t "watch/alarm/EH-TEST-001" \
  -m '{"elderly_id":"1","alarm_type":"sos","location":{"lat":31.210,"lng":121.545},"timestamp":1719234000}'
```

#### 上报签到
```bash
mosquitto_pub -h localhost -p 1883 \
  -t "watch/signin/EH-TEST-001" \
  -m '{"elderly_id":"1","signin_time":"08:30","timestamp":1719234000}'
```

#### 心跳保活
```bash
mosquitto_pub -h localhost -p 1883 \
  -t "watch/heartbeat/EH-TEST-001" \
  -m '{"device_id":"EH-TEST-001","battery":78,"timestamp":1719234000}'
```

---

## 6. MQTT Topic 完整参考

### 6.1 上行 Topic（手表 → 服务器）

| Topic | QoS | 说明 | Payload 必要字段 |
|-------|-----|------|-------------------|
| `watch/vital/{device_id}` | 1 | 实时体征上报 | `elderly_id`, `heart_rate`, `spo2`, `timestamp` |
| `watch/alarm/{device_id}` | 1 | 报警上报 | `elderly_id`, `alarm_type`, `location`, `timestamp` |
| `watch/signin/{device_id}` | 1 | 签到上报 | `elderly_id`, `signin_time`, `timestamp` |
| `watch/heartbeat/{device_id}` | 0 | 心跳保活（60s） | `device_id`, `battery`, `timestamp` |
| `watch/position/{device_id}` | 1 | GPS/基站定位 | `elderly_id`, `lat`, `lng`, `accuracy` |
| `watch/sleep/{device_id}` | 1 | 睡眠数据（晨起上报） | `elderly_id`, `sleep_start`, `sleep_end`, `quality` |
| `watch/online/{device_id}` | 1 | 上线通知 | `elderly_id`, `timestamp` |
| `watch/offline/{device_id}` | 1 | 离线通知 | `timestamp` |
| `watch/batch/{device_id}` | 1 | 断网补传（批量历史数据） | `elderly_id`, `records[]`（数组） |

### 6.2 下行 Topic（服务器 → 手表）

| Topic | QoS | 说明 | 预期手表行为 |
|-------|-----|------|----------------|
| `server/alarm/{device_id}` | 1 | 报警处理指令 | 停止本地报警声 |
| `server/upgrade/{device_id}` | 1 | OTA 升级指令 | 下载并安装新固件 |
| `server/config/{device_id}` | 1 | 配置下发 | 更新采集频率等参数 |

### 6.3 Payload 格式详细说明

#### 体征上报 `watch/vital/{device_id}`

```json
{
  "elderly_id": "1",
  "heart_rate": 85,
  "blood_pressure_sys": 135,
  "blood_pressure_dia": 82,
  "spo2": 97,
  "temperature": 36.8,
  "step_count": 1200,
  "timestamp": 1719234000
}
```

#### 报警上报 `watch/alarm/{device_id}`

```json
{
  "elderly_id": "1",
  "alarm_type": "sos",
  "location": {
    "lat": 31.210,
    "lng": 121.545,
    "accuracy": 10
  },
  "timestamp": 1719234000
}
```

`alarm_type` 取值范围：
- `sos` — 一键求救（P0 级）
- `fall` — 跌倒检测（P1 级）
- `abnormal_vital` — 体征异常（P2 级）
- `geofence` — 电子围栏越界（P1 级）
- `device_offline` — 设备离线（P2 级）

#### 批量补传 `watch/batch/{device_id}`

```json
{
  "elderly_id": "1",
  "records": [
    {
      "type": "vital",
      "data": {"heart_rate": 85, "spo2": 97, "timestamp": 1719231000}
    },
    {
      "type": "position",
      "data": {"lat": 31.210, "lng": 121.545, "timestamp": 1719232000}
    }
  ]
}
```

---

## 7. 完整端到端测试流程

### 7.1 正常流程测试

```
步骤 1：启动后端
  $ docker compose up -d
  ✅ 所有容器状态为 Up

步骤 2：启动手表模拟器
  $ python watch_simulator.py --device-id EH-TEST-001
  ✅ 看到 "✅ 手表 EH-TEST-001 已连接到 EMQX"

步骤 3：验证设备上线
  打开 EMQX Dashboard → Clients
  ✅ 看到 watch_EH-TEST-001 在线

步骤 4：验证体征数据入库
  等待 30 秒（自动上报间隔）
  $ docker exec -it ehc-mysql mysql -uroot -proot123456 \
      -e "SELECT * FROM elderly_health.vital_signs ORDER BY id DESC LIMIT 3;"
  ✅ 看到最新的体征记录

步骤 5：模拟 SOS 报警
  在模拟器中按 Ctrl+C 触发 SOS（或另开终端发送）
  ✅ 后端 alarm-service 日志显示 "收到新报警"
  ✅ MySQL alarms 表新增记录，level=P0
  ✅ 前端管理台 "报警管理" 页面出现新报警（红色高亮）

步骤 6：确认报警处理流程
  在前端管理台 → 报警管理 → 点击 "确认"
  ✅ 手表模拟器收到下行消息: server/alarm/{device_id}
  ✅ 报警状态变为 "confirmed"

步骤 7：模拟签到
  发送签到消息
  ✅ MySQL signin_records 表新增记录
  ✅ 前端 "签到管理" 页面显示今日签到
```

### 7.2 异常流程测试

```
测试 A：网络中断后恢复（批量补传）
  1. 停止模拟器（模拟断网）
  2. 等待 2 分钟
  3. 重新启动模拟器
  ✅ 模拟器发送 watch/batch 补传历史数据
  ✅ 服务端正常接收并入库

测试 B：设备电量低
  发送心跳时 battery=5
  ✅ 触发低电量提醒（前端提示）

测试 C：多次 SOS 防抖
  1 秒内发送 5 次 SOS
  ✅ 服务端去重，只产生 1 条报警记录
```

---

## 8. 预期行为与验证点

### 8.1 各服务日志位置

```bash
# 设备连接/断开
docker logs -f ehc-device-service

# 体征数据处理
docker logs -f ehc-vital-service   # （如已拆分）
docker logs -f ehc-device-service  # 体征上报在 device-service 处理

# 报警处理
docker logs -f ehc-alarm-service

# 签到处理
docker logs -f ehc-signin-service

# MQTT 消息追踪（EMQX）
docker exec -it ehc-emqx emqx ctl topics list
docker exec -it ehc-emqx emqx ctl clients list
```

### 8.2 数据库验证 SQL

```sql
-- 查看最新体征数据
SELECT e.name, v.heart_rate, v.spo2, v.created_at
FROM vital_signs v
JOIN elderly_profiles e ON v.elderly_id = e.id
ORDER BY v.id DESC LIMIT 10;

-- 查看未处理报警
SELECT a.id, e.name, a.alarm_type, a.level, a.status, a.created_at
FROM alarms a
JOIN elderly_profiles e ON a.elderly_id = e.id
WHERE a.status = 'pending'
ORDER BY a.created_at DESC;

-- 查看今日签到
SELECT e.name, s.signin_time, s.status
FROM signin_records s
JOIN elderly_profiles e ON s.elderly_id = e.id
WHERE DATE(s.signin_date) = CURDATE();

-- 查看设备在线状态
SELECT device_id, status, last_online_time
FROM devices
ORDER BY last_online_time DESC;
```

---

## 9. 故障排查

### 9.1 手表无法连接 EMQX

| 现象 | 原因 | 解决方案 |
|------|------|------------|
| Connection refused | EMQX 未启动 | `docker start ehc-emqx` |
| Connection timeout | 防火墙未开放 1883 端口 | 开放端口或关闭防火墙测试 |
| Client ID 冲突 | 同一 ID 已在线 | 使用不同的 `device_id` |

### 9.2 数据未入库

| 现象 | 原因 | 解决方案 |
|------|------|------------|
| MQTT 消息已发送但数据库无数据 | device-service 未运行 | `docker start ehc-device-service` |
| 报警未触发 | `alarm_type` 字段值不正确 | 检查拼写，参考 6.3 节 |
| 体征数据字段缺失 | JSON 缺少必填字段 | 对照 `vital_signs` 表结构补全 |

### 9.3 EMQX Dashboard 无法访问

```bash
# 检查端口映射
docker port ehc-emqx

# 重启 EMQX
docker restart ehc-emqx

# 查看 EMQX 启动日志
docker logs ehc-emqx | tail -50
```

---

## 附录

### A. 快速参考卡片

```bash
# EMQX 地址
Broker:   localhost:1883   (MQTT)
Dashboard: http://localhost:18083  (admin / public)

# 模拟器运行
python watch_simulator.py --device-id EH-TEST-001 --broker localhost

# 查看实时日志
docker logs -f ehc-device-service  # 设备连接
docker logs -f ehc-alarm-service   # 报警处理

# 验证数据
mysql -h 127.0.0.1 -u root -proot123456 elderly_health \
  -e "SELECT * FROM vital_signs ORDER BY id DESC LIMIT 5;"
```

### B. 测试检查清单

- [ ] EMQX 正常运行（Dashboard 可访问）
- [ ] 后端所有服务状态为 Up
- [ ] 手表模拟器成功连接 EMQX
- [ ] 体征数据正常入库（`vital_signs` 表）
- [ ] SOS 报警触发后前端实时收到
- [ ] 报警确认后下行指令发送到手表
- [ ] 签到数据正常入库（`signin_records` 表）
- [ ] 心跳消息正常接收（`devices.last_heartbeat` 更新）
- [ ] 设备下线后 `devices.status` 变为 `offline`
- [ ] 批量补传功能正常
