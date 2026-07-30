package com.example.elderlyhealth.util

import com.example.elderlyhealth.BuildConfig
import com.example.elderlyhealth.data.model.ApiResponse
import com.example.elderlyhealth.data.model.LoginResponse
import com.example.elderlyhealth.data.model.RefreshTokenRequest
import com.google.gson.Gson
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import okhttp3.Authenticator
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import okhttp3.Route
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TokenRefreshAuthenticator @Inject constructor(
    private val tokenManager: TokenManager,
    private val gson: Gson
) : Authenticator {

    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()

    override fun authenticate(route: Route?, response: Response): Request? {
        if (response.request.header("Authorization") == null) return null

        synchronized(this) {
            val currentToken = runBlocking { tokenManager.accessToken.first() }
            if (currentToken == null) return null

            val refreshToken = runBlocking { tokenManager.refreshToken.first() } ?: return null

            val refreshRequest = RefreshTokenRequest(refreshToken)
            val jsonBody = gson.toJson(refreshRequest)
                .toRequestBody("application/json".toMediaType())

            val request = Request.Builder()
                .url("${BuildConfig.BASE_URL}/auth/refresh")
                .post(jsonBody)
                .header("Content-Type", "application/json")
                .build()

            try {
                val refreshResponse = client.newCall(request).execute()
                if (!refreshResponse.isSuccessful) return null

                val body = refreshResponse.body?.string() ?: return null
                val apiResponse = gson.fromJson(body, ApiResponse::class.java)
                if (apiResponse.code != 0 && apiResponse.code != 200) return null

                val data = gson.fromJson(gson.toJson(apiResponse.data), LoginResponse::class.java)
                runBlocking {
                    tokenManager.saveTokens(data.accessToken, data.refreshToken)
                }

                return response.request.newBuilder()
                    .header("Authorization", "Bearer ${data.accessToken}")
                    .header("Content-Type", "application/json")
                    .build()
            } catch (_: Exception) {
                return null
            }
        }
    }
}