package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/robfig/cron/v3"
	"go.uber.org/zap"

	"elderly-health-backend/internal/alarm"
	"elderly-health-backend/internal/shared/config"
	"elderly-health-backend/internal/shared/database"
	"elderly-health-backend/internal/shared/logger"
	"elderly-health-backend/internal/shared/middleware"
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

	// 启动报警队列消费者
	alarm.StartAlarmQueueConsumer()

	// 启动定时任务（报警升级、超时检查）
	c := cron.New()
	c.AddFunc("@every 30s", alarm.CheckEscalation) // 每 30s 检查报警超时升级
	c.AddFunc("@every 5m", alarm.CleanupResolvedAlarms) // 每 5 分钟清理已解决报警
	c.Start()
	defer c.Stop()

	gin.SetMode(cfg.Server.Mode)

	router := gin.New()
	router.Use(middleware.Recovery(), middleware.RequestLogger(), middleware.CORS())

	api := router.Group("/v1")
	alarm.RegisterRoutes(api, cfg.JWT.Secret)

	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "UP", "timestamp": time.Now()})
	})

	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	logger.Log.Info("alarm-service starting", zap.String("addr", addr))

	go func() {
		if err := router.Run(addr); err != nil {
			logger.Log.Fatal("Failed to start server", zap.Error(err))
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Log.Info("alarm-service shutting down...")
}
