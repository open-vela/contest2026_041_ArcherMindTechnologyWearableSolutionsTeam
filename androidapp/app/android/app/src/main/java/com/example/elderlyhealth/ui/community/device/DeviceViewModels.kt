package com.example.elderlyhealth.ui.community.device

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.model.DeviceModels
import com.example.elderlyhealth.data.model.DeviceRegisterRequest
import com.example.elderlyhealth.data.repository.DeviceRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DeviceDetailUiState(
    val device: DeviceModels? = null,
    val isLoading: Boolean = true,
    val error: String? = null,
    val actionLoading: Boolean = false,
    val actionSuccess: String? = null,
    val showUnbindDialog: Boolean = false,
    val showDeleteDialog: Boolean = false,
    val showBindDialog: Boolean = false,
    val bindElderlyId: String = ""
)

@HiltViewModel
class DeviceDetailViewModel @Inject constructor(
    private val deviceRepository: DeviceRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(DeviceDetailUiState())
    val uiState: StateFlow<DeviceDetailUiState> = _uiState.asStateFlow()

    fun load(deviceId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            deviceRepository.getDeviceDetail(deviceId).fold(
                onSuccess = { d -> _uiState.update { it.copy(device = d, isLoading = false) } },
                onFailure = { e -> _uiState.update { it.copy(error = e.message, isLoading = false) } }
            )
        }
    }

    fun showUnbindDialog() { _uiState.update { it.copy(showUnbindDialog = true) } }
    fun hideUnbindDialog() { _uiState.update { it.copy(showUnbindDialog = false) } }
    fun unbindDevice(deviceId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(actionLoading = true, showUnbindDialog = false) }
            deviceRepository.unbindDevice(deviceId).fold(
                onSuccess = {
                    _uiState.update { it.copy(actionLoading = false, actionSuccess = "已解绑") }
                    load(deviceId)
                },
                onFailure = { e -> _uiState.update { it.copy(actionLoading = false, error = e.message) } }
            )
        }
    }

    fun showDeleteDialog() { _uiState.update { it.copy(showDeleteDialog = true) } }
    fun hideDeleteDialog() { _uiState.update { it.copy(showDeleteDialog = false) } }
    fun deleteDevice(deviceId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(actionLoading = true, showDeleteDialog = false) }
            deviceRepository.deleteDevice(deviceId).fold(
                onSuccess = { _uiState.update { it.copy(actionLoading = false, actionSuccess = "已删除") } },
                onFailure = { e -> _uiState.update { it.copy(actionLoading = false, error = e.message) } }
            )
        }
    }

    fun showBindDialog() { _uiState.update { it.copy(showBindDialog = true) } }
    fun hideBindDialog() { _uiState.update { it.copy(showBindDialog = false) } }
    fun updateBindElderlyId(v: String) { _uiState.update { it.copy(bindElderlyId = v) } }
    fun bindDevice(deviceId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(actionLoading = true, showBindDialog = false) }
            deviceRepository.bindDevice(deviceId, _uiState.value.bindElderlyId).fold(
                onSuccess = {
                    _uiState.update { it.copy(actionLoading = false, actionSuccess = "已绑定", bindElderlyId = "") }
                    load(deviceId)
                },
                onFailure = { e -> _uiState.update { it.copy(actionLoading = false, error = e.message) } }
            )
        }
    }
}

data class DeviceFormUiState(
    val deviceSn: String = "",
    val deviceName: String = "",
    val deviceType: String = "",
    val elderlyId: String = "",
    val isSaving: Boolean = false,
    val error: String? = null,
    val saved: Boolean = false
)

@HiltViewModel
class DeviceFormViewModel @Inject constructor(
    private val deviceRepository: DeviceRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(DeviceFormUiState())
    val uiState: StateFlow<DeviceFormUiState> = _uiState.asStateFlow()

    fun loadForEdit(deviceId: String) {
        viewModelScope.launch {
            deviceRepository.getDeviceDetail(deviceId).onSuccess { d ->
                _uiState.update { it.copy(deviceSn = d.deviceSn, deviceName = d.deviceType, deviceType = d.deviceType) }
            }
        }
    }

    fun updateSn(v: String) { _uiState.update { it.copy(deviceSn = v) } }
    fun updateName(v: String) { _uiState.update { it.copy(deviceName = v) } }
    fun updateType(v: String) { _uiState.update { it.copy(deviceType = v) } }
    fun updateElderlyId(v: String) { _uiState.update { it.copy(elderlyId = v) } }

    fun save(deviceId: String?) {
        val s = _uiState.value
        if (s.deviceSn.isBlank()) { _uiState.update { it.copy(error = "请输入设备SN") }; return }
        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true, error = null) }
            val req = DeviceRegisterRequest(s.deviceSn, s.deviceName, s.deviceType, s.elderlyId.ifBlank { null })
            val result = if (deviceId != null) deviceRepository.updateDevice(deviceId, req)
            else deviceRepository.registerDevice(req)
            result.fold(
                onSuccess = { _uiState.update { it.copy(saved = true, isSaving = false) } },
                onFailure = { e -> _uiState.update { it.copy(error = e.message, isSaving = false) } }
            )
        }
    }
}
