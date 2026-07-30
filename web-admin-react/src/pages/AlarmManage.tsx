import { useEffect, useState } from 'react';
import {
  Table, Card, Button, Tag, Space, Typography, message, Modal, Descriptions,
  Timeline, Row, Col, Popconfirm, Select, Input, Statistic, Alert, Badge,
} from 'antd';
import {
  AlertOutlined, PhoneOutlined, CheckCircleOutlined, ClockCircleOutlined,
  FireOutlined, WarningOutlined, ExclamationCircleOutlined, NotificationOutlined,
} from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';
import { alarmAPI } from '@/api';
import type { AlarmRecord } from '@/types';
import { useWSStore } from '@/store/wsStore';
import dayjs from 'dayjs';

const { Title, Text, Paragraph } = Typography;

const levelConfig: Record<string, { color: string; bg: string; icon: React.ReactNode; label: string }> = {
  P0: { color: '#ff4d4f', bg: '#fff2f0', icon: <FireOutlined />, label: 'P0-紧急' },
  P1: { color: '#fa8c16', bg: '#fff7e6', icon: <ExclamationCircleOutlined />, label: 'P1-严重' },
  P2: { color: '#faad14', bg: '#fffbe6', icon: <WarningOutlined />, label: 'P2-关注' },
  P3: { color: '#1890ff', bg: '#e6f7ff', icon: <AlertOutlined />, label: 'P3-提醒' },
};

const typeMap: Record<string, string> = {
  SOS: 'SOS求助', FALL: '跌倒检测', VITAL_ABNORMAL: '体征异常',
  SIGNIN_TIMEOUT: '签到超时', DEVICE_OFFLINE: '设备离线',
};

export default function AlarmManage() {
  const [data, setData] = useState<AlarmRecord[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [filterLevel, setFilterLevel] = useState<string>();
  const [filterStatus, setFilterStatus] = useState<string>();
  const [detailVisible, setDetailVisible] = useState(false);
  const [currentItem, setCurrentItem] = useState<AlarmRecord | null>(null);
  const [realtimeAlarm, setRealtimeAlarm] = useState<any | null>(null);
  // 存储通过 WebSocket 实时收到的报警（后端 API 可能还没写入数据库）
  const [realtimeRecords, setRealtimeRecords] = useState<AlarmRecord[]>([]);
  const pageSize = 8;

  // WebSocket 实时报警
  const { connected, lastAlarmData, resetNewAlarms } = useWSStore();

  // 将 WS 报警数据转换为 AlarmRecord 格式并插入列表
  const injectRealtimeAlarm = (wsData: any) => {
    const record: AlarmRecord = {
      id: wsData.alarm_id || `rt-${Date.now()}`,
      elderly_id: wsData.elderly_id || '',
      elderly_name: '', // 后端返回时补充
      device_sn: wsData.device_sn || '',
      alarm_type: wsData.alarm_type || 'UNKNOWN',
      level: wsData.level || wsData.severity || 'P1',
      status: 'pending' as const,
      description: wsData.description || '',
      triggered_at: wsData.triggered_at || new Date().toISOString(),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      handler_name: null,
      handler_id: null,
      location_lat: 0,
      location_lng: 0,
      vital_snapshot: undefined,
      handling_logs: [],
      _isRealtime: true as unknown as undefined, // 标记：这是实时推送的数据
    };
    setRealtimeRecords((prev) => {
      if (prev.some((r) => r.id === record.id)) return prev;
      return [record, ...prev];
    });
    setRealtimeAlarm(wsData);
    setTimeout(() => { setRealtimeAlarm(null); }, 8000);
  };

  const loadData = async (trigger?: string) => {
    setLoading(true);
    try {
      const res = await alarmAPI.getList({ page, page_size: pageSize, level: filterLevel, status: filterStatus });
      const raw = res?.data;
      const list = Array.isArray(raw) ? raw : (Array.isArray(raw?.data) ? raw.data : []);
      const tot = res?.total ?? 0;
      setData(list);
      setTotal(tot);
      // API 加载成功后，清理已被 DB 写入的实时记录（按 id 去重）
      setRealtimeRecords((prev) =>
        prev.filter((rr) => !list.some((db) => db.id === rr.id))
      );
    } catch (err) {
      console.error('[AlarmManage] Failed to load alarms:', err);
      message.error('加载报警列表失败');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadData('initial'); }, [page, filterLevel, filterStatus]);

  // 监听 WebSocket 新报警消息（通过 wsStore 的 lastAlarmData）
  useEffect(() => {
    if (lastAlarmData) {
      injectRealtimeAlarm(lastAlarmData);
      loadData('ws-lastAlarmData');
    }
  }, [lastAlarmData]);

  // 监听 ws:message 自定义事件
  useEffect(() => {
    const handleWSMessage = (event: CustomEvent) => {
      const msg = event.detail;
      if (msg.type === 'new_alarm') {
        injectRealtimeAlarm(msg.data);
        loadData('ws-customEvent');
      }
    };
    window.addEventListener('ws:message', handleWSMessage as EventListener);
    return () => window.removeEventListener('ws:message', handleWSMessage as EventListener);
  }, []);

  // 合并显示：API 数据 + 实时推送数据（去重）
  const mergedData = (() => {
    const dbIds = new Set(data.map((d) => d.id));
    const uniqueRT = realtimeRecords.filter((r) => !dbIds.has(r.id));
    return [...uniqueRT, ...data];
  })();

  const counts = {
    total: total + realtimeRecords.length,
    pending: mergedData.filter((a) => a.status === 'pending').length,
    p0: mergedData.filter((a) => a.level === 'P0' && a.status !== 'resolved').length,
  };

  const handleConfirm = async (id: string) => {
    try {
      await alarmAPI.confirm(id);
      message.success('报警已确认');
      loadData();
    } catch { message.error('确认失败'); }
  };
  const handleEscalate = async (id: string) => {
    try {
      await alarmAPI.escalate(id);
      message.warning('报警已升级为P0，正在联动120');
      loadData();
    } catch { message.error('升级失败'); }
  };
  const handleResolve = async (id: string) => {
    try {
      await alarmAPI.resolve(id);
      message.success('报警已解决');
      loadData();
    } catch { message.error('解决失败'); }
  };

  const columns: ColumnsType<AlarmRecord> = [
    {
      title: '级别', dataIndex: 'level', width: 90,
      render: (v: string, r) => {
        const c = levelConfig[v];
        // 实时推送的数据加闪烁标记
        return (
          <span>
            <Tag color={c?.color} icon={c?.icon}>{c?.label}</Tag>
            {(r as any)._isRealtime && (
              <Badge status="processing" style={{ marginLeft: 4 }} />
            )}
          </span>
        );
      },
    },
    { title: '老人', dataIndex: 'elderly_name', width: 90, render: (v: string) => v || <Text type="secondary">-</Text> },
    {
      title: '类型', dataIndex: 'alarm_type', width: 100,
      render: (v: string) => typeMap[v] || v,
    },
    { title: '描述', dataIndex: 'description', ellipsis: true },
    {
      title: '状态', dataIndex: 'status', width: 100,
      render: (v: string, r) => {
        const isRT = (r as any)._isRealtime;
        const map: Record<string, { color: string; text: string }> = {
          pending: { color: 'red', text: '待处理' },
          confirmed: { color: 'orange', text: '已确认' },
          processing: { color: 'blue', text: '处理中' },
          resolved: { color: 'green', text: '已解决' },
          escalated: { color: 'purple', text: '已升级' },
        };
        return (
          <span>
            <Tag color={map[v]?.color}>{map[v]?.text}</Tag>
            {isRT && <Tag color="blue" style={{ marginLeft: 4 }}>实时</Tag>}
          </span>
        );
      },
    },
    {
      title: '触发时间', dataIndex: 'triggered_at', width: 150,
      render: (v: string) => dayjs(v).format('MM-DD HH:mm:ss'),
    },
    { title: '处理人', dataIndex: 'handler_name', width: 90, render: (v: string | null) => v || <Text type="secondary">-</Text> },
    {
      title: '操作', width: 260, render: (_, r) => (
        <Space size={0}>
          <Button type="link" size="small" onClick={() => { setCurrentItem(r); setDetailVisible(true); }}>详情</Button>
          {r.status === 'pending' && (
            <>
              <Button type="link" size="small" style={{ color: '#fa8c16' }} onClick={() => handleConfirm(r.id)}>确认</Button>
              <Popconfirm title="确定升级为P0并联动120？" onConfirm={() => handleEscalate(r.id)}>
                <Button type="link" size="small" danger icon={<PhoneOutlined />}>🚑120联动</Button>
              </Popconfirm>
            </>
          )}
          {(r.status === 'confirmed' || r.status === 'processing') && (
            <>
              <Button type="link" size="small" style={{ color: '#52c41a' }} onClick={() => handleResolve(r.id)}>解决</Button>
              <Popconfirm title="确定升级为P0并联动120？" onConfirm={() => handleEscalate(r.id)}>
                <Button type="link" size="small" danger icon={<PhoneOutlined />}>🚑升级</Button>
              </Popconfirm>
            </>
          )}
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Title level={4}>报警管理</Title>

      {/* 实时报警通知横幅 */}
      {realtimeAlarm && (
        <Alert
          type="error"
          banner
          icon={<NotificationOutlined />}
          message={`🚨 新${realtimeAlarm.severity || 'P0'}级报警 - WebSocket 实时推送`}
          description={`设备 ${realtimeAlarm.device_sn || '-'} 触发 ${typeMap[realtimeAlarm.alarm_type] || realtimeAlarm.alarm_type || '未知'} 报警`}
          showIcon
          closable
          onClose={() => setRealtimeAlarm(null)}
          style={{ marginBottom: 16 }}
        />
      )}

      <Row gutter={16} style={{ marginBottom: 16 }}>
        <Col span={8}>
          <Card size="small" style={{ borderLeft: '4px solid #ff4d4f', background: counts.p0 > 0 ? '#fff2f0' : undefined }}>
            <Statistic title="P0活跃报警" value={counts.p0} prefix={<FireOutlined style={{ color: '#ff4d4f' }} />} />
          </Card>
        </Col>
        <Col span={8}>
          <Card size="small" style={{ borderLeft: '4px solid #fa8c16' }}>
            <Statistic title="待处理报警" value={counts.pending} prefix={<ClockCircleOutlined style={{ color: '#fa8c16' }} />} />
          </Card>
        </Col>
        <Col span={8}>
          <Card size="small" style={{ borderLeft: '4px solid #1677ff' }}>
            <Statistic title="总报警数" value={counts.total} prefix={<AlertOutlined />} />
          </Card>
        </Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Space>
          <Select allowClear placeholder="级别" value={filterLevel} onChange={(v) => { setFilterLevel(v); setPage(1); }}
            options={[{ value: 'P0', label: 'P0-紧急' }, { value: 'P1', label: 'P1-严重' }, { value: 'P2', label: 'P2-关注' }, { value: 'P3', label: 'P3-提醒' }]}
            style={{ width: 130 }}
          />
          <Select allowClear placeholder="状态" value={filterStatus} onChange={(v) => { setFilterStatus(v); setPage(1); }}
            options={[
              { value: 'pending', label: '待处理' }, { value: 'confirmed', label: '已确认' },
              { value: 'processing', label: '处理中' }, { value: 'resolved', label: '已解决' },
            ]}
            style={{ width: 120 }}
          />
        </Space>
      </Card>

      <Table
        dataSource={mergedData}
        columns={columns}
        rowKey="id"
        loading={loading}
        pagination={{ current: page, total: counts.total, pageSize, onChange: (p) => setPage(p) }}
        scroll={{ x: 1100 }}
        onRow={(r) => ({
          style: {
            background: (r as any)._isRealtime ? '#e6fffb' :
              (r.status === 'pending' && r.level === 'P0' ? '#fff2f0' : undefined),
          },
        })}
        summary={
          realtimeRecords.length > 0
            ? () => (
                <div style={{ textAlign: 'center', padding: '8px 0', color: '#1890ff', fontSize: 13 }}>
                  💡 表格顶部 {realtimeRecords.length} 条为 WebSocket 实时推送数据（后端数据库写入后将自动合并）
                </div>
              )
            : undefined
        }
      />

      {/* 详情弹窗 */}
      <Modal title="报警详情" open={detailVisible} onCancel={() => { setDetailVisible(false); setCurrentItem(null); }} footer={null} width={640}>
        {currentItem && (
          <>
            <Descriptions bordered column={2} size="small" style={{ marginBottom: 16 }}>
              <Descriptions.Item label="报警级别">
                <Tag color={levelConfig[currentItem.level]?.color}>{levelConfig[currentItem.level]?.label}</Tag>
              </Descriptions.Item>
              <Descriptions.Item label="报警类型">{typeMap[currentItem.alarm_type]}</Descriptions.Item>
              <Descriptions.Item label="老人">{currentItem.elderly_name || '-'}</Descriptions.Item>
              <Descriptions.Item label="设备SN">{currentItem.device_sn || '-'}</Descriptions.Item>
              <Descriptions.Item label="状态">
                <Tag>{currentItem.status === 'pending' ? '待处理' : currentItem.status === 'confirmed' ? '已确认' : currentItem.status}</Tag>
                {(currentItem as any)._isRealtime && <Tag color="blue" style={{ marginLeft: 8 }}>实时推送</Tag>}
              </Descriptions.Item>
              <Descriptions.Item label="触发时间">
                {dayjs(currentItem.triggered_at).format('YYYY-MM-DD HH:mm:ss')}
                {(currentItem as any)._isRealtime && <Text type="secondary" style={{ display: 'block', fontSize: 12 }}>(WebSocket 推送时间)</Text>}
              </Descriptions.Item>
              <Descriptions.Item label="处理人">{currentItem.handler_name || '-'}</Descriptions.Item>
              <Descriptions.Item label="描述" span={2}>{currentItem.description || '-'}</Descriptions.Item>
            </Descriptions>

            {currentItem.vital_snapshot && (
              <Card title="📊 报警时体征快照" size="small" style={{ marginBottom: 16 }}>
                <Space size={16}>
                  <Statistic title="心率" value={currentItem.vital_snapshot.heart_rate} suffix="bpm" valueStyle={{ color: currentItem.vital_snapshot.heart_rate > 100 || currentItem.vital_snapshot.heart_rate < 50 ? '#ff4d4f' : '#52c41a' }} />
                  <Statistic title="血氧" value={currentItem.vital_snapshot.blood_oxygen} suffix="%" valueStyle={{ color: currentItem.vital_snapshot.blood_oxygen < 93 ? '#ff4d4f' : '#52c41a' }} />
                  <Statistic title="体温" value={currentItem.vital_snapshot.temperature} suffix="℃" />
                  <Statistic title="血压" value={`${currentItem.vital_snapshot.systolic_bp}/${currentItem.vital_snapshot.diastolic_bp}`} suffix="mmHg" valueStyle={{ color: currentItem.vital_snapshot.systolic_bp > 140 ? '#ff4d4f' : '#52c41a' }} />
                </Space>
              </Card>
            )}

            {Array.isArray(currentItem.handling_logs) && currentItem.handling_logs.length > 0 && (
              <Card title="📋 处理记录" size="small">
                <Timeline
                  items={currentItem.handling_logs.map((log: any) => ({
                    children: (
                      <div>
                        <Text strong>{log.handler_name}</Text>
                        <Tag style={{ marginLeft: 8 }}>{log.action}</Tag>
                        <br />
                        <Text type="secondary">{log.comment}</Text>
                        <br />
                        <Text type="secondary" style={{ fontSize: 12 }}>{dayjs(log.created_at).format('YYYY-MM-DD HH:mm:ss')}</Text>
                      </div>
                    ),
                  }))}
                />
              </Card>
            )}
          </>
        )}
      </Modal>
    </div>
  );
}
