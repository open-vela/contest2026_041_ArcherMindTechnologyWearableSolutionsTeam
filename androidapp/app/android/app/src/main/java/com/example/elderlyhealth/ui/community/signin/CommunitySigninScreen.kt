package com.example.elderlyhealth.ui.community.signin

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CommunitySigninScreen(
    onBack: () -> Unit,
    viewModel: CommunitySigninViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showManualDialog by remember { mutableStateOf(false) }
    var manualElderlyId by remember { mutableStateOf("") }
    var manualNotes by remember { mutableStateOf("") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("签到概览") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回") } }
            )
        }
    ) { padding ->
        if (uiState.isLoading) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else {
            Column(
                modifier = Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(16.dp)
            ) {
                uiState.overview?.let { ov ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("今日签到统计", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            Spacer(modifier = Modifier.height(12.dp))
                            Row(horizontalArrangement = Arrangement.SpaceEvenly, modifier = Modifier.fillMaxWidth()) {
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Text("${ov.signed}", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.headlineMedium, color = Color(0xFF43A047))
                                    Text("已签到", style = MaterialTheme.typography.bodySmall)
                                }
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Text("${ov.unsigned}", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.headlineMedium, color = Color(0xFFFF9800))
                                    Text("待签到", style = MaterialTheme.typography.bodySmall)
                                }
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Text("${ov.timeout}", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.headlineMedium, color = Color.Red)
                                    Text("超时", style = MaterialTheme.typography.bodySmall)
                                }
                            }
                            Spacer(modifier = Modifier.height(8.dp))
                            Text("总人数: ${ov.total} · 签到率: ${(ov.rate * 100).toInt()}%")
                            Spacer(modifier = Modifier.height(8.dp))
                            LinearProgressIndicator(
                                progress = { ov.rate.toFloat() },
                                modifier = Modifier.fillMaxWidth().height(10.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    Text("暂无未签到名单", style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
    }

    if (showManualDialog) {
        AlertDialog(
            onDismissRequest = { showManualDialog = false },
            title = { Text("社区代签") },
            text = {
                Column {
                    Text("确认代 ${manualElderlyId} 签到?")
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(value = manualNotes, onValueChange = { manualNotes = it }, label = { Text("备注") }, modifier = Modifier.fillMaxWidth())
                }
            },
            confirmButton = {
                Button(onClick = {
                    viewModel.manualSignin(manualElderlyId, manualNotes)
                    showManualDialog = false
                }) { Text("确认签到") }
            },
            dismissButton = { TextButton(onClick = { showManualDialog = false }) { Text("取消") } }
        )
    }
}
