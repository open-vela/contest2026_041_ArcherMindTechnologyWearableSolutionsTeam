package com.example.elderlyhealth.ui.community.trend

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.model.*
import com.example.elderlyhealth.data.repository.DashboardRepository
import com.example.elderlyhealth.util.TokenManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class TrendUiState(
    val deviceTrend: DeviceOnlineRateResponse? = null,
    val alarmTrend: AlarmTrendResponse? = null,
    val isLoading: Boolean = true,
    val error: String? = null,
    val selectedTrend: String = "device"
)

@HiltViewModel
class TrendViewModel @Inject constructor(
    private val dashboardRepository: DashboardRepository,
    private val tokenManager: TokenManager
) : ViewModel() {
    private val _uiState = MutableStateFlow(TrendUiState())
    val uiState: StateFlow<TrendUiState> = _uiState.asStateFlow()

    init { load() }

    fun selectTrend(t: String) { _uiState.update { it.copy(selectedTrend = t) } }

    fun load() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            val communityId = tokenManager.getCommunityId() ?: ""
            dashboardRepository.getDeviceTrend(communityId).fold(
                onSuccess = { trend -> _uiState.update { it.copy(deviceTrend = trend) } },
                onFailure = { e -> _uiState.update { it.copy(error = e.message) } }
            )
            dashboardRepository.getAlarmTrend(communityId).fold(
                onSuccess = { trend -> _uiState.update { it.copy(alarmTrend = trend) } },
                onFailure = { e -> _uiState.update { it.copy(error = e.message) } }
            )
            _uiState.update { it.copy(isLoading = false) }
        }
    }
}
