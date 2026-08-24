# AI Elderly Health Care - LVGL Application

LVGL-based elderly health monitoring and SOS alarm application for OpenVela on SF32LB52-DevKit-LCD.

## Overview

This application provides a wearable health monitoring interface with:

- **Real-time vital sign display** (heart rate, SpO2, body temperature)
- **Step counter** with daily goal progress
- **SOS alarm** with 10-second countdown and auto-notification
- **Health detail page** with time-range history (1h/6h/24h)
- **Settings page** for brightness, collection interval, toggles, and upload mode
- **HTTP data upload** to backend API (conditional on network availability)
- **Simulated sensor data** for development without real hardware sensors

## Hardware

| Item | Spec |
|------|------|
| Board | SF32LB52-DevKit-LCD |
| MCU | SiFli SF32LB52 (ARM Cortex-M33) |
| Display | 1.85" CO5300 AMOLED, 390×450, QSPI |
| Touch | FT6146 capacitive, I2C1, `/dev/input0` |
| LCD device | `/dev/lcd0`, `/dev/fb0` |
| Console | UART1 (PA18/PA19), baud 1000000 |
| Flash | 16MB NOR, XIP @ `0x12010000` |

## Project Structure

```
apps/examples/elderly/
├── Kconfig                     # Build configuration menu
├── Makefile                    # NuttX Make build
├── Make.defs                   # App registration
├── CMakeLists.txt              # CMake build
├── elderly_main.c              # Main entry: LVGL init + event loop
├── ui_common.h                 # Shared definitions (colors, screen, data structs)
├── ui_manager.c / .h           # Page navigation (swipe left/right)
├── ui_index.c / .h             # Home page: SOS button, vitals, steps
├── ui_health_detail.c / .h     # Heart rate detail with history
├── ui_settings.c / .h          # Settings: brightness, interval, toggles
├── ui_sos.c / .h               # SOS alarm page with countdown
├── http_client.c / .h          # HTTP client (POSIX sockets, conditional)
└── data_collector.c / .h       # Sensor data collection + alarm logic
```

Board-level config:

```
vendor/sifli/boards/sf32lb52/sf32lb52_devkit_lcd/configs/elderly/
├── defconfig                   # NuttX defconfig with LVGL + elderly app
└── README.md                   # Config description
```

## Build

### Prerequisites

- OpenVela source tree (`dev-ai-contest-2026` branch)
- ARM cross-compiler (`arm-none-eabi-gcc 10.3+`)
- CMake 3.20+ and Ninja

### Compile

```bash
cd /opt/openvela_2026

# Configure
cmake -B cmake_out/sf32lb52_elderly \
  -S "$PWD/nuttx" \
  -GNinja \
  -DBOARD_CONFIG=../vendor/sifli/boards/sf32lb52/sf32lb52_devkit_lcd/configs/elderly \
  -DEXTRA_FLAGS="-Wno-cpp -Wno-deprecated-declarations"

# Build
cmake --build cmake_out/sf32lb52_elderly
```

Output: `cmake_out/sf32lb52_elderly/nuttx.bin` (~1.3MB)

### Flash

```bash
sftool -c SF32LB52 -p /dev/ttyUSB0 -b 1000000 \
       --before default_reset --after soft_reset \
       write_flash cmake_out/sf32lb52_elderly/nuttx.bin@0x12010000
```

> If `sftool` reports `Failed to connect to the chip`, press the Reset button on the board and retry.

### Serial Console

```bash
# Must use picocom (RTS issue with this board)
picocom -b 1000000 --noreset --lower-rts --lower-dtr /dev/ttyUSB0
```

> **Do NOT use `screen` or `cu`** — they hold RTS asserted and keep the SoC in reset.

### Run

```
nsh> elderly
```

## UI Pages

### Home Page

- Large red **SOS** button (long press to trigger alarm)
- Three vital sign cards: **HR** (bpm), **SpO2** (%), **Temp** (°C)
- Step progress bar with daily goal (6000 steps)
- Health status bar ("All vitals normal" / "Abnormal vitals")
- Status bar: connection indicator + battery level

### Heart Rate Detail

- Large heart rate display with Normal/Low/High status
- Time range selector: 1h / 6h / 24h
- Scrollable history list (time + value)

### Settings

- Brightness slider
- Collection interval (±5s, range 5-300s)
- Toggle switches: SOS Alert, Fall Detection, Simulated Data
- Upload mode: MQTT / HTTP
- Save button

### SOS Alarm Page

- "ALARM TRIGGERED" header in red
- 10-second countdown timer
- Vital sign snapshot at alarm time
- Location display
- "Cancel Alarm" button
- Notification status ("Family & community notified")

## Navigation

| Gesture | Action |
|---------|--------|
| Swipe left | Next page (Home → Detail → Settings → SOS) |
| Swipe right | Previous page |
| Long press SOS button | Trigger alarm |

## Configuration (Kconfig)

| Config | Default | Description |
|--------|---------|-------------|
| `EXAMPLES_ELDERLY_SCREEN_WIDTH` | 390 | Screen width (pixels) |
| `EXAMPLES_ELDERLY_SCREEN_HEIGHT` | 450 | Screen height (pixels) |
| `EXAMPLES_ELDERLY_SERVER_URL` | `http://101.35.231.154/api/v1` | Backend API URL |
| `EXAMPLES_ELDERLY_DEVICE_SN` | `EH-WATCH-20260101` | Device serial number |
| `EXAMPLES_ELDERLY_DEFAULT_INTERVAL` | 10 | Data collection interval (seconds) |
| `EXAMPLES_ELDERLY_STACKSIZE` | 65536 | Task stack size |
| `EXAMPLES_ELDERLY_PRIORITY` | 100 | Task priority |

Modify via menuconfig:

```bash
cd cmake_out/sf32lb52_elderly
ninja menuconfig
# Search for "elderly" to find all options
```

## Network

The SF32LB52-DevKit-LCD has **no built-in network hardware**. The HTTP client is compiled conditionally:

- **Without `CONFIG_NET`**: All HTTP functions return `-ENOSYS`. The app runs in offline mode with simulated data. UI and data collection work normally.
- **With network** (e.g., USB RNDIS, external WiFi module): Data is uploaded to the backend API per the collection interval.

To enable networking, add to defconfig:

```
CONFIG_NET=y
CONFIG_NET_TCP=y
CONFIG_NET_IPv4=y
CONFIG_NET_SOCKOPTS=y
```

## Backend API

The application communicates with the elderly health backend API (see `API接口文档.md`):

| Function | Endpoint | Method |
|----------|----------|--------|
| Upload vitals | `/v1/devices/{sn}/vital` | POST |
| Upload alarm | `/v1/devices/{sn}/alarm` | POST |
| Upload heartbeat | `/v1/devices/{sn}/heartbeat` | POST (every 60s) |
| Upload position | `/v1/devices/{sn}/position` | POST |

Base URL: `http://101.35.231.154/api/v1`

## Vital Sign Normal Ranges

| Metric | Normal Range | Alarm Trigger |
|--------|-------------|---------------|
| Heart Rate | 55-100 bpm | < 55 or > 100 |
| SpO2 | 95-100% | < 95% |
| Temperature | 35.5-37.3°C | < 35.5 or > 37.3 |

## LVGL Version

- LVGL **v9.1.0**
- Fonts: Montserrat 14/16/20/24/28/36
- Display backend: NuttX LCD (`/dev/lcd0`)
- Input backend: NuttX Touchscreen (`/dev/input0`)

## License

Apache-2.0 (consistent with OpenVela project conventions)
