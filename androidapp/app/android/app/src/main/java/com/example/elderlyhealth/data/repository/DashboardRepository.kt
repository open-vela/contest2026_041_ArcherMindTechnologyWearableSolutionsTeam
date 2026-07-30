package com.example.elderlyhealth.data.repository

import com.example.elderlyhealth.data.api.DashboardApi
import com.example.elderlyhealth.data.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DashboardRepository @Inject constructor(
    private val dashboardApi: DashboardApi
) {
    suspend fun getOverview(communityId: String): Result<DashboardOverview> = apiCall {
        dashboardApi.getDashboardOverview(communityId)
    }

    suspend fun getDeviceTrend(communityId: String, range: String = "7d"): Result<DeviceOnlineRateResponse> = apiCall {
        dashboardApi.getDeviceTrend(communityId, range)
    }

    suspend fun getAlarmTrend(communityId: String, range: String = "30d"): Result<AlarmTrendResponse> = apiCall {
        dashboardApi.getAlarmTrend(communityId, range)
    }
}
