/**
 * 老人管理 API 接口测试
 */
import { describe, it, expect, beforeAll, afterAll, afterEach } from 'vitest';
import { elderlyAPI } from '../index';
import { server } from '@/test/mocks/server';

// 启动 MSW
beforeAll(() => server.listen());
afterAll(() => server.close());
afterEach(() => server.resetHandlers());

// 设置 Token（API 请求需要）
beforeAll(() => {
  localStorage.setItem('access_token', 'mock_token');
});

describe('elderlyAPI.getList', () => {
  it('返回分页数据结构和数据', async () => {
    const res = await elderlyAPI.getList({ page: 1, page_size: 10 });
    expect(res.data.list).toBeInstanceOf(Array);
    expect(res.data.total).toBeGreaterThan(0);
    expect(res.data.page).toBe(1);
  });

  it('支持 keyword 搜索过滤', async () => {
    const res = await elderlyAPI.getList({ page: 1, page_size: 10, status: 'active' });
    expect(res.data.list.every((e: any) => e.status === 'active')).toBe(true);
  });
});

describe('elderlyAPI.getDetail', () => {
  it('返回指定 ID 的老人详情', async () => {
    const res = await elderlyAPI.getDetail('e001');
    expect(res.data.id).toBe('e001');
    expect(res.data.real_name).toBeTruthy();
  });
});

describe('elderlyAPI.create', () => {
  it('创建成功后返回新老人数据', async () => {
    const res = await elderlyAPI.create({
      real_name: '测试老人',
      gender: 'M',
      age: 75,
      phone: '13800001111',
      community_id: 'c001',
      emergency_contact_name: '测试联系人',
      emergency_contact_phone: '13900001111',
    });
    expect(res.code).toBe(0);
    expect(res.data.real_name).toBe('测试老人');
  });
});

describe('elderlyAPI.update', () => {
  it('更新成功后返回更新后的数据', async () => {
    const res = await elderlyAPI.update('e001', { real_name: '更新后姓名' });
    expect(res.code).toBe(0);
    expect(res.data.real_name).toBe('更新后姓名');
  });
});

describe('elderlyAPI.delete', () => {
  it('删除成功不报错', async () => {
    await expect(elderlyAPI.delete('e001')).resolves.toBeDefined();
  });
});
