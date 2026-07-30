package com.example.elderlyhealth.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class LoginUiState(
    val username: String = "",
    val password: String = "",
    val phone: String = "",
    val smsCode: String = "",
    val isSmsMode: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null,
    val loginSuccess: Boolean = false,
    val role: String = ""
)

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(LoginUiState())
    val uiState: StateFlow<LoginUiState> = _uiState.asStateFlow()

    fun updateUsername(value: String) { _uiState.update { it.copy(username = value) } }
    fun updatePassword(value: String) { _uiState.update { it.copy(password = value) } }
    fun updatePhone(value: String) { _uiState.update { it.copy(phone = value) } }
    fun updateSmsCode(value: String) { _uiState.update { it.copy(smsCode = value) } }
    fun toggleMode() { _uiState.update { it.copy(isSmsMode = !it.isSmsMode, error = null) } }

    fun login() {
        val state = _uiState.value
        if (state.isSmsMode) {
            if (state.phone.isBlank() || state.smsCode.isBlank()) {
                _uiState.update { it.copy(error = "请输入手机号和验证码") }
                return
            }
        } else {
            if (state.username.isBlank() || state.password.isBlank()) {
                _uiState.update { it.copy(error = "请输入账号和密码") }
                return
            }
        }

        val isSmsMode = state.isSmsMode
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = if (isSmsMode) {
                authRepository.smsLogin(state.phone, state.smsCode)
            } else {
                authRepository.login(state.username, state.password)
            }

            result.fold(
                onSuccess = { response ->
                    authRepository.saveSession(response)
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            loginSuccess = true,
                            role = response.user.role
                        )
                    }
                },
                onFailure = { e ->
                    _uiState.update {
                        it.copy(isLoading = false, error = e.message ?: "登录失败")
                    }
                }
            )
        }
    }

    fun sendSms() {
        val phone = _uiState.value.phone
        if (phone.length < 10 || phone.length > 15) {
            _uiState.update { it.copy(error = "请输入正确的手机号") }
            return
        }
        viewModelScope.launch {
            authRepository.sendSms(phone)
                .onFailure { _uiState.update { it.copy(error = "验证码发送失败") } }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun resetLoginSuccess() {
        _uiState.update { it.copy(loginSuccess = false) }
    }
}
