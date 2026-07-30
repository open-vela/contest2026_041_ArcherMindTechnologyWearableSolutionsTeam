package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
	"github.com/robfig/cron/v3"
	"go.uber.org/zap"

	"elderly-health-backend/internal/shared/config"
	"elderly-health-backend/internal/shared/database"
	"elderly-health-backend/internal/shared/logger"
	"elderly-health-backend/internal/shared/middleware"
	"elderly-health-backend/internal/shared/redis"
	"elderly-health-backend/internal/signin"
)

func main() {
	cfg, err := config.Load("")
	if err != nil {
		panic(fmt.Sprintf("Failed to load config: %v", err))
	}
	logger.Init(cfg.Log.Level, cfg.Log.OutputPath)
	defer logger.Sync()
	database.Init(&cfg.MySQL)
	defer database.Close()
	redis.Init(&cfg.Redis)
	defer redis.Close()
	redis.InitCache()

	// 定时任务：每日签到调度
	c := cron.New()
	c.AddFunc("0 8 * * *", signin.DailySigninDispatch)     // 每天 08:00 推送签到提醒
	c.AddFunc("30 8 * * *", signin.SecondReminder)           // 08:30 二次提醒
	c.AddFunc("0 9 * * *", signin.NotifyFamily)               // 09:00 通知子女
	c.AddFunc("0 10 * * *", signin.PhoneCallCheck)            // 10:00 电话催签
	c.Start()
	defer c.Stop()

	gin.SetMode(cfg.Server.Mode)
	router := gin.New()
	router.Use(middleware.Recovery(), middleware.RequestLogger(), middleware.CORS())
	api := router.Group("/v1")
	signin.RegisterRoutes(api, cfg.JWT.Secret)

	router.GET("/health", func(c *gin.Context) { c.JSON(200, gin.H{"status": "UP"}) })

	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	logger.Log.Info("signin-service starting", zap.String("addr", addr))
	go router.Run(addr)

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Log.Info("signin-service shutting down...")
}
