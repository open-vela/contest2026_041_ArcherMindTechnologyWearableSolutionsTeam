package com.example.elderlyhealth.ui.community.elderly

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.elderlyhealth.data.model.ElderlyProfile
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.elderlyhealth.data.repository.ElderlyRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ElderlyDetailUiState(
    val profile: ElderlyProfile? = null,
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class ElderlyDetailViewModel @Inject constructor(
    private val elderlyRepository: ElderlyRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(ElderlyDetailUiState())
    val uiState: StateFlow<ElderlyDetailUiState> = _uiState.asStateFlow()

    fun load(elderlyId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            elderlyRepository.getElderlyDetail(elderlyId).fold(
                onSuccess = { profile -> _uiState.update { it.copy(profile = profile, isLoading = false) } },
                onFailure = { error -> _uiState.update { it.copy(error = error.message, isLoading = false) } }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ElderlyDetailScreen(
    elderlyId: String,
    onBack: () -> Unit,
    onReportsClick: ((String) -> Unit)? = null,
    onSigninCalendarClick: ((String) -> Unit)? = null,
    viewModel: ElderlyDetailViewModel = hiltViewModel()
) {
    LaunchedEffect(elderlyId) { viewModel.load(elderlyId) }
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("老人详情") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回") } }
            )
        }
    ) { padding ->
        if (uiState.isLoading) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else {
            uiState.error?.let { error ->
                Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                    Text(error, color = MaterialTheme.colorScheme.error)
                }
            } ?: uiState.profile?.let { p ->
                Column(
                    modifier = Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(16.dp)
                ) {
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text(p.name, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                            Spacer(modifier = Modifier.height(4.dp))
                            Text("${p.age}岁 · ${if (p.gender == "male") "男" else "女"} · ${p.phone}")
                            Text("地址: ${p.address}")

                            p.community?.let { c ->
                                Spacer(modifier = Modifier.height(8.dp))
                                Text("所属社区: ${c.name}")
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    // Device info
                    p.device?.let { d ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("设备信息", fontWeight = FontWeight.Bold)
                                Text("SN: ${d.deviceSn}")
                                Text("电量: ${d.battery}% · 固件: ${d.firmwareVersion}")
                                Text("最后心跳: ${d.lastHeartbeatAt}")
                            }
                        }
                    }

                    // Emergency contact
                    p.emergencyContact?.let { ec ->
                        Spacer(modifier = Modifier.height(12.dp))
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("紧急联系人", fontWeight = FontWeight.Bold)
                                Text("${ec.name} (${ec.relation}) · ${ec.phone}")
                            }
                        }
                    }

                    // Medical history
                    p.medicalHistory?.let { mh ->
                        Spacer(modifier = Modifier.height(12.dp))
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("病史信息", fontWeight = FontWeight.Bold)
                                Text("高血压: ${if (mh.hypertension) "是" else "否"}")
                                Text("糖尿病: ${if (mh.diabetes) "是" else "否"}")
                                mh.heartDisease?.let { Text("心脏病: $it") }
                                if (!mh.allergies.isNullOrEmpty()) Text("过敏: ${mh.allergies.joinToString(", ")}")
                                if (!mh.medications.isNullOrEmpty()) {
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text("用药:")
                                    mh.medications.forEach { Text("  • ${it.name} ${it.dosage} ${it.frequency}") }
                                }
                            }
                        }
                    }

                    // Vital baseline
                    p.baseline?.let { b ->
                        Spacer(modifier = Modifier.height(12.dp))
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("体征基线", fontWeight = FontWeight.Bold)
                                Text("心率: ${b.heartRateMin} ~ ${b.heartRateMax} bpm")
                                Text("血氧: ≥ ${b.spo2Min}%")
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        onReportsClick?.let {
                            OutlinedButton(onClick = { it(elderlyId) }, modifier = Modifier.weight(1f)) {
                                Text("健康报告")
                            }
                        }
                        onSigninCalendarClick?.let {
                            OutlinedButton(onClick = { it(elderlyId) }, modifier = Modifier.weight(1f)) {
                                Text("签到日历")
                            }
                        }
                    }

                    // Bound family
                    if (!p.boundFamily.isNullOrEmpty()) {
                        Spacer(modifier = Modifier.height(12.dp))
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("绑定家属", fontWeight = FontWeight.Bold)
                                p.boundFamily.forEach { f ->
                                    Row(modifier = Modifier.padding(vertical = 2.dp)) {
                                        Text("${f.realName} (${f.relation}) ${if (f.isPrimary) "[主要]" else ""}")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
