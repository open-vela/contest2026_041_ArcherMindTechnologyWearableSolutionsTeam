package com.example.elderlyhealth.ui.family.alarm

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
import com.example.elderlyhealth.util.DateUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FamilyAlarmScreen(
    alarmId: String,
    onBack: () -> Unit,
    viewModel: FamilyAlarmViewModel = hiltViewModel()
) {
    LaunchedEffect(alarmId) { viewModel.loadAlarm(alarmId) }
    val uiState by viewModel.uiState.collectAsState()
    var showSafeDialog by remember { mutableStateOf(false) }
    var showHelpDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("报警详情") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回")
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
            uiState.error?.let { error ->
                Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                    Text(error, color = MaterialTheme.colorScheme.error)
                }
            } ?: uiState.alarmDetail?.let { alarm ->
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding)
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp)
                ) {
                    // Level badge
                    val detail = alarm.alarm
                    val levelColor = when (detail.alarmLevel) {
                        "P0" -> Color.Red  "P1" -> Color(0xFFFF9800)  "P2" -> Color(0xFF2196F3)  else -> Color.Gray
                    }
                    Surface(shape = MaterialTheme.shapes.small, color = levelColor.copy(alpha = 0.15f)) {
                        Text(
                            "${detail.alarmLevel} · ${detail.alarmType}",
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                            color = levelColor,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    Spacer(modifier = Modifier.height(12.dp))
                    Text(detail.title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(detail.description, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(modifier = Modifier.height(16.dp))

                    // Vital snapshot
                    detail.vitalSnapshotJson?.let { vitalStr ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("体征快照", fontWeight = FontWeight.Bold)
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(vitalStr, style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    // Time & status
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            InfoRow("报警时间", DateUtils.formatDateTime(detail.createdAt))
                            InfoRow("状态", detail.status)
                            detail.locationJson?.let { loc ->
                                InfoRow("位置", loc)
                            }
                        }
                    }

                    // Timeline
                    if (detail.timeline.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(16.dp))
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("处理时间线", fontWeight = FontWeight.Bold)
                                Spacer(modifier = Modifier.height(8.dp))
                                detail.timeline.forEach { tl: com.example.elderlyhealth.data.model.AlarmTimeline ->
                                    Row(modifier = Modifier.padding(vertical = 4.dp)) {
                                        Text("● ", color = MaterialTheme.colorScheme.primary)
                                        Column {
                                            Text("${tl.action} - ${tl.by}")
                                            Text(DateUtils.formatDateTime(tl.at), style = MaterialTheme.typography.bodySmall)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    // Confirm actions
                    if (!uiState.confirmed && detail.status != "RESOLVED") {
                        Text("请确认老人的状态:", fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Button(
                                onClick = { showSafeDialog = true },
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF43A047)),
                                modifier = Modifier.weight(1f)
                            ) { Text("一切正常") }
                            OutlinedButton(
                                onClick = { showHelpDialog = true },
                                modifier = Modifier.weight(1f)
                            ) { Text("需要帮助") }
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        OutlinedButton(
                            onClick = { viewModel.confirmAlarm(alarmId, "CANNOT_CONTACT") },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.Red)
                        ) { Text("无法联系上老人") }
                    }

                    if (uiState.confirmed) {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFFE8F5E9))
                        ) {
                            Text(
                                "✓ 已确认",
                                modifier = Modifier.padding(16.dp),
                                color = Color(0xFF43A047),
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
        }
    }

    if (showSafeDialog) {
        AlertDialog(
            onDismissRequest = { showSafeDialog = false },
            title = { Text("确认") },
            text = { Text("确认老人一切正常？") },
            confirmButton = {
                Button(onClick = { viewModel.confirmAlarm(alarmId, "SAFE"); showSafeDialog = false }) {
                    Text("确认")
                }
            },
            dismissButton = { TextButton(onClick = { showSafeDialog = false }) { Text("取消") } }
        )
    }

    if (showHelpDialog) {
        AlertDialog(
            onDismissRequest = { showHelpDialog = false },
            title = { Text("确认") },
            text = { Text("标记为需要帮助？") },
            confirmButton = {
                Button(onClick = { viewModel.confirmAlarm(alarmId, "NEED_HELP"); showHelpDialog = false }) {
                    Text("确认")
                }
            },
            dismissButton = { TextButton(onClick = { showHelpDialog = false }) { Text("取消") } }
        )
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(modifier = Modifier.padding(vertical = 4.dp)) {
        Text("$label: ", fontWeight = FontWeight.Medium, modifier = Modifier.width(72.dp))
        Text(value, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
