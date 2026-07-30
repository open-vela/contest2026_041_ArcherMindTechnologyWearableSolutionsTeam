package com.example.elderlyhealth.di

import com.example.elderlyhealth.data.api.*
import com.example.elderlyhealth.data.repository.*
import com.example.elderlyhealth.util.TokenManager
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object RepositoryModule {

    @Provides
    @Singleton
    fun provideAuthRepository(
        authApi: AuthApi,
        tokenManager: TokenManager
    ): AuthRepository = AuthRepository(authApi, tokenManager)

    @Provides
    @Singleton
    fun provideElderlyRepository(
        elderlyApi: ElderlyApi
    ): ElderlyRepository = ElderlyRepository(elderlyApi)

    @Provides
    @Singleton
    fun provideVitalRepository(
        vitalApi: VitalApi
    ): VitalRepository = VitalRepository(vitalApi)

    @Provides
    @Singleton
    fun provideAlarmRepository(
        alarmApi: AlarmApi
    ): AlarmRepository = AlarmRepository(alarmApi)

    @Provides
    @Singleton
    fun provideSigninRepository(
        signinApi: SigninApi
    ): SigninRepository = SigninRepository(signinApi)

    @Provides
    @Singleton
    fun providePatrolRepository(
        patrolApi: PatrolApi
    ): PatrolRepository = PatrolRepository(patrolApi)

    @Provides
    @Singleton
    fun provideReportRepository(
        reportApi: ReportApi
    ): ReportRepository = ReportRepository(reportApi)

    @Provides
    @Singleton
    fun provideDashboardRepository(
        dashboardApi: DashboardApi
    ): DashboardRepository = DashboardRepository(dashboardApi)

    @Provides
    @Singleton
    fun provideDeviceRepository(
        deviceApi: DeviceApi
    ): DeviceRepository = DeviceRepository(deviceApi)
}
