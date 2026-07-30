package com.example.elderlyhealth.data.repository

import com.example.elderlyhealth.data.api.VitalApi
import com.example.elderlyhealth.data.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class VitalRepository @Inject constructor(
    private val vitalApi: VitalApi
) {
    suspend fun getRealtimeVital(elderlyId: String): Result<RealtimeVital> = apiCall {
        vitalApi.getRealtimeVital(elderlyId)
    }

    suspend fun getVitalHistory(
        elderlyId: String,
        metric: String,
        range: String = "24h",
        interval: String = "5m"
    ): Result<VitalHistoryResponse> = apiCall {
        vitalApi.getVitalHistory(elderlyId, metric, range, interval)
    }

    suspend fun getVitalOverview(
        elderlyId: String,
        range: String = "24h"
    ): Result<VitalOverviewResponse> = apiCall {
        vitalApi.getVitalOverview(elderlyId, range)
    }
}
