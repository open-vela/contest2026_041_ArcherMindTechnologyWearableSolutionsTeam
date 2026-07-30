package com.example.elderlyhealth.ui.community.alarm

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.elderlyhealth.data.model.AlarmItem
import com.example.elderlyhealth.util.DateUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlarmBoardScreen(
    onAlarmClick: (String) -> Unit,
    onBack: () -> Unit,
    viewModel: AlarmBoardViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("报警看板") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回") } }
            )
        }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            // Summary bar
            uiState.summary?.let { s ->
                Card(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)) {
                    Row(
                        modifier = Modifier.padding(12.dp).fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        SummaryBadge("P0", "${s.p0Count}", Color.Red)
                        SummaryBadge("P1", "${s.p1Count}", Color(0xFFFF9800))
                        SummaryBadge("P2", "${s.p2Count}", Color(0xFF2196F3))
                        SummaryBadge("P3", "${s.p3Count}", Color.Gray)
                        SummaryBadge("未处理", "${s.unhandled}", MaterialTheme.colorScheme.error)
                    }
                }
            }

            // Filter chips
            Row(
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                listOf("P0", "P1", "P2", "P3").forEach { level ->
                    FilterChip(
                        selected = uiState.selectedLevels.contains(level),
                        onClick = { viewModel.toggleLevel(level) },
                        label = { Text(level) }
                    )
                }
            }

            if (uiState.isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(uiState.alarmList) { alarm ->
                        AlarmListCard(alarm, onClick = { onAlarmClick(alarm.alarmId) })
                    }
                    if (uiState.alarmList.isEmpty()) {
                        item {
                            Box(modifier = Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                                Text("暂无报警", color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SummaryBadge(label: String, count: String, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(count, fontWeight = FontWeight.Bold, color = color, style = MaterialTheme.typography.titleMedium)
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun AlarmListCard(alarm: AlarmItem, onClick: () -> Unit) {
    val levelColor = when (alarm.alarmLevel) {
        "P0" -> Color.Red  "P1" -> Color(0xFFFF9800)  "P2" -> Color(0xFF2196F3)  else -> Color.Gray
    }
    Card(modifier = Modifier.fillMaxWidth().clickable { onClick() }) {
        Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Warning, null, tint = levelColor, modifier = Modifier.size(32.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text("${alarm.elderly.name} - ${alarm.alarmTypeLabel}", fontWeight = FontWeight.Bold)
                Text(alarm.title, style = MaterialTheme.typography.bodySmall, maxLines = 1)
                Text(
                    "${DateUtils.formatDateTime(alarm.createdAt)} · ${alarm.statusLabel}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Surface(shape = MaterialTheme.shapes.small, color = levelColor.copy(alpha = 0.15f)) {
                Text(
                    alarm.alarmLevel,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                    color = levelColor,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}
