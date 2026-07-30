-- =============================================
-- 补丁: 添加数据库中缺失的列和表
-- 版本: v1.2 | 日期: 2026-07-02
-- 适配: MySQL 8.0 (不支持 ADD COLUMN IF NOT EXISTS)
-- =============================================

USE elderly_health;

-- 1. elderly_profiles: 添加 community_name 列（冗余存储社区名称）
-- MySQL 8.0 没有 IF NOT EXISTS，用存储过程做安全检查
DROP PROCEDURE IF EXISTS _patch_add_columns;

DELIMITER //
CREATE PROCEDURE _patch_add_columns()
BEGIN
    -- 1. elderly_profiles.community_name
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                   WHERE TABLE_SCHEMA = 'elderly_health'
                   AND TABLE_NAME = 'elderly_profiles'
                   AND COLUMN_NAME = 'community_name') THEN
        ALTER TABLE elderly_profiles ADD COLUMN community_name VARCHAR(128) COMMENT '社区名称' AFTER community_id;
    END IF;

    -- 2. devices.device_name
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                   WHERE TABLE_SCHEMA = 'elderly_health'
                   AND TABLE_NAME = 'devices'
                   AND COLUMN_NAME = 'device_name') THEN
        ALTER TABLE devices ADD COLUMN device_name VARCHAR(128) COMMENT '设备名称' AFTER device_sn;
    END IF;

    -- 3. admin_audit_logs.resource_name
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                   WHERE TABLE_SCHEMA = 'elderly_health'
                   AND TABLE_NAME = 'admin_audit_logs'
                   AND COLUMN_NAME = 'resource_name') THEN
        ALTER TABLE admin_audit_logs ADD COLUMN resource_name VARCHAR(128) COMMENT '资源名称' AFTER resource_type;
    END IF;
END //
DELIMITER ;

CALL _patch_add_columns();
DROP PROCEDURE IF EXISTS _patch_add_columns;

-- 4. system_config: 创建完整的系统配置表（匹配后端 handler 字段名）
CREATE TABLE IF NOT EXISTS system_config (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';

-- 初始化默认配置数据
INSERT IGNORE INTO system_config (id) VALUES (1);

-- 5. 为已有的老人档案回填 community_name（从 communities 表同步）
UPDATE elderly_profiles e
INNER JOIN communities c ON e.community_id = c.id
SET e.community_name = c.name
WHERE e.community_name IS NULL AND e.community_id IS NOT NULL;

-- 6. 为已有的设备回填 device_name
UPDATE devices SET device_name = '智能健康手表'
WHERE device_name IS NULL AND device_type = 'watch';

UPDATE devices SET device_name = CONCAT('设备-', device_sn)
WHERE device_name IS NULL AND device_type != 'watch';
