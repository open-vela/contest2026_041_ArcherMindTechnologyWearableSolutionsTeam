import { useEffect, useState } from 'react';
import {
  Table, Card, Button, Tag, Space, Typography, message, Modal, Form, Input, Select,
  Row, Col, Tabs, Descriptions, Popconfirm, Badge, Timeline,
} from 'antd';
import {
  SafetyCertificateOutlined, AuditOutlined, PlusOutlined, DeleteOutlined,
  LockOutlined, UnlockOutlined, PoweroffOutlined, KeyOutlined,
} from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';
import { adminAPI } from '@/api';
import type { UserInfo, AdminRole, AuditLog } from '@/types';
import dayjs from 'dayjs';

const { Title, Text, Paragraph } = Typography;

export default function AdminManage() {
  const [activeTab, setActiveTab] = useState('users');
  const [admins, setAdmins] = useState<UserInfo[]>([]);
  const [adminTotal, setAdminTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [roles, setRoles] = useState<AdminRole[]>([]);
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>([]);
  const [auditTotal, setAuditTotal] = useState(0);
  const [auditPage, setAuditPage] = useState(1);
  const [createVisible, setCreateVisible] = useState(false);
  const [form] = Form.useForm();

  const pageSize = 6;

  const loadAdmins = async () => {
    setLoading(true);
    try {
      const res = await adminAPI.getAdmins({ page, page_size: pageSize });
      // 后端 SuccessPage 返回 {code, message, data, total, page, page_size}
      const raw = res?.data;
      const list: UserInfo[] = Array.isArray(raw) ? raw : (Array.isArray(raw?.data) ? raw.data : []);
      const tot = res?.total ?? 0;
      console.log('[AdminManage] loadAdmins response:', res);
      console.log('[AdminManage] parsed list:', list, 'total:', tot);
      // 确保每个用户都有 permissions 数组
      const safeList = list.map((a: any) => ({
        ...a,
        permissions: Array.isArray(a.permissions) ? a.permissions : [],
      }));
      setAdmins(safeList);
      setAdminTotal(tot);
    } catch (err) {
      console.error('[AdminManage] Failed to load admins:', err);
      message.error('加载管理员列表失败');
      setAdmins([]);
    } finally { setLoading(false); }
  };

  const loadRoles = async () => {
    try {
      const res = await adminAPI.getRoles();
      const rawRoles = Array.isArray(res?.data) ? res.data : (Array.isArray(res) ? res : []);
      // 确保 permissions 字段不为 undefined
      const safeRoles = rawRoles.map((r: any) => ({
        ...r,
        permissions: Array.isArray(r.permissions) ? r.permissions : [],
      }));
      setRoles(safeRoles);
    } catch { /* fallback */ }
  };

  const loadAuditLogs = async () => {
    setLoading(true);
    try {
      const res = await adminAPI.getAuditLogs({ page: auditPage, page_size: 8 });
      // 后端 SuccessPage 返回 {code, message, data, total, page, page_size}
      const raw = res?.data;
      const list: AuditLog[] = Array.isArray(raw) ? raw : (Array.isArray(raw?.data) ? raw.data : []);
      const tot = res?.total ?? 0;
      setAuditLogs(list);
      setAuditTotal(tot);
    } catch (err) {
      console.error('[AdminManage] Failed to load audit logs:', err);
      setAuditLogs([]);
    } finally { setLoading(false); }
  };

  useEffect(() => { loadAdmins(); }, [page]);
  useEffect(() => { loadRoles(); }, []);
  useEffect(() => { loadAuditLogs(); }, [auditPage]);

  const userColumns: ColumnsType<UserInfo> = [
    { title: '用户名', dataIndex: 'username', width: 100 },
    { title: '姓名', dataIndex: 'real_name', width: 100 },
    {
      title: '角色', dataIndex: 'role', width: 100,
      render: (_: string, r: UserInfo) => {
        const roleCode = r.role;
        const displayName = r.admin_role || {
          super_admin: '超级管理员',
          admin: '管理员',
          community: '社区人员',
          family: '家属',
          elderly: '老人',
        }[roleCode] || roleCode;
        const colorMap: Record<string, string> = {
          super_admin: 'red', admin: 'blue', community: 'green', family: 'orange', elderly: 'default',
        };
        return <Tag color={colorMap[roleCode] || 'default'}>{displayName}</Tag>;
      },
    },
    { title: '社区', dataIndex: 'community_name', width: 100, render: (v: string) => v || <Text type="secondary">全局</Text> },
    { title: '手机', dataIndex: 'phone', width: 120 },
    {
      title: '权限数', dataIndex: 'permissions', width: 70,
      render: (v: string[]) => <Tag>{(Array.isArray(v) ? v.length : 0)} 项</Tag>,
    },
    {
      title: '操作', width: 200, render: (_, r) => (
        <Space size={0}>
          <Popconfirm title="确定重置密码？" onConfirm={() => message.success('密码已重置')}>
            <Button type="link" size="small" icon={<KeyOutlined />}>重置密码</Button>
          </Popconfirm>
          <Popconfirm title="确定锁定？" onConfirm={() => message.success('已锁定')}>
            <Button type="link" size="small" icon={<LockOutlined />}>锁定</Button>
          </Popconfirm>
          <Popconfirm title="确定强制登出？" onConfirm={() => message.success('已强制登出')}>
            <Button type="link" size="small" danger icon={<PoweroffOutlined />}>登出</Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  const auditColumns: ColumnsType<AuditLog> = [
    {
      title: '级别', dataIndex: 'audit_level', width: 70,
      render: (v: string) => {
        const map: Record<string, string> = { CRITICAL: '严重', HIGH: '高', MEDIUM: '中', LOW: '低' };
        const colorMap: Record<string, string> = { CRITICAL: 'red', HIGH: 'orange', MEDIUM: 'blue', LOW: 'default' };
        return <Tag color={colorMap[v]}>{map[v]}</Tag>;
      },
    },
    { title: '操作人', dataIndex: 'operator_name', width: 100 },
    { title: '模块', dataIndex: 'module', width: 80 },
    { title: '操作', dataIndex: 'operation', width: 100 },
    { title: '描述', dataIndex: 'description', ellipsis: true },
    { title: '来源IP', dataIndex: 'source_ip', width: 120 },
    {
      title: '结果', dataIndex: 'result_status', width: 70,
      render: (v: string) => v === 'SUCCESS' ? <Tag color="green">成功</Tag> : v === 'DENIED' ? <Tag color="orange">拒绝</Tag> : <Tag color="red">失败</Tag>,
    },
    { title: '时间', dataIndex: 'created_at', width: 130, render: (v: string) => dayjs(v).format('MM-DD HH:mm:ss') },
  ];

  const handleCreateAdmin = async (values: Record<string, unknown>) => {
    try {
      await adminAPI.createAdmin({
        username: values.username as string,
        real_name: values.real_name as string,
        password: 'Temp@123',
        admin_role_id: values.role as string,
        phone: values.phone as string,
      } as any);
      message.success('管理员已创建，初始密码: Temp@123');
      setCreateVisible(false);
      form.resetFields();
      loadAdmins();
    } catch (e: any) { console.error('[AdminManage] Create failed:', e); message.error(e?.message || '创建失败'); }
  };

  const tabItems = [
    {
      key: 'users', label: <span><SafetyCertificateOutlined /> 管理员账户</span>,
      children: (
        <>
          <Card style={{ marginBottom: 16 }}>
            <Space>
              <Button type="primary" icon={<PlusOutlined />} onClick={() => setCreateVisible(true)}>新建管理员</Button>
              <Text type="secondary">共 {adminTotal} 个管理员</Text>
            </Space>
          </Card>
          <Table dataSource={admins} columns={userColumns} rowKey="id" loading={loading}
            pagination={{ current: page, total: adminTotal, pageSize, onChange: (p) => setPage(p) }} />
        </>
      ),
    },
    {
      key: 'roles', label: <span><SafetyCertificateOutlined /> 角色管理</span>,
      children: (
        <Row gutter={[16, 16]}>
          {roles.map((role) => (
            <Col xs={24} sm={12} key={role.id}>
              <Card title={role.role_name} size="small" extra={role.is_system ? <Tag color="blue">系统预置</Tag> : null}>
                <Paragraph type="secondary">{role.description || role.role_name}</Paragraph>
                <Text>权限码: </Text>
                <Tag>{role.role_code}</Tag>
                <br />
                <Button type="link" size="small" onClick={() => message.info(`查看 ${role.role_name} 的完整权限列表`)}>
                  查看权限详情 ({(role.permissions?.length ?? 0) > 0 ? role.permissions.length : '预置'})
                </Button>
              </Card>
            </Col>
          ))}
        </Row>
      ),
    },
    {
      key: 'audit', label: <span><AuditOutlined /> 审计日志</span>,
      children: (
        <Table dataSource={auditLogs} columns={auditColumns} rowKey="id" loading={loading}
          pagination={{ current: auditPage, total: auditTotal, pageSize: 8, onChange: (p) => setAuditPage(p) }}
          scroll={{ x: 900 }}
          onRow={(r) => ({
            style: { background: r.audit_level === 'CRITICAL' ? '#fff2f0' : r.audit_level === 'HIGH' ? '#fffbe6' : undefined },
          })}
        />
      ),
    },
    {
      key: 'security', label: <span>🔒 安全策略</span>,
      children: (
        <Row gutter={[16, 16]}>
          <Col span={12}>
            <Card title="密码策略" size="small">
              <Descriptions column={1} size="small">
                <Descriptions.Item label="最小长度">12 位</Descriptions.Item>
                <Descriptions.Item label="复杂度">大小写字母 + 数字 + 特殊字符</Descriptions.Item>
                <Descriptions.Item label="有效期">90 天</Descriptions.Item>
                <Descriptions.Item label="历史密码校验">最近 5 个密码不可用</Descriptions.Item>
                <Descriptions.Item label="哈希算法">bcrypt (cost=12)</Descriptions.Item>
              </Descriptions>
            </Card>
          </Col>
          <Col span={12}>
            <Card title="登录策略" size="small">
              <Descriptions column={1} size="small">
                <Descriptions.Item label="最大失败次数">5 次</Descriptions.Item>
                <Descriptions.Item label="锁定时间">30 分钟</Descriptions.Item>
                <Descriptions.Item label="IP 锁定阈值">同 IP 20 次失败 / 30 分钟</Descriptions.Item>
                <Descriptions.Item label="2FA 验证">强制启用 (TOTP)</Descriptions.Item>
              </Descriptions>
            </Card>
          </Col>
          <Col span={12}>
            <Card title="会话策略" size="small">
              <Descriptions column={1} size="small">
                <Descriptions.Item label="Access Token 有效期">15 分钟</Descriptions.Item>
                <Descriptions.Item label="Refresh Token 有效期">8 小时</Descriptions.Item>
                <Descriptions.Item label="最大并发会话">3 个</Descriptions.Item>
                <Descriptions.Item label="空闲超时">30 分钟自动登出</Descriptions.Item>
              </Descriptions>
            </Card>
          </Col>
          <Col span={12}>
            <Card title="IP 白名单策略" size="small">
              <Descriptions column={1} size="small">
                <Descriptions.Item label="级别">三级 (全局 / 角色 / 用户)</Descriptions.Item>
                <Descriptions.Item label="规则">CIDR 格式 (192.168.1.0/24)</Descriptions.Item>
                <Descriptions.Item label="默认">白名单为空时允许所有IP</Descriptions.Item>
              </Descriptions>
            </Card>
          </Col>
          <Col span={24}>
            <Popconfirm title="确定强制所有管理员重新登录？">
              <Button danger icon={<PoweroffOutlined />}>🚨 强制全局登出</Button>
            </Popconfirm>
          </Col>
        </Row>
      ),
    },
  ];

  return (
    <div>
      <Title level={4}>系统管理</Title>
      <Tabs activeKey={activeTab} onChange={setActiveTab} items={tabItems} />

      <Modal title="新建管理员" open={createVisible} onCancel={() => { setCreateVisible(false); form.resetFields(); }} onOk={() => form.submit()} width={480}>
        <Form form={form} layout="vertical" onFinish={handleCreateAdmin}>
          <Form.Item name="username" label="用户名" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="real_name" label="姓名" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="phone" label="联系电话">
            <Input />
          </Form.Item>
          <Form.Item name="role" label="角色" rules={[{ required: true }]}>
            <Select options={[
              { value: 'admin', label: '管理员' },
              { value: 'community', label: '社区人员' },
            ]} />
          </Form.Item>
          <Form.Item name="community_name" label="所属社区">
            <Select options={[
              { value: '花木社区', label: '花木社区' },
              { value: '联洋社区', label: '联洋社区' },
              { value: '', label: '全局' },
            ]} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
