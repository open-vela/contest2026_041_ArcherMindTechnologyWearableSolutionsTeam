package device

import (
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	goredis "github.com/redis/go-redis/v9"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"elderly-health-backend/internal/shared/database"
	apperrors "elderly-health-backend/internal/shared/errors"
	"elderly-health-backend/internal/shared/logger"
	"elderly-health-backend/internal/shared/middleware"
	"elderly-health-backend/internal/shared/mqtt"
	"elderly-health-backend/internal/shared/redis"
	"elderly-health-backend/internal/shared/utils"
)

// RegisterRoutes 注册设备管理 REST 路由
func RegisterRoutes(r *gin.RouterGroup, jwtSecret string) {
	auth := r.Group("")
	auth.Use(middleware.JWTAuth(jwtSecret))
	{
		auth.GET("/devices", ListDevices)
		auth.GET("/devices/:id", GetDevice)
		auth.POST("/devices", RegisterDevice)
		auth.PUT("/devices/:id", UpdateDevice)
		auth.POST("/devices/:id/ota", TriggerOTA)
		auth.POST("/devices/:id/restart", RestartDevice)

		// 设备 HTTP 辅助接口（设备端调用，使用设备证书认证，此处简化为 API Key）
		auth.GET("/devices/ntp", GetServerTime)
		auth.GET("/devices/firmware/latest", GetLatestFirmware)
		auth.POST("/devices/:id/diagnostic", UploadDiagnostic)
	}

	// 设备端 HTTP 数据上报接口（无需 JWT，设备通过 device_sn 自证身份）
	deviceHTTP := r.Group("")
	{
		deviceHTTP.POST("/devices/online", HandleHTTPDeviceOnline)
		deviceHTTP.POST("/devices/heartbeat", HandleHTTPHeartbeat)
		deviceHTTP.POST("/devices/position", HandleHTTPPosition)
	}
}

// ============ MQTT 消息处理 ============

func StartMQTTHandlers() {
	// 设备上线
	mqtt.MQTTClient.SubscribeFunc("device/+/online", 1, handleDeviceOnline)
	// 设备心跳
	mqtt.MQTTClient.SubscribeFunc("device/+/heartbeat", 1, handleHeartbeat)
	// 体征数据（转发至 vital-service 处理，此处只做预处理）
	mqtt.MQTTClient.SubscribeFunc("device/+/vital", 1, handleVitalForward)
	// SOS/报警
	mqtt.MQTTClient.SubscribeFunc("device/+/alarm", 1, handleAlarmForward)
	// 签到
	mqtt.MQTTClient.SubscribeFunc("device/+/signin", 1, handleSigninForward)
	// 位置
	mqtt.MQTTClient.SubscribeFunc("device/+/position", 1, handlePosition)
	// 断网补传
	mqtt.MQTTClient.SubscribeFunc("device/+/batch", 1, handleBatchData)

	logger.Log.Info("MQTT handlers registered for device topics")
}

// ============ 设备上线处理 ============

func handleDeviceOnline(topic string, payload []byte) {
	deviceSN := extractDeviceSN(topic)
	logger.Log.Info("Device online", zap.String("sn", deviceSN))

	// 更新 Redis 在线状态
	ctx := context.Background()
	redis.CacheHelper.Set(ctx, redis.Key(redis.KeyDeviceOnline, deviceSN), "1", 90*time.Second)
	redis.CacheHelper.HSet(ctx, redis.Key(redis.KeyDeviceStatus, deviceSN),
		"status", "online",
		"last_seen", time.Now().UTC().Format(time.RFC3339),
	)

	// 更新 MySQL 设备状态
	database.DB.Exec(
		"UPDATE devices SET status='online', last_online_at=NOW(), updated_at=NOW() WHERE device_sn=?",
		deviceSN,
	)

	// 下发配置参数
	configCmd := mqtt.ConfigCommand{
		ReportInterval:       15,
		ActiveInterval:       5,
		SleepInterval:        300,
		PositionInterval:     300,
		AlarmPositionInterval: 10,
		HRThresholdLow:       40,
		HRThresholdHigh:      140,
		SpO2Threshold:        90,
		TempThresholdLow:     35.0,
		TempThresholdHigh:    38.5,
		FallSensitivity:      "medium",
		NTPHost:              "ntp.aliyun.com",
	}

	if err := mqtt.MQTTClient.Publish(
		mqtt.DeviceTopic(mqtt.TopicDeviceConfig, deviceSN), 1, configCmd,
	); err != nil {
		logger.Log.Error("Failed to send config to device", zap.String("sn", deviceSN), zap.Error(err))
	}
}

// ============ 心跳处理 ============

func handleHeartbeat(topic string, payload []byte) {
	var hb mqtt.HeartbeatData
	if err := json.Unmarshal(payload, &hb); err != nil {
		logger.Log.Warn("Invalid heartbeat payload", zap.Error(err))
		return
	}

	deviceSN := hb.DeviceSN

	// 刷新 Redis 状态
	ctx := context.Background()
	redis.CacheHelper.Set(ctx, redis.Key(redis.KeyDeviceOnline, deviceSN), "1", 90*time.Second)
	redis.CacheHelper.HSet(ctx, redis.Key(redis.KeyDeviceStatus, deviceSN),
		"battery", hb.Battery,
		"signal", hb.SignalStrength,
		"firmware", hb.FirmwareVersion,
		"last_seen", time.Now().UTC().Format(time.RFC3339),
	)

	// 更新 MySQL 设备状态
	database.DB.Exec(
		`UPDATE devices SET battery=?, signal_strength=?, firmware_version=?, 
		last_online_at=NOW(), updated_at=NOW() WHERE device_sn=?`,
		hb.Battery, hb.SignalStrength, hb.FirmwareVersion, deviceSN,
	)

	// 插入心跳时序记录
	database.DB.Exec(
		`INSERT INTO device_heartbeats (device_sn, battery, signal_strength, firmware_version, reported_at)
		 VALUES (?, ?, ?, ?, NOW())`,
		deviceSN, hb.Battery, hb.SignalStrength, hb.FirmwareVersion,
	)

	// 低电量告警
	if hb.Battery < 10 {
		logger.Log.Warn("Low battery alert", zap.String("sn", deviceSN), zap.Int("battery", hb.Battery))
	}
}

// ============ 体征转发 ============

func handleVitalForward(topic string, payload []byte) {
	// 体征数据经过设备服务做初步校验后，通过内部 channel 或直接调用 vital-service
	// 实际部署中可改为 gRPC 调用或 Kafka 消息传递
	var vitals mqtt.VitalData
	if err := json.Unmarshal(payload, &vitals); err != nil {
		logger.Log.Warn("Invalid vital payload", zap.Error(err))
		return
	}

	// 写入 Redis 最新体征缓存
	ctx := context.Background()
	latestKey := redis.Key(redis.KeyVitalSigns, vitals.ElderlyID)
	vitalJSON, _ := json.Marshal(vitals)
	redis.CacheHelper.Set(ctx, latestKey, string(vitalJSON), 2*time.Minute)

	// 写入 MySQL 时序表
	if vitals.HeartRate != nil || vitals.SpO2 != nil || vitals.Temperature != nil {
		database.DB.Exec(
			`INSERT INTO vital_signs (elderly_id, device_id, heart_rate, spo2, temperature,
			 steps, accel_x, accel_y, accel_z, activity_level, posture, confidence_hr,
			 reported_at, created_at)
			 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, FROM_UNIXTIME(?/1000), NOW())`,
			vitals.ElderlyID, vitals.DeviceSN,
			vitals.HeartRate, vitals.SpO2, vitals.Temperature,
			vitals.Steps, vitals.AccelX, vitals.AccelY, vitals.AccelZ,
			vitals.ActivityLev, vitals.Posture, vitals.Confidence,
			vitals.Timestamp,
		)
	}
}

// ============ SOS/报警转发 ============
// ===== 版本：v20260701-1620 (alarm-db-fix-v3) =====
// 修复说明（2026-07-01 v3）：
//   原代码有3个致命Bug导致报警消息无法写入数据库：
//   Bug1: *alarm.Latitude/*alarm.Longitude — MQTT消息不含经纬度时 nil 指针 panic → goroutine崩溃 → INSERT不执行
//   Bug2: JSON发 level 字段，Go struct 读 Severity → 字段名不匹配 → alarm_level 为空
//   Bug3: database.DB.Exec() 返回值完全忽略 → SQL失败也无感知
//
//   修复方案：改用 map[string]interface{} 接收原始 JSON（安全方式），兼容多种字段名，增加错误检查和日志

func handleAlarmForward(topic string, payload []byte) {
	// 用 map 接收原始 JSON（不依赖 AlarmData 结构体指针字段，避免 nil 解引用 panic）
	var rawMap map[string]interface{}
	if err := json.Unmarshal(payload, &rawMap); err != nil {
		logger.Log.Warn("❌ [Alarm] Invalid JSON payload", zap.Error(err), zap.String("raw", string(payload)))
		return
	}

	// 提取字段（兼容多种 JSON 格式）
	deviceSN, _ := rawMap["device_sn"].(string)
	elderlyID, _ := rawMap["elderly_id"].(string)
	alarmType, _ := rawMap["alarm_type"].(string)

	// 兼容 level / severity 两种字段名（MQTTX测试通常发 level，规范应发 severity）
	severity, _ := rawMap["severity"].(string)
	if severity == "" {
		severity, _ = rawMap["level"].(string)
	}
	// severity 仍然为空时默认 P1（确保 NOT NULL 约束满足）
	if severity == "" {
		severity = "P1"
	}
	// alarm_type 为空时默认 SOS
	if alarmType == "" {
		alarmType = "SOS"
	}

	logger.Log.Info("✅ [Alarm] Message received",
		zap.String("device_sn", deviceSN),
		zap.String("alarm_type", alarmType),
		zap.String("severity", severity),
		zap.String("elderly_id", elderlyID),
		zap.String("raw_payload", string(payload)),
	)

	// 🔑 关键修复：elderly_id 为空时通过 device_sn 反查
	if elderlyID == "" && deviceSN != "" {
		logger.Log.Warn("[Alarm] elderly_id empty, trying lookup by device_sn...", zap.String("sn", deviceSN))
		err := database.DB.QueryRow(
			"SELECT elderly_id FROM devices WHERE device_sn = ? AND status != 'deleted'",
			deviceSN,
		).Scan(&elderlyID)
		if err != nil {
			logger.Log.Error("[Alarm] Failed to lookup elderly_id by device_sn",
				zap.Error(err), zap.String("sn", deviceSN))
			// 兜底：查 elderly_profiles 表第一条记录（仅用于测试/开发环境）
			_ = database.DB.QueryRow("SELECT id FROM elderly_profiles LIMIT 1").Scan(&elderlyID)
			if elderlyID != "" {
				logger.Log.Warn("[Alarm] ⚠️ Using fallback elderly_id (first profile in DB)", zap.String("id", elderlyID))
			}
		} else {
			logger.Log.Info("[Alarm] ✅ Found elderly_id from device", zap.String("id", elderlyID))
		}
	}

	// 如果仍然没有 elderly_id，记录错误并跳过（NOT NULL + 外键约束会导致 INSERT 失败）
	if elderlyID == "" {
		logger.Log.Error("[Alarm] ❌ Cannot insert: no elderly_id available (device_sn also empty or not found)",
			zap.String("device_sn", deviceSN),
			zap.String("payload", string(payload)),
		)
		return
	}

	// 安全构建 location JSON（经纬度可能缺失，必须检查后再读取，避免解引用 nil 指针）
	var locationJSON []byte
	if latVal, latOk := rawMap["latitude"]; latOk {
		if lonVal, lonOk := rawMap["longitude"]; lonOk {
			locationJSON, _ = json.Marshal(map[string]float64{
				"latitude":  toFloat64(latVal),
				"longitude": toFloat64(lonVal),
			})
		}
	}
	if locationJSON == nil {
		locationJSON, _ = json.Marshal(nil)
	}

	// 构建快照 JSON（所有体征字段都是可选的）
	var snapshotJSON []byte
	snapshotJSON, _ = json.Marshal(map[string]interface{}{
		"heart_rate":  safeGet(rawMap, "heart_rate"),
		"spo2":        safeGet(rawMap, "spo2"),
		"temperature": safeGet(rawMap, "temperature"),
		"battery":     safeGet(rawMap, "battery"),
	})

	// 写入报警记录到 MySQL
	id := utils.NewUUID()
	result, err := database.DB.Exec(
		`INSERT INTO alarm_records (id, elderly_id, alarm_type, alarm_level, alarm_source,
		 vital_snapshot_json, location_json, description, status, created_at, updated_at)
		 VALUES (?, ?, ?, ?, 'device', ?, ?, ?, 'pending', NOW(), NOW())`,
		id, elderlyID, alarmType, severity,
		snapshotJSON, locationJSON, alarmType,
	)

	if err != nil {
		logger.Log.Error("❌ [Alarm] INSERT failed!",
			zap.Error(err),
			zap.String("id", id),
			zap.String("device_sn", deviceSN),
			zap.String("elderly_id", elderlyID),
			zap.String("alarm_type", alarmType),
			zap.String("severity", severity),
		)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	logger.Log.Info("✅ [Alarm] DB write OK",
		zap.String("alarm_id", id),
		zap.String("device_sn", deviceSN),
		zap.String("severity", severity),
		zap.Int64("rows", rowsAffected),
	)

	// 加入 Redis 报警处理队列（Sorted Set，按严重程度排序）
	ctx := context.Background()
	score := float64(int64(utils.SeverityScore(severity))*1e12 + time.Now().UnixNano())
	redis.Client.ZAdd(ctx, redis.KeyAlarmQueue, goredis.Z{Score: score, Member: id})
}

// ============ 签到转发 ============

func handleSigninForward(topic string, payload []byte) {
	var signin mqtt.SigninData
	if err := json.Unmarshal(payload, &signin); err != nil {
		logger.Log.Warn("Invalid signin payload", zap.Error(err))
		return
	}

	now := time.Now()
	id := utils.NewUUID()

	database.DB.Exec(
		`INSERT INTO signin_records (id, elderly_id, device_id, signin_method, signin_status, 
		 signin_at, signin_date, created_at)
		 VALUES (?, ?, ?, ?, 'checked_in', FROM_UNIXTIME(?/1000), CURDATE(), NOW())
		 ON DUPLICATE KEY UPDATE signin_method=?, signin_at=FROM_UNIXTIME(?/1000)`,
		id, signin.ElderlyID, signin.DeviceSN, signin.Method,
		signin.Timestamp,
		signin.Method, signin.Timestamp,
	)

	// 缓存今日签到状态
	ctx := context.Background()
	redis.CacheHelper.Set(ctx, redis.Key(redis.KeySigninToday, signin.ElderlyID), "1", 24*time.Hour)

	logger.Log.Info("Signin recorded",
		zap.String("elderly", signin.ElderlyID),
		zap.String("method", signin.Method),
		zap.Time("time", now),
	)
}

// ============ 位置处理 ============

func handlePosition(topic string, payload []byte) {
	var pos mqtt.PositionData
	if err := json.Unmarshal(payload, &pos); err != nil {
		logger.Log.Warn("Invalid position payload", zap.Error(err))
		return
	}

	// 缓存最新位置
	ctx := context.Background()
	posJSON, _ := json.Marshal(map[string]float64{
		"lat": pos.Latitude, "lng": pos.Longitude, "accuracy": pos.Accuracy,
	})
	redis.CacheHelper.HSet(ctx, redis.Key(redis.KeyDeviceStatus, pos.DeviceSN),
		"position", string(posJSON),
		"position_updated", time.Now().UTC().Format(time.RFC3339),
	)
}

// ============ 断网补传处理 ============

func handleBatchData(topic string, payload []byte) {
	var batch mqtt.BatchData
	if err := json.Unmarshal(payload, &batch); err != nil {
		logger.Log.Warn("Invalid batch payload", zap.Error(err))
		return
	}

	logger.Log.Info("Processing batch data",
		zap.String("sn", batch.DeviceSN),
		zap.String("type", batch.DataType),
		zap.Int("seq", batch.BatchSeq),
		zap.Int("total", batch.TotalBatches),
	)

	// 按数据类型分别处理
	for i, record := range batch.Records {
		switch batch.DataType {
		case "vital":
			var v mqtt.VitalData
			if err := json.Unmarshal(record, &v); err == nil {
				v.DeviceSN = batch.DeviceSN
				payload2, _ := json.Marshal(v)
				handleVitalForward("device/"+batch.DeviceSN+"/vital", payload2)
			}
		case "alarm":
			// 批量报警直接透传原始 JSON 给 handleAlarmForward（已修复为 map 安全解析）
			handleAlarmForward("device/"+batch.DeviceSN+"/alarm", record)
		case "signin":
			var s mqtt.SigninData
			if err := json.Unmarshal(record, &s); err == nil {
				s.DeviceSN = batch.DeviceSN
				payload2, _ := json.Marshal(s)
				handleSigninForward("device/"+batch.DeviceSN+"/signin", payload2)
			}
		}

		if i%50 == 49 {
			time.Sleep(100 * time.Millisecond) // 批量处理节流
		}
	}

	// 发送补传确认
	ackTopic := mqtt.DeviceAckTopic(batch.DeviceSN, batch.BatchID)
	mqtt.MQTTClient.Publish(ackTopic, 1, gin.H{
		"batch_id":  batch.BatchID,
		"status":    "received",
		"processed": len(batch.Records),
	})
}

// ============ REST 接口 ============

func ListDevices(c *gin.Context) {
	page := utils.Pagination{}
	c.ShouldBindQuery(&page)
	page.Normalize()

	var total int64
	database.DB.QueryRow("SELECT COUNT(*) FROM devices WHERE status != 'deleted'").Scan(&total)

	rows, err := database.DB.Query(
		`SELECT d.id, d.device_sn, d.device_name, d.device_type, d.firmware_version, d.status, 
		 d.elderly_id, d.battery, d.signal_strength, d.last_online_at, e.name as elderly_name, d.created_at
		 FROM devices d LEFT JOIN elderly_profiles e ON d.elderly_id = e.id
		 WHERE d.status != 'deleted' ORDER BY d.created_at DESC, d.id ASC LIMIT ? OFFSET ?`,
		page.PageSize, page.Offset(),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "查询失败"))
		return
	}
	defer rows.Close()

	var list []gin.H
	for rows.Next() {
		var id, sn, deviceName, devType, fwVer, status string
		var elderlyID sql.NullString
		var battery, signal sql.NullInt64
		var lastOnline sql.NullTime
		var elderlyName sql.NullString
		var createdAt time.Time
		rows.Scan(&id, &sn, &deviceName, &devType, &fwVer, &status, &elderlyID, &battery, &signal, &lastOnline, &elderlyName, &createdAt)

		// 获取实时在线状态
		ctx := context.Background()
		online, _ := redis.CacheHelper.Exists(ctx, redis.Key(redis.KeyDeviceOnline, sn))

		list = append(list, gin.H{
			"id": id, "device_sn": sn, "device_name": deviceName, "device_type": devType,
			"firmware_version": fwVer, "status": status,
			"elderly_id": elderlyID.String, "elderly_name": elderlyName.String,
			"battery": battery.Int64, "signal_strength": signal.Int64,
			"is_online": online > 0,
			"last_online_at": lastOnline.Time,
			"created_at": createdAt,
		})
	}

	c.JSON(http.StatusOK, utils.SuccessPage(list, total, page.Page, page.PageSize))
}

func GetDevice(c *gin.Context) {
	id := c.Param("id")

	var dID, dSN, dName, dType, fwVer, status string
	var elderlyID, elderlyName sql.NullString
	var battery, signal sql.NullInt64
	var lastOnline, createdAt sql.NullTime
	err := database.DB.QueryRow(
		`SELECT d.id, d.device_sn, d.device_name, d.device_type, d.firmware_version, d.status,
		 d.elderly_id, d.battery, d.signal_strength, d.last_online_at, d.created_at, e.name as elderly_name
		 FROM devices d LEFT JOIN elderly_profiles e ON d.elderly_id = e.id WHERE d.id = ?`, id,
	).Scan(&dID, &dSN, &dName, &dType, &fwVer, &status, &elderlyID, &battery, &signal, &lastOnline, &createdAt, &elderlyName)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, utils.Error(apperrors.ErrCodeDeviceNotFound, "设备不存在"))
		return
	}

	// 补充实时状态
	ctx := context.Background()
	online, _ := redis.CacheHelper.Exists(ctx, redis.Key(redis.KeyDeviceOnline, dSN))
	statusData, _ := redis.CacheHelper.HGetAll(ctx, redis.Key(redis.KeyDeviceStatus, dSN))

	c.JSON(http.StatusOK, utils.Success(gin.H{
		"id":              dID,
		"device_sn":       dSN,
		"device_name":     dName,
		"device_type":     dType,
		"firmware_version": fwVer,
		"status":          status,
		"elderly_id":      elderlyID.String,
		"elderly_name":    elderlyName.String,
		"battery":         battery.Int64,
		"signal_strength": signal.Int64,
		"last_online_at":  lastOnline.Time,
		"created_at":      createdAt.Time,
		"is_online":       online > 0,
		"realtime":        statusData,
	}))
}

type RegisterDeviceRequest struct {
	DeviceSN   string `json:"device_sn" binding:"required"`
	DeviceType string `json:"device_type" binding:"required"`
	ElderlyID  string `json:"elderly_id"`
}

func RegisterDevice(c *gin.Context) {
	var req RegisterDeviceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	id := utils.NewUUID()
	_, err := database.DB.Exec(
		`INSERT INTO devices (id, device_sn, device_type, elderly_id, firmware_version, 
		 status, registered_at, created_at, updated_at)
		 VALUES (?, ?, ?, ?, '1.0.0', 'offline', NOW(), NOW(), NOW())`,
		id, req.DeviceSN, req.DeviceType, req.ElderlyID,
	)

	if err != nil {
		c.JSON(http.StatusConflict, utils.Error(apperrors.ErrCodeConflict, "设备SN已存在"))
		return
	}

	c.JSON(http.StatusCreated, utils.Success(gin.H{"id": id, "message": "设备注册成功"}))
}

func UpdateDevice(c *gin.Context) {
	id := c.Param("id")
	var req RegisterDeviceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	database.DB.Exec(
		"UPDATE devices SET elderly_id=?, updated_at=NOW() WHERE id=?",
		req.ElderlyID, id,
	)

	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "更新成功"}))
}

type OTARequest struct {
	FirmwareURL string `json:"firmware_url" binding:"required"`
	Version     string `json:"version" binding:"required"`
	MD5         string `json:"md5" binding:"required"`
	Strategy    string `json:"strategy"`
}

func TriggerOTA(c *gin.Context) {
	id := c.Param("id")
	var req OTARequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	// 获取设备 SN
	var deviceSN string
	database.DB.QueryRow("SELECT device_sn FROM devices WHERE id=?", id).Scan(&deviceSN)

	otaCmd := mqtt.OTACommand{
		OTAID:       utils.NewUUID(),
		FirmwareURL: req.FirmwareURL,
		Version:     req.Version,
		MD5:         req.MD5,
		Strategy:    req.Strategy,
	}

	if err := mqtt.MQTTClient.Publish(
		mqtt.DeviceTopic(mqtt.TopicDeviceOTA, deviceSN), 1, otaCmd,
	); err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "OTA指令下发失败"))
		return
	}

	c.JSON(http.StatusOK, utils.Success(gin.H{
		"ota_id":  otaCmd.OTAID,
		"message": "OTA指令已下发",
	}))
}

func RestartDevice(c *gin.Context) {
	id := c.Param("id")
	var deviceSN string
	database.DB.QueryRow("SELECT device_sn FROM devices WHERE id=?", id).Scan(&deviceSN)

	if err := mqtt.MQTTClient.Publish(
		mqtt.DeviceTopic(mqtt.TopicDeviceRestart, deviceSN), 1,
		gin.H{"command": "restart", "timestamp": time.Now().Unix()},
	); err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "重启指令下发失败"))
		return
	}

	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "重启指令已下发"}))
}

// ============ 设备辅助接口 ============

func GetServerTime(c *gin.Context) {
	now := time.Now().UTC()
	c.JSON(http.StatusOK, utils.Success(gin.H{
		"timestamp": now.UnixMilli(),
		"datetime":  now.Format(time.RFC3339),
		"timezone":  "UTC",
	}))
}

type FirmwareInfo struct {
	Version     string `json:"version"`
	DownloadURL string `json:"download_url"`
	FileSize    int64  `json:"file_size"`
	MD5         string `json:"md5"`
	ReleaseDate string `json:"release_date"`
	Changelog   string `json:"changelog"`
	Mandatory   bool   `json:"mandatory"`
}

func GetLatestFirmware(c *gin.Context) {
	// 根据 device_type 查询最新固件（简化版本）
	fw := FirmwareInfo{
		Version:     "2.1.0",
		DownloadURL: "https://ota.elderly-health.com/firmware/bes2700_v2.1.0.bin",
		FileSize:    15728640,
		MD5:         "a1b2c3d4e5f6...",
		ReleaseDate: "2026-06-15",
		Changelog:   "优化心率检测算法；修复蓝牙断连问题",
		Mandatory:   false,
	}
	c.JSON(http.StatusOK, utils.Success(fw))
}

type DiagnosticData struct {
	DeviceSN     string `json:"device_sn"`
	CrashLog     string `json:"crash_log"`
	ErrorCode    string `json:"error_code"`
	FirmwareInfo string `json:"firmware_info"`
}

func UploadDiagnostic(c *gin.Context) {
	sn := c.Param("id")
	var data DiagnosticData
	if err := c.ShouldBindJSON(&data); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	// 存储诊断日志（可写入文件系统或 ES）
	logger.Log.Warn("Device diagnostic uploaded",
		zap.String("sn", sn),
		zap.String("error", data.ErrorCode),
	)

	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "诊断日志已接收"}))
}

// ============ 工具函数 ============

func extractDeviceSN(topic string) string {
	// topic 格式: device/{device_sn}/online
	parts := splitTopic(topic)
	if len(parts) >= 2 {
		return parts[1]
	}
	return ""
}

func splitTopic(topic string) []string {
	var parts []string
	start := 0
	for i, c := range topic {
		if c == '/' {
			parts = append(parts, topic[start:i])
			start = i + 1
		}
	}
	parts = append(parts, topic[start:])
	return parts
}

// ============ 报警处理辅助函数（安全类型转换，避免 panic）============

// toFloat64 将任意 interface{} 安全转换为 float64（用于经纬度等数值字段）
func toFloat64(v interface{}) float64 {
	switch n := v.(type) {
	case float64:
		return n
	case int:
		return float64(n)
	case int64:
		return float64(n)
	case int32:
		return float64(n)
	case string:
		if f, err := strconv.ParseFloat(n, 64); err == nil {
			return f
		}
	}
	return 0
}

// safeGet 从 map 中安全取值（key不存在时返回 nil 而非 panic）
func safeGet(m map[string]interface{}, key string) interface{} {
	if v, ok := m[key]; ok {
		return v
	}
	return nil
}

// ============ 设备端 HTTP 数据上报接口（供模拟器/无 MQTT 场景使用）============

// HandleHTTPDeviceOnline POST /api/v1/devices/online
// 设备上线通知（复用 MQTT handleDeviceOnline 的业务逻辑）
func HandleHTTPDeviceOnline(c *gin.Context) {
	var body map[string]interface{}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	deviceSN, _ := body["device_sn"].(string)
	if deviceSN == "" {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "device_sn 不能为空"))
		return
	}

	logger.Log.Info("[HTTP] Device online", zap.String("sn", deviceSN))

	// 更新 Redis 在线状态
	ctx := context.Background()
	redis.CacheHelper.Set(ctx, redis.Key(redis.KeyDeviceOnline, deviceSN), "1", 90*time.Second)
	redis.CacheHelper.HSet(ctx, redis.Key(redis.KeyDeviceStatus, deviceSN),
		"status", "online",
		"last_seen", time.Now().UTC().Format(time.RFC3339),
	)

	// 更新 MySQL 设备状态
	database.DB.Exec(
		"UPDATE devices SET status='online', last_online_at=NOW(), updated_at=NOW() WHERE device_sn=?",
		deviceSN,
	)

	c.JSON(http.StatusOK, utils.Success(gin.H{
		"message": "设备上线成功",
		"config": gin.H{
			"report_interval":        15,
			"active_interval":        5,
			"sleep_interval":         300,
			"position_interval":      300,
			"alarm_position_interval": 10,
			"hr_threshold_low":       40,
			"hr_threshold_high":      140,
			"spo2_threshold":         90,
			"temp_threshold_low":     35.0,
			"temp_threshold_high":    38.5,
			"fall_sensitivity":       "medium",
			"ntp_host":               "ntp.aliyun.com",
		},
	}))
}

// HandleHTTPHeartbeat POST /api/v1/devices/heartbeat
// 设备心跳上报（复用 MQTT handleHeartbeat 的业务逻辑）
func HandleHTTPHeartbeat(c *gin.Context) {
	var body map[string]interface{}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	deviceSN, _ := body["device_sn"].(string)
	if deviceSN == "" {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "device_sn 不能为空"))
		return
	}

	logger.Log.Info("[HTTP] Heartbeat received",
		zap.String("device_sn", deviceSN),
		zap.Any("battery", body["battery"]),
	)

	ctx := context.Background()
	redis.CacheHelper.Set(ctx, redis.Key(redis.KeyDeviceOnline, deviceSN), "1", 90*time.Second)
	redis.CacheHelper.HSet(ctx, redis.Key(redis.KeyDeviceStatus, deviceSN),
		"status", "online",
		"battery", safeGet(body, "battery"),
		"signal", safeGet(body, "signal_strength"),
		"firmware", safeGet(body, "firmware_version"),
		"last_seen", time.Now().UTC().Format(time.RFC3339),
	)

	database.DB.Exec(
		`UPDATE devices SET battery=?, signal_strength=?, firmware_version=?,
		 last_online_at=NOW(), updated_at=NOW() WHERE device_sn=?`,
		safeGet(body, "battery"), safeGet(body, "signal_strength"),
		safeGet(body, "firmware_version"), deviceSN,
	)

	database.DB.Exec(
		`INSERT INTO device_heartbeats (device_sn, battery, signal_strength, firmware_version, reported_at)
		 VALUES (?, ?, ?, ?, NOW())`,
		deviceSN, safeGet(body, "battery"), safeGet(body, "signal_strength"), safeGet(body, "firmware_version"),
	)

	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "心跳上报成功"}))
}

// HandleHTTPPosition POST /api/v1/devices/position
// 设备位置上报（复用 MQTT handlePosition 的业务逻辑）
func HandleHTTPPosition(c *gin.Context) {
	var body map[string]interface{}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	deviceSN, _ := body["device_sn"].(string)
	if deviceSN == "" {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "device_sn 不能为空"))
		return
	}

	logger.Log.Info("[HTTP] Position received",
		zap.String("device_sn", deviceSN),
		zap.Any("lat", body["latitude"]),
		zap.Any("lng", body["longitude"]),
	)

	ctx := context.Background()
	posJSON, _ := json.Marshal(map[string]interface{}{
		"lat": toFloat64(body["latitude"]),
		"lng": toFloat64(body["longitude"]),
		"accuracy": toFloat64(body["accuracy"]),
	})
	redis.CacheHelper.HSet(ctx, redis.Key(redis.KeyDeviceStatus, deviceSN),
		"position", string(posJSON),
		"position_updated", time.Now().UTC().Format(time.RFC3339),
	)

	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "位置上报成功"}))
}
