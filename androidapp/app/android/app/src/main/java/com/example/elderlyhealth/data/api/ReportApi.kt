package com.example.elderlyhealth.data.api

import com.example.elderlyhealth.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface ReportApi {
    @GET("reports")
    suspend fun getReportList(
        @Query("elderly_id") elderlyId: String,
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 10
    ): Response<ApiResponse<PaginatedData<ReportItem>>>

    @GET("reports/{report_id}")
    suspend fun getReportDetail(
        @Path("report_id") reportId: String
    ): Response<ApiResponse<ReportDetail>>
}
