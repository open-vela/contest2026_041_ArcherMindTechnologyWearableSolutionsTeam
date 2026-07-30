package com.example.elderlyhealth.data.api

import com.example.elderlyhealth.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface AlarmApi {
    @GET("alarms")
    suspend fun getAlarmList(
        @Query("community_id") communityId: String? = null,
        @Query("status") status: String? = null,
        @Query("level") level: String? = null,
        @Query("elderly_id") elderlyId: String? = null,
        @Query("from") from: String? = null,
        @Query("to") to: String? = null,
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 20
    ): Response<ApiResponse<AlarmListResponse>>

    @GET("alarms/{alarm_id}")
    suspend fun getAlarmDetail(
        @Path("alarm_id") alarmId: String
    ): Response<ApiResponse<AlarmDetail>>

    @POST("alarms/{alarm_id}/confirm")
    suspend fun confirmAlarm(
        @Path("alarm_id") alarmId: String,
        @Body request: ConfirmAlarmRequest
    ): Response<ApiResponse<ConfirmAlarmResponse>>

    @POST("alarms/{alarm_id}/escalate")
    suspend fun escalateAlarm(
        @Path("alarm_id") alarmId: String
    ): Response<ApiResponse<Unit>>

    @POST("alarms/{alarm_id}/emergency")
    suspend fun emergencyCall(
        @Path("alarm_id") alarmId: String,
        @Body request: EmergencyRequest
    ): Response<ApiResponse<EmergencyResponse>>

    @POST("alarms/{alarm_id}/resolve")
    suspend fun resolveAlarm(
        @Path("alarm_id") alarmId: String,
        @Body request: ResolveAlarmRequest
    ): Response<ApiResponse<Unit>>

    @GET("alarms/stats")
    suspend fun getAlarmStats(@Query("community_id") communityId: String? = null): Response<ApiResponse<AlarmSummary>>
}
