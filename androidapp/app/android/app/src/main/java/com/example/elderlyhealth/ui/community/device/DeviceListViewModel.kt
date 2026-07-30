package com.example.elderlyhealth.ui.community.device

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.model.DeviceModels
import com.example.elderlyhealth.data.repository.DeviceRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DeviceListUiState(
    val allDevices: List<DeviceModels> = emptyList(),
    val isLoading: Boolean = true,
    val error: String? = null,
    val filterOnline: Boolean? = null
) {
    val devices: List<DeviceModels> get() = when (filterOnline) {
        true -> allDevices.filter { it.status == "online" }
        false -> allDevices.filter { it.status == "offline" }
        null -> allDevices
    }
}

@HiltViewModel
class DeviceListViewModel @Inject constructor(
    private val deviceRepository: DeviceRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(DeviceListUiState())
    val uiState: StateFlow<DeviceListUiState> = _uiState.asStateFlow()

    init { load() }

    fun load() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            deviceRepository.getDeviceList().fold(
                onSuccess = { data -> _uiState.update { it.copy(allDevices = data.list, isLoading = false) } },
                onFailure = { e -> _uiState.update { it.copy(error = e.message, isLoading = false) } }
            )
        }
    }

    fun toggleFilter() {
        _uiState.update {
            it.copy(filterOnline = when (it.filterOnline) { null -> true  true -> false  false -> null })
        }
    }
}
