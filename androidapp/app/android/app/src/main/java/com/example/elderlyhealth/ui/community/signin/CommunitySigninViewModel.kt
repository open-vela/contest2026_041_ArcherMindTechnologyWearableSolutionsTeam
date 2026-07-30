package com.example.elderlyhealth.ui.community.signin

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.model.*
import com.example.elderlyhealth.data.repository.SigninRepository
import com.example.elderlyhealth.util.TokenManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import javax.inject.Inject

data class CommunitySigninUiState(
    val overview: SigninOverviewResponse? = null,
    val isLoading: Boolean = true,
    val error: String? = null,
    val manualSigninLoading: Boolean = false,
    val manualSigninSuccess: Boolean = false
)

@HiltViewModel
class CommunitySigninViewModel @Inject constructor(
    private val signinRepository: SigninRepository,
    private val tokenManager: TokenManager
) : ViewModel() {
    private val _uiState = MutableStateFlow(CommunitySigninUiState())
    val uiState: StateFlow<CommunitySigninUiState> = _uiState.asStateFlow()

    init { load() }

    fun load(date: String? = null) {
        val d = date ?: LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"))
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            val communityId = tokenManager.getCommunityId() ?: ""
            signinRepository.getSigninOverview(communityId, d).fold(
                onSuccess = { overview -> _uiState.update { it.copy(overview = overview, isLoading = false) } },
                onFailure = { error -> _uiState.update { it.copy(error = error.message, isLoading = false) } }
            )
        }
    }

    fun manualSignin(elderlyId: String, notes: String = "") {
        viewModelScope.launch {
            _uiState.update { it.copy(manualSigninLoading = true) }
            val operatorName = tokenManager.userInfo.first().realName
            signinRepository.manualSignin(ManualSigninRequest(elderlyId, notes = notes, operator = operatorName)).fold(
                onSuccess = { _uiState.update { it.copy(manualSigninSuccess = true, manualSigninLoading = false) } },
                onFailure = { error -> _uiState.update { it.copy(error = error.message, manualSigninLoading = false) } }
            )
        }
    }
}
