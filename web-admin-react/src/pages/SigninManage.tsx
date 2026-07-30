import { useEffect, useState } from 'react';
import { Table, Card, Button, Tag, Space, Typography, message, Row, Col, Statistic, Progress, Popconfirm } from 'antd';
import { CheckCircleOutlined, ClockCircleOutlined, WarningOutlined, UserSwitchOutlined, CalendarOutlined } from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';
import { signinAPI } from '@/api';
import type { SigninRecord } from '@/types';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

export default function SigninManage() {
  const [data, setData] = useState<SigninRecord[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [overview, setOverview] = useState({ signed: 0, unsigned: 0, timeout: 0, total: 0, rate: 0 });
  const pageSize = 8;

  const loadData = async () => {
    setLoading(true);
    try {
      const [res, ov] = await Promise.all([
        signinAPI.getList({ page, page_size: pageSize }),
        signinAPI.getCommunityOverview(),
      ]);
      const raw = res?.data;
      const list = Array.isArray(raw) ? raw : (Array.isArray(raw?.data) ? raw.data : []);
      const tot = res?.total ?? 0;
      setData(list);
      setTotal(tot);
      if (ov?.data) setOverview(ov.data);
    } catch (err) {
      console.error('[SigninManage] Failed to load:', err);
      message.error('加载签到列表失败');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadData(); }, [page]);

  const handleProxy = async (elderlyId: string) => {
    try {
      await signinAPI.proxySignin(elderlyId);
      message.success('代签成功');
      loadData();
    } catch { message.error('代签失败'); }
  };

  const columns: ColumnsType<SigninRecord> = [
    { title: '老人', dataIndex: 'elderly_name', width: 100 },
    { title: '日期', dataIndex: 'signin_date', width: 110 },
    {
      title: '签到时间', dataIndex: 'signin_time', width: 130,
      render: (v: string | null) => v ? dayjs(v).format('HH:mm:ss') : <Text type="secondary">-</Text>,
    },
    {
      title: '方式', dataIndex: 'method', width: 90,
      render: (v: string | null) => {
        if (!v) return <Text type="secondary">-</Text>;
        const map: Record<string, { color: string; text: string }> = {
          touch: { color: 'blue', text: '触摸' }, voice: { color: 'green', text: '语音' },
          gesture: { color: 'purple', text: '抬腕' }, auto: { color: 'cyan', text: '自动' },
          proxy: { color: 'orange', text: '代签' },
          watch: { color: 'cyan', text: '手表' }, face: { color: 'magenta', text: '人脸' },
          phone: { color: 'geekblue', text: '电话' },
        };
        return <Tag color={map[v]?.color}>{map[v]?.text}</Tag>;
      },
    },
    {
      title: '状态', dataIndex: 'status', width: 80,
      render: (v: string) => {
        if (v === 'signed') return <Tag color="green" icon={<CheckCircleOutlined />}>已签</Tag>;
        if (v === 'unsigned') return <Tag color="orange" icon={<ClockCircleOutlined />}>未签</Tag>;
        return <Tag color="red" icon={<WarningOutlined />}>超时</Tag>;
      },
    },
    {
      title: '提醒次数', dataIndex: 'check_levels', width: 90,
      render: (v: number) => v > 0 ? <Text type="warning">{v} 次</Text> : <Text type="secondary">0</Text>,
    },
    {
      title: '代签人', dataIndex: 'proxy_by', width: 90,
      render: (v: string | null) => v || <Text type="secondary">-</Text>,
    },
    {
      title: '操作', width: 80,
      render: (_, r) => (
        r.status !== 'signed' ? (
          <Popconfirm title="确定代签？" onConfirm={() => handleProxy(r.elderly_id)}>
            <Button type="link" size="small" icon={<UserSwitchOutlined />}>代签</Button>
          </Popconfirm>
        ) : null
      ),
    },
  ];

  return (
    <div>
      <Title level={4}>签到管理</Title>

      <Row gutter={16} style={{ marginBottom: 16 }}>
        <Col span={6}>
          <Card size="small" style={{ borderLeft: '4px solid #1677ff' }}>
            <Statistic title="总人数" value={overview.total} prefix={<CalendarOutlined />} />
          </Card>
        </Col>
        <Col span={6}>
          <Card size="small" style={{ borderLeft: '4px solid #52c41a' }}>
            <Statistic title="已签到" value={overview.signed} valueStyle={{ color: '#52c41a' }} prefix={<CheckCircleOutlined />} />
          </Card>
        </Col>
        <Col span={6}>
          <Card size="small" style={{ borderLeft: '4px solid #fa8c16' }}>
            <Statistic title="未签到" value={overview.unsigned} valueStyle={{ color: '#fa8c16' }} prefix={<ClockCircleOutlined />} />
          </Card>
        </Col>
        <Col span={6}>
          <Card size="small" style={{ borderLeft: '4px solid #ff4d4f' }}>
            <Statistic title="超时" value={overview.timeout} valueStyle={{ color: '#ff4d4f' }} prefix={<WarningOutlined />} />
          </Card>
        </Col>
      </Row>

      <Row gutter={16} style={{ marginBottom: 16 }}>
        <Col span={24}>
          <Card size="small">
            <Space>
              <Text>今日签到率：</Text>
              <Progress
                type="circle"
                percent={overview.rate}
                size={60}
                status={overview.rate >= 100 ? 'success' : overview.rate >= 60 ? 'active' : 'exception'}
              />
              <Text type="secondary">
                （{overview.signed} / {overview.total}）签到窗口 08:00 - 10:00
              </Text>
            </Space>
          </Card>
        </Col>
      </Row>

      <Table dataSource={data} columns={columns} rowKey="id" loading={loading}
        pagination={{ current: page, total, pageSize, onChange: (p) => setPage(p) }}
        onRow={(r) => ({
          style: { background: r.status === 'timeout' ? '#fff2f0' : r.status === 'unsigned' ? '#fffbe6' : undefined },
        })}
      />
    </div>
  );
}
