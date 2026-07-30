import { useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import { Layout, Menu, Badge, Avatar, Dropdown, theme, Typography } from 'antd';
import {
  DashboardOutlined,
  TeamOutlined,
  ThunderboltOutlined,
  AlertOutlined,
  CheckCircleOutlined,
  EnvironmentOutlined,
  FileTextOutlined,
  SettingOutlined,
  SafetyCertificateOutlined,
  LogoutOutlined,
  UserOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
  ApiOutlined,
  HeartOutlined,
} from '@ant-design/icons';
import { useAuthStore } from '@/store/authStore';
import { useWSStore } from '@/store/wsStore';
import type { MenuProps } from 'antd';

const { Sider, Header, Content } = Layout;
const { Text } = Typography;

type MenuItem = Required<MenuProps>['items'][number];

function getItem(label: string, key: string, icon: React.ReactNode, children?: MenuItem[]): MenuItem {
  return { key, icon, label, children } as MenuItem;
}

const menuItems: MenuItem[] = [
  getItem('社区看板', '/dashboard', <DashboardOutlined />),
  { type: 'divider' },
  getItem('老人管理', '/elderly', <HeartOutlined />),
  getItem('设备管理', '/devices', <ThunderboltOutlined />),
  getItem('报警管理', '/alarms', <AlertOutlined />),
  getItem('签到管理', '/signin', <CheckCircleOutlined />),
  getItem('巡访管理', '/patrol', <EnvironmentOutlined />),
  { type: 'divider' },
  getItem('健康周报', '/reports', <FileTextOutlined />),
  { type: 'divider' },
  getItem('系统管理', '/admin', <SafetyCertificateOutlined />, [
    getItem('管理员管理', '/admin/users', <SafetyCertificateOutlined />),
    getItem('审计日志', '/admin/audit', <FileTextOutlined />),
  ]),
  getItem('系统设置', '/settings', <SettingOutlined />),
];

export default function AppLayout() {
  const [collapsed, setCollapsed] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const { user, logout } = useAuthStore();
  const { connected, newAlarms } = useWSStore();
  const { token: themeToken } = theme.useToken();

  const selectedKey = '/' + (location.pathname.split('/').filter(Boolean)[0] || 'dashboard');

  const userDropdownItems: MenuProps['items'] = [
    { key: 'profile', icon: <UserOutlined />, label: `${user?.real_name || user?.username}` },
    { key: 'role', icon: <SafetyCertificateOutlined />, label: `角色: ${user?.role === 'admin' ? '管理员' : user?.role}` },
    { type: 'divider' },
    { key: 'logout', icon: <LogoutOutlined />, label: '退出登录', danger: true },
  ];

  const handleUserMenu = ({ key }: { key: string }) => {
    if (key === 'logout') {
      logout().then(() => navigate('/login'));
    }
  };

  return (
    <Layout style={{ minHeight: '100vh' }}>
      {/* 侧边栏 */}
      <Sider
        trigger={null}
        collapsible
        collapsed={collapsed}
        width={220}
        theme="light"
        style={{
          borderRight: `1px solid ${themeToken.colorBorderSecondary}`,
          boxShadow: '2px 0 8px rgba(0,0,0,0.04)',
        }}
      >
        <div
          style={{
            height: 64,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            borderBottom: `1px solid ${themeToken.colorBorderSecondary}`,
          }}
        >
          {!collapsed ? (
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 32, height: 32, borderRadius: 8,
                background: 'linear-gradient(135deg, #1677ff, #69b1ff)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: '#fff', fontWeight: 'bold', fontSize: 16,
              }}>
                AI
              </div>
              <Text strong style={{ fontSize: 15, whiteSpace: 'nowrap' }}>
                健康守护后台
              </Text>
            </div>
          ) : (
            <div style={{
              width: 32, height: 32, borderRadius: 8,
              background: 'linear-gradient(135deg, #1677ff, #69b1ff)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: '#fff', fontWeight: 'bold', fontSize: 16,
            }}>
              AI
            </div>
          )}
        </div>
        <Menu
          mode="inline"
          selectedKeys={[selectedKey]}
          defaultOpenKeys={['/admin']}
          items={menuItems}
          onClick={({ key }) => navigate(key)}
          style={{ border: 'none', marginTop: 8 }}
        />
      </Sider>

      {/* 主内容区 */}
      <Layout>
        {/* 顶部栏 */}
        <Header
          style={{
            background: '#fff',
            padding: '0 24px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            borderBottom: `1px solid ${themeToken.colorBorderSecondary}`,
            height: 64,
            lineHeight: '64px',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <span
              onClick={() => setCollapsed(!collapsed)}
              style={{ fontSize: 18, cursor: 'pointer', color: themeToken.colorTextSecondary }}
            >
              {collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            </span>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <Badge status={connected ? 'success' : 'error'} text="" />
              <Text type="secondary" style={{ fontSize: 13 }}>
                {connected ? 'WebSocket 已连接' : 'WebSocket 未连接'}
              </Text>
              <ApiOutlined style={{ color: '#52c41a' }} />
              <Text type="secondary" style={{ fontSize: 13 }}>服务正常</Text>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
            <Badge count={newAlarms} size="small">
              <AlertOutlined style={{ fontSize: 18, cursor: 'pointer', color: '#ff4d4f' }}
                onClick={() => { navigate('/alarms'); }} />
            </Badge>
            <Dropdown menu={{ items: userDropdownItems, onClick: handleUserMenu }} placement="bottomRight">
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
                <Avatar size="small" icon={<UserOutlined />} style={{ background: '#1677ff' }} />
                <Text>{user?.real_name || user?.username || '管理员'}</Text>
              </div>
            </Dropdown>
          </div>
        </Header>

        {/* 页面内容 */}
        <Content
          style={{
            margin: 16,
            padding: 24,
            background: '#fff',
            borderRadius: 8,
            minHeight: 280,
            overflow: 'auto',
          }}
        >
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  );
}
