package com.example.elderlyhealth.ui.community.dashboard

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.elderlyhealth.data.model.DashboardOverview


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    onAlarmBoardClick: () -> Unit,
    onElderlyClick: () -> Unit,
    onDeviceClick: () -> Unit,
    onSigninClick: () -> Unit,
    onPatrolClick: () -> Unit,
    onTrendClick: () -> Unit,
    onLogout: () -> Unit,
    viewModel: DashboardViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showMenu by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("社区看板", fontWeight = FontWeight.Bold) },
                actions = {
                    Box {
                        IconButton(onClick = { showMenu = true }) {
                            Icon(Icons.Default.MoreVert, "更多")
                        }
                        DropdownMenu(expanded = showMenu, onDismissRequest = { showMenu = false }) {
                            DropdownMenuItem(
                                text = { Text("退出登录") },
                                onClick = { showMenu = false; onLogout() },
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
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp)
            ) {
                uiState.overview?.let { ov ->
                    // Stats cards
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Spacer(modifier = Modifier.height(12.dp))
                            StatsRow(
                                "老人总数", "${ov.elderly.total}",
                                "在线率", "${(ov.devices.online * 100 / maxOf(ov.devices.total, 1)).toInt()}%"
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            StatsRow(
                                "今日签到", "${ov.signin.todaySigned} / ${ov.signin.todayTotal}",
                                "签到率", "${(ov.signin.todaySigned * 100 / maxOf(ov.signin.todayTotal, 1)).toInt()}%"
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Alarm summary card
                    Card(modifier = Modifier.fillMaxWidth().clickable { onAlarmBoardClick() }) {
                        Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Warning, null, tint = Color.Red, modifier = Modifier.size(32.dp))
                            Spacer(modifier = Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text("报警概览", fontWeight = FontWeight.Bold)
                                Text("P0: ${ov.alarms.p0}  P1: ${ov.alarms.p1}  未处理: ${(ov.alarms.p0 + ov.alarms.p1)}")
                            }
                            Icon(Icons.Default.ChevronRight, null)
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    // Patrol summary
                    Card(modifier = Modifier.fillMaxWidth().clickable { onPatrolClick() }) {
                        Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.AutoMirrored.Filled.Assignment, null, tint = MaterialTheme.colorScheme.secondary, modifier = Modifier.size(32.dp))
                            Spacer(modifier = Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text("巡访概览", fontWeight = FontWeight.Bold)
                                Text("待处理: ${ov.patrols.pending}")
                            }
                            Icon(Icons.Default.ChevronRight, null)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Navigation buttons
                Text("功能入口", fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(8.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    NavCard("报警看板", Icons.Default.Warning, Color.Red, onAlarmBoardClick, Modifier.weight(1f))
                    NavCard("老人档案", Icons.Default.People, MaterialTheme.colorScheme.primary, onElderlyClick, Modifier.weight(1f))
                }
                Spacer(modifier = Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    NavCard("设备管理", Icons.Default.Devices, Color(0xFFF57C00), onDeviceClick, Modifier.weight(1f))
                    NavCard("签到概览", Icons.Default.CalendarMonth, Color(0xFF43A047), onSigninClick, Modifier.weight(1f))
                }
                Spacer(modifier = Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    NavCard("巡访任务", Icons.AutoMirrored.Filled.Assignment, Color(0xFF7B1FA2), onPatrolClick, Modifier.weight(1f))
                    NavCard("数据趋势", Icons.AutoMirrored.Filled.TrendingUp, Color(0xFF1565C0), onTrendClick, Modifier.weight(1f))
                }


            }
        }
    }
}

@Composable
private fun StatsRow(l1: String, v1: String, l2: String, v2: String) {
    Row(horizontalArrangement = Arrangement.SpaceEvenly, modifier = Modifier.fillMaxWidth()) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(v1, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
            Text(l1, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(v2, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
            Text(l2, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun NavCard(
    label: String, icon: ImageVector, color: Color, onClick: () -> Unit, modifier: Modifier = Modifier
) {
    Card(
        onClick = onClick,
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = color.copy(alpha = 0.08f))
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(icon, null, tint = color, modifier = Modifier.size(36.dp))
            Spacer(modifier = Modifier.height(8.dp))
            Text(label, fontWeight = FontWeight.Medium, color = color)
        }
    }
}
