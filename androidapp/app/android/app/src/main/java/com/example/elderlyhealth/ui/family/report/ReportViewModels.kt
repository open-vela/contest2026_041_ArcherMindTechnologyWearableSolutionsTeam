package com.example.elderlyhealth.ui.family.report

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.model.ReportDetail
import com.example.elderlyhealth.data.model.ReportItem
import com.example.elderlyhealth.data.repository.ReportRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ReportListUiState(
    val reports: List<ReportItem> = emptyList(),
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class ReportListViewModel @Inject constructor(
    private val reportRepository: ReportRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(ReportListUiState())
    val uiState: StateFlow<ReportListUiState> = _uiState.asStateFlow()

    fun load(elderlyId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            reportRepository.getReportList(elderlyId).fold(
                onSuccess = { data ->
                    _uiState.update { it.copy(reports = data.list, isLoading = false) }
                },
                onFailure = { e ->
                    _uiState.update { it.copy(error = e.message, isLoading = false) }
                }
            )
        }
    }
}

data class ReportDetailUiState(
    val detail: ReportDetail? = null,
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class ReportDetailViewModel @Inject constructor(
    private val reportRepository: ReportRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(ReportDetailUiState())
    val uiState: StateFlow<ReportDetailUiState> = _uiState.asStateFlow()

    fun load(reportId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            reportRepository.getReportDetail(reportId).fold(
                onSuccess = { detail ->
                    _uiState.update { it.copy(detail = detail, isLoading = false) }
                },
                onFailure = { e ->
                    _uiState.update { it.copy(error = e.message, isLoading = false) }
                }
            )
        }
    }
}
