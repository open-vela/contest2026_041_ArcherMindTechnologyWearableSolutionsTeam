package com.example.elderlyhealth.util

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "auth_prefs")

data class UserInfo(
    val userId: String = "",
    val username: String = "",
    val realName: String = "",
    val role: String = "",
    val avatarUrl: String = "",
    val communityId: String = ""
)

@Singleton
class TokenManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private val ACCESS_TOKEN = stringPreferencesKey("access_token")
        private val REFRESH_TOKEN = stringPreferencesKey("refresh_token")
        private val USER_ID = stringPreferencesKey("user_id")
        private val USERNAME = stringPreferencesKey("username")
        private val REAL_NAME = stringPreferencesKey("real_name")
        private val ROLE = stringPreferencesKey("role")
        private val AVATAR_URL = stringPreferencesKey("avatar_url")
        private val COMMUNITY_ID = stringPreferencesKey("community_id")
    }

    val accessToken: Flow<String?> = context.dataStore.data.map { it[ACCESS_TOKEN] }
    val refreshToken: Flow<String?> = context.dataStore.data.map { it[REFRESH_TOKEN] }
    val communityId: Flow<String?> = context.dataStore.data.map { it[COMMUNITY_ID] }
    val userInfo: Flow<UserInfo> = context.dataStore.data.map { prefs ->
        UserInfo(
            userId = prefs[USER_ID] ?: "",
            username = prefs[USERNAME] ?: "",
            realName = prefs[REAL_NAME] ?: "",
            role = prefs[ROLE] ?: "",
            avatarUrl = prefs[AVATAR_URL] ?: "",
            communityId = prefs[COMMUNITY_ID] ?: ""
        )
    }

    suspend fun saveTokens(access: String, refresh: String) {
        context.dataStore.edit {
            it[ACCESS_TOKEN] = access
            it[REFRESH_TOKEN] = refresh
        }
    }

    suspend fun saveUserInfo(user: UserInfo) {
        context.dataStore.edit {
            it[USER_ID] = user.userId
            it[USERNAME] = user.username
            it[REAL_NAME] = user.realName
            it[ROLE] = user.role
            it[AVATAR_URL] = user.avatarUrl
            it[COMMUNITY_ID] = user.communityId
        }
    }

    suspend fun saveCommunityId(communityId: String) {
        context.dataStore.edit { it[COMMUNITY_ID] = communityId }
    }

    suspend fun getAccessTokenSync(): String? {
        return context.dataStore.data.first()[ACCESS_TOKEN]
    }

    suspend fun getCommunityId(): String? {
        return context.dataStore.data.first()[COMMUNITY_ID]
    }

    suspend fun clear() {
        context.dataStore.edit { it.clear() }
    }
}
