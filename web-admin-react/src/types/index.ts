// ============ 用户 & 认证 ============
export interface UserInfo {
  id: string;
  username: string;
  phone: string;
  email: string;
  role: 'admin' | 'community' | 'family' | 'elderly' | 'super_admin';
  real_name: string;
  avatar_url: string;
  community_id: string;
  community_name: string;
  admin_role?: string; // 后端 admin_roles.role_name，如“超级管理员”
  permissions: string[];
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  user: UserInfo;
}

export interface AdminRole {
  id: string;
  role_code: 'super_admin' | 'admin' | 'operator' | 'viewer';
  role_name: string;
  description: string;
  is_system: boolean;
  is_active: boolean;
  permissions: AdminPermission[];
}

export interface AdminPermission {
  id: string;
  perm_code: string;
  perm_name: string;
  module: string;
  action: string;
  sensitivity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
}

export interface AuditLog {
  id: string;
  audit_level: string;
  operator_name: string;
  module: string;
  operation: string;
  description: string;
  resource_type: string;
  source_ip: string;
  result_status: 'SUCCESS' | 'FAILURE' | 'DENIED';
  created_at: string;
}

// ============ 老人管理 ============
export interface ElderlyProfile {
  id: string;
  user_id: string;
  real_name: string;
  name?: string;           // 后端实际返回的姓名字段（优先使用）
  nickname: string;
  gender: 'M' | 'F' | 'male' | 'female';
  age: number;
  birthday: string;
  birth_date?: string;     // 后端实际返回的出生日期字段
  id_card: string;
  avatar_url: string;
  phone: string;
  emergency_contact_name: string;
  emergency_contact_phone: string;
  emergency_contact?: string;   // 后端实际返回的紧急联系人字段
  emergency_phone?: string;     // 后端实际返回的紧急联系电话字段
  address: string;
  community_id: string;
  community_name: string;
  health_history: string[];
  allergies: string[];
  medications: Medication[];
  device_count: number;
  bound_device_sn?: string;     // 后端返回的绑定设备序列号
  bound_device_name?: string;   // 后端返回的绑定设备名称
  latest_vital: VitalSigns | null;
  status: 'active' | 'attention' | 'alarming' | 'offline';
  care_level?: string;
  created_at?: string;
}

export interface Medication {
  name: string;
  dosage: string;
  frequency: string;
  time_slots: string[];
}

// ============ 设备管理 ============
export interface Device {
  id: string;
  device_sn: string;
  device_name: string;
  elderly_id: string;
  elderly_name: string;
  firmware_version: string;
  battery_level: number;   // 前端使用（兼容）
  battery?: number;        // 后端 API 实际返回字段名
  signal_strength: number;
  status: 'online' | 'offline' | 'sleep' | 'alarming';
  model?: string;
  activated_at?: string;
  last_heartbeat_at: string;
  sim_iccid?: string;
  location_lat?: number;
  location_lng?: number;
}

// ============ 体征数据 ============
export interface VitalSigns {
  heart_rate: number;
  blood_oxygen: number;
  temperature: number;
  systolic_bp: number;
  diastolic_bp: number;
  steps: number;
  sleep_minutes: number;
  posture: string;
  activity_level: number;
  recorded_at: string;
}

export interface VitalHistory {
  elderly_id: string;
  elderly_name: string;
  metric: string;
  data: { time: string; value: number }[];
}

// ============ 报警管理 ============
export interface AlarmRecord {
  id: string;
  elderly_id: string;
  elderly_name: string;
  device_id: string;
  device_sn?: string;           // 设备序列号
  alarm_type: 'SOS' | 'FALL' | 'VITAL_ABNORMAL' | 'SIGNIN_TIMEOUT' | 'DEVICE_OFFLINE' | string;
  level: 'P0' | 'P1' | 'P2' | 'P3' | string;
  vital_snapshot: VitalSigns | null;
  status: 'pending' | 'confirmed' | 'processing' | 'resolved' | 'escalated';
  description: string;
  location_lat: number;
  location_lng: number;
  triggered_at: string;
  created_at?: string;          // 创建时间
  updated_at?: string;          // 更新时间
  resolved_at: string | null;
  handler_name: string | null;
  handler_id?: string | null;   // 处理人ID
  handling_logs: AlarmHandlingLog[];
}

export interface AlarmHandlingLog {
  id: string;
  action: string;
  handler_name: string;
  comment: string;
  created_at: string;
}

// ============ 签到管理 ============
export interface SigninRecord {
  id: string;
  elderly_id: string;
  elderly_name: string;
  signin_date: string;
  signin_time: string | null;
  method: 'touch' | 'voice' | 'gesture' | 'auto' | 'proxy' | null;
  status: 'signed' | 'unsigned' | 'timeout';
  proxy_by: string | null;
  check_levels: number;
}

export interface SigninCalendar {
  elderly_id: string;
  elderly_name: string;
  month: string;
  records: { date: string; status: string }[];
}

// ============ 巡访管理 ============
export interface PatrolTask {
  id: string;
  elderly_id: string;
  elderly_name: string;
  priority: 'urgent' | 'normal' | 'regular';
  task_type: string;
  description: string;
  assigned_to: string;
  assigned_name: string;
  status: 'pending' | 'accepted' | 'completed' | 'cancelled';
  scheduled_date: string;
  completed_at: string | null;
  result: string | null;
}

export interface PatrolRecord {
  id: string;
  task_id: string;
  elderly_name: string;
  staff_name: string;
  visit_type: string;
  health_check: VitalSigns | null;
  notes: string;
  photos: string[];
  created_at: string;
}

// ============ 健康周报 ============
export interface HealthReport {
  id: string;
  elderly_id: string;
  elderly_name: string;
  report_week: string;
  health_score: number;
  avg_heart_rate: number;
  avg_blood_oxygen: number;
  avg_temperature: number;
  total_steps: number;
  alarm_count: number;
  signin_days: number;
  trends: { metric: string; direction: 'up' | 'down' | 'stable'; change: string }[];
  ai_summary: string;
  ai_suggestions: string[];
  generated_by: string;
  status: 'draft' | 'published';
  created_at: string;
}

// ============ 社区看板 ============
export interface DashboardData {
  summary: {
    total_elderly: number;
    online_devices: number;
    today_signin_rate: number;
    pending_alarms: number;
  };
  alarm_trend: { date: string; count: number; level: string }[];
  device_online_rate: { time: string; rate: number }[];
  recent_alarms: AlarmRecord[];
  pending_patrols: PatrolTask[];
  elderly_distribution: { community: string; count: number }[];
  signin_overview: { signed: number; unsigned: number; timeout: number; total: number };
}

// ============ 系统设置 ============
export interface SystemConfig {
  signin_start_time: string;
  signin_end_time: string;
  signin_reminder_interval: number;
  signin_escalation_timeout: number;
  alarm_p0_response_seconds: number;
  alarm_p1_escalation_minutes: number;
  heart_rate_low: number;
  heart_rate_high: number;
  blood_oxygen_low: number;
  temperature_low: number;
  temperature_high: number;
  notification_channels: { sms: boolean; phone: boolean; push: boolean; wechat: boolean };
}

export interface SystemStatus {
  mysql: string;
  redis: string;
  emqx: string;
  websocket: string;
  uptime: string;
  memory_usage: string;
  cpu_usage: string;
}

// ============ API 响应格式 ============
export interface ApiResponse<T = unknown> {
  code: number;
  message: string;
  data: T;
}

// 分页响应（与后端 utils.SuccessPage 格式一致: {code, message, data: T[], total, page, page_size}）
export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  page_size: number;
}

export interface PaginationParams {
  page: number;
  page_size: number;
  keyword?: string;
  sort_by?: string;
  sort_order?: 'asc' | 'desc';
}
