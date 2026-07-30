import apiClient from './client';
import type {
  LoginRequest,
  LoginResponse,
  ApiResponse,
  UserInfo,
  AdminRole,
  AdminPermission,
  AuditLog,
  PaginatedResponse,
  PaginationParams,
  SystemStatus,
  SystemConfig,
} from '@/types';

// ========== 认证 ==========
export const authAPI = {
  login: (data: LoginRequest) =>
    apiClient.post<ApiResponse<LoginResponse>>('/auth/login', data).then((r) => r.data),

  refresh: (refreshToken: string) =>
    apiClient.post<ApiResponse<{ access_token: string; refresh_token: string; expires_in: number }>>(
      '/auth/refresh',
      { refresh_token: refreshToken },
    ).then((r) => r.data),

  logout: () =>
    apiClient.post<ApiResponse>('/auth/logout').then((r) => r.data),

  getProfile: () =>
    apiClient.get<ApiResponse<UserInfo>>('/auth/profile').then((r) => r.data),

  changePassword: (oldPassword: string, newPassword: string) =>
    apiClient.put<ApiResponse>('/auth/password', { old_password: oldPassword, new_password: newPassword }).then((r) => r.data),
};

// ========== 老人管理 ==========
export const elderlyAPI = {
  getList: (params: PaginationParams & { community_id?: string; status?: string }) =>
    apiClient.get<ApiResponse<PaginatedResponse<import('@/types').ElderlyProfile>>>('/elderly', { params }).then((r) => r.data),

  getDetail: (id: string) =>
    apiClient.get<ApiResponse<import('@/types').ElderlyProfile>>(`/elderly/${id}`).then((r) => r.data),

  create: (data: Partial<import('@/types').ElderlyProfile>) =>
    apiClient.post<ApiResponse<import('@/types').ElderlyProfile>>('/elderly', data).then((r) => r.data),

  update: (id: string, data: Partial<import('@/types').ElderlyProfile>) =>
    apiClient.put<ApiResponse<import('@/types').ElderlyProfile>>(`/elderly/${id}`, data).then((r) => r.data),

  delete: (id: string) =>
    apiClient.delete<ApiResponse>(`/elderly/${id}`).then((r) => r.data),

  getVitalsHistory: (elderlyId: string, metric: string, range: string) =>
    apiClient.get<ApiResponse<import('@/types').VitalHistory>>(`/elderly/${elderlyId}/vitals`, {
      params: { metric, range },
    }).then((r) => r.data),
};

// ========== 设备管理 ==========
export const deviceAPI = {
  getList: (params: PaginationParams & { status?: string }) =>
    apiClient.get<ApiResponse<PaginatedResponse<import('@/types').Device>>>('/devices', { params }).then((r) => r.data),

  getDetail: (id: string) =>
    apiClient.get<ApiResponse<import('@/types').Device>>(`/devices/${id}`).then((r) => r.data),

  bind: (deviceId: string, elderlyId: string) =>
    apiClient.put<ApiResponse>(`/devices/${deviceId}/bind`, { elderly_id: elderlyId }).then((r) => r.data),

  unbind: (deviceId: string) =>
    apiClient.post<ApiResponse>(`/devices/${deviceId}/unbind`).then((r) => r.data),

  otaUpgrade: (deviceId: string, firmwareUrl: string, version: string) =>
    apiClient.post<ApiResponse>(`/devices/${deviceId}/ota`, { firmware_url: firmwareUrl, version }).then((r) => r.data),

  restart: (deviceId: string) =>
    apiClient.post<ApiResponse>(`/devices/${deviceId}/restart`).then((r) => r.data),
};

// ========== 报警管理 ==========
export const alarmAPI = {
  getList: (params: PaginationParams & { level?: string; status?: string; type?: string }) =>
    apiClient.get<ApiResponse<PaginatedResponse<import('@/types').AlarmRecord>>>('/alarms', { params }).then((r) => r.data),

  getDetail: (id: string) =>
    apiClient.get<ApiResponse<import('@/types').AlarmRecord>>(`/alarms/${id}`).then((r) => r.data),

  confirm: (id: string, comment?: string) =>
    apiClient.post<ApiResponse>(`/alarms/${id}/confirm`, { comment }).then((r) => r.data),

  escalate: (id: string) =>
    apiClient.post<ApiResponse>(`/alarms/${id}/escalate`).then((r) => r.data),

  resolve: (id: string, comment?: string) =>
    apiClient.post<ApiResponse>(`/alarms/${id}/resolve`, { comment }).then((r) => r.data),

  emergency: (id: string) =>
    apiClient.post<ApiResponse>(`/alarms/${id}/emergency`).then((r) => r.data),
};

// ========== 签到管理 ==========
export const signinAPI = {
  getList: (params: PaginationParams & { date?: string; status?: string; community_id?: string }) =>
    apiClient.get<ApiResponse<PaginatedResponse<import('@/types').SigninRecord>>>('/signin', { params }).then((r) => r.data),

  getCalendar: (elderlyId: string, month: string) =>
    apiClient.get<ApiResponse<import('@/types').SigninCalendar>>(`/signin/${elderlyId}/calendar`, { params: { month } }).then((r) => r.data),

  proxySignin: (elderlyId: string, date: string) =>
    apiClient.post<ApiResponse>('/signin/proxy', { elderly_id: elderlyId, date }).then((r) => r.data),

  getCommunityOverview: (date?: string) =>
    apiClient.get<ApiResponse<{ signed: number; unsigned: number; timeout: number; total: number; rate: number }>>(
      '/signin/overview',
      { params: { date } },
    ).then((r) => r.data),
};

// ========== 巡访管理 ==========
export const patrolAPI = {
  getTasks: (params: PaginationParams & { status?: string; priority?: string }) =>
    apiClient.get<ApiResponse<PaginatedResponse<import('@/types').PatrolTask>>>('/patrol/tasks', { params }).then((r) => r.data),

  createTask: (data: Partial<import('@/types').PatrolTask>) =>
    apiClient.post<ApiResponse<import('@/types').PatrolTask>>('/patrol/tasks', data).then((r) => r.data),

  assignTask: (taskId: string, staffId: string) =>
    apiClient.put<ApiResponse>(`/patrol/tasks/${taskId}/assign`, { staff_id: staffId }).then((r) => r.data),

  submitRecord: (taskId: string, data: { notes: string; health_check?: import('@/types').VitalSigns; photos?: string[] }) =>
    apiClient.post<ApiResponse>(`/patrol/tasks/${taskId}/submit`, data).then((r) => r.data),

  getRecords: (params: PaginationParams) =>
    apiClient.get<ApiResponse<PaginatedResponse<import('@/types').PatrolRecord>>>('/patrol/records', { params }).then((r) => r.data),
};

// ========== 健康周报 ==========
export const reportAPI = {
  getList: (params: PaginationParams & { elderly_id?: string }) =>
    apiClient.get<ApiResponse<PaginatedResponse<import('@/types').HealthReport>>>('/reports', { params }).then((r) => r.data),

  getDetail: (id: string) =>
    apiClient.get<ApiResponse<import('@/types').HealthReport>>(`/reports/${id}`).then((r) => r.data),

  generate: (elderlyId: string, week: string) =>
    apiClient.post<ApiResponse<import('@/types').HealthReport>>('/reports/generate', { elderly_id: elderlyId, week }).then((r) => r.data),
};

// ========== 社区看板 ==========
export const dashboardAPI = {
  getData: (communityId?: string) =>
    apiClient.get<ApiResponse<import('@/types').DashboardData>>('/dashboard', { params: { community_id: communityId } }).then((r) => r.data),
};

// ========== 管理员管理 ==========
export const adminAPI = {
  getAdmins: (params: PaginationParams) =>
    apiClient.get<ApiResponse<PaginatedResponse<UserInfo>>>('/admin/users', { params }).then((r) => r.data),

  createAdmin: (data: Partial<UserInfo> & { password: string; admin_role_id: string }) =>
    apiClient.post<ApiResponse<UserInfo>>('/admin/users', data).then((r) => r.data),

  updateAdmin: (id: string, data: Partial<UserInfo>) =>
    apiClient.put<ApiResponse<UserInfo>>(`/admin/users/${id}`, data).then((r) => r.data),

  deleteAdmin: (id: string) =>
    apiClient.delete<ApiResponse>(`/admin/users/${id}`).then((r) => r.data),

  resetPassword: (id: string, newPassword: string) =>
    apiClient.post<ApiResponse>(`/admin/users/${id}/reset-password`, { password: newPassword }).then((r) => r.data),

  lockAdmin: (id: string) =>
    apiClient.post<ApiResponse>(`/admin/users/${id}/lock`).then((r) => r.data),

  unlockAdmin: (id: string) =>
    apiClient.post<ApiResponse>(`/admin/users/${id}/unlock`).then((r) => r.data),

  forceLogout: (id: string) =>
    apiClient.post<ApiResponse>(`/admin/users/${id}/force-logout`).then((r) => r.data),

  getRoles: () =>
    apiClient.get<ApiResponse<AdminRole[]>>('/admin/roles').then((r) => r.data),

  updateRolePermissions: (roleId: string, permIds: string[]) =>
    apiClient.put<ApiResponse>(`/admin/roles/${roleId}/permissions`, { permission_ids: permIds }).then((r) => r.data),

  getAuditLogs: (params: PaginationParams & { module?: string; level?: string; operator_id?: string }) =>
    apiClient.get<ApiResponse<PaginatedResponse<AuditLog>>>('/admin/audit-logs', { params }).then((r) => r.data),
};

// ========== 系统设置 ==========
export const systemAPI = {
  getConfig: () =>
    apiClient.get<ApiResponse<SystemConfig>>('/system/config').then((r) => r.data),

  updateConfig: (data: Partial<SystemConfig>) =>
    apiClient.put<ApiResponse>('/system/config', data).then((r) => r.data),

  getStatus: () =>
    apiClient.get<ApiResponse<SystemStatus>>('/system/status').then((r) => r.data),
};
