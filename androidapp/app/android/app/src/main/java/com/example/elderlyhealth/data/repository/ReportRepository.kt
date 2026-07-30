package com.example.elderlyhealth.data.repository

import com.example.elderlyhealth.data.api.ReportApi
import com.example.elderlyhealth.data.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ReportRepository @Inject constructor(
    private val reportApi: ReportApi
) {
    suspend fun getReportList(
        elderlyId: String,
        page: Int = 1
    ): Result<PaginatedData<ReportItem>> = apiCall {
        reportApi.getReportList(elderlyId, page)
    }

    suspend fun getReportDetail(reportId: String): Result<ReportDetail> = apiCall {
        reportApi.getReportDetail(reportId)
    }
}
