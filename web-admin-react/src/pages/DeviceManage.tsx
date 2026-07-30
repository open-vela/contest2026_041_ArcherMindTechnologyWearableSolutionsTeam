import { useEffect, useState, useRef, useCallback } from 'react';
import { Table, Card, Button, Input, Select, Tag, Space, Typography, Progress, message, Modal, Descriptions, Row, Col, Statistic, Tooltip } from 'antd';
import { ReloadOutlined, ApiOutlined, WarningOutlined, WifiOutlined } from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';
import { deviceAPI } from '@/api';  // ← 使用真实 API
import type { Device } from '@/types';
import { useWSStore } from '@/store/wsStore';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

// ===== 版本标记：部署后 Console 应显示 v20260630-2230 =====
console.log('[DeviceManage] === VERSION: v20260630-2230 (new-device-reload) ===');

export default function DeviceManage() {
  const [data, setData] = useState<Device[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [status, setStatus] = useState<string>();
  const [detailVisible, setDetailVisible] = useState(false);
  const [currentItem, setCurrentItem] = useState<Device | null>(null);
  const pageSize = 8;

  // WebSocket 实时数据
  const { connected, deviceOnline } = useWSStore();
  const refreshTimerRef = useRef<number | null>(null);

  // 从真实 API 加载数据
  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const res = await deviceAPI.getList({ page, page_size: pageSize, status });
      console.log('[DeviceManage] API response:', JSON.stringify(res));
      // 兼容两种响应格式：
      //   格式A（后端实际返回）: { code, data: [...], total, page }
      //   格式B（前端预期）:    { code, data: { list: [...], total } }
      const raw = res?.data;
      const list = Array.isArray(raw) ? raw : (Array.isArray(raw?.data) ? raw.data : []);
      const tot = res?.total ?? 0;
      console.log('[DeviceManage] list:', list.length, 'items, total:', tot);
      setData(list);
      setTotal(tot);
    } catch (err) {
      console.error('[DeviceManage] Failed to load devices:', err);
      message.error('加载设备列表失败');
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, status]);

  useEffect(() => { loadData(); }, [loadData]);

  // 监听 WebSocket 消息，本地即时更新（无需重新请求 API）
  useEffect(() => {
    console.log('[DeviceManage] === 注册 ws:message 监听器 ===');

    const handleWSMessage = (event: Event) => {
      console.log('[DeviceManage] ★★★ 收到自定义事件! event type:', event.type);
      const customEvent = event as CustomEvent;
      console.log('[DeviceManage] ★★★ event.detail:', customEvent.detail);

      const msg = customEvent.detail;
      if (!msg) {
        console.warn('[DeviceManage] ★★★ msg 为空，跳过');
        return;
      }

      console.log('[DeviceManage] WS raw message:', JSON.stringify(msg), 'type:', msg?.type);

      if (msg.type === 'device_online' || msg.type === 'heartbeat') {
        const wsData = msg.data;
        console.log('[DeviceManage] wsData:', JSON.stringify(wsData), 'device_sn:', wsData?.device_sn);
        if (!wsData?.device_sn) {
          console.warn('[DeviceManage] missing device_sn, skipping');
          return;
        }

        console.log('[DeviceManage]', msg.type, 'event received:', wsData);

        // 策略：先尝试本地更新已知设备，如果设备不在当前列表则重新加载
        let found = false;
        setData((prev) => {
          const exists = prev.some((item) => item.device_sn === wsData.device_sn);
          if (!exists) {
            // 新设备不在当前列表中 → 标记需要 reload
            found = false;
            return prev;  // 不修改，等下面触发 loadData
          }
          found = true;
          // 已知设备 → 本地即时更新
          return prev.map((item) => {
            if (item.device_sn === wsData.device_sn) {
              return {
                ...item,
                status: 'online' as const,
                last_heartbeat_at: wsData.timestamp
                  ? new Date(wsData.timestamp * 1000).toISOString()  // Unix 时间戳转换
                  : new Date().toISOString(),
                battery_level: wsData.battery ?? item.battery_level,
                signal_strength: wsData.signal_strength ?? item.signal_strength,
              };
            }
            return item;
          });
        });

        // 新设备上线 → 重新加载列表以获取完整数据
        if (!found) {
          console.log('[DeviceManage] New device online, reloading list:', wsData.device_sn);
          loadData();
        }
      }
    };

    window.addEventListener('ws:message', handleWSMessage as EventListener);

    // 调试：记录监听器注册情况
    (window as any).__debug_ws_listeners = ((window as any).__debug_ws_listeners || 0) + 1;
    console.log('[DeviceManage] 监听器已注册，累计:', (window as any).__debug_ws_listeners);

    return () => {
      window.removeEventListener('ws:message', handleWSMessage as EventListener);
      (window as any).__debug_ws_listeners = ((window as any).__debug_ws_listeners || 1) - 1;
      console.log('[DeviceManage] 监听器已移除，剩余:', (window as any).__debug_ws_listeners);
    };
  }, []);

  const statusMap: Record<string, { color: string; text: string }> = {
    online: { color: 'green', text: '在线' },
    offline: { color: 'default', text: '离线' },
    sleep: { color: 'blue', text: '休眠' },
    alarming: { color: 'red', text: '报警中' },
  };

  const columns: ColumnsType<Device> = [
    { title: '设备SN', dataIndex: 'device_sn', width: 180 },
    { title: '型号', dataIndex: 'model', width: 90,
      render: (_: string, r: Device) => r.model || r.device_type || '—',
    },
    { title: '绑定老人', dataIndex: 'elderly_name', width: 90 },
    { title: '固件版本', dataIndex: 'firmware_version', width: 100 },
    {
      title: '电量', dataIndex: 'battery', width: 100,
      render: (_: number, r: Device) => {
        const batt = r.battery_level ?? (r as any).battery ?? 0;
        return (
          <Progress percent={batt} size="small"
            strokeColor={batt > 60 ? '#52c41a' : batt > 20 ? '#faad14' : '#ff4d4f'}
            format={(p) => `${p}%`}
          />
        );
      },
    },
    {
      title: '信号', dataIndex: 'signal_strength', width: 70,
      render: (v: number) => {
        if (v == null || v <= 0) return <Text type="secondary">无信号</Text>;
        const level = Math.min(v, 5);
        const colors = ['#ff4d4f', '#ff4d4f', '#faad14', '#52c41a', '#52c41a', '#52c41a'];
        return (
          <Tooltip title={`信号强度 ${level}/5`}>
            <span style={{ color: colors[level], fontSize: 16 }}>📶</span>
            <Text type="secondary" style={{ fontSize: 12, marginLeft: 4 }}>{level}格</Text>
          </Tooltip>
        );
      },
    },
    {
      title: '状态', dataIndex: 'status', width: 100,
      render: (v: string, r: Device) => {
        // 优先使用 WebSocket 实时状态
        const wsOnline = (deviceOnline ?? {})[r.device_sn];
        const displayStatus = wsOnline !== undefined ? (wsOnline ? 'online' : v) : v;
        const statusInfo = statusMap[displayStatus] || statusMap[v];
        return (
          <Tooltip title={connected ? '实时状态' : '静态数据'}>
            <Tag color={statusInfo?.color} icon={wsOnline ? <WifiOutlined /> : undefined}>
              {statusInfo?.text}
              {wsOnline && connected ? '' : ''}
            </Tag>
          </Tooltip>
        );
      },
    },
    {
      title: '最后心跳', dataIndex: 'last_heartbeat_at', width: 140,
      render: (v: string) => <Text type="secondary">{dayjs(v).format('MM-DD HH:mm:ss')}</Text>,
    },
    {
      title: '操作', width: 160, render: (_, r) => (
        <Space size={0}>
          <Button type="link" size="small" onClick={() => { setCurrentItem(r); setDetailVisible(true); }}>详情</Button>
          <Button type="link" size="small" onClick={() => message.success('OTA升级指令已下发')}>OTA</Button>
          <Button type="link" size="small" danger onClick={() => message.success('重启指令已下发')}>重启</Button>
        </Space>
      ),
    },
  ];

  const summary = {
    total: total ?? 0,
    online: connected
      ? Object.values(deviceOnline ?? {}).filter(Boolean).length || (data ?? []).filter((d) => d.status === 'online').length
      : (data ?? []).filter((d) => d.status === 'online').length,
    offline: (data ?? []).filter((d) => d.status === 'offline').length,
    alarming: (data ?? []).filter((d) => d.status === 'alarming').length,
  };

  return (
    <div>
      <Title level={4}>设备管理</Title>

      <Row gutter={16} style={{ marginBottom: 16 }}>
        <Col span={6}><Card size="small"><Statistic title="设备总数" value={summary.total} prefix={<ApiOutlined />} /></Card></Col>
        <Col span={6}><Card size="small"><Statistic title="在线" value={summary.online} valueStyle={{ color: '#52c41a' }} /></Card></Col>
        <Col span={6}><Card size="small"><Statistic title="离线" value={summary.offline} valueStyle={{ color: '#8c8c8c' }} /></Card></Col>
        <Col span={6}><Card size="small"><Statistic title="报警中" value={summary.alarming} valueStyle={{ color: '#ff4d4f' }} prefix={<WarningOutlined />} /></Card></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Row gutter={16} align="middle">
          <Col flex="auto">
            <Select
              allowClear placeholder="状态筛选" value={status} onChange={(v) => { setStatus(v); setPage(1); }}
              options={[
                { value: 'online', label: '在线' }, { value: 'offline', label: '离线' },
                { value: 'sleep', label: '休眠' }, { value: 'alarming', label: '报警中' },
              ]}
              style={{ width: 150 }}
            />
          </Col>
          <Col><Button icon={<ReloadOutlined />} onClick={loadData}>刷新</Button></Col>
        </Row>
      </Card>

      <Table dataSource={data} columns={columns} rowKey="id" loading={loading}
        pagination={{ current: page, total, pageSize, onChange: (p) => setPage(p) }} />

      <Modal title="设备详情" open={detailVisible} onCancel={() => { setDetailVisible(false); setCurrentItem(null); }} footer={null} width={560}>
        {currentItem && (
          <Descriptions bordered column={2} size="small">
            <Descriptions.Item label="设备SN">{currentItem.device_sn}</Descriptions.Item>
            <Descriptions.Item label="设备名称">{currentItem.device_name}</Descriptions.Item>
            <Descriptions.Item label="型号">{currentItem.model}</Descriptions.Item>
            <Descriptions.Item label="固件">{currentItem.firmware_version}</Descriptions.Item>
            <Descriptions.Item label="绑定老人">{currentItem.elderly_name}</Descriptions.Item>
            <Descriptions.Item label="状态"><Tag color={statusMap[currentItem.status]?.color}>{statusMap[currentItem.status]?.text}</Tag></Descriptions.Item>
            <Descriptions.Item label="电量">{
              (currentItem.battery_level != null || (currentItem as any).battery != null)
                ? `${currentItem.battery_level ?? (currentItem as any).battery ?? 0}%`
                : '未知'
            }</Descriptions.Item>
            <Descriptions.Item label="信号">{
              (currentItem.signal_strength != null || (currentItem as any).signal_strength != null)
                ? `${currentItem.signal_strength ?? (currentItem as any).signal_strength ?? 0} 格`
                : '未知'
            }</Descriptions.Item>
            <Descriptions.Item label="SIM卡">{currentItem.sim_iccid}</Descriptions.Item>
            <Descriptions.Item label="激活时间">{dayjs(currentItem.activated_at).format('YYYY-MM-DD HH:mm')}</Descriptions.Item>
            <Descriptions.Item label="最后心跳">{dayjs(currentItem.last_heartbeat_at).format('YYYY-MM-DD HH:mm:ss')}</Descriptions.Item>
            <Descriptions.Item label="位置">
              {currentItem.location_lat != null && currentItem.location_lng != null
                ? `${Number(currentItem.location_lat).toFixed(4)}, ${Number(currentItem.location_lng).toFixed(4)}`
                : '暂无定位数据'}
            </Descriptions.Item>
          </Descriptions>
        )}
      </Modal>
    </div>
  );
}
