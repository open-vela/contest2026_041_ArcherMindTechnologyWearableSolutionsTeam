package com.example.elderlyhealth.data.model

import com.google.gson.annotations.SerializedName

data class ReportItem(
    @SerializedName("report_id") val reportId: String = "",
    @SerializedName("elderly_id") val elderlyId: String = "",
    @SerializedName("elderly_name") val elderlyName: String = "",
    @SerializedName("report_week_start") val reportWeekStart: String = "",
    @SerializedName("report_week_end") val reportWeekEnd: String = "",
    @SerializedName("report_title") val reportTitle: String = "",
    @SerializedName("health_score") val healthScore: Int = 0,
    @SerializedName("summary") val reportSummary: ReportSummary = ReportSummary(),
    @SerializedName("created_at") val createdAt: String = ""
)

data class ReportSummary(
    @SerializedName("avg_heart_rate") val avgHeartRate: Int = 0,
    @SerializedName("avg_spo2") val avgSpo2: Int = 0,
    @SerializedName("total_steps") val totalSteps: Int = 0,
    @SerializedName("anomalies") val anomalies: Int = 0,
    @SerializedName("trend") val trend: String = "stable"
)

data class ReportDetail(
    @SerializedName("report_id") val reportId: String = "",
    @SerializedName("elderly_name") val elderlyName: String = "",
    @SerializedName("report_week") val reportWeek: String = "",
    @SerializedName("health_score") val healthScore: Int = 0,
    @SerializedName("report_content") val reportContent: String = "",
    @SerializedName("summary_meta") val summaryMeta: ReportSummary = ReportSummary(),
    @SerializedName("anomaly_events") val anomalyEvents: List<AnomalyEvent> = emptyList(),
    @SerializedName("advice_list") val adviceList: List<HealthAdvice> = emptyList()
)

data class AnomalyEvent(
    @SerializedName("date") val date: String = "",
    @SerializedName("type") val type: String = "",
    @SerializedName("detail") val detail: String = "",
    @SerializedName("alarm_id") val alarmId: String? = null
)

data class HealthAdvice(
    @SerializedName("category") val category: String = "",
    @SerializedName("advice") val advice: String = ""
)
