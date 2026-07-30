package models

import (
	"database/sql"
	"time"
)

// ====== 用户 ======

type User struct {
	ID             string         `json:"id"`
	Username       string         `json:"username"`
	PasswordHash   string         `json:"-"`
	Phone          sql.NullString `json:"phone"`
	Email          sql.NullString `json:"email"`
	Role           string         `json:"role"`
	AvatarURL      sql.NullString `json:"avatar_url"`
	RealName       sql.NullString `json:"real_name"`
	Status         string         `json:"status"`
	AdminRoleID    sql.NullString `json:"admin_role_id"`
	MFASecret      sql.NullString `json:"-"`
	MFAEnabled     bool           `json:"mfa_enabled"`
	FailedLogins   int            `json:"-"`
	LockedUntil    sql.NullTime   `json:"-"`
	PasswordExpire sql.NullTime   `json:"-"`
	IPWhitelist    sql.NullString `json:"-"`
	LastLoginAt    sql.NullTime   `json:"last_login_at"`
	LastLoginIP    sql.NullString `json:"last_login_ip"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
}

// ====== 老人档案 ======

type ElderlyProfile struct {
	ID                    string         `json:"id"`
	UserID                sql.NullString `json:"user_id"`
	CommunityID           sql.NullString `json:"community_id"`
	Name                  string         `json:"name"`
	Gender                string         `json:"gender"`
	BirthDate             sql.NullTime   `json:"birth_date"`
	Phone                 sql.NullString `json:"phone"`
	EmergencyContact      sql.NullString `json:"emergency_contact"`
	EmergencyPhone        sql.NullString `json:"emergency_phone"`
	Address               sql.NullString `json:"address"`
	MedicalHistoryMeta    sql.NullString `json:"medical_history_meta"`
	AllergiesMeta         sql.NullString `json:"allergies_meta"`
	MedicationsMeta       sql.NullString `json:"medications_meta"`
	HeartRateBaseline     sql.NullFloat64 `json:"heart_rate_baseline"`
	Spo2Baseline          sql.NullFloat64 `json:"spo2_baseline"`
	TempBaseline          sql.NullFloat64 `json:"temp_baseline"`
	CareLevel             string         `json:"care_level"`
	Status                string         `json:"status"`
	CreatedAt             time.Time      `json:"created_at"`
	UpdatedAt             time.Time      `json:"updated_at"`
}

// ====== 社区 ======

type Community struct {
	ID          string         `json:"id"`
	Name        string         `json:"name"`
	Address     sql.NullString `json:"address"`
	ContactName sql.NullString `json:"contact_name"`
	ContactPhone sql.NullString `json:"contact_phone"`
	TotalElderly int           `json:"total_elderly"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
}

// ====== 设备 ======

type Device struct {
	ID              string         `json:"id"`
	ElderlyID       sql.NullString `json:"elderly_id"`
	DeviceSN        string         `json:"device_sn"`
	DeviceType      string         `json:"device_type"`
	FirmwareVersion string         `json:"firmware_version"`
	Status          string         `json:"status"`
	Battery         sql.NullInt64  `json:"battery"`
	SignalStrength  sql.NullInt64  `json:"signal_strength"`
	LastOnlineAt    sql.NullTime   `json:"last_online_at"`
	RegisteredAt    time.Time      `json:"registered_at"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
}

// ====== 报警 ======

type AlarmRecord struct {
	ID               string         `json:"id"`
	ElderlyID        string         `json:"elderly_id"`
	DeviceID         sql.NullString `json:"device_id"`
	AlarmType        string         `json:"alarm_type"`
	AlarmLevel       string         `json:"alarm_level"`
	AlarmSource      string         `json:"alarm_source"`
	VitalSnapshotJSON sql.NullString `json:"vital_snapshot_json"`
	LocationJSON     sql.NullString `json:"location_json"`
	Description      sql.NullString `json:"description"`
	Status           string         `json:"status"`
	HandledBy        sql.NullString `json:"handled_by"`
	HandledAt        sql.NullTime   `json:"handled_at"`
	ResolvedBy       sql.NullString `json:"resolved_by"`
	ResolvedAt       sql.NullTime   `json:"resolved_at"`
	EscalatedTo      sql.NullString `json:"escalated_to"`
	CreatedAt        time.Time      `json:"created_at"`
	UpdatedAt        time.Time      `json:"updated_at"`
}

// ====== 报警处理日志 ======

type AlarmHandlingLog struct {
	ID          string    `json:"id"`
	AlarmID     string    `json:"alarm_id"`
	Action      string    `json:"action"`
	OperatorID  string    `json:"operator_id"`
	OperatorRole string   `json:"operator_role"`
	Note        sql.NullString `json:"note"`
	CreatedAt   time.Time `json:"created_at"`
}

// ====== 签到 ======

type SigninRecord struct {
	ID            string         `json:"id"`
	ElderlyID     string         `json:"elderly_id"`
	DeviceID      sql.NullString `json:"device_id"`
	SigninMethod  string         `json:"signin_method"`
	SigninStatus  string         `json:"signin_status"`
	ProxyBy       sql.NullString `json:"proxy_by"`
	SigninAt      time.Time      `json:"signin_at"`
	SigninDate    string         `json:"signin_date"`
	CreatedAt     time.Time      `json:"created_at"`
}

// ====== 巡访 ======

type PatrolTask struct {
	ID            string         `json:"id"`
	ElderlyID     string         `json:"elderly_id"`
	CommunityID   sql.NullString `json:"community_id"`
	TaskType      string         `json:"task_type"`
	Priority      string         `json:"priority"`
	AssignedTo    sql.NullString `json:"assigned_to"`
	ScheduledDate sql.NullTime   `json:"scheduled_date"`
	Status        string         `json:"status"`
	Note          sql.NullString `json:"note"`
	CreatedAt     time.Time      `json:"created_at"`
	UpdatedAt     time.Time      `json:"updated_at"`
}

type PatrolRecord struct {
	ID          string         `json:"id"`
	TaskID      string         `json:"task_id"`
	ElderlyID   string         `json:"elderly_id"`
	StaffID     string         `json:"staff_id"`
	PatrolType  string         `json:"patrol_type"`
	PatrolAt    time.Time      `json:"patrol_at"`
	HealthNote  sql.NullString `json:"health_note"`
	MoodScore   sql.NullInt64  `json:"mood_score"`
	Status      string         `json:"status"`
	PhotosJSON  sql.NullString `json:"photos_json"`
	CreatedAt   time.Time      `json:"created_at"`
}

// ====== 健康周报 ======

type HealthReport struct {
	ID                string         `json:"id"`
	ElderlyID         string         `json:"elderly_id"`
	ReportWeek        string         `json:"report_week"`
	HealthScore       sql.NullInt64  `json:"health_score"`
	AbnormalEvents    sql.NullInt64  `json:"abnormal_events"`
	AvgHeartRate      sql.NullFloat64 `json:"avg_heart_rate"`
	AvgSpO2           sql.NullFloat64 `json:"avg_spo2"`
	TotalSteps        sql.NullInt64  `json:"total_steps"`
	SigninRate        sql.NullFloat64 `json:"signin_rate"`
	TrendSummaryJSON  sql.NullString `json:"trend_summary_json"`
	AISummary         sql.NullString `json:"ai_summary"`
	Suggestions       sql.NullString `json:"suggestions"`
	GeneratedBy       string         `json:"generated_by"`
	GeneratedAt       time.Time      `json:"generated_at"`
	CreatedAt         time.Time      `json:"created_at"`
}

// ====== 管理员 ======

type AdminRole struct {
	ID          string    `json:"id"`
	RoleCode    string    `json:"role_code"`
	RoleName    string    `json:"role_name"`
	Description sql.NullString `json:"description"`
	IsSystem    bool      `json:"is_system"`
	IsActive    bool      `json:"is_active"`
	CreatedBy   sql.NullString `json:"created_by"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type AdminPermission struct {
	ID          string `json:"id"`
	PermCode    string `json:"perm_code"`
	PermName    string `json:"perm_name"`
	Module      string `json:"module"`
	Action      string `json:"action"`
	Sensitivity string `json:"sensitivity"`
	Description sql.NullString `json:"description"`
}

type AdminSession struct {
	ID               string       `json:"id"`
	AdminID          string       `json:"admin_id"`
	RefreshTokenHash string       `json:"-"`
	AccessTokenJTI   string       `json:"access_token_jti"`
	SourceIP         string       `json:"source_ip"`
	UserAgent        sql.NullString `json:"user_agent"`
	DeviceInfo       sql.NullString `json:"device_info"`
	Status           string       `json:"status"`
	IssuedAt         time.Time    `json:"issued_at"`
	ExpiresAt        time.Time    `json:"expires_at"`
	LastActiveAt     sql.NullTime `json:"last_active_at"`
	RevokedAt        sql.NullTime `json:"revoked_at"`
	RevokedBy        sql.NullString `json:"revoked_by"`
}

type AdminAuditLog struct {
	ID             int64          `json:"id"`
	AuditLevel     string         `json:"audit_level"`
	OperatorID     string         `json:"operator_id"`
	OperatorName   string         `json:"operator_name"`
	OperatorRole   string         `json:"operator_role"`
	HTTPMethod     string         `json:"http_method"`
	Endpoint       string         `json:"endpoint"`
	Module         string         `json:"module"`
	Operation      string         `json:"operation"`
	Description    sql.NullString `json:"description"`
	ResourceType   string         `json:"resource_type"`
	ResourceID     sql.NullString `json:"resource_id"`
	SourceIP       string         `json:"source_ip"`
	ResultStatus   string         `json:"result_status"`
	HTTPStatus     sql.NullInt64  `json:"http_status"`
	ErrorCode      sql.NullString `json:"error_code"`
	DurationMs     sql.NullInt64  `json:"duration_ms"`
	CreatedAt      time.Time      `json:"created_at"`
}

// ====== 体征数据（时序） ======

type VitalSign struct {
	ID           int64     `json:"id"`
	ElderlyID    string    `json:"elderly_id"`
	DeviceID     string    `json:"device_id"`
	HeartRate    sql.NullInt64  `json:"heart_rate"`
	SpO2         sql.NullFloat64 `json:"spo2"`
	Temperature  sql.NullFloat64 `json:"temperature"`
	Steps        sql.NullInt64  `json:"steps"`
	AccelX       sql.NullFloat64 `json:"accel_x"`
	AccelY       sql.NullFloat64 `json:"accel_y"`
	AccelZ       sql.NullFloat64 `json:"accel_z"`
	ActivityLevel sql.NullInt64  `json:"activity_level"`
	Posture      sql.NullString `json:"posture"`
	ConfidenceHR sql.NullFloat64 `json:"confidence_hr"`
	ReportedAt   time.Time `json:"reported_at"`
	CreatedAt    time.Time `json:"created_at"`
}

// ====== 家庭绑定 ======

type FamilyBinding struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	ElderlyID string    `json:"elderly_id"`
	Relation  string    `json:"relation"`
	Verified  bool      `json:"verified"`
	CreatedAt time.Time `json:"created_at"`
}

// ====== 通知日志 ======

type NotificationLog struct {
	ID             int64          `json:"id"`
	RecipientID    string         `json:"recipient_id"`
	RecipientType  string         `json:"recipient_type"`
	NotifyChannel  string         `json:"notify_channel"`
	NotifyType     string         `json:"notify_type"`
	Content        string         `json:"content"`
	Status         string         `json:"status"`
	ExternalRef    sql.NullString `json:"external_ref"`
	SentAt         time.Time      `json:"sent_at"`
	DeliveredAt    sql.NullTime   `json:"delivered_at"`
	CreatedAt      time.Time      `json:"created_at"`
}
