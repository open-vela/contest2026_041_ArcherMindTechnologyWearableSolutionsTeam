package com.example.elderlyhealth.ui.family.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.model.BindingInfo
import com.example.elderlyhealth.data.repository.AuthRepository
import com.example.elderlyhealth.data.repository.ElderlyRepository
import com.example.elderlyhealth.util.TokenManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class FamilyHomeUiState(
    val bindings: List<BindingInfo> = emptyList(),
    val isLoading: Boolean = true,
    val error: String? = null,
    val userName: String = ""
)

@HiltViewModel
class FamilyHomeViewModel @Inject constructor(
    private val elderlyRepository: ElderlyRepository,
    private val tokenManager: TokenManager,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(FamilyHomeUiState())
    val uiState: StateFlow<FamilyHomeUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    fun loadData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            tokenManager.userInfo.first().let { user ->
                _uiState.update { it.copy(userName = user.realName) }
            }

            elderlyRepository.getMyBindings().fold(
                onSuccess = { bindings ->
                    _uiState.update { it.copy(bindings = bindings, isLoading = false) }
                },
                onFailure = { e ->
                    _uiState.update { it.copy(error = e.message, isLoading = false) }
                }
            )
        }
    }

    fun logout() {
        viewModelScope.launch {
            authRepository.logout()
            authRepository.clearSession()
        }
    }
}
