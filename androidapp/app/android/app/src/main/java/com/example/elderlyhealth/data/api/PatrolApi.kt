package com.example.elderlyhealth.data.api

import com.example.elderlyhealth.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface PatrolApi {
    @GET("patrol/tasks")
    suspend fun getPatrolTasks(
        @Query("community_id") communityId: String? = null,
        @Query("status") status: String? = null,
        @Query("staff_id") staffId: String? = null,
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 20
    ): Response<ApiResponse<PaginatedData<PatrolTask>>>

    @POST("patrol/tasks/{task_id}/assign")
    suspend fun assignPatrolTask(
        @Path("task_id") taskId: String,
        @Body request: AssignPatrolRequest
    ): Response<ApiResponse<Unit>>

    @POST("patrol/tasks/{task_id}/start")
    suspend fun startPatrolTask(
        @Path("task_id") taskId: String
    ): Response<ApiResponse<Unit>>

    @POST("patrol/tasks/{task_id}/submit")
    suspend fun submitPatrolRecord(
        @Path("task_id") taskId: String,
        @Body request: PatrolRecordRequest
    ): Response<ApiResponse<Unit>>

    @GET("patrol/records")
    suspend fun getPatrolRecords(
        @Query("task_id") taskId: String? = null,
        @Query("staff_id") staffId: String? = null,
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 20
    ): Response<ApiResponse<Unit>>
}
