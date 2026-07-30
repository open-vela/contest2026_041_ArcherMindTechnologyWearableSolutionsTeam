import { useEffect, useState } from 'react';
import {
  Card, Row, Col, Typography, Form, InputNumber, Switch, TimePicker,
  Button, message, Descriptions, Tag, Space, Statistic, Divider, Spin,
} from 'antd';
import {
  SettingOutlined, SaveOutlined, CheckCircleOutlined,
  ClockCircleOutlined, ApiOutlined, DatabaseOutlined,
} from '@ant-design/icons';
import { systemAPI } from '@/api';
import type { SystemConfig, SystemStatus } from '@/types';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

// 默认配置（后端无数据时的兜底）
const defaultConfig: SystemConfig = {
  signin_start_time: '06:00',
  signin_end_time: '10:00',
  signin_reminder_interval: 30,
  signin_escalation_timeout: 60,
  alarm_p0_response_seconds: 300,
  alarm_p1_escalation_minutes: 15,
  heart_rate_low: 60,
  heart_rate_high: 100,
  blood_oxygen_low: 90,
  temperature_low: 36.0,
  temperature_high: 37.5,
  notification_channels: { sms: true, phone: true, push: true, wechat: false },
};

export default function SystemSettings() {
  const [config, setConfig] = useState<SystemConfig>(defaultConfig);
  const [status, setStatus] = useState<SystemStatus | null>(null);
  const [loading, setLoading] = useState(false);
  const [form] = Form.useForm();

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    try {
      const [cfgRes, statusRes] = await Promise.all([
        systemAPI.getConfig(),
        systemAPI.getStatus(),
      ]);
      // 后端返回 {code, message, data: {...}}
      const cfgData = cfgRes?.data as SystemConfig | undefined;
      if (cfgData) {
        // 合并默认值，确保 notification_channels 存在
        const merged: SystemConfig = {
          ...defaultConfig,
          ...cfgData,
          notification_channels: {
            ...defaultConfig.notification_channels,
            ...(cfgData.notification_channels || {}),
          },
        };
        setConfig(merged);
        form.setFieldsValue({
          ...merged,
          signin_start_time: dayjs(merged.signin_start_time, 'HH:mm'),
          signin_end_time: dayjs(merged.signin_end_time, 'HH:mm'),
        });
      } else {
        setConfig(defaultConfig);
        form.setFieldsValue({
          ...defaultConfig,
          signin_start_time: dayjs(defaultConfig.signin_start_time, 'HH:mm'),
          signin_end_time: dayjs(defaultConfig.signin_end_time, 'HH:mm'),
        });
      }

      const statusData = statusRes?.data as SystemStatus | undefined;
      if (statusData) {
        setStatus({
          mysql: statusData.mysql || 'UNKNOWN',
          redis: statusData.redis || 'UNKNOWN',
          emqx: statusData.emqx || 'UNKNOWN',
          websocket: statusData.websocket || 'UNKNOWN',
          uptime: statusData.uptime || statusData.uptime_seconds?.toString() || '0',
          cpu_usage: statusData.cpu_usage || 'N/A',
          memory_usage: statusData.memory_usage || 'N/A',
        });
      }
    } catch (e) {
      console.error('[SystemSettings] Load failed:', e);
      // 使用默认配置，不崩溃
      setConfig(defaultConfig);
      form.setFieldsValue({
        ...defaultConfig,
        signin_start_time: dayjs(defaultConfig.signin_start_time, 'HH:mm'),
        signin_end_time: dayjs(defaultConfig.signin_end_time, 'HH:mm'),
      });
    }
  };

  const handleSaveConfig = async (values: Record<string, unknown>) => {
    setLoading(true);
    try {
      const data: Partial<SystemConfig> = {
        ...values as unknown as Partial<SystemConfig>,
        signin_start_time: (values.signin_start_time as dayjs.Dayjs)?.format('HH:mm'),
        signin_end_time: (values.signin_end_time as dayjs.Dayjs)?.format('HH:mm'),
      };
      await systemAPI.updateConfig(data);
      message.success('配置已保存');
      loadData();
    } catch {
      message.error('保存失败');
    } finally {
      setLoading(false);
    }
  };

  const channels = config.notification_channels || defaultConfig.notification_channels;

  return (
    <div>
      <Title level={4}>系统设置</Title>

      {/* 系统状态面板 */}
      {status ? (
        <Card title="📡 系统状态" size="small" style={{ marginBottom: 16 }}>
          <Row gutter={16}>
            <Col span={6}>
              <Statistic
                title="MySQL 数据库"
                value={status.mysql === 'UP' ? '正常' : '异常'}
                valueStyle={{ color: status.mysql === 'UP' ? '#52c41a' : '#ff4d4f' }}
                prefix={<DatabaseOutlined />}
              />
            </Col>
            <Col span={6}>
              <Statistic
                title="Redis 缓存"
                value={status.redis === 'UP' ? '正常' : '异常'}
                valueStyle={{ color: status.redis === 'UP' ? '#52c41a' : '#ff4d4f' }}
                prefix={<ApiOutlined />}
              />
            </Col>
            <Col span={6}>
              <Statistic
                title="EMQX MQTT"
                value={status.emqx === 'UP' ? '正常' : '异常'}
                valueStyle={{ color: status.emqx === 'UP' ? '#52c41a' : '#ff4d4f' }}
                prefix={<ApiOutlined />}
              />
            </Col>
            <Col span={6}>
              <Statistic
                title="WebSocket"
                value={status.websocket === 'UP' ? '正常' : '异常'}
                valueStyle={{ color: status.websocket === 'UP' ? '#52c41a' : '#ff4d4f' }}
                prefix={<CheckCircleOutlined />}
              />
            </Col>
          </Row>
          <Divider style={{ margin: '16px 0' }} />
          <Row gutter={16}>
            <Col span={8}>
              <Statistic title="运行时间" value={status.uptime} prefix={<ClockCircleOutlined />} />
            </Col>
            <Col span={8}>
              <Statistic title="CPU 使用率" value={status.cpu_usage} />
            </Col>
            <Col span={8}>
              <Statistic title="内存使用率" value={status.memory_usage} />
            </Col>
          </Row>
        </Card>
      ) : (
        <Card title="📡 系统状态" size="small" style={{ marginBottom: 16 }}>
          <Spin tip="加载中..." />
        </Card>
      )}

      {/* 参数配置 */}
      <Card title={<Space><SettingOutlined /> 参数配置</Space>} style={{ marginBottom: 16 }}>
        <Form form={form} layout="vertical" onFinish={handleSaveConfig}>
          <Row gutter={24}>
            <Col span={12}>
              <Card title="📋 签到设置" size="small" style={{ marginBottom: 16 }}>
                <Form.Item name="signin_start_time" label="签到开始时间">
                  <TimePicker format="HH:mm" style={{ width: '100%' }} />
                </Form.Item>
                <Form.Item name="signin_end_time" label="签到结束时间">
                  <TimePicker format="HH:mm" style={{ width: '100%' }} />
                </Form.Item>
                <Form.Item name="signin_reminder_interval" label="提醒间隔（分钟）">
                  <InputNumber min={5} max={120} style={{ width: '100%' }} />
                </Form.Item>
                <Form.Item name="signin_escalation_timeout" label="超时升级时间（分钟）">
                  <InputNumber min={10} max={240} style={{ width: '100%' }} />
                </Form.Item>
              </Card>
            </Col>
            <Col span={12}>
              <Card title="🚨 报警设置" size="small" style={{ marginBottom: 16 }}>
                <Form.Item name="alarm_p0_response_seconds" label="P0 响应时限（秒）">
                  <InputNumber min={60} max={600} style={{ width: '100%' }} />
                </Form.Item>
                <Form.Item name="alarm_p1_escalation_minutes" label="P1 升级为 P0（分钟）">
                  <InputNumber min={1} max={60} style={{ width: '100%' }} />
                </Form.Item>
              </Card>
              <Card title="📊 体征阈值设置" size="small" style={{ marginBottom: 16 }}>
                <Row gutter={12}>
                  <Col span={12}>
                    <Form.Item name="heart_rate_low" label="心率下限">
                      <InputNumber min={30} max={80} style={{ width: '100%' }} />
                    </Form.Item>
                  </Col>
                  <Col span={12}>
                    <Form.Item name="heart_rate_high" label="心率上限">
                      <InputNumber min={90} max={180} style={{ width: '100%' }} />
                    </Form.Item>
                  </Col>
                </Row>
                <Form.Item name="blood_oxygen_low" label="血氧下限 (%)">
                  <InputNumber min={80} max={100} style={{ width: '100%' }} />
                </Form.Item>
                <Row gutter={12}>
                  <Col span={12}>
                    <Form.Item name="temperature_low" label="体温下限 (℃)">
                      <InputNumber min={34} max={37} step={0.1} style={{ width: '100%' }} />
                    </Form.Item>
                  </Col>
                  <Col span={12}>
                    <Form.Item name="temperature_high" label="体温上限 (℃)">
                      <InputNumber min={37} max={42} step={0.1} style={{ width: '100%' }} />
                    </Form.Item>
                  </Col>
                </Row>
              </Card>
            </Col>
          </Row>
          <Row gutter={24}>
            <Col span={12}>
              <Card title="📢 通知渠道" size="small">
                <Space direction="vertical">
                  <Space>
                    <Text>短信通知：</Text>
                    <Switch defaultChecked={channels.sms} />
                  </Space>
                  <Space>
                    <Text>电话通知：</Text>
                    <Switch defaultChecked={channels.phone} />
                  </Space>
                  <Space>
                    <Text>App推送：</Text>
                    <Switch defaultChecked={channels.push} />
                  </Space>
                  <Space>
                    <Text>微信通知：</Text>
                    <Switch defaultChecked={channels.wechat} />
                  </Space>
                </Space>
              </Card>
            </Col>
          </Row>
          <Form.Item style={{ marginTop: 24 }}>
            <Button type="primary" htmlType="submit" icon={<SaveOutlined />} loading={loading} size="large">
              保存配置
            </Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  );
}
