package com.example.elderlyhealth.data.repository

import com.example.elderlyhealth.data.api.PatrolApi
import com.example.elderlyhealth.data.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PatrolRepository @Inject constructor(
    private val patrolApi: PatrolApi
) {
    suspend fun getPatrolTasks(
        communityId: String? = null,
        status: String? = null,
        page: Int = 1
    ): Result<PaginatedData<PatrolTask>> = apiCall {
        patrolApi.getPatrolTasks(communityId, status, page = page)
    }

    suspend fun assignTask(taskId: String, staffId: String): Result<Unit> = apiCall(allowNullData = true) {
        patrolApi.assignPatrolTask(taskId, AssignPatrolRequest(staffId))
    }

    suspend fun submitRecord(taskId: String, request: PatrolRecordRequest): Result<Unit> = apiCall(allowNullData = true) {
        patrolApi.submitPatrolRecord(taskId, request)
    }

    suspend fun getPatrolRecords(page: Int = 1): Result<Unit> = apiCall(allowNullData = true) {
        patrolApi.getPatrolRecords(page = page)
    }
}
