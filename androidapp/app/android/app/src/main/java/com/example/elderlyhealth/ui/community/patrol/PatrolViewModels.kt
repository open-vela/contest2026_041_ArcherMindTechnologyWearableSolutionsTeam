package com.example.elderlyhealth.ui.community.patrol

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.model.PatrolCheckItems
import com.example.elderlyhealth.data.model.PatrolRecordRequest
import com.example.elderlyhealth.data.model.PatrolTask
import com.example.elderlyhealth.data.repository.PatrolRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class PatrolListUiState(
    val tasks: List<PatrolTask> = emptyList(),
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class PatrolListViewModel @Inject constructor(
    private val patrolRepository: PatrolRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(PatrolListUiState())
    val uiState: StateFlow<PatrolListUiState> = _uiState.asStateFlow()

    init { load() }

    fun load() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            patrolRepository.getPatrolTasks().fold(
                onSuccess = { data -> _uiState.update { it.copy(tasks = data.list, isLoading = false) } },
                onFailure = { e -> _uiState.update { it.copy(error = e.message, isLoading = false) } }
            )
        }
    }

    fun assignTask(taskId: String, staffId: String) {
        viewModelScope.launch {
            patrolRepository.assignTask(taskId, staffId).onSuccess { load() }
        }
    }

}

data class PatrolRecordUiState(
    val elderlyStatus: String = "",
    val bloodPressure: String = "",
    val bloodSugar: String = "",
    val generalCondition: String = "良好",
    val mood: String = "正常",
    val remarks: String = "",
    val isSaving: Boolean = false,
    val error: String? = null,
    val saved: Boolean = false
)

@HiltViewModel
class PatrolRecordViewModel @Inject constructor(
    private val patrolRepository: PatrolRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(PatrolRecordUiState())
    val uiState: StateFlow<PatrolRecordUiState> = _uiState.asStateFlow()

    fun updateStatus(v: String) { _uiState.update { it.copy(elderlyStatus = v) } }
    fun updateBP(v: String) { _uiState.update { it.copy(bloodPressure = v) } }
    fun updateBS(v: String) { _uiState.update { it.copy(bloodSugar = v) } }
    fun updateCondition(v: String) { _uiState.update { it.copy(generalCondition = v) } }
    fun updateMood(v: String) { _uiState.update { it.copy(mood = v) } }
    fun updateRemarks(v: String) { _uiState.update { it.copy(remarks = v) } }

    fun submit(taskId: String, elderlyId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true) }
            val s = _uiState.value
            val checkItems = PatrolCheckItems(
                bloodPressure = s.bloodPressure.ifBlank { null },
                bloodSugar = s.bloodSugar.toDoubleOrNull(),
                generalCondition = s.generalCondition.ifBlank { null },
                mood = s.mood.ifBlank { null }
            )
            patrolRepository.submitRecord(
                taskId,
                PatrolRecordRequest(
                    elderlyId = elderlyId,
                    visitAt = java.time.Instant.now().toString(),
                    elderlyStatus = s.elderlyStatus,
                    checkItems = checkItems,
                    remarks = s.remarks
                )
            ).fold(
                onSuccess = { _uiState.update { it.copy(saved = true, isSaving = false) } },
                onFailure = { error -> _uiState.update { it.copy(error = error.message, isSaving = false) } }
            )
        }
    }
}
