package com.example.elderlyhealth.data.repository

import com.example.elderlyhealth.data.model.ApiResponse
import retrofit2.Response

suspend fun <T> apiCall(allowNullData: Boolean = false, call: suspend () -> Response<ApiResponse<T>>): Result<T> {
    return try {
        val response = call()
        if (response.isSuccessful) {
            val body = response.body()
            if (body != null && (body.code == 0 || body.code == 200)) {
                @Suppress("UNCHECKED_CAST")
                val data = body.data
                if (!allowNullData && data == null) {
                    return Result.failure(Exception("服务返回数据为空"))
                }
                Result.success(data as T)
            } else {
                Result.failure(Exception(body?.message ?: "Unknown error"))
            }
        } else {
            val errorBody = response.errorBody()?.string() ?: response.message()
            Result.failure(Exception("HTTP ${response.code()}: $errorBody"))
        }
    } catch (e: Exception) {
        Result.failure(e)
    }
}

suspend fun <T, R> apiCallMap(
    call: suspend () -> Response<ApiResponse<T>>,
    mapper: (ApiResponse<T>) -> R
): Result<R> {
    return try {
        val response = call()
        if (response.isSuccessful) {
            val body = response.body()
            if (body != null && (body.code == 0 || body.code == 200)) {
                Result.success(mapper(body))
            } else {
                Result.failure(Exception(body?.message ?: "Unknown error"))
            }
        } else {
            Result.failure(Exception("HTTP ${response.code()}: ${response.message()}"))
        }
    } catch (e: Exception) {
        Result.failure(e)
    }
}
