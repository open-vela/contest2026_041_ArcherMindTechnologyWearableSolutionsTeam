package utils

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/golang-jwt/jwt/v5"
)

// ============ UUID ============

func NewUUID() string {
	return uuid.New().String()
}

// ============ 密码 ============

// HashPassword bcrypt 加密
func HashPassword(password string, cost int) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), cost)
	return string(bytes), err
}

// CheckPassword 验证密码
func CheckPassword(passwordHash, password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(password))
	return err == nil
}

// ============ Token ============

// GenerateToken 生成 JWT Token
func GenerateToken(userID, username, role, secret string, ttl time.Duration) (string, error) {
	return generateJWT(userID, username, role, secret, ttl, "access")
}

// GenerateRefreshToken 生成 Refresh Token
func GenerateRefreshToken(userID, username, role, secret string, ttl time.Duration) (string, error) {
	return generateJWT(userID, username, role, secret, ttl, "refresh")
}

func generateJWT(userID, username, role, secret string, ttl time.Duration, tokenType string) (string, error) {
	now := time.Now()
	claims := jwt.MapClaims{
		"user_id":  userID,
		"username": username,
		"role":     role,
		"type":     tokenType,
		"jti":      NewUUID(),
		"iat":      now.Unix(),
		"exp":      now.Add(ttl).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// ============ 哈希 ============

// SHA256Hash 计算 SHA256 哈希
func SHA256Hash(data string) string {
	h := sha256.Sum256([]byte(data))
	return hex.EncodeToString(h[:])
}

// ============ 随机字符串 ============

// RandomString 生成随机字符串
func RandomString(n int) (string, error) {
	const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	bytes := make([]byte, n)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	for i, b := range bytes {
		bytes[i] = letters[b%byte(len(letters))]
	}
	return string(bytes), nil
}

// ============ 手机号校验 ============

var phoneRegex = regexp.MustCompile(`^1[3-9]\d{9}$`)

func ValidatePhone(phone string) bool {
	return phoneRegex.MatchString(phone)
}

// ============ 脱敏 ============

// MaskPhone 手机号脱敏
func MaskPhone(phone string) string {
	if len(phone) < 7 {
		return phone
	}
	return phone[:3] + "****" + phone[len(phone)-4:]
}

// MaskName 姓名脱敏
func MaskName(name string) string {
	if len(name) <= 1 {
		return name
	}
	runes := []rune(name)
	return string(runes[0]) + strings.Repeat("*", len(runes)-1)
}

// ============ 时间工具 ============

// StartOfWeek 获取本周一 00:00:00 (UTC)
func StartOfWeek(t time.Time) time.Time {
	weekday := t.Weekday()
	if weekday == time.Sunday {
		weekday = 7
	}
	return time.Date(t.Year(), t.Month(), t.Day()-int(weekday)+1, 0, 0, 0, 0, time.UTC)
}

// EndOfWeek 获取本周日 23:59:59
func EndOfWeek(t time.Time) time.Time {
	return StartOfWeek(t).AddDate(0, 0, 7).Add(-time.Second)
}

// StartOfDay 获取当天 00:00:00
func StartOfDay(t time.Time) time.Time {
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, t.Location())
}

// EndOfDay 获取当天 23:59:59
func EndOfDay(t time.Time) time.Time {
	return StartOfDay(t).AddDate(0, 0, 1).Add(-time.Second)
}

// ============ 分页 ============

type Pagination struct {
	Page     int `json:"page" form:"page"`
	PageSize int `json:"page_size" form:"page_size"`
}

func (p *Pagination) Normalize() {
	if p.Page < 1 {
		p.Page = 1
	}
	if p.PageSize < 1 || p.PageSize > 100 {
		p.PageSize = 20
	}
}

func (p *Pagination) Offset() int {
	return (p.Page - 1) * p.PageSize
}

// ============ 响应格式 ============

type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

type PageResponse struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
	Total   int64       `json:"total"`
	Page    int         `json:"page"`
	PageSize int        `json:"page_size"`
}

func Success(data interface{}) Response {
	return Response{Code: 0, Message: "success", Data: data}
}

func SuccessPage(data interface{}, total int64, page, pageSize int) PageResponse {
	return PageResponse{Code: 0, Message: "success", Data: data, Total: total, Page: page, PageSize: pageSize}
}

func Error(code int, message string) Response {
	return Response{Code: code, Message: message}
}

// ============ 报警等级工具 ============

// SeverityScore 将报警等级转为排序分数
func SeverityScore(level string) int {
	switch level {
	case "P0":
		return 4
	case "P1":
		return 3
	case "P2":
		return 2
	case "P3":
		return 1
	default:
		return 0
	}
}

// ============ 健康评分 ============

// CalculateHealthScore 根据异常事件数计算健康评分
func CalculateHealthScore(abnormalEvents int) int {
	if abnormalEvents == 0 {
		return 100
	}
	if abnormalEvents <= 2 {
		return 80
	}
	if abnormalEvents <= 5 {
		return 60
	}
	if abnormalEvents <= 10 {
		return 40
	}
	return 20
}

// ============ 格式化 ============

// FormatWeekLabel 格式化周标签
func FormatWeekLabel(t time.Time) string {
	year, week := t.ISOWeek()
	start := StartOfWeek(t)
	return fmt.Sprintf("%d-W%02d (%s~%s)", year, week, start.Format("01-02"), EndOfWeek(t).Format("01-02"))
}

// ReportWeek 生成周报标识
func ReportWeek(t time.Time) string {
	year, week := t.ISOWeek()
	return fmt.Sprintf("%d-W%02d", year, week)
}
