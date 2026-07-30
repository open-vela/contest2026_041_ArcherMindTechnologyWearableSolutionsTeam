package com.example.elderlyhealth.ui.family.alarm

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.model.AlarmDetail
import com.example.elderlyhealth.data.repository.AlarmRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class FamilyAlarmUiState(
    val alarmDetail: AlarmDetail? = null,
    val isLoading: Boolean = true,
    val error: String? = null,
    val confirmResult: String? = null,
    val confirmLoading: Boolean = false,
    val confirmed: Boolean = false
)

@HiltViewModel
class FamilyAlarmViewModel @Inject constructor(
    private val alarmRepository: AlarmRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(FamilyAlarmUiState())
    val uiState: StateFlow<FamilyAlarmUiState> = _uiState.asStateFlow()

    fun loadAlarm(alarmId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            alarmRepository.getAlarmDetail(alarmId).fold(
                onSuccess = { detail ->
                    _uiState.update { it.copy(alarmDetail = detail, isLoading = false) }
                },
                onFailure = { e ->
                    _uiState.update { it.copy(error = e.message, isLoading = false) }
                }
            )
        }
    }

    fun confirmAlarm(alarmId: String, result: String, note: String = "") {
        viewModelScope.launch {
            _uiState.update { it.copy(confirmLoading = true) }
            alarmRepository.confirmAlarm(alarmId, result, note).fold(
                onSuccess = {
                    _uiState.update { it.copy(confirmed = true, confirmLoading = false) }
                },
                onFailure = { e ->
                    _uiState.update { it.copy(error = e.message, confirmLoading = false) }
                }
            )
        }
    }
}
