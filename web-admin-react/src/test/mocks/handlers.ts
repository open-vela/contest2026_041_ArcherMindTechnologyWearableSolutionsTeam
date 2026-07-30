/**
 * MSW (Mock Service Worker) 请求处理器
 * 模拟所有后端 API 接口，用于接口测试
 */
import { http, HttpResponse, type HttpHandler } from 'msw';
import {
  successResponse,
  errorResponse,
  paginatedResponse,
  createElderly,
  createElderlyList,
  createDevice,
  createAlarm,
  createAlarmList,
  createSigninRecord,
  createPatrolTask,
  createDashboardData,
  createUserInfo,
  createAdminRole,
} from '../factories';

// ============ 辅助：从请求中提取分页参数 ============
function getPagination(url: URL) {
  const page = parseInt(url.searchParams.get('page') || '1', 10);
  const page_size = parseInt(url.searchParams.get('page_size') || '20', 10);
  return { page, page_size };
}

// ============ 辅助：模拟网络延迟 ============
function simulateDelay(ms = 200): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ============ Handlers ============
export const handlers: HttpHandler[] = [
  // ===== 认证接口 =====
  http.post('/api/v1/auth/login', async ({ request }) => {
    const body = (await request.json()) as any;
    if (body.username === 'admin' && body.password === 'Admin@2026') {
      return HttpResponse.json(
        successResponse({
          access_token: 'mock_access_token_12345',
          refresh_token: 'mock_refresh_token_67890',
          expires_in: 7200,
          user: createUserInfo(),
        }),
      );
    }
    return HttpResponse.json(errorResponse('用户名或密码错误', 401), { status: 401 });
  }),

  http.post('/api/v1/auth/refresh', async ({ request }) => {
    const body = (await request.json()) as any;
    if (body.refresh_token) {
      return HttpResponse.json(
        successResponse({
          access_token: 'new_mock_access_token',
          refresh_token: body.refresh_token,
        }),
      );
    }
    return HttpResponse.json(errorResponse('Refresh token 无效', 401), { status: 401 });
  }),

  http.post('/api/v1/auth/logout', () => {
    return HttpResponse.json(successResponse(null, '登出成功'));
  }),

  http.get('/api/v1/auth/profile', () => {
    return HttpResponse.json(successResponse(createUserInfo()));
  }),

  // ===== 老人管理接口 =====
  http.get('/api/v1/elderly', async ({ request }) => {
    const url = new URL(request.url);
    const { page, page_size } = getPagination(url);
    const keyword = url.searchParams.get('keyword') || '';
    const status = url.searchParams.get('status') || '';

    let list = createElderlyList(50);
    if (keyword) {
      list = list.filter((e) => e.real_name.includes(keyword));
    }
    if (status) {
      list = list.filter((e) => e.status === status);
    }

    return HttpResponse.json(paginatedResponse(list, page, page_size));
  }),

  http.get('/api/v1/elderly/:id', ({ params }) => {
    const { id } = params;
    return HttpResponse.json(successResponse(createElderly({ id: id as string })));
  }),

  http.post('/api/v1/elderly', async ({ request }) => {
    const body = (await request.json()) as any;
    return HttpResponse.json(
      successResponse(createElderly({ id: 'e_new_001', ...body }), '创建成功'),
      { status: 201 },
    );
  }),

  http.put('/api/v1/elderly/:id', async ({ request, params }) => {
    const body = (await request.json()) as any;
    return HttpResponse.json(
      successResponse(createElderly({ id: params.id as string, ...body }), '更新成功'),
    );
  }),

  http.delete('/api/v1/elderly/:id', () => {
    return HttpResponse.json(successResponse(null, '删除成功'));
  }),

  // ===== 设备接口 =====
  http.get('/api/v1/devices', ({ request }) => {
    const url = new URL(request.url);
    const { page, page_size } = getPagination(url);
    const list = Array.from({ length: 20 }, (_, i) => createDevice({ id: `d${i + 1}` }));
    return HttpResponse.json(paginatedResponse(list, page, page_size));
  }),

  http.get('/api/v1/devices/:id', ({ params }) => {
    return HttpResponse.json(successResponse(createDevice({ id: params.id as string })));
  }),

  http.post('/api/v1/devices/bind', async ({ request }) => {
    const body = (await request.json()) as any;
    return HttpResponse.json(
      successResponse(createDevice({ elderly_id: body.elderly_id }), '绑定成功'),
      { status: 201 },
    );
  }),

  http.post('/api/v1/devices/:id/unbind', () => {
    return HttpResponse.json(successResponse(null, '解绑成功'));
  }),

  http.post('/api/v1/devices/:id/restart', () => {
    return HttpResponse.json(successResponse(null, '重启指令已发送'));
  }),

  // ===== 报警接口 =====
  http.get('/api/v1/alarms', ({ request }) => {
    const url = new URL(request.url);
    const { page, page_size } = getPagination(url);
    const list = createAlarmList(30);
    return HttpResponse.json(paginatedResponse(list, page, page_size));
  }),

  http.get('/api/v1/alarms/:id', ({ params }) => {
    return HttpResponse.json(successResponse(createAlarm({ id: params.id as string })));
  }),

  http.post('/api/v1/alarms/:id/confirm', () => {
    return HttpResponse.json(successResponse(null, '报警已确认'));
  }),

  http.post('/api/v1/alarms/:id/process', () => {
    return HttpResponse.json(successResponse(null, '开始处理报警'));
  }),

  http.post('/api/v1/alarms/:id/resolve', async ({ request }) => {
    const body = (await request.json()) as any;
    return HttpResponse.json(
      successResponse(
        createAlarm({ status: 'resolved', handling_logs: [{ id: 'hl_new', action: 'resolved', handler_name: '测试员', comment: body.comment || '', created_at: new Date().toISOString() }] }),
        '报警已解决',
      ),
    );
  }),

  http.post('/api/v1/alarms/:id/escalate', () => {
    return HttpResponse.json(successResponse(null, '报警已升级'));
  }),

  // ===== 签到接口 =====
  http.get('/api/v1/signin', ({ request }) => {
    const url = new URL(request.url);
    const { page, page_size } = getPagination(url);
    const date = url.searchParams.get('date') || new Date().toISOString().split('T')[0];
    const list = Array.from({ length: 20 }, (_, i) =>
      createSigninRecord({ id: `s${i + 1}`, signin_date: date }),
    );
    return HttpResponse.json(paginatedResponse(list, page, page_size));
  }),

  http.get('/api/v1/signin/stats', ({ request }) => {
    const url = new URL(request.url);
    const date = url.searchParams.get('date') || new Date().toISOString().split('T')[0];
    return HttpResponse.json(
      successResponse({
        date,
        signed: 6,
        unsigned: 1,
        timeout: 1,
        total: 8,
        signin_rate: 75,
      }),
    );
  }),

  // ===== 巡访接口 =====
  http.get('/api/v1/patrol', ({ request }) => {
    const url = new URL(request.url);
    const { page, page_size } = getPagination(url);
    const list = Array.from({ length: 15 }, (_, i) => createPatrolTask({ id: `p${i + 1}` }));
    return HttpResponse.json(paginatedResponse(list, page, page_size));
  }),

  http.post('/api/v1/patrol', async ({ request }) => {
    const body = (await request.json()) as any;
    return HttpResponse.json(
      successResponse(createPatrolTask(body), '巡访任务已创建'),
      { status: 201 },
    );
  }),

  http.post('/api/v1/patrol/:id/accept', () => {
    return HttpResponse.json(successResponse(null, '任务已接受'));
  }),

  http.post('/api/v1/patrol/:id/complete', async ({ request }) => {
    const body = (await request.json()) as any;
    return HttpResponse.json(
      successResponse(
        createPatrolTask({ status: 'completed', result: body.result }),
        '任务已完成',
      ),
    );
  }),

  // ===== 健康报告接口 =====
  http.get('/api/v1/reports', ({ request }) => {
    const url = new URL(request.url);
    const { page, page_size } = getPagination(url);
    const list = Array.from({ length: 10 }, (_, i) => ({
      id: `r${i + 1}`,
      elderly_id: `e${String((i % 8) + 1).padStart(3, '0')}`,
      elderly_name: `老人${i + 1}`,
      report_week: `2026-W${String(25 - (i % 4)).padStart(2, '0')}`,
      health_score: 80 + Math.floor(Math.random() * 20),
      created_at: new Date(Date.now() - i * 86400000).toISOString(),
    }));
    return HttpResponse.json(paginatedResponse(list, page, page_size));
  }),

  // ===== 社区看板接口 =====
  http.get('/api/v1/dashboard', () => {
    return HttpResponse.json(successResponse(createDashboardData()));
  }),

  // ===== 管理员接口 =====
  http.get('/api/v1/admin/roles', () => {
    const list = ['super_admin', 'admin', 'operator', 'viewer'].map((code, i) =>
      createAdminRole({ id: `r00${i + 1}`, role_code: code, role_name: `${code}角色` }),
    );
    return HttpResponse.json(successResponse(list));
  }),

  http.post('/api/v1/admin/roles', async ({ request }) => {
    const body = (await request.json()) as any;
    return HttpResponse.json(
      successResponse(createAdminRole(body), '角色创建成功'),
      { status: 201 },
    );
  }),

  http.put('/api/v1/admin/roles/:id', async ({ request }) => {
    const body = (await request.json()) as any;
    return HttpResponse.json(successResponse(createAdminRole(body), '角色更新成功'));
  }),

  http.delete('/api/v1/admin/roles/:id', () => {
    return HttpResponse.json(successResponse(null, '角色已删除'));
  }),

  // ===== 系统配置接口 =====
  http.get('/api/v1/system/config', () => {
    return HttpResponse.json(
      successResponse({
        signin_start_time: '08:00',
        signin_end_time: '10:00',
        alarm_p0_response_seconds: 5,
        heart_rate_low: 50,
        heart_rate_high: 100,
      }),
    );
  }),

  http.put('/api/v1/system/config', () => {
    return HttpResponse.json(successResponse(null, '配置更新成功'));
  }),

  http.get('/api/v1/system/status', () => {
    return HttpResponse.json(
      successResponse({
        mysql: 'UP',
        redis: 'UP',
        emqx: 'UP',
        websocket: 'UP',
        uptime: '7d 12h 34m',
        memory_usage: '45.2%',
        cpu_usage: '23.8%',
      }),
    );
  }),

  // ===== 模拟 500 错误（用于错误场景测试）=====
  http.get('/api/v1/_test_error', () => {
    return HttpResponse.json(errorResponse('内部服务器错误', 500), { status: 500 });
  }),

  // ===== 模拟网络超时（用于超时测试）=====
  http.get('/api/v1/_test_timeout', async () => {
    await simulateDelay(30000); // 30秒延迟
    return HttpResponse.json(successResponse(null));
  }),
];
