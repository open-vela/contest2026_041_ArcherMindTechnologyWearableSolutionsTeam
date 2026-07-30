package com.example.elderlyhealth.data.api

import com.example.elderlyhealth.data.model.*
import com.google.gson.JsonElement
import retrofit2.Response
import retrofit2.http.*

interface ElderlyApi {
    @POST("elderly")
    suspend fun createElderly(@Body request: CreateElderlyRequest): Response<ApiResponse<CreateElderlyResponse>>

    @GET("elderly")
    suspend fun getElderlyList(
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 20,
        @Query("community_id") communityId: String? = null,
        @Query("keyword") keyword: String? = null,
        @Query("status") status: String? = null
    ): Response<ApiResponse<List<ElderlyProfile>>>

    @GET("elderly/{elderly_id}")
    suspend fun getElderlyDetail(@Path("elderly_id") elderlyId: String): Response<ApiResponse<JsonElement>>

    @PUT("elderly/{elderly_id}")
    suspend fun updateElderly(
        @Path("elderly_id") elderlyId: String,
        @Body request: UpdateElderlyRequest
    ): Response<ApiResponse<Unit>>

    @POST("bindings")
    suspend fun bindElderly(@Body request: BindElderlyRequest): Response<ApiResponse<Unit>>

    @GET("bindings")
    suspend fun getMyBindings(): Response<ApiResponse<BindingsResponse>>

    @PUT("bindings/{binding_id}")
    suspend fun updateBinding(
        @Path("binding_id") bindingId: String,
        @Body request: BindElderlyRequest
    ): Response<ApiResponse<Unit>>

    @DELETE("bindings/{binding_id}")
    suspend fun unbindElderly(@Path("binding_id") bindingId: String): Response<ApiResponse<Unit>>
}
