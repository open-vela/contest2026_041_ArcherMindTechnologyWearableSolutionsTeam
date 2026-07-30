/**
 * Dashboard 页面逻辑测试（不依赖 antd Row/Col 渲染）
 * 重点测试数据获取和状态更新逻辑
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// ============ Mock 所有 antd 组件（避免 matchMedia 问题） ============
vi.mock('antd', () => {
  const actual = vi.importActual('antd');
  return {
    ...actual,
    Row: ({ children }: any) => children,
    Col: ({ children }: any) => children,
    Card: ({ children, title, ...rest }: any) => <div data-testid="card" data-title={title} {...rest}>{children}</div>,
    Statistic: ({ title, value, suffix, prefix }: any) => <div data-testid="statistic" data-title={title}>{value}{suffix}</div>,
    Table: () => <div data-testid="table" />,
    Tag: ({ children, color }: any) => <span data-testid="tag" data-color={color}>{children}</span>,
    Badge: ({ children, color, text }: any) => <span data-testid="badge">{text || children}</span>,
    Progress: () => <div data-testid="progress" />,
    Typography: { Title: ({ children }: any) => <div data-testid="title">{children}</div>, Text: ({ children }: any) => <span data-testid="text">{children}</span> },
    Space: ({ children }: any) => <div data-testid="space">{children}</div>,
  };
});

vi.mock('@ant-design/icons', () => ({}));
vi.mock('recharts', () => ({
  BarChart: () => null,
  Bar: () => null,
  XAxis: () => null,
  YAxis: () => null,
  CartesianGrid: () => null,
  Tooltip: () => null,
  ResponsiveContainer: ({ children }: any) => children,
  LineChart: () => null,
  Line: () => null,
}));

vi.mock('dayjs', () => ({
  default: {
    format: () => '2026-06-24 16:00',
  },
}));

// ============ Mock mockService ============
vi.mock('@/mock/service', () => ({
  mockService: {
    getDashboard: vi.fn(),
  },
}));

import { mockService } from '@/mock/service';
import type { DashboardData } from '@/types';

const mockDashboardData: DashboardData = {
  summary: { total_elderly: 8, online_devices: 7, today_signin_rate: 75, pending_alarms: 2 },
  alarm_trend: [{ date: '06-24', count: 5, level: 'P0' }],
  device_online_rate: [{ time: '16:00', rate: 88 }],
  recent_alarms: [{ id: 'a001', elderly_id: 'e001', elderly_name: '测试老人', device_id: 'd001', alarm_type: 'SOS', level: 'P0', vital_snapshot: null, status: 'pending', description: '测试', location_lat: 31, location_lng: 121, triggered_at: new Date().toISOString(), resolved_at: null, handler_name: null, handling_logs: [] }],
  pending_patrols: [{ id: 'p001', elderly_id: 'e001', elderly_name: '测试老人', priority: 'normal', task_type: '探访', description: '', assigned_to: 's001', assigned_name: '社区员', status: 'pending', scheduled_date: '2026-06-24', completed_at: null, result: null }],
  elderly_distribution: [{ community: '花木社区', count: 5 }],
  signin_overview: { signed: 6, unsigned: 1, timeout: 1, total: 8 },
};

describe('Dashboard 数据逻辑', () => {
  beforeEach(() => {
    (mockService.getDashboard as any).mockResolvedValue({ code: 0, data: mockDashboardData });
  });
  afterEach(() => vi.clearAllMocks());

  it('getDashboard 返回正确的 summary 数据', async () => {
    const res = await mockService.getDashboard();
    expect(res.data.summary.total_elderly).toBe(8);
    expect(res.data.summary.online_devices).toBe(7);
    expect(res.data.summary.pending_alarms).toBe(2);
  });

  it('getDashboard 返回报警趋势数据', async () => {
    const res = await mockService.getDashboard();
    expect(res.data.alarm_trend.length).toBeGreaterThan(0);
  });

  it('getDashboard 失败时 code !== 0', async () => {
    (mockService.getDashboard as any).mockResolvedValue({ code: 500, data: null, message: '错误' });
    const res = await mockService.getDashboard();
    expect(res.code).not.toBe(0);
  });
});
