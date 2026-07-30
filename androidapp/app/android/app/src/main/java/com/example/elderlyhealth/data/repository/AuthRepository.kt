package com.example.elderlyhealth.data.repository

import com.example.elderlyhealth.data.api.AuthApi
import com.example.elderlyhealth.data.model.*
import com.example.elderlyhealth.util.TokenManager
import com.example.elderlyhealth.util.UserInfo
import kotlinx.coroutines.flow.first
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val authApi: AuthApi,
    private val tokenManager: TokenManager
) {
    suspend fun login(username: String, password: String): Result<LoginResponse> = apiCall {
        authApi.login(LoginRequest(username, password))
    }

    suspend fun smsLogin(phone: String, smsCode: String): Result<LoginResponse> = apiCall {
        authApi.smsLogin(SmsLoginRequest(phone, smsCode))
    }

    suspend fun sendSms(phone: String, scene: String = "login"): Result<Unit> = apiCall(allowNullData = true) {
        authApi.sendSms(SendSmsRequest(phone, scene))
    }

    suspend fun refreshToken(): Result<LoginResponse> {
        val refresh = tokenManager.refreshToken.first() ?: return Result.failure(Exception("No refresh token"))
        return apiCall { authApi.refreshToken(RefreshTokenRequest(refresh)) }.also { result ->
            result.onSuccess { response ->
                tokenManager.saveTokens(response.accessToken, response.refreshToken)
            }
        }
    }

    suspend fun logout(): Result<Unit> = apiCall(allowNullData = true) {
        authApi.logout()
    }

    suspend fun saveSession(response: LoginResponse) {
        tokenManager.saveTokens(response.accessToken, response.refreshToken)
        with(response.user) {
            tokenManager.saveUserInfo(
                com.example.elderlyhealth.util.UserInfo(
                    userId = userId,
                    username = username,
                    realName = realName,
                    role = role,
                    avatarUrl = avatarUrl,
                    communityId = communityId
                )
            )
        }
    }

    suspend fun clearSession() {
        tokenManager.clear()
    }

    suspend fun isLoggedIn(): Boolean {
        return !tokenManager.accessToken.first().isNullOrBlank()
    }

    suspend fun getCurrentRole(): String {
        return tokenManager.userInfo.first().role
    }

    suspend fun getProfile() = apiCall {
        authApi.getProfile()
    }

    suspend fun changePassword(oldPassword: String, newPassword: String): Result<Unit> = apiCall(allowNullData = true) {
        authApi.changePassword(ChangePasswordRequest(oldPassword, newPassword))
    }
}
