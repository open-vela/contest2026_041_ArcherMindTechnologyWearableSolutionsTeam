import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ConfigProvider, App as AntApp } from 'antd';
import zhCN from 'antd/locale/zh_CN';
import { useAuthStore } from '@/store/authStore';
import { useWSStore } from '@/store/wsStore';
import { useEffect } from 'react';
import AppLayout from '@/components/Layout/AppLayout';
import Login from '@/pages/Login';
import Dashboard from '@/pages/Dashboard';
import ElderlyManage from '@/pages/ElderlyManage';
import DeviceManage from '@/pages/DeviceManage';
import AlarmManage from '@/pages/AlarmManage';
import SigninManage from '@/pages/SigninManage';
import PatrolManage from '@/pages/PatrolManage';
import HealthReports from '@/pages/HealthReports';
import AdminManage from '@/pages/AdminManage';
import SystemSettings from '@/pages/SystemSettings';
import dayjs from 'dayjs';
import 'dayjs/locale/zh-cn';

dayjs.locale('zh-cn');

// 设置页面标题
const APP_TITLE = import.meta.env.VITE_APP_TITLE || 'AI老年健康守护系统';
document.title = APP_TITLE;

function AuthGuard({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAuthStore();
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  return <>{children}</>;
}

function AppRoutes() {
  const { isAuthenticated, token } = useAuthStore();
  const { connect } = useWSStore();

  // 只在首次认证成功时连接 WebSocket
  // 不依赖 token（token 刷新不应断开 WS），改由 wsStore 内部自行刷新 token
  useEffect(() => {
    if (isAuthenticated && token) {
      connect(token);
      // 不再在 cleanup 中 disconnect！
      // 让 wsStore 自己管理生命周期（包括 token 过期后自动用新 token 重连）
      // return () => disconnect();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated]); // 只依赖 isAuthenticated，不依赖 token

  return (
    <Routes>
      <Route path="/login" element={isAuthenticated ? <Navigate to="/dashboard" replace /> : <Login />} />
      <Route
        path="/"
        element={
          <AuthGuard>
            <AppLayout />
          </AuthGuard>
        }
      >
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<Dashboard />} />
        <Route path="elderly" element={<ElderlyManage />} />
        <Route path="devices" element={<DeviceManage />} />
        <Route path="alarms" element={<AlarmManage />} />
        <Route path="signin" element={<SigninManage />} />
        <Route path="patrol" element={<PatrolManage />} />
        <Route path="reports" element={<HealthReports />} />
        <Route path="admin/*" element={<AdminManage />} />
        <Route path="settings" element={<SystemSettings />} />
      </Route>
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <ConfigProvider
      locale={zhCN}
      theme={{
        token: {
          colorPrimary: '#1677ff',
          borderRadius: 6,
          fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif',
        },
        components: {
          Layout: { bodyBg: '#f5f5f5', headerBg: '#fff', siderBg: '#fff' },
          Menu: { itemBg: 'transparent', subMenuItemBg: 'transparent' },
        },
      }}
    >
      <AntApp>
        <BrowserRouter>
          <AppRoutes />
        </BrowserRouter>
      </AntApp>
    </ConfigProvider>
  );
}
