#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
# AI 老年健康守护系统 - 手表端 MQTT 模拟器
# 功能：模拟 BES2700 手表通过 MQTT 与服务器通信
#
# 使用方法:
#   pip install -r requirements.txt
#   python watch_simulator.py                          # 默认单设备运行
#   python watch_simulator.py --device-id EH-TEST-001 # 指定设备ID
#   python watch_simulator.py --batch 10                    # 批量模拟10台设备
#   python watch_simulator.py --sos-delay 60               # 60秒后触发SOS
#   python watch_simulator.py --no-vitals                    # 不上报体征（仅心跳）
#   python watch_simulator.py -i                            # 交互模式
#
# 版本: 1.0.0
# 日期: 2026-06-24
# ============================================================

import argparse
import json
import random
import sys
import time
import threading
from datetime import datetime

try:
    import paho.mqtt.client as mqtt
    HAS_PAH0 = True
except ImportError:
    HAS_PAH0 = False


# ============================================================
# 配置常量
# ============================================================
DEFAULT_BROKER = "localhost"
DEFAULT_PORT = 1883
DEFAULT_ELDERLY_ID = 1
DEFAULT_DEVICE_ID = "EH-TEST-001"

# 模拟数据范围
HEART_RATE_RANGE = (60, 100)
SPO2_RANGE = (94, 99)
BP_SYS_RANGE = (110, 145)
BP_DIA_RANGE = (65, 95)
TEMP_RANGE = (36.2, 37.4)
STEPS_RANGE = (500, 15000)

# 上报间隔（秒）
VITAL_INTERVAL = 30
HEARTBEAT_INTERVAL = 60
POSITION_INTERVAL = 300  # 5分钟上报一次位置


# ============================================================
# 日志输出
# ============================================================
def now_ts():
    """当前 Unix 时间戳"""
    return int(time.time())


def now_str():
    """当前时间字符串 HH:MM:SS"""
    return datetime.now().strftime("%H:%M:%S")


def log(device_id, msg, color=""):
    """带时间戳的日志输出"""
    ts = datetime.now().strftime("%H:%M:%S")
    try:
        print(f"{color}[{ts}] [{device_id}]{msg}")
    except UnicodeEncodeError:
        # Windows GBK 控制台兼容
        print(f"[{ts}] [{device_id}]{msg}")


# ============================================================
# 模拟数据生成
# ============================================================
def generate_vital(elderly_id):
    """生成模拟体征数据"""
    return {
        "elderly_id": str(elderly_id),
        "heart_rate": random.randint(*HEART_RATE_RANGE),
        "blood_pressure_sys": random.randint(*BP_SYS_RANGE),
        "blood_pressure_dia": random.randint(*BP_DIA_RANGE),
        "spo2": random.randint(*SPO2_RANGE),
        "temperature": round(random.uniform(*TEMP_RANGE), 1),
        "step_count": random.randint(*STEPS_RANGE),
        "timestamp": now_ts(),
    }


def generate_position(elderly_id):
    """生成模拟位置数据（花木社区附近）"""
    base_lat = 31.210
    base_lng = 121.545
    return {
        "elderly_id": str(elderly_id),
        "lat": round(base_lat + random.uniform(-0.01, 0.01), 6),
        "lng": round(base_lng + random.uniform(-0.01, 0.01), 6),
        "accuracy": random.randint(5, 50),
        "timestamp": now_ts(),
    }


def generate_heartbeat(device_id, battery=None):
    """生成心跳数据"""
    return {
        "device_id": device_id,
        "battery": battery if battery is not None else random.randint(20, 100),
        "timestamp": now_ts(),
    }


def generate_sos_alarm(elderly_id):
    """生成 SOS 报警数据"""
    pos = generate_position(elderly_id)
    return {
        "elderly_id": str(elderly_id),
        "alarm_type": "sos",
        "location": {
            "lat": pos["lat"],
            "lng": pos["lng"],
            "accuracy": pos["accuracy"],
        },
        "timestamp": now_ts(),
    }


def generate_fall_alarm(elderly_id):
    """生成跌倒报警数据"""
    pos = generate_position(elderly_id)
    return {
        "elderly_id": str(elderly_id),
        "alarm_type": "fall",
        "location": {
            "lat": pos["lat"],
            "lng": pos["lng"],
            "accuracy": pos["accuracy"],
        },
        "timestamp": now_ts(),
    }


def generate_signin(elderly_id):
    """生成签到数据"""
    return {
        "elderly_id": str(elderly_id),
        "signin_time": now_str(),
        "timestamp": now_ts(),
    }


# ============================================================
# MQTT 回调
# ============================================================
def make_on_connect(device_id, elderly_id):
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            log(device_id, " [OK] 已连接到 EMQX Broker", "\033[92m")
            # 订阅下行指令 Topic
            topics = [
                (f"server/alarm/{device_id}", 1),
                (f"server/upgrade/{device_id}", 1),
                (f"server/config/{device_id}", 1),
            ]
            client.subscribe(topics)
            log(device_id, " [SUB] 已订阅下行 Topic: server/#", "\033[94m")

            # 发送上线通知
            online_msg = json.dumps({
                "elderly_id": str(elderly_id),
                "timestamp": now_ts(),
            }, ensure_ascii=False)
            client.publish(f"watch/online/{device_id}", online_msg, qos=1)
            log(device_id, " [ONLINE] 已发送上线通知", "\033[96m")
        else:
            errors = {
                1: "协议版本不正确",
                2: "客户端 ID 无效",
                3: "服务器不可用",
                4: "用户名/密码错误",
                5: "未授权",
            }
            log(device_id, f" [ERR] 连接失败: {errors.get(rc, f'未知错误({rc})')}", "\033[91m")
    return on_connect


def make_on_message(device_id):
    def on_message(client, userdata, msg):
        try:
            payload = json.loads(msg.payload.decode())
            log(device_id, f" [DOWN] 收到下行指令 [{msg.topic}]: {json.dumps(payload, ensure_ascii=False)}", "\033[93m")
        except Exception:
            log(device_id, f" [DOWN] 收到下行指令 [{msg.topic}]: {msg.payload}", "\033[93m")
    return on_message


def make_on_disconnect(device_id):
    def on_disconnect(client, userdata, rc):
        if rc != 0:
            log(device_id, f" [WARN] 连接意外断开 (rc={rc})，正在重连...", "\033[93m")
        else:
            log(device_id, " [OFFLINE] 已断开连接", "\033[91m")
    return on_disconnect


# ============================================================
# 定时任务
# ============================================================
def vital_loop(client, device_id, elderly_id, interval, stop_event):
    """定时上报体征数据"""
    while not stop_event.is_set():
        data = generate_vital(elderly_id)
        topic = f"watch/vital/{device_id}"
        client.publish(topic, json.dumps(data, ensure_ascii=False), qos=1)
        log(device_id, f" [VITAL] 心率={data['heart_rate']}, 血氧={data['spo2']}, 血压={data['blood_pressure_sys']}/{data['blood_pressure_dia']}", "\033[92m")
        stop_event.wait(interval)


def heartbeat_loop(client, device_id, interval, stop_event):
    """定时发送心跳"""
    while not stop_event.is_set():
        battery = random.randint(20, 100)
        data = generate_heartbeat(device_id, battery)
        topic = f"watch/heartbeat/{device_id}"
        client.publish(topic, json.dumps(data, ensure_ascii=False), qos=0)
        log(device_id, f" [PING] 心跳: 电量={battery}%", "\033[96m")
        stop_event.wait(interval)


def position_loop(client, device_id, elderly_id, interval, stop_event):
    """定时上报位置"""
    while not stop_event.is_set():
        data = generate_position(elderly_id)
        topic = f"watch/position/{device_id}"
        client.publish(topic, json.dumps(data, ensure_ascii=False), qos=1)
        log(device_id, f" [GPS] 位置: lat={data['lat']}, lng={data['lng']}", "\033[94m")
        stop_event.wait(interval)


# ============================================================
# 主模拟器类
# ============================================================
class WatchSimulator:
    def __init__(self, broker, port, device_id, elderly_id,
                 send_vitals=True, send_position=True,
                 sos_delay=None):
        self.broker = broker
        self.port = port
        self.device_id = device_id
        self.elderly_id = elderly_id
        self.send_vitals = send_vitals
        self.send_position = send_position
        self.sos_delay = sos_delay

        self.client = mqtt.Client(client_id=f"watch_{device_id}")
        self.stop_event = threading.Event()
        self.threads = []

    def start(self):
        """启动模拟器"""
        self.client.on_connect = make_on_connect(self.device_id, self.elderly_id)
        self.client.on_message = make_on_message(self.device_id)
        self.client.on_disconnect = make_on_disconnect(self.device_id)

        try:
            self.client.connect(self.broker, self.port, 60)
        except ConnectionRefusedError:
            log(self.device_id, f" [ERR] 无法连接到 {self.broker}:{self.port}，请确认 EMQX 已启动", "\033[91m")
            sys.exit(1)

        self.client.loop_start()

        # 启动定时任务线程
        if self.send_vitals:
            t = threading.Thread(
                target=vital_loop,
                args=(self.client, self.device_id, self.elderly_id, VITAL_INTERVAL, self.stop_event),
                daemon=True,
            )
            t.start()
            self.threads.append(t)

        t = threading.Thread(
            target=heartbeat_loop,
            args=(self.client, self.device_id, HEARTBEAT_INTERVAL, self.stop_event),
            daemon=True,
        )
        t.start()
        self.threads.append(t)

        if self.send_position:
            t = threading.Thread(
                target=position_loop,
                args=(self.client, self.device_id, self.elderly_id, POSITION_INTERVAL, self.stop_event),
                daemon=True,
            )
            t.start()
            self.threads.append(t)

        # SOS 延迟触发
        if self.sos_delay:
            def delayed_sos():
                time.sleep(self.sos_delay)
                self.trigger_sos()
            t = threading.Thread(target=delayed_sos, daemon=True)
            t.start()
            log(self.device_id, f" [TIMER] SOS 将在 {self.sos_delay} 秒后自动触发", "\033[93m")

        log(self.device_id, " [START] 模拟器已启动，按 Ctrl+C 停止", "\033[92m")
        log(self.device_id, f"   体征间隔={VITAL_INTERVAL}s | 心跳间隔={HEARTBEAT_INTERVAL}s", "\033[96m")

        # 主线程等待
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            self.stop()

    def stop(self):
        """停止模拟器"""
        log(self.device_id, " [STOP] 正在停止模拟器...", "\033[93m")
        self.stop_event.set()

        # 发送离线通知
        offline_msg = json.dumps({"timestamp": now_ts()}, ensure_ascii=False)
        self.client.publish(f"watch/offline/{self.device_id}", offline_msg, qos=1)
        log(self.device_id, " [OFFLINE] 已发送离线通知", "\033[96m")

        time.sleep(0.5)
        self.client.loop_stop()
        self.client.disconnect()
        log(self.device_id, " [EXIT] 模拟器已停止", "\033[92m")
        sys.exit(0)

    def trigger_sos(self):
        """手动触发 SOS 报警"""
        data = generate_sos_alarm(self.elderly_id)
        topic = f"watch/alarm/{self.device_id}"
        self.client.publish(topic, json.dumps(data, ensure_ascii=False), qos=1)
        log(self.device_id, " [SOS] 已触发 SOS 报警!", "\033[91m")

    def trigger_signin(self):
        """手动触发签到"""
        data = generate_signin(self.elderly_id)
        topic = f"watch/signin/{self.device_id}"
        self.client.publish(topic, json.dumps(data, ensure_ascii=False), qos=1)
        log(self.device_id, " [SIGNIN] 已上报签到", "\033[92m")

    def trigger_fall_alarm(self):
        """手动触发跌倒报警"""
        data = generate_fall_alarm(self.elderly_id)
        topic = f"watch/alarm/{self.device_id}"
        self.client.publish(topic, json.dumps(data, ensure_ascii=False), qos=1)
        log(self.device_id, " [FALL] 已触发跌倒报警!", "\033[91m")


# ============================================================
# 批量模拟器
# ============================================================
class BatchSimulator:
    def __init__(self, broker, port, count, base_device_id="EH-BATCH", base_elderly_id=1):
        self.broker = broker
        self.port = port
        self.count = count
        self.base_device_id = base_device_id
        self.base_elderly_id = base_elderly_id
        self.simulators = []

    def start(self):
        """启动批量模拟"""
        print(f"\033[92m [BATCH] 批量模拟模式: {self.count} 台设备\033[0m")
        for i in range(1, self.count + 1):
            device_id = f"{self.base_device_id}-{i:03d}"
            elderly_id = self.base_elderly_id + (i - 1)
            sim = WatchSimulator(
                self.broker, self.port, device_id, elderly_id,
                send_vitals=True, send_position=True, sos_delay=None,
            )
            t = threading.Thread(target=sim.start, daemon=True)
            t.start()
            self.simulators.append(sim)
            time.sleep(0.1)  # 错开连接时间

        log("BATCH", f" [OK] {self.count} 台设备模拟器已全部启动", "\033[92m")
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            log("BATCH", " [STOP] 正在停止所有模拟器...", "\033[93m")
            for sim in self.simulators:
                sim.stop_event.set()
            sys.exit(0)


# ============================================================
# 命令行入口
# ============================================================
def main():
    parser = argparse.ArgumentParser(
        description="AI 老年健康守护系统 - 手表端 MQTT 模拟器",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "示例:\n"
            "  python watch_simulator.py                             # 默认单设备\n"
            "  python watch_simulator.py -d EH-TEST-001 -e 1       # 指定设备ID和老人ID\n"
            "  python watch_simulator.py -b localhost -p 1883        # 指定 Broker 地址\n"
            "  python watch_simulator.py --batch 20                  # 批量模拟20台设备\n"
            "  python watch_simulator.py --sos-delay 30              # 30秒后自动触发SOS\n"
            "  python watch_simulator.py --no-vitals --no-position   # 仅发送心跳（最小负载）\n"
            "  python watch_simulator.py -i                          # 交互模式\n"
        ),
    )
    parser.add_argument("-d", "--device-id", default=DEFAULT_DEVICE_ID,
                        help=f"设备ID (默认: {DEFAULT_DEVICE_ID})")
    parser.add_argument("-e", "--elderly-id", default=DEFAULT_ELDERLY_ID, type=int,
                        help=f"绑定的老人ID (默认: {DEFAULT_ELDERLY_ID})")
    parser.add_argument("-b", "--broker", default=DEFAULT_BROKER,
                        help=f"EMQX Broker 地址 (默认: {DEFAULT_BROKER})")
    parser.add_argument("-p", "--port", default=DEFAULT_PORT, type=int,
                        help=f"EMQX 端口 (默认: {DEFAULT_PORT})")
    parser.add_argument("--batch", default=0, type=int,
                        help="批量模拟模式：同时模拟 N 台设备")
    parser.add_argument("--base-device-id", default="EH-BATCH",
                        help="批量模式设备ID前缀 (默认: EH-BATCH)")
    parser.add_argument("--sos-delay", default=0, type=int,
                        help="启动后延迟 N 秒自动触发 SOS 报警")
    parser.add_argument("--no-vitals", action="store_true",
                        help="不上报体征数据")
    parser.add_argument("--no-position", action="store_true",
                        help="不上报位置数据")
    parser.add_argument("--interactive", "-i", action="store_true",
                        help="交互模式：启动后可通过命令手动触发事件")

    args = parser.parse_args()

    # 检查依赖
    if not HAS_PAHO:
        print("[ERROR] 缺少依赖: paho-mqtt")
        print("  请先安装: pip install -r requirements.txt")
        sys.exit(1)

    print("=" * 62)
    print("  AI 老年健康守护系统 - 手表端 MQTT 模拟器")
    print(f"  模式: {'批量模拟 x' + str(args.batch) if args.batch > 0 else '单设备'}")
    print(f"  Broker: {args.broker}:{args.port}")
    print("=" * 62)
    print()

    if args.batch > 0:
        sim = BatchSimulator(
            args.broker, args.port, args.batch,
            base_device_id=args.base_device_id,
        )
        sim.start()
    else:
        sim = WatchSimulator(
            args.broker, args.port,
            args.device_id, args.elderly_id,
            send_vitals=not args.no_vitals,
            send_position=not args.no_position,
            sos_delay=args.sos_delay if args.sos_delay > 0 else None,
        )

        if args.interactive:
            # 交互模式：另开线程运行 MQTT，主线程接收命令
            t = threading.Thread(target=sim.start, daemon=True)
            t.start()
            print("\n交互命令: sos | signin | fall | quit")
            print("-" * 40)
            while True:
                try:
                    cmd = input(">> ").strip().lower()
                    if cmd == "sos":
                        sim.trigger_sos()
                    elif cmd == "signin":
                        sim.trigger_signin()
                    elif cmd == "fall":
                        sim.trigger_fall_alarm()
                    elif cmd in ("quit", "exit", "q"):
                        sim.stop()
                    else:
                        print("  可用命令: sos, signin, fall, quit")
                except (EOFError, KeyboardInterrupt):
                    sim.stop()
        else:
            sim.start()


if __name__ == "__main__":
    main()
