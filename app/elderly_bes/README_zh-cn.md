# AI 老年健康守护系统 — BES2800 LVGL 应用

基于 LVGL 的老年健康监测与 SOS 报警应用，运行在 **BES2800BP** (best1700_ep) 开发板上，适配 **454×454 圆形 AMOLED** 表盘。

---

## 一、硬件平台

| 项目 | 规格 |
|------|------|
| 芯片 | BES2800BP（Cortex-M55 + HiFi4 DSP） |
| SDK 代号 | `best1700_ep` |
| 屏幕 | RM69330 DSI 圆形 AMOLED，454×454 像素 |
| 触摸 | TMA525C 电容触控 |
| 网络 | Wi-Fi（已启用） |
| 控制台 | USB 串口 |

---

## 二、编译步骤

### 2.1 前置条件

- OpenVela 源码树（`dev-ai-contest-2026` 分支）
- ARM 交叉编译工具链
- CMake 3.20+ / Ninja
- 应用源码位于 `apps/examples/elderly_bes/`

### 2.2 启用应用

需要在 defconfig 中启用老年健康应用。在 `vendor/bes/boards/best1700_ep/aos_evb/configs/ap/defconfig` 中添加：

```
CONFIG_EXAMPLES_ELDERLY_BES=y
```

或通过 menuconfig 启用：

```bash
cd /opt/openvela_2026

# 先配置 BES1700 AP
source build/envsetup.sh
lunch vendor/bes/boards/best1700_ep/aos_evb/configs/ap cmake_out/bes1700_ap

# 进入 menuconfig 启用应用
cd cmake_out/bes1700_ap
ninja menuconfig
# 搜索 "elderly" → 启用 "Elderly Health Care App (BES2800)"

# 保存配置
ninja savedefconfig
```

### 2.3 编译

```bash
cd /opt/openvela_2026

# 方法一：使用 build.sh（推荐）
./build.sh vendor/bes/boards/best1700_ep/aos_evb/configs/ap --cmake

# 方法二：手动 cmake
source build/envsetup.sh
lunch vendor/bes/boards/best1700_ep/aos_evb/configs/ap cmake_out/bes1700_ap
m
```

编译产物：`cmake_out/bes1700_ap/nuttx.bin`

### 2.4 烧录

USB 连接开发板，使用 BES 提供的烧录工具：

```bash
# 具体烧录命令参考 BES 文档
# 通常通过 USB DFM 或 JTAG 烧录
```

### 2.5 串口连接

```bash
# BES1700 使用 USB 串口控制台
picocom -b 921600 /dev/ttyACM0
```

### 2.6 启动应用

NuttX Shell 启动后输入：

```
nsh> elderly
```

---

## 三、圆形表盘适配说明

### 3.1 关键改动

| 改动项 | 原始值（矩形 SF32LB52） | 新值（圆形 BES2800） |
|--------|------------------------|---------------------|
| 屏幕尺寸 | 390×450 | 454×454 |
| 安全边距 | 12px | 50px |
| SOS 按钮 | 140px | 120px |
| 体征卡片宽度 | ~115px | 95px |
| 配置前缀 | `EXAMPLES_ELDERLY` | `EXAMPLES_ELDERLY_BES` |

### 3.2 圆形显示安全区域

454px 圆形屏幕的内接正方形边长 ≈ 321px，安全边距 50px 确保内容不被圆弧裁剪：

```
         ┌─────────────┐
       ╱   50px 安全区   ╲
      │  ┌─────────────┐  │
      │  │  内容区域    │  │
      │  │  354×354    │  │
      │  └─────────────┘  │
       ╲                 ╱
         └─────────────┘
```

### 3.3 字体

BES2800 defconfig 已包含 Montserrat 字体 20/22/24/28/32/36/38/40/48，无需额外配置。

---

## 四、Kconfig 配置项

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `EXAMPLES_ELDERLY_BES` | n | 启用应用 |
| `EXAMPLES_ELDERLY_BES_PRIORITY` | 100 | 任务优先级 |
| `EXAMPLES_ELDERLY_BES_STACKSIZE` | 65536 | 栈大小（字节） |
| `EXAMPLES_ELDERLY_BES_INPUT_DEVPATH` | `/dev/input0` | 触摸设备路径 |
| `EXAMPLES_ELDERLY_BES_SCREEN_WIDTH` | 454 | 屏幕宽度 |
| `EXAMPLES_ELDERLY_BES_SCREEN_HEIGHT` | 454 | 屏幕高度 |
| `EXAMPLES_ELDERLY_BES_SERVER_URL` | `http://101.35.231.154/api/v1` | 后端 API |
| `EXAMPLES_ELDERLY_BES_DEVICE_SN` | `EH-WATCH-BES2800` | 设备序列号 |
| `EXAMPLES_ELDERLY_BES_DEFAULT_INTERVAL` | 10 | 采集间隔（秒） |

---

## 五、网络说明

BES2800 开发板 **内置 Wi-Fi**，HTTP 客户端默认启用。需要：

1. 确保 defconfig 中包含 `CONFIG_NET=y`、`CONFIG_NET_TCP=y`（已默认启用）
2. 连接 Wi-Fi 后应用自动上传数据

---

## 六、功能一览

- **实时体征**：心率、血氧、体温（模拟数据模式）
- **SOS 呼救**：长按触发，10 秒倒计时
- **步数统计**：每日 6000 步目标
- **健康详情**：心率历史，1h/6h/24h 切换
- **设置页面**：亮度、采集间隔、功能开关
- **数据上传**：HTTP POST 到后端 API
- **左/右滑动**：页面切换
