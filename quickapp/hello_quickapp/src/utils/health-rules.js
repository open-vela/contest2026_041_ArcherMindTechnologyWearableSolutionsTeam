import { VITAL_RANGES, TIP_LEVELS } from './constants'

/**
 * 健康提示规则引擎
 * 根据体征数据判断是否需要生成健康提示
 */
export class HealthRulesEngine {
  constructor() {
    this.lastTipTime = {}
    this.tipCooldown = 5 * 60 * 1000 // 5分钟提示冷却时间
  }

  /**
   * 检查体征数据并生成提示
   * @param {Object} vitals - 体征数据
   * @returns {Object|null} 健康提示对象
   */
  checkVitals(vitals) {
    const { heartRate, spo2, temperature } = vitals

    // 优先级：严重 > 警告 > 提示
    const tips = []

    // 检查血氧
    if (spo2 !== null && spo2 > 0) {
      const spo2Tip = this.checkSpo2(spo2)
      if (spo2Tip) tips.push(spo2Tip)
    }

    // 检查心率
    if (heartRate !== null && heartRate > 0) {
      const heartRateTip = this.checkHeartRate(heartRate)
      if (heartRateTip) tips.push(heartRateTip)
    }

    // 检查体温
    if (temperature !== null && temperature > 0) {
      const tempTip = this.checkTemperature(temperature)
      if (tempTip) tips.push(tempTip)
    }

    // 按严重程度排序
    tips.sort((a, b) => {
      const levelOrder = { danger: 0, warning: 1, info: 2 }
      return levelOrder[a.level] - levelOrder[b.level]
    })

    // 返回最严重的提示（如果有）
    if (tips.length > 0) {
      const tip = tips[0]
      if (this.canShowTip(tip.type)) {
        this.lastTipTime[tip.type] = Date.now()
        return tip
      }
    }

    return null
  }

  /**
   * 检查血氧
   */
  checkSpo2(spo2) {
    if (spo2 < VITAL_RANGES.spo2.danger) {
      return {
        type: 'spo2',
        level: TIP_LEVELS.DANGER,
        message: '血氧异常，正在呼叫帮助',
        value: spo2
      }
    }

    if (spo2 < VITAL_RANGES.spo2.warning) {
      return {
        type: 'spo2',
        level: TIP_LEVELS.WARNING,
        message: '血氧偏低，建议深呼吸',
        value: spo2
      }
    }

    return null
  }

  /**
   * 检查心率
   */
  checkHeartRate(heartRate) {
    if (heartRate < VITAL_RANGES.heartRate.dangerLow ||
        heartRate > VITAL_RANGES.heartRate.dangerHigh) {
      return {
        type: 'heartRate',
        level: TIP_LEVELS.DANGER,
        message: '心率异常，正在呼叫帮助',
        value: heartRate
      }
    }

    if (heartRate < VITAL_RANGES.heartRate.warningLow) {
      return {
        type: 'heartRate',
        level: TIP_LEVELS.WARNING,
        message: '心率偏低，请注意',
        value: heartRate
      }
    }

    if (heartRate > VITAL_RANGES.heartRate.warningHigh) {
      return {
        type: 'heartRate',
        level: TIP_LEVELS.WARNING,
        message: '心率偏高，建议休息',
        value: heartRate
      }
    }

    return null
  }

  /**
   * 检查体温
   */
  checkTemperature(temperature) {
    if (temperature < VITAL_RANGES.temperature.warningLow) {
      return {
        type: 'temperature',
        level: TIP_LEVELS.WARNING,
        message: '体温偏低，注意保暖',
        value: temperature
      }
    }

    if (temperature > VITAL_RANGES.temperature.warningHigh) {
      return {
        type: 'temperature',
        level: TIP_LEVELS.WARNING,
        message: '体温偏高，注意休息',
        value: temperature
      }
    }

    return null
  }

  /**
   * 检查是否可以显示提示（冷却时间）
   */
  canShowTip(type) {
    const lastTime = this.lastTipTime[type]
    if (!lastTime) return true
    return Date.now() - lastTime >= this.tipCooldown
  }

  /**
   * 检查是否需要触发报警
   */
  shouldTriggerAlarm(vitals) {
    const { heartRate, spo2 } = vitals

    // P0 紧急报警条件
    if (spo2 !== null && spo2 < VITAL_RANGES.spo2.danger) {
      return { level: 'P0', reason: '血氧严重异常' }
    }

    if (heartRate !== null) {
      if (heartRate < VITAL_RANGES.heartRate.dangerLow ||
          heartRate > VITAL_RANGES.heartRate.dangerHigh) {
        return { level: 'P0', reason: '心率严重异常' }
      }
    }

    // P1 严重报警条件
    if (spo2 !== null && spo2 < VITAL_RANGES.spo2.warning) {
      return { level: 'P1', reason: '血氧偏低' }
    }

    if (heartRate !== null) {
      if (heartRate < VITAL_RANGES.heartRate.warningLow ||
          heartRate > VITAL_RANGES.heartRate.warningHigh) {
        return { level: 'P1', reason: '心率异常' }
      }
    }

    return null
  }
}

/**
 * 跌倒检测器
 */
export class FallDetector {
  constructor() {
    this.accelBuffer = []
    this.bufferSize = 50
    this.isFallDetected = false
    this.lastFallTime = 0
    this.fallCooldown = 60 * 1000 // 1分钟冷却时间
  }

  /**
   * 添加加速度数据
   */
  addAcceleration(data) {
    this.accelBuffer.push({
      x: data.x,
      y: data.y,
      z: data.z,
      timestamp: data.timestamp
    })

    if (this.accelBuffer.length > this.bufferSize) {
      this.accelBuffer.shift()
    }

    this.analyzeData()
  }

  /**
   * 分析加速度数据
   */
  analyzeData() {
    if (this.accelBuffer.length < 10) return

    // 计算加速度 magnitude
    const magnitudes = this.accelBuffer.map(d =>
      Math.sqrt(d.x * d.x + d.y * d.y + d.z * d.z)
    )

    // 第一级：阈值判断
    const maxMag = Math.max(...magnitudes)
    const minMag = Math.min(...magnitudes)
    const threshold = 25 // m/s²

    if (maxMag - minMag > threshold) {
      // 第二级：姿态特征识别（简化版）
      // 检查是否有突然的加速度变化
      const lastFew = magnitudes.slice(-5)
      const avgRecent = lastFew.reduce((a, b) => a + b, 0) / lastFew.length

      if (avgRecent > 20) {
        // 第三级：上下文验证（简化版）
        // 检查是否在合理时间间隔内
        const now = Date.now()
        if (now - this.lastFallTime > this.fallCooldown) {
          this.isFallDetected = true
          this.lastFallTime = now
          console.log('跌倒检测触发')
        }
      }
    }
  }

  /**
   * 检查是否检测到跌倒
   */
  checkFall() {
    if (this.isFallDetected) {
      this.isFallDetected = false
      return true
    }
    return false
  }

  /**
   * 重置检测器
   */
  reset() {
    this.accelBuffer = []
    this.isFallDetected = false
  }
}

export default HealthRulesEngine
