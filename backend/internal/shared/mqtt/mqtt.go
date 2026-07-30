package mqtt

import (
	"encoding/json"
	"fmt"
	"sync"
	"time"

	mqttlib "github.com/eclipse/paho.mqtt.golang"
	"go.uber.org/zap"

	"elderly-health-backend/internal/shared/config"
	"elderly-health-backend/internal/shared/logger"
)

// Client MQTT 客户端封装
type Client struct {
	client    mqttlib.Client
	cfg       *config.MQTTConfig
	handlers  map[string]mqttlib.MessageHandler
	mu        sync.RWMutex
	connected bool
}

var (
	// 默认 MQTT 客户端实例
	MQTTClient *Client
)

// Init 初始化 MQTT 客户端
func Init(cfg *config.MQTTConfig) error {
	MQTTClient = &Client{
		cfg:      cfg,
		handlers: make(map[string]mqttlib.MessageHandler),
	}

	opts := mqttlib.NewClientOptions().
		AddBroker(cfg.Broker).
		SetClientID(cfg.ClientID).
		SetUsername(cfg.Username).
		SetPassword(cfg.Password).
		SetCleanSession(false).
		SetKeepAlive(60 * time.Second).
		SetPingTimeout(10 * time.Second).
		SetConnectTimeout(10 * time.Second).
		SetAutoReconnect(true).
		SetMaxReconnectInterval(30 * time.Second).
		SetConnectionLostHandler(MQTTClient.onConnectionLost).
		SetOnConnectHandler(MQTTClient.onConnect)

	MQTTClient.client = mqttlib.NewClient(opts)

	token := MQTTClient.client.Connect()
	if token.Wait() && token.Error() != nil {
		return fmt.Errorf("mqtt connect failed: %w", token.Error())
	}

	logger.Log.Info("MQTT connected successfully", zap.String("broker", cfg.Broker))
	return nil
}

func (c *Client) onConnect(client mqttlib.Client) {
	c.mu.Lock()
	c.connected = true
	c.mu.Unlock()

	logger.Log.Info("MQTT (re)connected, resubscribing topics...")

	// 重新订阅所有 topic
	c.mu.RLock()
	for topic, handler := range c.handlers {
		if token := client.Subscribe(topic, c.cfg.QoS, handler); token.Wait() && token.Error() != nil {
			logger.Log.Error("MQTT resubscribe failed",
				zap.String("topic", topic),
				zap.Error(token.Error()),
			)
		}
	}
	c.mu.RUnlock()
}

func (c *Client) onConnectionLost(client mqttlib.Client, err error) {
	c.mu.Lock()
	c.connected = false
	c.mu.Unlock()

	logger.Log.Warn("MQTT connection lost, will auto-reconnect", zap.Error(err))
}

// IsConnected 检查连接状态
func (c *Client) IsConnected() bool {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.connected
}

// Subscribe 订阅 Topic
func (c *Client) Subscribe(topic string, qos byte, handler mqttlib.MessageHandler) error {
	c.mu.Lock()
	c.handlers[topic] = handler
	c.mu.Unlock()

	token := c.client.Subscribe(topic, qos, handler)
	if token.Wait() && token.Error() != nil {
		return fmt.Errorf("subscribe topic %s failed: %w", topic, token.Error())
	}

	logger.Log.Info("MQTT subscribed", zap.String("topic", topic))
	return nil
}

// SubscribeFunc 订阅 Topic（使用消息处理函数）
func (c *Client) SubscribeFunc(topic string, qos byte, fn func(topic string, payload []byte)) error {
	handler := func(client mqttlib.Client, msg mqttlib.Message) {
		fn(msg.Topic(), msg.Payload())
	}
	return c.Subscribe(topic, qos, handler)
}

// Publish 发布消息
func (c *Client) Publish(topic string, qos byte, payload interface{}) error {
	var data []byte
	var err error

	switch v := payload.(type) {
	case string:
		data = []byte(v)
	case []byte:
		data = v
	default:
		data, err = json.Marshal(v)
		if err != nil {
			return fmt.Errorf("marshal payload failed: %w", err)
		}
	}

	token := c.client.Publish(topic, qos, false, data)
	if token.Wait() && token.Error() != nil {
		return fmt.Errorf("publish to %s failed: %w", topic, token.Error())
	}

	return nil
}

// Close 关闭连接
func (c *Client) Close() {
	if c.client != nil && c.client.IsConnected() {
		c.client.Disconnect(250)
		logger.Log.Info("MQTT disconnected")
	}
}

// ============ Topic 常量和辅助函数 ============

const (
	// 上行 topic
	TopicDeviceOnline    = "device/%s/online"
	TopicDeviceHeartbeat = "device/%s/heartbeat"
	TopicDeviceVital     = "device/%s/vital"
	TopicDeviceAlarm     = "device/%s/alarm"
	TopicDeviceSignin    = "device/%s/signin"
	TopicDevicePosition  = "device/%s/position"
	TopicDeviceSleep     = "device/%s/sleep"
	TopicDeviceBatch     = "device/%s/batch"

	// 下行 topic
	TopicDeviceConfig     = "device/%s/config"
	TopicDeviceSigninPush = "device/%s/signin_push"
	TopicDeviceOTA        = "device/%s/ota"
	TopicDeviceRestart    = "device/%s/restart"
	TopicDeviceReject     = "device/%s/reject"
	TopicDeviceAck        = "device/%s/ack/%s"
)

// DeviceTopic 生成设备上行 topic
func DeviceTopic(format, deviceSN string) string {
	return fmt.Sprintf(format, deviceSN)
}

// DeviceAckTopic 生成 ACK topic
func DeviceAckTopic(deviceSN, msgID string) string {
	return fmt.Sprintf(TopicDeviceAck, deviceSN, msgID)
}

// ============ 上行数据模型 ============

// VitalData 设备体征上报数据
type VitalData struct {
	DeviceSN    string  `json:"device_sn"`
	ElderlyID   string  `json:"elderly_id"`
	Seq         int64   `json:"seq"`
	Timestamp   int64   `json:"timestamp"`
	HeartRate   *int    `json:"heart_rate,omitempty"`
	SpO2        *float64 `json:"spo2,omitempty"`
	Temperature *float64 `json:"temperature,omitempty"`
	Steps       *int    `json:"steps,omitempty"`
	AccelX      *float64 `json:"accel_x,omitempty"`
	AccelY      *float64 `json:"accel_y,omitempty"`
	AccelZ      *float64 `json:"accel_z,omitempty"`
	ActivityLev *int    `json:"activity_level,omitempty"`
	Posture     *string `json:"posture,omitempty"`
	Confidence  *float64 `json:"confidence_hr,omitempty"`
	ReportInterval int  `json:"report_interval"`
}

// AlarmData 设备报警上报数据
type AlarmData struct {
	DeviceSN  string `json:"device_sn"`
	ElderlyID string `json:"elderly_id"`
	Seq       int64  `json:"seq"`
	Timestamp int64  `json:"timestamp"`
	AlarmType string `json:"alarm_type"` // SOS / FALL / VITAL_ABNORMAL
	Severity  string `json:"severity"`    // P0 / P1 / P2 / P3
	// SOS 特定字段
	SOSPressDuration *int `json:"sos_press_duration,omitempty"`
	// 跌倒检测字段
	FallConfidence   *float64 `json:"fall_confidence,omitempty"`
	FallStage        *string  `json:"fall_stage,omitempty"` // SUSPECT / CONFIRMED / VERIFIED
	ImpactForce      *float64 `json:"impact_force,omitempty"`
	// 体征异常字段
	AbnormalMetric  *string  `json:"abnormal_metric,omitempty"`
	AbnormalValue   *float64 `json:"abnormal_value,omitempty"`
	ThresholdValue  *float64 `json:"threshold_value,omitempty"`
	// 环境快照
	HeartRate    *int     `json:"heart_rate,omitempty"`
	SpO2         *float64 `json:"spo2,omitempty"`
	Temperature  *float64 `json:"temperature,omitempty"`
	Battery      *int     `json:"battery,omitempty"`
	Latitude     *float64 `json:"latitude,omitempty"`
	Longitude    *float64 `json:"longitude,omitempty"`
}

// SigninData 设备签到的数据
type SigninData struct {
	DeviceSN   string `json:"device_sn"`
	ElderlyID  string `json:"elderly_id"`
	Timestamp  int64  `json:"timestamp"`
	Method     string `json:"method"` // touch / voice / wrist_up / auto
}

// HeartbeatData 设备心跳数据
type HeartbeatData struct {
	DeviceSN        string `json:"device_sn"`
	Battery         int    `json:"battery"`
	SignalStrength  int    `json:"signal_strength"`
	FirmwareVersion string `json:"firmware_version"`
	UptimeSeconds   int64  `json:"uptime_seconds"`
	FreeHeap        int64  `json:"free_heap,omitempty"`
	Temperature     *float64 `json:"device_temp,omitempty"`
}

// BatchData 断网补传批次
type BatchData struct {
	DeviceSN   string        `json:"device_sn"`
	BatchID    string        `json:"batch_id"`
	BatchSeq   int           `json:"batch_seq"`
	TotalBatches int         `json:"total_batches"`
	DataType   string        `json:"data_type"` // vital / alarm / signin
	Records    []json.RawMessage `json:"records"`
}

// PositionData 位置数据
type PositionData struct {
	DeviceSN  string  `json:"device_sn"`
	ElderlyID string  `json:"elderly_id"`
	Timestamp int64   `json:"timestamp"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Accuracy  float64 `json:"accuracy,omitempty"`
	Speed     float64 `json:"speed,omitempty"`
	Altitude  float64 `json:"altitude,omitempty"`
}

// SleepData 睡眠状态数据
type SleepData struct {
	DeviceSN   string `json:"device_sn"`
	ElderlyID  string `json:"elderly_id"`
	Timestamp  int64  `json:"timestamp"`
	Status     string `json:"status"` // awake / light_sleep / deep_sleep
}

// ============ 下行指令模型 ============

type ConfigCommand struct {
	ReportInterval   int     `json:"report_interval"`
	ActiveInterval   int     `json:"active_interval"`
	SleepInterval    int     `json:"sleep_interval"`
	PositionInterval int     `json:"position_interval"`
	AlarmPositionInterval int `json:"alarm_position_interval"`
	HRThresholdLow   int     `json:"hr_threshold_low"`
	HRThresholdHigh  int     `json:"hr_threshold_high"`
	SpO2Threshold    int     `json:"spo2_threshold"`
	TempThresholdLow float64 `json:"temp_threshold_low"`
	TempThresholdHigh float64 `json:"temp_threshold_high"`
	FallSensitivity  string  `json:"fall_sensitivity"` // low / medium / high
	NTPHost          string  `json:"ntp_host"`
}

type SigninPushCommand struct {
	PushID    string `json:"push_id"`
	Message   string `json:"message"`
	Greeting  string `json:"greeting"`
	Priority  int    `json:"priority"` // 1=普通提醒 2=紧急提醒
	AutoDismiss int  `json:"auto_dismiss"` // 自动消失秒数
}

type OTACommand struct {
	OTAID      string `json:"ota_id"`
	FirmwareURL string `json:"firmware_url"`
	Version    string `json:"version"`
	FileSize   int64  `json:"file_size"`
	MD5        string `json:"md5"`
	ForceUpdate bool  `json:"force_update"`
	Strategy   string `json:"strategy"` // immediate / scheduled / user_confirm
}
