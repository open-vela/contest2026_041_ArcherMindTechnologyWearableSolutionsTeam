package com.example.elderlyhealth.data.api

import com.example.elderlyhealth.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface AuthApi {
    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): Response<ApiResponse<LoginResponse>>

    @POST("auth/sms/login")
    suspend fun smsLogin(@Body request: SmsLoginRequest): Response<ApiResponse<LoginResponse>>

    @POST("auth/sms/send")
    suspend fun sendSms(@Body request: SendSmsRequest): Response<ApiResponse<Unit>>

    @POST("auth/refresh")
    suspend fun refreshToken(@Body request: RefreshTokenRequest): Response<ApiResponse<LoginResponse>>

    @POST("auth/logout")
    suspend fun logout(): Response<ApiResponse<Unit>>

    @GET("auth/profile")
    suspend fun getProfile(): Response<ApiResponse<UserInfo>>

    @PUT("auth/password")
    suspend fun changePassword(@Body request: ChangePasswordRequest): Response<ApiResponse<Unit>>
}
