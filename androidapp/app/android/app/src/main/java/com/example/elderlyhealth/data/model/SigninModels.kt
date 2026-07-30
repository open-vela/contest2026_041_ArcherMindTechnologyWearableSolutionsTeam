package com.example.elderlyhealth.data.model

import com.google.gson.annotations.SerializedName

data class TodaySigninStatus(
    @SerializedName("elderly_id") val elderlyId: String = "",
    @SerializedName("date") val date: String = "",
    @SerializedName("status") val status: String = "",
    @SerializedName("signed_at") val signedAt: String? = null,
    @SerializedName("method") val method: String? = null,
    @SerializedName("reminder_count") val reminderCount: Int = 0,
    @SerializedName("last_reminder_at") val lastReminderAt: String? = null
)

data class SigninCalendarResponse(
    @SerializedName("elderly_id") val elderlyId: String = "",
    @SerializedName("month") val month: String = "",
    @SerializedName("signin_rate") val signinRate: Double = 0.0,
    @SerializedName("days") val days: List<CalendarDay> = emptyList()
)

data class CalendarDay(
    @SerializedName("date") val date: String = "",
    @SerializedName("status") val status: String = "",
    @SerializedName("signed_at") val signedAt: String? = null
)

data class SigninOverviewResponse(
    @SerializedName("signed") val signed: Int = 0,
    @SerializedName("unsigned") val unsigned: Int = 0,
    @SerializedName("timeout") val timeout: Int = 0,
    @SerializedName("total") val total: Int = 0,
    @SerializedName("rate") val rate: Double = 0.0
)

data class ManualSigninRequest(
    @SerializedName("elderly_id") val elderlyId: String,
    @SerializedName("method") val method: String = "COMMUNITY_MANUAL",
    @SerializedName("notes") val notes: String = "",
    @SerializedName("operator") val operator: String = ""
)
