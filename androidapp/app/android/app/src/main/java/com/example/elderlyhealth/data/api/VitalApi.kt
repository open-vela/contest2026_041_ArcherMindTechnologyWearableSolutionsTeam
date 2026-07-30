package com.example.elderlyhealth.data.api

import com.example.elderlyhealth.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface VitalApi {
    @GET("vitals/{elderly_id}/realtime")
    suspend fun getRealtimeVital(
        @Path("elderly_id") elderlyId: String
    ): Response<ApiResponse<RealtimeVital>>

    @GET("vitals/{elderly_id}/history")
    suspend fun getVitalHistory(
        @Path("elderly_id") elderlyId: String,
        @Query("metric") metric: String,
        @Query("range") range: String = "24h",
        @Query("interval") interval: String = "5m",
        @Query("from") from: String? = null,
        @Query("to") to: String? = null
    ): Response<ApiResponse<VitalHistoryResponse>>

    @GET("vitals/{elderly_id}/overview")
    suspend fun getVitalOverview(
        @Path("elderly_id") elderlyId: String,
        @Query("range") range: String = "24h"
    ): Response<ApiResponse<VitalOverviewResponse>>
}
