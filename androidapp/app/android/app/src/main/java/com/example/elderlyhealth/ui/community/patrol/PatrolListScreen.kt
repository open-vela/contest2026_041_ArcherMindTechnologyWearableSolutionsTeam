package com.example.elderlyhealth.ui.community.patrol

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Assignment
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.elderlyhealth.data.model.PatrolTask
import com.example.elderlyhealth.util.DateUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PatrolListScreen(
    onRecordSubmit: (String, String) -> Unit,
    onBack: () -> Unit,
    onRecordsClick: () -> Unit = {},
    viewModel: PatrolListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("巡访任务") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回") } },
                actions = { TextButton(onClick = onRecordsClick) { Text("历史记录") } }
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
                items(uiState.tasks) { task ->
                    PatrolTaskCard(task, onRecord = { onRecordSubmit(task.id, task.elderlyId) })
                }
                if (uiState.tasks.isEmpty()) {
                    item {
                        Box(modifier = Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                            Text("暂无巡访任务", color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PatrolTaskCard(task: PatrolTask, onRecord: () -> Unit) {
    val priorityColor = when (task.priority) {
        "P0" -> Color.Red  "P1" -> Color(0xFFFF9800)  else -> Color.Gray
    }
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.AutoMirrored.Filled.Assignment, null, modifier = Modifier.size(32.dp), tint = priorityColor)
                Spacer(modifier = Modifier.width(8.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text("${task.taskType} - ${task.elderlyName}", fontWeight = FontWeight.Bold)
                    Text(task.description, style = MaterialTheme.typography.bodySmall)
                }
                Surface(shape = MaterialTheme.shapes.small, color = priorityColor.copy(alpha = 0.15f)) {
                    Text(task.priority, modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp), color = priorityColor, fontWeight = FontWeight.Bold)
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text("截止: ${DateUtils.formatDateTime(task.scheduledDate)} · 状态: ${task.status}", style = MaterialTheme.typography.bodySmall)

            if (task.status == "IN_PROGRESS") {
                Spacer(modifier = Modifier.height(8.dp))
                Button(onClick = onRecord, modifier = Modifier.fillMaxWidth()) { Text("提交巡访记录") }
            }
        }
    }
}
