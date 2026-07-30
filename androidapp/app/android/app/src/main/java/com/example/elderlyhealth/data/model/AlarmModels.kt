package com.example.elderlyhealth.data.model

import com.google.gson.annotations.SerializedName

data class AlarmItem(
    @SerializedName("alarm_id") val alarmId: String = "",
    @SerializedName("elderly_name") val elderlyName: String = "",
    @SerializedName("alarm_source") val alarmSource: String = "",
    @SerializedName("elderly") val elderly: AlarmElderly = AlarmElderly(),
    @SerializedName("alarm_type") val alarmType: String = "",
    @SerializedName("alarm_type_label") val alarmTypeLabel: String = "",
    @SerializedName("alarm_level") val alarmLevel: String = "",
    @SerializedName("title") val title: String = "",
    @SerializedName("description") val description: String = "",
    @SerializedName("vital_snapshot") val vitalSnapshot: VitalSnapshot? = null,
    @SerializedName("location_snapshot") val locationSnapshot: Position? = null,
    @SerializedName("status") val status: String = "",
    @SerializedName("status_label") val statusLabel: String = "",
    @SerializedName("created_at") val createdAt: String = "",
    @SerializedName("dispatched_at") val dispatchedAt: String? = null,
    @SerializedName("elapsed_seconds") val elapsedSeconds: Int = 0,
    @SerializedName("family_response") val familyResponse: String? = null,
    @SerializedName("is_120_called") val is120Called: Boolean = false,
    @SerializedName("device") val device: AlarmDevice? = null
)

data class AlarmDetailData(
    @SerializedName("alarm_id") val alarmId: String = "",
    @SerializedName("alarm_type") val alarmType: String = "",
    @SerializedName("alarm_level") val alarmLevel: String = "",
    @SerializedName("title") val title: String = "",
    @SerializedName("description") val description: String = "",
    @SerializedName("elderly_id") val elderlyId: String = "",
    @SerializedName("elderly_name") val elderlyName: String = "",
    @SerializedName("elderly") val elderly: AlarmElderlyDetail = AlarmElderlyDetail(),
    @SerializedName("device") val device: AlarmDevice? = null,
    @SerializedName("vital_snapshot_json") val vitalSnapshotJson: String? = null,
    @SerializedName("location_json") val locationJson: String? = null,
    @SerializedName("status") val status: String = "",
    @SerializedName("created_at") val createdAt: String = "",
    @SerializedName("timeline") val timeline: List<AlarmTimeline> = emptyList(),
    @SerializedName("notification_status") val notificationStatus: NotificationStatus? = null,
    @SerializedName("handling_logs") val handlingLogs: List<HandlingLog> = emptyList()
)

data class AlarmDetail(
    @SerializedName("alarm") val alarm: AlarmDetailData = AlarmDetailData(),
    @SerializedName("logs") val logs: List<HandlingLog> = emptyList()
)

data class AlarmSummary(
    @SerializedName("total") val total: Int = 0,
    @SerializedName("p0_count") val p0Count: Int = 0,
    @SerializedName("p1_count") val p1Count: Int = 0,
    @SerializedName("p2_count") val p2Count: Int = 0,
    @SerializedName("p3_count") val p3Count: Int = 0,
    @SerializedName("unhandled") val unhandled: Int = 0
)

data class AlarmElderly(
    @SerializedName("elderly_id") val elderlyId: String = "",
    @SerializedName("name") val name: String = "",
    @SerializedName("address") val address: String = ""
)

data class AlarmElderlyDetail(
    @SerializedName("elderly_id") val elderlyId: String = "",
    @SerializedName("name") val name: String = "",
    @SerializedName("age") val age: Int = 0,
    @SerializedName("address") val address: String = "",
    @SerializedName("emergency_contact") val emergencyContact: EmergencyContact? = null,
    @SerializedName("medical_history") val medicalHistory: MedicalHistory? = null
)

data class AlarmDevice(
    @SerializedName("device_id") val deviceId: String = "",
    @SerializedName("device_sn") val deviceSn: String = ""
)

data class AlarmTimeline(
    @SerializedName("action") val action: String = "",
    @SerializedName("at") val at: String = "",
    @SerializedName("by") val by: String = ""
)

data class NotificationStatus(
    @SerializedName("push") val push: String = "",
    @SerializedName("sms") val sms: String = "",
    @SerializedName("phone") val phone: String = "",
    @SerializedName("websocket") val websocket: String = ""
)

data class HandlingLog(
    @SerializedName("action") val action: String = "",
    @SerializedName("operator") val operator: String = "",
    @SerializedName("note") val note: String = "",
    @SerializedName("created_at") val createdAt: String = ""
)

data class ConfirmAlarmRequest(
    @SerializedName("confirm_result") val confirmResult: String,
    @SerializedName("note") val note: String = ""
)

data class ConfirmAlarmResponse(
    @SerializedName("alarm_id") val alarmId: String = "",
    @SerializedName("status") val status: String = "",
    @SerializedName("confirmed_at") val confirmedAt: String = ""
)

class EscalateAlarmRequest

data class EmergencyRequest(
    @SerializedName("initiator") val initiator: String = "community",
    @SerializedName("notes") val notes: String = ""
)

data class EmergencyResponse(
    @SerializedName("alarm_id") val alarmId: String = "",
    @SerializedName("120_call_id") val callId: String = "",
    @SerializedName("status") val status: String = "",
    @SerializedName("info_pushed") val infoPushed: EmergencyInfo? = null
)

data class EmergencyInfo(
    @SerializedName("elderly_name") val elderlyName: String = "",
    @SerializedName("age") val age: Int = 0,
    @SerializedName("address") val address: String = "",
    @SerializedName("latest_vital") val latestVital: VitalSnapshot? = null,
    @SerializedName("medical_history") val medicalHistory: MedicalHistory? = null,
    @SerializedName("emergency_contact") val emergencyContact: String = ""
)

data class ResolveAlarmRequest(
    @SerializedName("comment") val comment: String = ""
)

data class AlarmListResponse(
    @SerializedName("list") val list: List<AlarmItem> = emptyList(),
    @SerializedName("summary") val summary: AlarmSummary? = null,
    @SerializedName("pagination") val pagination: Pagination = Pagination()
)


