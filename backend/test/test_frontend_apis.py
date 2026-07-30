#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AI老年健康守护系统 - 前端接口测试脚本

测试所有前端调用的后端 API 接口，生成详细测试报告。

使用方式：
    python test_frontend_apis.py                    # 使用默认配置
    python test_frontend_apis.py --host http://localhost:8080  # 指定服务器地址
    python test_frontend_apis.py --user admin --password xxx   # 指定账号
    python test_frontend_apis.py --verbose                    # 详细输出
    python test_frontend_apis.py --report json                # 输出 JSON 报告
"""

import argparse
import json
import sys
import time
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# ============ 颜色输出 ============
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    END = '\033[0m'

    @staticmethod
    def disable():
        """禁用颜色（Windows 兼容）"""
        Colors.GREEN = Colors.RED = Colors.YELLOW = Colors.BLUE = Colors.CYAN = Colors.BOLD = Colors.END = ''


# ============ 测试配置 ============
DEFAULT_CONFIG = {
    'host': 'http://localhost:8080',
    'username': 'admin',
    'password': 'Admin@2026',
    'timeout': 10,
}

# ============ 测试数据 ============
TEST_DATA = {
    'elderly': {
        'name': '测试老人',
        'gender': 'male',
        'age': 75,
        'phone': '13800138000',
        'address': '测试地址',
        'emergency_contact': '测试家属',
        'emergency_phone': '13900139000',
        'care_level': 'normal',
        'medical_history': '无',
    },
    'device': {
        'device_sn': 'EH-TEST-001',
        'device_name': '测试手表',
        'elderly_id': '',  # 会在测试中动态设置
    },
}


class APITester:
    """
    API 测试器

    功能：
    - 自动登录获取 Token
    - 测试所有前端接口
    - 生成测试报告
    """

    def __init__(self, config: Dict[str, Any], verbose: bool = False):
        self.config = config
        self.verbose = verbose
        self.base_url = config['host'].rstrip('/')
        self.timeout = config.get('timeout', 10)

        # 创建 Session（自动处理 Cookie 和 Headers）
        self.session = self._create_session()

        # 认证信息
        self.access_token: Optional[str] = None
        self.refresh_token: Optional[str] = None
        self.current_user: Optional[Dict] = None

        # 测试统计
        self.results: List[Dict[str, Any]] = []
        self.passed = 0
        self.failed = 0
        self.skipped = 0

        # 测试过程中创建的资源 ID（用于清理）
        self.created_elderly_id: Optional[str] = None
        self.created_alarm_id: Optional[str] = None
        self.created_task_id: Optional[str] = None
        self.created_report_id: Optional[str] = None

    def _page_data(self, resp: Dict[str, Any]) -> Dict[str, Any]:
        """兼容两种分页格式：
        - 旧格式：data 为 list，total/page/page_size 在响应外层
        - 新格式：data 为对象，内部包含 list/total/page/page_size
        """
        data = resp.get('data') or {}
        if isinstance(data, list):
            return {
                'list': data,
                'total': resp.get('total', 0),
                'page': resp.get('page', 1),
                'page_size': resp.get('page_size', 10),
            }
        return data

    def _create_session(self) -> requests.Session:
        """创建带重试机制的 Session"""
        session = requests.Session()

        # 重试策略
        retry_strategy = Retry(
            total=3,
            backoff_factor=0.5,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=['GET', 'POST', 'PUT', 'DELETE'],
        )
        adapter = HTTPAdapter(max_retries=retry_strategy)
        session.mount('http://', adapter)
        session.mount('https://', adapter)

        # 默认 Headers
        session.headers.update({
            'Content-Type': 'application/json',
            'User-Agent': 'API-Tester/1.0',
        })

        return session

    def _log(self, message: str, level: str = 'info'):
        """输出日志"""
        if not self.verbose and level == 'debug':
            return

        prefix = {
            'info': f'{Colors.BLUE}[INFO]{Colors.END}',
            'debug': f'{Colors.CYAN}[DEBUG]{Colors.END}',
            'warning': f'{Colors.YELLOW}[WARN]{Colors.END}',
            'error': f'{Colors.RED}[ERROR]{Colors.END}',
            'success': f'{Colors.GREEN}[PASS]{Colors.END}',
            'fail': f'{Colors.RED}[FAIL]{Colors.END}',
        }.get(level, '[INFO]')

        print(f'{prefix} {message}')

    def _request(
        self,
        method: str,
        path: str,
        data: Optional[Dict] = None,
        params: Optional[Dict] = None,
        headers: Optional[Dict] = None,
        auth_required: bool = True,
    ) -> Tuple[int, Dict[str, Any]]:
        """
        发送 HTTP 请求

        Returns:
            (status_code, response_json)
        """
        url = f'{self.base_url}{path}'

        # 添加认证 Header
        request_headers = dict(self.session.headers)
        if headers:
            request_headers.update(headers)

        if auth_required and self.access_token:
            request_headers['Authorization'] = f'Bearer {self.access_token}'

        try:
            if method.upper() == 'GET':
                response = self.session.get(url, params=params, headers=request_headers, timeout=self.timeout)
            elif method.upper() == 'POST':
                response = self.session.post(url, json=data, params=params, headers=request_headers, timeout=self.timeout)
            elif method.upper() == 'PUT':
                response = self.session.put(url, json=data, params=params, headers=request_headers, timeout=self.timeout)
            elif method.upper() == 'DELETE':
                response = self.session.delete(url, params=params, headers=request_headers, timeout=self.timeout)
            else:
                raise ValueError(f'不支持的 HTTP 方法: {method}')

            # 解析响应
            try:
                resp_json = response.json()
            except json.JSONDecodeError:
                resp_json = {'raw': response.text}

            return response.status_code, resp_json

        except requests.exceptions.Timeout:
            self._log(f'请求超时: {method} {path}', 'error')
            return 0, {'error': 'timeout'}
        except requests.exceptions.ConnectionError:
            self._log(f'连接失败: {url}', 'error')
            return 0, {'error': 'connection_failed'}
        except Exception as e:
            self._log(f'请求异常: {e}', 'error')
            return 0, {'error': str(e)}

    def _assert(
        self,
        test_name: str,
        passed: bool,
        detail: str = '',
        response: Optional[Dict] = None,
    ):
        """记录测试结果"""
        result = {
            'name': test_name,
            'passed': passed,
            'detail': detail,
            'response': response,
            'timestamp': datetime.now().isoformat(),
        }
        self.results.append(result)

        if passed:
            self.passed += 1
            self._log(f'✓ {test_name}', 'success')
        else:
            self.failed += 1
            self._log(f'✗ {test_name}: {detail}', 'fail')

        if self.verbose and response:
            print(f'   响应: {json.dumps(response, ensure_ascii=False, indent=2)[:200]}...')

    # ============ 认证相关 ============
    def login(self) -> bool:
        """登录获取 Token"""
        self._log('=' * 60, 'info')
        self._log('开始登录...', 'info')
        self._log(f'  用户名: {self.config["username"]}', 'debug')
        self._log(f'  服务器: {self.base_url}', 'debug')

        status, resp = self._request(
            'POST',
            '/api/v1/auth/login',
            data={
                'username': self.config['username'],
                'password': self.config['password'],
            },
            auth_required=False,
        )

        if status == 200 and resp.get('code') == 0:
            data = resp.get('data', {})
            self.access_token = data.get('access_token')
            self.refresh_token = data.get('refresh_token')
            self.current_user = data.get('user')

            self._log(f'登录成功！用户: {self.current_user.get("username")}', 'success')
            self._log(f'  角色: {self.current_user.get("role")}', 'debug')
            self._log(f'  Token 过期时间: {data.get("expires_in")}秒', 'debug')
            return True
        else:
            self._log(f'登录失败！状态码: {status}', 'error')
            self._log(f'  响应: {resp}', 'error')
            return False

    def test_refresh_token(self):
        """测试刷新 Token"""
        self._log('测试: 刷新 Token', 'info')

        if not self.refresh_token:
            self._assert('刷新Token', False, '没有 refresh_token')
            return

        status, resp = self._request(
            'POST',
            '/api/v1/auth/refresh',
            data={'refresh_token': self.refresh_token},
            auth_required=False,
        )

        if status == 200 and resp.get('code') == 0:
            self.access_token = resp['data']['access_token']
            self._assert('刷新Token', True, '', resp)
        else:
            self._assert('刷新Token', False, f'状态码: {status}', resp)

    def test_get_profile(self):
        """测试获取用户信息"""
        self._log('测试: 获取用户信息', 'info')

        status, resp = self._request('GET', '/api/v1/auth/profile')

        if status == 200 and resp.get('code') == 0:
            user = resp['data']
            self._assert('获取用户信息', True, f'用户名: {user.get("username")}', resp)
        else:
            self._assert('获取用户信息', False, f'状态码: {status}', resp)

    def test_change_password(self):
        """测试修改密码"""
        self._log('测试: 修改密码', 'info')

        status, resp = self._request(
            'PUT',
            '/api/v1/auth/password',
            data={
                'old_password': self.config['password'],
                'new_password': self.config['password'],  # 改回原密码
            },
        )

        # 无论成功失败都记录（可能密码策略限制）
        if status == 200:
            self._assert('修改密码', True, '', resp)
        else:
            self._assert('修改密码', False, f'状态码: {status}', resp)

    def test_logout(self):
        """测试登出"""
        self._log('测试: 登出', 'info')

        status, resp = self._request('POST', '/api/v1/auth/logout')

        if status == 200:
            self._assert('登出', True, '', resp)
            self.access_token = None
        else:
            self._assert('登出', False, f'状态码: {status}', resp)

    # ============ 老人管理 ============
    def test_elderly_list(self):
        """测试获取老人列表"""
        self._log('测试: 获取老人列表', 'info')

        status, resp = self._request('GET', '/api/v1/elderly', params={
            'page': 1,
            'page_size': 10,
        })

        if status == 200 and resp.get('code') == 0:
            data = self._page_data(resp)
            total = data.get('total', 0)
            self._assert('获取老人列表', True, f'总数: {total}', resp)
            return data.get('list', [])
        else:
            self._assert('获取老人列表', False, f'状态码: {status}', resp)
            return []

    def test_elderly_create(self):
        """测试创建老人"""
        self._log('测试: 创建老人', 'info')

        status, resp = self._request(
            'POST',
            '/api/v1/elderly',
            data=TEST_DATA['elderly'],
        )

        if status == 200 and resp.get('code') == 0:
            elderly = resp.get('data') or {}
            self.created_elderly_id = elderly.get('id')
            self._assert('创建老人', True, f'ID: {self.created_elderly_id}', resp)
        else:
            self._assert('创建老人', False, f'状态码: {status}', resp)
            self.created_elderly_id = None

    def test_elderly_detail(self):
        """测试获取老人详情"""
        if not self.created_elderly_id:
            self._log('跳过: 获取老人详情（没有测试数据）', 'warning')
            self.skipped += 1
            return

        self._log('测试: 获取老人详情', 'info')

        status, resp = self._request('GET', f'/api/v1/elderly/{self.created_elderly_id}')

        if status == 200 and resp.get('code') == 0:
            self._assert('获取老人详情', True, '', resp)
        else:
            self._assert('获取老人详情', False, f'状态码: {status}', resp)

    def test_elderly_update(self):
        """测试更新老人信息"""
        if not self.created_elderly_id:
            self._log('跳过: 更新老人信息（没有测试数据）', 'warning')
            self.skipped += 1
            return

        self._log('测试: 更新老人信息', 'info')

        status, resp = self._request(
            'PUT',
            f'/api/v1/elderly/{self.created_elderly_id}',
            data={'address': f'测试地址_{int(time.time())}'},
        )

        if status == 200 and resp.get('code') == 0:
            self._assert('更新老人信息', True, '', resp)
        else:
            self._assert('更新老人信息', False, f'状态码: {status}', resp)

    def test_elderly_vitals(self):
        """测试获取老人体征历史"""
        if not self.created_elderly_id:
            self._log('跳过: 获取老人体征历史（没有测试数据）', 'warning')
            self.skipped += 1
            return

        self._log('测试: 获取老人体征历史', 'info')

        status, resp = self._request('GET', f'/api/v1/elderly/{self.created_elderly_id}/vitals', params={
            'metric': 'heart_rate',
            'range': '7d',
        })

        if status == 200 and resp.get('code') == 0:
            self._assert('获取老人体征历史', True, '', resp)
        else:
            self._assert('获取老人体征历史', False, f'状态码: {status}', resp)

    def test_elderly_delete(self):
        """测试删除老人（清理测试数据）"""
        if not self.created_elderly_id:
            self._log('跳过: 删除老人（没有测试数据）', 'warning')
            self.skipped += 1
            return

        self._log('测试: 删除老人', 'info')

        status, resp = self._request('DELETE', f'/api/v1/elderly/{self.created_elderly_id}')

        if status == 200 and resp.get('code') == 0:
            self._assert('删除老人', True, '', resp)
            self.created_elderly_id = None
        else:
            self._assert('删除老人', False, f'状态码: {status}', resp)

    # ============ 设备管理 ============
    def test_device_list(self):
        """测试获取设备列表"""
        self._log('测试: 获取设备列表', 'info')

        status, resp = self._request('GET', '/api/v1/devices', params={
            'page': 1,
            'page_size': 10,
        })

        if status == 200 and resp.get('code') == 0:
            data = self._page_data(resp)
            total = data.get('total', 0)
            self._assert('获取设备列表', True, f'总数: {total}', resp)
        else:
            self._assert('获取设备列表', False, f'状态码: {status}', resp)

    # ============ 报警管理 ============
    def test_alarm_list(self):
        """测试获取报警列表"""
        self._log('测试: 获取报警列表', 'info')

        status, resp = self._request('GET', '/api/v1/alarms', params={
            'page': 1,
            'page_size': 10,
        })

        if status == 200 and resp.get('code') == 0:
            data = self._page_data(resp)
            total = data.get('total', 0)
            self._assert('获取报警列表', True, f'总数: {total}', resp)

            # 保存一个报警 ID 用于后续测试
            if total > 0:
                self.created_alarm_id = data['list'][0]['id']
        else:
            self._assert('获取报警列表', False, f'状态码: {status}', resp)

    def test_alarm_detail(self):
        """测试获取报警详情"""
        if not self.created_alarm_id:
            self._log('跳过: 获取报警详情（没有测试数据）', 'warning')
            self.skipped += 1
            return

        self._log('测试: 获取报警详情', 'info')

        status, resp = self._request('GET', f'/api/v1/alarms/{self.created_alarm_id}')

        if status == 200 and resp.get('code') == 0:
            self._assert('获取报警详情', True, '', resp)
        else:
            self._assert('获取报警详情', False, f'状态码: {status}', resp)

    def test_alarm_confirm(self):
        """测试确认报警"""
        if not self.created_alarm_id:
            self._log('跳过: 确认报警（没有测试数据）', 'warning')
            self.skipped += 1
            return

        self._log('测试: 确认报警', 'info')

        status, resp = self._request(
            'POST',
            f'/api/v1/alarms/{self.created_alarm_id}/confirm',
            data={'comment': '测试确认'},
        )

        # 可能报警已被处理，接受 200 或 400
        if status in [200, 400]:
            self._assert('确认报警', True, f'状态码: {status}', resp)
        else:
            self._assert('确认报警', False, f'状态码: {status}', resp)

    # ============ 签到管理 ============
    def test_signin_list(self):
        """测试获取签到列表"""
        self._log('测试: 获取签到列表', 'info')

        status, resp = self._request('GET', '/api/v1/signin', params={
            'page': 1,
            'page_size': 10,
            'date': datetime.now().strftime('%Y-%m-%d'),
        })

        if status == 200 and resp.get('code') == 0:
            data = self._page_data(resp)
            total = data.get('total', 0)
            self._assert('获取签到列表', True, f'总数: {total}', resp)
        else:
            self._assert('获取签到列表', False, f'状态码: {status}', resp)

    def test_signin_overview(self):
        """测试获取签到概览"""
        self._log('测试: 获取签到概览', 'info')

        status, resp = self._request('GET', '/api/v1/signin/overview', params={
            'date': datetime.now().strftime('%Y-%m-%d'),
        })

        if status == 200 and resp.get('code') == 0:
            self._assert('获取签到概览', True, '', resp)
        else:
            self._assert('获取签到概览', False, f'状态码: {status}', resp)

    # ============ 巡访管理 ============
    def test_patrol_tasks(self):
        """测试获取巡访任务列表"""
        self._log('测试: 获取巡访任务列表', 'info')

        status, resp = self._request('GET', '/api/v1/patrol/tasks', params={
            'page': 1,
            'page_size': 10,
        })

        if status == 200 and resp.get('code') == 0:
            data = self._page_data(resp)
            total = data.get('total', 0)
            self._assert('获取巡访任务列表', True, f'总数: {total}', resp)
        else:
            self._assert('获取巡访任务列表', False, f'状态码: {status}', resp)

    # ============ 健康周报 ============
    def test_report_list(self):
        """测试获取健康周报列表"""
        self._log('测试: 获取健康周报列表', 'info')

        status, resp = self._request('GET', '/api/v1/reports', params={
            'page': 1,
            'page_size': 10,
        })

        if status == 200 and resp.get('code') == 0:
            data = self._page_data(resp)
            total = data.get('total', 0)
            self._assert('获取健康周报列表', True, f'总数: {total}', resp)
        else:
            self._assert('获取健康周报列表', False, f'状态码: {status}', resp)

    # ============ 社区看板 ============
    def test_dashboard(self):
        """测试获取社区看板数据"""
        self._log('测试: 获取社区看板数据', 'info')

        status, resp = self._request('GET', '/api/v1/dashboard')

        if status == 200 and resp.get('code') == 0:
            self._assert('获取社区看板数据', True, '', resp)
        else:
            self._assert('获取社区看板数据', False, f'状态码: {status}', resp)

    # ============ 管理员管理 ============
    def test_admin_list(self):
        """测试获取管理员列表"""
        self._log('测试: 获取管理员列表', 'info')

        status, resp = self._request('GET', '/api/v1/admin/users', params={
            'page': 1,
            'page_size': 10,
        })

        if status == 200 and resp.get('code') == 0:
            data = self._page_data(resp)
            total = data.get('total', 0)
            self._assert('获取管理员列表', True, f'总数: {total}', resp)
        else:
            self._assert('获取管理员列表', False, f'状态码: {status}', resp)

    def test_admin_roles(self):
        """测试获取角色列表"""
        self._log('测试: 获取角色列表', 'info')

        status, resp = self._request('GET', '/api/v1/admin/roles')

        if status == 200 and resp.get('code') == 0:
            self._assert('获取角色列表', True, '', resp)
        else:
            self._assert('获取角色列表', False, f'状态码: {status}', resp)

    def test_admin_audit_logs(self):
        """测试获取审计日志"""
        self._log('测试: 获取审计日志', 'info')

        status, resp = self._request('GET', '/api/v1/admin/audit-logs', params={
            'page': 1,
            'page_size': 10,
        })

        if status == 200 and resp.get('code') == 0:
            data = self._page_data(resp)
            total = data.get('total', 0)
            self._assert('获取审计日志', True, f'总数: {total}', resp)
        else:
            self._assert('获取审计日志', False, f'状态码: {status}', resp)

    # ============ 系统设置 ============
    def test_system_config(self):
        """测试获取系统配置"""
        self._log('测试: 获取系统配置', 'info')

        status, resp = self._request('GET', '/api/v1/system/config')

        if status == 200 and resp.get('code') == 0:
            self._assert('获取系统配置', True, '', resp)
        else:
            self._assert('获取系统配置', False, f'状态码: {status}', resp)

    def test_system_status(self):
        """测试获取系统状态"""
        self._log('测试: 获取系统状态', 'info')

        status, resp = self._request('GET', '/api/v1/system/status')

        if status == 200 and resp.get('code') == 0:
            self._assert('获取系统状态', True, '', resp)
        else:
            self._assert('获取系统状态', False, f'状态码: {status}', resp)

    # ============ 异常场景测试 ============
    def test_unauthorized_access(self):
        """测试未授权访问"""
        self._log('测试: 未授权访问', 'info')

        # 临时清除 Token
        old_token = self.access_token
        self.access_token = None

        status, resp = self._request('GET', '/api/v1/elderly', auth_required=False)

        # 恢复 Token
        self.access_token = old_token

        if status == 401:
            self._assert('未授权访问拦截', True, '正确返回 401', resp)
        else:
            self._assert('未授权访问拦截', False, f'期望 401，实际 {status}', resp)

    def test_invalid_token(self):
        """测试无效 Token"""
        self._log('测试: 无效 Token', 'info')

        old_token = self.access_token
        self.access_token = 'invalid_token_12345'

        status, resp = self._request('GET', '/api/v1/elderly')

        # 恢复 Token
        self.access_token = old_token

        if status == 401:
            self._assert('无效Token拦截', True, '正确返回 401', resp)
        else:
            self._assert('无效Token拦截', False, f'期望 401，实际 {status}', resp)

    def test_not_found(self):
        """测试 404 接口"""
        self._log('测试: 404 接口', 'info')

        status, resp = self._request('GET', '/api/v1/nonexistent')

        if status == 404:
            self._assert('404处理', True, '正确返回 404', resp)
        else:
            self._assert('404处理', False, f'期望 404，实际 {status}', resp)

    # ============ 运行所有测试 ============
    def run_all_tests(self):
        """运行所有测试"""
        self._log('=' * 60, 'info')
        self._log(f'{Colors.BOLD}AI老年健康守护系统 - 前端接口测试{Colors.END}', 'info')
        self._log('=' * 60, 'info')
        self._log(f'开始时间: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}', 'info')
        self._log(f'服务器: {self.base_url}', 'info')
        self._log('=' * 60, 'info')

        start_time = time.time()

        # 1. 认证测试
        self._log('\n' + '=' * 60, 'info')
        self._log(f'{Colors.BOLD}模块 1: 认证管理{Colors.END}', 'info')
        self._log('=' * 60, 'info')

        if not self.login():
            self._log('登录失败，跳过后续测试', 'error')
            return

        self.test_refresh_token()
        self.test_get_profile()
        self.test_change_password()

        # 2. 老人管理测试
        self._log('\n' + '=' * 60, 'info')
        self._log(f'{Colors.BOLD}模块 2: 老人管理{Colors.END}', 'info')
        self._log('=' * 60, 'info')

        self.test_elderly_list()
        self.test_elderly_create()
        self.test_elderly_detail()
        self.test_elderly_update()
        self.test_elderly_vitals()
        # 最后删除测试数据
        self.test_elderly_delete()

        # 3. 设备管理测试
        self._log('\n' + '=' * 60, 'info')
        self._log(f'{Colors.BOLD}模块 3: 设备管理{Colors.END}', 'info')
        self._log('=' * 60, 'info')

        self.test_device_list()

        # 4. 报警管理测试
        self._log('\n' + '=' * 60, 'info')
        self._log(f'{Colors.BOLD}模块 4: 报警管理{Colors.END}', 'info')
        self._log('=' * 60, 'info')

        self.test_alarm_list()
        self.test_alarm_detail()
        self.test_alarm_confirm()

        # 5. 签到管理测试
        self._log('\n' + '=' * 60, 'info')
        self._log(f'{Colors.BOLD}模块 5: 签到管理{Colors.END}', 'info')
        self._log('=' * 60, 'info')

        self.test_signin_list()
        self.test_signin_overview()

        # 6. 巡访管理测试
        self._log('\n' + '=' * 60, 'info')
        self._log(f'{Colors.BOLD}模块 6: 巡访管理{Colors.END}', 'info')
        self._log('=' * 60, 'info')

        self.test_patrol_tasks()

        # 7. 健康周报测试
        self._log('\n' + '=' * 60, 'info')
        self._log(f'{Colors.BOLD}模块 7: 健康周报{Colors.END}', 'info')
        self._log('=' * 60, 'info')

        self.test_report_list()

        # 8. 社区看板测试
        self._log('\n' + '=' * 60, 'info')
        self._log(f'{Colors.BOLD}模块 8: 社区看板{Colors.END}', 'info')
        self._log('=' * 60, 'info')

        self.test_dashboard()

        # 9. 管理员管理测试
        self._log('\n' + '=' * 60, 'info')
        self._log(f'{Colors.BOLD}模块 9: 管理员管理{Colors.END}', 'info')
        self._log('=' * 60, 'info')

        self.test_admin_list()
        self.test_admin_roles()
        self.test_admin_audit_logs()

        # 10. 系统设置测试
        self._log('\n' + '=' * 60, 'info')
        self._log(f'{Colors.BOLD}模块 10: 系统设置{Colors.END}', 'info')
        self._log('=' * 60, 'info')

        self.test_system_config()
        self.test_system_status()

        # 11. 异常场景测试
        self._log('\n' + '=' * 60, 'info')
        self._log(f'{Colors.BOLD}模块 11: 异常场景测试{Colors.END}', 'info')
        self._log('=' * 60, 'info')

        self.test_unauthorized_access()
        self.test_invalid_token()
        self.test_not_found()

        # 12. 登出
        self._log('\n' + '=' * 60, 'info')
        self._log(f'{Colors.BOLD}模块 12: 登出{Colors.END}', 'info')
        self._log('=' * 60, 'info')

        self.test_logout()

        # 测试完成
        elapsed_time = time.time() - start_time
        self._print_summary(elapsed_time)

    def _print_summary(self, elapsed_time: float):
        """打印测试摘要"""
        self._log('\n' + '=' * 60, 'info')
        self._log(f'{Colors.BOLD}测试摘要{Colors.END}', 'info')
        self._log('=' * 60, 'info')

        total = self.passed + self.failed + self.skipped

        print(f'\n  总测试数: {total}')
        print(f'  {Colors.GREEN}✓ 通过: {self.passed}{Colors.END}')
        print(f'  {Colors.RED}✗ 失败: {self.failed}{Colors.END}')
        if self.skipped > 0:
            print(f'  {Colors.YELLOW}- 跳过: {self.skipped}{Colors.END}')
        print(f'  耗时: {elapsed_time:.2f} 秒')
        print(f'  通过率: {self.passed / (self.passed + self.failed) * 100:.1f}%' if (self.passed + self.failed) > 0 else '  通过率: N/A')

        self._log('=' * 60, 'info')

        # 失败详情
        if self.failed > 0:
            print(f'\n{Colors.RED}失败详情:{Colors.END}')
            for result in self.results:
                if not result['passed']:
                    print(f'  ✗ {result["name"]}')
                    print(f'    {result["detail"]}')

    def export_report(self, format: str = 'text'):
        """导出测试报告"""
        if format == 'json':
            report = {
                'timestamp': datetime.now().isoformat(),
                'host': self.base_url,
                'user': self.config['username'],
                'summary': {
                    'total': self.passed + self.failed + self.skipped,
                    'passed': self.passed,
                    'failed': self.failed,
                    'skipped': self.skipped,
                    'pass_rate': self.passed / (self.passed + self.failed) * 100 if (self.passed + self.failed) > 0 else 0,
                },
                'results': self.results,
            }
            print(json.dumps(report, ensure_ascii=False, indent=2))
        else:
            # 文本报告
            print('\n' + '=' * 60)
            print('测试报告')
            print('=' * 60)
            print(f'时间: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
            print(f'服务器: {self.base_url}')
            print(f'用户: {self.config["username"]}')
            print('=' * 60)

            for result in self.results:
                status = f'{Colors.GREEN}PASS{Colors.END}' if result['passed'] else f'{Colors.RED}FAIL{Colors.END}'
                print(f'[{status}] {result["name"]}')
                if not result['passed']:
                    print(f'       {result["detail"]}')


def load_config_from_args() -> Dict[str, Any]:
    """从命令行参数加载配置"""
    parser = argparse.ArgumentParser(
        description='AI老年健康守护系统 - 前端接口测试脚本',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python test_frontend_apis.py
  python test_frontend_apis.py --host http://localhost:8080
  python test_frontend_apis.py --user admin --password xxx
  python test_frontend_apis.py --verbose --report json > report.json
        """,
    )

    parser.add_argument('--host', type=str, default=None, help='服务器地址 (默认: http://localhost:8080)')
    parser.add_argument('--user', type=str, default=None, help='用户名 (默认: admin)')
    parser.add_argument('--password', type=str, default=None, help='密码 (默认: Admin@2026)')
    parser.add_argument('--timeout', type=int, default=10, help='请求超时时间(秒) (默认: 10)')
    parser.add_argument('--verbose', '-v', action='store_true', help='详细输出')
    parser.add_argument('--report', type=str, choices=['text', 'json'], default='text', help='报告格式')
    parser.add_argument('--no-color', action='store_true', help='禁用颜色输出')

    args = parser.parse_args()

    # 合并配置
    config = DEFAULT_CONFIG.copy()
    if args.host:
        config['host'] = args.host
    if args.user:
        config['username'] = args.user
    if args.password:
        config['password'] = args.password
    config['timeout'] = args.timeout

    # 禁用颜色
    if args.no_color:
        Colors.disable()

    return config, args.verbose, args.report


def main():
    """主函数"""
    # 解析命令行参数
    config, verbose, report_format = load_config_from_args()

    # 创建测试器
    tester = APITester(config, verbose)

    try:
        # 运行所有测试
        tester.run_all_tests()

        # 导出报告
        if report_format != 'text':
            tester.export_report(report_format)

        # 退出码
        sys.exit(0 if tester.failed == 0 else 1)

    except KeyboardInterrupt:
        print(f'\n\n{Colors.YELLOW}测试被用户中断{Colors.END}')
        sys.exit(130)
    except Exception as e:
        print(f'\n\n{Colors.RED}测试异常: {e}{Colors.END}')
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
