/**
 * 常量配置
 * 服务器地址：http://101.35.231.154/api/v1
 */

// 体征正常范围
export const VITAL_RANGES = {
  heartRate: {
    min: 60,
    max: 100,
    warningLow: 50,
    warningHigh: 120,
    dangerLow: 30,
    dangerHigh: 180
  },
  spo2: {
    min: 95,
    max: 100,
    warning: 92,
    danger: 85
  },
  temperature: {
    min: 36.1,
    max: 37.2,
    warningLow: 35.5,
    warningHigh: 37.5
  }
}

// 活动目标默认值
export const ACTIVITY_DEFAULTS = {
  goalSteps: 6000,
  collectInterval: 5,
  uploadInterval: 30
}

// 报警级别
export const ALARM_LEVELS = {
  P0: 'P0',
  P1: 'P1',
  P2: 'P2',
  P3: 'P3'
}

// 健康提示级别
export const TIP_LEVELS = {
  INFO: 'info',
  WARNING: 'warning',
  DANGER: 'danger'
}

// 存储键名
export const STORAGE_KEYS = {
  USER_SETTINGS: 'user_settings',
  TODAY_ACTIVITY: 'today_activity',
  SOS_RECORDS: 'sos_records',
  SOS_CACHE: 'sos_cache',
  VITAL_HISTORY: 'vital_history',
  VITAL_CACHE: 'vital_cache',
  UPLOAD_LOG: 'upload_log',
  UPLOAD_MODE: 'upload_mode',
  MQTT_STATUS: 'mqtt_status',
  MQTT_CMD: 'mqtt_cmd'
}

// ============================================
// 服务器 API 配置
// Base URL: http://101.35.231.154/api/v1
// ============================================
export const API_CONFIG = {
  BASE_URL: 'http://101.35.231.154',
  VERSION: '/api/v1',

  // 设备信息（根据实际设备填写）
  DEVICE_SN: 'EH-WATCH-20260101',
  ELDERLY_ID: '47e306a7-76b0-11f1-a296-0242ac130012',

  // MQTT 配置（真机使用）
  MQTT: {
    // TCP Broker（原生 MQTT，需要平台 socket 支持）
    BROKER: 'mqtt://101.35.231.154:1883',
    // WebSocket Broker（MQTT over WebSocket，手表平台推荐）
    WS_BROKER: 'ws://101.35.231.154:8083/mqtt',
    // 登录凭证
    USERNAME: 'elderly_device',
    PASSWORD: 'SilverHair@2026',
    CLIENT_ID: 'EH-WATCH-20260101',
    // 连接参数
    KEEP_ALIVE: 60,
    QOS: 1,
    CLEAN_START: false,
    SESSION_EXPIRY: 86400
  },

  // HTTP API 端点（模拟器调试使用）
  ENDPOINTS: {
    // 体征数据上报（模拟器通过HTTP POST）
    VITAL_SIGN: '/api/v1/vitals/sign',
    // 报警数据上报（模拟器通过HTTP POST）
    ALARM_REPORT: '/api/v1/alarms/report',
    // 设备心跳
    DEVICE_HEARTBEAT: '/api/v1/devices/heartbeat',
    // 设备上线
    DEVICE_ONLINE: '/api/v1/devices/online',
    // 设备位置上报
    DEVICE_POSITION: '/api/v1/devices/position',
    // 查询体征历史
    VITAL_HISTORY: '/api/v1/vitals',
    // 查询报警列表
    ALARM_LIST: '/api/v1/alarms'
  },

  // MQTT Topic 定义
  MQTT_TOPICS: {
    VITAL: (sn) => `device/${sn}/vital`,
    ALARM: (sn) => `device/${sn}/alarm`,
    HEARTBEAT: (sn) => `device/${sn}/heartbeat`,
    ONLINE: (sn) => `device/${sn}/online`,
    POSITION: (sn) => `device/${sn}/position`,
    BATCH: (sn) => `device/${sn}/batch`,
    SIGNIN: (sn) => `device/${sn}/signin`
  }
}

// 传感器配置
export const SENSOR_CONFIG = {
  heartRateInterval: 1000,
  spo2Interval: 5000,
  accelerometerInterval: 100
}

// 上传模式
export const UPLOAD_MODE = {
  HTTP: 'http',   // 模拟器调试：通过HTTP API上传
  MQTT: 'mqtt'    // 真机：通过MQTT上传
}

// 上传模式的中文标签
export const UPLOAD_MODE_LABELS = {
  http: 'HTTP 模式（调试）',
  mqtt: 'MQTT 模式（真机）'
}
