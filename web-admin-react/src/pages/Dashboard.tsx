import { useEffect, useState } from 'react';
import { Row, Col, Card, Table, Tag, Statistic, Typography, Space, Spin, Badge, Progress } from 'antd';
import {
  TeamOutlined, ThunderboltOutlined, CheckCircleOutlined,
  AlertOutlined,
} from '@ant-design/icons';
import { dashboardAPI } from '@/api';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

// 后端实际返回的 Dashboard 数据结构（扁平式）
interface BackendDashboard {
  alarms?: { p0: number; p1: number; pending: number; today_total: number };
  devices?: { online: number; total: number };
  elderly?: { active: number; total: number };
  patrols?: { pending: number };
  server_time?: string;
  signin?: { checked_in: number; rate: number; total: number };
}

const levelColor: Record<string, string> = { P0: '#ff4d4f', P1: '#fa8c16', P2: '#faad14', P3: '#1890ff' };

export default function Dashboard() {
  const [data, setData] = useState<BackendDashboard | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
    const timer = setInterval(loadData, 30000);
    return () => clearInterval(timer);
  }, []);

  const loadData = async () => {
    try {
      const res = await dashboardAPI.getData();
      console.log('[Dashboard] API raw response:', JSON.stringify(res).slice(0, 500));
      // 兼容后端返回的扁平结构
      const rawData = res?.data as BackendDashboard | null;
      console.log('[Dashboard] Parsed data:', JSON.stringify(rawData)?.slice(0, 300));
      setData(rawData);
    } catch (e) {
      console.error('[Dashboard] Failed to load:', e);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div style={{ textAlign: 'center', padding: 100 }}><Spin size="large" tip="加载中..." /></div>;
  }
  if (!data) return <div>数据加载失败</div>;

  // 安全取值（全部带默认值）
  const elderlyTotal = data?.elderly?.total ?? 0;
  const devicesOnline = data?.devices?.online ?? 0;
  const devicesTotal = data?.devices?.total ?? 0;
  const signinRate = data?.signin?.rate ?? 0;
  const pendingAlarms = data?.alarms?.pending ?? 0;
  const p0Alarms = data?.alarms?.p0 ?? 0;
  const p1Alarms = data?.alarms?.p1 ?? 0;
  const todayAlarmTotal = data?.alarms?.today_total ?? 0;
  const activeElderly = data?.elderly?.active ?? 0;
  const pendingPatrols = data?.patrols?.pending ?? 0;
  const signedIn = data?.signin?.checked_in ?? 0;
  const signInTotal = data?.signin?.total ?? 0;

  return (
    <div>
      <Title level={4} style={{ marginBottom: 20 }}>
        社区看板 {' '}
        <Text type="secondary" style={{ fontSize: 14, fontWeight: 'normal' }}>
          {dayjs().format('YYYY年MM月DD日 HH:mm')} 更新
          {data.server_time ? ` · 服务器 ${dayjs(data.server_time).format('HH:mm:ss')}` : ''}
        </Text>
      </Title>

      {/* 顶部指标卡片 — 使用后端实际返回的扁平字段 */}
      <Row gutter={[16, 16]} style={{ marginBottom: 20 }}>
        <Col xs={12} sm={6}>
          <Card style={{ borderLeft: '4px solid #1677ff' }}>
            <Statistic title="接入老人" value={elderlyTotal} prefix={<TeamOutlined />} />
            {activeElderly > 0 && (
              <Text type="secondary" style={{ fontSize: 12 }}>活跃 {activeElderly}</Text>
            )}
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card style={{ borderLeft: '4px solid #52c41a' }}>
            <Statistic title="在线设备" value={devicesOnline}
              suffix={`/ ${devicesTotal}`}
              prefix={<ThunderboltOutlined />}
              valueStyle={devicesOnline === devicesTotal && devicesTotal > 0 ? { color: '#52c41a' } : undefined}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card style={{ borderLeft: '4px solid #722ed1' }}>
            <Statistic title="今日签到率" value={Math.round(signinRate * 100)}
              suffix="%" prefix={<CheckCircleOutlined />}
              valueStyle={signInTotal === 0 ? undefined : signinRate >= 0.9 ? { color: '#52c41a' } : { color: '#faad14' }}
            />
            {signInTotal > 0 && (
              <Text type="secondary" style={{ fontSize: 12 }}>{signedIn}/{signInTotal}</Text>
            )}
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card style={{
            borderLeft: `4px solid ${pendingAlarms + p0Alarms > 0 ? '#ff4d4f' : '#52c41a'}`,
            background: p0Alarms > 0 ? '#fff2f0' : undefined,
          }}>
            <Statistic title="待处理报警" value={pendingAlarms}
              prefix={<AlertOutlined style={{ color: p0Alarms > 0 ? '#ff4d4f' : '#52c41a' }} />}
            />
            {todayAlarmTotal > 0 && (
              <Space size={8}>
                <Tag color="#ff4d4f">P0:{p0Alarms}</Tag>
                <Tag color="#faad14">P1:{p1Alarms}</Tag>
                <Text type="secondary">今日{todayAlarmTotal}</Text>
              </Space>
            )}
          </Card>
        </Col>
      </Row>

      {/* 中间区域 — 后端暂未提供图表数据时显示占位 */}
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col xs={24} lg={16}>
          <Card
            title={<Space>📊 数据概览</Space>}
            size="small"
          >
            <Row gutter={[24, 16]}>
              <Col span={6}>
                <Statistic title="P0 紧急报警" value={p0Alarms} valueStyle={{ color: p0Alarms > 0 ? '#ff4d4f' : '#999' }} />
              </Col>
              <Col span={6}>
                <Statistic title="P1 严重报警" value={p1Alarms} valueStyle={{ color: p1Alarms > 0 ? '#faad14' : '#999' }} />
              </Col>
              <Col span={6}>
                <Statistic title="今日总报警" value={todayAlarmTotal} />
              </Col>
              <Col span={6}>
                <Statistic title="待办巡访" value={pendingPatrols} suffix="项"
                  valueStyle={{ color: pendingPatrols > 0 ? '#1677ff' : '#999' }}
                />
              </Col>
            </Row>
            <div style={{ marginTop: 16, padding: '12px 16px', background: '#fafafa', borderRadius: 8, fontSize: 13, color: '#666' }}>
              💡 图表模块（报警趋势/设备在线率）将在后端实现统计接口后自动展示。当前显示的是实时统计数据。
            </div>
          </Card>
        </Col>

        <Col xs={24} lg={8}>
          {/* 签到概况 */}
          <Card title="今日签到概况" size="small" style={{ marginBottom: 16 }}>
            <Progress
              percent={signInTotal > 0 ? Math.round((signedIn / signInTotal) * 100) : 0}
              status={signedIn < signInTotal ? 'exception' : 'success'}
              format={(p) => `${p}%`}
            />
            <Row justify="space-around" style={{ marginTop: 8 }}>
              <Col><Text type="success">已签 {signedIn}</Text></Col>
              <Col><Text type="warning">未签 {(signInTotal || 0) - signedIn}</Text></Col>
              <Col><Text>总数 {signInTotal}</Text></Col>
            </Row>
          </Card>

          {/* 设备状态 */}
          <Card title="📱 设备状态" size="small">
            <Progress
              percent={devicesTotal > 0 ? Math.round((devicesOnline / devicesTotal) * 100) : 0}
              status={devicesOnline === devicesTotal && devicesTotal > 0 ? 'success' : 'normal'}
              strokeColor={devicesOnline === devicesTotal && devicesTotal > 0 ? '#52c41a' : '#1677ff'}
              format={(p) => `${devicesOnline}/${devicesTotal}`}
            />
            <Row justify="space-around" style={{ marginTop: 8 }}>
              <Col><Text type="success">在线 {devicesOnline}</Text></Col>
              <Col><Text type="secondary">总计 {devicesTotal}</Text></Col>
            </Row>
          </Card>
        </Col>
      </Row>
    </div>
  );
}
