package com.example.elderlyhealth.data.model

import com.google.gson.annotations.SerializedName

data class RealtimeVital(
    @SerializedName("elderly_id") val elderlyId: String = "",
    @SerializedName("device_id") val deviceId: String = "",
    @SerializedName("heart_rate") val heartRate: Int = 0,
    @SerializedName("spo2") val spo2: Int = 0,
    @SerializedName("temperature") val temperature: Double = 0.0,
    @SerializedName("steps") val steps: Int = 0,
    @SerializedName("activity_level") val activityLevel: Int = 0,
    @SerializedName("posture") val posture: Int = 0,
    @SerializedName("posture_label") val postureLabel: String = "",
    @SerializedName("battery") val battery: Int = 0,
    @SerializedName("device_online") val deviceOnline: Boolean = false,
    @SerializedName("updated_at") val updatedAt: String = ""
)

data class VitalHistoryResponse(
    @SerializedName("metric") val metric: String = "",
    @SerializedName("unit") val unit: String = "",
    @SerializedName("interval") val interval: String = "",
    @SerializedName("baseline") val baseline: VitalBaseline? = null,
    @SerializedName("summary") val summary: VitalSummary? = null,
    @SerializedName("data_points") val dataPoints: List<VitalDataPoint> = emptyList()
)

data class VitalSummary(
    @SerializedName("avg") val avg: Double = 0.0,
    @SerializedName("max") val max: Double = 0.0,
    @SerializedName("min") val min: Double = 0.0,
    @SerializedName("anomalies") val anomalies: Int = 0
)

data class VitalDataPoint(
    @SerializedName("ts") val ts: String = "",
    @SerializedName("value") val value: Double = 0.0
)

data class VitalOverviewResponse(
    @SerializedName("range") val range: String = "24h",
    @SerializedName("heart_rate") val heartRate: VitalMetric = VitalMetric(),
    @SerializedName("spo2") val spo2: VitalMetric = VitalMetric(),
    @SerializedName("temperature") val temperature: VitalMetric = VitalMetric(),
    @SerializedName("steps") val steps: StepMetric = StepMetric()
)

data class VitalMetric(
    @SerializedName("current") val current: Double = 0.0,
    @SerializedName("avg") val avg: Double = 0.0,
    @SerializedName("max") val max: Double = 0.0,
    @SerializedName("min") val min: Double = 0.0,
    @SerializedName("trend") val trend: String = "stable",
    @SerializedName("unit") val unit: String = ""
)

data class StepMetric(
    @SerializedName("total_today") val totalToday: Int = 0,
    @SerializedName("avg_daily_7d") val avgDaily7d: Int = 0,
    @SerializedName("trend") val trend: String = "stable",
    @SerializedName("unit") val unit: String = "步"
)
