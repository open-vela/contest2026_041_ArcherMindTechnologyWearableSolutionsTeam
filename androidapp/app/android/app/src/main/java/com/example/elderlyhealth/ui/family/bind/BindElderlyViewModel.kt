package com.example.elderlyhealth.ui.family.bind

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.repository.ElderlyRepository
import com.example.elderlyhealth.data.model.BindElderlyRequest
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class BindUiState(
    val elderlyId: String = "",
    val relation: String = "son",
    val verifyCode: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
    val success: Boolean = false
)

@HiltViewModel
class BindElderlyViewModel @Inject constructor(
    private val elderlyRepository: ElderlyRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(BindUiState())
    val uiState: StateFlow<BindUiState> = _uiState.asStateFlow()

    fun updateElderlyId(value: String) { _uiState.update { it.copy(elderlyId = value) } }
    fun updateRelation(value: String) { _uiState.update { it.copy(relation = value) } }
    fun updateVerifyCode(value: String) { _uiState.update { it.copy(verifyCode = value) } }

    fun bind() {
        val s = _uiState.value
        if (s.elderlyId.isBlank() || s.verifyCode.isBlank()) {
            _uiState.update { it.copy(error = "请填写完整信息") }
            return
        }
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            elderlyRepository.bindElderly(
                BindElderlyRequest(s.elderlyId, s.relation, s.verifyCode)
            ).fold(
                onSuccess = { _uiState.update { it.copy(success = true, isLoading = false) } },
                onFailure = { e -> _uiState.update { it.copy(error = e.message, isLoading = false) } }
            )
        }
    }
}
