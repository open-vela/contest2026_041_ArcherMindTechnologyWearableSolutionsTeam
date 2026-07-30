package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

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

	// 急救联动服务接口
	router.POST("/v1/emergency/call", InitiateEmergencyCall)
	router.GET("/v1/emergency/status/:ambulance_id", TrackEmergency)

	router.GET("/health", func(c *gin.Context) { c.JSON(200, gin.H{"status": "UP"}) })

	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	logger.Log.Info("emergency-service starting", zap.String("addr", addr))
	go router.Run(addr)

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
}

type EmergencyRequest struct {
	ElderlyID string  `json:"elderly_id" binding:"required"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Address   string  `json:"address"`
	Phone     string  `json:"phone"`
	Condition string  `json:"condition"`
}

func InitiateEmergencyCall(c *gin.Context) {
	var req EmergencyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"code": 10002, "message": "参数错误"})
		return
	}

	logger.Log.Error("EMERGENCY CALL INITIATED",
		zap.String("elderly", req.ElderlyID),
		zap.String("address", req.Address),
		zap.String("condition", req.Condition),
	)

	// 返回模拟救援信息
	c.JSON(200, gin.H{
		"code":    0,
		"message": "急救已派出",
		"data": gin.H{
			"ambulance_id": "AMB-" + fmt.Sprintf("%d", 100000+time.Now().Unix()%99999),
			"status":       "dispatched",
			"eta_minutes":  15,
			"hospital":     "XX市人民医院",
			"contact":      "13800000120",
		},
	})
}

func TrackEmergency(c *gin.Context) {
	c.JSON(200, gin.H{
		"code": 0,
		"data": gin.H{
			"ambulance_id": c.Param("ambulance_id"),
			"status":       "en_route",
			"eta_minutes":  5,
			"location":     gin.H{"lat": 30.5, "lng": 104.0},
		},
	})
}
