package com.example.elderlyhealth.data.repository

import com.example.elderlyhealth.data.api.AlarmApi
import com.example.elderlyhealth.data.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AlarmRepository @Inject constructor(
    private val alarmApi: AlarmApi
) {
    suspend fun getAlarmList(
        communityId: String? = null,
        status: String? = null,
        level: String? = null,
        elderlyId: String? = null,
        page: Int = 1
    ): Result<AlarmListResponse> = apiCall {
        alarmApi.getAlarmList(communityId, status, level, elderlyId, page = page)
    }

    suspend fun getAlarmDetail(alarmId: String): Result<AlarmDetail> = apiCall {
        alarmApi.getAlarmDetail(alarmId)
    }

    suspend fun confirmAlarm(alarmId: String, result: String, note: String = ""): Result<ConfirmAlarmResponse> = apiCall {
        alarmApi.confirmAlarm(alarmId, ConfirmAlarmRequest(result, note))
    }

    suspend fun escalateAlarm(alarmId: String): Result<Unit> = apiCall(allowNullData = true) {
        alarmApi.escalateAlarm(alarmId)
    }

    suspend fun emergencyCall(alarmId: String, notes: String = ""): Result<EmergencyResponse> = apiCall {
        alarmApi.emergencyCall(alarmId, EmergencyRequest(notes = notes))
    }

    suspend fun resolveAlarm(alarmId: String, comment: String = ""): Result<Unit> = apiCall(allowNullData = true) {
        alarmApi.resolveAlarm(alarmId, ResolveAlarmRequest(comment))
    }
}
