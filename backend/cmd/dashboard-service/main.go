package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"elderly-health-backend/internal/dashboard"
	"elderly-health-backend/internal/shared/config"
	"elderly-health-backend/internal/shared/database"
	"elderly-health-backend/internal/shared/logger"
	"elderly-health-backend/internal/shared/middleware"
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
	router.Use(middleware.Recovery(), middleware.RequestLogger(), middleware.CORS())
	api := router.Group("/v1")
	dashboard.RegisterRoutes(api, cfg.JWT.Secret)

	router.GET("/health", func(c *gin.Context) { c.JSON(200, gin.H{"status": "UP"}) })
	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	logger.Log.Info("dashboard-service starting", zap.String("addr", addr))
	go router.Run(addr)

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
}
