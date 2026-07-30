/**
 * 模拟传感器数据服务
 * 提供心率、血氧、体温、加速度、步数、位置等模拟数据
 * 用于模拟器演示和功能测试
 */

export class MockSensorService {
  constructor() {
    this.isRunning = false
    this.timers = {}

    // 模拟数据状态
    this.state = {
      // 心率：基础值 + 随机波动
      heartRate: { base: 72, variance: 8, min: 55, max: 120 },

      // 血氧：正常范围波动
      spo2: { base: 97, variance: 2, min: 90, max: 100 },

      // 体温：正常范围波动
      temperature: { base: 36.5, variance: 0.3, min: 35.5, max: 37.5 },

      // 加速度：模拟正常活动
      accelerometer: { baseX: 0, baseY: 0, baseZ: 9.8, variance: 0.5 },

      // 步数：每秒随机增加
      steps: { current: 0, increment: { min: 0, max: 2 } },

      // 位置：北京天安门附近
      location: {
        latitude: 39.9042,
        longitude: 116.4074,
        variance: 0.0001
      }
    }

    // 上一次的模拟值（用于平滑过渡）
    this.lastValues = {
      heartRate: 72,
      spo2: 97,
      temperature: 36.5
    }

    // 回调函数
    this.callbacks = {
      onHeartRate: null,
      onSpO2: null,
      onTemperature: null,
      onAccelerometer: null,
      onSteps: null,
      onLocation: null
    }
  }

  /**
   * 启动模拟数据采集
   * @param {Object} callbacks - 数据回调函数
   */
  start(callbacks) {
    if (this.isRunning) return

    this.callbacks = { ...this.callbacks, ...callbacks }
    this.isRunning = true

    // 启动各传感器模拟
    this.startHeartRateSimulation()
    this.startSpO2Simulation()
    this.startTemperatureSimulation()
    this.startAccelerometerSimulation()
    this.startStepsSimulation()
    this.startLocationSimulation()
  }

  /**
   * 停止模拟数据采集
   */
  stop() {
    this.isRunning = false

    // 清除所有定时器
    Object.keys(this.timers).forEach(key => {
      if (this.timers[key]) {
        clearInterval(this.timers[key])
        this.timers[key] = null
      }
    })
  }

  /**
   * 生成平滑的模拟值
   * @param {string} type - 数据类型
   * @param {Object} config - 配置参数
   * @returns {number} 模拟值
   */
  generateSmoothValue(type, config) {
    const lastValue = this.lastValues[type]
    const { base, variance, min, max } = config

    // 随机波动，但保持与上一次值的连续性
    const delta = (Math.random() - 0.5) * variance
    let newValue = lastValue + delta

    // 如果偏离基础值太远，向基础值回归
    const deviation = newValue - base
    if (Math.abs(deviation) > variance * 2) {
      newValue = base + deviation * 0.7
    }

    // 限制在有效范围内
    newValue = Math.max(min, Math.min(max, newValue))

    this.lastValues[type] = newValue
    return newValue
  }

  /**
   * 模拟心率数据
   * 心率范围：55-120 bpm
   * 更新频率：每2秒
   */
  startHeartRateSimulation() {
    this.timers.heartRate = setInterval(() => {
      if (!this.isRunning) return

      const heartRate = Math.round(this.generateSmoothValue('heartRate', this.state.heartRate))

      if (this.callbacks.onHeartRate) {
        this.callbacks.onHeartRate({
          heartRate: heartRate,
          timestamp: Date.now()
        })
      }
    }, 2000)
  }

  /**
   * 模拟血氧数据
   * 血氧范围：90-100%
   * 更新频率：每5秒
   */
  startSpO2Simulation() {
    this.timers.spo2 = setInterval(() => {
      if (!this.isRunning) return

      const spo2 = Math.round(this.generateSmoothValue('spo2', this.state.spo2))

      if (this.callbacks.onSpO2) {
        this.callbacks.onSpO2({
          spo2: spo2,
          timestamp: Date.now()
        })
      }
    }, 5000)
  }

  /**
   * 模拟体温数据
   * 体温范围：35.5-37.5°C
   * 更新频率：每10秒
   */
  startTemperatureSimulation() {
    this.timers.temperature = setInterval(() => {
      if (!this.isRunning) return

      const temperature = parseFloat(this.generateSmoothValue('temperature', this.state.temperature).toFixed(1))

      if (this.callbacks.onTemperature) {
        this.callbacks.onTemperature({
          temperature: temperature,
          timestamp: Date.now()
        })
      }
    }, 10000)
  }

  /**
   * 模拟加速度数据
   * 用于跌倒检测测试
   * 更新频率：每100ms
   */
  startAccelerometerSimulation() {
    this.timers.accelerometer = setInterval(() => {
      if (!this.isRunning) return

      const { baseX, baseY, baseZ, variance } = this.state.accelerometer

      // 正常活动的加速度
      const x = baseX + (Math.random() - 0.5) * variance
      const y = baseY + (Math.random() - 0.5) * variance
      const z = baseZ + (Math.random() - 0.5) * variance

      if (this.callbacks.onAccelerometer) {
        this.callbacks.onAccelerometer({
          x: parseFloat(x.toFixed(2)),
          y: parseFloat(y.toFixed(2)),
          z: parseFloat(z.toFixed(2)),
          timestamp: Date.now()
        })
      }
    }, 100)
  }

  /**
   * 模拟步数数据
   * 步数随机增加
   * 更新频率：每秒
   */
  startStepsSimulation() {
    this.timers.steps = setInterval(() => {
      if (!this.isRunning) return

      const { increment } = this.state.steps
      const stepIncrement = Math.floor(Math.random() * (increment.max - increment.min + 1)) + increment.min
      this.state.steps.current += stepIncrement

      if (this.callbacks.onSteps) {
        this.callbacks.onSteps({
          steps: this.state.steps.current,
          timestamp: Date.now()
        })
      }
    }, 1000)
  }

  /**
   * 模拟位置数据
   * 位置在设定点附近小幅移动
   * 更新频率：每5秒
   */
  startLocationSimulation() {
    this.timers.location = setInterval(() => {
      if (!this.isRunning) return

      const { latitude, longitude, variance } = this.state.location

      // 在设定位置附近随机移动
      const lat = latitude + (Math.random() - 0.5) * variance
      const lng = longitude + (Math.random() - 0.5) * variance

      if (this.callbacks.onLocation) {
        this.callbacks.onLocation({
          latitude: parseFloat(lat.toFixed(6)),
          longitude: parseFloat(lng.toFixed(6)),
          accuracy: Math.round(Math.random() * 10 + 5), // 5-15米精度
          timestamp: Date.now()
        })
      }
    }, 5000)
  }

  /**
   * 设置模拟数据模式
   * @param {string} mode - 'normal' | 'abnormal' | 'fall'
   */
  setMode(mode) {
    switch (mode) {
      case 'normal':
        // 正常模式
        this.state.heartRate.base = 72
        this.state.heartRate.min = 55
        this.state.heartRate.max = 120
        this.state.spo2.base = 97
        this.state.temperature.base = 36.5
        break

      case 'abnormal':
        // 异常模式：心率偏高，血氧偏低
        this.state.heartRate.base = 110
        this.state.heartRate.min = 95
        this.state.heartRate.max = 130
        this.state.spo2.base = 88
        this.state.temperature.base = 37.8
        break

      case 'fall':
        // 跌倒模式：触发一次高加速度
        this.triggerFallEvent()
        break
    }
  }

  /**
   * 触发跌倒事件
   * 模拟一次高加速度冲击
   */
  triggerFallEvent() {
    // 暂时替换加速度回调，发送跌倒数据
    const originalCallback = this.callbacks.onAccelerometer

    let fallCount = 0
    const fallTimer = setInterval(() => {
      fallCount++

      // 跌倒时的加速度：突然增大然后恢复
      const intensity = fallCount <= 5 ? 15 + Math.random() * 10 : 0
      const x = (Math.random() - 0.5) * intensity
      const y = (Math.random() - 0.5) * intensity
      const z = 9.8 + (Math.random() - 0.5) * intensity

      if (originalCallback) {
        originalCallback({
          x: parseFloat(x.toFixed(2)),
          y: parseFloat(y.toFixed(2)),
          z: parseFloat(z.toFixed(2)),
          timestamp: Date.now(),
          isFallEvent: fallCount <= 5
        })
      }

      if (fallCount >= 10) {
        clearInterval(fallTimer)
      }
    }, 100)
  }

  /**
   * 获取当前模拟状态
   */
  getStatus() {
    return {
      isRunning: this.isRunning,
      mode: this.state.heartRate.base === 72 ? 'normal' : 'abnormal',
      lastValues: { ...this.lastValues }
    }
  }
}

export default MockSensorService
