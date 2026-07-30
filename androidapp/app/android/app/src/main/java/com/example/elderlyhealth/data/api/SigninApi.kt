package com.example.elderlyhealth.data.api

import com.example.elderlyhealth.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface SigninApi {
    @GET("signin/today")
    suspend fun getTodaySignin(
        @Query("elderly_id") elderlyId: String,
        @Query("date") date: String? = null
    ): Response<ApiResponse<TodaySigninStatus>>

    @GET("signin/{elderly_id}/calendar")
    suspend fun getSigninCalendar(
        @Path("elderly_id") elderlyId: String,
        @Query("month") month: String
    ): Response<ApiResponse<SigninCalendarResponse>>

    @GET("signin/overview")
    suspend fun getSigninOverview(
        @Query("community_id") communityId: String,
        @Query("date") date: String
    ): Response<ApiResponse<SigninOverviewResponse>>

    @POST("signin/proxy")
    suspend fun manualSignin(
        @Body request: ManualSigninRequest
    ): Response<ApiResponse<Unit>>
}
