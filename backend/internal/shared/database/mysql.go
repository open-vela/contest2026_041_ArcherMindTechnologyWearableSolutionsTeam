package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"go.uber.org/zap"

	"elderly-health-backend/internal/shared/config"
	"elderly-health-backend/internal/shared/logger"
)

var DB *sql.DB

// Init 初始化 MySQL 连接池
func Init(cfg *config.MySQLConfig) error {
	var err error
	DB, err = sql.Open("mysql", cfg.DSN())
	if err != nil {
		return fmt.Errorf("open mysql failed: %w", err)
	}

	DB.SetMaxOpenConns(cfg.MaxOpenConns)
	DB.SetMaxIdleConns(cfg.MaxIdleConns)
	DB.SetConnMaxLifetime(cfg.ConnMaxLifetime)

	// 健康检查
	if err = DB.Ping(); err != nil {
		return fmt.Errorf("ping mysql failed: %w", err)
	}

	logger.Log.Info("MySQL connected successfully",
		zap.String("host", cfg.Host),
		zap.Int("port", cfg.Port),
		zap.String("database", cfg.Database),
	)

	// 自动执行数据库补丁迁移
	if err := RunPatches(); err != nil {
		logger.Log.Warn("Database patch migration warning (non-critical)", zap.Error(err))
	}

	return nil
}

// RunPatches 自动执行数据库补丁迁移（添加缺失的列和表）
func RunPatches() error {
	if DB == nil {
		return nil
	}

	// 安全添加列：先检查列是否存在
	addColumnIfNotExists := func(table, column, definition string) {
		var count int
		err := DB.QueryRow(
			`SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
			table, column,
		).Scan(&count)
		if err == nil && count == 0 {
			if _, err := DB.Exec(fmt.Sprintf("ALTER TABLE %s ADD COLUMN %s %s", table, column, definition)); err != nil {
				logger.Log.Debug("Failed to add column", zap.String("table", table), zap.String("column", column), zap.Error(err))
			} else {
				logger.Log.Info("Added missing column", zap.String("table", table), zap.String("column", column))
			}
		}
	}

	addColumnIfNotExists("elderly_profiles", "community_name", "VARCHAR(128) COMMENT '社区名称' AFTER community_id")
	addColumnIfNotExists("devices", "device_name", "VARCHAR(128) COMMENT '设备名称' AFTER device_sn")
	addColumnIfNotExists("admin_audit_logs", "resource_name", "VARCHAR(128) COMMENT '资源名称' AFTER resource_type")

	// 4. 创建 system_config 表（如果不存在）
	DB.Exec(`CREATE TABLE IF NOT EXISTS system_config (
		id                          INT PRIMARY KEY DEFAULT 1,
		system_name                 VARCHAR(128) DEFAULT '智慧养老照护平台',
		signin_start_time           VARCHAR(8) DEFAULT '06:00' COMMENT '签到开始时间',
		signin_end_time             VARCHAR(8) DEFAULT '10:00' COMMENT '签到截止时间',
		signin_reminder_interval    INT DEFAULT 30 COMMENT '签到提醒间隔(分钟)',
		signin_escalation_timeout   INT DEFAULT 60 COMMENT '签到超时升级(分钟)',
		alarm_p0_response_seconds   INT DEFAULT 300 COMMENT 'P0报警响应时限(秒)',
		alarm_p1_escalation_minutes INT DEFAULT 15 COMMENT 'P1报警升级时限(分钟)',
		heart_rate_low              VARCHAR(16) DEFAULT '60' COMMENT '心率下限',
		heart_rate_high             VARCHAR(16) DEFAULT '100' COMMENT '心率上限',
		blood_oxygen_low            VARCHAR(16) DEFAULT '90' COMMENT '血氧下限',
		temperature_low             VARCHAR(16) DEFAULT '36.0' COMMENT '体温下限',
		temperature_high            VARCHAR(16) DEFAULT '37.5' COMMENT '体温上限',
		notification_sms            TINYINT(1) DEFAULT 1 COMMENT '短信通知',
		notification_phone          TINYINT(1) DEFAULT 1 COMMENT '电话通知',
		notification_push           TINYINT(1) DEFAULT 1 COMMENT 'APP推送',
		notification_wechat         TINYINT(1) DEFAULT 0 COMMENT '微信通知',
		updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表'`)

	// 初始化默认配置数据
	DB.Exec(`INSERT IGNORE INTO system_config (id) VALUES (1)`)

	// 5. 回填数据：为已有的老人档案同步社区名称
	DB.Exec(`UPDATE elderly_profiles e INNER JOIN communities c ON e.community_id = c.id SET e.community_name = c.name WHERE e.community_name IS NULL AND e.community_id IS NOT NULL`)
	// 为已有的设备回填 device_name
	DB.Exec(`UPDATE devices SET device_name = '智能健康手表' WHERE device_name IS NULL AND device_type = 'watch'`)
	DB.Exec(`UPDATE devices SET device_name = CONCAT('设备-', device_sn) WHERE device_name IS NULL AND device_type != 'watch'`)

	return nil
}

// Close 关闭数据库连接
func Close() {
	if DB != nil {
		_ = DB.Close()
		logger.Log.Info("MySQL connection closed")
	}
}

// HealthCheck 数据库健康检查
func HealthCheck() error {
	if DB == nil {
		return fmt.Errorf("database not initialized")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return DB.PingContext(ctx)
}

// Exec 执行非查询SQL
func Exec(query string, args ...interface{}) (sql.Result, error) {
	return DB.Exec(query, args...)
}

// Query 执行查询
func Query(query string, args ...interface{}) (*sql.Rows, error) {
	return DB.Query(query, args...)
}

// QueryRow 执行单行查询
func QueryRow(query string, args ...interface{}) *sql.Row {
	return DB.QueryRow(query, args...)
}
