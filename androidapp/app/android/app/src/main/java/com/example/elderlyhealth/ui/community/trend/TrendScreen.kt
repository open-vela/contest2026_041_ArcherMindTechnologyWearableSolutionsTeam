package com.example.elderlyhealth.ui.community.trend

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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TrendScreen(
    onBack: () -> Unit,
    viewModel: TrendViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("数据趋势") },
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
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(
                        selected = uiState.selectedTrend == "device",
                        onClick = { viewModel.selectTrend("device") },
                        label = { Text("设备在线率") }
                    )
                    FilterChip(
                        selected = uiState.selectedTrend == "alarm",
                        onClick = { viewModel.selectTrend("alarm") },
                        label = { Text("报警趋势") }
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                if (uiState.selectedTrend == "device") {
                    uiState.deviceTrend?.let { dt ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("设备在线率", fontWeight = FontWeight.Bold)
                                Spacer(modifier = Modifier.height(12.dp))

                                Text(
                                    text = "${"%.1f".format(dt.currentRate)}%",
                                    style = MaterialTheme.typography.displayMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = if (dt.currentRate >= 80) Color(0xFF2E7D32) else Color(0xFFC62828)
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text("在线 ${dt.onlineDevices} / 总计 ${dt.totalDevices} 台",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                } else {
                    uiState.alarmTrend?.let { at ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("报警趋势", fontWeight = FontWeight.Bold)
                                Spacer(modifier = Modifier.height(4.dp))
                                at.alarmTrendSummary.let { s ->
                                    Text("周期总数: ${s.periodTotal} · P0: ${s.p0Total} · P1: ${s.p1Total}")
                                }
                                Spacer(modifier = Modifier.height(8.dp))

                                at.dataPoints.forEach { dp ->
                                    Row(modifier = Modifier.padding(vertical = 2.dp)) {
                                        Text("${dp.date}: ", fontWeight = FontWeight.Medium, modifier = Modifier.width(80.dp))
                                        Text("P0:${dp.p0} P1:${dp.p1} P2:${dp.p2} P3:${dp.p3}")
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
