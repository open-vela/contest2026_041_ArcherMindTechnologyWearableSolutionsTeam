package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"elderly-health-backend/internal/shared/config"
	"elderly-health-backend/internal/shared/database"
	"elderly-health-backend/internal/shared/logger"
	"elderly-health-backend/internal/shared/redis"
)

func main() {
	cfg, _ := config.Load("")
	logger.Init(cfg.Log.Level, cfg.Log.OutputPath)
	defer logger.Sync()
	database.Init(&cfg.MySQL)
	defer database.Close()
	redis.Init(&cfg.Redis)
	defer redis.Close()
	redis.InitCache()

	gin.SetMode(cfg.Server.Mode)
	router := gin.New()

	// 通知服务 - Webhook 回调接口
	router.POST("/v1/webhooks/sms/callback", SMSCallback)
	router.POST("/v1/webhooks/phone/callback", PhoneCallback)
	router.POST("/v1/webhooks/emergency/callback", EmergencyCallback)

	router.GET("/health", func(c *gin.Context) { c.JSON(200, gin.H{"status": "UP"}) })

	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	logger.Log.Info("notify-service starting", zap.String("addr", addr))
	go router.Run(addr)

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
}

func SMSCallback(c *gin.Context) {
	var req struct {
		Phone   string `json:"phone"`
		Status  string `json:"status"`
		MessageID string `json:"message_id"`
	}
	c.ShouldBindJSON(&req)

	// 更新通知状态
	database.DB.Exec(
		`UPDATE notification_logs SET status=?, delivered_at=NOW() WHERE external_ref=?`,
		req.Status, req.MessageID,
	)
	c.JSON(200, gin.H{"code": 0})
}

func PhoneCallback(c *gin.Context) {
	var req struct {
		CallID   string `json:"call_id"`
		Status   string `json:"status"`
		Duration int    `json:"duration"`
	}
	c.ShouldBindJSON(&req)

	database.DB.Exec(
		`UPDATE notification_logs SET status=?, delivered_at=NOW() WHERE external_ref=?`,
		req.Status, req.CallID,
	)
	c.JSON(200, gin.H{"code": 0})
}

func EmergencyCallback(c *gin.Context) {
	var req struct {
		AmbulanceID string `json:"ambulance_id"`
		Status      string `json:"status"`
		ETAMinutes  int    `json:"eta_minutes"`
	}
	c.ShouldBindJSON(&req)

	logger.Log.Info("Emergency callback received",
		zap.String("ambulance", req.AmbulanceID),
		zap.String("status", req.Status),
		zap.Int("eta", req.ETAMinutes),
	)

	c.JSON(200, gin.H{"code": 0, "acknowledged": true})
}
