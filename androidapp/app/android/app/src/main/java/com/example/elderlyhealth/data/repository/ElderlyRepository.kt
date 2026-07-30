package com.example.elderlyhealth.data.repository

import com.example.elderlyhealth.data.api.ElderlyApi
import com.example.elderlyhealth.data.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ElderlyRepository @Inject constructor(
    private val elderlyApi: ElderlyApi
) {
    suspend fun createElderly(request: CreateElderlyRequest): Result<CreateElderlyResponse> = apiCall {
        elderlyApi.createElderly(request)
    }

    suspend fun getElderlyList(
        communityId: String? = null,
        keyword: String? = null,
        status: String? = null,
        page: Int = 1
    ): Result<PaginatedData<ElderlyProfile>> = apiCallMap(
        call = { elderlyApi.getElderlyList(page = page, communityId = communityId, keyword = keyword, status = status) },
        mapper = { PaginatedData(list = it.data ?: emptyList()) }
    )

    suspend fun getElderlyDetail(elderlyId: String): Result<ElderlyProfile> = runCatching {
        android.util.Log.d("ElderlyRepo", "getElderlyDetail: id=$elderlyId")
        val response = elderlyApi.getElderlyDetail(elderlyId)
        android.util.Log.d("ElderlyRepo", "URL: ${response.raw().request.url}")
        if (!response.isSuccessful) {
            val error = response.errorBody()?.string() ?: "请求失败"
            throw Exception(error)
        }
        val body = response.body() ?: throw Exception("响应为空")
        val data = body.data ?: throw Exception("服务返回数据为空")
        android.util.Log.d("ElderlyRepo", "response body data: $data")
        val detailResponse = com.google.gson.Gson().fromJson(data, ElderlyDetailResponse::class.java)
        val profile = detailResponse.toElderlyProfile()
        android.util.Log.d("ElderlyRepo", "parsed id=${profile.id} name=${profile.name}")
        profile
    }

    suspend fun updateElderly(elderlyId: String, request: UpdateElderlyRequest): Result<Unit> = apiCall {
        elderlyApi.updateElderly(elderlyId, request)
    }

    suspend fun bindElderly(request: BindElderlyRequest): Result<Unit> = apiCall {
        elderlyApi.bindElderly(request)
    }

    suspend fun getMyBindings(): Result<List<BindingInfo>> = apiCallMap(
        call = { elderlyApi.getMyBindings() },
        mapper = { it.data?.list ?: emptyList() }
    )

    suspend fun unbindElderly(bindingId: String): Result<Unit> = apiCall(allowNullData = true) {
        elderlyApi.unbindElderly(bindingId)
    }
}
