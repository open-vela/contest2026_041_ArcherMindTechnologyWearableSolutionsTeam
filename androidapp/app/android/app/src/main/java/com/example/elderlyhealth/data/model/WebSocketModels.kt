package com.example.elderlyhealth.data.model

import com.google.gson.annotations.SerializedName

data class WsMessage(
    @SerializedName("type") val type: String = "",
    @SerializedName("timestamp") val timestamp: String = "",
    @SerializedName("payload") val payload: Map<String, Any?> = emptyMap(),
    @SerializedName("message_id") val messageId: String = ""
)

data class WsSubscribeRequest(
    @SerializedName("action") val action: String,
    @SerializedName("topic") val topic: String
)

data class WsPing(
    @SerializedName("action") val action: String = "ping"
)

data class WsPong(
    @SerializedName("action") val action: String = "",
    @SerializedName("timestamp") val timestamp: String = ""
)

data class WsVitalUpdate(
    @SerializedName("elderly_id") val elderlyId: String = "",
    @SerializedName("heart_rate") val heartRate: Int = 0,
    @SerializedName("spo2") val spo2: Int = 0,
    @SerializedName("temperature") val temperature: Double = 0.0,
    @SerializedName("steps") val steps: Int = 0
)

data class WsAlarmNotify(
    @SerializedName("alarm_id") val alarmId: String = "",
    @SerializedName("elderly_id") val elderlyId: String = "",
    @SerializedName("level") val level: String = "",
    @SerializedName("type") val type: String = "",
    @SerializedName("title") val title: String = ""
)

data class WsSigninNotify(
    @SerializedName("elderly_id") val elderlyId: String = "",
    @SerializedName("date") val date: String = "",
    @SerializedName("status") val status: String = "",
    @SerializedName("signed_at") val signedAt: String = ""
)

data class WsDeviceStatus(
    @SerializedName("device_id") val deviceId: String = "",
    @SerializedName("online") val online: Boolean = false,
    @SerializedName("battery") val battery: Int = 0
)

// Alert level priorities
enum class AlarmLevel(val value: String, val priority: Int) {
    P0("P0", 0),
    P1("P1", 1),
    P2("P2", 2),
    P3("P3", 3);

    companion object {
        fun fromValue(value: String): AlarmLevel =
            entries.find { it.value == value } ?: P3
    }
}

enum class AlarmStatus(val value: String) {
    CREATED("CREATED"),
    DISPATCHED("DISPATCHED"),
    CONFIRMED("CONFIRMED"),
    RESOLVED("RESOLVED"),
    ESCALATED("ESCALATED");

    companion object {
        fun fromValue(value: String): AlarmStatus =
            entries.find { it.value == value } ?: CREATED
    }
}

enum class UserRole(val value: String) {
    ELDERLY("elderly"),
    FAMILY("family"),
    COMMUNITY("community"),
    ADMIN("admin"),
    DEVICE("device");

    companion object {
        fun fromValue(value: String): UserRole =
            entries.find { it.value == value } ?: FAMILY
    }
}
