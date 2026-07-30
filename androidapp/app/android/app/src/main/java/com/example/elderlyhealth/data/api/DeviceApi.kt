package com.example.elderlyhealth.data.api

import com.example.elderlyhealth.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface DeviceApi {
    @POST("devices")
    suspend fun registerDevice(@Body request: DeviceRegisterRequest): Response<ApiResponse<Unit>>

    @GET("devices")
    suspend fun getDeviceList(
        @Query("community_id") communityId: String? = null,
        @Query("status") status: String? = null,
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 50
    ): Response<ApiResponse<List<DeviceModels>>>

    @GET("devices/{device_id}")
    suspend fun getDeviceDetail(
        @Path("device_id") deviceId: String
    ): Response<ApiResponse<DeviceModels>>

    @PUT("devices/{device_id}")
    suspend fun updateDevice(
        @Path("device_id") deviceId: String,
        @Body request: DeviceRegisterRequest
    ): Response<ApiResponse<Unit>>

    @DELETE("devices/{device_id}")
    suspend fun deleteDevice(
        @Path("device_id") deviceId: String
    ): Response<ApiResponse<Unit>>

    @POST("devices/{device_id}/unbind")
    suspend fun unbindDevice(
        @Path("device_id") deviceId: String
    ): Response<ApiResponse<Unit>>

    @PUT("devices/{device_id}/bind")
    suspend fun bindDevice(
        @Path("device_id") deviceId: String,
        @Body request: Map<String, String>
    ): Response<ApiResponse<Unit>>

    @GET("devices/stats")
    suspend fun getDeviceStats(
        @Query("community_id") communityId: String? = null
    ): Response<ApiResponse<Unit>>
}
