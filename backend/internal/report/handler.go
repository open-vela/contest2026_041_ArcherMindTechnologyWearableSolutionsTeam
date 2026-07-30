package report

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"elderly-health-backend/internal/shared/database"
	apperrors "elderly-health-backend/internal/shared/errors"
	"elderly-health-backend/internal/shared/middleware"
	"elderly-health-backend/internal/shared/utils"
)

func RegisterRoutes(r *gin.RouterGroup, jwtSecret string) {
	auth := r.Group("")
	auth.Use(middleware.JWTAuth(jwtSecret))
	{
		auth.GET("/reports", ListReports)
		auth.GET("/reports/:id", GetReport)
		auth.POST("/reports/generate", GenerateReport)
	}
}

func ListReports(c *gin.Context) {
	elderlyID := c.Query("elderly_id")
	page := utils.Pagination{}
	c.ShouldBindQuery(&page)
	page.Normalize()

	var total int64
	query := "SELECT COUNT(*) FROM health_reports WHERE 1=1"
	args := []interface{}{}
	if elderlyID != "" {
		query += " AND elderly_id = ?"
		args = append(args, elderlyID)
	}
	database.DB.QueryRow(query, args...).Scan(&total)

	rows, _ := database.DB.Query(
		`SELECT id, elderly_id, report_week, health_score, abnormal_events,
		 avg_heart_rate, avg_spo2, total_steps, signin_rate, generated_by, generated_at
		 FROM health_reports ORDER BY generated_at DESC LIMIT ? OFFSET ?`,
		page.PageSize, page.Offset(),
	)
	defer rows.Close()

	var list []gin.H
	for rows.Next() {
		var id, eID, reportWeek, generatedBy string
		var healthScore, abnormalEvents, totalSteps int
		var avgHR, avgSpO2, signinRate float64
		var generatedAt time.Time
		rows.Scan(&id, &eID, &reportWeek, &healthScore, &abnormalEvents,
			&avgHR, &avgSpO2, &totalSteps, &signinRate, &generatedBy, &generatedAt)
		list = append(list, gin.H{
			"id": id, "elderly_id": eID, "report_week": reportWeek,
			"health_score": healthScore, "abnormal_events": abnormalEvents,
			"avg_heart_rate": avgHR, "avg_spo2": avgSpO2,
			"total_steps": totalSteps, "signin_rate": signinRate,
			"generated_by": generatedBy, "generated_at": generatedAt,
		})
	}

	c.JSON(http.StatusOK, utils.SuccessPage(list, total, page.Page, page.PageSize))
}

func GetReport(c *gin.Context) {
	id := c.Param("id")

	var r struct {
		ID, ElderlyID, ReportWeek, AISummary, Suggestions string
		HealthScore, AbnormalEvents, TotalSteps           int
		AvgHeartRate, AvgSpO2, SigninRate                float64
		TrendSummaryJSON                                  string
		GeneratedAt                                       time.Time
	}

	err := database.DB.QueryRow(
		`SELECT id, elderly_id, report_week, health_score, abnormal_events,
		 avg_heart_rate, avg_spo2, total_steps, signin_rate, trend_summary_json,
		 ai_summary, suggestions, generated_at
		 FROM health_reports WHERE id = ?`, id,
	).Scan(&r.ID, &r.ElderlyID, &r.ReportWeek, &r.HealthScore, &r.AbnormalEvents,
		&r.AvgHeartRate, &r.AvgSpO2, &r.TotalSteps, &r.SigninRate,
		&r.TrendSummaryJSON, &r.AISummary, &r.Suggestions, &r.GeneratedAt)

	if err != nil {
		c.JSON(http.StatusNotFound, utils.Error(apperrors.ErrCodeNotFound, "报告不存在"))
		return
	}

	c.JSON(http.StatusOK, utils.Success(r))
}

type GenerateReportRequest struct {
	ElderlyID string `json:"elderly_id" binding:"required"`
}

func GenerateReport(c *gin.Context) {
	var req GenerateReportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.Error(apperrors.ErrCodeBadRequest, "参数错误"))
		return
	}

	// 计算本周统计数据
	weekStart := utils.StartOfWeek(time.Now())
	reportWeek := utils.ReportWeek(time.Now())

	// 统计本周异常事件
	var abnormalEvents int
	database.DB.QueryRow(
		`SELECT COUNT(*) FROM alarm_records WHERE elderly_id=? AND created_at >= ?`,
		req.ElderlyID, weekStart,
	).Scan(&abnormalEvents)

	// 统计平均心率、血氧
	var avgHR, avgSpO2 float64
	database.DB.QueryRow(
		`SELECT AVG(COALESCE(heart_rate,0)), AVG(COALESCE(spo2,0))
		 FROM vital_signs WHERE elderly_id=? AND reported_at >= ?`,
		req.ElderlyID, weekStart,
	).Scan(&avgHR, &avgSpO2)

	// 统计步数
	var totalSteps int
	database.DB.QueryRow(
		`SELECT SUM(COALESCE(steps,0)) FROM vital_signs WHERE elderly_id=? AND reported_at >= ?`,
		req.ElderlyID, weekStart,
	).Scan(&totalSteps)

	// 统计签到率
	var signinTotal, signinChecked int
	database.DB.QueryRow(
		`SELECT COUNT(*), SUM(CASE WHEN signin_status='checked_in' THEN 1 ELSE 0 END)
		 FROM signin_records WHERE elderly_id=? AND signin_date >= ?`,
		req.ElderlyID, weekStart.Format("2006-01-02"),
	).Scan(&signinTotal, &signinChecked)

	signinRate := float64(0)
	if signinTotal > 0 {
		signinRate = float64(signinChecked) / float64(signinTotal) * 100
	}

	healthScore := utils.CalculateHealthScore(abnormalEvents)

	// 生成 AI 摘要（简化版本，实际应调用 LLM）
	aiSummary := "本周长者整体健康状况良好。"
	if abnormalEvents > 0 {
		aiSummary = "本周发生了异常事件，请关注长者健康状况。"
	}

	suggestions := "建议保持规律作息，适量运动，注意饮食均衡。"

	id := utils.NewUUID()
	userID, _ := c.Get("user_id")

	database.DB.Exec(
		`INSERT INTO health_reports (id, elderly_id, report_week, health_score, abnormal_events,
		 avg_heart_rate, avg_spo2, total_steps, signin_rate, ai_summary, suggestions,
		 generated_by, generated_at, created_at)
		 VALUES (?,?,?,?,?,?,?,?,?,?,?,?,NOW(),NOW())`,
		id, req.ElderlyID, reportWeek, healthScore, abnormalEvents,
		avgHR, avgSpO2, totalSteps, signinRate, aiSummary, suggestions, userID,
	)

	c.JSON(http.StatusCreated, utils.Success(gin.H{
		"id":            id,
		"report_week":   reportWeek,
		"health_score":  healthScore,
		"abnormal_events": abnormalEvents,
		"avg_heart_rate":  avgHR,
		"avg_spo2":        avgSpO2,
		"total_steps":     totalSteps,
		"signin_rate":     signinRate,
		"ai_summary":      aiSummary,
		"suggestions":     suggestions,
	}))
}
