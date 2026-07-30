-- =============================================
-- AI老年健康守护系统 — MySQL 数据库初始化脚本
-- 版本: v1.0 | 日期: 2026-06-24
-- =============================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS elderly_health
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE elderly_health;

-- =============================================
-- 1. 管理员角色表
-- =============================================
CREATE TABLE IF NOT EXISTS admin_roles (
    id              CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    role_code       VARCHAR(32) NOT NULL COMMENT '角色编码',
    role_name       VARCHAR(64) NOT NULL COMMENT '角色名称',
    description     VARCHAR(256) COMMENT '角色描述',
    is_system       TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否系统预置角色',
    is_active       TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用',
    created_by      CHAR(36) NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_admin_roles_code (role_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员角色表';

-- =============================================
-- 2. 权限定义表
-- =============================================
CREATE TABLE IF NOT EXISTS admin_permissions (
    id              CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    perm_code       VARCHAR(64) NOT NULL COMMENT '权限码',
    perm_name       VARCHAR(128) NOT NULL COMMENT '权限名称',
    module          VARCHAR(32) NOT NULL COMMENT '所属模块',
    `action`        VARCHAR(32) NOT NULL COMMENT '操作',
    sensitivity     VARCHAR(8) NOT NULL DEFAULT 'LOW' COMMENT '敏感级',
    description     VARCHAR(256) NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_admin_perms_code (perm_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='权限定义表';

-- =============================================
-- 3. 角色权限关联表
-- =============================================
CREATE TABLE IF NOT EXISTS admin_role_permissions (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_id         CHAR(36) NOT NULL,
    permission_id   CHAR(36) NOT NULL,
    granted_by      CHAR(36) NULL,
    granted_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_role_perm (role_id, permission_id),
    CONSTRAINT fk_rp_role FOREIGN KEY (role_id) REFERENCES admin_roles(id) ON DELETE CASCADE,
    CONSTRAINT fk_rp_perm FOREIGN KEY (permission_id) REFERENCES admin_permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色权限关联表';

-- =============================================
-- 4. 用户基础表
-- =============================================
CREATE TABLE IF NOT EXISTS users (
    id              CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    username        VARCHAR(64) NOT NULL,
    password_hash   VARCHAR(256) NOT NULL,
    phone           VARCHAR(20),
    email           VARCHAR(128),
    role            VARCHAR(20) NOT NULL DEFAULT 'family' COMMENT 'elderly|family|community|admin|super_admin',
    avatar_url      VARCHAR(512),
    real_name       VARCHAR(64),
    status          VARCHAR(16) NOT NULL DEFAULT 'active' COMMENT 'active|disabled|deleted',
    -- 管理员扩展字段
    admin_role_id   CHAR(36) NULL,
    mfa_secret      VARCHAR(64) NULL,
    mfa_enabled     TINYINT(1) NOT NULL DEFAULT 0,
    failed_logins   INT NOT NULL DEFAULT 0,
    locked_until    TIMESTAMP NULL,
    password_expire TIMESTAMP NULL,
    ip_whitelist    TEXT NULL,
    last_login_at   TIMESTAMP NULL,
    last_login_ip   VARCHAR(45) NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_users_username (username),
    UNIQUE KEY uk_users_phone (phone),
    INDEX idx_users_role (role),
    INDEX idx_users_admin_role (admin_role_id),
    CONSTRAINT fk_users_admin_role FOREIGN KEY (admin_role_id) REFERENCES admin_roles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户基础表';

-- =============================================
-- 5. 管理员会话表
-- =============================================
CREATE TABLE IF NOT EXISTS admin_sessions (
    id                  CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    admin_id            CHAR(36) NOT NULL,
    refresh_token_hash  VARCHAR(256) NOT NULL,
    access_token_jti    VARCHAR(64) NOT NULL,
    source_ip           VARCHAR(45) NOT NULL,
    user_agent          TEXT NULL,
    device_info         VARCHAR(256) NULL,
    status              VARCHAR(16) NOT NULL DEFAULT 'active',
    issued_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at          TIMESTAMP NOT NULL,
    last_active_at      TIMESTAMP NULL,
    revoked_at          TIMESTAMP NULL,
    revoked_by          CHAR(36) NULL,
    INDEX idx_as_admin (admin_id),
    INDEX idx_as_status (status, expires_at),
    CONSTRAINT fk_as_admin FOREIGN KEY (admin_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员会话表';

-- =============================================
-- 6. 管理员登录尝试记录表
-- =============================================
CREATE TABLE IF NOT EXISTS admin_login_attempts (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(64) NOT NULL,
    source_ip       VARCHAR(45) NOT NULL,
    success         TINYINT(1) NOT NULL DEFAULT 0,
    failure_reason  VARCHAR(64) NULL,
    user_agent      TEXT NULL,
    attempted_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ala_username_time (username, attempted_at),
    INDEX idx_ala_ip_time (source_ip, attempted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员登录尝试记录';

-- =============================================
-- 7. 管理员操作审计日志表
-- =============================================
CREATE TABLE IF NOT EXISTS admin_audit_logs (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    audit_level     VARCHAR(8) NOT NULL,
    operator_id     CHAR(36) NOT NULL,
    operator_name   VARCHAR(64) NOT NULL,
    operator_role   VARCHAR(32) NOT NULL,
    http_method     VARCHAR(8) NOT NULL,
    endpoint        VARCHAR(256) NOT NULL,
    module          VARCHAR(32) NOT NULL,
    operation       VARCHAR(32) NOT NULL,
    description     VARCHAR(512) NULL,
    resource_type   VARCHAR(32) NOT NULL,
    resource_id     VARCHAR(64) NULL,
    resource_name   VARCHAR(128) NULL,
    source_ip       VARCHAR(45) NOT NULL,
    user_agent      TEXT NULL,
    request_id      VARCHAR(64) NULL,
    request_params  JSON NULL,
    result_status   VARCHAR(8) NOT NULL,
    http_status     SMALLINT NULL,
    error_code      VARCHAR(16) NULL,
    error_message   VARCHAR(512) NULL,
    duration_ms     INT NULL,
    changes         JSON NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_aal_operator (operator_id, created_at),
    INDEX idx_aal_module_time (module, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员操作审计日志表';

-- =============================================
-- 8. 社区表
-- =============================================
CREATE TABLE IF NOT EXISTS communities (
    id              CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name            VARCHAR(128) NOT NULL,
    address         VARCHAR(512),
    contact_name    VARCHAR(64),
    contact_phone   VARCHAR(20),
    total_elderly   INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='社区表';

-- =============================================
-- 9. 老人档案表
-- =============================================
CREATE TABLE IF NOT EXISTS elderly_profiles (
    id                    CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id               CHAR(36) NULL,
    community_id          CHAR(36) NULL,
    name                  VARCHAR(64) NOT NULL,
    gender                VARCHAR(8) NOT NULL DEFAULT 'male',
    birth_date            DATE NULL,
    phone                 VARCHAR(20),
    emergency_contact     VARCHAR(64),
    emergency_phone       VARCHAR(20),
    address               VARCHAR(512),
    medical_history_meta  JSON,
    allergies_meta        JSON,
    medications_meta      JSON,
    heart_rate_baseline   DOUBLE NULL,
    spo2_baseline         DOUBLE NULL,
    temp_baseline         DOUBLE NULL,
    care_level            VARCHAR(16) DEFAULT 'normal',
    status                VARCHAR(16) NOT NULL DEFAULT 'active',
    created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ep_community (community_id),
    INDEX idx_ep_status (status),
    CONSTRAINT fk_ep_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE SET NULL,
    CONSTRAINT fk_ep_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='老人档案表';

-- =============================================
-- 10. 家庭绑定表
-- =============================================
CREATE TABLE IF NOT EXISTS family_bindings (
    id              CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id         CHAR(36) NOT NULL,
    elderly_id      CHAR(36) NOT NULL,
    relation        VARCHAR(32) NOT NULL,
    verified        TINYINT(1) NOT NULL DEFAULT 0,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_fb_user_elderly (user_id, elderly_id),
    INDEX idx_fb_elderly (elderly_id),
    CONSTRAINT fk_fb_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_fb_elderly FOREIGN KEY (elderly_id) REFERENCES elderly_profiles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='家庭绑定关系表';

-- =============================================
-- 11. 设备表
-- =============================================
CREATE TABLE IF NOT EXISTS devices (
    id              CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    elderly_id      CHAR(36) NULL,
    device_sn       VARCHAR(64) NOT NULL,
    device_type     VARCHAR(32) NOT NULL DEFAULT 'watch',
    firmware_version VARCHAR(32) DEFAULT '1.0.0',
    status          VARCHAR(16) NOT NULL DEFAULT 'offline',
    battery         INT,
    signal_strength INT,
    last_online_at  TIMESTAMP NULL,
    registered_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_devices_sn (device_sn),
    INDEX idx_devices_elderly (elderly_id),
    CONSTRAINT fk_devices_elderly FOREIGN KEY (elderly_id) REFERENCES elderly_profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='设备表';

-- =============================================
-- 12. 体征时序数据表（按天分区）
-- =============================================
CREATE TABLE IF NOT EXISTS vital_signs (
    id              BIGINT AUTO_INCREMENT,
    elderly_id      CHAR(36) NOT NULL,
    device_id       VARCHAR(64) NOT NULL,
    heart_rate      INT NULL,
    spo2            DOUBLE NULL,
    temperature     DOUBLE NULL,
    steps           INT NULL,
    accel_x         DOUBLE NULL,
    accel_y         DOUBLE NULL,
    accel_z         DOUBLE NULL,
    activity_level  INT NULL,
    posture         VARCHAR(16) NULL,
    confidence_hr   DOUBLE NULL,
    reported_at     TIMESTAMP NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, reported_at),
    INDEX idx_vs_elderly_time (elderly_id, reported_at),
    INDEX idx_vs_device_time (device_id, reported_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='体征时序数据表'
);

-- =============================================
-- 13. 设备心跳时序表
-- =============================================
CREATE TABLE IF NOT EXISTS device_heartbeats (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    device_sn       VARCHAR(64) NOT NULL,
    battery         INT,
    signal_strength INT,
    firmware_version VARCHAR(32),
    reported_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_dh_sn_time (device_sn, reported_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='设备心跳表';

-- =============================================
-- 14. 报警记录表
-- =============================================
CREATE TABLE IF NOT EXISTS alarm_records (
    id                  CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    elderly_id          CHAR(36) NOT NULL,
    device_id           CHAR(36) NULL,
    alarm_type          VARCHAR(32) NOT NULL COMMENT 'SOS|FALL|VITAL_ABNORMAL|SIGNIN_TIMEOUT|DEVICE_OFFLINE',
    alarm_level         VARCHAR(8) NOT NULL DEFAULT 'P2' COMMENT 'P0|P1|P2|P3',
    alarm_source        VARCHAR(16) NOT NULL DEFAULT 'device' COMMENT 'device|system|manual',
    vital_snapshot_json JSON,
    location_json       JSON,
    description         VARCHAR(512),
    status              VARCHAR(16) NOT NULL DEFAULT 'pending' COMMENT 'pending|confirmed|resolved|escalated|archived',
    handled_by          CHAR(36) NULL,
    handled_at          TIMESTAMP NULL,
    resolved_by         CHAR(36) NULL,
    resolved_at         TIMESTAMP NULL,
    escalated_to        VARCHAR(32) NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ar_elderly (elderly_id, created_at),
    INDEX idx_ar_level_status (alarm_level, status),
    INDEX idx_ar_created (created_at),
    CONSTRAINT fk_ar_elderly FOREIGN KEY (elderly_id) REFERENCES elderly_profiles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='报警记录表';

-- =============================================
-- 15. 报警处理日志表
-- =============================================
CREATE TABLE IF NOT EXISTS alarm_handling_logs (
    id              CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    alarm_id        CHAR(36) NOT NULL,
    action          VARCHAR(32) NOT NULL COMMENT 'confirmed|resolved|escalated|emergency_120',
    operator_id     CHAR(36) NOT NULL,
    operator_role   VARCHAR(20) NOT NULL,
    note            VARCHAR(512),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ahl_alarm (alarm_id),
    CONSTRAINT fk_ahl_alarm FOREIGN KEY (alarm_id) REFERENCES alarm_records(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='报警处理日志表';

-- =============================================
-- 16. 签到记录表
-- =============================================
CREATE TABLE IF NOT EXISTS signin_records (
    id              CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    elderly_id      CHAR(36) NOT NULL,
    device_id       CHAR(36) NULL,
    signin_method   VARCHAR(16) NOT NULL DEFAULT 'touch' COMMENT 'touch|voice|wrist_up|auto|proxy',
    signin_status   VARCHAR(16) NOT NULL DEFAULT 'pending' COMMENT 'pending|checked_in|missed',
    proxy_by        CHAR(36) NULL,
    signin_at       TIMESTAMP NULL,
    signin_date     DATE NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_sr_elderly_date (elderly_id, signin_date),
    INDEX idx_sr_date (signin_date),
    CONSTRAINT fk_sr_elderly FOREIGN KEY (elderly_id) REFERENCES elderly_profiles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='签到记录表';

-- =============================================
-- 17. 巡访任务表
-- =============================================
CREATE TABLE IF NOT EXISTS patrol_tasks (
    id              CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    elderly_id      CHAR(36) NOT NULL,
    community_id    CHAR(36) NULL,
    task_type       VARCHAR(32) NOT NULL DEFAULT 'regular' COMMENT 'urgent|regular|scheduled',
    priority        VARCHAR(16) NOT NULL DEFAULT 'normal' COMMENT 'urgent|high|normal|low',
    assigned_to     CHAR(36) NULL,
    scheduled_date  DATE NULL,
    status          VARCHAR(16) NOT NULL DEFAULT 'pending' COMMENT 'pending|assigned|in_progress|completed|cancelled',
    note            VARCHAR(512),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_pt_elderly (elderly_id),
    INDEX idx_pt_assigned (assigned_to),
    INDEX idx_pt_status (status),
    CONSTRAINT fk_pt_elderly FOREIGN KEY (elderly_id) REFERENCES elderly_profiles(id),
    CONSTRAINT fk_pt_assigned FOREIGN KEY (assigned_to) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='巡访任务表';

-- =============================================
-- 18. 巡访记录表
-- =============================================
CREATE TABLE IF NOT EXISTS patrol_records (
    id              CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    task_id         CHAR(36) NOT NULL,
    elderly_id      CHAR(36) NOT NULL,
    staff_id        CHAR(36) NOT NULL,
    patrol_type     VARCHAR(16) NOT NULL DEFAULT 'home_visit',
    patrol_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    health_note     TEXT,
    mood_score      INT COMMENT '1-5',
    photos_json     JSON,
    status          VARCHAR(16) NOT NULL DEFAULT 'completed',
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_pr_task (task_id),
    INDEX idx_pr_elderly (elderly_id),
    CONSTRAINT fk_pr_task FOREIGN KEY (task_id) REFERENCES patrol_tasks(id),
    CONSTRAINT fk_pr_elderly FOREIGN KEY (elderly_id) REFERENCES elderly_profiles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='巡访记录表';

-- =============================================
-- 19. 健康周报表
-- =============================================
CREATE TABLE IF NOT EXISTS health_reports (
    id                CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    elderly_id        CHAR(36) NOT NULL,
    report_week       VARCHAR(8) NOT NULL COMMENT '2026-W25',
    health_score      INT COMMENT '0-100',
    abnormal_events   INT DEFAULT 0,
    avg_heart_rate    DOUBLE,
    avg_spo2          DOUBLE,
    total_steps       INT,
    signin_rate       DOUBLE,
    trend_summary_json JSON,
    ai_summary        TEXT,
    suggestions       TEXT,
    generated_by      VARCHAR(64) NOT NULL COMMENT 'system|user_id',
    generated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_hr_elderly_week (elderly_id, report_week),
    INDEX idx_hr_elderly (elderly_id),
    CONSTRAINT fk_hr_elderly FOREIGN KEY (elderly_id) REFERENCES elderly_profiles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='健康周报表';

-- =============================================
-- 20. 通知日志表
-- =============================================
CREATE TABLE IF NOT EXISTS notification_logs (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    recipient_id    CHAR(36) NOT NULL,
    recipient_type  VARCHAR(16) NOT NULL COMMENT 'elderly|family|community|admin',
    notify_channel  VARCHAR(16) NOT NULL COMMENT 'push|sms|phone|mqtt',
    notify_type     VARCHAR(32) NOT NULL COMMENT 'alarm|signin_remind|report|system',
    content         TEXT NOT NULL,
    status          VARCHAR(16) NOT NULL DEFAULT 'pending' COMMENT 'pending|sent|delivered|failed',
    external_ref    VARCHAR(128),
    sent_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    delivered_at    TIMESTAMP NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_nl_recipient (recipient_id, created_at),
    INDEX idx_nl_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知发送日志表';

-- =============================================
-- 21. 体征小时聚合表
-- =============================================
CREATE TABLE IF NOT EXISTS vital_signs_hourly (
    hour_bucket     DATE NOT NULL COMMENT 'YYYY-MM-DD',
    hour_slot       TINYINT NOT NULL COMMENT '0-23',
    elderly_id      CHAR(36) NOT NULL,
    avg_heart_rate  DOUBLE,
    max_heart_rate  INT,
    min_heart_rate  INT,
    avg_spo2        DOUBLE,
    min_spo2        DOUBLE,
    avg_temperature DOUBLE,
    total_steps     INT,
    sample_count    INT NOT NULL DEFAULT 0,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (hour_bucket, hour_slot, elderly_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='体征小时聚合表';

-- =============================================
-- 自动分区维护事件
-- =============================================
DELIMITER //
CREATE EVENT IF NOT EXISTS evt_auto_partition_vital_signs
ON SCHEDULE EVERY 1 DAY STARTS '2026-06-27 00:00:00'
DO BEGIN
    DECLARE _next_date DATE;
    DECLARE _partition_name VARCHAR(64);
    SET _next_date = CURRENT_DATE + INTERVAL 2 DAY;
    SET _partition_name = CONCAT('p', DATE_FORMAT(_next_date, '%Y%m%d'));
    SET @sql = CONCAT(
        'ALTER TABLE vital_signs REORGANIZE PARTITION p_future INTO (',
        'PARTITION ', _partition_name, ' VALUES LESS THAN (TO_DAYS(''', _next_date, ''')),',
        'PARTITION p_future VALUES LESS THAN MAXVALUE)'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

-- =============================================
-- 预置数据
-- =============================================

-- 预置管理员角色
INSERT INTO admin_roles (id, role_code, role_name, description, is_system, is_active) VALUES
(UUID(), 'super_admin', '超级管理员', '系统最高权限，管理所有管理员和全局策略', 1, 1),
(UUID(), 'admin', '管理员', '日常管理权限，含全部业务运营', 1, 1),
(UUID(), 'operator', '运营人员', '报警处理、签到监督、巡访执行', 1, 1),
(UUID(), 'viewer', '只读观察员', '查看看板和报表，无操作权限', 1, 1);

-- 预置权限（核心模块）
INSERT INTO admin_permissions (id, perm_code, perm_name, module, `action`, sensitivity) VALUES
-- 系统管理
(UUID(), 'admin:manage', '管理员管理', 'admin', 'manage', 'CRITICAL'),
(UUID(), 'admin:read', '管理员查看', 'admin', 'read', 'HIGH'),
(UUID(), 'role:manage', '角色管理', 'admin', 'manage', 'CRITICAL'),
(UUID(), 'role:read', '角色查看', 'admin', 'read', 'HIGH'),
(UUID(), 'audit:read', '审计日志查看', 'admin', 'read', 'HIGH'),
-- 老人管理
(UUID(), 'elderly:read', '老人档案查看', 'elderly', 'read', 'MEDIUM'),
(UUID(), 'elderly:write', '老人档案编辑', 'elderly', 'write', 'HIGH'),
(UUID(), 'elderly:delete', '老人档案删除', 'elderly', 'delete', 'HIGH'),
-- 设备管理
(UUID(), 'device:read', '设备信息查看', 'device', 'read', 'MEDIUM'),
(UUID(), 'device:write', '设备注册编辑', 'device', 'write', 'HIGH'),
(UUID(), 'device:ota', '设备OTA升级', 'device', 'ota', 'HIGH'),
(UUID(), 'device:remote_control', '设备远程控制', 'device', 'remote_control', 'HIGH'),
-- 报警管理
(UUID(), 'alarm:read', '报警查看', 'alarm', 'read', 'MEDIUM'),
(UUID(), 'alarm:handle', '报警处理', 'alarm', 'handle', 'HIGH'),
(UUID(), 'alarm:escalate', '报警升级', 'alarm', 'escalate', 'CRITICAL'),
(UUID(), 'alarm:resolve', '报警解决', 'alarm', 'resolve', 'HIGH'),
-- 签到管理
(UUID(), 'signin:read', '签到查看', 'signin', 'read', 'LOW'),
(UUID(), 'signin:proxy', '代签操作', 'signin', 'proxy', 'MEDIUM'),
-- 巡访管理
(UUID(), 'patrol:read', '巡访查看', 'patrol', 'read', 'LOW'),
(UUID(), 'patrol:write', '巡访任务管理', 'patrol', 'write', 'MEDIUM'),
-- 周报管理
(UUID(), 'report:read', '周报查看', 'report', 'read', 'LOW'),
(UUID(), 'report:write', '周报生成', 'report', 'write', 'MEDIUM'),
-- 看板
(UUID(), 'dashboard:read', '看板查看', 'dashboard', 'read', 'LOW'),
-- 系统运维
(UUID(), 'system:read', '系统状态查看', 'system', 'read', 'MEDIUM'),
(UUID(), 'system:manage', '系统配置管理', 'system', 'manage', 'CRITICAL');

-- 为超级管理员分配所有权限
INSERT INTO admin_role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM admin_roles r, admin_permissions p WHERE r.role_code = 'super_admin';

-- 为管理员分配业务权限（排除系统管理关键权限）
INSERT INTO admin_role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM admin_roles r, admin_permissions p
WHERE r.role_code = 'admin' AND p.sensitivity != 'CRITICAL';

-- 为运营人员分配查看和处理权限
INSERT INTO admin_role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM admin_roles r, admin_permissions p
WHERE r.role_code = 'operator' AND p.perm_code IN (
    'elderly:read','device:read','alarm:read','alarm:handle',
    'signin:read','signin:proxy','patrol:read','patrol:write',
    'report:read','dashboard:read'
);

-- 为观察员分配只读权限
INSERT INTO admin_role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM admin_roles r, admin_permissions p
WHERE r.role_code = 'viewer' AND p.perm_code IN (
    'elderly:read','device:read','alarm:read',
    'signin:read','report:read','dashboard:read'
);

-- 创建默认超级管理员账号 (admin / Admin@2026)
-- 密码: Admin@2026 的 bcrypt 哈希
INSERT INTO users (id, username, password_hash, role, real_name, status, admin_role_id) 
SELECT UUID(), 'admin', '$2a$12$LJ3m4ys3GZfnYMz8kVsKaOq8GfDM5M4YLrPKCHgNGxcPLKZcFQBHO', 'super_admin', '系统管理员', 'active', id
FROM admin_roles WHERE role_code = 'super_admin' LIMIT 1;

-- 创建默认社区
INSERT INTO communities (id, name, address, contact_name, contact_phone) VALUES
(UUID(), '阳光社区', 'XX市XX区阳光路100号', '张主任', '13800001111'),
(UUID(), '幸福社区', 'XX市XX区幸福路200号', '李主任', '13800002222'),
(UUID(), '长寿社区', 'XX市XX区长寿路300号', '王主任', '13800003333');
