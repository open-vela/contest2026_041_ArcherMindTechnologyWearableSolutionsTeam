package redis

import (
	"context"
	"fmt"
	"time"

	goredis "github.com/redis/go-redis/v9"
	"go.uber.org/zap"

	"elderly-health-backend/internal/shared/config"
	"elderly-health-backend/internal/shared/logger"
)

var Client *goredis.Client

// Init 初始化 Redis 客户端
func Init(cfg *config.RedisConfig) error {
	Client = goredis.NewClient(&goredis.Options{
		Addr:     cfg.Addr(),
		Password: cfg.Password,
		DB:       cfg.DB,
		PoolSize: cfg.PoolSize,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := Client.Ping(ctx).Err(); err != nil {
		return fmt.Errorf("ping redis failed: %w", err)
	}

	logger.Log.Info("Redis connected successfully",
		zap.String("addr", cfg.Addr()),
		zap.Int("db", cfg.DB),
	)

	return nil
}

// Close 关闭 Redis 连接
func Close() {
	if Client != nil {
		_ = Client.Close()
		logger.Log.Info("Redis connection closed")
	}
}

// Cache 缓存辅助函数
type Cache struct {
	Client *goredis.Client
}

var CacheHelper *Cache

func InitCache() {
	CacheHelper = &Cache{Client: Client}
}

// Set 设置缓存
func (c *Cache) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	return c.Client.Set(ctx, key, value, ttl).Err()
}

// Get 获取缓存
func (c *Cache) Get(ctx context.Context, key string) (string, error) {
	return c.Client.Get(ctx, key).Result()
}

// Del 删除缓存
func (c *Cache) Del(ctx context.Context, keys ...string) error {
	return c.Client.Del(ctx, keys...).Err()
}

// Exists 检查 key 是否存在
func (c *Cache) Exists(ctx context.Context, keys ...string) (int64, error) {
	return c.Client.Exists(ctx, keys...).Result()
}

// SetJSON 缓存 JSON 对象
func (c *Cache) SetJSON(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	return c.Client.Set(ctx, key, value, ttl).Err()
}

// HSet 设置 Hash 字段
func (c *Cache) HSet(ctx context.Context, key string, values ...interface{}) error {
	return c.Client.HSet(ctx, key, values...).Err()
}

// HGet 获取 Hash 字段
func (c *Cache) HGet(ctx context.Context, key, field string) (string, error) {
	return c.Client.HGet(ctx, key, field).Result()
}

// HGetAll 获取 Hash 全部字段
func (c *Cache) HGetAll(ctx context.Context, key string) (map[string]string, error) {
	return c.Client.HGetAll(ctx, key).Result()
}

// ZAdd 添加 Sorted Set 成员
func (c *Cache) ZAdd(ctx context.Context, key string, members ...goredis.Z) error {
	return c.Client.ZAdd(ctx, key, members...).Err()
}

// ZRevRange 获取 Sorted Set 范围（降序）
func (c *Cache) ZRevRange(ctx context.Context, key string, start, stop int64) ([]string, error) {
	return c.Client.ZRevRange(ctx, key, start, stop).Result()
}

// Lock 获取分布式锁
func (c *Cache) Lock(ctx context.Context, key string, ttl time.Duration) (bool, error) {
	return c.Client.SetNX(ctx, "lock:"+key, "1", ttl).Result()
}

// Unlock 释放分布式锁
func (c *Cache) Unlock(ctx context.Context, key string) error {
	return c.Client.Del(ctx, "lock:"+key).Err()
}

// Incr 自增计数器
func (c *Cache) Incr(ctx context.Context, key string) (int64, error) {
	return c.Client.Incr(ctx, key).Result()
}

// Expire 设置过期时间
func (c *Cache) Expire(ctx context.Context, key string, ttl time.Duration) error {
	return c.Client.Expire(ctx, key, ttl).Err()
}

// ============ 预定义缓存 Key 生成器 ============

const (
	KeyVitalSigns      = "vital:latest:%s"    // vital:latest:{elderly_id}
	KeyDeviceOnline    = "device:online:%s"    // device:online:{device_sn}
	KeyDeviceStatus    = "device:status:%s"    // device:status:{device_sn}
	KeyAlarmQueue      = "alarm:queue"         // Sorted Set: score=severity*1e12+timestamp
	KeySigninToday     = "signin:today:%s"     // signin:today:{elderly_id}
	KeyWSConnMap       = "ws:conn:%s"          // ws:conn:{user_id}
	KeyTokenBlacklist  = "token:blacklist"     // Set
	KeyAdminPerms      = "admin:perms:%s"      // admin:perms:{user_id} Hash
	KeyLoginFails      = "login:fails:%s:%s"   // login:fails:{username}:{ip}
	KeyRateLimit       = "ratelimit:%s:%s:%d"  // ratelimit:{endpoint}:{ip}:{window_sec}
)

// Key 生成带格式的缓存 key
func Key(format string, args ...interface{}) string {
	return fmt.Sprintf(format, args...)
}
