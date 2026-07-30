package com.example.elderlyhealth.ui.community.device

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Devices
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.elderlyhealth.data.model.DeviceModels
import com.example.elderlyhealth.util.DateUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DeviceListScreen(
    onBack: () -> Unit,
    onDeviceClick: (String) -> Unit = {},
    onAddClick: () -> Unit = {},
    viewModel: DeviceListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("设备管理") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回") } },
                actions = {
                    IconButton(onClick = onAddClick) { Icon(Icons.Filled.Add, "添加") }
                    TextButton(onClick = { viewModel.toggleFilter() }) {
                        Text(
                            when (uiState.filterOnline) {
                                null -> "全部"
                                true -> "在线"
                                false -> "离线"
                            }
                        )
                    }
                }
            )
        }
    ) { padding ->
        if (uiState.isLoading) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(uiState.devices) { device ->
                    DeviceCard(device, onClick = { onDeviceClick(device.id) })
                }
            }
        }
    }
}

@Composable
private fun DeviceCard(device: DeviceModels, onClick: () -> Unit = {}) {
    Card(modifier = Modifier.fillMaxWidth(), onClick = onClick) {
        Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Devices, null, modifier = Modifier.size(40.dp), tint = MaterialTheme.colorScheme.primary)
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(device.deviceSn, fontWeight = FontWeight.Bold)
                Text(device.deviceType, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(device.elderlyName.ifEmpty { "未绑定" }, style = MaterialTheme.typography.bodySmall)
            }
            Column(horizontalAlignment = Alignment.End) {
                Surface(
                    shape = MaterialTheme.shapes.small,
                    color = if (device.status == "online") Color(0xFF4CAF50).copy(alpha = 0.1f) else Color.Gray.copy(alpha = 0.1f)
                ) {
                    Text(
                        if (device.status == "online") "在线" else "离线",
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = if (device.status == "online") Color(0xFF4CAF50) else Color.Gray
                    )
                }
                Text("电量 ${device.battery}%", style = MaterialTheme.typography.labelSmall)
            }
        }
    }
}
