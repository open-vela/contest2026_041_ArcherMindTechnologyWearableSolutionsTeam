package com.example.elderlyhealth.data.model

import com.google.gson.annotations.SerializedName

data class PatrolTask(
    @SerializedName("id") val id: String = "",
    @SerializedName("elderly_id") val elderlyId: String = "",
    @SerializedName("elderly_name") val elderlyName: String = "",
    @SerializedName("task_type") val taskType: String = "",
    @SerializedName("priority") val priority: String = "",
    @SerializedName("description") val description: String = "",
    @SerializedName("status") val status: String = "",
    @SerializedName("assigned_to") val assignedTo: String? = null,
    @SerializedName("assigned_name") val assignedName: String? = null,
    @SerializedName("scheduled_date") val scheduledDate: String = "",
    @SerializedName("created_at") val createdAt: String = ""
)

data class AssignPatrolRequest(
    @SerializedName("staff_id") val staffId: String,
    @SerializedName("priority") val priority: String = "P1"
)

data class PatrolRecordRequest(
    @SerializedName("elderly_id") val elderlyId: String,
    @SerializedName("visit_at") val visitAt: String,
    @SerializedName("visit_duration") val visitDuration: Int = 1800,
    @SerializedName("elderly_status") val elderlyStatus: String = "",
    @SerializedName("check_items") val checkItems: PatrolCheckItems? = null,
    @SerializedName("remarks") val remarks: String = "",
    @SerializedName("need_follow_up") val needFollowUp: Boolean = false
)

data class PatrolCheckItems(
    @SerializedName("blood_pressure") val bloodPressure: String? = null,
    @SerializedName("blood_sugar") val bloodSugar: Double? = null,
    @SerializedName("general_condition") val generalCondition: String? = null,
    @SerializedName("mood") val mood: String? = null,
    @SerializedName("home_environment") val homeEnvironment: String? = null
)

data class PatrolAttachment(
    @SerializedName("type") val type: String = "",
    @SerializedName("url") val url: String = ""
)
