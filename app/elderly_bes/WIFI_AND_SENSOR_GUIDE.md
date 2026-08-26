# BES2800 WiFi 连接 & 六轴传感器接入指南

---

## 一、WiFi 连接

### 1.1 BES2800 WiFi 架构

```
┌─────────────────────────────────────────────────────────┐
│                    BES2800BP SoC                         │
│                                                          │
│  ┌──────────────────┐    RPMSG     ┌──────────────────┐ │
│  │   AP 核心         │ ◄══════════► │  APC1 核心        │ │
│  │  (Cortex-M55)     │   虚拟网卡   │  (WiFi 子系统)    │ │
│  │                   │              │                   │ │
│  │  wlan0 网络接口   │              │  WiFi 固件        │ │
│  │  TCP/IP 协议栈    │              │  驱动 RF 射频     │ │
│  │  NuttX 网络应用   │              │  管理连接         │ │
│  └──────────────────┘              └──────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

WiFi 通过 **RPMSG**（核间通信）运行在 APC1 核心上，AP 核心通过虚拟网络接口 `wlan0` 访问网络。defconfig 中已包含完整 WiFi 配置：

```
CONFIG_BES_WIFI_RPMSG_APC0C1=y      # RPMSG WiFi 通信
CONFIG_IEEE80211_BESTECHNIC_NETDEV_AX=y  # BES WiFi 网络设备
CONFIG_DRIVERS_IEEE80211=y           # IEEE 802.11 驱动
CONFIG_WIRELESS_WAPI=y               # WiFi API 工具
CONFIG_WIRELESS_WAPI_CMDTOPLINE=y    # wapi 命令行工具
CONFIG_NET=y                         # 网络协议栈
CONFIG_NET_TCP=y / CONFIG_NET_UDP=y
CONFIG_NETUTILS_DHCPC=y              # DHCP 客户端
CONFIG_NETDB_DNSCLIENT=y             # DNS 客户端
```

### 1.2 WiFi 连接步骤

在 NSH Shell 中执行：

```bash
# ① 查看无线网络接口
nsh> ifconfig
# 应该能看到 wlan0 接口（WiFi 初始化后自动出现）

# ② 扫描周围的 WiFi 网络
nsh> wapi scan wlan0
# 或
nsh> wapi scan wlan0 verbose

# ③ 连接 WiFi 热点
# WPA2/WPA3 加密网络：
nsh> wapi psk wlan0 "你的WiFi名称" "你的WiFi密码" 3
# 参数说明: 3 = WPA2/WPA3 混合模式

# 开放网络（无密码）：
nsh> wapi psk wlan0 "你的WiFi名称" "" 0

# ④ 启用网络接口
nsh> ifup wlan0

# ⑤ 获取 IP 地址 (DHCP)
nsh> renew wlan0
# 或设置静态 IP：
nsh> ifconfig wlan0 192.168.1.100

# ⑥ 设置 DNS 服务器
nsh> echo "nameserver 8.8.8.8" > /etc/resolv.conf

# ⑦ 测试连接
nsh> ping 8.8.8.8
nsh> ping baidu.com
```

### 1.3 开机自动连接 WiFi

在 `rcS.ap` 中添加（在 `elderly &` 之前）：

```bash
# WiFi 自动连接
#ifdef CONFIG_EXAMPLES_ELDERLY_BES
wapi psk wlan0 "YourSSID" "YourPassword" 3
ifup wlan0
renew wlan0
#endif

elderly &
```

### 1.4 在应用中使用网络

WiFi 连接成功后，应用可直接使用 POSIX socket API：

```c
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

int fd = socket(AF_INET, SOCK_STREAM, 0);
struct hostent *he = gethostbyname("api.example.com");
// ... 标准 socket 编程
```

---

## 二、六轴姿态传感器推荐

### 2.1 推荐方案对比

| 型号 | 厂商 | 接口 | 功耗 | NuttX 驱动 | 推荐度 | 备注 |
|------|------|------|------|-----------|--------|------|
| **BMI270** | Bosch | I2C/SPI | **超低** | ✅ 内置 | ⭐⭐⭐⭐⭐ | **首选**，智能手表标杆 |
| BMI160 | Bosch | I2C/SPI | 低 | ✅ 内置 | ⭐⭐⭐⭐ | 成熟方案，已停产 |
| LSM6DSO | ST | I2C/SPI | 低 | ❌ 需移植 | ⭐⭐⭐ | ST 生态好，需写驱动 |
| MPU6050 | TDK | I2C | 中 | ✅ 内置(mpu60x0) | ⭐⭐ | 老旧，精度一般 |
| SC7A20 | 士兰微 | I2C | 低 | ❌ 需移植 | ⭐⭐ | 国产便宜，仅 3 轴加速度 |

### 2.2 首选：BMI270

```
┌─────────────────────────────────────┐
│           BMI270 六轴传感器          │
│                                     │
│  ┌───────────┐  ┌───────────┐      │
│  │ 3轴加速度  │  │ 3轴陀螺仪  │      │
│  │ ±2/4/8/16g│  │ ±125~2000 │      │
│  │           │  │  °/s      │      │
│  └───────────┘  └───────────┘      │
│                                     │
│  接口: I2C (地址 0x68/0x69)         │
│        SPI (最高 10MHz)              │
│  电压: 1.71V ~ 3.6V                 │
│  封装: 2.5×3.0×0.8mm LGA            │
│  功耗: 加速度 685μA                  │
│        陀螺仪 685μA                  │
│        低功耗模式 < 800μA            │
│                                     │
│  特性:                              │
│  · 内置步进计数器                    │
│  · 内置跌倒检测                      │
│  · 内置手势识别                      │
│  · 内置抬腕唤醒                      │
│  · FIFO 缓冲区 (2KB)                │
└─────────────────────────────────────┘
```

**选择理由：**
1. NuttX 已内置完整驱动（含 uORB 支持）
2. Bosch 智能手表/手环市场占有率最高
3. 超低功耗，适合可穿戴设备
4. 内置步进计数器和跌倒检测（正好匹配 elderly 应用需求）
5. 2.5×3mm 小封装，适合表盘 PCB

---

## 三、BMI270 硬件接线

### 3.1 I2C 连接（推荐）

```
BES2800 EVB                    BMI270 模块
┌─────────────┐               ┌─────────────┐
│             │               │             │
│  I2C0 SDA ──┼────── SDA ────┤ SDA    BMI270│
│  I2C0 SCL ──┼────── SCL ────┤ SCL         │
│  GPIO (INT) ─┼────── INT1 ───┤ INT1        │
│  3.3V ───────┼────── VCC ────┤ VCC         │
│  GND ────────┼────── GND ────┤ GND         │
│             │               │             │
└─────────────┘               └─────────────┘

I2C 地址: 0x68 (SDO 接 GND) 或 0x69 (SDO 接 VCC)
```

### 3.2 BES1700 EVB 可用引脚

```
I2C0 已占用: TMA525C 触摸屏 (地址 0x20)
I2C1 可用:   PA33(SDA) / PA30(SCL)  ← 接 BMI270

中断引脚:    任意 GPIO（如 PA34/KEY1 或空闲 GPIO）
```

> ⚠️ **注意**：I2C0 已被触摸屏占用，BMI270 必须接 **I2C1**。

---

## 四、软件集成步骤

### 4.1 defconfig 添加配置

```bash
# 在 vendor/bes/boards/best1700_ep/aos_evb/configs/ap/defconfig 中添加

# === I2C1 总线 ===
CONFIG_BES_I2C1=y

# === NuttX 传感器框架 ===
CONFIG_SENSORS=y

# === BMI270 驱动 ===
CONFIG_SENSORS_BMI270=y
CONFIG_SENSORS_BMI270_UORB=y

# === 可选: uORB 传感器总线 ===
CONFIG_UORB=y
```

### 4.2 驱动注册（板级初始化）

在 `vendor/bes/boards/best1700_ep/aos_evb/src/ap.c` 中添加 BMI270 初始化：

```c
#include <nuttx/sensors/bmi270.h>

/* BMI270 I2C 配置 */
#define BMI270_I2C_BUS    1       /* I2C1 */
#define BMI270_I2C_ADDR   0x68   /* SDO 接 GND */
#define BMI270_INT_GPIO   GPIO_PIN34  /* 中断引脚 */

int board_bmi270_init(void)
{
  struct i2c_master_s *i2c;
  int ret;

  /* 获取 I2C1 总线 */
  i2c = up_i2cinitialize(BMI270_I2C_BUS);
  if (i2c == NULL)
    {
      syslog(LOG_ERR, "Failed to init I2C1\n");
      return -ENODEV;
    }

  /* 注册 BMI270 驱动 */
  ret = bmi270_register(i2c, BMI270_I2C_ADDR);
  if (ret < 0)
    {
      syslog(LOG_ERR, "BMI270 register failed: %d\n", ret);
    }

  return ret;
}
```

### 4.3 在 elderly 应用中读取传感器数据

```c
#include <nuttx/sensors/sensor.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>

/* 传感器数据读取线程 */
static void *sensor_thread(void *arg)
{
  int fd;
  struct sensor_accel accel;
  struct sensor_gyro gyro;

  /* 打开加速度计设备 */
  fd = open("/dev/sensor_accel0", O_RDONLY);
  if (fd < 0)
    {
      LV_LOG_ERROR("Cannot open accel sensor");
      return NULL;
    }

  /* 设置采样率 (100Hz) */
  unsigned long interval = 10000; /* 10ms = 100Hz */
  ioctl(fd, SNIOC_SET_INTERVAL, &interval);

  /* 启用传感器 */
  ioctl(fd, SNIOC_ACTIVATE, 1);

  while (1)
    {
      /* 读取加速度数据 */
      if (read(fd, &accel, sizeof(accel)) == sizeof(accel))
        {
          float ax = accel.x;  /* X 轴加速度 (m/s²) */
          float ay = accel.y;  /* Y 轴加速度 */
          float az = accel.z;  /* Z 轴加速度 */

          /* 跌倒检测: 合加速度突变 */
          float total = sqrtf(ax*ax + ay*ay + az*az);
          if (total < 2.0f || total > 20.0f)
            {
              /* 可能跌倒! */
              trigger_fall_alarm();
            }
        }

      usleep(10000);  /* 10ms */
    }

  close(fd);
  return NULL;
}
```

### 4.4 BMI270 内置步进计数器

BMI270 有硬件步进计数器，比软件算法更省电更准确：

```c
/* 通过 ioctl 读取步数 */
int fd = open("/dev/sensor_accel0", O_RDONLY);

struct sensor_event_fifo event;
while (read(fd, &event, sizeof(event)) > 0)
  {
    if (event.sensor_type == SENSOR_TYPE_STEP_COUNTER)
      {
        uint32_t steps = event.step_counter;
        /* 更新 UI 步数显示 */
      }
  }
```

### 4.5 BMI270 内置跌倒检测

BMI270 有硬件跌倒检测功能，通过中断引脚通知：

```c
/* 配置 GPIO 中断 */
#include <nuttx/irq.h>
#include <nuttx/gpio.h>

static int fall_irq_handler(int irq, void *context, void *arg)
{
  /* 跌倒检测中断 */
  LV_LOG_WARN("Fall detected by BMI270!");
  data_collector_trigger_fall_alarm();
  return OK;
}

/* 初始化时注册中断 */
irq_attach(GPIO_TO_IRQ(BMI270_INT_GPIO), fall_irq_handler, NULL);
irq_set_trigger(GPIO_TO_IRQ(BMI270_INT_GPIO), IRQ_TRIGGER_RISING);
```

---

## 五、开发步骤总结

```
步骤 1: 硬件准备
├── 购买 BMI270 模块 (如 CJMCU-270)
├── 连接到 BES1700 EVB 的 I2C1 (PA33/PA30)
└── 连接中断引脚到 GPIO

步骤 2: 配置 defconfig
├── 启用 CONFIG_BES_I2C1=y
├── 启用 CONFIG_SENSORS_BMI270=y
├── 启用 CONFIG_SENSORS=y
└── 编译验证驱动加载

步骤 3: NSH 验证
├── nsh> ls /dev/sensor_*    # 确认设备节点
├── nsh> sensortest -n 100 /dev/sensor_accel0  # 读取数据
└── nsh> sensortest -n 100 /dev/sensor_gyro0

步骤 4: 应用集成
├── 读取加速度计 → 跌倒检测
├── 读取陀螺仪 → 姿态识别
├── 步进计数 → 步数统计
└── UI 显示传感器数据

步骤 5: WiFi 联调
├── wapi psk wlan0 "SSID" "PASS" 3
├── ifup wlan0 && renew wlan0
├── HTTP 上传传感器数据
└── 验证端到端数据链路
```

---

## 六、常见问题

### Q1: WiFi 扫描不到热点？
```bash
# 检查 WiFi 子系统是否启动
nsh> ifconfig
# 如果没有 wlan0，检查 APC1 核心是否正常运行
# 可能需要等待几秒让 WiFi 固件加载完成
```

### Q2: BMI270 I2C 通信失败？
```bash
# 检查 I2C 总线
nsh> i2c dev 1        # 扫描 I2C1 总线上的设备
# 应该能看到地址 0x68 或 0x69
# 如果没有，检查接线和上拉电阻
```

### Q3: 传感器数据不准？
- BMI270 需要校准（出厂已校准，但可运行时微调）
- 避免 PCB 机械振动影响加速度计
- 陀螺仪需要温度补偿

### Q4: 如何选择 I2C 还是 SPI？
- **I2C**：接线简单（2 根线），速度够用（400KHz），推荐
- **SPI**：速度快（10MHz），适合高速采样场景
- 智能手表场景 I2C 足够
