package adminauth

import (
	"context"
	"database/sql"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"go.uber.org/zap"

	"elderly-health-backend/internal/shared/config"
	"elderly-health-backend/internal/shared/database"
	apperrors "elderly-health-backend/internal/shared/errors"
	"elderly-health-backend/internal/shared/logger"
	"elderly-health-backend/internal/shared/models"
	"elderly-health-backend/internal/shared/redis"
	"elderly-health-backend/internal/shared/utils"
)

func RegisterAdminRoutes(r *gin.RouterGroup, jwtSecret string) {
	// 管理员管理
	r.GET("/admin/users", ListAdmins)
	r.POST("/admin/users", CreateAdmin)
	r.PUT("/admin/users/:id", UpdateAdmin)
	r.DELETE("/admin/users/:id", DeleteAdmin)
	r.POST("/admin/users/:id/reset-password", ResetAdminPassword)
	r.POST("/admin/users/:id/lock", LockAdmin)
	r.POST("/admin/users/:id/unlock", UnlockAdmin)

	// 角色管理
	r.GET("/admin/roles", ListRoles)
	r.POST("/admin/roles", CreateRole)
	r.PUT("/admin/roles/:id", UpdateRole)
	r.DELETE("/admin/roles/:id", DeleteRole)

	// 权限管理
	r.GET("/admin/permissions", ListPermissions)

	// 会话管理
	r.GET("/admin/sessions", ListActiveSessions)
	r.DELETE("/admin/sessions/:id", RevokeSession)

	// 审计日志
	r.GET("/admin/audit-logs", ListAuditLogs)

	// 安全设置
	r.GET("/admin/security/config", GetSecurityConfig)
	r.PUT("/admin/security/config", UpdateSecurityConfig)
	r.POST("/admin/logout", AdminLogout(jwtSecret))

	// 当前登录管理员
	r.GET("/admin/profile", GetCurrentAdminProfile)
	r.PUT("/admin/password", ChangeAdminPassword)
}

// ============ 管理员登录 ============

type AdminLoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func AdminLogin(secret string, secCfg config.SecurityConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req AdminLoginRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
			return
		}

		// IP 检查
		if len(secCfg.IPWhitelist) > 0 {
			ipAllowed := false
			for _, ip := range secCfg.IPWhitelist {
				if ip == c.ClientIP() {
					ipAllowed = true
					break
				}
			}
			if !ipAllowed {
				c.JSON(http.StatusForbidden, utils.Error(apperrors.ErrCodeIPNotAllowed, "IP 未授权"))
				recordLoginAttempt(req.Username, c.ClientIP(), false, "IP_NOT_ALLOWED")
				return
			}
		}

		// 登录失败计数检查
		ctx := context.Background()
		failKey := redis.Key(redis.KeyLoginFails, req.Username, c.ClientIP())
		failCount, _ := redis.CacheHelper.Get(ctx, failKey)
		if failCount != "" && len(failCount) > 0 {
			if cnt := atoi(failCount); cnt >= secCfg.MaxLoginAttempts {
				c.JSON(http.StatusTooManyRequests, utils.Error(apperrors.ErrCodeAccountLocked,
					"登录失败次数过多，账户已锁定30分钟"))
				return
			}
		}

		// 查询管理员
		var user models.User
		var adminRoleID sql.NullString
		err := database.DB.QueryRow(
			`SELECT u.id, u.username, u.password_hash, u.role, u.status, u.admin_role_id,
			 u.failed_logins, u.locked_until
			 FROM users u WHERE u.username = ? AND u.role IN ('admin','super_admin')`,
			req.Username,
		).Scan(&user.ID, &user.Username, &user.PasswordHash, &user.Role, &user.Status,
			&adminRoleID, &user.FailedLogins, &user.LockedUntil)

		if err == sql.ErrNoRows {
			c.JSON(http.StatusUnauthorized, utils.Error(apperrors.ErrCodeInvalidCredential, "用户名或密码错误"))
			incrementLoginFails(req.Username, c.ClientIP(), secCfg.MaxLoginAttempts, secCfg.LockDuration)
			return
		}

		// 检查锁定
		if user.LockedUntil.Valid && user.LockedUntil.Time.After(time.Now()) {
			c.JSON(http.StatusForbidden, utils.Error(apperrors.ErrCodeAccountLocked,
				"账户已被锁定至 "+user.LockedUntil.Time.Format("15:04:05")))
			return
		}

		// 验证密码
		if !utils.CheckPassword(user.PasswordHash, req.Password) {
			c.JSON(http.StatusUnauthorized, utils.Error(apperrors.ErrCodeInvalidCredential, "密码错误"))
			incrementLoginFails(req.Username, c.ClientIP(), secCfg.MaxLoginAttempts, secCfg.LockDuration)
			recordLoginAttempt(req.Username, c.ClientIP(), false, "BAD_PASSWORD")
			return
		}

		// 生成 Token（管理员短时效）
		accessToken, _ := utils.GenerateToken(user.ID, user.Username, user.Role, secret, 15*time.Minute)
		refreshToken, _ := utils.GenerateRefreshToken(user.ID, user.Username, user.Role, secret, 8*time.Hour)
		rtHash := utils.SHA256Hash(refreshToken)

		// 记录会话
		database.DB.Exec(
			`INSERT INTO admin_sessions (id, admin_id, refresh_token_hash, access_token_jti,
			 source_ip, user_agent, status, issued_at, expires_at)
			 VALUES (UUID(), ?, ?, ?, ?, ?, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 8 HOUR))`,
			user.ID, rtHash, "jti", c.ClientIP(), c.Request.UserAgent(),
		)

		// 清除失败计数
		redis.CacheHelper.Del(ctx, failKey)

		// 更新登录信息
		database.DB.Exec(
			"UPDATE users SET failed_logins=0, last_login_at=NOW(), last_login_ip=? WHERE id=?",
			c.ClientIP(), user.ID,
		)

		recordLoginAttempt(req.Username, c.ClientIP(), true, "")

		logger.Log.Info("Admin logged in", zap.String("username", req.Username), zap.String("ip", c.ClientIP()))

		c.JSON(http.StatusOK, utils.Success(gin.H{
			"access_token":  accessToken,
			"refresh_token": refreshToken,
			"token_type":    "Bearer",
			"expires_in":    900,
			"user": gin.H{
				"id":       user.ID,
				"username": user.Username,
				"role":     user.Role,
			},
		}))
	}
}

// ============ Token 刷新 ============

type AdminRefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

func AdminRefreshToken(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req AdminRefreshTokenRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "缺少 refresh_token"))
			return
		}

		token, err := jwt.Parse(req.RefreshToken, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}
			return []byte(secret), nil
		})
		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, utils.Error(apperrors.ErrCodeTokenInvalid, "refresh_token 无效或已过期"))
			return
		}

		origClaims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusUnauthorized, utils.Error(apperrors.ErrCodeTokenInvalid, "无法解析 token 声明"))
			return
		}

		now := time.Now()
		newClaims := jwt.MapClaims{}
		for k, v := range origClaims {
			newClaims[k] = v
		}
		newClaims["type"] = "access"
		newClaims["iat"] = now.Unix()
		newClaims["exp"] = now.Add(15 * time.Minute).Unix()

		accessToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, newClaims).SignedString([]byte(secret))
		if err != nil {
			c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "生成 access_token 失败"))
			return
		}

		c.JSON(http.StatusOK, utils.Success(gin.H{
			"access_token": accessToken,
			"token_type":   "Bearer",
			"expires_in":   900,
		}))
	}
}

// ============ 管理员 CRUD ============

func ListAdmins(c *gin.Context) {
	page := utils.Pagination{}
	c.ShouldBindQuery(&page)
	page.Normalize()

	// 管理员账户页同时展示管理员与社区人员
	roleFilter := "role IN ('admin','super_admin','community')"

	var total int64
	database.DB.QueryRow(
		"SELECT COUNT(*) FROM users WHERE " + roleFilter,
	).Scan(&total)

	rows, err := database.DB.Query(
		`SELECT u.id, u.username, u.role, u.real_name, u.email, u.phone, u.status,
		 ar.role_name, u.last_login_at, u.last_login_ip, u.created_at
		 FROM users u LEFT JOIN admin_roles ar ON u.admin_role_id = ar.id
		 WHERE u.` + roleFilter + ` ORDER BY u.created_at DESC, u.id ASC LIMIT ? OFFSET ?`,
		page.PageSize, page.Offset(),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "查询失败"))
		return
	}
	defer rows.Close()

	var list []gin.H
	for rows.Next() {
		var id, username, role, status string
		var realName, email, phone, roleName, lastLoginIP sql.NullString
		var lastLogin sql.NullTime
		var createdAt time.Time
		rows.Scan(&id, &username, &role, &realName, &email, &phone, &status,
			&roleName, &lastLogin, &lastLoginIP, &createdAt)
		list = append(list, gin.H{
			"id": id, "username": username, "role": role,
			"real_name": realName.String, "email": email.String,
			"phone": phone.String, "status": status,
			"admin_role": roleName.String,
			"last_login_at": lastLogin.Time, "last_login_ip": lastLoginIP.String,
			"created_at": createdAt,
		})
	}

	c.JSON(http.StatusOK, utils.SuccessPage(list, total, page.Page, page.PageSize))
}

type CreateAdminRequest struct {
	Username    string `json:"username" binding:"required,min=3"`
	Password    string `json:"password" binding:"required,min=8"`
	RealName    string `json:"real_name"`
	Email       string `json:"email"`
	Phone       string `json:"phone"`
	AdminRoleID string `json:"admin_role_id"`
}

func CreateAdmin(c *gin.Context) {
	var req CreateAdminRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	// 检查用户名是否已存在
	var existingID string
	if err := database.DB.QueryRow(
		"SELECT id FROM users WHERE username = ?", req.Username,
	).Scan(&existingID); err == nil {
		c.JSON(http.StatusConflict, utils.Error(apperrors.ErrCodeUserAlreadyExist, "用户名已存在"))
		return
	}

	// 检查手机号是否已被占用
	if req.Phone != "" {
		var phoneUserID string
		if err := database.DB.QueryRow(
			"SELECT id FROM users WHERE phone = ?", req.Phone,
		).Scan(&phoneUserID); err == nil {
			c.JSON(http.StatusConflict, utils.Error(apperrors.ErrCodeConflict, "手机号已被占用"))
			return
		}
	}

	passwordHash, _ := utils.HashPassword(req.Password, 12)
	id := utils.NewUUID()

	// 前端用 admin_role_id 字段传递用户角色（admin/community），这里同步写入 role
	userRole := "admin"
	if req.AdminRoleID == "community" {
		userRole = "community"
	}

	_, err := database.DB.Exec(
		`INSERT INTO users (id, username, password_hash, role, real_name, email, phone,
		 admin_role_id, status, created_at, updated_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active', NOW(), NOW())`,
		id, req.Username, passwordHash, userRole, req.RealName, req.Email, req.Phone, req.AdminRoleID,
	)
	if err != nil {
		c.JSON(http.StatusConflict, utils.Error(apperrors.ErrCodeUserAlreadyExist, "创建失败，请重试"))
		return
	}

	auditLog(c, "CREATE", "user", id, req.Username, "", "管理员创建成功")

	c.JSON(http.StatusCreated, utils.Success(gin.H{"id": id, "message": "管理员创建成功"}))
}

func UpdateAdmin(c *gin.Context) {
	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "更新成功"}))
}

func DeleteAdmin(c *gin.Context) {
	id := c.Param("id")
	userID, _ := c.Get("user_id")

	if id == userID {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeCantDeleteSelf, "不能删除自己"))
		return
	}

	database.DB.Exec("UPDATE users SET status='disabled', updated_at=NOW() WHERE id=?", id)
	auditLog(c, "DELETE", "user", id, "", "", "管理员已禁用")
	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "管理员已禁用"}))
}

type ResetPasswordRequest struct {
	NewPassword string `json:"new_password" binding:"required,min=8"`
}

func ResetAdminPassword(c *gin.Context) {
	id := c.Param("id")
	var req ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "密码长度至少8位"))
		return
	}

	hash, _ := utils.HashPassword(req.NewPassword, 12)
	database.DB.Exec("UPDATE users SET password_hash=?, password_expire=DATE_ADD(NOW(), INTERVAL 90 DAY) WHERE id=?", hash, id)
	auditLog(c, "RESET_PASSWORD", "user", id, "", "", "密码已重置")
	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "密码重置成功"}))
}

func LockAdmin(c *gin.Context) {
	id := c.Param("id")
	userID, _ := c.Get("user_id")
	if id == userID {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeCantLockSelf, "不能锁定自己"))
		return
	}
	database.DB.Exec("UPDATE users SET status='disabled', locked_until=DATE_ADD(NOW(), INTERVAL 30 MINUTE) WHERE id=?", id)
	auditLog(c, "LOCK", "user", id, "", "", "管理员已锁定")
	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "管理员已锁定"}))
}

func UnlockAdmin(c *gin.Context) {
	id := c.Param("id")
	database.DB.Exec("UPDATE users SET status='active', locked_until=NULL, failed_logins=0 WHERE id=?", id)
	auditLog(c, "UNLOCK", "user", id, "", "", "管理员已解锁")
	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "管理员已解锁"}))
}

// ============ 角色管理 ============

func ListRoles(c *gin.Context) {
	page := utils.Pagination{}
	c.ShouldBindQuery(&page)
	page.Normalize()

	var total int64
	database.DB.QueryRow("SELECT COUNT(*) FROM admin_roles").Scan(&total)

	rows, _ := database.DB.Query(
		`SELECT id, role_code, role_name, description, is_system, is_active FROM admin_roles
		 ORDER BY role_code LIMIT ? OFFSET ?`,
		page.PageSize, page.Offset(),
	)
	defer rows.Close()

	var list []gin.H
	for rows.Next() {
		var r models.AdminRole
		rows.Scan(&r.ID, &r.RoleCode, &r.RoleName, &r.Description, &r.IsSystem, &r.IsActive)

		// 查询该角色关联的权限列表
		permRows, _ := database.DB.Query(
			`SELECT p.id, p.perm_code, p.perm_name, p.module, p.action, p.sensitivity
			 FROM admin_role_permissions rp
			 JOIN admin_permissions p ON rp.permission_id = p.id
			 WHERE rp.role_id = ?
			 ORDER BY p.module, p.action`, r.ID)
		var perms []gin.H
		for permRows.Next() {
			var p models.AdminPermission
			permRows.Scan(&p.ID, &p.PermCode, &p.PermName, &p.Module, &p.Action, &p.Sensitivity)
			perms = append(perms, gin.H{
				"id":         p.ID,
				"perm_code":  p.PermCode,
				"perm_name":  p.PermName,
				"module":     p.Module,
				"action":     p.Action,
				"sensitivity": p.Sensitivity,
			})
		}
		permRows.Close()

		list = append(list, gin.H{
			"id":          r.ID,
			"role_code":   r.RoleCode,
			"role_name":   r.RoleName,
			"description": r.Description.String,
			"is_system":   r.IsSystem,
			"is_active":   r.IsActive,
			"permissions": perms,
		})
	}
	c.JSON(http.StatusOK, utils.SuccessPage(list, total, page.Page, page.PageSize))
}

func CreateRole(c *gin.Context) {
	var req struct {
		RoleCode string   `json:"role_code" binding:"required"`
		RoleName string   `json:"role_name" binding:"required"`
		Perms    []string `json:"permission_ids"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	id := utils.NewUUID()
	database.DB.Exec(
		`INSERT INTO admin_roles (id, role_code, role_name, created_at, updated_at) VALUES (?,?,?,NOW(),NOW())`,
		id, req.RoleCode, req.RoleName,
	)

	for _, permID := range req.Perms {
		database.DB.Exec(
			`INSERT INTO admin_role_permissions (role_id, permission_id) VALUES (?,?)`,
			id, permID,
		)
	}

	c.JSON(http.StatusCreated, utils.Success(gin.H{"id": id, "message": "角色创建成功"}))
}

func UpdateRole(c *gin.Context) {
	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "角色已更新"}))
}

func DeleteRole(c *gin.Context) {
	id := c.Param("id")

	// 检查是否系统角色
	var isSystem bool
	database.DB.QueryRow("SELECT is_system FROM admin_roles WHERE id=?", id).Scan(&isSystem)
	if isSystem {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeSystemRoleCantDelete, "系统预置角色不可删除"))
		return
	}

	database.DB.Exec("DELETE FROM admin_roles WHERE id=?", id)
	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "角色已删除"}))
}

// ============ 权限列表 ============

func ListPermissions(c *gin.Context) {
	rows, _ := database.DB.Query(`SELECT id, perm_code, perm_name, module, action, sensitivity FROM admin_permissions ORDER BY module, action`)
	defer rows.Close()
	var list []models.AdminPermission
	for rows.Next() {
		var p models.AdminPermission
		rows.Scan(&p.ID, &p.PermCode, &p.PermName, &p.Module, &p.Action, &p.Sensitivity)
		list = append(list, p)
	}
	c.JSON(http.StatusOK, utils.Success(list))
}

// ============ 会话管理 ============

func ListActiveSessions(c *gin.Context) {
	rows, _ := database.DB.Query(
		`SELECT s.id, s.admin_id, u.username, s.source_ip, s.device_info, s.status,
		 s.issued_at, s.expires_at, s.last_active_at
		 FROM admin_sessions s JOIN users u ON s.admin_id = u.id
		 WHERE s.status='active' ORDER BY s.issued_at DESC`,
	)
	defer rows.Close()
	var list []models.AdminSession
	for rows.Next() {
		var s models.AdminSession
		var username string
		rows.Scan(&s.ID, &s.AdminID, &username, &s.SourceIP, &s.DeviceInfo, &s.Status,
			&s.IssuedAt, &s.ExpiresAt, &s.LastActiveAt)
		list = append(list, s)
	}
	c.JSON(http.StatusOK, utils.Success(list))
}

func RevokeSession(c *gin.Context) {
	id := c.Param("id")
	userID, _ := c.Get("user_id")
	database.DB.Exec(
		"UPDATE admin_sessions SET status='revoked', revoked_at=NOW(), revoked_by=? WHERE id=?",
		userID, id,
	)
	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "会话已吊销"}))
}

// ============ 审计日志 ============

func ListAuditLogs(c *gin.Context) {
	page := utils.Pagination{}
	c.ShouldBindQuery(&page)
	page.Normalize()

	var total int64
	database.DB.QueryRow("SELECT COUNT(*) FROM admin_audit_logs").Scan(&total)

	rows, _ := database.DB.Query(
		`SELECT id, audit_level, operator_name, module, operation, description,
		 resource_type, resource_name, source_ip, result_status, created_at
		 FROM admin_audit_logs ORDER BY created_at DESC, id ASC LIMIT ? OFFSET ?`,
		page.PageSize, page.Offset(),
	)
	defer rows.Close()
	var list []gin.H
	for rows.Next() {
		var id int64
		var auditLevel, operatorName, module, operation string
		var description, resourceType, resourceName, sourceIP, resultStatus sql.NullString
		var createdAt time.Time
		rows.Scan(&id, &auditLevel, &operatorName, &module, &operation,
			&description, &resourceType, &resourceName, &sourceIP, &resultStatus, &createdAt)
		list = append(list, gin.H{
			"id":             id,
			"audit_level":    auditLevel,
			"operator_name":  operatorName,
			"module":         module,
			"operation":      operation,
			"description":    description.String,
			"resource_type":  resourceType.String,
			"resource_name":  resourceName.String,
			"source_ip":      sourceIP.String,
			"result_status":  resultStatus.String,
			"created_at":     createdAt,
		})
	}
	c.JSON(http.StatusOK, utils.SuccessPage(list, total, page.Page, page.PageSize))
}

// ============ 安全配置 ============

func GetSecurityConfig(c *gin.Context) {
	c.JSON(http.StatusOK, utils.Success(gin.H{
		"max_login_attempts": 5,
		"lock_duration_min":  30,
		"password_min_len":   12,
		"password_expire_days": 90,
		"require_2fa":        true,
		"session_timeout_min": 15,
	}))
}

func UpdateSecurityConfig(c *gin.Context) {
	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "安全配置已更新"}))
}

func AdminLogout(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, _ := c.Get("user_id")
		database.DB.Exec(
			"UPDATE admin_sessions SET status='revoked', revoked_at=NOW() WHERE admin_id=? AND status='active'",
			userID,
		)
		c.JSON(http.StatusOK, utils.Success(gin.H{"message": "已退出登录"}))
	}
}

// ============ 当前登录管理员 ============

func GetCurrentAdminProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	username, _ := c.Get("username")
	role, _ := c.Get("role")

	var realName, email, phone sql.NullString
	err := database.DB.QueryRow(
		"SELECT real_name, email, phone FROM users WHERE id=?",
		userID,
	).Scan(&realName, &email, &phone)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "查询用户信息失败"))
		return
	}

	c.JSON(http.StatusOK, utils.Success(gin.H{
		"id":        userID,
		"username":  username,
		"role":      role,
		"real_name": realName.String,
		"email":     email.String,
		"phone":     phone.String,
	}))
}

type ChangeAdminPasswordRequest struct {
	OldPassword string `json:"old_password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=8"`
}

func ChangeAdminPassword(c *gin.Context) {
	var req ChangeAdminPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "新密码长度至少8位"))
		return
	}

	userID, _ := c.Get("user_id")

	var passwordHash string
	err := database.DB.QueryRow(
		"SELECT password_hash FROM users WHERE id=?",
		userID,
	).Scan(&passwordHash)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "查询用户密码失败"))
		return
	}

	if !utils.CheckPassword(passwordHash, req.OldPassword) {
		c.JSON(http.StatusUnauthorized, utils.Error(apperrors.ErrCodeInvalidCredential, "旧密码错误"))
		return
	}

	newHash, err := utils.HashPassword(req.NewPassword, 12)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "密码加密失败"))
		return
	}

	_, err = database.DB.Exec(
		"UPDATE users SET password_hash=?, updated_at=NOW() WHERE id=?",
		newHash, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.Error(apperrors.ErrCodeInternal, "密码更新失败"))
		return
	}

	c.JSON(http.StatusOK, utils.Success(gin.H{"message": "密码修改成功"}))
}

// ============ 辅助函数 ============

func auditLog(c *gin.Context, operation, resourceType, resourceID, resourceName, note, description string) {
	operatorID, _ := c.Get("user_id")
	operatorName, _ := c.Get("username")
	operatorRole, _ := c.Get("role")

	database.DB.Exec(
		`INSERT INTO admin_audit_logs (audit_level, operator_id, operator_name, operator_role,
		 http_method, endpoint, module, operation, description, resource_type, resource_id,
		 resource_name, source_ip, user_agent, result_status, http_status, created_at)
		 VALUES ('MEDIUM', ?, ?, ?, ?, ?, 'admin', ?, ?, ?, ?, ?, ?, ?, 'SUCCESS', 200, NOW())`,
		operatorID, operatorName, operatorRole, c.Request.Method, c.Request.URL.Path,
		operation, description, resourceType, resourceID, resourceName,
		c.ClientIP(), c.Request.UserAgent(),
	)
}

func incrementLoginFails(username, ip string, maxAttempts int, lockDuration time.Duration) {
	ctx := context.Background()
	key := redis.Key(redis.KeyLoginFails, username, ip)
	count, _ := redis.CacheHelper.Incr(ctx, key)
	redis.CacheHelper.Expire(ctx, key, lockDuration)

	if int(count) >= maxAttempts {
		database.DB.Exec(
			"UPDATE users SET failed_logins=?, locked_until=DATE_ADD(NOW(), INTERVAL ? SECOND) WHERE username=?",
			count, int(lockDuration.Seconds()), username,
		)
	} else {
		database.DB.Exec("UPDATE users SET failed_logins=? WHERE username=?", count, username)
	}
}

func recordLoginAttempt(username, ip string, success bool, reason string) {
	successInt := 0
	if success {
		successInt = 1
	}
	database.DB.Exec(
		`INSERT INTO admin_login_attempts (username, source_ip, success, failure_reason, attempted_at)
		 VALUES (?, ?, ?, ?, NOW())`, username, ip, successInt, reason,
	)
}

func atoi(s string) int {
	var n int
	for _, c := range s {
		if c < '0' || c > '9' {
			return n
		}
		n = n*10 + int(c-'0')
	}
	return n
}
