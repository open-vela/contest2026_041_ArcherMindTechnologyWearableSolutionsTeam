// Mock 服务层：模拟后端 API 响应，便于前端独立开发和演示
// 切换到真实 API 只需修改 api/index.ts 中的调用即可

import {
  mockElderly, mockDevices, mockAlarms, mockSigninRecords, mockPatrolTasks,
  mockReports, mockDashboard, mockAdminRoles, mockAuditLogs,
  mockSystemConfig, mockSystemStatus,
  delay, paginate,
} from './data';
import type {
  ApiResponse, PaginatedResponse, PaginationParams, LoginResponse, UserInfo,
  ElderlyProfile, Device, AlarmRecord, SigninRecord, SigninCalendar,
  PatrolTask, HealthReport, AdminRole, AdminPermission, AuditLog,
  SystemConfig, SystemStatus, DashboardData,
} from '@/types';

// 管理员 permission 列表
const mockPermissions: AdminPermission[] = [
  { id: 'p001', perm_code: 'admin:manage', perm_name: '管理员管理', module: 'admin', action: 'manage', sensitivity: 'CRITICAL' },
  { id: 'p002', perm_code: 'admin:read', perm_name: '查看管理员', module: 'admin', action: 'read', sensitivity: 'HIGH' },
  { id: 'p003', perm_code: 'elderly:manage', perm_name: '老人档案管理', module: 'elderly', action: 'manage', sensitivity: 'HIGH' },
  { id: 'p004', perm_code: 'elderly:read', perm_name: '查看老人档案', module: 'elderly', action: 'read', sensitivity: 'MEDIUM' },
  { id: 'p005', perm_code: 'device:manage', perm_name: '设备管理', module: 'device', action: 'manage', sensitivity: 'HIGH' },
  { id: 'p006', perm_code: 'device:read', perm_name: '查看设备', module: 'device', action: 'read', sensitivity: 'LOW' },
  { id: 'p007', perm_code: 'alarm:handle', perm_name: '处理报警', module: 'alarm', action: 'handle', sensitivity: 'CRITICAL' },
  { id: 'p008', perm_code: 'alarm:escalate', perm_name: '升级报警', module: 'alarm', action: 'escalate', sensitivity: 'CRITICAL' },
  { id: 'p009', perm_code: 'alarm:read', perm_name: '查看报警', module: 'alarm', action: 'read', sensitivity: 'HIGH' },
  { id: 'p010', perm_code: 'signin:proxy', perm_name: '代签操作', module: 'signin', action: 'proxy', sensitivity: 'MEDIUM' },
  { id: 'p011', perm_code: 'signin:read', perm_name: '查看签到', module: 'signin', action: 'read', sensitivity: 'LOW' },
  { id: 'p012', perm_code: 'patrol:manage', perm_name: '巡访管理', module: 'patrol', action: 'manage', sensitivity: 'HIGH' },
  { id: 'p013', perm_code: 'patrol:read', perm_name: '查看巡访', module: 'patrol', action: 'read', sensitivity: 'MEDIUM' },
  { id: 'p014', perm_code: 'report:read', perm_name: '查看周报', module: 'report', action: 'read', sensitivity: 'MEDIUM' },
  { id: 'p015', perm_code: 'dashboard:read', perm_name: '查看看板', module: 'dashboard', action: 'read', sensitivity: 'LOW' },
  { id: 'p016', perm_code: 'system:manage', perm_name: '系统运维', module: 'system', action: 'manage', sensitivity: 'CRITICAL' },
];

// 保存原始数据的引用，支持增删改
let elderlyData = [...mockElderly];
let devicesData = [...mockDevices];
let alarmsData = [...mockAlarms];
let signinData = [...mockSigninRecords];
let patrolData = [...mockPatrolTasks];
let reportsData = [...mockReports];

function ok<T>(data: T): ApiResponse<T> {
  return { code: 0, message: 'success', data };
}

function err(code: number, message: string): ApiResponse {
  return { code, message, data: null as never };
}

const mockAdminUsers: UserInfo[] = [
  { id: 'adm001', username: 'admin', phone: '138****0000', email: 'admin@elderly-health.com', role: 'admin', real_name: '系统管理员', avatar_url: '', community_id: '', community_name: '', permissions: mockPermissions.map((p) => p.perm_code) },
  { id: 'adm002', username: 'zhangys', phone: '138****0001', email: 'zhangys@elderly-health.com', role: 'admin', real_name: '社区张医生', avatar_url: '', community_id: 'c001', community_name: '花木社区', permissions: ['elderly:read', 'device:read', 'alarm:handle', 'alarm:read', 'signin:read', 'patrol:manage', 'patrol:read', 'report:read', 'dashboard:read'] },
  { id: 'adm003', username: 'xiaowang', phone: '138****0002', email: 'xiaowang@elderly-health.com', role: 'admin', real_name: '社区小王', avatar_url: '', community_id: 'c001', community_name: '花木社区', permissions: ['elderly:read', 'device:read', 'alarm:handle', 'alarm:read', 'signin:proxy', 'signin:read', 'patrol:manage', 'patrol:read', 'report:read', 'dashboard:read'] },
  { id: 'adm004', username: 'viewer01', phone: '138****0003', email: '', role: 'admin', real_name: '观察员A', avatar_url: '', community_id: '', community_name: '', permissions: ['dashboard:read', 'report:read'] },
];

export const mockService = {
  // ========== 认证 ==========
  async login(username: string, password: string): Promise<ApiResponse<LoginResponse>> {
    await delay(500);
    if (username === 'admin' && password === 'Admin@2026') {
      const user = mockAdminUsers[0];
      const token = 'mock-jwt-token-' + Date.now();
      const refreshToken = 'mock-refresh-token-' + Date.now();
      localStorage.setItem('access_token', token);
      localStorage.setItem('refresh_token', refreshToken);
      return ok({ access_token: token, refresh_token: refreshToken, expires_in: 28800, user });
    }
    if (username === 'zhangys' && password === 'Admin@2026') {
      const user = mockAdminUsers[1];
      const token = 'mock-jwt-token-' + Date.now();
      const refreshToken = 'mock-refresh-token-' + Date.now();
      localStorage.setItem('access_token', token);
      localStorage.setItem('refresh_token', refreshToken);
      return ok({ access_token: token, refresh_token: refreshToken, expires_in: 28800, user });
    }
    throw new Error('用户名或密码错误');
  },

  async profile(): Promise<ApiResponse<UserInfo>> {
    await delay(200);
    const cached = localStorage.getItem('user_info');
    if (cached) return ok(JSON.parse(cached));
    return ok(mockAdminUsers[0]);
  },

  async logout(): Promise<ApiResponse<null>> {
    await delay(100);
    return ok(null);
  },

  // ========== 老人管理 ==========
  async getElderlyList(params: PaginationParams) {
    await delay(300);
    let filtered = [...elderlyData];
    if (params.keyword) {
      const kw = params.keyword.toLowerCase();
      filtered = filtered.filter((e) =>
        e.real_name.includes(kw) || e.phone.includes(kw) || e.address.includes(kw),
      );
    }
    return ok(paginate(filtered, params.page, params.page_size));
  },

  async getElderlyDetail(id: string) {
    await delay(200);
    const item = elderlyData.find((e) => e.id === id);
    return item ? ok(item) : err(404, '老人档案不存在');
  },

  async createElderly(data: Partial<ElderlyProfile>) {
    await delay(300);
    const item: ElderlyProfile = {
      id: 'e' + Date.now(),
      user_id: 'u' + Date.now(),
      real_name: data.real_name || '',
      nickname: data.nickname || '',
      gender: data.gender || 'M',
      age: data.age || 70,
      birthday: data.birthday || '',
      id_card: data.id_card || '',
      avatar_url: '',
      phone: data.phone || '',
      emergency_contact_name: data.emergency_contact_name || '',
      emergency_contact_phone: data.emergency_contact_phone || '',
      address: data.address || '',
      community_id: data.community_id || 'c001',
      community_name: data.community_name || '花木社区',
      health_history: data.health_history || [],
      allergies: data.allergies || [],
      medications: data.medications || [],
      device_count: 0,
      latest_vital: null,
      status: 'active',
    };
    elderlyData = [item, ...elderlyData];
    return ok(item);
  },

  async updateElderly(id: string, data: Partial<ElderlyProfile>) {
    await delay(300);
    const idx = elderlyData.findIndex((e) => e.id === id);
    if (idx === -1) return err(404, '老人档案不存在');
    elderlyData[idx] = { ...elderlyData[idx], ...data };
    return ok(elderlyData[idx]);
  },

  async deleteElderly(id: string) {
    await delay(200);
    elderlyData = elderlyData.filter((e) => e.id !== id);
    return ok(null);
  },

  // ========== 设备管理 ==========
  async getDevices(params: PaginationParams & { status?: string }) {
    await delay(300);
    let filtered = [...devicesData];
    if (params.keyword) {
      const kw = params.keyword.toLowerCase();
      filtered = filtered.filter((d) => d.device_sn.toLowerCase().includes(kw) || d.elderly_name.includes(kw));
    }
    if (params.status) {
      filtered = filtered.filter((d) => d.status === params.status);
    }
    return ok(paginate(filtered, params.page, params.page_size));
  },

  async getDeviceDetail(id: string) {
    await delay(200);
    const item = devicesData.find((d) => d.id === id);
    return item ? ok(item) : err(404, '设备不存在');
  },

  // ========== 报警管理 ==========
  async getAlarms(params: PaginationParams & { level?: string; status?: string }) {
    await delay(300);
    let filtered = [...alarmsData];
    if (params.keyword) {
      const kw = params.keyword.toLowerCase();
      filtered = filtered.filter((a) => a.elderly_name.includes(kw) || a.description.includes(kw));
    }
    if (params.level) filtered = filtered.filter((a) => a.level === params.level);
    if (params.status) filtered = filtered.filter((a) => a.status === params.status);
    return ok(paginate(filtered, params.page, params.page_size));
  },

  async getAlarmDetail(id: string) {
    await delay(200);
    const item = alarmsData.find((a) => a.id === id);
    return item ? ok(item) : err(404, '报警记录不存在');
  },

  async confirmAlarm(id: string) {
    await delay(300);
    const idx = alarmsData.findIndex((a) => a.id === id);
    if (idx === -1) return err(404, '报警记录不存在');
    alarmsData[idx] = { ...alarmsData[idx], status: 'confirmed' };
    return ok(alarmsData[idx]);
  },

  async escalateAlarm(id: string) {
    await delay(300);
    const idx = alarmsData.findIndex((a) => a.id === id);
    if (idx === -1) return err(404, '报警记录不存在');
    alarmsData[idx] = { ...alarmsData[idx], status: 'escalated', level: 'P0' };
    return ok(alarmsData[idx]);
  },

  async resolveAlarm(id: string) {
    await delay(300);
    const idx = alarmsData.findIndex((a) => a.id === id);
    if (idx === -1) return err(404, '报警记录不存在');
    alarmsData[idx] = { ...alarmsData[idx], status: 'resolved', resolved_at: new Date().toISOString() };
    return ok(alarmsData[idx]);
  },

  // ========== 签到管理 ==========
  async getSignins(params: PaginationParams & { date?: string; status?: string }) {
    await delay(300);
    let filtered = [...signinData];
    if (params.keyword) {
      filtered = filtered.filter((s) => s.elderly_name.includes(params.keyword!));
    }
    if (params.status) filtered = filtered.filter((s) => s.status === params.status);
    return ok(paginate(filtered, params.page, params.page_size));
  },

  async proxySignin(elderlyId: string) {
    await delay(300);
    const item = signinData.find((s) => s.elderly_id === elderlyId && s.status !== 'signed');
    if (item) {
      item.status = 'signed';
      item.signin_time = new Date().toISOString();
      item.method = 'proxy';
      item.proxy_by = '当前用户';
    }
    return ok(null);
  },

  async getCommunityOverview() {
    await delay(200);
    const total = signinData.length;
    const signed = signinData.filter((s) => s.status === 'signed').length;
    const unsigned = signinData.filter((s) => s.status === 'unsigned').length;
    const timeout = signinData.filter((s) => s.status === 'timeout').length;
    return ok({ signed, unsigned, timeout, total, rate: Math.round((signed / total) * 100) });
  },

  // ========== 巡访管理 ==========
  async getPatrolTasks(params: PaginationParams) {
    await delay(300);
    let filtered = [...patrolData];
    if (params.keyword) {
      filtered = filtered.filter((p) => p.elderly_name.includes(params.keyword!) || p.task_type.includes(params.keyword!));
    }
    return ok(paginate(filtered, params.page, params.page_size));
  },

  async createPatrolTask(data: Partial<PatrolTask>) {
    await delay(300);
    const task: PatrolTask = {
      id: 'p' + Date.now(),
      elderly_id: data.elderly_id || '',
      elderly_name: data.elderly_name || '',
      priority: data.priority || 'normal',
      task_type: data.task_type || '',
      description: data.description || '',
      assigned_to: data.assigned_to || '',
      assigned_name: data.assigned_name || '',
      status: 'pending',
      scheduled_date: data.scheduled_date || new Date().toISOString().split('T')[0],
      completed_at: null,
      result: null,
    };
    patrolData = [task, ...patrolData];
    return ok(task);
  },

  async assignTask(taskId: string, staffId: string) {
    await delay(200);
    const task = patrolData.find((t) => t.id === taskId);
    if (task) task.assigned_to = staffId;
    return ok(null);
  },

  // ========== 健康周报 ==========
  async getReports(params: PaginationParams) {
    await delay(300);
    return ok(paginate(reportsData, params.page, params.page_size));
  },

  async getReportDetail(id: string) {
    await delay(200);
    const item = reportsData.find((r) => r.id === id);
    return item ? ok(item) : err(404, '健康周报不存在');
  },

  async generateReport() {
    await delay(1500);
    const report = reportsData[0];
    report.id = 'r' + Date.now();
    report.report_week = '2026-W26';
    report.status = 'draft';
    reportsData = [report, ...reportsData];
    return ok(report);
  },

  // ========== 社区看板 ==========
  async getDashboard(): Promise<ApiResponse<DashboardData>> {
    await delay(400);
    return ok(mockDashboard);
  },

  // ========== 管理员管理 ==========
  async getAdmins(params: PaginationParams) {
    await delay(300);
    return ok(paginate(mockAdminUsers, params.page, params.page_size));
  },

  async createAdmin(data: Partial<UserInfo> & { password: string }) {
    await delay(300);
    const user: UserInfo = {
      id: 'adm' + Date.now(),
      username: data.username || '',
      phone: data.phone || '',
      email: data.email || '',
      role: data.role || 'admin',
      real_name: data.real_name || '',
      avatar_url: '',
      community_id: data.community_id || '',
      community_name: data.community_name || '',
      permissions: [],
    };
    mockAdminUsers.push(user);
    return ok(user);
  },

  async getRoles() {
    await delay(200);
    return ok(mockAdminRoles);
  },

  async updateRolePermissions(roleId: string, permIds: string[]) {
    await delay(300);
    const role = mockAdminRoles.find((r) => r.id === roleId);
    if (role) role.permissions = mockPermissions.filter((p) => permIds.includes(p.id));
    return ok(null);
  },

  async getAuditLogs(params: PaginationParams) {
    await delay(300);
    return ok(paginate(mockAuditLogs, params.page, params.page_size));
  },

  // ========== 系统设置 ==========
  async getSystemConfig() {
    await delay(200);
    return ok(mockSystemConfig);
  },

  async updateSystemConfig(data: Partial<SystemConfig>) {
    await delay(300);
    Object.assign(mockSystemConfig, data);
    return ok(null);
  },

  async getSystemStatus() {
    await delay(300);
    return ok(mockSystemStatus);
  },
};
