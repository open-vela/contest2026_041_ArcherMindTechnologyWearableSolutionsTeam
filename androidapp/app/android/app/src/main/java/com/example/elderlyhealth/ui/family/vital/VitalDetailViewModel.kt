package com.example.elderlyhealth.ui.family.vital

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.model.*
import com.example.elderlyhealth.data.repository.VitalRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class VitalDetailUiState(
    val realtime: RealtimeVital? = null,
    val overview: VitalOverviewResponse? = null,
    val heartRateHistory: VitalHistoryResponse? = null,
    val spo2History: VitalHistoryResponse? = null,
    val selectedMetric: String = "heart_rate",
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class VitalDetailViewModel @Inject constructor(
    private val vitalRepository: VitalRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(VitalDetailUiState())
    val uiState: StateFlow<VitalDetailUiState> = _uiState.asStateFlow()

    private var elderlyId: String = ""

    fun init(elderlyId: String) {
        this.elderlyId = elderlyId
        loadAll()
    }

    fun selectMetric(metric: String) {
        _uiState.update { it.copy(selectedMetric = metric) }
    }

    private fun loadAll() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val realtimeResult = vitalRepository.getRealtimeVital(elderlyId)
            val overviewResult = vitalRepository.getVitalOverview(elderlyId)
            val hrResult = vitalRepository.getVitalHistory(elderlyId, "heart_rate", "24h")
            val spo2Result = vitalRepository.getVitalHistory(elderlyId, "spo2", "24h")

            realtimeResult.fold(
                onSuccess = { realtime -> _uiState.update { it.copy(realtime = realtime) } },
                onFailure = { e -> _uiState.update { it.copy(error = e.message) } }
            )

            overviewResult.fold(
                onSuccess = { overview -> _uiState.update { it.copy(overview = overview) } },
                onFailure = { e -> _uiState.update { it.copy(error = e.message) } }
            )

            hrResult.fold(
                onSuccess = { history -> _uiState.update { it.copy(heartRateHistory = history) } },
                onFailure = { e -> _uiState.update { it.copy(error = e.message) } }
            )

            spo2Result.fold(
                onSuccess = { history -> _uiState.update { it.copy(spo2History = history) } },
                onFailure = { e -> _uiState.update { it.copy(error = e.message) } }
            )

            _uiState.update { it.copy(isLoading = false) }
        }
    }
}
