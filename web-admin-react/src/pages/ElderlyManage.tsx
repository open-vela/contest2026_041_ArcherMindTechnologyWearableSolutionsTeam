import { useEffect, useState } from 'react';
import {
  Table, Card, Button, Input, Select, Modal, Form, Tag, Space, Descriptions, Row, Col,
  Typography, message, Popconfirm, InputNumber, Alert,
} from 'antd';
import { PlusOutlined, SearchOutlined, EditOutlined, DeleteOutlined, EyeOutlined, SwapOutlined } from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';
import { elderlyAPI, deviceAPI } from '@/api';
import type { ElderlyProfile, Device } from '@/types';

const { Title, Text } = Typography;

// 前端展示用的扩展类型（包含后端返回的额外字段）
interface ElderlyDisplay extends ElderlyProfile {
  bound_device_sn?: string;
  bound_device_name?: string;
}

export default function ElderlyManage() {
  const [data, setData] = useState<ElderlyDisplay[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [keyword, setKeyword] = useState('');
  const [detailVisible, setDetailVisible] = useState(false);
  const [editVisible, setEditVisible] = useState(false);
  const [currentItem, setCurrentItem] = useState<ElderlyDisplay | null>(null);
  const [deviceList, setDeviceList] = useState<Device[]>([]);
  const [boundDevice, setBoundDevice] = useState<Device | null>(null);
  const [changeDeviceMode, setChangeDeviceMode] = useState(false);
  const [form] = Form.useForm();

  const pageSize = 8;

  const loadData = async () => {
    setLoading(true);
    try {
      const res = await elderlyAPI.getList({ page, page_size: pageSize, keyword });
      console.log('[ElderlyManage] res 完整响应:', JSON.stringify(res));
      console.log('[ElderlyManage] res.data:', res?.data);
      console.log('[ElderlyManage] res.total:', res?.total);
      const raw = res?.data;
      const list = Array.isArray(raw) ? raw : (Array.isArray(raw?.data) ? raw.data : []);
      const tot = res?.total ?? 0;
      console.log('[ElderlyManage] 解析后 list.length:', list.length, 'total:', tot);
      console.log('[ElderlyManage] 完整list:', JSON.stringify(list));
      list.forEach((item: any, idx: number) => {
        console.log(`[ElderlyManage] [${idx}] id=${item.id} name=${item.name} community=${item.community_name} device_sn=${item.bound_device_sn} device_name=${item.bound_device_name} device_count=${item.device_count}`);
      });
      setData(list);
      setTotal(tot);
    } catch (err) {
      console.error('[ElderlyManage] Failed to load:', err);
      message.error('加载老人列表失败');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadData(); }, [page, keyword]);

  // 获取设备列表（用于绑定）
  const fetchDevices = async (): Promise<Device[]> => {
    try {
      const res = await deviceAPI.getList({ page: 1, page_size: 200 });
      const raw = res?.data;
      const list = Array.isArray(raw) ? raw : (Array.isArray(raw?.data) ? raw.data : []);
      setDeviceList(list);
      return list;
    } catch (e) {
      console.error('[ElderlyManage] Failed to load devices:', e);
      return deviceList;
    }
  };

  useEffect(() => { fetchDevices(); }, []);

  // 查找当前老人绑定的设备
  const findBoundDevice = (elderlyId: string): Device | null => {
    return deviceList.find((d) => d.elderly_id === elderlyId) || null;
  };

  const statusMap: Record<string, { color: string; text: string }> = {
    active: { color: 'green', text: '正常' },
    attention: { color: 'orange', text: '关注' },
    alarming: { color: 'red', text: '报警中' },
    offline: { color: 'default', text: '离线' },
  };

  const columns: ColumnsType<ElderlyDisplay> = [
    { title: '姓名', width: 90, render: (_, r) => r.name || r.real_name },
    { title: '性别', dataIndex: 'gender', width: 50, render: (v: string) => v === 'male' || v === 'M' ? '男' : '女' },
    { title: '年龄', dataIndex: 'age', width: 50 },
    { title: '社区', dataIndex: 'community_name', width: 100 },
    { title: '联系电话', dataIndex: 'phone', width: 120 },
    {
      title: '绑定设备', width: 140, render: (_, r) => {
        const device = findBoundDevice(r.id);
        if (device) {
          return <Tag color="blue">{device.device_name || device.device_sn}</Tag>;
        }
        if (r.bound_device_name) {
          return <Tag color="blue">{r.bound_device_name}</Tag>;
        }
        return <Text type="secondary">未绑定</Text>;
      },
    },
    {
      title: '最新体征', width: 200, render: (_, r) => {
        if (!r.latest_vital) return <Text type="secondary">暂无数据</Text>;
        const v = r.latest_vital;
        return (
          <Space size={8}>
            <Tag>❤️ {v.heart_rate}</Tag>
            <Tag>💉 {v.blood_oxygen}%</Tag>
            <Tag>🌡 {v.temperature}℃</Tag>
            <Tag>🩸 {v.systolic_bp}/{v.diastolic_bp}</Tag>
          </Space>
        );
      },
    },
    {
      title: '状态', dataIndex: 'status', width: 90,
      render: (v: string) => <Tag color={statusMap[v]?.color}>{statusMap[v]?.text || v}</Tag>,
    },
    {
      title: '操作', width: 180, render: (_, r) => (
        <Space>
          <Button type="link" size="small" icon={<EyeOutlined />} onClick={() => { setCurrentItem(r); setDetailVisible(true); }}>
            详情
          </Button>
          <Button type="link" size="small" icon={<EditOutlined />} onClick={async () => {
            setCurrentItem(r);
            const devices = await fetchDevices(); // 刷新设备列表并获取最新数据
            const device = devices.find((d) => d.elderly_id === r.id) || null;
            setBoundDevice(device);
            setChangeDeviceMode(false);
            form.setFieldsValue({
              name: r.name,
              nickname: r.nickname,
              gender: r.gender,
              age: r.age,
              phone: r.phone,
              community_name: r.community_name,
              address: r.address,
              emergency_contact: r.emergency_contact_name || r.emergency_contact || '',
              emergency_phone: r.emergency_contact_phone || r.emergency_phone || '',
            });
            setEditVisible(true);
          }}>
            编辑
          </Button>
          <Popconfirm title="确定删除？" onConfirm={async () => {
            try {
              await elderlyAPI.delete(r.id);
              message.success('已删除');
              loadData();
              fetchDevices();
            } catch (e) {
              console.error('[ElderlyManage] Delete failed:', e);
              message.error('删除失败');
            }
          }}>
            <Button type="link" size="small" danger icon={<DeleteOutlined />} />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  const handleEdit = async (values: Partial<ElderlyProfile> & { device_sn?: string }) => {
    try {
      // 构造与后端 UpdateElderlyRequest 匹配的请求体
      const updateData: Record<string, unknown> = {
        name: values.name,
        gender: values.gender,
        age: values.age,
        phone: values.phone,
        community_name: values.community_name,
        address: values.address,
        emergency_contact: values.emergency_contact,
        emergency_phone: values.emergency_phone,
      };

      // 处理设备绑定
      if (changeDeviceMode) {
        // 处于更换模式：传新的 device_sn（空字符串表示解绑）
        updateData.device_sn = values.device_sn ?? '';
      } else if (boundDevice) {
        // 未更换设备：保持当前绑定不变
        updateData.device_sn = boundDevice.device_sn;
      } else if (values.device_sn) {
        // 之前未绑定设备，现在新选了一个
        updateData.device_sn = values.device_sn;
      }

      if (currentItem) {
        await elderlyAPI.update(currentItem.id, updateData);
        message.success('更新成功');
      } else {
        await elderlyAPI.create(updateData);
        message.success('创建成功');
      }
      setEditVisible(false);
      setCurrentItem(null);
      setBoundDevice(null);
      setChangeDeviceMode(false);
      form.resetFields();
      loadData();
      fetchDevices();
    } catch (e) {
      console.error('[ElderlyManage] Edit/Create failed:', e);
      message.error('操作失败');
    }
  };

  // 获取空闲设备列表（未被其他老人绑定的设备）
  const getAvailableDevices = (): Device[] => {
    return deviceList.filter((d) => !d.elderly_id || d.elderly_id === currentItem?.id);
  };

  return (
    <div>
      <Title level={4}>老人管理</Title>

      <Card style={{ marginBottom: 16 }}>
        <Row gutter={16} align="middle">
          <Col flex="auto">
            <Input.Search
              placeholder="搜索姓名、电话、地址"
              allowClear
              enterButton={<SearchOutlined />}
              value={keyword}
              onChange={(e) => setKeyword(e.target.value)}
              onSearch={() => { setPage(1); loadData(); }}
              style={{ maxWidth: 360 }}
            />
          </Col>
          <Col>
            <Button type="primary" icon={<PlusOutlined />} onClick={() => { setCurrentItem(null); setBoundDevice(null); setChangeDeviceMode(true); form.resetFields(); setEditVisible(true); }}>
              新增老人
            </Button>
          </Col>
        </Row>
      </Card>

      <Table
        dataSource={data}
        columns={columns}
        rowKey="id"
        loading={loading}
        pagination={{ current: page, total, pageSize, onChange: (p) => setPage(p), showTotal: (t) => `共 ${t} 位老人` }}
        scroll={{ x: 1000 }}
      />

      {/* 详情弹窗 */}
      <Modal
        title="老人档案详情"
        open={detailVisible}
        onCancel={() => { setDetailVisible(false); setCurrentItem(null); }}
        footer={null}
        width={720}
      >
        {currentItem && (
          <Descriptions bordered column={2} size="small">
            <Descriptions.Item label="姓名">{currentItem.name}</Descriptions.Item>
            <Descriptions.Item label="昵称">{currentItem.nickname}</Descriptions.Item>
            <Descriptions.Item label="性别">{currentItem.gender === 'male' ? '男' : '女'}</Descriptions.Item>
            <Descriptions.Item label="年龄">{currentItem.age} 岁</Descriptions.Item>
            <Descriptions.Item label="出生日期">{currentItem.birthday || currentItem.birth_date}</Descriptions.Item>
            <Descriptions.Item label="身份证号">{currentItem.id_card}</Descriptions.Item>
            <Descriptions.Item label="联系电话">{currentItem.phone}</Descriptions.Item>
            <Descriptions.Item label="所属社区">{currentItem.community_name}</Descriptions.Item>
            <Descriptions.Item label="地址" span={2}>{currentItem.address}</Descriptions.Item>
            <Descriptions.Item label="紧急联系人">{currentItem.emergency_contact_name || currentItem.emergency_contact}</Descriptions.Item>
            <Descriptions.Item label="紧急联系电话">{currentItem.emergency_contact_phone || currentItem.emergency_phone}</Descriptions.Item>
            <Descriptions.Item label="绑定设备" span={2}>
              {(() => {
                const device = findBoundDevice(currentItem.id);
                if (device) {
                  return (
                    <Space>
                      <Tag color="blue">{device.device_name || device.device_sn}</Tag>
                      <Text type="secondary">({device.device_sn})</Text>
                    </Space>
                  );
                }
                if (currentItem.bound_device_name) {
                  return <Tag color="blue">{currentItem.bound_device_name} ({currentItem.bound_device_sn})</Tag>;
                }
                return <Text type="secondary">未绑定设备</Text>;
              })()}
            </Descriptions.Item>
            <Descriptions.Item label="疾病史" span={2}>
              {Array.isArray(currentItem.health_history) && currentItem.health_history.length > 0
                ? currentItem.health_history.map((h) => <Tag key={h} color="orange">{h}</Tag>)
                : <Text type="secondary">无</Text>}
            </Descriptions.Item>
            <Descriptions.Item label="过敏史" span={2}>
              {Array.isArray(currentItem.allergies) && currentItem.allergies.length > 0
                ? currentItem.allergies.map((a) => <Tag key={a} color="red">{a}</Tag>)
                : <Text type="secondary">无</Text>}
            </Descriptions.Item>
            <Descriptions.Item label="当前用药" span={2}>
              {Array.isArray(currentItem.medications) && currentItem.medications.length > 0
                ? currentItem.medications.map((m, i) => (
                  <Tag key={i} color="blue">{m.name} {m.dosage} ({m.frequency})</Tag>
                ))
                : <Text type="secondary">无</Text>}
            </Descriptions.Item>
            <Descriptions.Item label="状态">
              <Tag color={statusMap[currentItem.status]?.color}>{statusMap[currentItem.status]?.text}</Tag>
            </Descriptions.Item>
            {currentItem.latest_vital && (
              <Descriptions.Item label="最新体征" span={2}>
                <Space size={8}>
                  <Tag>心率 {currentItem.latest_vital.heart_rate} bpm</Tag>
                  <Tag>血氧 {currentItem.latest_vital.blood_oxygen}%</Tag>
                  <Tag>体温 {currentItem.latest_vital.temperature}℃</Tag>
                  <Tag>血压 {currentItem.latest_vital.systolic_bp}/{currentItem.latest_vital.diastolic_bp} mmHg</Tag>
                </Space>
              </Descriptions.Item>
            )}
          </Descriptions>
        )}
      </Modal>

      {/* 编辑弹窗 */}
      <Modal
        title={currentItem ? '编辑老人档案' : '新增老人'}
        open={editVisible}
        onCancel={() => { setEditVisible(false); setCurrentItem(null); setBoundDevice(null); setChangeDeviceMode(false); form.resetFields(); }}
        onOk={() => form.submit()}
        width={640}
      >
        <Form form={form} layout="vertical" onFinish={handleEdit}>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="name" label="姓名" rules={[{ required: true }]}>
                <Input />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="nickname" label="昵称">
                <Input />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="gender" label="性别" rules={[{ required: true }]}>
                <Select options={[{ value: 'male', label: '男' }, { value: 'female', label: '女' }]} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="age" label="年龄">
                <InputNumber min={60} max={120} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="phone" label="联系电话" rules={[{ required: true }]}>
                <Input />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="community_name" label="所属社区">
                <Select options={[{ value: '花木社区', label: '花木社区' }, { value: '联洋社区', label: '联洋社区' }]} />
              </Form.Item>
            </Col>
            <Col span={24}>
              <Form.Item name="address" label="地址">
                <Input />
              </Form.Item>
            </Col>

            {/* 设备绑定区域 */}
            <Col span={24}>
              <Form.Item label="设备绑定">
                {boundDevice && !changeDeviceMode ? (
                  // 已绑定设备，显示当前绑定 + 更换按钮
                  <Space direction="vertical" style={{ width: '100%' }}>
                    <Alert
                      type="info"
                      showIcon
                      message={`已绑定设备: ${boundDevice.device_name || boundDevice.device_sn}`}
                      description={`设备序列号: ${boundDevice.device_sn}`}
                      action={
                        <Button size="small" type="primary" icon={<SwapOutlined />} onClick={() => { setChangeDeviceMode(true); form.setFieldValue('device_sn', undefined); }}>
                          更换设备
                        </Button>
                      }
                    />
                  </Space>
                ) : (
                  // 未绑定设备 或 处于更换模式，显示设备选择下拉框
                  <Space direction="vertical" style={{ width: '100%' }} size="small">
                    {boundDevice && changeDeviceMode && (
                      <Alert
                        type="warning"
                        showIcon
                        message="正在更换设备"
                        description={`当前绑定: ${boundDevice.device_name || boundDevice.device_sn}，选择新设备后将自动解绑旧设备`}
                      />
                    )}
                    <Form.Item name="device_sn" noStyle>
                      <Select
                        allowClear
                        placeholder="选择要绑定的设备（仅显示空闲设备）"
                        options={getAvailableDevices().map((d) => ({
                          value: d.device_sn,
                          label: `${d.device_name || d.device_sn} (空闲)`,
                        }))}
                      />
                    </Form.Item>
                    {changeDeviceMode && boundDevice && (
                      <Button size="small" onClick={() => { setChangeDeviceMode(false); form.setFieldValue('device_sn', boundDevice.device_sn); }}>
                        取消更换，保持当前设备
                      </Button>
                    )}
                  </Space>
                )}
              </Form.Item>
            </Col>

            <Col span={12}>
              <Form.Item name="emergency_contact" label="紧急联系人">
                <Input />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="emergency_phone" label="紧急联系电话">
                <Input />
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Modal>
    </div>
  );
}
