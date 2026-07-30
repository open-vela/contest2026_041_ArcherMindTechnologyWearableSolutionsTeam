package com.example.elderlyhealth.ui.family.vital

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
import com.example.elderlyhealth.ui.common.VitalMetricCard
import com.example.elderlyhealth.ui.common.LineChart
import com.example.elderlyhealth.util.DateUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VitalDetailScreen(
    elderlyId: String,
    onBack: () -> Unit,
    viewModel: VitalDetailViewModel = hiltViewModel()
) {
    LaunchedEffect(elderlyId) { viewModel.init(elderlyId) }
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("体征详情") },
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
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp)
            ) {
                // Current realtime vitals
                uiState.realtime?.let { vital ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text("当前体征", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                            Spacer(modifier = Modifier.height(12.dp))
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                                VitalMetricCard(label = "心率", value = "${vital.heartRate}", unit = "bpm", color = Color(0xFFE53935))
                                VitalMetricCard(label = "血氧", value = "${vital.spo2}", unit = "%", color = Color(0xFF43A047))
                                VitalMetricCard(label = "体温", value = "${vital.temperature}", unit = "°C", color = Color(0xFF1565C0))
                                VitalMetricCard(label = "步数", value = "${vital.steps}", unit = "", color = Color(0xFFF57C00))
                            }
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                "更新于: ${DateUtils.formatDateTime(vital.updatedAt)} · ${vital.postureLabel}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Metric filter chips
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(
                        selected = uiState.selectedMetric == "heart_rate",
                        onClick = { viewModel.selectMetric("heart_rate") },
                        label = { Text("心率") }
                    )
                    FilterChip(
                        selected = uiState.selectedMetric == "spo2",
                        onClick = { viewModel.selectMetric("spo2") },
                        label = { Text("血氧") }
                    )
                    FilterChip(
                        selected = uiState.selectedMetric == "temperature",
                        onClick = { viewModel.selectMetric("temperature") },
                        label = { Text("体温") }
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Chart
                val history = when (uiState.selectedMetric) {
                    "heart_rate" -> uiState.heartRateHistory
                    "spo2" -> uiState.spo2History
                    else -> null
                }

                history?.let { h ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text(
                                "24小时趋势 - ${h.metric} (${h.unit})",
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(8.dp))

                            h.summary?.let { s ->
                                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                                    Text("平均: ${s.avg}", style = MaterialTheme.typography.bodySmall)
                                    Text("最高: ${s.max}", style = MaterialTheme.typography.bodySmall, color = Color.Red)
                                    Text("最低: ${s.min}", style = MaterialTheme.typography.bodySmall, color = Color(0xFF1565C0))
                                }
                            }

                            Spacer(modifier = Modifier.height(12.dp))

                            if (h.dataPoints.isNotEmpty()) {
                                LineChart(
                                    dataPoints = h.dataPoints,
                                    modifier = Modifier.fillMaxWidth().height(200.dp),
                                    baselineMin = h.baseline?.heartRateMin?.toDouble(),
                                    baselineMax = h.baseline?.heartRateMax?.toDouble()
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Overview metrics
                uiState.overview?.let { overview ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text("24小时概览", fontWeight = FontWeight.Bold)
                            Spacer(modifier = Modifier.height(12.dp))

                            MetricRow("心率", "${overview.heartRate.avg.toInt()}", "${overview.heartRate.current.toInt()}", overview.heartRate.trend)
                            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
                            MetricRow("血氧", "${overview.spo2.avg.toInt()}", "${overview.spo2.current.toInt()}", overview.spo2.trend)
                            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
                            MetricRow("体温", "${overview.temperature.avg}", "${overview.temperature.current}", overview.temperature.trend)
                            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
                            MetricRow("步数", "今日: ${overview.steps.totalToday}", "近7日均: ${overview.steps.avgDaily7d}", overview.steps.trend)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(80.dp))
            }
        }
    }
}

@Composable
private fun MetricRow(label: String, avg: String, current: String, trend: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, modifier = Modifier.width(48.dp))
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(avg, fontWeight = FontWeight.Bold)
            Text("均值", style = MaterialTheme.typography.labelSmall)
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(current, fontWeight = FontWeight.Bold)
            Text("当前", style = MaterialTheme.typography.labelSmall)
        }
        val trendColor = when (trend) {
            "stable" -> Color(0xFF43A047)
            "declining" -> Color(0xFFE53935)
            else -> Color(0xFFF57C00)
        }
        Surface(shape = MaterialTheme.shapes.small, color = trendColor.copy(alpha = 0.1f)) {
            Text(
                when (trend) { "stable" -> "稳定"  "declining" -> "下降"  else -> "上升" },
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
                color = trendColor,
                style = MaterialTheme.typography.labelSmall
            )
        }
    }
}
