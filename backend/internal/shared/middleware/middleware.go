package middleware

import (
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/time/rate"

	apperrors "elderly-health-backend/internal/shared/errors"
	"elderly-health-backend/internal/shared/redis"
)

// ============ JWT Claims ============

type Claims struct {
	UserID   string `json:"user_id"`
	Username string `json:"username"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

// ============ 认证中间件 ============

// JWTAuth JWT 认证中间件
func JWTAuth(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		tokenStr := extractToken(c)
		if tokenStr == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"code":    apperrors.ErrCodeUnauthorized,
				"message": "缺少认证令牌",
			})
			return
		}

		// 检查 Token 黑名单
		ctx := c.Request.Context()
		if redis.CacheHelper != nil {
			isMember, _ := redis.Client.SIsMember(ctx, redis.KeyTokenBlacklist, tokenStr).Result()
			if isMember {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
					"code":    apperrors.ErrCodeTokenInvalid,
					"message": "令牌已失效",
				})
				return
			}
		}

		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(secret), nil
		})

		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"code":    apperrors.ErrCodeTokenInvalid,
				"message": "令牌无效或已过期",
			})
			return
		}

		// 注入用户信息
		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("role", claims.Role)
		c.Next()
	}
}

// RequireRole 角色权限中间件
func RequireRole(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole, _ := c.Get("role")
		roleStr, ok := userRole.(string)
		if !ok {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"code":    apperrors.ErrCodeForbidden,
				"message": "无权访问",
			})
			return
		}

		for _, r := range roles {
			if roleStr == r {
				c.Next()
				return
			}
		}

		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
			"code":    apperrors.ErrCodeForbidden,
			"message": "角色无权限访问",
		})
	}
}

// extractToken 从 Header 提取 Token
func extractToken(c *gin.Context) string {
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		return ""
	}

	parts := strings.SplitN(authHeader, " ", 2)
	if len(parts) == 2 && strings.ToLower(parts[0]) == "bearer" {
		return parts[1]
	}

	return ""
}

// ============ 限流中间件 ============

// RateLimit IP 限流中间件
func RateLimit(rps int, burst int) gin.HandlerFunc {
	limiters := make(map[string]*rate.Limiter)

	return func(c *gin.Context) {
		ip := c.ClientIP()
		limiter, ok := limiters[ip]
		if !ok {
			limiter = rate.NewLimiter(rate.Limit(rps), burst)
			limiters[ip] = limiter
		}

		if !limiter.Allow() {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"code":    apperrors.ErrCodeTooManyRequest,
				"message": "请求过于频繁，请稍后再试",
			})
			return
		}
		c.Next()
	}
}

// ============ CORS 中间件 ============

func CORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, PATCH, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Accept, Authorization, X-Request-ID")
		c.Header("Access-Control-Max-Age", "86400")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}

// ============ 请求日志中间件 ============

func RequestLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery

		c.Next()

		latency := time.Since(start)
		statusCode := c.Writer.Status()

		if query != "" {
			path = path + "?" + query
		}

		gin.DefaultWriter.Write([]byte(
			formatLogLine(c.Request.Method, path, statusCode, latency, c.ClientIP()),
		))
	}
}

func formatLogLine(method, path string, statusCode int, latency time.Duration, clientIP string) string {
	return "[" + time.Now().Format(time.RFC3339) + "] " +
		method + " " + path + " " +
		"| " + string(rune(statusCode)) + " | " +
		latency.String() + " | " + clientIP + "\n"
}

// ============ 恢复中间件 ============

func Recovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
					"code":    apperrors.ErrCodeInternal,
					"message": "服务器内部错误",
				})
			}
		}()
		c.Next()
	}
}
