/**
 * 集成测试配置
 * 当 VITE_USE_MOCK=false 时，测试会连真实后端服务器
 */

export const INTEGRATION_CONFIG = {
  // API 服务器地址
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080',

  // WebSocket 地址
  wsURL: import.meta.env.VITE_WS_URL || 'ws://localhost:8080',

  // 是否使用 Mock（从环境变量读取）
  useMock: import.meta.env.VITE_USE_MOCK !== 'false',

  // 测试用户凭据
  testUser: {
    username: import.meta.env.TEST_USERNAME || 'admin',
    password: import.meta.env.TEST_PASSWORD || 'Admin@2026',
  },

  // 测试超时（毫秒）
  timeout: 10000,

  // 后端服务端口（用于健康检查）
  healthCheckURL: import.meta.env.VITE_API_BASE_URL
    ? `${import.meta.env.VITE_API_BASE_URL}/health`
    : 'http://localhost:8080/health',
};

/**
 * 检查后端服务器是否可达
 */
export async function checkBackendHealth(): Promise<boolean> {
  if (INTEGRATION_CONFIG.useMock) {
    return true; // Mock 模式不需要检查
  }

  try {
    const response = await fetch(INTEGRATION_CONFIG.healthCheckURL, {
      method: 'GET',
      signal: AbortSignal.timeout(3000),
    });
    return response.ok;
  } catch {
    console.warn(`⚠️  后端服务器不可达: ${INTEGRATION_CONFIG.baseURL}`);
    console.warn('   请确认后端已启动，或设置 VITE_USE_MOCK=true 使用 Mock 模式');
    return false;
  }
}

/**
 * 获取当前测试模式
 */
export function getTestMode(): 'mock' | 'integration' {
  return INTEGRATION_CONFIG.useMock ? 'mock' : 'integration';
}
