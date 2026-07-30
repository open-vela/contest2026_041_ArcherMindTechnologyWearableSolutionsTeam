/**
 * 集成测试示例：连真实后端服务器
 *
 * 运行方式：
 *   npm run test:integration
 *
 * 前置条件：
 *   1. 后端服务器已启动（docker compose up -d）
 *   2. .env.test 中 VITE_USE_MOCK=false
 *   3. 数据库中有测试数据
 */

import { describe, it, expect, beforeAll } from 'vitest';
import axios from 'axios';
import { INTEGRATION_CONFIG, checkBackendHealth } from '../config';

const apiClient = axios.create({
  baseURL: INTEGRATION_CONFIG.baseURL,
  timeout: INTEGRATION_CONFIG.timeout,
  headers: { 'Content-Type': 'application/json' },
});

describe('集成测试：认证 API（连真实后端）', () => {
  beforeAll(async () => {
    if (!INTEGRATION_CONFIG.useMock) {
      const isHealthy = await checkBackendHealth();
      if (!isHealthy) {
        throw new Error('后端服务器不可达，请先启动后端服务');
      }
    }
  });

  it('正确凭据能登录成功', async () => {
    const response = await apiClient.post('/api/v1/auth/login', {
      username: INTEGRATION_CONFIG.testUser.username,
      password: INTEGRATION_CONFIG.testUser.password,
    });

    expect(response.status).toBe(200);
    expect(response.data.code).toBe(0);
    expect(response.data.data.access_token).toBeTruthy();
  });

  it('错误密码返回 401', async () => {
    try {
      await apiClient.post('/api/v1/auth/login', {
        username: INTEGRATION_CONFIG.testUser.username,
        password: 'wrong_password',
      });
      expect(true).toBe(false); // 不应该到这里
    } catch (error: any) {
      expect(error.response.status).toBe(401);
    }
  });
});

describe('集成测试：老人管理 API', () => {
  let accessToken: string;

  beforeAll(async () => {
    // 先登录获取 Token
    const loginRes = await apiClient.post('/api/v1/auth/login', {
      username: INTEGRATION_CONFIG.testUser.username,
      password: INTEGRATION_CONFIG.testUser.password,
    });
    accessToken = loginRes.data.data.access_token;
  });

  it('获取老人列表', async () => {
    const response = await apiClient.get('/api/v1/elderly', {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    expect(response.status).toBe(200);
    expect(response.data.code).toBe(0);
    expect(Array.isArray(response.data.data)).toBe(true);
  });

  it('无 Token 访问返回 401', async () => {
    try {
      await apiClient.get('/api/v1/elderly');
      expect(true).toBe(false);
    } catch (error: any) {
      expect(error.response.status).toBe(401);
    }
  });
});
