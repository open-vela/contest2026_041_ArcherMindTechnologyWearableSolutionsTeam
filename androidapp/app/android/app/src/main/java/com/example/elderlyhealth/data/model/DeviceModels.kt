package com.example.elderlyhealth.data.model

import com.google.gson.annotations.SerializedName

data class DeviceModels(
    @SerializedName("id") val id: String = "",
    @SerializedName("device_sn") val deviceSn: String = "",
    @SerializedName("device_type") val deviceType: String = "",
    @SerializedName("elderly_name") val elderlyName: String = "",
    @SerializedName("is_online") val isOnline: Boolean = false,
    @SerializedName("status") val status: String = "",
    @SerializedName("battery") val battery: Int = 0,
    @SerializedName("signal_strength") val signalStrength: Int = 0,
    @SerializedName("firmware_version") val firmwareVersion: String = "",
    @SerializedName("last_online_at") val lastOnlineAt: String = "",
    @SerializedName("created_at") val createdAt: String = ""
) {
    val elderlyId: String get() = ""
}

data class DeviceRegisterRequest(
    @SerializedName("device_sn") val deviceSn: String,
    @SerializedName("device_name") val deviceName: String,
    @SerializedName("device_type") val deviceType: String = "BES2700",
    @SerializedName("elderly_id") val elderlyId: String? = null
)
