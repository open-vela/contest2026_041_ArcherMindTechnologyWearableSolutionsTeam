package com.example.elderlyhealth.ui.community.alarm

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
fun CommunityAlarmDetailScreen(
    alarmId: String,
    onBack: () -> Unit,
    viewModel: CommunityAlarmDetailViewModel = hiltViewModel()
) {
    LaunchedEffect(alarmId) { viewModel.load(alarmId) }
    val uiState by viewModel.uiState.collectAsState()
    var showEscalateDialog by remember { mutableStateOf(false) }
    var showResolveDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("报警详情") },
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
            } ?: uiState.detail?.let { alarm ->
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding)
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp)
                ) {
                    // Header
                    val levelColor = when (alarm.alarm.alarmLevel) {
                        "P0" -> Color.Red  "P1" -> Color(0xFFFF9800)  else -> Color.Gray
                    }
                    Surface(shape = MaterialTheme.shapes.small, color = levelColor.copy(alpha = 0.15f)) {
                        Text(
                            "${alarm.alarm.alarmLevel} · ${alarm.alarm.alarmType}",
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                            color = levelColor, fontWeight = FontWeight.Bold
                        )
                    }

                    Spacer(modifier = Modifier.height(8.dp))
                    Text(alarm.alarm.title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Text(alarm.alarm.description, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(modifier = Modifier.height(12.dp))

                    // Elderly info
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text("老人信息", fontWeight = FontWeight.Bold)
                            Spacer(modifier = Modifier.height(4.dp))
                            Text("姓名: ${alarm.alarm.elderly.name} (${alarm.alarm.elderly.age}岁)")
                            Text("地址: ${alarm.alarm.elderly.address}")
                            alarm.alarm.elderly.emergencyContact?.let { ec ->
                                Text("紧急联系人: ${ec.name} ${ec.phone}")
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Location
                    alarm.alarm.locationJson?.let { loc ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("位置", fontWeight = FontWeight.Bold)
                                Text(loc, style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }

                    // Vital
                    alarm.alarm.vitalSnapshotJson?.let { vital ->
                        Spacer(modifier = Modifier.height(8.dp))
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("体征快照", fontWeight = FontWeight.Bold)
                                Text(vital, style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }

                    // Timeline
                    if (alarm.alarm.timeline.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(12.dp))
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("时间线", fontWeight = FontWeight.Bold)
                                alarm.alarm.timeline.forEach { tl ->
                                    Row(modifier = Modifier.padding(vertical = 2.dp)) {
                                        Text("● ${tl.action} - ${DateUtils.formatDateTime(tl.at)} (${tl.by})")
                                    }
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    // Action buttons
                    if (alarm.alarm.status != "RESOLVED" && alarm.alarm.status != "CONFIRMED") {
                        Text("社区操作:", fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.height(8.dp))

                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            OutlinedButton(
                                onClick = { showEscalateDialog = true },
                                modifier = Modifier.weight(1f),
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFFF9800))
                            ) { Icon(Icons.Default.ArrowUpward, null); Spacer(Modifier.width(4.dp)); Text("升级") }

                            Button(
                                onClick = { viewModel.emergencyCall(alarmId, "社区人员判断需要急救") },
                                modifier = Modifier.weight(1f),
                                colors = ButtonDefaults.buttonColors(containerColor = Color.Red)
                            ) { Icon(Icons.Default.LocalHospital, null); Spacer(Modifier.width(4.dp)); Text("120") }
                        }

                        Spacer(modifier = Modifier.height(8.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            OutlinedButton(
                                onClick = { viewModel.confirm(alarmId) },
                                modifier = Modifier.weight(1f),
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFF43A047))
                            ) { Icon(Icons.Default.CheckCircle, null); Spacer(Modifier.width(4.dp)); Text("确认") }

                            OutlinedButton(
                                onClick = { showResolveDialog = true },
                                modifier = Modifier.weight(1f)
                            ) { Icon(Icons.Default.Check, null); Spacer(Modifier.width(4.dp)); Text("关闭报警") }
                        }
                    }

                    uiState.actionSuccess?.let { msg ->
                        Spacer(modifier = Modifier.height(12.dp))
                        Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFE8F5E9))) {
                            Text("✓ $msg", modifier = Modifier.padding(16.dp), color = Color(0xFF43A047))
                        }
                    }
                }
            }
        }
    }

    if (showEscalateDialog) {
        AlertDialog(
            onDismissRequest = { showEscalateDialog = false },
            title = { Text("升级报警") },
            text = { Text("确认将此报警升级?") },
            confirmButton = {
                Button(onClick = { viewModel.escalate(alarmId); showEscalateDialog = false }) { Text("确认升级") }
            },
            dismissButton = { TextButton(onClick = { showEscalateDialog = false }) { Text("取消") } }
        )
    }

    if (showResolveDialog) {
        var notes by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { showResolveDialog = false },
            title = { Text("关闭报警") },
            text = {
                OutlinedTextField(value = notes, onValueChange = { notes = it }, label = { Text("备注") }, modifier = Modifier.fillMaxWidth())
            },
            confirmButton = { Button(onClick = { viewModel.resolve(alarmId, notes); showResolveDialog = false }) { Text("确认关闭") } },
            dismissButton = { TextButton(onClick = { showResolveDialog = false }) { Text("取消") } }
        )
    }
}
