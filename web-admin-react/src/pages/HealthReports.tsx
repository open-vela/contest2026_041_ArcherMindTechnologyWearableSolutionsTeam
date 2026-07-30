import { useEffect, useState } from 'react';
import { Table, Card, Button, Tag, Space, Typography, message, Modal, Descriptions, Statistic, Row, Col, Progress, List } from 'antd';
import { FileTextOutlined, RobotOutlined, ReloadOutlined, ArrowUpOutlined, ArrowDownOutlined, MinusOutlined } from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';
import { reportAPI } from '@/api';
import type { HealthReport } from '@/types';
import dayjs from 'dayjs';

const { Title, Text, Paragraph } = Typography;

const directionIcon = (d: string) => {
  if (d === 'up') return <ArrowUpOutlined style={{ color: '#ff4d4f' }} />;
  if (d === 'down') return <ArrowDownOutlined style={{ color: '#52c41a' }} />;
  return <MinusOutlined />;
};

export default function HealthReports() {
  const [data, setData] = useState<HealthReport[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [detailVisible, setDetailVisible] = useState(false);
  const [currentItem, setCurrentItem] = useState<HealthReport | null>(null);
  const [generating, setGenerating] = useState(false);
  const pageSize = 6;

  const loadData = async () => {
    setLoading(true);
    try {
      const res = await reportAPI.getList({ page, page_size: pageSize });
      const raw = res?.data;
      const list = Array.isArray(raw) ? raw : (Array.isArray(raw?.data) ? raw.data : []);
      const tot = res?.total ?? 0;
      setData(list);
      setTotal(tot);
    } catch (err) {
      console.error('[HealthReports] Failed to load:', err);
      message.error('加载健康周报失败');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadData(); }, [page]);

  const handleGenerate = async () => {
    setGenerating(true);
    try {
      await reportAPI.generate('e001', dayjs().format('YYYY-W01'));
      message.success('AI健康周报已生成');
      loadData();
    } catch (e) {
      console.error('[HealthReports] Generate failed:', e);
      message.error('生成失败');
    } finally {
      setGenerating(false);
    }
  };

  const columns: ColumnsType<HealthReport> = [
    { title: '老人', dataIndex: 'elderly_name', width: 90 },
    { title: '周次', dataIndex: 'report_week', width: 90 },
    {
      title: '健康评分', dataIndex: 'health_score', width: 100,
      render: (v: number) => (
        <Progress type="circle" percent={v} size={36} strokeColor={v >= 80 ? '#52c41a' : v >= 60 ? '#faad14' : '#ff4d4f'} />
      ),
    },
    { title: '平均心率', dataIndex: 'avg_heart_rate', width: 80, render: (v: number) => `${v} bpm` },
    { title: '平均血氧', dataIndex: 'avg_blood_oxygen', width: 80, render: (v: number) => `${v}%` },
    { title: '总步数', dataIndex: 'total_steps', width: 90, render: (v: number) => v.toLocaleString() },
    { title: '报警次数', dataIndex: 'alarm_count', width: 80, render: (v: number) => v > 0 ? <Tag color="red">{v}</Tag> : <Tag color="green">0</Tag> },
    { title: '签到天数', dataIndex: 'signin_days', width: 80, render: (v: number) => `${v}/7` },
    {
      title: '状态', dataIndex: 'status', width: 80,
      render: (v: string) => v === 'published' ? <Tag color="blue">已发布</Tag> : <Tag>草稿</Tag>,
    },
    { title: '生成时间', dataIndex: 'created_at', width: 130, render: (v: string) => dayjs(v).format('MM-DD HH:mm') },
    {
      title: '操作', width: 80, render: (_, r) => (
        <Button type="link" size="small" onClick={() => { setCurrentItem(r); setDetailVisible(true); }}>
          详情
        </Button>
      ),
    },
  ];

  return (
    <div>
      <Title level={4}>健康周报</Title>

      <Card style={{ marginBottom: 16 }}>
        <Space>
          <Button type="primary" icon={<RobotOutlined />} loading={generating} onClick={handleGenerate}>
            AI 生成周报
          </Button>
          <Text type="secondary">基于本周体征数据，AI自动生成健康评估和建议</Text>
        </Space>
      </Card>

      <Table dataSource={data} columns={columns} rowKey="id" loading={loading}
        pagination={{ current: page, total, pageSize, onChange: (p) => setPage(p) }} />

      {/* 周报详情弹窗 */}
      <Modal title="健康周报详情" open={detailVisible} onCancel={() => { setDetailVisible(false); setCurrentItem(null); }} footer={null} width={720}>
        {currentItem && (
          <>
            <Row gutter={16} style={{ marginBottom: 16 }}>
              <Col span={8}><Statistic title="健康评分" value={currentItem.health_score} suffix="分" valueStyle={{ color: currentItem.health_score >= 80 ? '#52c41a' : currentItem.health_score >= 60 ? '#faad14' : '#ff4d4f', fontSize: 36 }} /></Col>
              <Col span={4}><Statistic title="心率" value={currentItem.avg_heart_rate} suffix="bpm" /></Col>
              <Col span={4}><Statistic title="血氧" value={currentItem.avg_blood_oxygen} suffix="%" /></Col>
              <Col span={4}><Statistic title="体温" value={currentItem.avg_temperature} suffix="℃" /></Col>
              <Col span={4}><Statistic title="步数" value={currentItem.total_steps} /></Col>
            </Row>

            {/* 趋势 */}
            <Card title="📈 本周趋势" size="small" style={{ marginBottom: 16 }}>
              {(currentItem.trends && currentItem.trends.length > 0)
                ? currentItem.trends.map((t, i) => (
                    <Tag key={i} icon={directionIcon(t.direction)}>
                      {t.metric}: {t.change}
                    </Tag>
                  ))
                : <Text type="secondary">暂无趋势数据</Text>}
            </Card>

            {/* AI 小结 */}
            <Card title="🤖 AI 健康小结" size="small" style={{ marginBottom: 16 }}>
              <Paragraph>{currentItem.ai_summary}</Paragraph>
            </Card>

            {/* AI 建议 */}
            <Card title="💡 AI 建议" size="small">
              <List
                size="small"
                dataSource={currentItem.ai_suggestions ?? []}
                renderItem={(item) => <List.Item>{item}</List.Item>}
                locale={{ emptyText: '暂无建议' }}
              />
            </Card>

            <Descriptions size="small" style={{ marginTop: 16 }}>
              <Descriptions.Item label="生成者">{currentItem.generated_by}</Descriptions.Item>
              <Descriptions.Item label="生成时间">{dayjs(currentItem.created_at).format('YYYY-MM-DD HH:mm')}</Descriptions.Item>
            </Descriptions>
          </>
        )}
      </Modal>
    </div>
  );
}
