import storage from '@system.storage'

/**
 * 异步存储操作封装
 */
export function promisify(fn) {
  return (opts = {}) => new Promise((resolve, reject) => {
    fn({
      ...opts,
      success: data => resolve(data),
      fail: (data, code) => reject({ data, code })
    })
  })
}

/**
 * 获取存储数据
 */
export function getStorage(key) {
  return new Promise((resolve, reject) => {
    storage.get({
      key: key,
      success: (data) => {
        if (data) {
          resolve(JSON.parse(data))
        } else {
          resolve(null)
        }
      },
      fail: (data, code) => {
        console.error(`获取存储失败 [${key}]:`, code)
        reject({ data, code })
      }
    })
  })
}

/**
 * 设置存储数据
 */
export function setStorage(key, value) {
  return new Promise((resolve, reject) => {
    storage.set({
      key: key,
      value: JSON.stringify(value),
      success: () => {
        resolve()
      },
      fail: (data, code) => {
        console.error(`设置存储失败 [${key}]:`, code)
        reject({ data, code })
      }
    })
  })
}

/**
 * 格式化时间戳为 HH:MM
 */
export function formatTime(timestamp) {
  const date = new Date(timestamp)
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  return `${hours}:${minutes}`
}

/**
 * 格式化时间戳为 YYYY-MM-DD
 */
export function formatDate(timestamp) {
  const date = new Date(timestamp)
  const year = date.getFullYear()
  const month = (date.getMonth() + 1).toString().padStart(2, '0')
  const day = date.getDate().toString().padStart(2, '0')
  return `${year}-${month}-${day}`
}

/**
 * 格式化体征数值
 */
export function formatVitalValue(value, type) {
  if (value === null || value === undefined || value < 0) {
    return '--'
  }

  switch (type) {
    case 'temperature':
      return value.toFixed(1)
    case 'heartRate':
    case 'spo2':
      return Math.round(value).toString()
    default:
      return value.toString()
  }
}

/**
 * 获取体征值颜色
 */
export function getVitalColor(value, type) {
  switch (type) {
    case 'heartRate':
      if (value < 50 || value > 120) return '#FF9800'
      if (value < 30 || value > 180) return '#FF6B6B'
      return '#4CAF50'
    case 'spo2':
      if (value < 92) return '#FF9800'
      if (value < 85) return '#FF6B6B'
      return '#4CAF50'
    case 'temperature':
      if (value < 35.5 || value > 37.5) return '#FF9800'
      return '#4CAF50'
    default:
      return '#4CAF50'
  }
}

/**
 * 计算步数目标完成百分比
 */
export function calculateStepsPercent(steps, goal) {
  return Math.min(100, Math.round((steps / goal) * 100))
}

/**
 * 生成唯一ID
 */
export function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2)
}

/**
 * 防抖函数
 */
export function debounce(fn, delay) {
  let timer = null
  return function() {
    if (timer) clearTimeout(timer)
    timer = setTimeout(() => {
      fn.apply(this, arguments)
    }, delay)
  }
}

/**
 * 节流函数
 */
export function throttle(fn, interval) {
  let lastTime = 0
  return function() {
    const now = Date.now()
    if (now - lastTime >= interval) {
      lastTime = now
      fn.apply(this, arguments)
    }
  }
}
