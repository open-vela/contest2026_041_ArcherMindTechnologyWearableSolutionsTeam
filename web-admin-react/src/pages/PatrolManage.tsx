import { useEffect, useState } from 'react';
import { Table, Card, Button, Tag, Space, Typography, message, Modal, Form, Select, Input, DatePicker, Row, Col, Statistic } from 'antd';
import { PlusOutlined, EnvironmentOutlined } from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';
import { patrolAPI, elderlyAPI } from '@/api';
import type { PatrolTask } from '@/types';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

export default function PatrolManage() {
  const [data, setData] = useState<PatrolTask[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [createVisible, setCreateVisible] = useState(false);
  const [elderlyOptions, setElderlyOptions] = useState<{ value: string; label: string }[]>([]);
  const [form] = Form.useForm();
  const pageSize = 8;

  const loadData = async () => {
    setLoading(true);
    try {
      const res = await patrolAPI.getTasks({ page, page_size: pageSize });
      // 后端 SuccessPage 返回 {code, message, data, total, page, page_size}
      // res = axios response data = {code, message, data, total, ...}
      const raw = res?.data;
      const list: PatrolTask[] = Array.isArray(raw) ? raw : (Array.isArray(raw?.data) ? raw.data : []);
      const tot = res?.total ?? 0;
      // 映射后端字段名到前端字段名
      const mapped = list.map((item: any) => ({
        ...item,
        assigned_name: item.assigned_to_name || item.assigned_name || '',
        description: item.note || item.description || '',
        elderly_name: item.elderly_name || '',
      }));
      setData(mapped);
      setTotal(tot);
    } catch (err) {
      console.error('[PatrolManage] Failed to load:', err);
      message.error('加载巡访任务失败');
    } finally {
      setLoading(false);
    }
  };

  const loadElderlyOptions = async () => {
    try {
      const res = await elderlyAPI.getList({ page: 1, page_size: 100 });
      const raw = res?.data;
      const list = Array.isArray(raw) ? raw : (Array.isArray(raw?.data) ? raw.data : []);
      setElderlyOptions(list.map((e: any) => ({
        value: e.id,
        label: e.name || e.real_name || e.elderly_name || '未知',
      })));
    } catch (err) {
      console.error('[PatrolManage] Failed to load elderly list:', err);
    }
  };

  useEffect(() => { loadData(); }, [page]);
  useEffect(() => { loadElderlyOptions(); }, []);

  const columns: ColumnsType<PatrolTask> = [
    {
      title: '优先级', dataIndex: 'priority', width: 80,
      render: (v: string) => {
        const map: Record<string, { color: string; text: string }> = {
          urgent: { color: 'red', text: '紧急' },
          normal: { color: 'orange', text: '常规' },
          regular: { color: 'blue', text: '定期' },
        };
        return <Tag color={map[v]?.color}>{map[v]?.text || v}</Tag>;
      },
    },
    { title: '老人', dataIndex: 'elderly_name', width: 90 },
    { title: '任务类型', dataIndex: 'task_type', width: 100 },
    { title: '描述', dataIndex: 'description', ellipsis: true },
    { title: '指派给', dataIndex: 'assigned_name', width: 100, render: (v: string) => v || <Text type="secondary">未指派</Text> },
    {
      title: '状态', dataIndex: 'status', width: 80,
      render: (v: string) => {
        const map: Record<string, { color: string; text: string }> = {
          pending: { color: 'default', text: '待接单' },
          accepted: { color: 'blue', text: '已接单' },
          assigned: { color: 'blue', text: '已指派' },
          completed: { color: 'green', text: '已完成' },
          cancelled: { color: 'default', text: '已取消' },
        };
        return <Tag color={map[v]?.color}>{map[v]?.text || v}</Tag>;
      },
    },
    { title: '计划日期', dataIndex: 'scheduled_date', width: 110 },
    {
      title: '完成时间', dataIndex: 'completed_at', width: 130,
      render: (v: string | null) => v ? dayjs(v).format('MM-DD HH:mm') : '-',
    },
    {
      title: '操作', width: 140, render: (_, r) => (
        <Space size={0}>
          {r.status === 'pending' && (
            <Button type="link" size="small" onClick={async () => { await patrolAPI.assignTask(r.id, 's001'); message.success('已指派'); loadData(); }}>
              指派
            </Button>
          )}
          {r.status === 'accepted' && (
            <Button type="link" size="small" style={{ color: '#52c41a' }} onClick={() => message.success('巡访记录已提交')}>
              提交记录
            </Button>
          )}
        </Space>
      ),
    },
  ];

  const stats = {
    pending: data.filter((t) => t.status === 'pending').length,
    accepted: data.filter((t) => t.status === 'accepted' || t.status === 'assigned').length,
    completed: data.filter((t) => t.status === 'completed').length,
    urgent: data.filter((t) => t.priority === 'urgent' && t.status !== 'completed').length,
  };

  const handleCreate = async (values: Record<string, unknown>) => {
    try {
      // 后端期望: elderly_id(必填), task_type(必填), priority, scheduled_date, note
      await patrolAPI.createTask({
        elderly_id: values.elderly_id as string,
        task_type: values.task_type as string,
        note: values.note as string,
        priority: values.priority as 'urgent' | 'normal' | 'regular',
        scheduled_date: (values.scheduled_date as dayjs.Dayjs)?.format('YYYY-MM-DD'),
      });
      message.success('巡访任务已创建');
      setCreateVisible(false);
      form.resetFields();
      loadData();
    } catch (e) {
      console.error('[PatrolManage] Create failed:', e);
      message.error('创建失败');
    }
  };

  return (
    <div>
      <Title level={4}>巡访管理</Title>

      <Row gutter={16} style={{ marginBottom: 16 }}>
        <Col span={6}><Card size="small"><Statistic title="待接单" value={stats.pending} valueStyle={{ color: stats.pending > 0 ? '#fa8c16' : undefined }} /></Card></Col>
        <Col span={6}><Card size="small"><Statistic title="进行中" value={stats.accepted} valueStyle={{ color: '#1677ff' }} /></Card></Col>
        <Col span={6}><Card size="small"><Statistic title="已完成" value={stats.completed} valueStyle={{ color: '#52c41a' }} /></Card></Col>
        <Col span={6}><Card size="small" style={{ background: stats.urgent > 0 ? '#fff2f0' : undefined }}>
          <Statistic title="紧急待办" value={stats.urgent} valueStyle={{ color: stats.urgent > 0 ? '#ff4d4f' : '#52c41a' }} />
        </Card></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Button type="primary" icon={<PlusOutlined />} onClick={() => setCreateVisible(true)}>新建巡访任务</Button>
      </Card>

      <Table dataSource={data} columns={columns} rowKey="id" loading={loading}
        pagination={{ current: page, total, pageSize, onChange: (p) => setPage(p) }} />

      <Modal title="新建巡访任务" open={createVisible} onCancel={() => { setCreateVisible(false); form.resetFields(); }} onOk={() => form.submit()} width={500}>
        <Form form={form} layout="vertical" onFinish={handleCreate}>
          <Form.Item name="elderly_id" label="老人" rules={[{ required: true, message: '请选择老人' }]}>
            <Select options={elderlyOptions} placeholder="请选择老人" showSearch optionFilterProp="label" />
          </Form.Item>
          <Form.Item name="task_type" label="任务类型" rules={[{ required: true, message: '请选择任务类型' }]}>
            <Select options={[
              { value: '健康检查', label: '健康检查' }, { value: '跌倒排查', label: '跌倒排查' },
              { value: '设备排查', label: '设备排查' }, { value: '定期探访', label: '定期探访' },
              { value: '用药指导', label: '用药指导' },
            ]} />
          </Form.Item>
          <Form.Item name="priority" label="优先级" rules={[{ required: true, message: '请选择优先级' }]}>
            <Select options={[
              { value: 'urgent', label: '紧急' }, { value: 'normal', label: '常规' }, { value: 'regular', label: '定期' },
            ]} />
          </Form.Item>
          <Form.Item name="scheduled_date" label="计划日期" rules={[{ required: true, message: '请选择计划日期' }]}>
            <DatePicker style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item name="note" label="任务描述">
            <Input.TextArea rows={3} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
