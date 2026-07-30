package com.example.elderlyhealth.ui.community.device

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.elderlyhealth.util.DateUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DeviceDetailScreen(
    deviceId: String,
    onBack: () -> Unit,
    onEdit: (String) -> Unit,
    viewModel: DeviceDetailViewModel = hiltViewModel()
) {
    LaunchedEffect(deviceId) { viewModel.load(deviceId) }
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("设备详情") },
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
            } ?: uiState.device?.let { d ->
                Column(
                    modifier = Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(16.dp)
                ) {
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Devices, null, modifier = Modifier.size(48.dp), tint = MaterialTheme.colorScheme.primary)
                                Spacer(Modifier.width(12.dp))
                                Column {
                                    Text(d.deviceSn, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                                    Surface(shape = MaterialTheme.shapes.small, color = if (d.status == "online") Color(0xFF4CAF50).copy(alpha = 0.1f) else Color.Gray.copy(alpha = 0.1f)) {
                                        Text(
                                            if (d.status == "online") "在线" else "离线",
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
                                            color = if (d.status == "online") Color(0xFF4CAF50) else Color.Gray
                                        )
                                    }
                                }
                            }
                            Spacer(Modifier.height(12.dp))
                            Row { Text("类型: ", fontWeight = FontWeight.Medium); Text(d.deviceType) }
                            Row { Text("SN: ", fontWeight = FontWeight.Medium); Text(d.deviceSn) }
                            Row { Text("固件版本: ", fontWeight = FontWeight.Medium); Text(d.firmwareVersion) }
                            Row { Text("电量: ", fontWeight = FontWeight.Medium); Text("${d.battery}%") }
                            Row { Text("信号强度: ", fontWeight = FontWeight.Medium); Text("${d.signalStrength}") }
                            Row { Text("最后在线: ", fontWeight = FontWeight.Medium); Text(DateUtils.formatDateTime(d.lastOnlineAt)) }
                        }
                    }

                    Spacer(Modifier.height(12.dp))

                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text("绑定信息", fontWeight = FontWeight.Bold)
                            Spacer(Modifier.height(4.dp))
                            if (d.elderlyName.isNotEmpty()) {
                                Text("绑定老人: ${d.elderlyName}")
                            } else {
                                Text("未绑定", color = Color.Gray)
                            }
                        }
                    }

                    Spacer(Modifier.height(24.dp))

                    Button(onClick = { onEdit(deviceId) }, modifier = Modifier.fillMaxWidth()) {
                        Icon(Icons.Default.Edit, null); Spacer(Modifier.width(4.dp)); Text("编辑设备")
                    }
                    Spacer(Modifier.height(8.dp))

                    if (d.elderlyName.isNotEmpty()) {
                        OutlinedButton(onClick = { viewModel.showUnbindDialog() }, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFFF9800))) {
                            Icon(Icons.Default.LinkOff, null); Spacer(Modifier.width(4.dp)); Text("解绑设备")
                        }
                        Spacer(Modifier.height(8.dp))
                    } else {
                        OutlinedButton(onClick = { viewModel.showBindDialog() }, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFF4CAF50))) {
                            Icon(Icons.Default.Link, null); Spacer(Modifier.width(4.dp)); Text("绑定老人")
                        }
                        Spacer(Modifier.height(8.dp))
                    }

                    OutlinedButton(
                        onClick = { viewModel.showDeleteDialog() },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.Red)
                    ) { Icon(Icons.Default.Delete, null); Spacer(Modifier.width(4.dp)); Text("删除设备") }

                    uiState.actionSuccess?.let { msg ->
                        Spacer(Modifier.height(12.dp))
                        Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFE8F5E9))) {
                            Text("✓ $msg", modifier = Modifier.padding(16.dp), color = Color(0xFF43A047))
                        }
                    }
                }
            }
        }
    }

    if (uiState.showUnbindDialog) {
        AlertDialog(
            onDismissRequest = { viewModel.hideUnbindDialog() },
            title = { Text("解绑设备") },
            text = { Text("确认将此设备与老人解绑?") },
            confirmButton = { Button(onClick = { viewModel.unbindDevice(deviceId) }) { Text("确认解绑") } },
            dismissButton = { TextButton(onClick = { viewModel.hideUnbindDialog() }) { Text("取消") } }
        )
    }

    if (uiState.showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { viewModel.hideDeleteDialog() },
            title = { Text("删除设备") },
            text = { Text("确认删除此设备?此操作不可恢复。") },
            confirmButton = { Button(onClick = { viewModel.deleteDevice(deviceId) }, colors = ButtonDefaults.buttonColors(containerColor = Color.Red)) { Text("删除") } },
            dismissButton = { TextButton(onClick = { viewModel.hideDeleteDialog() }) { Text("取消") } }
        )
    }

    if (uiState.showBindDialog) {
        AlertDialog(
            onDismissRequest = { viewModel.hideBindDialog() },
            title = { Text("绑定老人") },
            text = {
                OutlinedTextField(value = uiState.bindElderlyId, onValueChange = { viewModel.updateBindElderlyId(it) }, label = { Text("老人ID") }, modifier = Modifier.fillMaxWidth())
            },
            confirmButton = { Button(onClick = { viewModel.bindDevice(deviceId) }) { Text("确认绑定") } },
            dismissButton = { TextButton(onClick = { viewModel.hideBindDialog() }) { Text("取消") } }
        )
    }
}
