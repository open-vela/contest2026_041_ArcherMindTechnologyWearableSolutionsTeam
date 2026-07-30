package com.example.elderlyhealth.data.model

import com.google.gson.annotations.SerializedName

data class LoginRequest(
    @SerializedName("username") val username: String,
    @SerializedName("password") val password: String,
    @SerializedName("login_type") val loginType: String = "password"
)

data class SmsLoginRequest(
    @SerializedName("phone") val phone: String,
    @SerializedName("sms_code") val smsCode: String
)

data class SendSmsRequest(
    @SerializedName("phone") val phone: String,
    @SerializedName("scene") val scene: String = "login"
)

data class RefreshTokenRequest(
    @SerializedName("refresh_token") val refreshToken: String
)

data class LoginResponse(
    @SerializedName("access_token") val accessToken: String = "",
    @SerializedName("refresh_token") val refreshToken: String = "",
    @SerializedName("expires_in") val expiresIn: Int = 7200,
    @SerializedName("token_type") val tokenType: String = "Bearer",
    @SerializedName("user") val user: UserInfo = UserInfo()
)

data class UserInfo(
    @SerializedName("user_id") val userId: String = "",
    @SerializedName("username") val username: String = "",
    @SerializedName("real_name") val realName: String = "",
    @SerializedName("role") val role: String = "",
    @SerializedName("avatar_url") val avatarUrl: String = "",
    @SerializedName("community_id") val communityId: String = ""
)

data class ChangePasswordRequest(
    @SerializedName("old_password") val oldPassword: String,
    @SerializedName("new_password") val newPassword: String
)
