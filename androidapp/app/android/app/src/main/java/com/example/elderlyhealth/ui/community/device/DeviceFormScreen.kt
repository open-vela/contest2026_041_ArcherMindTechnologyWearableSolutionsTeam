package com.example.elderlyhealth.ui.community.device

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DeviceFormScreen(
    deviceId: String?,
    onBack: () -> Unit,
    onSaved: () -> Unit,
    viewModel: DeviceFormViewModel = hiltViewModel()
) {
    LaunchedEffect(deviceId) { if (deviceId != null) viewModel.loadForEdit(deviceId) }
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(uiState.saved) { if (uiState.saved) onSaved() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (deviceId != null) "编辑设备" else "注册设备") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回") } }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier.fillMaxSize().padding(padding).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            OutlinedTextField(value = uiState.deviceSn, onValueChange = { viewModel.updateSn(it) }, label = { Text("设备SN") }, modifier = Modifier.fillMaxWidth())
            OutlinedTextField(value = uiState.deviceName, onValueChange = { viewModel.updateName(it) }, label = { Text("设备名称") }, modifier = Modifier.fillMaxWidth())
            OutlinedTextField(value = uiState.deviceType, onValueChange = { viewModel.updateType(it) }, label = { Text("设备类型") }, modifier = Modifier.fillMaxWidth())
            OutlinedTextField(value = uiState.elderlyId, onValueChange = { viewModel.updateElderlyId(it) }, label = { Text("绑定老人ID (可选)") }, modifier = Modifier.fillMaxWidth())

            uiState.error?.let { Text(it, color = MaterialTheme.colorScheme.error) }

            Spacer(Modifier.weight(1f))

            Button(
                onClick = { viewModel.save(deviceId) },
                modifier = Modifier.fillMaxWidth(),
                enabled = !uiState.isSaving
            ) {
                if (uiState.isSaving) CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                else Text(if (deviceId != null) "保存" else "注册")
            }
        }
    }
}
