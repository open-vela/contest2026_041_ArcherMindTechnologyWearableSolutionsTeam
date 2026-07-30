package com.example.elderlyhealth.data.api

import com.example.elderlyhealth.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface DashboardApi {
    @GET("dashboard/overview")
    suspend fun getDashboardOverview(
        @Query("community_id") communityId: String
    ): Response<ApiResponse<DashboardOverview>>

    @GET("dashboard/device-online-rate")
    suspend fun getDeviceTrend(
        @Query("community_id") communityId: String,
        @Query("range") range: String = "7d"
    ): Response<ApiResponse<DeviceOnlineRateResponse>>

    @GET("dashboard/alarm-trend")
    suspend fun getAlarmTrend(
        @Query("community_id") communityId: String,
        @Query("range") range: String = "30d"
    ): Response<ApiResponse<AlarmTrendResponse>>
}
