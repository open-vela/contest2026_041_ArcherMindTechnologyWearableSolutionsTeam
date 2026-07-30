import type {
  DashboardData,
  ElderlyProfile,
  Device,
  AlarmRecord,
  SigninRecord,
  PatrolTask,
  HealthReport,
  AdminRole,
  AuditLog,
  SystemConfig,
  SystemStatus,
  UserInfo,
} from '@/types';

// ============ 模拟老人数据 ============
export const mockElderly: ElderlyProfile[] = [
  {
    id: 'e001', user_id: 'u001', real_name: '张德福', nickname: '老张',
    gender: 'M', age: 76, birthday: '1949-03-15', id_card: '310***********1234',
    avatar_url: '', phone: '138****6789',
    emergency_contact_name: '张小明', emergency_contact_phone: '139****7890',
    address: '上海市浦东新区花木街道1号', community_id: 'c001', community_name: '花木社区',
    health_history: ['高血压', '冠心病'], allergies: ['青霉素'],
    medications: [{ name: '氨氯地平', dosage: '5mg', frequency: '每日1次', time_slots: ['08:00'] }],
    device_count: 1, latest_vital: { heart_rate: 72, blood_oxygen: 97, temperature: 36.5, systolic_bp: 135, diastolic_bp: 85, steps: 3200, sleep_minutes: 420, posture: 'walking', activity_level: 3, recorded_at: '2026-06-24T16:30:00Z' },
    status: 'active',
  },
  {
    id: 'e002', user_id: 'u002', real_name: '李秀兰', nickname: '李阿姨',
    gender: 'F', age: 82, birthday: '1943-08-22', id_card: '310***********5678',
    avatar_url: '', phone: '138****7890',
    emergency_contact_name: '李建国', emergency_contact_phone: '139****4567',
    address: '上海市浦东新区花木街道3号', community_id: 'c001', community_name: '花木社区',
    health_history: ['糖尿病', '骨质疏松'], allergies: [],
    medications: [{ name: '二甲双胍', dosage: '500mg', frequency: '每日2次', time_slots: ['08:00', '18:00'] }],
    device_count: 1, latest_vital: { heart_rate: 88, blood_oxygen: 95, temperature: 36.8, systolic_bp: 150, diastolic_bp: 92, steps: 1200, sleep_minutes: 380, posture: 'sitting', activity_level: 1, recorded_at: '2026-06-24T16:25:00Z' },
    status: 'attention',
  },
  {
    id: 'e003', user_id: 'u003', real_name: '王建国', nickname: '老王',
    gender: 'M', age: 79, birthday: '1946-12-03', id_card: '310***********9012',
    avatar_url: '', phone: '138****9012',
    emergency_contact_name: '王芳', emergency_contact_phone: '139****8901',
    address: '上海市浦东新区联洋社区5号', community_id: 'c002', community_name: '联洋社区',
    health_history: ['脑梗后遗症'], allergies: ['头孢类'],
    medications: [{ name: '阿司匹林', dosage: '100mg', frequency: '每日1次', time_slots: ['08:00'] }],
    device_count: 1, latest_vital: { heart_rate: 65, blood_oxygen: 96, temperature: 36.3, systolic_bp: 128, diastolic_bp: 78, steps: 800, sleep_minutes: 450, posture: 'lying', activity_level: 1, recorded_at: '2026-06-24T16:20:00Z' },
    status: 'active',
  },
  {
    id: 'e004', user_id: 'u004', real_name: '赵桂英', nickname: '赵奶奶',
    gender: 'F', age: 85, birthday: '1940-05-18', id_card: '310***********3456',
    avatar_url: '', phone: '138****3456',
    emergency_contact_name: '赵强', emergency_contact_phone: '139****0123',
    address: '上海市浦东新区联洋社区8号', community_id: 'c002', community_name: '联洋社区',
    health_history: ['心律失常', '高血压', '慢性肾炎'], allergies: ['磺胺'],
    medications: [
      { name: '美托洛尔', dosage: '25mg', frequency: '每日2次', time_slots: ['08:00', '20:00'] },
      { name: '硝苯地平', dosage: '30mg', frequency: '每日1次', time_slots: ['08:00'] },
    ],
    device_count: 1, latest_vital: { heart_rate: 95, blood_oxygen: 92, temperature: 37.2, systolic_bp: 165, diastolic_bp: 98, steps: 500, sleep_minutes: 360, posture: 'sitting', activity_level: 1, recorded_at: '2026-06-24T16:15:00Z' },
    status: 'alarming',
  },
  {
    id: 'e005', user_id: 'u005', real_name: '陈大伟', nickname: '老陈',
    gender: 'M', age: 71, birthday: '1954-11-08', id_card: '310***********7890',
    avatar_url: '', phone: '138****0123',
    emergency_contact_name: '陈静', emergency_contact_phone: '139****3456',
    address: '上海市浦东新区花木街道2号', community_id: 'c001', community_name: '花木社区',
    health_history: [], allergies: [],
    medications: [],
    device_count: 1, latest_vital: { heart_rate: 70, blood_oxygen: 98, temperature: 36.4, systolic_bp: 122, diastolic_bp: 76, steps: 5800, sleep_minutes: 480, posture: 'walking', activity_level: 5, recorded_at: '2026-06-24T16:35:00Z' },
    status: 'active',
  },
  {
    id: 'e006', user_id: 'u006', real_name: '刘美华', nickname: '刘阿姨',
    gender: 'F', age: 74, birthday: '1951-07-25', id_card: '310***********4321',
    avatar_url: '', phone: '138****8765',
    emergency_contact_name: '刘明', emergency_contact_phone: '139****5678',
    address: '上海市浦东新区花木街道6号', community_id: 'c001', community_name: '花木社区',
    health_history: ['轻度认知障碍'], allergies: [],
    medications: [{ name: '多奈哌齐', dosage: '5mg', frequency: '每日1次', time_slots: ['20:00'] }],
    device_count: 1, latest_vital: { heart_rate: 78, blood_oxygen: 96, temperature: 36.6, systolic_bp: 140, diastolic_bp: 86, steps: 2100, sleep_minutes: 400, posture: 'walking', activity_level: 2, recorded_at: '2026-06-24T16:28:00Z' },
    status: 'active',
  },
  {
    id: 'e007', user_id: 'u007', real_name: '孙正明', nickname: '老孙',
    gender: 'M', age: 68, birthday: '1957-02-14', id_card: '310***********6543',
    avatar_url: '', phone: '138****5432',
    emergency_contact_name: '孙丽', emergency_contact_phone: '139****7890',
    address: '上海市浦东新区联洋社区3号', community_id: 'c002', community_name: '联洋社区',
    health_history: [], allergies: ['海鲜'],
    medications: [],
    device_count: 1, latest_vital: null,
    status: 'offline',
  },
  {
    id: 'e008', user_id: 'u008', real_name: '周玉兰', nickname: '周奶奶',
    gender: 'F', age: 80, birthday: '1945-09-30', id_card: '310***********8765',
    avatar_url: '', phone: '138****0987',
    emergency_contact_name: '周杰', emergency_contact_phone: '139****6543',
    address: '上海市浦东新区联洋社区7号', community_id: 'c002', community_name: '联洋社区',
    health_history: ['慢性阻塞性肺病'], allergies: [],
    medications: [{ name: '沙美特罗', dosage: '50μg', frequency: '每日2次', time_slots: ['08:00', '20:00'] }],
    device_count: 1, latest_vital: { heart_rate: 80, blood_oxygen: 93, temperature: 36.9, systolic_bp: 138, diastolic_bp: 84, steps: 1600, sleep_minutes: 410, posture: 'sitting', activity_level: 2, recorded_at: '2026-06-24T16:22:00Z' },
    status: 'active',
  },
];

// ============ 模拟设备数据 ============
export const mockDevices: Device[] = [
  { id: 'd001', device_sn: 'EH-WATCH-20260101', device_name: '智能手表A1', elderly_id: 'e001', elderly_name: '张德福', firmware_version: 'v2.3.1', battery_level: 85, signal_strength: 4, status: 'online', model: 'EH-Pro', activated_at: '2026-01-15T08:00:00Z', last_heartbeat_at: '2026-06-24T16:50:00Z', sim_iccid: '8986***********01', location_lat: 31.2304, location_lng: 121.4737 },
  { id: 'd002', device_sn: 'EH-WATCH-20260102', device_name: '智能手表A2', elderly_id: 'e002', elderly_name: '李秀兰', firmware_version: 'v2.3.1', battery_level: 62, signal_strength: 3, status: 'online', model: 'EH-Pro', activated_at: '2026-01-16T09:00:00Z', last_heartbeat_at: '2026-06-24T16:48:00Z', sim_iccid: '8986***********02', location_lat: 31.2320, location_lng: 121.4750 },
  { id: 'd003', device_sn: 'EH-WATCH-20260103', device_name: '智能手表A3', elderly_id: 'e003', elderly_name: '王建国', firmware_version: 'v2.2.8', battery_level: 45, signal_strength: 2, status: 'online', model: 'EH-Pro', activated_at: '2026-01-20T10:00:00Z', last_heartbeat_at: '2026-06-24T16:45:00Z', sim_iccid: '8986***********03', location_lat: 31.2150, location_lng: 121.4890 },
  { id: 'd004', device_sn: 'EH-WATCH-20260104', device_name: '智能手表A4', elderly_id: 'e004', elderly_name: '赵桂英', firmware_version: 'v2.3.0', battery_level: 28, signal_strength: 4, status: 'alarming', model: 'EH-Pro', activated_at: '2026-01-18T11:00:00Z', last_heartbeat_at: '2026-06-24T16:49:00Z', sim_iccid: '8986***********04', location_lat: 31.2180, location_lng: 121.4920 },
  { id: 'd005', device_sn: 'EH-WATCH-20260105', device_name: '智能手表A5', elderly_id: 'e005', elderly_name: '陈大伟', firmware_version: 'v2.3.1', battery_level: 91, signal_strength: 5, status: 'online', model: 'EH-Pro', activated_at: '2026-02-01T08:00:00Z', last_heartbeat_at: '2026-06-24T16:50:00Z', sim_iccid: '8986***********05', location_lat: 31.2300, location_lng: 121.4730 },
  { id: 'd006', device_sn: 'EH-WATCH-20260106', device_name: '智能手表A6', elderly_id: 'e006', elderly_name: '刘美华', firmware_version: 'v2.2.8', battery_level: 73, signal_strength: 4, status: 'online', model: 'EH-Pro', activated_at: '2026-02-05T09:00:00Z', last_heartbeat_at: '2026-06-24T16:44:00Z', sim_iccid: '8986***********06', location_lat: 31.2310, location_lng: 121.4740 },
  { id: 'd007', device_sn: 'EH-WATCH-20260107', device_name: '智能手表A7', elderly_id: 'e007', elderly_name: '孙正明', firmware_version: 'v2.3.0', battery_level: 12, signal_strength: 0, status: 'offline', model: 'EH-Lite', activated_at: '2026-03-01T08:00:00Z', last_heartbeat_at: '2026-06-24T08:30:00Z', sim_iccid: '8986***********07', location_lat: 31.2160, location_lng: 121.4900 },
  { id: 'd008', device_sn: 'EH-WATCH-20260108', device_name: '智能手表A8', elderly_id: 'e008', elderly_name: '周玉兰', firmware_version: 'v2.3.1', battery_level: 55, signal_strength: 3, status: 'online', model: 'EH-Pro', activated_at: '2026-03-10T10:00:00Z', last_heartbeat_at: '2026-06-24T16:47:00Z', sim_iccid: '8986***********08', location_lat: 31.2190, location_lng: 121.4910 },
];

// ============ 模拟报警数据 ============
export const mockAlarms: AlarmRecord[] = [
  {
    id: 'a001', elderly_id: 'e004', elderly_name: '赵桂英', device_id: 'd004',
    alarm_type: 'VITAL_ABNORMAL', level: 'P0',
    vital_snapshot: { heart_rate: 95, blood_oxygen: 92, temperature: 37.2, systolic_bp: 165, diastolic_bp: 98, steps: 500, sleep_minutes: 360, posture: 'sitting', activity_level: 1, recorded_at: '2026-06-24T16:15:00Z' },
    status: 'pending',
    description: '心率持续偏高(95bpm)，血氧饱和度下降至92%，血压异常升高(165/98mmHg)',
    location_lat: 31.2180, location_lng: 121.4920,
    triggered_at: '2026-06-24T16:15:00Z', resolved_at: null, handler_name: null,
    handling_logs: [],
  },
  {
    id: 'a002', elderly_id: 'e003', elderly_name: '王建国', device_id: 'd003',
    alarm_type: 'FALL', level: 'P1',
    vital_snapshot: { heart_rate: 78, blood_oxygen: 96, temperature: 36.3, systolic_bp: 130, diastolic_bp: 80, steps: 800, sleep_minutes: 450, posture: 'lying', activity_level: 0, recorded_at: '2026-06-24T14:22:00Z' },
    status: 'processing',
    description: '跌倒检测触发，加速度突变+姿态由站立变平躺，持续静止2分钟',
    location_lat: 31.2150, location_lng: 121.4890,
    triggered_at: '2026-06-24T14:22:00Z', resolved_at: null, handler_name: '社区小王',
    handling_logs: [
      { id: 'hl001', action: 'confirmed', handler_name: '系统自动', comment: 'AI跌倒检测三级流水线确认：加速度突变>3g + 姿态变化 + 静止2分钟', created_at: '2026-06-24T14:22:05Z' },
      { id: 'hl002', action: 'notified', handler_name: '系统自动', comment: '已推送通知给子女王芳，已拨打老人电话无应答', created_at: '2026-06-24T14:22:30Z' },
    ],
  },
  {
    id: 'a003', elderly_id: 'e002', elderly_name: '李秀兰', device_id: 'd002',
    alarm_type: 'VITAL_ABNORMAL', level: 'P2',
    vital_snapshot: { heart_rate: 88, blood_oxygen: 95, temperature: 36.8, systolic_bp: 150, diastolic_bp: 92, steps: 1200, sleep_minutes: 380, posture: 'sitting', activity_level: 1, recorded_at: '2026-06-24T15:30:00Z' },
    status: 'confirmed',
    description: '血压偏高(150/92mmHg)，超出设定阈值',
    location_lat: 31.2320, location_lng: 121.4750,
    triggered_at: '2026-06-24T15:30:00Z', resolved_at: null, handler_name: '社区张医生',
    handling_logs: [
      { id: 'hl003', action: 'confirmed', handler_name: '社区张医生', comment: '已联系老人，自述头晕，建议休息观察', created_at: '2026-06-24T15:35:00Z' },
    ],
  },
  {
    id: 'a004', elderly_id: 'e001', elderly_name: '张德福', device_id: 'd001',
    alarm_type: 'SOS', level: 'P0',
    vital_snapshot: { heart_rate: 110, blood_oxygen: 98, temperature: 36.7, systolic_bp: 145, diastolic_bp: 90, steps: 3200, sleep_minutes: 420, posture: 'standing', activity_level: 2, recorded_at: '2026-06-24T10:05:00Z' },
    status: 'resolved',
    description: '老人主动按下SOS按钮',
    location_lat: 31.2304, location_lng: 121.4737,
    triggered_at: '2026-06-24T10:05:00Z', resolved_at: '2026-06-24T10:25:00Z', handler_name: '社区小王',
    handling_logs: [
      { id: 'hl004', action: 'confirmed', handler_name: '系统自动', comment: 'SOS按钮触发，P0级响应', created_at: '2026-06-24T10:05:02Z' },
      { id: 'hl005', action: 'notified', handler_name: '系统自动', comment: '已通知子女和社区人员', created_at: '2026-06-24T10:05:05Z' },
      { id: 'hl006', action: 'resolved', handler_name: '社区小王', comment: '上门查看，老人误触SOS，身体无异常', created_at: '2026-06-24T10:25:00Z' },
    ],
  },
  {
    id: 'a005', elderly_id: 'e007', elderly_name: '孙正明', device_id: 'd007',
    alarm_type: 'DEVICE_OFFLINE', level: 'P2',
    vital_snapshot: null,
    status: 'pending',
    description: '设备离线超过8小时，最后心跳时间 2026-06-24 08:30',
    location_lat: 31.2160, location_lng: 121.4900,
    triggered_at: '2026-06-24T16:30:00Z', resolved_at: null, handler_name: null,
    handling_logs: [],
  },
];

// ============ 模拟签到数据 ============
export const mockSigninRecords: SigninRecord[] = [
  { id: 's001', elderly_id: 'e001', elderly_name: '张德福', signin_date: '2026-06-24', signin_time: '2026-06-24T07:55:00Z', method: 'touch', status: 'signed', proxy_by: null, check_levels: 0 },
  { id: 's002', elderly_id: 'e002', elderly_name: '李秀兰', signin_date: '2026-06-24', signin_time: '2026-06-24T08:12:00Z', method: 'voice', status: 'signed', proxy_by: null, check_levels: 1 },
  { id: 's003', elderly_id: 'e003', elderly_name: '王建国', signin_date: '2026-06-24', signin_time: '2026-06-24T08:45:00Z', method: 'touch', status: 'signed', proxy_by: null, check_levels: 2 },
  { id: 's004', elderly_id: 'e004', elderly_name: '赵桂英', signin_date: '2026-06-24', signin_time: null, method: null, status: 'unsigned', proxy_by: null, check_levels: 3 },
  { id: 's005', elderly_id: 'e005', elderly_name: '陈大伟', signin_date: '2026-06-24', signin_time: '2026-06-24T07:30:00Z', method: 'gesture', status: 'signed', proxy_by: null, check_levels: 0 },
  { id: 's006', elderly_id: 'e006', elderly_name: '刘美华', signin_date: '2026-06-24', signin_time: '2026-06-24T08:03:00Z', method: 'touch', status: 'signed', proxy_by: null, check_levels: 0 },
  { id: 's007', elderly_id: 'e007', elderly_name: '孙正明', signin_date: '2026-06-24', signin_time: null, method: null, status: 'timeout', proxy_by: null, check_levels: 4 },
  { id: 's008', elderly_id: 'e008', elderly_name: '周玉兰', signin_date: '2026-06-24', signin_time: '2026-06-24T09:30:00Z', method: 'proxy', status: 'signed', proxy_by: '社区小王', check_levels: 3 },
];

// ============ 模拟巡访任务 ============
export const mockPatrolTasks: PatrolTask[] = [
  { id: 'p001', elderly_id: 'e004', elderly_name: '赵桂英', priority: 'urgent', task_type: '健康检查', description: '心率异常+高血压报警，需上门查看', assigned_to: 's001', assigned_name: '社区张医生', status: 'pending', scheduled_date: '2026-06-24', completed_at: null, result: null },
  { id: 'p002', elderly_id: 'e003', elderly_name: '王建国', priority: 'urgent', task_type: '跌倒排查', description: '跌倒报警后续跟进，确认老人状况', assigned_to: 's002', assigned_name: '社区小王', status: 'accepted', scheduled_date: '2026-06-24', completed_at: null, result: null },
  { id: 'p003', elderly_id: 'e007', elderly_name: '孙正明', priority: 'normal', task_type: '设备排查', description: '设备离线超过8小时，上门确认设备状态', assigned_to: 's002', assigned_name: '社区小王', status: 'pending', scheduled_date: '2026-06-24', completed_at: null, result: null },
  { id: 'p004', elderly_id: 'e001', elderly_name: '张德福', priority: 'regular', task_type: '定期探访', description: '月度例行探访，健康评估', assigned_to: 's001', assigned_name: '社区张医生', status: 'completed', scheduled_date: '2026-06-20', completed_at: '2026-06-20T14:30:00Z', result: '老人状态良好，血压控制平稳' },
  { id: 'p005', elderly_id: 'e002', elderly_name: '李秀兰', priority: 'regular', task_type: '用药指导', description: '糖尿病用药依从性检查', assigned_to: 's001', assigned_name: '社区张医生', status: 'pending', scheduled_date: '2026-06-25', completed_at: null, result: null },
  { id: 'p006', elderly_id: 'e008', elderly_name: '周玉兰', priority: 'regular', task_type: '呼吸训练', description: 'COPD呼吸康复训练指导', assigned_to: 's001', assigned_name: '社区张医生', status: 'pending', scheduled_date: '2026-06-25', completed_at: null, result: null },
];

// ============ 模拟健康周报 ============
export const mockReports: HealthReport[] = [
  {
    id: 'r001', elderly_id: 'e001', elderly_name: '张德福', report_week: '2026-W25',
    health_score: 88, avg_heart_rate: 72, avg_blood_oxygen: 97, avg_temperature: 36.5, total_steps: 22400,
    alarm_count: 1, signin_days: 7,
    trends: [
      { metric: '心率', direction: 'stable', change: '与上周持平' },
      { metric: '血氧', direction: 'stable', change: '保持良好水平' },
      { metric: '步数', direction: 'up', change: '较上周增加15%' },
    ],
    ai_summary: '张德福本周整体健康状况良好。心率、血氧、体温均在正常范围内。日均步数3200步，较上周增加15%，活动量适中。周一出现一次SOS误触，已由社区人员上门确认无异常。建议继续保持当前运动和用药习惯。',
    ai_suggestions: ['继续保持每日散步习惯，建议傍晚时段', '氨氯地平按时服用，血压控制良好', '建议每日饮水量不少于1500ml'],
    generated_by: 'AI系统', status: 'published', created_at: '2026-06-23T08:00:00Z',
  },
  {
    id: 'r002', elderly_id: 'e002', elderly_name: '李秀兰', report_week: '2026-W25',
    health_score: 72, avg_heart_rate: 86, avg_blood_oxygen: 95, avg_temperature: 36.7, total_steps: 8400,
    alarm_count: 2, signin_days: 6,
    trends: [
      { metric: '血压', direction: 'up', change: '收缩压较上周升高8mmHg' },
      { metric: '心率', direction: 'up', change: '静息心率较上周升高5bpm' },
      { metric: '步数', direction: 'down', change: '较上周减少22%' },
    ],
    ai_summary: '李秀兰本周健康状态需关注。血压出现上升趋势，收缩压峰值达150mmHg，已触发一次P2报警。活动量较上周明显下降，日均仅1200步。本周四有一次签到延迟，经二次提醒后完成。建议加强血压监测频率，关注用药依从性。',
    ai_suggestions: ['建议早晚各测一次血压，记录数据', '二甲双胍需严格按时服用，不可漏服', '建议在家人陪同下每日轻度散步20分钟', '注意低盐低脂饮食'],
    generated_by: 'AI系统', status: 'published', created_at: '2026-06-23T08:05:00Z',
  },
  {
    id: 'r003', elderly_id: 'e004', elderly_name: '赵桂英', report_week: '2026-W25',
    health_score: 58, avg_heart_rate: 90, avg_blood_oxygen: 93, avg_temperature: 37.1, total_steps: 3500,
    alarm_count: 3, signin_days: 5,
    trends: [
      { metric: '心率', direction: 'up', change: '心率异常波动，峰值95bpm' },
      { metric: '血氧', direction: 'down', change: '夜间血氧最低89%' },
      { metric: '血压', direction: 'up', change: '持续偏高，均值160/95mmHg' },
    ],
    ai_summary: '【重点关注】赵桂英本周健康状况出现明显恶化。心率持续偏高且波动大，今日触发P0级报警。血压持续在危险区间，血氧有下降趋势。本周签到仅5天，有2天未完成签到。建议立即安排社区医生上门评估，考虑调整用药方案。',
    ai_suggestions: ['【紧急】立即安排上门健康评估', '美托洛尔剂量建议医生重新评估', '建议进行24小时动态心电监测', '硝苯地平需确认是否按时服用', '家属需加强关注，建议每日探视或电话'],
    generated_by: 'AI系统', status: 'published', created_at: '2026-06-23T08:10:00Z',
  },
];

// ============ 社区看板数据 ============
export const mockDashboard: DashboardData = {
  summary: { total_elderly: 8, online_devices: 7, today_signin_rate: 75, pending_alarms: 2 },
  alarm_trend: [
    { date: '06-18', count: 2, level: 'P1' },
    { date: '06-19', count: 1, level: 'P2' },
    { date: '06-20', count: 3, level: 'P0' },
    { date: '06-21', count: 2, level: 'P1' },
    { date: '06-22', count: 4, level: 'P0' },
    { date: '06-23', count: 3, level: 'P1' },
    { date: '06-24', count: 5, level: 'P0' },
  ],
  device_online_rate: [
    { time: '00:00', rate: 100 }, { time: '02:00', rate: 100 }, { time: '04:00', rate: 100 },
    { time: '06:00', rate: 100 }, { time: '08:00', rate: 88 }, { time: '10:00', rate: 88 },
    { time: '12:00', rate: 88 }, { time: '14:00', rate: 88 }, { time: '16:00', rate: 88 },
  ],
  recent_alarms: mockAlarms.slice(0, 5),
  pending_patrols: mockPatrolTasks.filter((t) => t.status !== 'completed').slice(0, 5),
  elderly_distribution: [
    { community: '花木社区', count: 5 },
    { community: '联洋社区', count: 3 },
  ],
  signin_overview: { signed: 6, unsigned: 1, timeout: 1, total: 8 },
};

// ============ 模拟管理员角色 ============
export const mockAdminRoles: AdminRole[] = [
  {
    id: 'r001', role_code: 'super_admin', role_name: '超级管理员',
    description: '系统最高权限，可管理所有管理员和全局安全策略', is_system: true, is_active: true,
    permissions: [],
  },
  {
    id: 'r002', role_code: 'admin', role_name: '管理员',
    description: '日常管理权限，含全部业务运营权限', is_system: true, is_active: true,
    permissions: [],
  },
  {
    id: 'r003', role_code: 'operator', role_name: '运营人员',
    description: '报警处理、签到监督、巡访执行', is_system: true, is_active: true,
    permissions: [],
  },
  {
    id: 'r004', role_code: 'viewer', role_name: '只读观察员',
    description: '仅查看看板和报表数据', is_system: true, is_active: true,
    permissions: [],
  },
];

// ============ 模拟审计日志 ============
export const mockAuditLogs: AuditLog[] = [
  { id: 'al001', audit_level: 'CRITICAL', operator_name: 'admin', module: 'admin', operation: 'CREATE', description: '创建新管理员 社区张医生(operator)', resource_type: 'user', source_ip: '192.168.1.100', result_status: 'SUCCESS', created_at: '2026-06-24T15:30:00Z' },
  { id: 'al002', audit_level: 'HIGH', operator_name: 'admin', module: 'admin', operation: 'RESET_PASSWORD', description: '重置管理员 社区小王 的密码', resource_type: 'user', source_ip: '192.168.1.100', result_status: 'SUCCESS', created_at: '2026-06-24T14:20:00Z' },
  { id: 'al003', audit_level: 'HIGH', operator_name: 'admin', module: 'security', operation: 'UPDATE', description: '修改安全策略：启用全局IP白名单', resource_type: 'security', source_ip: '192.168.1.100', result_status: 'SUCCESS', created_at: '2026-06-24T11:15:00Z' },
  { id: 'al004', audit_level: 'MEDIUM', operator_name: '社区张医生', module: 'elderly', operation: 'UPDATE', description: '更新赵桂英用药方案', resource_type: 'elderly', source_ip: '192.168.1.101', result_status: 'SUCCESS', created_at: '2026-06-24T10:30:00Z' },
  { id: 'al005', audit_level: 'LOW', operator_name: '社区小王', module: 'patrol', operation: 'CREATE', description: '创建巡访任务：王建国跌倒排查', resource_type: 'patrol', source_ip: '192.168.1.102', result_status: 'SUCCESS', created_at: '2026-06-24T09:45:00Z' },
  { id: 'al006', audit_level: 'CRITICAL', operator_name: 'unknown', module: 'auth', operation: 'LOGIN', description: '管理员登录失败：密码错误（第5次）', resource_type: 'session', source_ip: '10.0.0.55', result_status: 'FAILURE', created_at: '2026-06-24T09:30:00Z' },
  { id: 'al007', audit_level: 'HIGH', operator_name: 'admin', module: 'alarm', operation: 'ESCALATE', description: '升级报警 a001（赵桂英-P0）', resource_type: 'alarm', source_ip: '192.168.1.100', result_status: 'SUCCESS', created_at: '2026-06-24T08:20:00Z' },
  { id: 'al008', audit_level: 'MEDIUM', operator_name: '社区小王', module: 'signin', operation: 'PROXY', description: '代签：周玉兰 2026-06-24', resource_type: 'signin', source_ip: '192.168.1.102', result_status: 'SUCCESS', created_at: '2026-06-24T07:55:00Z' },
];

// ============ 模拟系统配置 ============
export const mockSystemConfig: SystemConfig = {
  signin_start_time: '08:00',
  signin_end_time: '10:00',
  signin_reminder_interval: 30,
  signin_escalation_timeout: 60,
  alarm_p0_response_seconds: 5,
  alarm_p1_escalation_minutes: 10,
  heart_rate_low: 50,
  heart_rate_high: 100,
  blood_oxygen_low: 93,
  temperature_low: 35.5,
  temperature_high: 37.5,
  notification_channels: { sms: true, phone: true, push: true, wechat: true },
};

// ============ 模拟系统状态 ============
export const mockSystemStatus: SystemStatus = {
  mysql: 'UP',
  redis: 'UP',
  emqx: 'UP',
  websocket: 'UP',
  uptime: '7d 12h 34m',
  memory_usage: '45.2%',
  cpu_usage: '23.8%',
};

// ============ 延迟模拟函数 ============
export function delay(ms = 300): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export function paginate<T>(list: T[], page: number, pageSize: number) {
  const start = (page - 1) * pageSize;
  return {
    list: list.slice(start, start + pageSize),
    total: list.length,
    page,
    page_size: pageSize,
  };
}
