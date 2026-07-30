package com.example.elderlyhealth.data.model

import com.google.gson.annotations.SerializedName

data class ApiResponse<T>(
    @SerializedName("code") val code: Int = 0,
    @SerializedName("message") val message: String = "success",
    @SerializedName("data") val data: T? = null,
    @SerializedName("detail") val detail: String? = null,
    @SerializedName("trace_id") val traceId: String? = null
)

data class Pagination(
    @SerializedName("page") val page: Int = 1,
    @SerializedName("page_size") val pageSize: Int = 20,
    @SerializedName("total") val total: Int = 0,
    @SerializedName("total_pages") val totalPages: Int = 0
)

data class PaginatedData<T>(
    @SerializedName("list") val list: List<T> = emptyList(),
    @SerializedName("pagination") val pagination: Pagination = Pagination()
)

data class Position(
    @SerializedName("latitude") val latitude: Double = 0.0,
    @SerializedName("longitude") val longitude: Double = 0.0,
    @SerializedName("altitude") val altitude: Double = 0.0,
    @SerializedName("accuracy") val accuracy: Double = 0.0,
    @SerializedName("position_type") val positionType: String = "",
    @SerializedName("address") val address: String = ""
)

data class VitalSnapshot(
    @SerializedName("heart_rate") val heartRate: Int = 0,
    @SerializedName("spo2") val spo2: Int = 0,
    @SerializedName("temperature") val temperature: Double = 0.0,
    @SerializedName("battery") val battery: Int? = null,
    @SerializedName("steps") val steps: Int? = null,
    @SerializedName("posture") val posture: Int? = null,
    @SerializedName("posture_label") val postureLabel: String? = null
)
