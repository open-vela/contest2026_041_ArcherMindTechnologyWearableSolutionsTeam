package vital

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"elderly-health-backend/internal/shared/database"
	apperrors "elderly-health-backend/internal/shared/errors"
	"elderly-health-backend/internal/shared/logger"
	"elderly-health-backend/internal/shared/middleware"
	"elderly-health-backend/internal/shared/redis"
	"elderly-health-backend/internal/shared/utils"
)

func RegisterRoutes(r *gin.RouterGroup, jwtSecret string) {
	auth := r.Group("")
	auth.Use(middleware.JWTAuth(jwtSecret))
	{
		auth.GET("/vitals/realtime/:elderly_id", GetRealtimeVitals)
		auth.GET("/vitals/history/:elderly_id", GetVitalsHistory)
		auth.GET("/vitals/trend/:elderly_id", GetVitalsTrend)
	}

	// 设备端体征上报（无需 JWT，模拟器调试用）
	r.POST("/vitals/sign", HandleVitalSignReport)
}

func GetRealtimeVitals(c *gin.Context) {
	elderlyID := c.Param("elderly_id")

	// 从 Redis 缓存获取最新体征
	// 简化版本：返回数据库最新一条
	row := database.DB.QueryRow(
		`SELECT heart_rate, spo2, temperature, steps, activity_level, posture, reported_at
		 FROM vital_signs WHERE elderly_id=? ORDER BY reported_at DESC LIMIT 1`, elderlyID,
	)

	var hr, steps, activity int
	var spo2, temp, confidence float64
	var posture string
	var reportedAt time.Time
	row.Scan(&hr, &spo2, &temp, &steps, &activity, &posture, &reportedAt)

	c.JSON(http.StatusOK, utils.Success(gin.H{
		"elderly_id":    elderlyID,
		"heart_rate":    hr,
		"spo2":          spo2,
		"temperature":   temp,
		"steps":         steps,
		"activity_level": activity,
		"posture":       posture,
		"confidence_hr": confidence,
		"reported_at":   reportedAt,
	}))
}

func GetVitalsHistory(c *gin.Context) {
	elderlyID := c.Param("elderly_id")
	start := c.DefaultQuery("start", time.Now().Add(-24*time.Hour).Format(time.RFC3339))
	end := c.DefaultQuery("end", time.Now().Format(time.RFC3339))

	rows, err := database.DB.Query(
		`SELECT heart_rate, spo2, temperature, steps, reported_at
		 FROM vital_signs WHERE elderly_id=? AND reported_at BETWEEN ? AND ?
		 ORDER BY reported_at LIMIT 1000`, elderlyID, start, end,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(10001, "查询失败"))
		return
	}
	defer rows.Close()

	var history []gin.H
	for rows.Next() {
		var hr, steps int
		var spo2, temp float64
		var ts time.Time
		rows.Scan(&hr, &spo2, &temp, &steps, &ts)
		history = append(history, gin.H{
			"heart_rate": hr, "spo2": spo2, "temperature": temp,
			"steps": steps, "timestamp": ts,
		})
	}

	c.JSON(http.StatusOK, utils.Success(history))
}

func GetVitalsTrend(c *gin.Context) {
	elderlyID := c.Param("elderly_id")

	rows, _ := database.DB.Query(
		`SELECT hour_bucket, hour_slot, avg_heart_rate, avg_spo2, total_steps
		 FROM vital_signs_hourly WHERE elderly_id=?
		 AND hour_bucket >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
		 ORDER BY hour_bucket, hour_slot`, elderlyID,
	)
	defer rows.Close()

	var trend []gin.H
	for rows.Next() {
		var bucket string
		var slot int
		var avgHR, avgSpO2 float64
		var steps int
		rows.Scan(&bucket, &slot, &avgHR, &avgSpO2, &steps)
		trend = append(trend, gin.H{
			"date": bucket, "hour": slot,
			"avg_heart_rate": avgHR, "avg_spo2": avgSpO2, "total_steps": steps,
		})
	}

	c.JSON(http.StatusOK, utils.Success(trend))
}

// HandleVitalSignReport POST /api/v1/vitals/sign
// 设备端体征数据 HTTP 上报（模拟器调试用）
func HandleVitalSignReport(c *gin.Context) {
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

	logger.Log.Info("[HTTP] Vital sign received",
		zap.String("device_sn", deviceSN),
		zap.Any("heart_rate", body["heart_rate"]),
		zap.Any("spo2", body["spo2"]),
		zap.Any("temperature", body["temperature"]),
	)

	// 通过 device_sn 查找 elderly_id
	elderlyID, _ := body["elderly_id"].(string)
	if elderlyID == "" {
		database.DB.QueryRow(
			"SELECT elderly_id FROM devices WHERE device_sn=? AND status != 'deleted'",
			deviceSN,
		).Scan(&elderlyID)
	}

	// 写入 MySQL vital_signs 表
	if elderlyID != "" {
		database.DB.Exec(
			`INSERT INTO vital_signs (elderly_id, device_id, heart_rate, spo2, temperature,
			 steps, activity_level, posture, reported_at, created_at)
			 VALUES (?, ?, ?, ?, ?, ?, ?, ?, FROM_UNIXTIME(?/1000), NOW())`,
			elderlyID, deviceSN,
			safeGetFloat(body, "heart_rate"), safeGetFloat(body, "spo2"), safeGetFloat(body, "temperature"),
			safeGetFloat(body, "steps"), safeGetFloat(body, "activity_level"), safeGetString(body, "posture"),
			safeGetFloat(body, "timestamp"),
		)
	}

	// 更新 Redis 最新体征缓存
	ctx := context.Background()
	if elderlyID != "" {
		latestKey := redis.Key(redis.KeyVitalSigns, elderlyID)
		vitalJSON, _ := json.Marshal(body)
		redis.CacheHelper.Set(ctx, latestKey, string(vitalJSON), 2*time.Minute)
	}

	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "体征数据上报成功"}))
}

func safeGetFloat(m map[string]interface{}, key string) interface{} {
	if v, ok := m[key]; ok {
		switch n := v.(type) {
		case float64:
			return n
		case int:
			return float64(n)
		case int64:
			return float64(n)
		}
		return v
	}
	return nil
}

func safeGetString(m map[string]interface{}, key string) interface{} {
	if v, ok := m[key]; ok {
		return v
	}
	return nil
}
