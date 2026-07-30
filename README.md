# AI老年健康守护系统（银发守护）

## 一、作品简介

**AI老年健康守护系统（银发守护 / Silver-haired Protector）** 是一个面向老龄化社会的五端协同智慧养老平台。系统以"今天还好吗"为核心理念，通过老人佩戴的 BES2700 智能手表 7×24 小时无感采集心率、血氧、体温、IMU 等体征数据，结合 **本地三级流水线跌倒检测算法** 和 **云端 P0-P3 四级规则引擎**，构建从"体征采集 → 数据分析 → AI 解读 → 分级报警 → 子女关怀 → 社区响应 → 120 急救"的全链路闭环守护体系。当检测到 SOS 求救、跌倒或生命体征严重异常时，系统在 **5 秒内**通过 Push + 短信 + 电话三重通道触达子女和社区，联动 120 急救，解决独居老人突发意外无法及时获救的社会痛点。

**核心亮点：**
- **三级流水线跌倒检测**：加速度阈值 → 姿态特征 → 上下文验证，全程离线运行，召回率 >95%，检测延迟 <500ms
- **P0-P3 四级智能报警**：基于滑动窗口 + 多阈值组合判定的规则引擎，P0 紧急报警 ≤5 秒全通道触达
- **五端协同架构**：老人手表（BES2700）+ 家庭大屏（Gemini-S1）+ 子女快应用 + 社区 Web 管理台 + 云端微服务中台
- **72 小时离线缓存**：手表端 RingBuffer 断网缓存，网络恢复自动补传，数据零丢失
- **AI 健康周报**：云端 LLM（腾讯混元/阿里百炼）自动生成大白话风格健康周报，推送给子女
- **完整后台管理体系**：管理员 RBAC 鉴权 + 双因素认证 + IP 白名单 + 全操作审计日志
- **全链路 AI 辅助开发**：从需求拆解、方案设计、代码编写到部署排障，全程 AI 协作

---

## 二、选题方向

**快应用 / 手表应用创新**

理由：本作品基于 **VelaOS 智能手表平台（BES2700 芯片）**，充分发挥手表端传感器（PPG 心率、SpO2 血氧、温度、六轴 IMU、GPS）的硬件能力，在端侧完成跌倒检测和健康异常判断，真正发挥"手表作为随身健康终端"的独特优势。同时，子女端以 **快应用（Quick App）** 形态免安装触达，社区管理端以 **React Web 管理台** 提供驾驶舱式运营视图，形成完整的"端-云-人"三位一体解决方案。相比纯手机 App 方案，手表天然具备 24 小时贴身佩戴、传感器持续采集、SOS 一键触达三大不可替代性。手表端开发在内存（<1MB）、计算资源、圆屏 UI（466×466）等方面有严格工程约束，技术挑战性高。

---

## 三、目录结构

```
elderly-care-system/
│
├── Silver-haired_Protector/      — 手表端快应用（子女端 App）
│   ├── src/app.ux               — 应用入口组件（生命周期管理）
│   ├── src/manifest.json         — 应用配置（包名、权限、路由、后台特性）
│   ├── src/pages/                — 页面：首页体征 / SOS报警 / 健康详情 / 设置
│   ├── src/services/             — 核心服务：传感器采集 / 数据缓存 / 上传 / 报警 / 跌倒检测
│   ├── src/utils/                — 工具函数
│   └── package.json              — 快应用依赖（aiot-toolkit）
│
├── web-admin-react/              — 社区管理 Web 端（React + TypeScript）
│   ├── src/api/                  — API 层（Axios 封装，对接所有微服务）
│   ├── src/stores/               — Zustand 状态管理（认证/看板/报警/老人档案）
│   ├── src/pages/                — 页面：登录 / 社区看板 / 老人管理 / 设备管理 / 报警管理 / 签到 / 巡访 / 周报 / 设置
│   ├── src/components/           — 通用组件：布局 / 统计卡片 / 图表 / 筛选栏 / 状态标签
│   ├── src/hooks/                — 自定义 Hooks（WebSocket / 轮询 / 认证）
│   ├── src/types/                — TypeScript 类型定义
│   ├── src/utils/                — 工具函数
│   ├── vite.config.ts            — Vite 构建配置
│   └── package.json              — 依赖：React 18 / Ant Design 5 / Recharts / Zustand / Axios
│
├── backend/                      — Go 微服务后台（12 个服务）
│   ├── cmd/                      — 各服务启动入口（main.go）
│   │   ├── admin-auth-service/   — 管理员认证鉴权服务（:8011）
│   │   ├── user-service/         — 老人档案 + 家庭绑定 + 社区管理（:8001）
│   │   ├── device-service/       — 设备注册 + MQTT 数据消费（:8002）
│   │   ├── vital-service/        — 体征数据存储与查询（:8003）
│   │   ├── alarm-service/        — 报警查询/处理 + 规则引擎（:8004）
│   │   ├── signin-service/       — 签到管理与查询（:8005）
│   │   ├── patrol-service/       — 巡访任务管理（:8006）
│   │   ├── notify-service/       — 通知推送 Push/SMS/电话（:8007）
│   │   ├── report-service/       — AI 健康周报生成与查询（:8008）
│   │   ├── emergency-service/    — 120 急救联动（:8009，内部 gRPC）
│   │   ├── dashboard-service/    — 看板统计 + 系统配置（:8010）
│   │   └── websocket-service/    — WebSocket ↔ MQTT 实时桥接（:8012）
│   ├── internal/                 — 各服务内部实现（handler / service 层）
│   ├── internal/shared/          — 共享基础设施（config / database / redis / mqtt / models / middleware）
│   ├── deploy/                   — 部署文件
│   │   ├── docker-compose.yml    — 全栈 Docker Compose（MySQL + Redis + EMQX + 12 个微服务 + Nginx 前端）
│   │   ├── Dockerfile            — 多阶段构建镜像
│   │   ├── nginx.conf            — Nginx 反向代理 / 静态资源
│   │   ├── setup.sh / setup.bat  — 一键部署脚本
│   │   └── backup.sql            — 数据库备份
│   └── migrations/               — 数据库初始化 SQL（建表 + 分区 + 种子数据）
│
├── bes-watch/                    — 手表端 BES2700 硬件相关说明
│   └── Readme.txt                — 手表端开发/烧录/调试说明
│
├── docs/                         — (预留) 文档目录
│
├── AI健康守护_版本A_业务流程说明.md           — 业务流程详细说明（手表端/手机端/中台端 + 交互流程）
├── 服务器后台架构设计说明书.md                — 后台 12 个微服务详细设计说明书
├── 前端架构设计说明书.md                      — Web 管理端前端架构设计说明书
├── 数据库设计文档.md                          — MySQL 8.0 + Redis 完整数据库设计文档
├── 后台管理员账户管理体系设计说明书.md          — 管理员认证/RBAC/审计/安全策略设计
├── API接口文档.md                             — 完整 REST API + WebSocket 接口文档
├── AI老年健康守护系统_参赛技术方案_详细版.pptx   — 参赛技术方案 PPT
├── AI老年健康守护系统方案介绍.pdf               — 方案介绍 PDF
└── README.md                                  — 本文件
```

---

## 四、运行方式

### 4.1 环境要求

| 组件 | 要求 |
|------|------|
| 操作系统 | Linux（推荐 Ubuntu 20.04+）/ Windows 10+ / macOS |
| Docker | ≥ 20.10，Docker Compose ≥ 2.0 |
| Go | ≥ 1.21（仅本地开发编译需要） |
| Node.js | ≥ 16（仅前端本地开发需要） |
| 硬件 | 最低 4C8G（生产环境建议 4C8G×3） |

### 4.2 一键部署（推荐，Docker Compose）

```bash
# 1. 克隆项目
git clone <your-repo-url>
cd elderly-care-system

# 2. 一键部署全栈服务（MySQL + Redis + EMQX + 12 个微服务 + Nginx 前端）
cd backend/deploy
docker compose up -d

# 3. 查看服务状态
docker compose ps

# 4. 访问地址
# Web 管理端：http://<服务器IP>/
# API 基础地址：http://<服务器IP>/api/v1/
# WebSocket：ws://<服务器IP>/ws
# EMQX Dashboard：http://<服务器IP>:18083/
```

### 4.3 分端本地开发运行

#### 4.3.1 Web 管理端（web-admin-react）

```bash
cd web-admin-react

# 安装依赖
npm install

# 本地开发（需要先启动后台服务）
npm run dev
# 默认访问 http://localhost:5173

# 生产构建
npm run build
# 产出物在 dist/ 目录，可直接由 Nginx 托管
```

#### 4.3.2 后台微服务（backend）

```bash
cd backend

# 安装 Go 依赖
cd cmd/alarm-service && go mod tidy  # 以 alarm-service 为例

# 本地启动（需要先启动 MySQL + Redis + EMQX）
# 方式一：使用 setup.sh 脚本
cd backend/deploy && bash setup.sh

# 方式二：手动启动每个服务（以 admin-auth-service 为例）
cd backend/cmd/admin-auth-service
DB_DSN="root:password@tcp(127.0.0.1:3306)/elderly_health" \
REDIS_ADDR="127.0.0.1:6379" \
JWT_SECRET="your-secret-key" \
go run main.go
```

#### 4.3.3 手表端快应用（Silver-haired_Protector）

```bash
cd Silver-haired_Protector

# 安装依赖
npm install

# 本地开发（需要快应用开发工具）
npm start

# 构建发布包
npm run build

# 发布
npm run release
```

> **手表端硬件要求**：需要 BES2700 芯片的智能手表设备，使用 VelaOS/OpenVela 系统。本地开发时可使用模拟器调试，无需真机。详情参见 `bes-watch/Readme.txt`。

### 4.4 数据库初始化

```bash
# 数据库初始化 SQL 在容器启动时自动执行
# 文件位置：backend/migrations/init.sql（含所有建表语句和种子数据）

# 如需要手动执行：
docker exec -i ehc-mysql mysql -uroot -p${MYSQL_ROOT_PASSWORD} elderly_health < backend/migrations/init.sql
```

---

## 五、AI Coding 使用说明

### 5.1 协作模式

本项目全程借助 AI（WorkBuddy）完成开发，采用"人定方向、AI 执行、人审结果"的协作模式，覆盖以下环节：

| 阶段 | AI 协作方式 | 产出物 |
|------|------------|--------|
| **需求拆解** | 根据用户口述的业务场景（老人佩戴手表→健康监测→分级报警→子女/社区响应），AI 自动分析并拆解为五端协同的业务流程，生成完整的 PRD 级业务流程说明 | `AI健康守护_版本A_业务流程说明.md` |
| **方案设计** | AI 根据需求自动设计微服务划分（12 个服务）、数据库 ER 模型（19 张表 + 2 张时序分区表）、API 协议定义、前端组件树和状态管理方案 | 架构/数据库/API/前端设计说明书 |
| **编码实现** | AI 逐服务生成 Go 代码（Gin handler + 业务逻辑 + 数据访问层）、React 前端页面组件 + API 封装 + Zustand Store、快应用页面 + 服务层代码 | `backend/`、`web-admin-react/`、`Silver-haired_Protector/` |
| **调试排障** | 编译报错、SQL 语法问题、Docker 部署兼容性、端口冲突、Nginx 反向代理配置等问题的排查与修复，AI 根据错误日志定位并给出修复方案 | 各版本 `.bak` / `.<date>` 备份文件 |
| **文档生成** | AI 自动生成 6 份完整技术文档（架构设计、前端架构、数据库设计、API 接口、管理员体系、业务流程），并生成参赛 PPT | 根目录 6 份 `.md` 文档 + `.pptx` |
| **部署配置** | AI 生成 Dockerfile（多阶段构建）、docker-compose.yml（全栈编排）、Nginx 配置（反向代理 + 静态资源）、一键部署脚本 | `backend/deploy/` |

### 5.2 实际效果

- **开发效率**：从零到完整可运行的五端系统（12 个微服务 + Web 管理台 + 快应用 + 6 份设计文档），整体开发周期压缩至传统模式的 **1/5 ~ 1/3**
- **代码质量**：AI 生成的 Go 代码遵循标准项目结构（cmd/internal/pkg），React 代码遵循组件化最佳实践，数据库设计完整覆盖命名规范、索引策略、分区方案、降采样策略
- **文档完备性**：AI 自动生成的技术文档覆盖架构设计、接口定义、数据库设计、部署流程等评委关注的核心维度，文档风格统一、内容详实
- **迭代速度**：Docker 部署过程中遇到多次兼容性问题，AI 快速定位根因（如 MySQL 8.0.35 特定版本行为差异、EMQX 5.x 认证配置变更），从发现到修复通常在 10 分钟内完成

### 5.3 典型 AI 协作示例

**场景一：报警规则引擎设计**

> 用户提出需求："需要四层报警，最紧急的叫 P0，然后是 P1、P2、P3" → AI 自动拆解为：① 定义每级触发条件（P0: SOS/跌倒/心率<30或>180/血氧<85%；P1-P3 逐级放宽）② 设计滑动窗口检测算法 ③ 定义报警生命周期状态机（CREATED→DISPATCHED→CONFIRMED→RESOLVED，含超时自动升级逻辑）④ 三级协同机制（子女优先→社区介入→120 联动）

**场景二：数据库分区方案选型**

> 用户提出："体征数据量很大，每分钟一条，怎么存" → AI 对比分析 TDengine vs MySQL 分区表 vs TimescaleDB，最终基于统一技术栈和运维简洁性推荐 MySQL 8.0 RANGE 分区（按天）+ 降采样聚合表（小时粒度）方案，并生成完整的分区自动维护 Event 和降采样定时任务 SQL

---

> 本项目由 WorkBuddy AI 辅助开发完成。完整 AI 协作对话日志可通过项目内的设计文档追溯，各阶段的迭代记录（含 `.bak` / `.<date>` 备份文件）保存在对应模块的 `deploy/` 目录中。
