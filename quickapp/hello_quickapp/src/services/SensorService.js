/**
 * 传感器采集服务
 * 支持真实传感器和模拟数据两种模式
 * 运行时从 storage 读取配置切换数据来源
 */
import sensor from '@system.sensor'
import storage from '@system.storage'
import MockSensorService from './MockSensorService'
import { STORAGE_KEYS } from '../utils/constants'

export class SensorService {
  constructor() {
    this.heartRateCallback = null
    this.spo2Callback = null
    this.temperatureCallback = null
    this.accelerometerCallback = null
    this.stepsCallback = null
    this.locationCallback = null
    this.isRunning = false

    // 模拟数据服务实例
    this.mockService = null

    // 数据模式：'normal' | 'abnormal' | 'fall'
    this.dataMode = 'normal'

    // 数据来源：'mock' | 'real'，从 storage 读取
    this.dataSource = 'mock'
  }

  /**
   * 初始化：从 storage 读取数据来源配置
   * @param {Function} callback - 初始化完成回调
   */
  init(callback) {
    storage.get({
      key: STORAGE_KEYS.USER_SETTINGS,
      success: (data) => {
        if (data) {
          try {
            const settings = JSON.parse(data)
            this.dataSource = settings.useMockData !== false ? 'mock' : 'real'
            this.dataMode = settings.mockMode || 'normal'
          } catch (e) {
            this.dataSource = 'mock'
          }
        }
        if (callback) callback()
      },
      fail: () => {
        if (callback) callback()
      }
    })
  }

  /**
   * 启动传感器采集
   * @param {Object} callbacks - 数据回调函数
   */
  start(callbacks) {
    if (this.isRunning) return

    this.heartRateCallback = callbacks.onHeartRate
    this.spo2Callback = callbacks.onSpO2
    this.temperatureCallback = callbacks.onTemperature
    this.accelerometerCallback = callbacks.onAccelerometer
    this.stepsCallback = callbacks.onSteps
    this.locationCallback = callbacks.onLocation

    if (this.dataSource === 'mock') {
      this.startMockData()
    } else {
      this.startRealSensors()
    }

    this.isRunning = true
  }

  /**
   * 停止传感器采集
   */
  stop() {
    if (this.dataSource === 'mock') {
      this.stopMockData()
    } else {
      this.stopRealSensors()
    }

    this.isRunning = false
  }

  /**
   * 重新加载配置并重启采集
   * @param {Object} callbacks - 数据回调函数
   */
  reload(callbacks) {
    this.stop()
    this.init(() => {
      this.start(callbacks)
    })
  }

  /**
   * 设置数据模式
   * @param {string} mode - 'normal' | 'abnormal' | 'fall'
   */
  setDataMode(mode) {
    this.dataMode = mode
    if (this.dataSource === 'mock' && this.mockService) {
      this.mockService.setMode(mode)
    }
  }

  /**
   * 获取当前数据来源
   */
  getDataSource() {
    return this.dataSource
  }

  // ============================================
  // 模拟数据模式
  // ============================================

  /**
   * 启动模拟数据
   */
  startMockData() {
    this.mockService = new MockSensorService()
    this.mockService.start({
      onHeartRate: this.heartRateCallback,
      onSpO2: this.spo2Callback,
      onTemperature: this.temperatureCallback,
      onAccelerometer: this.accelerometerCallback,
      onSteps: this.stepsCallback,
      onLocation: this.locationCallback
    })

    // 设置初始模式
    if (this.dataMode !== 'normal') {
      this.mockService.setMode(this.dataMode)
    }
  }

  /**
   * 停止模拟数据
   */
  stopMockData() {
    if (this.mockService) {
      this.mockService.stop()
      this.mockService = null
    }
  }

  // ============================================
  // 真实传感器模式
  // ============================================

  /**
   * 启动真实传感器
   */
  startRealSensors() {
    this.startHeartRate()
    this.startSpO2()
    this.startAccelerometer()
    // 温度传感器部分设备不支持，可按需扩展
  }

  /**
   * 停止真实传感器
   */
  stopRealSensors() {
    this.stopHeartRate()
    this.stopSpO2()
    this.stopAccelerometer()
  }

  /**
   * 启动心率采集
   */
  startHeartRate() {
    sensor.subscribeHeartRate({
      callback: (data) => {
        if (this.heartRateCallback) {
          this.heartRateCallback({
            heartRate: data.heartRate,
            timestamp: data.timestamp || Date.now()
          })
        }
      },
      fail: (data, code) => {
        console.error(`心率采集失败: code=${code}`)
      }
    })
  }

  /**
   * 停止心率采集
   */
  stopHeartRate() {
    sensor.unsubscribeHeartRate({
      success: () => {},
      fail: (data, code) => {
        console.error(`停止心率采集失败: code=${code}`)
      }
    })
  }

  /**
   * 启动血氧采集
   */
  startSpO2() {
    sensor.subscribeSpO2({
      callback: (data) => {
        if (this.spo2Callback) {
          this.spo2Callback({
            spo2: data.spo2,
            timestamp: data.timestamp || Date.now()
          })
        }
      },
      fail: (data, code) => {
        console.error(`血氧采集失败: code=${code}`)
      }
    })
  }

  /**
   * 停止血氧采集
   */
  stopSpO2() {
    sensor.unsubscribeSpO2({
      success: () => {},
      fail: (data, code) => {
        console.error(`停止血氧采集失败: code=${code}`)
      }
    })
  }

  /**
   * 启动加速度采集（用于跌倒检测）
   */
  startAccelerometer() {
    sensor.subscribeAccelerometer({
      callback: (data) => {
        if (this.accelerometerCallback) {
          this.accelerometerCallback({
            x: data.x,
            y: data.y,
            z: data.z,
            timestamp: data.timestamp || Date.now()
          })
        }
      },
      fail: (data, code) => {
        console.error(`加速度采集失败: code=${code}`)
      }
    })
  }

  /**
   * 停止加速度采集
   */
  stopAccelerometer() {
    sensor.unsubscribeAccelerometer({
      success: () => {},
      fail: (data, code) => {
        console.error(`停止加速度采集失败: code=${code}`)
      }
    })
  }

  /**
   * 触发跌倒事件（仅模拟模式有效）
   */
  triggerFallEvent() {
    if (this.dataSource === 'mock' && this.mockService) {
      this.mockService.triggerFallEvent()
    }
  }
}

export default SensorService
