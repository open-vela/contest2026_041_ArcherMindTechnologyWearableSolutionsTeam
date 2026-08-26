# OpenVela LVGL 应用开发指南 — 基于 BES2800 圆形表盘

> 本文档以「老年健康守护」应用为实例，完整记录从零开发 LVGL 应用的全过程，
> 包括精简策略、启动流程、踩坑记录和通用开发指南。

---

## 一、项目概览

### 1.1 硬件平台

```
┌─────────────────────────────────────────────┐
│            BES2800BP (best1700_ep)           │
│  ┌───────────────────────────────────────┐  │
│  │    Cortex-M55 + HiFi4 DSP            │  │
│  └───────────────────────────────────────┘  │
│  ┌──────────────┐  ┌───────────────────┐   │
│  │ RM69330 DSI   │  │ TMA525C 触摸      │   │
│  │ 454×454 圆形  │  │ I2C0              │   │
│  │ AMOLED        │  │ /dev/input0       │   │
│  │ /dev/fb0      │  │                   │   │
│  └──────────────┘  └───────────────────┘   │
│  ┌──────────────┐  ┌───────────────────┐   │
│  │ WiFi (RPMSG) │  │ eMMC              │   │
│  │ 16MB Flash    │  │ /dev/mmcsd0       │   │
│  └──────────────┘  └───────────────────┘   │
└─────────────────────────────────────────────┘
```

### 1.2 软件栈

```
┌─────────────────────────────────────────┐
│          elderly 应用 (用户空间)          │
│  ┌─────┐ ┌──────┐ ┌──────┐ ┌────────┐  │
│  │首页 │ │详情页│ │设置页│ │SOS报警 │  │
│  └──┬──┘ └──┬───┘ └──┬───┘ └───┬────┘  │
│     └───────┴────────┴─────────┘        │
│              ui_manager (页面管理器)      │
├─────────────────────────────────────────┤
│              LVGL v9 图形库              │
│   对象系统 | 样式系统 | 布局 | 事件      │
├─────────────────────────────────────────┤
│         NuttX 实时操作系统               │
│   调度 | 文件系统 | 驱动 | 网络          │
├─────────────────────────────────────────┤
│         BES2800 BSP (预编译库)           │
│   LCD驱动 | 触摸驱动 | Flash | WiFi     │
└─────────────────────────────────────────┘
```

---

## 二、精简策略

### 2.1 精简前后对比

```
精简前 (SF32LB52 版)                    精简后 (BES2800 版)
─────────────────────                   ─────────────────────
elderly_main.c    223行                  elderly_main.c     93行  ✓ 精简58%
ui_manager.c      169行                  ui_manager.c      169行  ✓ 保留
ui_index.c        401行                  ui_index.c        414行  ✓ 适配圆形
ui_health_detail  337行                  ui_health_detail  345行  ✓ 适配圆形
ui_settings.c     455行                  ui_settings.c     457行  ✓ 适配圆形
ui_sos.c          346行                  ui_sos.c          350行  ✓ 适配圆形
data_collector.c  600行 (后台线程+HTTP)   data_collector.c  125行  ✓ 精简79%
http_client.c     475行 (POSIX sockets)  http_client.c      删除  ✗ 移除
─────────────────────                   ─────────────────────
总计: ~3006行                            总计: ~2353行 (精简22%)
```

### 2.2 移除的模块及原因

```
┌──────────────────┬──────────────────────────────────────────┐
│ 移除模块          │ 原因                                      │
├──────────────────┼──────────────────────────────────────────┤
│ http_client.c    │ BES2800 无独立网络硬件，WiFi 通过 RPMSG    │
│                  │ 走 APc1 子系统，AP 侧无法直接 socket 通信  │
├──────────────────┼──────────────────────────────────────────┤
│ pthread 后台线程  │ 1) 吃栈空间（每线程需独立栈）               │
│ (collector_thread│ 2) LVGL 非线程安全，跨线程调用导致崩溃      │
│  heartbeat_thread│ 3) 精简后栈从 256KB→32KB，无空间开线程      │
├──────────────────┼──────────────────────────────────────────┤
│ HTTP 上传功能    │ 无网络 = 无法上传，保留接口但 stub 实现     │
├──────────────────┼──────────────────────────────────────────┤
│ 真实传感器读取    │ 初版用模拟数据验证 UI，后续再接入真实传感器  │
└──────────────────┴──────────────────────────────────────────┘
```

### 2.3 data_collector.c 的 Stub 设计

原始 `data_collector.c` 包含 600 行代码（线程、HTTP、传感器）。
精简为 125 行的 **stub**，保留接口但不执行实际操作：

```c
// 保留的接口（供 UI 层调用）
app_context_t *app_get_context(void);          // 返回全局上下文
void data_collector_init(void);                // 初始化静态数据
void data_collector_trigger_sos(void);         // 空实现
bool data_collector_check_abnormal(const vital_data_t *v);  // 真实逻辑

// 体征状态辅助函数（UI 层依赖）
const char *get_hr_status(int32_t hr);
lv_color_t get_hr_status_color(int32_t hr);
// ... spo2, temp 类似
```

这样 UI 层代码 **完全不需要改动**，后续接入真实传感器只需替换 stub 实现。

---

## 三、启动流程

### 3.1 完整启动链

```
┌─────────────────────────────────────────────────────────────┐
│                    BES2800 上电启动                           │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  BootROM → OTA Bootloader                                    │
│  · 选择 A/B 分区                                             │
│  · 跳转到 AP 代码入口 Boot_Loader                             │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  BSP 初始化 (libbeschip_ap.a + libbesboard_ap.a)            │
│  · PMU 电源管理                                              │
│  · Flash 初始化 (16MB NOR, XIP)                              │
│  · I2C0 总线                                                 │
│  · TMA525C 触摸驱动                                          │
│  · RM69330 LCD 初始化 (454×454 DSI)                          │
│  · eMMC 初始化                                               │
│  · WiFi/BT 固件加载                                          │
│  · 彩虹测试画面 → /dev/fb0                                   │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  NuttX 内核启动 (nx_start)                                   │
│  · 中断初始化                                                │
│  · 内存管理                                                  │
│  · 调度器启动                                                │
│  · 设备驱动注册 (/dev/fb0, /dev/input0, /dev/mmcsd0...)      │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  board_late_initialize()                                     │
│  · eMMC 分区挂载                                             │
│  · VIDEO FB 帧缓冲初始化                                     │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  NSH Shell 启动 → 执行 ROMFS init 脚本                       │
│                                                              │
│  /etc/init.d/rcS:                                            │
│    set +e                                                    │
│    uname -a > /dev/log                                       │
│    if [ $wifi.rftest.mode != 1 ]                             │
│    then                                                      │
│      elderly &    ← 自启我们的应用                            │
│    fi                                                        │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  elderly 进程启动 (main)                                     │
│  ① lv_init()                    初始化 LVGL 核心              │
│  ② lv_nuttx_dsc_init()          初始化 NuttX 显示描述符       │
│  ③ info.fb_path = "/dev/fb0"    设置帧缓冲路径               │
│  ④ info.input_path = "/dev/input0"  设置触摸设备              │
│  ⑤ lv_nuttx_init()              创建显示+输入设备              │
│  ⑥ ui_manager_init()            创建所有 UI 页面              │
│  ⑦ while(1) lv_timer_handler()  主事件循环                    │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  UI 渲染循环                                                 │
│  · lv_timer_handler() 处理动画、重绘、输入事件                 │
│  · LVGL 自动将脏区域刷新到 /dev/fb0                          │
│  · RM69330 LCD 驱动通过 DMA 传输帧到屏幕                      │
│  · usleep(idle * 1000) 空闲时休眠省电                        │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 elderly_main.c 核心代码

```c
int main(int argc, FAR char *argv[])
{
  lv_nuttx_dsc_t info;
  lv_nuttx_result_t result;

  /* ① 初始化 LVGL */
  lv_init();
  lv_nuttx_dsc_init(&info);

  /* ② 配置显示设备 */
  // BES2800 用 VIDEO_FB → /dev/fb0
  // SF32LB52 用 LCD 驱动 → /dev/lcd0
#ifdef CONFIG_LV_USE_NUTTX_LCD
  info.fb_path = "/dev/lcd0";
#elif defined(CONFIG_VIDEO_FB)
  info.fb_path = "/dev/fb0";
#endif

  /* ③ 配置触摸输入 */
  info.input_path = CONFIG_EXAMPLES_ELDERLY_BES_INPUT_DEVPATH;

  /* ④ 初始化 NuttX 显示驱动 */
  lv_nuttx_init(&info, &result);
  if (result.disp == NULL) return 1;  // 显示初始化失败

  /* ⑤ 创建 UI */
  ui_manager_init();

  /* ⑥ 主事件循环 */
  while (1) {
    uint32_t idle = lv_timer_handler();
    idle = idle ? idle : 1;
    usleep(idle * 1000);
  }
}
```

### 3.3 UI 页面架构

```
┌─────────────────────────────────────────────┐
│              ui_manager (页面管理器)          │
│  · 管理 4 个页面的创建、切换、生命周期        │
│  · 左右滑动手势切换页面                       │
│  · g_pages[PAGE_COUNT] 页面数组               │
│  · g_current 当前页面 ID                      │
└──────┬──────┬──────┬──────┬─────────────────┘
       │      │      │      │
       ▼      ▼      ▼      ▼
  ┌────────┐┌─────┐┌──────┐┌─────────┐
  │ INDEX  ││HEALTH││SETT- ││  SOS    │
  │ 首页   ││详情  ││INGS  ││ 报警页  │
  │        ││      ││设置页││         │
  │·SOS按钮││·心率 ││·亮度 ││·倒计时  │
  │·体征卡 ││ 大字 ││·间隔 ││·体征快照│
  │·步数条 ││·1h/  ││·开关 ││·位置    │
  │·健康状 ││ 6h/  ││·上传 ││·取消按钮│
  │ 态栏   ││ 24h  ││ 模式 ││·通知状态│
  │        ││·历史 ││·保存 ││         │
  └────────┘└─────┘└──────┘└─────────┘
```

---

## 四、圆形显示适配

### 4.1 安全边距计算

```
              454px
    ┌─────────────────────┐
    │     ╱─────────╲     │  ← 圆弧裁剪区域
    │   ╱  50px安全区 ╲   │
    │  │ ┌───────────┐ │  │
    │  │ │           │ │  │  内接正方形:
    │  │ │  354×354  │ │  │  454/√2 ≈ 321px
    │  │ │  内容区域  │ │  │  安全边距: (454-321)/2 ≈ 66px
    │  │ │           │ │  │  实际使用: 50px (视觉可接受)
    │  │ └───────────┘ │  │
    │   ╲             ╱   │
    │     ╲─────────╱     │
    └─────────────────────┘
```

### 4.2 布局策略

```c
// ui_common.h 中定义
#define SAFE_MARGIN    50    // 圆形安全边距
#define CONTENT_WIDTH  (SCREEN_WIDTH - 2 * SAFE_MARGIN)  // 354px

// 所有 UI 元素在 CONTENT_WIDTH 范围内布局
// 使用 LV_ALIGN_TOP_MID / LV_ALIGN_CENTER 居中对齐
// 避免使用 LV_ALIGN_TOP_LEFT（会超出圆形边界）
```

---

## 五、OpenVela LVGL 应用开发通用指南

### 5.1 项目结构

```
apps/examples/myapp/
├── Kconfig              # 配置菜单（必须）
├── Makefile             # NuttX Make 构建规则（必须）
├── Make.defs            # 应用注册（必须）
├── CMakeLists.txt       # CMake 构建规则（必须）
├── myapp_main.c         # 主入口（必须）
├── ui_xxx.c / .h        # UI 页面（按需）
└── data_xxx.c / .h      # 数据层（按需）
```

### 5.2 四个构建文件模板

**Kconfig** — 定义配置菜单：

```kconfig
menuconfig EXAMPLES_MYAPP
    tristate "My LVGL App"
    default n
    depends on GRAPHICS_LVGL        # 依赖 LVGL 库
    ---help---\
        My LVGL application description.

if EXAMPLES_MYAPP

config EXAMPLES_MYAPP_PRIORITY
    int "Task priority"
    default 100

config EXAMPLES_MYAPP_STACKSIZE
    int "Stack size"
    default 32768                   # 纯 UI 用 32KB
                                    # 有网络/线程用 64KB+

config EXAMPLES_MYAPP_SCREEN_WIDTH
    int "Screen width"
    default 454

config EXAMPLES_MYAPP_SCREEN_HEIGHT
    int "Screen height"
    default 454

endif
```

**Makefile**:

```makefile
include $(APPDIR)/Make.defs

PROGNAME  = myapp
PRIORITY  = $(CONFIG_EXAMPLES_MYAPP_PRIORITY)
STACKSIZE = $(CONFIG_EXAMPLES_MYAPP_STACKSIZE)
MODULE    = $(CONFIG_EXAMPLES_MYAPP)

CSRCS  = myapp_main.c
CSRCS += ui_page1.c
CSRCS += ui_page2.c

include $(APPDIR)/Application.mk
```

**Make.defs**:

```makefile
ifneq ($(CONFIG_EXAMPLES_MYAPP),)
CONFIGURED_APPS += $(APPDIR)/examples/myapp
endif
```

**CMakeLists.txt**:

```cmake
if(CONFIG_EXAMPLES_MYAPP)
  nuttx_add_application(
    NAME myapp
    PRIORITY ${CONFIG_EXAMPLES_MYAPP_PRIORITY}
    STACKSIZE ${CONFIG_EXAMPLES_MYAPP_STACKSIZE}
    MODULE ${CONFIG_EXAMPLES_MYAPP}
    DEPENDS lvgl
    SRCS myapp_main.c ui_page1.c ui_page2.c)
endif()
```

### 5.3 主入口模板

```c
#include <nuttx/config.h>
#include <unistd.h>
#include <sys/boardctl.h>
#include <lvgl/lvgl.h>

#undef NEED_BOARDINIT
#if defined(CONFIG_BOARDCTL) && !defined(CONFIG_NSH_ARCHINIT)
#  define NEED_BOARDINIT 1
#endif

int main(int argc, FAR char *argv[])
{
  lv_nuttx_dsc_t info;
  lv_nuttx_result_t result;

  if (lv_is_initialized()) return -1;

#ifdef NEED_BOARDINIT
  boardctl(BOARDIOC_INIT, 0);
#endif

  lv_init();
  lv_nuttx_dsc_init(&info);

  /* 显示设备 — 根据板级配置选择 */
#ifdef CONFIG_LV_USE_NUTTX_LCD
  info.fb_path = "/dev/lcd0";        // LCD 驱动 (SF32LB52 等)
#elif defined(CONFIG_VIDEO_FB)
  info.fb_path = "/dev/fb0";         // 帧缓冲 (BES2800 等)
#endif

  /* 触摸输入 */
#ifdef CONFIG_INPUT_TOUCHSCREEN
  info.input_path = "/dev/input0";
#endif

  lv_nuttx_init(&info, &result);
  if (result.disp == NULL) return 1;

  /* ===== 创建你的 UI ===== */
  create_my_ui(lv_screen_active());

  /* 主事件循环 */
  while (1) {
    uint32_t idle = lv_timer_handler();
    idle = idle ? idle : 1;
    usleep(idle * 1000);
  }

  lv_nuttx_deinit(&result);
  lv_deinit();
  return 0;
}
```

### 5.4 LVGL v9 常用 API 速查

#### 创建对象

```c
lv_obj_t *cont  = lv_obj_create(parent);      // 容器
lv_obj_t *btn   = lv_button_create(parent);   // 按钮
lv_obj_t *lbl   = lv_label_create(parent);    // 标签
lv_obj_t *bar   = lv_bar_create(parent);      // 进度条
lv_obj_t *sld   = lv_slider_create(parent);   // 滑块
lv_obj_t *sw    = lv_switch_create(parent);   // 开关
lv_obj_t *img   = lv_image_create(parent);    // 图片
```

#### 样式设置

```c
// 背景
lv_obj_set_style_bg_color(obj, lv_color_hex(0x1A1A1A), 0);
lv_obj_set_style_bg_opa(obj, LV_OPA_COVER, 0);

// 圆角
lv_obj_set_style_radius(obj, 12, 0);

// 边框
lv_obj_set_style_border_width(obj, 0, 0);

// 内边距
lv_obj_set_style_pad_all(obj, 8, 0);

// 文字
lv_obj_set_style_text_color(obj, lv_color_hex(0xFFFFFF), 0);
lv_obj_set_style_text_font(obj, &lv_font_montserrat_24, 0);

// 按下态变色
lv_obj_set_style_bg_color(obj, COLOR_PRESSED, LV_STATE_PRESSED);
```

#### 布局定位

```c
// 绝对定位
lv_obj_align(obj, LV_ALIGN_TOP_MID, 0, 50);     // 顶部居中
lv_obj_align(obj, LV_ALIGN_CENTER, 0, 0);        // 正中
lv_obj_align(obj, LV_ALIGN_BOTTOM_MID, 0, -20);  // 底部居中

// Flex 弹性布局
lv_obj_set_flex_flow(cont, LV_FLEX_FLOW_ROW);    // 水平排列
lv_obj_set_flex_flow(cont, LV_FLEX_FLOW_COLUMN); // 垂直排列
lv_obj_set_flex_align(cont,
  LV_FLEX_ALIGN_SPACE_EVENLY,  // 主轴均匀分布
  LV_FLEX_ALIGN_CENTER,        // 交叉轴居中
  LV_FLEX_ALIGN_CENTER);       // 基线居中
```

#### 事件处理

```c
// 点击事件
lv_obj_add_event_cb(btn, my_cb, LV_EVENT_CLICKED, user_data);

// 长按事件
lv_obj_add_event_cb(btn, my_cb, LV_EVENT_LONG_PRESSED, NULL);

// 值变化事件 (滑块/开关)
lv_obj_add_event_cb(slider, my_cb, LV_EVENT_VALUE_CHANGED, NULL);

// 回调函数
static void my_cb(lv_event_t *e)
{
  lv_obj_t *target = lv_event_get_target(e);
  void *data = lv_event_get_user_data(e);
  // ...
}
```

### 5.5 defconfig 关键配置项

```bash
# === LVGL 核心 ===
CONFIG_GRAPHICS_LVGL=y
CONFIG_LV_USE_NUTTX=y
CONFIG_LV_USE_NUTTX_TOUCHSCREEN=y
CONFIG_LV_COLOR_DEPTH_32=y
CONFIG_LV_MEM_SIZE_KILOBYTES=2048
CONFIG_LV_FONT_MONTSERRAT_14=y
CONFIG_LV_FONT_MONTSERRAT_20=y
CONFIG_LV_FONT_MONTSERRAT_24=y
CONFIG_LV_FONT_MONTSERRAT_28=y
CONFIG_LV_FONT_MONTSERRAT_36=y

# === 显示 (二选一) ===
# 方式 A: LCD 驱动 (SF32LB52 等)
CONFIG_LCD=y
CONFIG_LV_USE_NUTTX_LCD=y

# 方式 B: 帧缓冲 (BES2800 等)
CONFIG_VIDEO_FB=y
# 不要开 CONFIG_LV_USE_NUTTX_LCD!

# === 触摸 ===
CONFIG_INPUT=y
CONFIG_INPUT_TOUCHSCREEN=y

# === 应用 ===
CONFIG_EXAMPLES_MYAPP=y
CONFIG_EXAMPLES_MYAPP_STACKSIZE=32768
```

### 5.6 编译命令

```bash
cd /opt/openvela_2026

# BES2800 (best1700_ep)
VELA_EXTRA_FLAGS="-Wno-cpp -Wno-deprecated-declarations" \
  bash 1700_ap.sh

# 其他板子 (通用)
./build.sh <board_config_path> --cmake

# 产物位置
# BES2800: cmake_out/best1700_ep/aos_evb/out/nuttx_ap.bin
# 通用:    cmake_out/<board>_<config>/nuttx.bin
```

### 5.7 开机自启配置

在板级 `rcS` 或 `rcS.ap` 中添加：

```bash
# 条件自启 (推荐)
#ifdef CONFIG_EXAMPLES_MYAPP
myapp &
#endif
```

或者在 `rcS.last` 中无条件添加：

```bash
myapp &
```

---

## 六、BES2800 适配踩坑记录

### 6.1 坑 1: `/dev/lcd0` 不存在

```
现象: lv_nuttx_lcd_create: Error: cannot open lcd device: Error 2
原因: BES2800 用 VIDEO_FB (/dev/fb0)，不是 LCD 驱动 (/dev/lcd0)
修复: defconfig 移除 CONFIG_LV_USE_NUTTX_LCD=y
      代码中用 CONFIG_VIDEO_FB 判断设置 fb_path="/dev/fb0"
```

### 6.2 坑 2: 栈溢出 (Stack Overflow)

```
现象: arm_usagefault: Stack Overflow
原因: 1) data_collector 创建 pthread 吃栈
      2) LVGL UI 创建占用大量栈空间
      3) 64KB 栈不够
修复: 1) 移除 pthread 后台线程
      2) 栈大小 32KB (精简后足够)
      3) 精简前需要 128KB+
```

### 6.3 坑 3: NULL 指针崩溃 (MMFAR: 0x90)

```
现象: arm_memfault: Data access violation, MMFAR: 0x00000090
原因: 显示驱动未正确初始化，LVGL 内部访问 NULL display 对象
修复: 确保 fb_path 正确设置，lv_nuttx_init() 成功返回
```

### 6.4 坑 4: `up_nputs` 多重定义

```
现象: multiple definition of 'up_nputs'
原因: BES BSP 库 libbeschip_ap.a 与 NuttX arch 库符号冲突
修复: Toolchain.cmake 添加 add_link_options(-Wl,--allow-multiple-definition)
```

### 6.5 坑 5: FFmpeg 头文件缺失

```
现象: fatal error: libavutil/mem.h: No such file or directory
原因: CONFIG_MEDIA=y 依赖 FFmpeg，但 FFmpeg 库不在源码树中
修复: defconfig 移除 CONFIG_MEDIA=y / CONFIG_MEDIA_SERVER=y
      (elderly 应用不需要多媒体框架)
```

### 6.6 坑 6: mk2cmake.py 缺失

```
现象: python3: can't open file 'prebuild/mk2cmake.py'
原因: BES SDK 构建工具未包含在源码树中
修复: 创建 /opt/openvela_2026/prebuild/mk2cmake.py
      将 board_cfg.mk 转换为 board_cfg.cmake
```

### 6.7 坑 7: 字体缺失

```
现象: 'lv_font_montserrat_16' undeclared
原因: defconfig 只启用了部分字体大小
修复: 添加 CONFIG_LV_FONT_MONTSERRAT_14=y
      添加 CONFIG_LV_FONT_MONTSERRAT_16=y
```

---

## 七、调试技巧

### 7.1 串口日志

```bash
# BES2800 USB 串口
picocom -b 921600 /dev/ttyACM0

# LVGL 日志会带 [LVGL] 前缀
# 应用日志用 LV_LOG_USER() / LV_LOG_ERROR()
```

### 7.2 定位崩溃

在关键位置添加日志：

```c
LV_LOG_USER("[DEBUG] Step 1: lv_init done");
lv_nuttx_init(&info, &result);
LV_LOG_USER("[DEBUG] Step 2: lv_nuttx_init done, disp=%p", result.disp);
ui_manager_init();
LV_LOG_USER("[DEBUG] Step 3: UI created");
```

### 7.3 栈溢出检测

NuttX 支持栈溢出检测（ARM MPU）。崩溃日志中的关键字段：

```
CFSR: 00100000           ← STKOFLOV 位，确认是栈溢出
Stack Overflow           ← 明确提示
task: elderly            ← 崩溃的进程名
```

---

## 八、文件清单

```
apps/examples/elderly_bes/
├── Kconfig              58行   配置菜单
├── Makefile             20行   构建规则
├── Make.defs            23行   应用注册
├── CMakeLists.txt       25行   CMake 规则
├── elderly_main.c       93行   主入口 (精简版)
├── ui_common.h         177行   公共定义 + 数据结构
├── ui_manager.c/.h     216行   页面管理器
├── ui_index.c/.h       455行   首页
├── ui_health_detail    373行   心率详情页
├── ui_settings.c/.h    485行   设置页
├── ui_sos.c/.h         396行   SOS 报警页
├── data_collector.c    125行   数据层 (stub)
├── data_collector.h     48行   数据层接口
├── README_zh-cn.md      —      中文文档
└── defconfig_snippet    —      defconfig 片段
```
