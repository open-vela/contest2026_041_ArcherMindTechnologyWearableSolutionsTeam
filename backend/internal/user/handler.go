package user

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"elderly-health-backend/internal/shared/database"
	apperrors "elderly-health-backend/internal/shared/errors"
	"elderly-health-backend/internal/shared/logger"
	"elderly-health-backend/internal/shared/middleware"
	"elderly-health-backend/internal/shared/models"
	"elderly-health-backend/internal/shared/utils"
)

// RegisterRoutes 注册用户服务路由
func RegisterRoutes(r *gin.RouterGroup, jwtSecret string) {
	// 公开接口
	r.POST("/auth/login", Login(jwtSecret))
	r.POST("/auth/refresh", RefreshToken(jwtSecret))
	r.POST("/auth/send-code", SendVerifyCode)

	// 需要认证
	auth := r.Group("")
	auth.Use(middleware.JWTAuth(jwtSecret))
	{
		auth.GET("/auth/me", GetCurrentUser)
		auth.GET("/auth/profile", GetCurrentUser)
		auth.PUT("/auth/password", ChangePassword)

		// 老人档案
		auth.GET("/elderly", ListElderly)
		auth.GET("/elderly/:id", GetElderly)
		auth.POST("/elderly", CreateElderly)
		auth.PUT("/elderly/:id", UpdateElderly)
		auth.DELETE("/elderly/:id", DeleteElderly)

		// 子女绑定
		auth.POST("/family-bindings", CreateFamilyBinding)
		auth.GET("/family-bindings", ListFamilyBindings)
		auth.DELETE("/family-bindings/:id", RemoveFamilyBinding)

		// 社区管理
		auth.GET("/communities", ListCommunities)
		auth.GET("/communities/:id", GetCommunity)
		auth.POST("/communities", CreateCommunity)
	}
}

// ============ 认证 ============

type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func Login(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req LoginRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
			return
		}

		// 查询用户
		var user models.User
		err := database.DB.QueryRow(
			`SELECT id, username, password_hash, role, status, last_login_at FROM users WHERE username = ?`,
			req.Username,
		).Scan(&user.ID, &user.Username, &user.PasswordHash, &user.Role, &user.Status, &user.LastLoginAt)

		if err == sql.ErrNoRows {
			c.JSON(http.StatusUnauthorized, utils.Error(apperrors.ErrCodeInvalidCredential, "用户名或密码错误"))
			return
		}
		if err != nil {
			c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "服务器错误"))
			return
		}

		// 验证状态
		if user.Status != "active" {
			c.JSON(http.StatusForbidden, utils.Error(apperrors.ErrCodeAccountDisabled, "账户已被禁用"))
			return
		}

		// 验证密码
		if !utils.CheckPassword(user.PasswordHash, req.Password) {
			c.JSON(http.StatusUnauthorized, utils.Error(apperrors.ErrCodeInvalidCredential, "用户名或密码错误"))
			return
		}

		// 生成 Token
		accessToken, _ := utils.GenerateToken(user.ID, user.Username, user.Role, secret, 24*time.Hour)
		refreshToken, _ := utils.GenerateRefreshToken(user.ID, user.Username, user.Role, secret, 7*24*time.Hour)

		// 更新最后登录时间
		database.DB.Exec("UPDATE users SET last_login_at = NOW(), last_login_ip = ? WHERE id = ?",
			c.ClientIP(), user.ID)

		c.JSON(http.StatusOK, utils.Success(gin.H{
			"access_token":  accessToken,
			"refresh_token": refreshToken,
			"token_type":    "Bearer",
			"expires_in":    86400,
			"user": gin.H{
				"id":       user.ID,
				"username": user.Username,
				"role":     user.Role,
			},
		}))
	}
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

func RefreshToken(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req RefreshRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
			return
		}

		// 解析 Refresh Token（简化版本，实际应使用完整JWT解析）
		claims := &middleware.Claims{}
		// ... JWT 解析逻辑
		_ = claims

		accessToken, err := utils.GenerateToken("uid", "user", "family", secret, 24*time.Hour)
		if err != nil {
			c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "生成Token失败"))
			return
		}

		c.JSON(http.StatusOK, utils.Success(gin.H{
			"access_token": accessToken,
			"expires_in":   86400,
		}))
	}
}

type SendCodeRequest struct {
	Phone string `json:"phone" binding:"required"`
}

func SendVerifyCode(c *gin.Context) {
	var req SendCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	if !utils.ValidatePhone(req.Phone) {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "手机号格式不正确"))
		return
	}

	// TODO: 对接短信服务商发送验证码
	c.JSON(http.StatusOK, utils.Success(gin.H{
		"message": "验证码已发送",
		"expires": 300,
	}))
}

// ============ 当前用户 ============

func GetCurrentUser(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var user models.User
	err := database.DB.QueryRow(
		`SELECT id, username, phone, email, role, avatar_url, real_name, status, created_at
		 FROM users WHERE id = ?`, userID,
	).Scan(&user.ID, &user.Username, &user.Phone, &user.Email, &user.Role,
		&user.AvatarURL, &user.RealName, &user.Status, &user.CreatedAt)

	if err != nil {
		c.JSON(http.StatusNotFound, utils.Error(apperrors.ErrCodeUserNotFound, "用户不存在"))
		return
	}

	c.JSON(http.StatusOK, utils.Success(user))
}

type ChangePasswordRequest struct {
	OldPassword string `json:"old_password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=8"`
}

func ChangePassword(c *gin.Context) {
	var req ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	userID, _ := c.Get("user_id")

	var passwordHash string
	database.DB.QueryRow("SELECT password_hash FROM users WHERE id = ?", userID).Scan(&passwordHash)

	if !utils.CheckPassword(passwordHash, req.OldPassword) {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeInvalidCredential, "原密码错误"))
		return
	}

	newHash, _ := utils.HashPassword(req.NewPassword, 12)
	database.DB.Exec("UPDATE users SET password_hash = ? WHERE id = ?", newHash, userID)

	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "密码修改成功"}))
}

// ============ 老人档案 CRUD ============

func ListElderly(c *gin.Context) {
	page := utils.Pagination{}
	c.ShouldBindQuery(&page)
	page.Normalize()

	role, _ := c.Get("role")
	userID, _ := c.Get("user_id")

	baseFrom := `FROM elderly_profiles e LEFT JOIN communities c ON e.community_id = c.id WHERE e.status != 'deleted'`

	// 分别构建 count 和 data 查询参数
	var total int64
	var rows *sql.Rows
	var err error

	// 最新体征子查询（取 vital_signs 表中每个老人最新一条）
	latestVitalSelect := `
		(SELECT heart_rate FROM vital_signs WHERE elderly_id = e.id ORDER BY reported_at DESC LIMIT 1) as latest_heart_rate,
		(SELECT spo2 FROM vital_signs WHERE elderly_id = e.id ORDER BY reported_at DESC LIMIT 1) as latest_spo2,
		(SELECT temperature FROM vital_signs WHERE elderly_id = e.id ORDER BY reported_at DESC LIMIT 1) as latest_temperature,
		(SELECT steps FROM vital_signs WHERE elderly_id = e.id ORDER BY reported_at DESC LIMIT 1) as latest_steps,
		(SELECT reported_at FROM vital_signs WHERE elderly_id = e.id ORDER BY reported_at DESC LIMIT 1) as latest_vital_time`

	switch role {
	case "admin", "community", "super_admin":
		// 社区人员看辖区，管理员看全部
		database.DB.QueryRow("SELECT COUNT(*) " + baseFrom).Scan(&total)

		rows, err = database.DB.Query(
			`SELECT e.id, e.name, e.gender, TIMESTAMPDIFF(YEAR, e.birth_date, CURDATE()) as age, e.phone, e.address,
				c.name as community_name, e.care_level, e.status, e.created_at,
				(SELECT COUNT(*) FROM devices d WHERE d.elderly_id = e.id) as device_count,
				(SELECT d.device_sn FROM devices d WHERE d.elderly_id = e.id LIMIT 1) as bound_device_sn,
				(SELECT COALESCE(d.device_name, CONCAT('手表-', d.device_sn)) FROM devices d WHERE d.elderly_id = e.id LIMIT 1) as bound_device_name,
				` + latestVitalSelect + `
			 ` + baseFrom + ` ORDER BY e.created_at DESC, e.id ASC LIMIT ? OFFSET ?`,
			page.PageSize, page.Offset(),
		)
	case "family":
		database.DB.QueryRow(
			`SELECT COUNT(*) FROM family_bindings fb
			 JOIN elderly_profiles e ON fb.elderly_id = e.id
			 WHERE fb.user_id = ? AND e.status != 'deleted'`,
			userID,
		).Scan(&total)

		rows, err = database.DB.Query(
			`SELECT e.id, e.name, e.gender, TIMESTAMPDIFF(YEAR, e.birth_date, CURDATE()) as age, e.phone, e.address,
				c.name as community_name, e.care_level, e.status, e.created_at,
				(SELECT COUNT(*) FROM devices d WHERE d.elderly_id = e.id) as device_count,
				(SELECT d.device_sn FROM devices d WHERE d.elderly_id = e.id LIMIT 1) as bound_device_sn,
				(SELECT COALESCE(d.device_name, CONCAT('手表-', d.device_sn)) FROM devices d WHERE d.elderly_id = e.id LIMIT 1) as bound_device_name,
				` + latestVitalSelect + `
			 FROM family_bindings fb JOIN elderly_profiles e ON fb.elderly_id = e.id
			 LEFT JOIN communities c ON e.community_id = c.id
			 WHERE fb.user_id = ? AND e.status != 'deleted'
			 ORDER BY e.created_at DESC, e.id ASC LIMIT ? OFFSET ?`,
			userID, page.PageSize, page.Offset(),
		)
	default:
		c.JSON(http.StatusForbidden, utils.Error(apperrors.ErrCodeForbidden, "无权查看"))
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "查询失败"))
		return
	}
	defer rows.Close()

	var list []gin.H
	for rows.Next() {
		var id, name, gender string
		var age sql.NullInt64
		var deviceCount sql.NullInt64
		var phone, address, communityName, careLevel, status sql.NullString
		var boundDeviceSN, boundDeviceName sql.NullString
		var createdAt time.Time
		// 最新体征（可能为 NULL，老人可能还没上传过体征数据）
		var latestHR, latestSpo2, latestTemp sql.NullFloat64
		var latestSteps sql.NullInt64
		var latestVitalTime sql.NullTime
		rows.Scan(&id, &name, &gender, &age, &phone, &address, &communityName, &careLevel, &status, &createdAt,
			&deviceCount, &boundDeviceSN, &boundDeviceName,
			&latestHR, &latestSpo2, &latestTemp, &latestSteps, &latestVitalTime)

		// 构建 latest_vital 对象
		var latestVital gin.H
		if latestHR.Valid || latestSpo2.Valid || latestTemp.Valid {
			latestVital = gin.H{}
			if latestHR.Valid {
				latestVital["heart_rate"] = latestHR.Float64
			}
			if latestSpo2.Valid {
				latestVital["blood_oxygen"] = latestSpo2.Float64
			}
			if latestTemp.Valid {
				latestVital["temperature"] = latestTemp.Float64
			}
			if latestSteps.Valid {
				latestVital["steps"] = latestSteps.Int64
			}
			if latestVitalTime.Valid {
				latestVital["reported_at"] = latestVitalTime.Time.Format("2006-01-02 15:04:05")
			}
		}

		item := gin.H{
			"id": id, "name": name, "gender": gender, "age": age.Int64,
			"phone": phone.String, "address": address.String,
			"community_name": communityName.String, "care_level": careLevel.String,
			"status": status.String, "created_at": createdAt,
			"device_count": deviceCount.Int64,
			"bound_device_sn": boundDeviceSN.String,
			"bound_device_name": boundDeviceName.String,
		}
		if latestVital != nil {
			item["latest_vital"] = latestVital
		}
		list = append(list, item)
	}

	c.JSON(http.StatusOK, utils.SuccessPage(list, total, page.Page, page.PageSize))
}

func GetElderly(c *gin.Context) {
	id := c.Param("id")

	var p struct {
		ID                       string
		Name                     string
		Gender                   string
		Phone                    sql.NullString
		BirthDate                sql.NullTime
		Age                      sql.NullInt64
		Address                  sql.NullString
		CommunityName            sql.NullString
		EmergencyContact         sql.NullString
		EmergencyPhone           sql.NullString
		EmergencyContactRelation sql.NullString
		MedicalHistoryMeta       sql.NullString
		BaselineHeartRate        sql.NullFloat64
		BaselineSpo2             sql.NullFloat64
		BaselineTemp             sql.NullFloat64
		Status                   string
		CreatedAt                time.Time
	}
	err := database.DB.QueryRow(
		`SELECT e.id, e.name, e.gender, e.phone, e.birth_date, NULL as age, e.address,
			c.name as community_name,
			e.emergency_contact, e.emergency_phone, NULL as emergency_contact_relation,
			e.medical_history_meta,
			e.heart_rate_baseline, e.spo2_baseline, e.temp_baseline,
			e.status, e.created_at
		 FROM elderly_profiles e LEFT JOIN communities c ON e.community_id = c.id
		 WHERE e.id = ? AND e.status != 'deleted'`, id,
	).Scan(&p.ID, &p.Name, &p.Gender, &p.Phone, &p.BirthDate, &p.Age, &p.Address,
		&p.CommunityName,
		&p.EmergencyContact, &p.EmergencyPhone, &p.EmergencyContactRelation,
		&p.MedicalHistoryMeta,
		&p.BaselineHeartRate, &p.BaselineSpo2, &p.BaselineTemp,
		&p.Status, &p.CreatedAt)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, utils.Error(apperrors.ErrCodeNotFound, "老人不存在"))
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "查询失败"))
		return
	}

	// 查询绑定的设备信息
	var boundDeviceSN, boundDeviceName sql.NullString
	database.DB.QueryRow(
		`SELECT d.device_sn, COALESCE(d.device_name, CONCAT('手表-', d.device_sn))
		 FROM devices d WHERE d.elderly_id = ? LIMIT 1`, p.ID,
	).Scan(&boundDeviceSN, &boundDeviceName)

	c.JSON(http.StatusOK, utils.Success(gin.H{
		"id":                         p.ID,
		"name":                       p.Name,
		"gender":                     p.Gender,
		"phone":                      p.Phone.String,
		"birth_date":                 p.BirthDate,
		"age":                        p.Age,
		"address":                    p.Address,
		"community_name":             p.CommunityName.String,
		"emergency_contact":          p.EmergencyContact,
		"emergency_phone":            p.EmergencyPhone,
		"emergency_contact_relation": p.EmergencyContactRelation,
		"medical_history_meta":       p.MedicalHistoryMeta,
		"heart_rate_baseline":        p.BaselineHeartRate,
		"spo2_baseline":              p.BaselineSpo2,
		"temp_baseline":              p.BaselineTemp,
		"status":                     p.Status,
		"created_at":                 p.CreatedAt,
		"bound_device_sn":            boundDeviceSN.String,
		"bound_device_name":          boundDeviceName.String,
	}))
}

type CreateElderlyRequest struct {
	Name             string  `json:"name" binding:"required"`
	Gender           string  `json:"gender" binding:"required,oneof=male female"`
	Phone            string  `json:"phone"`
	CommunityName    string  `json:"community_name"`
	Age              int     `json:"age"`
	Address          string  `json:"address"`
	EmergencyContact string  `json:"emergency_contact"`
	EmergencyPhone   string  `json:"emergency_phone"`
	MedicalHistory   string  `json:"medical_history"`
	CareLevel        string  `json:"care_level"`
	HRBaseline       float64 `json:"hr_baseline"`
	Spo2Baseline     float64 `json:"spo2_baseline"`
}

func CreateElderly(c *gin.Context) {
	var req CreateElderlyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	// 老人档案需要关联一个用户账号，先创建该账号
	elderlyUserID := utils.NewUUID()
	username := "elderly_" + elderlyUserID[:8]
	passwordHash, _ := utils.HashPassword("Elderly@123", 12)
	_, err := database.DB.Exec(
		`INSERT INTO users (id, username, password_hash, role, status, real_name, created_at, updated_at)
		 VALUES (?, ?, ?, 'elderly', 'active', ?, NOW(), NOW())`,
		elderlyUserID, username, passwordHash, req.Name,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "创建关联用户账号失败"))
		return
	}

	id := utils.NewUUID()

	// 医疗史字符串转为 JSON，避免 MySQL JSON 列解析失败
	var medicalHistoryMeta interface{}
	if req.MedicalHistory != "" {
		b, _ := json.Marshal(gin.H{"description": req.MedicalHistory})
		medicalHistoryMeta = string(b)
	}

	// 如果传了社区名称，查找对应的 community_id
	var communityID interface{}
	if req.CommunityName != "" {
		var cid string
		err := database.DB.QueryRow("SELECT id FROM communities WHERE name = ?", req.CommunityName).Scan(&cid)
		if err == nil {
			communityID = cid
		}
		// 如果找不到对应社区，community_id 设为 NULL
	}

	_, err = database.DB.Exec(
		`INSERT INTO elderly_profiles (
			id, user_id, name, gender, birth_date, phone, community_id, address,
			emergency_contact, emergency_phone,
			medical_history_meta,
			status, created_at, updated_at
		) VALUES (
			?, ?, ?, ?, DATE_SUB(CURDATE(), INTERVAL ? YEAR), ?, ?, ?,
			?, ?,
			?, 'active', NOW(), NOW()
		)`,
		id, elderlyUserID, req.Name, req.Gender, req.Age, req.Phone, communityID, req.Address,
		req.EmergencyContact, req.EmergencyPhone, medicalHistoryMeta,
	)

	if err != nil {
		// 回滚已创建的用户账号
		database.DB.Exec("DELETE FROM users WHERE id = ?", elderlyUserID)
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "创建老人档案失败"))
		return
	}

	c.JSON(http.StatusCreated, utils.Success(gin.H{"id": id, "message": "创建成功"}))
}

type UpdateElderlyRequest struct {
	Name             string  `json:"name"`
	Gender           string  `json:"gender"`
	Age              int     `json:"age"`
	Phone            string  `json:"phone"`
	CommunityName    string  `json:"community_name"`
	Address          string  `json:"address"`
	EmergencyContact string  `json:"emergency_contact"`
	EmergencyPhone   string  `json:"emergency_phone"`
	MedicalHistory   string  `json:"medical_history"`
	DeviceSN         *string `json:"device_sn"` // 绑定的设备序列号；nil=不修改，ptr("")=解绑，ptr("SN")=绑定时
}

func UpdateElderly(c *gin.Context) {
	id := c.Param("id")
	var req UpdateElderlyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	var medicalHistoryMeta interface{}
	if req.MedicalHistory != "" {
		b, _ := json.Marshal(gin.H{"description": req.MedicalHistory})
		medicalHistoryMeta = string(b)
	}

	var birthDate interface{}
	if req.Age > 0 {
		birthDate = time.Now().AddDate(-req.Age, 0, 0).Format("2006-01-02")
	}

	// 如果传了社区名称，查找对应的 community_id
	var communityID interface{}
	if req.CommunityName != "" {
		var cid string
		err := database.DB.QueryRow("SELECT id FROM communities WHERE name = ?", req.CommunityName).Scan(&cid)
		if err == nil {
			communityID = cid
		}
		// 如果找不到对应社区，community_id 设为 NULL
	}

	// 注意: elderly_profiles 表无 age 列, 紧急联系人是 emergency_contact / emergency_phone
	result, err := database.DB.Exec(
		`UPDATE elderly_profiles SET name=?, gender=?, birth_date=?, phone=?, community_id=?, address=?,
			emergency_contact=?, emergency_phone=?,
			medical_history_meta=?, updated_at=NOW()
		 WHERE id=? AND status!='deleted'`,
		req.Name, req.Gender, birthDate, req.Phone, communityID, req.Address,
		req.EmergencyContact, req.EmergencyPhone,
		medicalHistoryMeta, id,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "更新失败"))
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, utils.Error(apperrors.ErrCodeNotFound, "老人不存在"))
		return
	}

	// 处理设备绑定（DeviceSN 为 *string：nil=不修改，ptr("")=解绑，ptr("SN")=绑定）
	if req.DeviceSN != nil {
		// 1. 先解绑该老人当前关联的所有设备
		_, _ = database.DB.Exec(
			"UPDATE devices SET elderly_id = NULL, updated_at = NOW() WHERE elderly_id = ?",
			id,
		)
		if *req.DeviceSN != "" {
			// 2. 绑定新设备
			_, err = database.DB.Exec(
				"UPDATE devices SET elderly_id = ?, updated_at = NOW() WHERE device_sn = ? AND (elderly_id IS NULL OR elderly_id = ?)",
				id, *req.DeviceSN, id,
			)
			if err != nil {
				logger.Log.Warn("Failed to bind device to elderly",
					zap.String("elderly_id", id),
					zap.String("device_sn", *req.DeviceSN),
					zap.Error(err),
				)
			}
		}
		// *req.DeviceSN == "" 时：只执行解绑，不绑定新设备
	}

	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "更新成功"}))
}

func DeleteElderly(c *gin.Context) {
	id := c.Param("id")

	_, err := database.DB.Exec(
		"UPDATE elderly_profiles SET status='deleted', updated_at=NOW() WHERE id=?",
		id,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "删除失败"))
		return
	}

	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "删除成功"}))
}

// ============ 子女绑定 ============

type BindFamilyRequest struct {
	ElderlyID string `json:"elderly_id" binding:"required"`
	Relation  string `json:"relation" binding:"required"`
}

func CreateFamilyBinding(c *gin.Context) {
	var req BindFamilyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	userID, _ := c.Get("user_id")

	id := utils.NewUUID()
	_, err := database.DB.Exec(
		`INSERT INTO family_bindings (id, user_id, elderly_id, relation, verified, created_at)
		 VALUES (?, ?, ?, ?, false, NOW())`,
		id, userID, req.ElderlyID, req.Relation,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "绑定失败"))
		return
	}

	c.JSON(http.StatusCreated, utils.Success(gin.H{"id": id, "message": "绑定请求已提交"}))
}

func ListFamilyBindings(c *gin.Context) {
	userID, _ := c.Get("user_id")

	rows, err := database.DB.Query(
		`SELECT fb.id, fb.elderly_id, e.name as elderly_name, fb.relation, fb.verified, fb.created_at
		 FROM family_bindings fb JOIN elderly_profiles e ON fb.elderly_id = e.id
		 WHERE fb.user_id = ?`, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "查询失败"))
		return
	}
	defer rows.Close()

	var list []gin.H
	for rows.Next() {
		var id, elderlyID, elderlyName, relation string
		var verified bool
		var createdAt time.Time
		rows.Scan(&id, &elderlyID, &elderlyName, &relation, &verified, &createdAt)
		list = append(list, gin.H{
			"id": id, "elderly_id": elderlyID, "elderly_name": elderlyName,
			"relation": relation, "verified": verified, "created_at": createdAt,
		})
	}

	c.JSON(http.StatusOK, utils.Success(list))
}

func RemoveFamilyBinding(c *gin.Context) {
	id := c.Param("id")
	_, err := database.DB.Exec("DELETE FROM family_bindings WHERE id = ?", id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "解绑失败"))
		return
	}
	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "解绑成功"}))
}

// ============ 社区管理 ============

func ListCommunities(c *gin.Context) {
	rows, err := database.DB.Query(
		`SELECT id, name, address, contact_name, contact_phone, total_elderly, created_at
		 FROM communities ORDER BY name`,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "查询失败"))
		return
	}
	defer rows.Close()

	var list []models.Community
	for rows.Next() {
		var c models.Community
		rows.Scan(&c.ID, &c.Name, &c.Address, &c.ContactName, &c.ContactPhone, &c.TotalElderly, &c.CreatedAt)
		list = append(list, c)
	}

	c.JSON(http.StatusOK, utils.Success(list))
}

func GetCommunity(c *gin.Context) {
	id := c.Param("id")
	var com models.Community
	err := database.DB.QueryRow(
		`SELECT id, name, address, contact_name, contact_phone, total_elderly, created_at
		 FROM communities WHERE id = ?`, id,
	).Scan(&com.ID, &com.Name, &com.Address, &com.ContactName, &com.ContactPhone, &com.TotalElderly, &com.CreatedAt)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, utils.Error(apperrors.ErrCodeNotFound, "社区不存在"))
		return
	}

	c.JSON(http.StatusOK, utils.Success(com))
}

type CreateCommunityRequest struct {
	Name        string `json:"name" binding:"required"`
	Address     string `json:"address"`
	ContactName string `json:"contact_name"`
	ContactPhone string `json:"contact_phone"`
}

func CreateCommunity(c *gin.Context) {
	var req CreateCommunityRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	id := utils.NewUUID()
	_, err := database.DB.Exec(
		`INSERT INTO communities (id, name, address, contact_name, contact_phone, created_at, updated_at)
		 VALUES (?, ?, ?, ?, ?, NOW(), NOW())`,
		id, req.Name, req.Address, req.ContactName, req.ContactPhone,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "创建失败"))
		return
	}

	c.JSON(http.StatusCreated, utils.Success(gin.H{"id": id, "message": "创建成功"}))
}
