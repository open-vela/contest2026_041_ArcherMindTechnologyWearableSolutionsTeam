package main

import (
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"go.uber.org/zap"

	"elderly-health-backend/internal/shared/config"
	"elderly-health-backend/internal/shared/database"
	"elderly-health-backend/internal/shared/logger"
	"elderly-health-backend/internal/shared/mqtt"
	"elderly-health-backend/internal/shared/redis"
	"elderly-health-backend/internal/websocket"
)

func main() {
	// 初始化配置
	cfg, err := config.Load("")
	if err != nil {
		panic(fmt.Sprintf("Failed to load config: %v", err))
	}

	// 覆盖端口为 8012（WebSocket 服务专用）
	cfg.Server.Port = 8012

	// 初始化日志
	if err := logger.Init(cfg.Log.Level, cfg.Log.OutputPath); err != nil {
		panic(fmt.Sprintf("Failed to init logger: %v", err))
	}
	defer logger.Sync()

	// 初始化 MySQL（WebSocket 服务需要查库获取用户信息等）
	if err := database.Init(&cfg.MySQL); err != nil {
		logger.Log.Fatal("Failed to init MySQL", zap.Error(err))
	}
	defer database.Close()

	// 初始化 Redis
	if err := redis.Init(&cfg.Redis); err != nil {
		logger.Log.Fatal("Failed to init Redis", zap.Error(err))
	}
	defer redis.Close()
	redis.InitCache()

	// 设置唯一 MQTT ClientID（避免与其他服务冲突）
	cfg.MQTT.ClientID = fmt.Sprintf("%s-ws-%d", cfg.MQTT.ClientID, 8012)
	logger.Log.Info("Using unique MQTT client_id", zap.String("client_id", cfg.MQTT.ClientID))

	// 初始化 MQTT（用于订阅设备消息并桥接到 WebSocket）
	if err := mqtt.Init(&cfg.MQTT); err != nil {
		logger.Log.Fatal("Failed to init MQTT", zap.Error(err))
	}
	defer mqtt.MQTTClient.Close()

	logger.Log.Info("websocket-service starting",
		zap.Int("port", cfg.Server.Port),
		zap.String("mqtt_broker", cfg.MQTT.Broker),
	)

	// 启动 WebSocket Hub（包含 MQTT 订阅桥接）
	wsHub := websocket.StartHub(cfg.JWT.Secret)

	// 注册路由
	mux := http.NewServeMux()
	mux.HandleFunc("/ws", websocket.HandleWebSocket)

	// 健康检查端点
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(fmt.Sprintf(`{
			"status": "UP",
			"ws_connections": %d,
			"mqtt_connected": %v,
			"mysql": "UP",
			"redis": "UP"
		}`, wsHub.GetConnectedClientsCount(), mqtt.MQTTClient.IsConnected())))
	})

	// 启动 HTTP 服务器
	server := &http.Server{
		Addr:    fmt.Sprintf(":%d", cfg.Server.Port),
		Handler: mux,
	}

	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Log.Fatal("Failed to start websocket-service", zap.Error(err))
		}
	}()

	// 优雅关闭
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Log.Info("websocket-service shutting down...")
	if wsHub != nil {
		wsHub.Stop()
		logger.Log.Info("WebSocket Hub stopped")
	}
	server.Close()
	logger.Log.Info("websocket-service stopped gracefully")
}
