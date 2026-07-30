package com.example.elderlyhealth.data.repository

import com.example.elderlyhealth.data.api.DeviceApi
import com.example.elderlyhealth.data.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DeviceRepository @Inject constructor(
    private val deviceApi: DeviceApi
) {
    suspend fun getDeviceList(
        communityId: String? = null,
        status: String? = null,
        page: Int = 1
    ): Result<PaginatedData<DeviceModels>> = apiCallMap(
        call = { deviceApi.getDeviceList(communityId, status, page) },
        mapper = { response -> PaginatedData(list = response.data ?: emptyList()) }
    )

    suspend fun getDeviceDetail(deviceId: String): Result<DeviceModels> = apiCall {
        deviceApi.getDeviceDetail(deviceId)
    }

    suspend fun registerDevice(request: DeviceRegisterRequest): Result<Unit> = apiCall(allowNullData = true) {
        deviceApi.registerDevice(request)
    }

    suspend fun unbindDevice(deviceId: String): Result<Unit> = apiCall(allowNullData = true) {
        deviceApi.unbindDevice(deviceId)
    }

    suspend fun bindDevice(deviceId: String, elderlyId: String): Result<Unit> = apiCall(allowNullData = true) {
        deviceApi.bindDevice(deviceId, mapOf("elderly_id" to elderlyId))
    }

    suspend fun updateDevice(deviceId: String, request: DeviceRegisterRequest): Result<Unit> = apiCall(allowNullData = true) {
        deviceApi.updateDevice(deviceId, request)
    }

    suspend fun deleteDevice(deviceId: String): Result<Unit> = apiCall(allowNullData = true) {
        deviceApi.deleteDevice(deviceId)
    }

    suspend fun getDeviceStats(communityId: String? = null): Result<Unit> = apiCall(allowNullData = true) {
        deviceApi.getDeviceStats(communityId)
    }
}
