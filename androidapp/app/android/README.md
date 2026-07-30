# AI老年健康守护 — 工程文档

---

## 一、项目配置

| 属性 | 值 |
|---|---|
| 应用名称 | `AI老年健康守护` |
| 包名 / applicationId | `com.example.elderlyhealth` |
| compileSdk / targetSdk / minSdk | `34` / `34` / `26` |
| Kotlin | `1.9.20` |
| Compose BOM | `2024.06.00` |
| AGP | `8.2.0` |
| 版本号 | `1.0.0` |
| API 地址 | `http://101.35.231.154/api/v1` |

---

## 二、核心依赖

- **Compose**: `material3`, `material-icons-extended`, `navigation-compose`, `hilt-navigation-compose`
- **Hilt DI**: `hilt-android 2.50`
- **Networking**: `Retrofit 2.9 + converter-gson`, `OkHttp 4.12 + logging-interceptor`
- **序列化**: `kotlinx-serialization-json 1.6.2`
- **图片**: `coil-compose 2.5`
- **持久化**: `datastore-preferences 1.0`

---

## 三、工程目录结构

```
app/src/main/java/com/example/elderlyhealth/
├── App.kt                          # Application 入口
├── MainActivity.kt                 # 单 Activity 宿主
├── di/
│   ├── NetworkModule.kt            # 提供 OkHttpClient、Retrofit、Gson、全部 Api 接口
│   └── RepositoryModule.kt         # 提供全部 Repository
├── data/
│   ├── api/                        # 9 个 Retrofit 接口
│   │   ├── AuthApi.kt              # auth/login、auth/refresh、auth/logout 等
│   │   ├── DashboardApi.kt         # dashboard/overview、device-online-rate、alarm-trend
│   │   ├── ElderlyApi.kt           # elderly CRUD、bindings CRUD
│   │   ├── VitalApi.kt             # vitals/realtime、history、overview
│   │   ├── AlarmApi.kt             # alarms CRUD、confirm、escalate、emergency、resolve
│   │   ├── SigninApi.kt            # signin/today、calendar、overview、proxy
│   │   ├── PatrolApi.kt            # patrol/tasks CRUD、records
│   │   ├── ReportApi.kt            # reports list、detail
│   │   └── DeviceApi.kt            # devices CRUD、bind、unbind、stats
│   ├── model/                      # 12 个数据模型文件
│   │   ├── AuthModels.kt           # LoginRequest/LoginResponse/UserInfo 等
│   │   ├── Common.kt               # ApiResponse<T>, Pagination, PaginatedData, Position
│   │   ├── ElderlyModels.kt        # ElderlyProfile, 嵌套的 DeviceBrief/VitalBaseline, NullXXX 包装
│   │   ├── DeviceModels.kt         # DeviceModels, DeviceRegisterRequest
│   │   ├── AlarmModels.kt          # AlarmItem, AlarmDetailData, ConfirmAlarmRequest 等
│   │   ├── SigninModels.kt         # TodaySigninStatus, SigninOverviewResponse, CalendarDay
│   │   ├── PatrolModels.kt         # PatrolTask, PatrolRecordRequest, PatrolCheckItems
│   │   ├── VitalModels.kt          # RealtimeVital, VitalHistoryResponse, VitalDataPoint
│   │   ├── ReportModels.kt         # ReportItem, ReportDetail
│   │   ├── DashboardModels.kt      # DashboardOverview, AlarmTrendResponse
│   │   └── WebSocketModels.kt      # WsMessage, WsVitalUpdate, WsAlarmNotify 等
│   ├── repository/                 # 10 个文件
│   │   ├── ApiCall.kt                # apiCall() / apiCallMap() 核心封装
│   │   ├── AuthRepository.kt        # login/smsLogin/sendSms/refresh/logout/saveSession
│   │   ├── ElderlyRepository.kt     # CRUD + bind/unbind
│   │   ├── DeviceRepository.kt      # CRUD + bind/unbind + stats
│   │   ├── AlarmRepository.kt       # list/detail/confirm/escalate/emergency/resolve
│   │   ├── VitalRepository.kt       # realtime/history/overview
│   │   ├── SigninRepository.kt      # today/calendar/overview/manual
│   │   ├── PatrolRepository.kt      # tasks/assign/submit/records
│   │   ├── ReportRepository.kt      # list/detail
│   │   └── DashboardRepository.kt   # overview/deviceTrend/alarmTrend
│   └── websocket/
│       └── ElderlyWebSocket.kt      # WebSocket 实时数据（未完全接入 UI）
├── ui/
│   ├── auth/
│   │   ├── LoginScreen.kt           # 密码/短信双模式登录
│   │   └── LoginViewModel.kt
│   ├── navigation/
│   │   ├── Screen.kt              # 全部路由定义（sealed class）
│   │   └── AppNavGraph.kt           # 路由 -> Composable 映射
│   ├── theme/
│   │   └── Theme.kt
│   ├── common/
│   │   ├── LineChart.kt             # Canvas 折线图组件
│   │   ├── VitalMetricCard.kt       # 体征指标卡片
│   │   └── LoadingState.kt          # 加载/错误/内容三态组件
│   ├── family/                     # 家属端（8 个屏幕）
│   │   ├── home/                    # 首页 -> 绑定老人列表 + 快捷入口
│   │   ├── vital/                   # 体征详情 + 趋势图
│   │   ├── alarm/                   # 报警详情 + 确认
│   │   ├── signin/                  # 签到日历
│   │   ├── report/                  # 报告列表 + 详情
│   │   └── bind/                    # 绑定老人
│   └── community/                  # 社区端（10 个屏幕）
│       ├── dashboard/               # 仪表盘概览 + 6 导航卡片
│       ├── alarm/                   # 报警看板 + 报警详情（可升级/呼救/确认）
│       ├── elderly/                 # 老人档案列表（本地姓名搜索）+ 详情 + 表单
│       ├── device/                  # 设备列表（在线离线筛选）+ 详情 + 注册/编辑
│       ├── signin/                  # 签到概览（统计）
│       ├── patrol/                  # 巡访任务列表 + 巡访记录提交 + 历史记录
│       └── trend/                   # 设备在线率 & 报警趋势
└── util/
    ├── TokenManager.kt              # DataStore 存取 token + userInfo
    ├── TokenInterceptor.kt          # OkHttp Interceptor, 注入 Bearer token
    ├── TokenRefreshAuthenticator.kt # OkHttp Authenticator, 401 时自动 refresh
    └── DateUtils.kt                 # ISO 8601 解析/格式化/年龄计算
```

---

## 四、关键架构说明

### 4.1 数据层
- **apiCall 封装**: `data/repository/ApiCall.kt`
  - `apiCall<T>(allowNullData, call)` — 统一解析 `ApiResponse<T>`，校验 `code==0 || code==200`
  - `apiCallMap<T,R>(call, mapper)` — 解析并映射（如提取 `data.list`）
  - 所有 Repository 方法通过此函数统一异常处理

- **服务端 Null 值处理**: 服务端返回 Go `sql.NullXXX` 格式（`{"String":"...","Valid":true}`）
  - 定义 `NullString/NullInt64/NullFloat64/NullTime` 包装类型
  - 老人详情 API 返回 `JsonElement`，手动反序列化为 `ElderlyDetailResponse` 再映射到 `ElderlyProfile`

### 4.2 认证体系

| 组件 | 职责 |
|---|---|
| `TokenManager` | DataStore 持久化 `access_token`, `refresh_token`, userInfo |
| `TokenInterceptor` | 每次请求自动添加 `Authorization: Bearer <token>` |
| `TokenRefreshAuthenticator` | 收到 401 后，synchronized 防并发，用 `refresh_token` 换新 token |

> 说明: `expiresIn` 字段存在于 `LoginResponse` 但**不参与主动过期判断**，完全依赖服务端 401 触发 TokenRefreshAuthenticator 刷新。

### 4.3 导航

- **路由定义**: `Screen.kt`（sealed class），每个路由附带 `createRoute()` 工厂方法
- **路由注册**: `AppNavGraph.kt`，`navArgument` 声明路径参数
- **共享屏幕**: 社区端复用家庭端的 `ReportListScreen`/`ReportDetailScreen`/`SigninCalendarScreen`
- **启动目的地**: `Screen.Login`

### 4.4 双角色

| 角色 | 入口 | 核心功能 |
|---|---|---|
| `family` | `FamilyHomeScreen` | 绑定老人列表、体征实时监控、签到日历、健康报告、报警确认 |
| `community` | `DashboardScreen` | 仪表盘、老人档案、设备管理、巡访管理、报警看板、签到统计、趋势分析 |

### 4.5 老人详情 API 映射

| 服务端字段 | 类型 | 映射目标 |
|---|---|---|
| `name` | `NullString` | `ElderlyProfile.name` |
| `age` | `NullInt64` | `ElderlyProfile.age` |
| `birth_date` | `NullTime` | `ElderlyProfile.birthDate` |
| `gender` | `NullString` | `ElderlyProfile.gender` |
| `phone` | `NullString` | `ElderlyProfile.phone` |
| `address` | `NullString` | `ElderlyProfile.address` |
| `heart_rate_baseline` | `NullString` | `VitalBaseline.heartRateMin/Max`（JSON 数组） |
| `temp_baseline` | `NullFloat64` | `VitalBaseline.tempMin/Max` |
| `spo2_baseline` | `NullFloat64` | `VitalBaseline.spo2Min` |
| `emergency_contact` | `NullString` | `EmergencyContact`（JSON 解析） |
| `medical_history` | `NullString` | `ElderlyProfile.medicalHistoryMeta`（JSON 字符串） |
| `bound_device_sn` | `NullString` | `DeviceBrief.deviceSn` |
| `bound_device_name` | `NullString` | 仅读取，当前未用 |
| `community_id` | `NullString` | `社区信息` |

---

## 五、API 端点速查

以下是 `GET elderly/{elderly_id}` 的实际返回字段（Go `sql.NullXXX` JSON 格式，使用时需注意 `Valid` 字段判断）：

- `elderly_id` — `NullString`
- `name` — `NullString`
- `phone` — `NullString`
- `gender` — `NullString` （`"male"` / `"female"`）
- `age` — `NullInt64`
- `birth_date` — `NullTime`（ISO 8601）
- `address` — `NullString`
- `community_id` — `NullString`
- `emergency_contact` — `NullString`（JSON: `{"name":"","phone":"","relation":""}`）
- `medical_history` — `NullString`（JSON: `{"hypertension":true,"diabetes":false,"heart_disease":"","allergies":[],"medications":[]}`）
- `bound_device_sn` — `NullString`
- `bound_device_name` — `NullString`
- `heart_rate_baseline` — `NullString`（JSON: `{"min":60,"max":100}`）
- `spo2_baseline` — `NullFloat64`
- `temp_baseline` — `NullFloat64`
- `bound_family` — `NullString`（JSON 数组）
- `status` — `NullString`

---

## 六、路由清单

| 路由 | 路径参数 | 屏幕 |
|---|---|---|
| `login` | 无 | `LoginScreen` |
| `family/home` | 无 | `FamilyHomeScreen` |
| `family/vital/{elderlyId}` | `elderlyId` | `VitalDetailScreen` |
| `family/alarm/{alarmId}` | `alarmId` | `FamilyAlarmScreen` |
| `family/signin/{elderlyId}` | `elderlyId` | `SigninCalendarScreen` |
| `family/reports/{elderlyId}` | `elderlyId` | `ReportListScreen` |
| `family/report/{reportId}` | `reportId` | `ReportDetailScreen` |
| `family/bind` | 无 | `BindElderlyScreen` |
| `community/dashboard` | 无 | `DashboardScreen` |
| `community/alarm_board` | 无 | `AlarmBoardScreen` |
| `community/alarm/{alarmId}` | `alarmId` | `CommunityAlarmDetailScreen` |
| `community/elderly` | 无 | `ElderlyListScreen` |
| `community/elderly/{elderlyId}` | `elderlyId` | `ElderlyDetailScreen` |
| `community/elderly/form/{elderlyId}` | `elderlyId` 或 `"new"` | `ElderlyFormScreen` |
| `community/devices` | 无 | `DeviceListScreen` |
| `community/device/{deviceId}` | `deviceId` | `DeviceDetailScreen` |
| `community/device/form/{deviceId}` | `deviceId` 或 `"new"` | `DeviceFormScreen` |
| `community/signin` | 无 | `CommunitySigninScreen` |
| `community/signin/{elderlyId}` | `elderlyId` | `SigninCalendarScreen` |
| `community/patrol` | 无 | `PatrolListScreen` |
| `community/patrol/record/{taskId}/{elderlyId}` | `taskId`, `elderlyId` | `PatrolRecordScreen` |
| `community/patrol/records` | 无 | `PatrolRecordListScreen` |
| `community/trend` | 无 | `TrendScreen` |
| `community/reports/{elderlyId}` | `elderlyId` | `ReportListScreen` |
| `community/report/{reportId}` | `reportId` | `ReportDetailScreen` |

---

## 七、已知问题

1. **无单元测试** — `src/test/` 和 `src/androidTest/` 目录不存在
2. **老人详情字段映射** — `tempBaseline`、`medicalHistoryMeta` 已补全但需接入数据验证
3. **未签到老人名单** — 社区签到页面未显示未签到老人列表（需后端补充列表 API）
4. **巡访记录列表** — `PatrolRecordListScreen` 仅占位

