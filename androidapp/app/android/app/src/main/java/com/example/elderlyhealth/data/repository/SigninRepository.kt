package com.example.elderlyhealth.data.repository

import com.example.elderlyhealth.data.api.SigninApi
import com.example.elderlyhealth.data.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SigninRepository @Inject constructor(
    private val signinApi: SigninApi
) {
    suspend fun getTodaySignin(elderlyId: String): Result<TodaySigninStatus> = apiCall {
        signinApi.getTodaySignin(elderlyId)
    }

    suspend fun getSigninCalendar(elderlyId: String, month: String): Result<SigninCalendarResponse> = apiCall {
        signinApi.getSigninCalendar(elderlyId, month)
    }

    suspend fun getSigninOverview(communityId: String, date: String): Result<SigninOverviewResponse> = apiCall {
        signinApi.getSigninOverview(communityId, date)
    }

    suspend fun manualSignin(request: ManualSigninRequest): Result<Unit> = apiCall(allowNullData = true) {
        signinApi.manualSignin(request)
    }
}
