package com.example.elderlyhealth.ui.community.elderly

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.model.*
import com.example.elderlyhealth.data.repository.ElderlyRepository
import com.example.elderlyhealth.util.TokenManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ElderlyListUiState(
    val elderlyList: List<ElderlyProfile> = emptyList(),
    val filteredList: List<ElderlyProfile> = emptyList(),
    val isLoading: Boolean = true,
    val error: String? = null,
    val keyword: String = ""
)

@HiltViewModel
class ElderlyListViewModel @Inject constructor(
    private val elderlyRepository: ElderlyRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(ElderlyListUiState())
    val uiState: StateFlow<ElderlyListUiState> = _uiState.asStateFlow()
    init { load() }

    fun load(keyword: String? = null) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            elderlyRepository.getElderlyList(keyword = keyword).fold(
                onSuccess = { data ->
                    _uiState.update { it.copy(elderlyList = data.list, filteredList = data.list, isLoading = false) }
                },
                onFailure = { e ->
                    _uiState.update { it.copy(error = e.message, isLoading = false) }
                }
            )
        }
    }

    fun updateKeyword(value: String) {
        _uiState.update {
            val kw = value.trim()
            it.copy(
                keyword = value,
                filteredList = if (kw.isEmpty()) it.elderlyList
                    else it.elderlyList.filter { p -> p.name.contains(kw, ignoreCase = true) }
            )
        }
    }
    fun search() { load(_uiState.value.keyword.ifBlank { null }) }
}

data class ElderlyFormUiState(
    val name: String = "",
    val phone: String = "",
    val gender: String = "female",
    val birthDate: String = "",
    val address: String = "",
    val emergencyName: String = "",
    val emergencyPhone: String = "",
    val emergencyRelation: String = "",
    val isSaving: Boolean = false,
    val error: String? = null,
    val saved: Boolean = false
)

@HiltViewModel
class ElderlyFormViewModel @Inject constructor(
    private val elderlyRepository: ElderlyRepository,
    private val tokenManager: TokenManager
) : ViewModel() {
    private val _uiState = MutableStateFlow(ElderlyFormUiState())
    val uiState: StateFlow<ElderlyFormUiState> = _uiState.asStateFlow()

    fun initForEdit(elderlyId: String) {
        viewModelScope.launch {
            elderlyRepository.getElderlyDetail(elderlyId).onSuccess { profile ->
                _uiState.update {
                    it.copy(
                        name = profile.name,
                        phone = profile.phone,
                        gender = profile.gender,
                        birthDate = profile.birthDate,
                        address = profile.address,
                        emergencyName = profile.emergencyContact?.name ?: "",
                        emergencyPhone = profile.emergencyContact?.phone ?: "",
                        emergencyRelation = profile.emergencyContact?.relation ?: ""
                    )
                }
            }
        }
    }

    fun updateName(v: String) { _uiState.update { it.copy(name = v) } }
    fun updatePhone(v: String) { _uiState.update { it.copy(phone = v) } }
    fun updateGender(v: String) { _uiState.update { it.copy(gender = v) } }
    fun updateBirthDate(v: String) { _uiState.update { it.copy(birthDate = v) } }
    fun updateAddress(v: String) { _uiState.update { it.copy(address = v) } }
    fun updateEmerName(v: String) { _uiState.update { it.copy(emergencyName = v) } }
    fun updateEmerPhone(v: String) { _uiState.update { it.copy(emergencyPhone = v) } }
    fun updateEmerRelation(v: String) { _uiState.update { it.copy(emergencyRelation = v) } }

    fun save(elderlyId: String?) {
        val s = _uiState.value
        if (elderlyId == null) {
            if (s.name.isBlank()) { _uiState.update { it.copy(error = "请输入姓名") }; return }
            if (s.phone.isBlank()) { _uiState.update { it.copy(error = "请输入手机号") }; return }
            if (s.birthDate.isBlank()) { _uiState.update { it.copy(error = "请输入出生日期") }; return }
        }
        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true, error = null) }

            if (elderlyId != null) {
                elderlyRepository.updateElderly(elderlyId, UpdateElderlyRequest(
                    address = s.address,
                    emergencyContact = EmergencyContact(s.emergencyName, s.emergencyPhone, s.emergencyRelation)
                )).fold(
                    onSuccess = { _uiState.update { it.copy(saved = true, isSaving = false) } },
                    onFailure = { error -> _uiState.update { it.copy(error = error.message, isSaving = false) } }
                )
            } else {
                val communityId = tokenManager.getCommunityId() ?: ""
                elderlyRepository.createElderly(CreateElderlyRequest(
                    name = s.name, phone = s.phone, gender = s.gender,
                    birthDate = s.birthDate, idCard = null,
                    address = s.address, latitude = 0.0, longitude = 0.0,
                    communityId = communityId,
                    emergencyContact = EmergencyContact(s.emergencyName, s.emergencyPhone, s.emergencyRelation),
                    medicalHistory = null, baseline = null
                )).fold(
                    onSuccess = { _uiState.update { it.copy(saved = true, isSaving = false) } },
                    onFailure = { error -> _uiState.update { it.copy(error = error.message, isSaving = false) } }
                )
            }
        }
    }
}
