/**
 * 测试数据工厂 (Test Data Factories)
 * 使用工厂模式生成可预测的模拟数据，支持覆盖默认值
 */
import type {
  ElderlyProfile,
  Device,
  AlarmRecord,
  SigninRecord,
  PatrolTask,
  HealthReport,
  UserInfo,
  DashboardData,
  AdminRole,
  ApiResponse,
} from '@/types';

// ============ 基础工厂函数 ============

/** 创建老人档案 */
export function createElderly(overrides: Partial<ElderlyProfile> = {}): ElderlyProfile {
  return {
    id: 'e001',
    user_id: 'u001',
    real_name: '张德福',
    nickname: '老张',
    gender: 'M',
    age: 76,
    birthday: '1949-03-15',
    id_card: '310***********1234',
    avatar_url: '',
    phone: '138****6789',
    emergency_contact_name: '张小明',
    emergency_contact_phone: '139****7890',
    address: '上海市浦东新区花木街道1号',
    community_id: 'c001',
    community_name: '花木社区',
    health_history: [],
    allergies: [],
    medications: [],
    device_count: 0,
    latest_vital: null,
    status: 'active',
    ...overrides,
  };
}

/** 创建设备 */
export function createDevice(overrides: Partial<Device> = {}): Device {
  return {
    id: 'd001',
    device_sn: 'EH-WATCH-20260101',
    device_name: '智能手表A1',
    elderly_id: 'e001',
    elderly_name: '张德福',
    firmware_version: 'v2.3.1',
    battery_level: 85,
    signal_strength: 4,
    status: 'online',
    model: 'EH-Pro',
    activated_at: '2026-01-15T08:00:00Z',
    last_heartbeat_at: new Date().toISOString(),
    sim_iccid: '8986***********01',
    location_lat: 31.2304,
    location_lng: 121.4737,
    ...overrides,
  };
}

/** 创建报警记录 */
export function createAlarm(overrides: Partial<AlarmRecord> = {}): AlarmRecord {
  return {
    id: 'a001',
    elderly_id: 'e001',
    elderly_name: '张德福',
    device_id: 'd001',
    alarm_type: 'SOS',
    level: 'P0',
    vital_snapshot: {
      heart_rate: 72,
      blood_oxygen: 97,
      temperature: 36.5,
      systolic_bp: 135,
      diastolic_bp: 85,
      steps: 3200,
      sleep_minutes: 420,
      posture: 'standing',
      activity_level: 3,
      recorded_at: new Date().toISOString(),
    },
    status: 'pending',
    description: '测试报警',
    location_lat: 31.2304,
    location_lng: 121.4737,
    triggered_at: new Date().toISOString(),
    resolved_at: null,
    handler_name: null,
    handling_logs: [],
    ...overrides,
  };
}

/** 创建签到记录 */
export function createSigninRecord(overrides: Partial<SigninRecord> = {}): SigninRecord {
  return {
    id: 's001',
    elderly_id: 'e001',
    elderly_name: '张德福',
    signin_date: new Date().toISOString().split('T')[0],
    signin_time: new Date().toISOString(),
    method: 'touch',
    status: 'signed',
    proxy_by: null,
    check_levels: 0,
    ...overrides,
  };
}

/** 创建巡访任务 */
export function createPatrolTask(overrides: Partial<PatrolTask> = {}): PatrolTask {
  return {
    id: 'p001',
    elderly_id: 'e001',
    elderly_name: '张德福',
    priority: 'normal',
    task_type: '定期探访',
    description: '测试巡访任务',
    assigned_to: 's001',
    assigned_name: '社区小王',
    status: 'pending',
    scheduled_date: new Date().toISOString().split('T')[0],
    completed_at: null,
    result: null,
    ...overrides,
  };
}

/** 创建健康报告 */
export function createHealthReport(overrides: Partial<HealthReport> = {}): HealthReport {
  return {
    id: 'r001',
    elderly_id: 'e001',
    elderly_name: '张德福',
    report_week: '2026-W25',
    health_score: 88,
    avg_heart_rate: 72,
    avg_blood_oxygen: 97,
    avg_temperature: 36.5,
    total_steps: 22400,
    alarm_count: 0,
    signin_days: 7,
    trends: [],
    ai_summary: '测试健康摘要',
    ai_suggestions: [],
    generated_by: 'AI系统',
    status: 'published',
    created_at: new Date().toISOString(),
    ...overrides,
  };
}

/** 创建用户信息 */
export function createUserInfo(overrides: Partial<UserInfo> = {}): UserInfo {
  return {
    id: 'admin-001',
    username: 'admin',
    real_name: '系统管理员',
    role: 'super_admin',
    role_name: '超级管理员',
    avatar_url: '',
    last_login_at: new Date().toISOString(),
    ...overrides,
  };
}

/** 创建管理员角色 */
export function createAdminRole(overrides: Partial<AdminRole> = {}): AdminRole {
  return {
    id: 'r001',
    role_code: 'operator',
    role_name: '运营人员',
    description: '报警处理、签到监督、巡访执行',
    is_system: false,
    is_active: true,
    permissions: [],
    ...overrides,
  };
}

// ============ 批量工厂 ============

/** 批量创建老人（用于分页测试） */
export function createElderlyList(count: number, overrides: Partial<ElderlyProfile> = {}): ElderlyProfile[] {
  return Array.from({ length: count }, (_, i) =>
    createElderly({
      id: `e${String(i + 1).padStart(3, '0')}`,
      real_name: `测试老人${i + 1}`,
      age: 70 + (i % 20),
      status: i < count - 2 ? 'active' : 'alarming',
      ...overrides,
    }),
  );
}

/** 批量创建报警 */
export function createAlarmList(count: number): AlarmRecord[] {
  const types: AlarmRecord['alarm_type'][] = ['SOS', 'FALL', 'VITAL_ABNORMAL', 'DEVICE_OFFLINE', 'GEOFENCE'];
  const levels: AlarmRecord['level'][] = ['P0', 'P1', 'P2', 'P3'];
  const statuses: AlarmRecord['status'][] = ['pending', 'confirmed', 'processing', 'resolved'];

  return Array.from({ length: count }, (_, i) =>
    createAlarm({
      id: `a${String(i + 1).padStart(3, '0')}`,
      alarm_type: types[i % types.length],
      level: levels[i % levels.length],
      status: statuses[i % statuses.length],
      elderly_id: `e${String((i % 8) + 1).padStart(3, '0')}`,
    }),
  );
}

// ============ API 响应包装 ============

/** 包装成功响应 */
export function successResponse<T>(data: T, message = 'success'): ApiResponse<T> {
  return {
    code: 0,
    message,
    data,
    request_id: `req_${Date.now()}`,
  };
}

/** 包装错误响应 */
export function errorResponse(message = '请求失败', code = 400): ApiResponse<null> {
  return {
    code,
    message,
    data: null,
    request_id: `req_${Date.now()}`,
  };
}

/** 包装分页响应 */
export function paginatedResponse<T>(list: T[], page: number, page_size: number) {
  return successResponse({
    list,
    total: list.length,
    page,
    page_size,
  });
}

// ============ Dashboard 测试数据 ============

export function createDashboardData(overrides: Partial<DashboardData> = {}): DashboardData {
  return {
    summary: {
      total_elderly: 8,
      online_devices: 7,
      today_signin_rate: 75,
      pending_alarms: 2,
    },
    alarm_trend: [
      { date: '06-18', count: 2, level: 'P1' },
      { date: '06-19', count: 1, level: 'P2' },
      { date: '06-24', count: 5, level: 'P0' },
    ],
    device_online_rate: [
      { time: '00:00', rate: 100 },
      { time: '08:00', rate: 88 },
      { time: '16:00', rate: 88 },
    ],
    recent_alarms: [createAlarm()],
    pending_patrols: [createPatrolTask()],
    elderly_distribution: [
      { community: '花木社区', count: 5 },
      { community: '联洋社区', count: 3 },
    ],
    signin_overview: { signed: 6, unsigned: 1, timeout: 1, total: 8 },
    ...overrides,
  };
}
