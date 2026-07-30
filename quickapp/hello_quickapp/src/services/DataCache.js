/**
 * 数据缓存服务
 * 72 小时 RingBuffer 缓存，支持体征数据存储和查询
 */
import storage from '@system.storage'
import { STORAGE_KEYS } from '../utils/constants'

// 72小时 = 72 * 60 * 60 * 1000 = 259200000ms
const CACHE_DURATION = 72 * 60 * 60 * 1000
// 每5秒采集一次，72小时约 51840 条数据
const MAX_RECORDS = 52000

export class DataCache {
  constructor() {
    this.vitalBuffer = []
    this.isLoaded = false
  }

  /**
   * 初始化缓存，从存储加载数据
   */
  init(callback) {
    storage.get({
      key: STORAGE_KEYS.VITAL_HISTORY,
      success: (data) => {
        if (data) {
          try {
            this.vitalBuffer = JSON.parse(data)
            // 过滤过期数据
            this.cleanExpired()
          } catch (e) {
            console.error('解析缓存数据失败:', e)
            this.vitalBuffer = []
          }
        }
        this.isLoaded = true
        if (callback) callback()
      },
      fail: (data, code) => {
        console.error(`读取缓存失败: code=${code}`)
        this.vitalBuffer = []
        this.isLoaded = true
        if (callback) callback()
      }
    })
  }

  /**
   * 添加体征数据到缓存
   * @param {Object} packet - VitalSignPacket
   */
  addVitalData(packet) {
    const record = {
      heartRate: packet.heartRate,
      spo2: packet.spo2,
      temperature: packet.temperature,
      timestamp: packet.timestamp || Date.now(),
      steps: packet.steps || 0,
      isAbnormal: packet.isAbnormal || false
    }

    this.vitalBuffer.push(record)

    // RingBuffer 策略：超出最大数量时移除最早数据
    if (this.vitalBuffer.length > MAX_RECORDS) {
      this.vitalBuffer.shift()
    }

    // 定期保存到存储
    this.saveToStorage()
  }

  /**
   * 获取指定时间范围内的数据
   * @param {Number} hours - 时间范围（小时）
   * @returns {Array} 数据数组
   */
  getDataByHours(hours) {
    const now = Date.now()
    const startTime = now - hours * 60 * 60 * 1000

    return this.vitalBuffer.filter(record =>
      record.timestamp >= startTime
    )
  }

  /**
   * 获取最新的体征数据
   * @returns {Object|null} 最新数据
   */
  getLatestVital() {
    if (this.vitalBuffer.length === 0) return null
    return this.vitalBuffer[this.vitalBuffer.length - 1]
  }

  /**
   * 获取今日活动数据
   * @returns {Object} 活动数据
   */
  getTodayActivity() {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const todayStart = today.getTime()

    const todayData = this.vitalBuffer.filter(record =>
      record.timestamp >= todayStart
    )

    // 从步数传感器获取最新步数（简化：取最大值）
    let maxSteps = 0
    todayData.forEach(record => {
      if (record.steps > maxSteps) {
        maxSteps = record.steps
      }
    })

    return {
      steps: maxSteps,
      activeMinutes: Math.floor(todayData.length * 5 / 60), // 假设每5秒采集一次
      calories: Math.floor(maxSteps * 0.04) // 简化计算：每步约0.04卡路里
    }
  }

  /**
   * 获取待上传的数据包
   * @param {Number} maxCount - 最大数量
   * @returns {Array} 待上传数据
   */
  getPendingUploadData(maxCount = 100) {
    // 获取未上传的数据（简化：取最近的数据）
    const pendingData = this.vitalBuffer.slice(-maxCount)
    return pendingData
  }

  /**
   * 标记数据已上传（清除已上传数据）
   * @param {Number} count - 清除数量
   */
  clearUploadedData(count = 100) {
    if (this.vitalBuffer.length > count) {
      this.vitalBuffer = this.vitalBuffer.slice(count)
    } else {
      this.vitalBuffer = []
    }
    this.saveToStorage()
  }

  /**
   * 清除过期数据（超过72小时）
   */
  cleanExpired() {
    const now = Date.now()
    const expireTime = now - CACHE_DURATION

    this.vitalBuffer = this.vitalBuffer.filter(record =>
      record.timestamp > expireTime
    )
  }

  /**
   * 保存到本地存储
   */
  saveToStorage() {
    storage.set({
      key: STORAGE_KEYS.VITAL_HISTORY,
      value: JSON.stringify(this.vitalBuffer),
      success: () => {},
      fail: (data, code) => {
        console.error(`保存缓存失败: code=${code}`)
      }
    })
  }

  /**
   * 清除所有缓存数据
   */
  clearAll() {
    this.vitalBuffer = []
    storage.delete({
      key: STORAGE_KEYS.VITAL_HISTORY,
      success: () => {},
      fail: (data, code) => {
        console.error(`清除缓存失败: code=${code}`)
      }
    })
  }
}

export default DataCache
