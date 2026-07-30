package com.example.elderlyhealth.data.model

import com.google.gson.annotations.SerializedName

data class DashboardOverview(
    @SerializedName("elderly") val elderly: DashboardElderlyStats = DashboardElderlyStats(),
    @SerializedName("devices") val devices: DashboardDeviceStats = DashboardDeviceStats(),
    @SerializedName("alarms") val alarms: DashboardAlarmStats = DashboardAlarmStats(),
    @SerializedName("signin") val signin: DashboardSigninStats = DashboardSigninStats(),
    @SerializedName("patrols") val patrols: DashboardPatrolStats = DashboardPatrolStats()
)

data class DashboardElderlyStats(
    @SerializedName("total") val total: Int = 0,
    @SerializedName("active") val active: Int = 0
)

data class DashboardDeviceStats(
    @SerializedName("total") val total: Int = 0,
    @SerializedName("online") val online: Int = 0
)

data class DashboardAlarmStats(
    @SerializedName("p0") val p0: Int = 0,
    @SerializedName("p1") val p1: Int = 0,
    @SerializedName("p2") val p2: Int = 0,
    @SerializedName("p3") val p3: Int = 0
)

data class DashboardSigninStats(
    @SerializedName("today_signed") val todaySigned: Int = 0,
    @SerializedName("today_total") val todayTotal: Int = 0
)

data class DashboardPatrolStats(
    @SerializedName("pending") val pending: Int = 0
)

data class DeviceOnlineRateResponse(
    @SerializedName("current_rate") val currentRate: Double = 0.0,
    @SerializedName("online_devices") val onlineDevices: Int = 0,
    @SerializedName("total_devices") val totalDevices: Int = 0
)

data class AlarmTrendResponse(
    @SerializedName("data_points") val dataPoints: List<AlarmTrendPoint> = emptyList(),
    @SerializedName("summary") val alarmTrendSummary: AlarmTrendSummary = AlarmTrendSummary()
)

data class AlarmTrendPoint(
    @SerializedName("date") val date: String = "",
    @SerializedName("p0") val p0: Int = 0,
    @SerializedName("p1") val p1: Int = 0,
    @SerializedName("p2") val p2: Int = 0,
    @SerializedName("p3") val p3: Int = 0
)

data class AlarmTrendSummary(
    @SerializedName("period_total") val periodTotal: Int = 0,
    @SerializedName("p0_total") val p0Total: Int = 0,
    @SerializedName("p1_total") val p1Total: Int = 0,
    @SerializedName("avg_response_seconds_p0") val avgResponseSecondsP0: Double = 0.0,
    @SerializedName("avg_response_seconds_p1") val avgResponseSecondsP1: Double = 0.0
)


