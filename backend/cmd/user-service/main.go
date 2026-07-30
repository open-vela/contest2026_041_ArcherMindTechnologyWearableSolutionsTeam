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
	"elderly-health-backend/internal/shared/middleware"
	"elderly-health-backend/internal/shared/redis"
	"elderly-health-backend/internal/user"
)

func main() {
	// 1. 加载配置
	cfg, err := config.Load("")
	if err != nil {
		panic(fmt.Sprintf("Failed to load config: %v", err))
	}

	// 2. 初始化日志
	if err := logger.Init(cfg.Log.Level, cfg.Log.OutputPath); err != nil {
		panic(fmt.Sprintf("Failed to init logger: %v", err))
	}
	defer logger.Sync()

	// 3. 初始化数据库
	if err := database.Init(&cfg.MySQL); err != nil {
		logger.Log.Fatal("Failed to init MySQL", zap.Error(err))
	}
	defer database.Close()

	// 4. 初始化 Redis
	if err := redis.Init(&cfg.Redis); err != nil {
		logger.Log.Fatal("Failed to init Redis", zap.Error(err))
	}
	defer redis.Close()

	redis.InitCache()

	// 5. 设置 Gin 模式
	gin.SetMode(cfg.Server.Mode)

	// 6. 创建路由
	router := gin.New()
	router.Use(middleware.Recovery(), middleware.RequestLogger(), middleware.CORS())
	router.Use(middleware.RateLimit(100, 200))

	// 7. 注册路由
	api := router.Group("/v1")
	user.RegisterRoutes(api, cfg.JWT.Secret)

	// 健康检查
	router.GET("/health", func(c *gin.Context) {
		dbOk := database.HealthCheck() == nil
		redisOk := redis.Client.Ping(c.Request.Context()).Err() == nil

		status := 200
		if !dbOk || !redisOk {
			status = 503
		}

		c.JSON(status, gin.H{
			"status":  status,
			"mysql":   statusStr(dbOk),
			"redis":   statusStr(redisOk),
		})
	})

	// 8. 启动服务
	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	logger.Log.Info("user-service starting", zap.String("addr", addr))

	go func() {
		if err := router.Run(addr); err != nil {
			logger.Log.Fatal("Failed to start server", zap.Error(err))
		}
	}()

	// 9. 优雅退出
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Log.Info("user-service shutting down...")
}

func statusStr(ok bool) string {
	if ok {
		return "UP"
	}
	return "DOWN"
}
