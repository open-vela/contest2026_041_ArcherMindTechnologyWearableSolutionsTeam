package com.example.elderlyhealth.ui.family.home

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.elderlyhealth.data.model.BindingInfo
import com.example.elderlyhealth.data.model.VitalSnapshot
import com.example.elderlyhealth.util.DateUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FamilyHomeScreen(
    onVitalClick: (String) -> Unit,
    onSigninClick: (String) -> Unit,
    onReportClick: (String) -> Unit,
    onBindClick: () -> Unit,
    onLogout: () -> Unit,
    viewModel: FamilyHomeViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showMenu by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("AI老年健康守护", fontWeight = FontWeight.Bold)
                        if (uiState.userName.isNotBlank()) {
                            Text(uiState.userName, style = MaterialTheme.typography.bodySmall)
                        }
                    }
                },
                actions = {
                    IconButton(onClick = onBindClick) {
                        Icon(Icons.Default.PersonAdd, contentDescription = "绑定老人")
                    }
                    Box {
                        IconButton(onClick = { showMenu = true }) {
                            Icon(Icons.Default.MoreVert, contentDescription = "更多")
                        }
                        DropdownMenu(expanded = showMenu, onDismissRequest = { showMenu = false }) {
                            DropdownMenuItem(
                                text = { Text("退出登录") },
                                onClick = {
                                    showMenu = false
                                    viewModel.logout()
                                    onLogout()
                                },
                                leadingIcon = { Icon(Icons.AutoMirrored.Filled.Logout, null) }
                            )
                        }
                    }
                }
            )
        }
    ) { padding ->
        if (uiState.isLoading) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else if (uiState.bindings.isEmpty()) {
            Column(
                modifier = Modifier.fillMaxSize().padding(padding).padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Icon(Icons.Default.FavoriteBorder, null, modifier = Modifier.size(80.dp), tint = MaterialTheme.colorScheme.primary)
                Spacer(modifier = Modifier.height(16.dp))
                Text("尚未绑定老人", style = MaterialTheme.typography.titleLarge)
                Spacer(modifier = Modifier.height(8.dp))
                Text("点击右上角 + 绑定您的家人", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(modifier = Modifier.height(24.dp))
                Button(onClick = onBindClick) { Text("绑定老人") }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(uiState.bindings) { binding ->
                    BindingCard(
                        binding = binding,
                        onVitalClick = { onVitalClick(binding.elderly.elderlyId) },
                        onAlarmClick = { onVitalClick(binding.elderly.elderlyId) },
                        onSigninClick = { onSigninClick(binding.elderly.elderlyId) },
                        onReportClick = { onReportClick(binding.elderly.elderlyId) }
                    )
                }
            }
        }
    }
}

@Composable
private fun BindingCard(
    binding: BindingInfo,
    onVitalClick: () -> Unit,
    onAlarmClick: () -> Unit,
    onSigninClick: () -> Unit,
    onReportClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable { onVitalClick() },
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Default.AccountCircle, null,
                    modifier = Modifier.size(48.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(binding.elderly.name, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                    Text(
                        "${binding.relation} · ${if (binding.isPrimary) "主要联系人" else "家庭成员"}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                // Online status
                Surface(
                    shape = MaterialTheme.shapes.small,
                    color = if (binding.deviceOnline) Color(0xFF4CAF50).copy(alpha = 0.1f) else Color.Gray.copy(alpha = 0.1f)
                ) {
                    Text(
                        if (binding.deviceOnline) "在线" else "离线",
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        color = if (binding.deviceOnline) Color(0xFF4CAF50) else Color.Gray,
                        style = MaterialTheme.typography.labelSmall
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Vital snapshot
            binding.latestVital?.let { vital ->
                VitalSnapshotRow(vital)
            }

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                ActionButton(
                    icon = Icons.AutoMirrored.Filled.Assignment,
                    label = "签到",
                    badge = if (binding.todaySignedIn) null else "!",
                    onClick = onSigninClick
                )
                ActionButton(
                    icon = Icons.Default.Warning,
                    label = "报警",
                    badge = if (binding.activeAlarms > 0) "${binding.activeAlarms}" else null,
                    onClick = onAlarmClick,
                    badgeColor = if (binding.activeAlarms > 0) Color.Red else null
                )
                ActionButton(
                    icon = Icons.Default.Description,
                    label = "周报",
                    onClick = onReportClick
                )
            }
        }
    }
}

@Composable
private fun VitalSnapshotRow(vital: VitalSnapshot) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        VitalItem("心率", "${vital.heartRate}", "bpm")
        VitalItem("血氧", "${vital.spo2}", "%")
        VitalItem("体温", "${vital.temperature}", "°C")
        VitalItem("步数", "${vital.steps ?: 0}", "")
    }
}

@Composable
private fun VitalItem(label: String, value: String, unit: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
        Text(unit, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ActionButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    badge: String? = null,
    badgeColor: Color? = null,
    onClick: () -> Unit
) {
    IconButton(onClick = onClick) {
        BadgedBox(badge = {
            if (badge != null) {
                Badge(containerColor = badgeColor ?: MaterialTheme.colorScheme.error) {
                    Text(badge, color = Color.White)
                }
            }
        }) {
            Icon(icon, label, tint = MaterialTheme.colorScheme.primary)
        }
    }
}
