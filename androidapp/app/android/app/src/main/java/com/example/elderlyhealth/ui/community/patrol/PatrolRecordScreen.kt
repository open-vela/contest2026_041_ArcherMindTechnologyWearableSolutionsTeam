package com.example.elderlyhealth.ui.community.patrol

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PatrolRecordScreen(
    taskId: String,
    elderlyId: String,
    onBack: () -> Unit,
    onSubmitted: () -> Unit,
    viewModel: PatrolRecordViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    LaunchedEffect(uiState.saved) { if (uiState.saved) onSubmitted() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("提交巡访记录") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回") } }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier.fillMaxSize().padding(padding).padding(16.dp).verticalScroll(rememberScrollState())
        ) {
            OutlinedTextField(
                value = uiState.elderlyStatus,
                onValueChange = { viewModel.updateStatus(it) },
                label = { Text("老人状态描述") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 3
            )
            Spacer(modifier = Modifier.height(12.dp))

            OutlinedTextField(
                value = uiState.bloodPressure,
                onValueChange = { viewModel.updateBP(it) },
                label = { Text("血压 (如: 135/85)") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))

            OutlinedTextField(
                value = uiState.bloodSugar,
                onValueChange = { viewModel.updateBS(it) },
                label = { Text("血糖") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))

            Text("身体状况")
            Row {
                listOf("良好", "一般", "较差").forEach { c ->
                    FilterChip(
                        selected = uiState.generalCondition == c,
                        onClick = { viewModel.updateCondition(c) },
                        label = { Text(c) },
                        modifier = Modifier.padding(end = 8.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            Text("情绪状态")
            Row {
                listOf("正常", "低落", "焦虑", "愉悦").forEach { m ->
                    FilterChip(
                        selected = uiState.mood == m,
                        onClick = { viewModel.updateMood(m) },
                        label = { Text(m) },
                        modifier = Modifier.padding(end = 8.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))
            OutlinedTextField(
                value = uiState.remarks,
                onValueChange = { viewModel.updateRemarks(it) },
                label = { Text("备注") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2
            )

            uiState.error?.let {
                Spacer(modifier = Modifier.height(8.dp))
                Text(it, color = MaterialTheme.colorScheme.error)
            }

            Spacer(modifier = Modifier.height(24.dp))
            Button(
                onClick = { viewModel.submit(taskId, elderlyId) },
                enabled = !uiState.isSaving,
                modifier = Modifier.fillMaxWidth()
            ) {
                if (uiState.isSaving) CircularProgressIndicator(modifier = Modifier.size(24.dp))
                else Text("提交巡访记录")
            }
        }
    }
}
