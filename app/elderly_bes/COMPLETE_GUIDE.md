# BES2800 智能手表应用开发完整指南

> **平台**: BES2800BP (best1700_ep) | **屏幕**: 454×454 圆形 AMOLED | **系统**: NuttX + LVGL v9

---

## 目录

```
一、项目架构与代码精简
  1.1 精简前后对比
  1.2 移除模块及原因
  1.3 Stub 设计模式
  1.4 最终文件清单

二、LVGL 应用开发
  2.1 启动流程
  2.2 项目结构与构建文件
  2.3 主入口模板
  2.4 页面管理器架构
  2.5 圆形显示适配
  2.6 LVGL v9 API 速查
  2.7 开机自启配置

三、WiFi 开发
  3.1 BES2800 WiFi 架构
  3.2 WiFi 管理器实现
  3.3 WiFi 设置页面 UI
  3.4 连接流程与命令

四、六轴传感器开发
  4.1 传感器选型：BMI270
  4.2 跌倒检测算法
  4.3 步数统计算法
  4.4 姿态识别算法
  4.5 传感器管理器实现
  4.6 硬件接入步骤

五、踩坑记录
  5.1 七大常见问题及修复

六、编译与调试
  6.1 完整编译流程
  6.2 调试技巧
```

---

## 一、项目架构与代码精简

### 1.1 精简前后对比

原始版本面向 SF32LB52（矩形 390×450），包含完整网络+传感器+后台线程。
精简版本面向 BES2800（圆形 454×454），保留完整 UI，用 stub 替代硬件依赖。

```
┌─────────────────────┬──────────────┬──────────────┬────────────┐
│ 文件                 │ 精简前行数    │ 精简后行数    │ 变化       │
├─────────────────────┼──────────────┼──────────────┼────────────┤
│ elderly_main.c      │ 223          │ 100          │ -55%       │
│ ui_manager.c        │ 169          │ 180          │ +6%        │
│ ui_index.c          │ 401          │ 460          │ +15% (圆形)│
│ ui_health_detail.c  │ 337          │ 345          │ +2%        │
│ ui_settings.c       │ 455          │ 500          │ +10%       │
│ ui_sos.c            │ 346          │ 365          │ +5%        │
│ data_collector.c    │ 600          │ 160          │ -73% (stub)│
│ http_client.c       │ 475          │ 删除          │ -100%      │
│ sensor_manager.c    │ 新增         │ 380          │ 新增       │
│ wifi_manager.c      │ 新增         │ 230          │ 新增       │
│ ui_wifi.c           │ 新增         │ 350          │ 新增       │
├─────────────────────┼──────────────┼──────────────┼────────────┤
│ 总计                │ ~3006        │ ~3896        │ +30%       │
│ 编译产物             │              │ 1.8MB        │            │
│ 栈大小              │ 64KB         │ 32KB         │ -50%       │
└─────────────────────┴──────────────┴──────────────┴────────────┘
```

### 1.2 移除模块及原因

```
┌────────────────────┬───────────────────────────────────────────────┐
│ 移除模块            │ 原因                                          │
├────────────────────┼───────────────────────────────────────────────┤
│ http_client.c      │ WiFi 通过 RPMSG 走 APC1，AP 侧无法直接 socket │
│                    │ 用 system("wapi ...") 代替                     │
├────────────────────┼───────────────────────────────────────────────┤
│ pthread 后台线程    │ 1) LVGL 非线程安全，跨线程调用崩溃              │
│ (collector_thread) │ 2) 每线程独立栈，内存紧张                       │
│                    │ 3) 改为主循环内 data_collector_update()         │
├────────────────────┼───────────────────────────────────────────────┤
│ 真实传感器读取      │ 初版用模拟验证 UI，BMI270 驱动就绪后再替换      │
└────────────────────┴───────────────────────────────────────────────┘
```

### 1.3 Stub 设计模式

`data_collector.c` 从 600 行精简为 160 行 stub，**保留全部接口**：

```c
// 保留的接口（UI 层无感知）
app_context_t *app_get_context(void);          // 全局上下文
void data_collector_init(void);                // 初始化静态数据
void data_collector_update(void);              // 集成传感器更新
void data_collector_trigger_sos(void);         // 触发报警 + 切换页面
bool data_collector_check_abnormal(const vital_data_t *v);  // 真实逻辑

// 体征状态辅助（UI 依赖）
const char *get_hr_status(int32_t hr);
lv_color_t get_hr_status_color(int32_t hr);
const char *get_spo2_status(int32_t spo2);
// ... temp 类似
```

**优势**：UI 层代码零改动，接入真实传感器时只需替换 stub 实现。

### 1.4 最终文件清单

```
apps/examples/elderly_bes/
├── Kconfig               58行   配置菜单
├── Makefile              25行   构建规则
├── Make.defs             23行   应用注册
├── CMakeLists.txt        30行   CMake 规则
│
├── elderly_main.c       100行   主入口（精简版）
├── ui_common.h          177行   公共定义 + 数据结构
│
├── ui_manager.c/.h      227行   页面管理器（5 页面）
├── ui_index.c/.h        501行   首页（SOS+体征+步数+姿态）
├── ui_health_detail.c/.h 373行  心率详情页
├── ui_settings.c/.h     500行   设置页（含 WiFi 入口）
├── ui_wifi.c/.h         466行   WiFi 设置页（扫描+连接）
├── ui_sos.c/.h          411行   SOS 报警页
│
├── sensor_manager.c/.h  514行   传感器（跌倒+步数+姿态）
├── wifi_manager.c/.h    346行   WiFi（扫描+连接+状态）
├── data_collector.c/.h  208行   数据层（stub + 传感器集成）
│
└── README_zh-cn.md       —      中文文档
```

---

## 二、LVGL 应用开发

### 2.1 启动流程

```
BES2800 上电
    │
    ▼
BootROM → OTA Bootloader → AP 入口
    │
    ▼
BSP 初始化 (libbeschip_ap.a)
├── PMU / Flash / I2C / 触摸 / LCD / eMMC / WiFi
└── 彩虹测试画面 → /dev/fb0
    │
    ▼
NuttX 内核 nx_start
├── 中断 / 内存 / 调度器
└── 设备驱动注册 (/dev/fb0, /dev/input0)
    │
    ▼
board_late_initialize() → eMMC 挂载 + VIDEO FB
    │
    ▼
NSH Shell → ROMFS init 脚本
├── rcS: if [ $wifi.rftest.mode != 1 ]; then elderly &; fi
└── elderly 进程启动
    │
    ▼
elderly main()
├── ① lv_init()
├── ② info.fb_path = "/dev/fb0"    ← BES2800 用 fb0，不是 lcd0
├── ③ info.input_path = "/dev/input0"
├── ④ lv_nuttx_init() → 创建显示+输入
├── ⑤ ui_manager_init() → 创建 5 个页面
├── ⑥ data_collector_init() → 初始化传感器
└── ⑦ while(1) { data_collector_update(); lv_timer_handler(); }
```

### 2.2 项目结构与构建文件

#### 四个必须文件

**Kconfig** — 配置菜单：

```kconfig
menuconfig EXAMPLES_ELDERLY_BES
    tristate "Elderly Health Care App (BES2800)"
    default n
    depends on GRAPHICS_LVGL

if EXAMPLES_ELDERLY_BES
config EXAMPLES_ELDERLY_BES_STACKSIZE
    int "Stack size"
    default 32768               # 纯 UI 32KB，有线程 64KB+
config EXAMPLES_ELDERLY_BES_SCREEN_WIDTH
    int "Screen width"
    default 454
endif
```

**Makefile**：

```makefile
include $(APPDIR)/Make.defs
PROGNAME  = elderly
PRIORITY  = $(CONFIG_EXAMPLES_ELDERLY_BES_PRIORITY)
STACKSIZE = $(CONFIG_EXAMPLES_ELDERLY_BES_STACKSIZE)
MODULE    = $(CONFIG_EXAMPLES_ELDERLY_BES)
CSRCS  = elderly_main.c ui_manager.c ui_index.c ...
include $(APPDIR)/Application.mk
```

**Make.defs**：

```makefile
ifneq ($(CONFIG_EXAMPLES_ELDERLY_BES),)
CONFIGURED_APPS += $(APPDIR)/examples/elderly_bes
endif
```

**CMakeLists.txt**：

```cmake
if(CONFIG_EXAMPLES_ELDERLY_BES)
  nuttx_add_application(NAME elderly PRIORITY ... STACKSIZE ...
    MODULE ... DEPENDS lvgl SRCS elderly_main.c ui_manager.c ...)
endif()
```

### 2.3 主入口模板

```c
#include <nuttx/config.h>
#include <unistd.h>
#include <sys/boardctl.h>
#include <lvgl/lvgl.h>

int main(int argc, FAR char *argv[])
{
  lv_nuttx_dsc_t info;
  lv_nuttx_result_t result;

  if (lv_is_initialized()) return -1;
  boardctl(BOARDIOC_INIT, 0);      // 板级初始化

  lv_init();                        // LVGL 核心初始化
  lv_nuttx_dsc_init(&info);         // NuttX 显示描述符

  // ★ 关键：根据板级选择显示设备
#ifdef CONFIG_LV_USE_NUTTX_LCD
  info.fb_path = "/dev/lcd0";       // LCD 驱动 (SF32LB52)
#elif defined(CONFIG_VIDEO_FB)
  info.fb_path = "/dev/fb0";        // 帧缓冲 (BES2800)
#endif

  info.input_path = "/dev/input0";  // 触摸设备

  lv_nuttx_init(&info, &result);    // 创建显示+输入
  if (result.disp == NULL) return 1;

  create_my_ui();                   // ★ 创建你的 UI

  while (1) {                       // 主事件循环
    uint32_t idle = lv_timer_handler();
    usleep((idle ? idle : 1) * 1000);
  }
}
```

### 2.4 页面管理器架构

```
┌─────────────────────────────────────────────┐
│              ui_manager (页面管理器)          │
│  · g_pages[PAGE_COUNT] 页面数组               │
│  · g_current 当前页面 ID                      │
│  · 左右滑动手势切换页面                       │
│  · SOS 报警时禁止滑动                        │
└────┬─────┬──────┬──────┬──────┬─────────────┘
     │     │      │      │      │
     ▼     ▼      ▼      ▼      ▼
  INDEX  HEALTH  SETT-   WIFI   SOS
  首页    详情    INGS    设置   报警
                  设置页   页    页
```

页面切换代码：

```c
// 隐藏当前页，显示目标页
void ui_manager_switch_page(page_id_t page)
{
  lv_obj_add_flag(g_pages[g_current], LV_OBJ_FLAG_HIDDEN);
  lv_obj_remove_flag(g_pages[page], LV_OBJ_FLAG_HIDDEN);
  g_current = page;

  if (page == PAGE_SETTINGS) ui_settings_sync_controls();
  if (page == PAGE_HEALTH_DETAIL) ui_health_detail_update();
  if (page == PAGE_WIFI) ui_wifi_refresh();
}
```

### 2.5 圆形显示适配

```
              454px
    ┌─────────────────────┐
    │     ╱─────────╲     │  ← 圆弧裁剪区域
    │   ╱  50px安全区 ╲   │
    │  │ ┌───────────┐ │  │
    │  │ │  354×354  │ │  │  内接正方形: 454/√2 ≈ 321px
    │  │ │  内容区域  │ │  │  安全边距: (454-321)/2 ≈ 66px
    │  │ │           │ │  │  实际使用: 50px (视觉可接受)
    │  │ └───────────┘ │  │
    │   ╲             ╱   │
    │     ╲─────────╱     │
    └─────────────────────┘
```

关键宏定义：

```c
#define SAFE_MARGIN    50
#define CONTENT_WIDTH  (SCREEN_WIDTH - 2 * SAFE_MARGIN)  // 354px
```

布局规则：
- 所有元素在 `CONTENT_WIDTH` 范围内
- 使用 `LV_ALIGN_TOP_MID` / `LV_ALIGN_CENTER` 居中
- 避免 `LV_ALIGN_TOP_LEFT`（会超出圆形边界）
- 深色主题（黑色背景 + 白色文字）适合 OLED

### 2.6 LVGL v9 API 速查

| 用途 | API |
|------|-----|
| 容器 | `lv_obj_create(parent)` |
| 按钮 | `lv_button_create(parent)` |
| 标签 | `lv_label_create(parent)` |
| 进度条 | `lv_bar_create(parent)` |
| 滑块 | `lv_slider_create(parent)` |
| 开关 | `lv_switch_create(parent)` |
| 文本框 | `lv_textarea_create(parent)` |
| 键盘 | `lv_keyboard_create(parent)` |
| 背景色 | `lv_obj_set_style_bg_color(obj, color, 0)` |
| 圆角 | `lv_obj_set_style_radius(obj, 12, 0)` |
| 文字字体 | `lv_obj_set_style_text_font(obj, &lv_font_montserrat_24, 0)` |
| Flex 布局 | `lv_obj_set_flex_flow(cont, LV_FLEX_FLOW_ROW)` |
| 居中 | `lv_obj_center(obj)` |
| 对齐 | `lv_obj_align(obj, LV_ALIGN_TOP_MID, 0, 50)` |
| 点击事件 | `lv_obj_add_event_cb(obj, cb, LV_EVENT_CLICKED, data)` |
| 活动屏幕 | `lv_screen_active()` |

### 2.7 开机自启配置

在板级 `rcS.ap` 中添加：

```c
// rcS.ap (C 预处理器文件)
#ifdef CONFIG_EXAMPLES_ELDERLY_BES
elderly &    // 后台启动
#elif defined(CONFIG_BESWATCH)
beswatch &
#else
lvgldemo widgets &
#endif
```

---

## 三、WiFi 开发

### 3.1 BES2800 WiFi 架构

```
┌──────────────────────────────────────────────────────┐
│                    BES2800BP SoC                      │
│                                                       │
│  ┌─────────────────┐    RPMSG      ┌───────────────┐ │
│  │   AP 核心        │ ◄══════════► │  APC1 核心     │ │
│  │  (Cortex-M55)    │  虚拟网卡    │  (WiFi 子系统) │ │
│  │                  │              │                │ │
│  │  wlan0 接口      │              │  WiFi 固件     │ │
│  │  TCP/IP 协议栈   │              │  RF 射频驱动   │ │
│  │  wapi 工具       │              │                │ │
│  └─────────────────┘              └───────────────┘ │
└──────────────────────────────────────────────────────┘
```

defconfig 已包含完整 WiFi 配置：

```
CONFIG_BES_WIFI_RPMSG_APC0C1=y        # RPMSG WiFi 通信
CONFIG_IEEE80211_BESTECHNIC_NETDEV_AX=y # BES WiFi 网络设备
CONFIG_WIRELESS_WAPI=y                 # wapi 命令行工具
CONFIG_NET=y / CONFIG_NET_TCP=y        # 网络协议栈
CONFIG_NETUTILS_DHCPC=y               # DHCP 客户端
```

### 3.2 WiFi 管理器实现

`wifi_manager.c` 通过 `popen()` 调用 `wapi` 命令：

```c
// 扫描 WiFi 网络
int wifi_manager_scan(void)
{
  run_cmd("ifup wlan0");              // 确保接口启用
  usleep(500000);

  for (int retry = 0; retry < 3; retry++) {
    if (run_cmd("wapi scan wlan0") == 0) break;
    usleep(1000000);                   // 失败重试
  }

  usleep(2000000);                     // 等待扫描完成
  char buf[2048];
  run_cmd_capture("wapi scan wlan0", buf, sizeof(buf));
  return parse_scan_output(buf);       // 解析 SSID/RSSI/加密
}

// 连接 WiFi
int wifi_manager_connect(const char *ssid, const char *password)
{
  char cmd[256];
  if (password[0])
    snprintf(cmd, sizeof(cmd), "wapi psk wlan0 \"%s\" \"%s\" 3", ssid, password);
  else
    snprintf(cmd, sizeof(cmd), "wapi psk wlan0 \"%s\" \"\" 0", ssid);

  run_cmd(cmd);
  run_cmd("ifup wlan0");
  run_cmd("renew wlan0");              // DHCP 获取 IP
  return 0;
}
```

### 3.3 WiFi 设置页面 UI

```
┌─────────────────────┐
│  ←  📶 WiFi         │  ← 返回按钮 + 标题
│  ┌───────────────┐  │
│  │ Connected     │  │  ← 状态卡片
│  │ MyWiFi  IP... │  │
│  └───────────────┘  │
│  [🔄 Scan] [✕ Disc] │  ← 扫描 + 断开按钮
│  ┌───────────────┐  │
│  │ 📶 Home_5G    │  │  ← 网络列表（可滚动）
│  │ 🔒 -45dBm    │  │
│  ├───────────────┤  │
│  │ 📶 Neighbor   │  │
│  │    -67dBm     │  │
│  └───────────────┘  │
└─────────────────────┘

点击加密网络 → 密码输入弹窗：
┌─────────────────────┐
│  Connect to:        │
│  Home_5G            │
│  [••••••••    👁]   │  ← 密码框 + 显示/隐藏
│  [✓Connect] [✕Canc] │  ← 连接/取消
│  ┌───────────────┐  │
│  │  软键盘        │  │  ← LVGL keyboard
│  └───────────────┘  │
└─────────────────────┘
```

### 3.4 连接流程

```bash
# NSH 手动连接
nsh> wapi psk wlan0 "MyWiFi" "password123" 3
nsh> ifup wlan0
nsh> renew wlan0
nsh> ping 8.8.8.8

# 应用内自动连接（WiFi 设置页）
# 1. Scan → 扫描网络列表
# 2. 点击网络 → 输入密码
# 3. Connect → wapi psk + ifup + renew
```

---

## 四、六轴传感器开发

### 4.1 传感器选型：BMI270

```
┌─────────────────────────────────────┐
│           BMI270 六轴传感器          │
│  ┌───────────┐  ┌───────────┐      │
│  │ 3轴加速度  │  │ 3轴陀螺仪  │      │
│  │ ±2/4/8/16g│  │ ±125~2000 │      │
│  │           │  │  °/s      │      │
│  └───────────┘  └───────────┘      │
│  接口: I2C (0x68) / SPI            │
│  功耗: <800μA                       │
│  封装: 2.5×3.0×0.8mm               │
│                                     │
│  ★ 内置步进计数器                    │
│  ★ 内置跌倒检测                      │
│  ★ 内置抬腕唤醒                      │
│  NuttX 已内置驱动 CONFIG_SENSORS_BMI270
└─────────────────────────────────────┘
```

**选择理由**：NuttX 内置驱动、超低功耗、内置步进计数+跌倒检测、智能手表标杆。

### 4.2 跌倒检测算法

检测模式：**自由落体 → 撞击**

```
加速度合值
    │
30  │                    ╱╲  ← 撞击 (>25 m/s²)
    │                   ╱  ╲
20  │                  ╱    ╲
    │                 ╱      ╲
 10 │────────────────╱        ╲──────
    │               ╱
  3 │─ ─ ─ ─ ─ ─ ╱─ ─ ─ ─ ─ ─ ─ ─  ← 自由落体阈值
    │            ↓
  0 │            自由落体开始
    └──────────────────────────────── 时间
              1.5s 窗口
```

```c
// 核心逻辑
if (magnitude < 3.0)         → 进入 FREEFALL 状态
if (magnitude > 25.0         → 进入 IMPACT 状态
  && 时间窗口 < 1.5s)         → 确认跌倒！
if (时间窗口 > 1.5s)          → 超时，恢复正常
```

参数：
| 参数 | 值 | 说明 |
|------|-----|------|
| `FREEFALL_THRESH` | 3.0 m/s² | 自由落体阈值 |
| `IMPACT_THRESH` | 25.0 m/s² | 撞击阈值 |
| `FALL_TIME_WINDOW` | 1500ms | 自由落体→撞击时间窗口 |
| `FALL_COOLDOWN` | 10000ms | 报警冷却时间 |

### 4.3 步数统计算法

基于加速度信号的**峰值检测**：

```
加速度合值 (去除重力)
    │
  3 │    ╱╲      ╱╲      ╱╲
    │   ╱  ╲    ╱  ╲    ╱  ╲
1.5 │──╱────╲──╱────╲──╱────╲──  ← 阈值
    │ ╱      ╲╱      ╲╱      ╲
  0 │╱
    └──────────────────────────── 时间
      步1    步2    步3    步4
      ←250ms→←250ms→←250ms→       最小步间隔
```

```c
delta = |magnitude - 9.81|;        // 去除重力
if (delta > 1.5 && !in_peak)       // 进入峰值
  in_peak = true;
if (delta < 0.75 && in_peak) {     // 离开峰值 → 计一步
  in_peak = false;
  if (interval > 250ms && interval < 2000ms)
    step_count++;
}
```

### 4.4 姿态识别算法

基于**重力方向**判断姿态：

```
姿态        加速度特征                  判定条件
──────────────────────────────────────────────────
站立        Z≈9.8, X≈0, Y≈0           az > 7 && |ax| < 4
坐姿        Z≈5-8 (倾斜)               az > 4 && az ≤ 7
平躺        Z≈0, Y≈9.8                 az < 3 && |ay| > 6
侧躺        X≈9.8                      |ax| > 6 && az < 3
行走        周期性变化 + 角速度>30°/s    gyro > 30 && 8<mag<12
```

使用**投票法平滑**（最近 4 次取众数）：

```c
posture_history[idx] = detected_posture;
idx = (idx + 1) % 4;
// 取 4 次中出现最多的姿态
```

### 4.5 传感器管理器实现

`sensor_manager.c` 架构：

```
sensor_manager_update()  ← 主循环每帧调用
    │
    ├─ generate_simulated_data()  ← 模拟模式（当前）
    │   或 read_bmi270()          ← 真实传感器（未来）
    │
    ├─ detect_fall()              跌倒检测
    ├─ detect_steps()             步数统计
    ├─ detect_posture()           姿态识别
    └─ calc_activity_level()      活动强度

模拟数据自动循环：
0-30s: 站立 → 30-60s: 行走 → 60-90s: 坐下
→ 90-120s: 行走 → 120-150s: 平躺（含跌倒模拟）
```

数据流：

```
sensor_manager → data_collector → ui_index (首页显示)
                       │
                       ├─ 步数 → 步数进度条
                       ├─ 姿态 → 姿态标签 "🚶 Walking"
                       ├─ 跌倒 → 自动触发 SOS 报警页
                       └─ 活动强度 → 卡路里估算
```

### 4.6 硬件接入步骤

```
步骤 1: 硬件接线
BMI270 模块 → BES1700 EVB I2C1
├── SDA → PA33
├── SCL → PA30
├── INT1 → GPIO (任意空闲)
├── VCC → 3.3V
└── GND → GND
I2C 地址: 0x68 (SDO 接 GND)

步骤 2: defconfig 配置
CONFIG_BES_I2C1=y
CONFIG_SENSORS=y
CONFIG_SENSORS_BMI270=y

步骤 3: NSH 验证
nsh> i2c dev 1              # 扫描 I2C1，应看到 0x68
nsh> sensortest /dev/sensor_accel0  # 读取加速度数据

步骤 4: 替换模拟数据
在 sensor_manager.c 中替换 generate_simulated_data()
为真实的 /dev/sensor_accel0 + /dev/sensor_gyro0 读取
```

---

## 五、踩坑记录

### 5.1 `/dev/lcd0` 不存在

```
现象: lv_nuttx_lcd_create: Error: cannot open lcd device: Error 2
原因: BES2800 用 VIDEO_FB (/dev/fb0)，不是 LCD 驱动 (/dev/lcd0)
修复: defconfig 移除 CONFIG_LV_USE_NUTTX_LCD=y
      代码: info.fb_path = "/dev/fb0"
```

### 5.2 栈溢出 (Stack Overflow)

```
现象: arm_usagefault: Stack Overflow
原因: pthread 后台线程吃栈 + LVGL UI 创建占用大量栈
修复: 移除 pthread，改为主循环内调用
      栈大小: 32KB (纯 UI) / 64KB+ (有线程)
```

### 5.3 NULL 指针崩溃 (MMFAR: 0x90)

```
现象: arm_memfault: Data access violation, MMFAR: 0x00000090
原因: 显示驱动未正确初始化，LVGL 访问 NULL display 对象
修复: 确保 fb_path 正确设置，lv_nuttx_init() 成功返回
```

### 5.4 `up_nputs` 多重定义

```
现象: multiple definition of 'up_nputs'
原因: BES BSP 库与 NuttX arch 库符号冲突
修复: Toolchain.cmake 添加:
      add_link_options(-Wl,--allow-multiple-definition)
```

### 5.5 FFmpeg 头文件缺失

```
现象: fatal error: libavutil/mem.h: No such file or directory
原因: CONFIG_MEDIA=y 依赖 FFmpeg，不在源码树中
修复: defconfig 移除 CONFIG_MEDIA=y / CONFIG_MEDIA_SERVER=y
```

### 5.6 `mk2cmake.py` 缺失

```
现象: python3: can't open file 'prebuild/mk2cmake.py'
原因: BES SDK 构建工具未包含
修复: 创建 /opt/openvela_2026/prebuild/mk2cmake.py
```

### 5.7 WiFi 扫描失败 (ENETDOWN)

```
现象: wapi_escan_channel_init: ioctl(SIOCSIWSCAN): 100
原因: wlan0 接口未就绪，WiFi 固件加载慢
修复: 扫描前先 ifup wlan0 + 等待 + 3次重试
```

---

## 六、编译与调试

### 6.1 完整编译流程

```bash
cd /opt/openvela_2026

# 编译 (使用官方脚本)
VELA_EXTRA_FLAGS="-Wno-cpp -Wno-deprecated-declarations \
  -Wno-format-overflow -Wno-format-truncation" \
  bash 1700_ap.sh

# 产物
ls -lh cmake_out/best1700_ep/aos_evb/out/nuttx_ap.bin
# → 1.8MB

# defconfig 关键配置
grep "ELDERLY\|LV_USE_NUTTX\|VIDEO_FB\|BMI270\|I2C1" \
  vendor/bes/boards/best1700_ep/aos_evb/configs/ap/defconfig
```

### 6.2 defconfig 关键配置

```bash
# === 显示 (BES2800 用 FB，不用 LCD) ===
CONFIG_VIDEO_FB=y
# CONFIG_LV_USE_NUTTX_LCD is not set

# === LVGL ===
CONFIG_GRAPHICS_LVGL=y
CONFIG_LV_USE_NUTTX=y
CONFIG_LV_USE_NUTTX_TOUCHSCREEN=y
CONFIG_LV_FONT_MONTSERRAT_14=y
CONFIG_LV_FONT_MONTSERRAT_16=y
CONFIG_LV_FONT_MONTSERRAT_20=y
# ... 24/28/32/36/38/40/48

# === 应用 ===
CONFIG_EXAMPLES_ELDERLY_BES=y
CONFIG_EXAMPLES_ELDERLY_BES_STACKSIZE=32768

# === 传感器 (接入 BMI270 后启用) ===
# CONFIG_BES_I2C1=y
# CONFIG_SENSORS=y
# CONFIG_SENSORS_BMI270=y
```

### 6.3 调试技巧

```bash
# 串口连接
picocom -b 921600 /dev/ttyACM0

# 定位崩溃 — 在关键位置加日志
LV_LOG_USER("[DEBUG] Step 1: lv_init done");
lv_nuttx_init(&info, &result);
LV_LOG_USER("[DEBUG] Step 2: disp=%p", result.disp);

# 栈溢出特征
# CFSR: 00100000 → STKOFLOV 位
# task: elderly → 崩溃进程名

# WiFi 调试
nsh> ifconfig              # 查看 wlan0 状态
nsh> wapi scan wlan0       # 手动扫描
nsh> ping 8.8.8.8          # 测试连通性
```

---

## 附录：页面导航全景图

```
┌─────────────────────────────────────────────────────────┐
│                                                          │
│   首页 ◄──── 左/右滑动 ────► 详情页                      │
│    │                            │                        │
│    │ 左滑                       │ 左滑                    │
│    ▼                            ▼                        │
│   详情页 ◄──────────────────► 设置页                     │
│                                │                         │
│                                │ 点击 WiFi               │
│                                ▼                         │
│                               WiFi 设置页                │
│                                │                         │
│                                │ ← 返回                  │
│                                ▼                         │
│                               设置页                     │
│                                                          │
│   任意页面 ──── 点击 SOS / 跌倒检测 ────► 报警页          │
│                                      │                   │
│                                      │ 取消/倒计时结束    │
│                                      ▼                   │
│                                     首页                 │
│                                                          │
└─────────────────────────────────────────────────────────┘
```
