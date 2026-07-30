package com.example.elderlyhealth.ui.family.signin

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.model.SigninCalendarResponse
import com.example.elderlyhealth.data.model.TodaySigninStatus
import com.example.elderlyhealth.data.repository.SigninRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SigninCalendarUiState(
    val today: TodaySigninStatus? = null,
    val calendar: SigninCalendarResponse? = null,
    val currentMonth: String = "",
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class SigninCalendarViewModel @Inject constructor(
    private val signinRepository: SigninRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SigninCalendarUiState())
    val uiState: StateFlow<SigninCalendarUiState> = _uiState.asStateFlow()

    private var elderlyId: String = ""

    fun init(elderlyId: String) {
        this.elderlyId = elderlyId
        val now = java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM"))
        _uiState.update { it.copy(currentMonth = now) }
        loadData(now)
    }

    fun changeMonth(month: String) {
        _uiState.update { it.copy(currentMonth = month) }
        loadData(month)
    }

    private fun loadData(month: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            signinRepository.getTodaySignin(elderlyId).fold(
                onSuccess = { todayStatus -> _uiState.update { it.copy(today = todayStatus) } },
                onFailure = { }
            )
            signinRepository.getSigninCalendar(elderlyId, month).fold(
                onSuccess = { cal ->
                    _uiState.update { it.copy(calendar = cal, isLoading = false) }
                },
                onFailure = { e ->
                    _uiState.update { it.copy(error = e.message, isLoading = false) }
                }
            )
        }
    }
}
