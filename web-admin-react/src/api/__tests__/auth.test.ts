/**
 * 认证 API 接口测试
 */
import { describe, it, expect, beforeAll, afterAll, afterEach } from 'vitest';
import { authAPI } from '../index';
import { server } from '@/test/mocks/server';

// 启动 MSW
beforeAll(() => server.listen());
afterAll(() => server.close());
afterEach(() => server.resetHandlers());

describe('authAPI.login', () => {
  it('正确用户名密码返回 access_token', async () => {
    const res = await authAPI.login({ username: 'admin', password: 'Admin@2026' });
    expect(res.data.access_token).toBeTruthy();
    expect(res.data.user.username).toBe('admin');
  });

  it('错误密码返回 401', async () => {
    await expect(
      authAPI.login({ username: 'admin', password: 'wrong_password' }),
    ).rejects.toThrow();
  });
});

describe('authAPI.getProfile', () => {
  it('能获取用户信息', async () => {
    localStorage.setItem('access_token', 'mock_token');
    const res = await authAPI.getProfile();
    expect(res.data.username).toBe('admin');
    expect(res.data.role).toBe('super_admin');
  });
});

describe('authAPI.logout', () => {
  it('登出成功返回成功消息', async () => {
    localStorage.setItem('access_token', 'mock_token');
    const res = await authAPI.logout();
    expect(res.code).toBe(0);
  });
});
