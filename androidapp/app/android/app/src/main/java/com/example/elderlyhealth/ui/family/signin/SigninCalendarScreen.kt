package com.example.elderlyhealth.ui.family.signin

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.elderlyhealth.data.model.CalendarDay
import com.example.elderlyhealth.util.DateUtils
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SigninCalendarScreen(
    elderlyId: String,
    onBack: () -> Unit,
    viewModel: SigninCalendarViewModel = hiltViewModel()
) {
    LaunchedEffect(elderlyId) { viewModel.init(elderlyId) }
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("签到日历") },
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
                // Today status
                uiState.today?.let { today ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = if (today.status == "SIGNED") Color(0xFFE8F5E9) else Color(0xFFFFF3E0)
                        )
                    ) {
                        Column(modifier = Modifier.padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                if (today.status == "SIGNED") "✅ 今日已签到" else "⏳ 今日待签到",
                                fontWeight = FontWeight.Bold
                            )
                            today.signedAt?.let {
                                Text("签到时间: ${DateUtils.formatTime(it)}")
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Calendar controls
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = {
                        val prev = prevMonth(uiState.currentMonth)
                        viewModel.changeMonth(prev)
                    }) {
                        Icon(Icons.Default.ChevronLeft, "上一月")
                    }
                    Text(
                        uiState.currentMonth,
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.titleLarge
                    )
                    IconButton(onClick = {
                        val next = nextMonth(uiState.currentMonth)
                        viewModel.changeMonth(next)
                    }) {
                        Icon(Icons.Default.ChevronRight, "下一月")
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Calendar grid
                val days = uiState.calendar?.days ?: emptyList()
                val weekDays = listOf("日", "一", "二", "三", "四", "五", "六")

                // Week header
                Row(modifier = Modifier.fillMaxWidth()) {
                    weekDays.forEach { day ->
                        Text(
                            day,
                            modifier = Modifier.weight(1f),
                            textAlign = TextAlign.Center,
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
                Spacer(modifier = Modifier.height(4.dp))

                // Calendar days
                val dayMap = days.associateBy { it.date }
                val daysInMonth = getDaysInMonth(uiState.currentMonth)

                val gridItems = mutableListOf<CalendarDay?>()
                val firstDayOfWeek = getFirstDayOfWeek(uiState.currentMonth)
                repeat(firstDayOfWeek) { gridItems.add(null) }
                daysInMonth.forEach { date ->
                    gridItems.add(dayMap[date])
                }

                // Calendar grid (manual rows to avoid nested scroll conflict)
                val rows = gridItems.chunked(7)
                rows.forEach { week ->
                    Row(modifier = Modifier.fillMaxWidth()) {
                        week.forEach { day ->
                            Box(modifier = Modifier.weight(1f)) {
                                CalendarDayCell(day)
                            }
                        }
                        val remaining = 7 - week.size
                        if (remaining > 0) {
                            repeat(remaining) {
                                Box(modifier = Modifier.weight(1f))
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Stats
                uiState.calendar?.let { cal ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text("本月签到率: ${(cal.signinRate * 100).toInt()}%", fontWeight = FontWeight.Bold)
                    LinearProgressIndicator(
                        progress = { cal.signinRate.toFloat() },
                        modifier = Modifier.fillMaxWidth().height(8.dp).padding(top = 4.dp)
                    )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CalendarDayCell(day: CalendarDay?) {
    Box(
        modifier = Modifier.aspectRatio(1f).padding(2.dp),
        contentAlignment = Alignment.Center
    ) {
        if (day != null) {
            val bgColor = when (day.status) {
                "SIGNED" -> Color(0xFF43A047)
                "TIMEOUT" -> Color(0xFFE53935)
                "PENDING" -> Color(0xFFFF9800)
                else -> Color.Transparent
            }
            val date = day.date.substringAfterLast("-").toIntOrNull() ?: return@Box
            Box(
                modifier = Modifier.size(32.dp).then(
                    if (bgColor != Color.Transparent) Modifier.background(bgColor, CircleShape) else Modifier
                ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "$date",
                    fontSize = 14.sp,
                    color = if (bgColor != Color.Transparent) Color.White else MaterialTheme.colorScheme.onSurface
                )
            }
        }
    }
}

private val monthFormatter = DateTimeFormatter.ofPattern("yyyy-MM")

private fun prevMonth(month: String): String {
    val ym = try { YearMonth.parse(month, monthFormatter) } catch (e: Exception) { return month }
    return ym.minusMonths(1).format(monthFormatter)
}

private fun nextMonth(month: String): String {
    val ym = try { YearMonth.parse(month, monthFormatter) } catch (e: Exception) { return month }
    return ym.plusMonths(1).format(monthFormatter)
}

private fun getDaysInMonth(month: String): List<String> {
    val ym = try { YearMonth.parse(month, monthFormatter) } catch (e: Exception) { return emptyList() }
    return (1..ym.lengthOfMonth()).map { "$month-${"%02d".format(it)}" }
}

private fun getFirstDayOfWeek(month: String): Int {
    val ld = try { LocalDate.parse("$month-01") } catch (e: Exception) { return 0 }
    return (ld.dayOfWeek.value % 7)
}
