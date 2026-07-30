package com.example.elderlyhealth.ui.community.elderly

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ElderlyFormScreen(
    elderlyId: String?,
    onBack: () -> Unit,
    onSaved: () -> Unit,
    viewModel: ElderlyFormViewModel = hiltViewModel()
) {
    LaunchedEffect(elderlyId) { if (elderlyId != null) viewModel.initForEdit(elderlyId) }
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(uiState.saved) { if (uiState.saved) onSaved() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (elderlyId != null) "编辑老人档案" else "新建老人档案") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "返回") } }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier.fillMaxSize().padding(padding).padding(16.dp).verticalScroll(rememberScrollState())
        ) {
            OutlinedTextField(value = uiState.name, onValueChange = { viewModel.updateName(it) }, label = { Text("姓名") }, singleLine = true, modifier = Modifier.fillMaxWidth())
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(value = uiState.phone, onValueChange = { viewModel.updatePhone(it) }, label = { Text("手机号") }, singleLine = true, modifier = Modifier.fillMaxWidth())
            Spacer(modifier = Modifier.height(8.dp))

            Text("性别")
            Row {
                listOf("male" to "男", "female" to "女").forEach { (v, l) ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        RadioButton(selected = uiState.gender == v, onClick = { viewModel.updateGender(v) })
                        Text(l)
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(value = uiState.birthDate, onValueChange = { viewModel.updateBirthDate(it) }, label = { Text("出生日期 (yyyy-MM-dd)") }, singleLine = true, modifier = Modifier.fillMaxWidth())
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(value = uiState.address, onValueChange = { viewModel.updateAddress(it) }, label = { Text("地址") }, modifier = Modifier.fillMaxWidth())

            Spacer(modifier = Modifier.height(16.dp))
            Text("紧急联系人", style = MaterialTheme.typography.titleSmall)
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(value = uiState.emergencyName, onValueChange = { viewModel.updateEmerName(it) }, label = { Text("联系人姓名") }, singleLine = true, modifier = Modifier.fillMaxWidth())
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(value = uiState.emergencyPhone, onValueChange = { viewModel.updateEmerPhone(it) }, label = { Text("联系人电话") }, singleLine = true, modifier = Modifier.fillMaxWidth())
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(value = uiState.emergencyRelation, onValueChange = { viewModel.updateEmerRelation(it) }, label = { Text("关系(如:儿子/女儿)") }, singleLine = true, modifier = Modifier.fillMaxWidth())

            uiState.error?.let { e ->
                Spacer(modifier = Modifier.height(8.dp))
                Text(e, color = MaterialTheme.colorScheme.error)
            }

            Spacer(modifier = Modifier.height(24.dp))
            Button(
                onClick = { viewModel.save(elderlyId) },
                enabled = !uiState.isSaving,
                modifier = Modifier.fillMaxWidth()
            ) {
                if (uiState.isSaving) CircularProgressIndicator(modifier = Modifier.size(24.dp))
                else Text("保存")
            }
        }
    }
}
