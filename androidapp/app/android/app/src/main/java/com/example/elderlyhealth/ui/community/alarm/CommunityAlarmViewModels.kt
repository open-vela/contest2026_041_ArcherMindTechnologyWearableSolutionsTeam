package com.example.elderlyhealth.ui.community.alarm

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.model.*
import com.example.elderlyhealth.data.repository.AlarmRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class AlarmBoardUiState(
    val alarmList: List<AlarmItem> = emptyList(),
    val summary: AlarmSummary? = null,
    val isLoading: Boolean = true,
    val error: String? = null,
    val selectedLevels: Set<String> = emptySet(),
    val selectedStatus: String? = null
)

@HiltViewModel
class AlarmBoardViewModel @Inject constructor(
    private val alarmRepository: AlarmRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AlarmBoardUiState())
    val uiState: StateFlow<AlarmBoardUiState> = _uiState.asStateFlow()

    init { load() }

    fun load() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            val level = _uiState.value.selectedLevels.joinToString(",")
            val status = _uiState.value.selectedStatus
            alarmRepository.getAlarmList(
                level = level.ifBlank { null },
                status = status
            ).fold(
                onSuccess = { resp ->
                    _uiState.update {
                        it.copy(alarmList = resp.list, summary = resp.summary, isLoading = false)
                    }
                },
                onFailure = { e ->
                    _uiState.update { it.copy(error = e.message, isLoading = false) }
                }
            )
        }
    }

    fun toggleLevel(level: String) {
        _uiState.update {
            val levels = it.selectedLevels.toMutableSet()
            if (levels.contains(level)) levels.remove(level) else levels.add(level)
            it.copy(selectedLevels = levels)
        }
        load()
    }

    fun setStatus(status: String?) {
        _uiState.update { it.copy(selectedStatus = status) }
        load()
    }
}

data class CommunityAlarmDetailUiState(
    val detail: AlarmDetail? = null,
    val isLoading: Boolean = true,
    val error: String? = null,
    val actionLoading: Boolean = false,
    val actionSuccess: String? = null
)

@HiltViewModel
class CommunityAlarmDetailViewModel @Inject constructor(
    private val alarmRepository: AlarmRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(CommunityAlarmDetailUiState())
    val uiState: StateFlow<CommunityAlarmDetailUiState> = _uiState.asStateFlow()

    fun load(alarmId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            alarmRepository.getAlarmDetail(alarmId).fold(
                onSuccess = { detail -> _uiState.update { it.copy(detail = detail, isLoading = false) } },
                onFailure = { error -> _uiState.update { it.copy(error = error.message, isLoading = false) } }
            )
        }
    }

    fun escalate(alarmId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(actionLoading = true) }
            alarmRepository.escalateAlarm(alarmId).fold(
                onSuccess = { _uiState.update { it.copy(actionLoading = false, actionSuccess = "已升级") } },
                onFailure = { error -> _uiState.update { it.copy(actionLoading = false, error = error.message) } }
            )
        }
    }

    fun emergencyCall(alarmId: String, notes: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(actionLoading = true) }
            alarmRepository.emergencyCall(alarmId, notes).fold(
                onSuccess = { _uiState.update { it.copy(actionLoading = false, actionSuccess = "已呼叫120") } },
                onFailure = { error -> _uiState.update { it.copy(actionLoading = false, error = error.message) } }
            )
        }
    }

    fun confirm(alarmId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(actionLoading = true) }
            alarmRepository.confirmAlarm(alarmId, "confirmed").fold(
                onSuccess = { _uiState.update { it.copy(actionLoading = false, actionSuccess = "已确认") } },
                onFailure = { error -> _uiState.update { it.copy(actionLoading = false, error = error.message) } }
            )
        }
    }

    fun resolve(alarmId: String, comment: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(actionLoading = true) }
            alarmRepository.resolveAlarm(alarmId, comment).fold(
                onSuccess = { _uiState.update { it.copy(actionLoading = false, actionSuccess = "已关闭") } },
                onFailure = { error -> _uiState.update { it.copy(actionLoading = false, error = error.message) } }
            )
        }
    }
}
