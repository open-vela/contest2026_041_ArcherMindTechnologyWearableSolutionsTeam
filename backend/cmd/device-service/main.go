package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"elderly-health-backend/internal/device"
	"elderly-health-backend/internal/shared/config"
	"elderly-health-backend/internal/shared/database"
	"elderly-health-backend/internal/shared/logger"
	"elderly-health-backend/internal/shared/middleware"
	"elderly-health-backend/internal/shared/mqtt"
	"elderly-health-backend/internal/shared/redis"
)

func main() {
	cfg, err := config.Load("")
	if err != nil {
		panic(fmt.Sprintf("Failed to load config: %v", err))
	}

	if err := logger.Init(cfg.Log.Level, cfg.Log.OutputPath); err != nil {
		panic(fmt.Sprintf("Failed to init logger: %v", err))
	}
	defer logger.Sync()

	if err := database.Init(&cfg.MySQL); err != nil {
		logger.Log.Fatal("Failed to init MySQL", zap.Error(err))
	}
	defer database.Close()

	if err := redis.Init(&cfg.Redis); err != nil {
		logger.Log.Fatal("Failed to init Redis", zap.Error(err))
	}
	defer redis.Close()
	redis.InitCache()

	// 初始化 MQTT
	if err := mqtt.Init(&cfg.MQTT); err != nil {
		logger.Log.Fatal("Failed to init MQTT", zap.Error(err))
	}
	defer mqtt.MQTTClient.Close()

	// 启动 MQTT 消息处理
	device.StartMQTTHandlers()

	gin.SetMode(cfg.Server.Mode)

	router := gin.New()
	router.Use(middleware.Recovery(), middleware.RequestLogger(), middleware.CORS())

	api := router.Group("/v1")
	device.RegisterRoutes(api, cfg.JWT.Secret)

	// 健康检查
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"mysql":  "UP",
			"redis":  "UP",
			"mqtt":   mqtt.MQTTClient.IsConnected(),
		})
	})

	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	logger.Log.Info("device-service starting", zap.String("addr", addr))

	go func() {
		if err := router.Run(addr); err != nil {
			logger.Log.Fatal("Failed to start server", zap.Error(err))
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Log.Info("device-service shutting down...")
}
