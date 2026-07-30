package com.example.elderlyhealth.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.elderlyhealth.ui.auth.LoginScreen
import com.example.elderlyhealth.ui.auth.LoginViewModel
import com.example.elderlyhealth.ui.family.alarm.FamilyAlarmScreen
import com.example.elderlyhealth.ui.family.bind.BindElderlyScreen
import com.example.elderlyhealth.ui.family.home.FamilyHomeScreen
import com.example.elderlyhealth.ui.family.report.ReportDetailScreen
import com.example.elderlyhealth.ui.family.report.ReportListScreen
import com.example.elderlyhealth.ui.family.signin.SigninCalendarScreen
import com.example.elderlyhealth.ui.family.vital.VitalDetailScreen
import com.example.elderlyhealth.ui.community.alarm.AlarmBoardScreen
import com.example.elderlyhealth.ui.community.alarm.CommunityAlarmDetailScreen
import com.example.elderlyhealth.ui.community.dashboard.DashboardScreen
import com.example.elderlyhealth.ui.community.device.DeviceDetailScreen
import com.example.elderlyhealth.ui.community.device.DeviceFormScreen
import com.example.elderlyhealth.ui.community.device.DeviceListScreen
import com.example.elderlyhealth.ui.community.elderly.ElderlyFormScreen
import com.example.elderlyhealth.ui.community.elderly.ElderlyDetailScreen
import com.example.elderlyhealth.ui.community.elderly.ElderlyListScreen
import com.example.elderlyhealth.ui.community.patrol.PatrolListScreen
import com.example.elderlyhealth.ui.community.patrol.PatrolRecordListScreen
import com.example.elderlyhealth.ui.community.patrol.PatrolRecordScreen
import com.example.elderlyhealth.ui.community.signin.CommunitySigninScreen
import com.example.elderlyhealth.ui.community.trend.TrendScreen

@Composable
fun AppNavGraph(
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController = navController,
        startDestination = Screen.Login.route
    ) {
        composable(Screen.Login.route) {
            LoginScreen(
                onLoginSuccess = { role ->
                    val dest = when (role) {
                        "family" -> Screen.FamilyHome.route
                        else -> Screen.CommunityDashboard.route
                    }
                    navController.navigate(dest) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                }
            )
        }

        // Family screens
        composable(Screen.FamilyHome.route) {
            FamilyHomeScreen(
                onVitalClick = { elderlyId ->
                    navController.navigate(Screen.FamilyVitalDetail.createRoute(elderlyId))
                },
                onSigninClick = { elderlyId ->
                    navController.navigate(Screen.FamilySigninCalendar.createRoute(elderlyId))
                },
                onReportClick = { elderlyId ->
                    navController.navigate(Screen.FamilyReportList.createRoute(elderlyId))
                },
                onBindClick = {
                    navController.navigate(Screen.FamilyBind.route)
                },
                onLogout = {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(0) { inclusive = true }
                    }
                }
            )
        }

        composable(
            Screen.FamilyVitalDetail.route,
            arguments = listOf(navArgument("elderlyId") { type = NavType.StringType })
        ) { backStackEntry ->
            val elderlyId = backStackEntry.arguments?.getString("elderlyId") ?: return@composable
            VitalDetailScreen(elderlyId = elderlyId, onBack = { navController.popBackStack() })
        }

        composable(
            Screen.FamilyAlarm.route,
            arguments = listOf(navArgument("alarmId") { type = NavType.StringType })
        ) { backStackEntry ->
            val alarmId = backStackEntry.arguments?.getString("alarmId") ?: return@composable
            FamilyAlarmScreen(alarmId = alarmId, onBack = { navController.popBackStack() })
        }

        composable(
            Screen.FamilySigninCalendar.route,
            arguments = listOf(navArgument("elderlyId") { type = NavType.StringType })
        ) { backStackEntry ->
            val elderlyId = backStackEntry.arguments?.getString("elderlyId") ?: return@composable
            SigninCalendarScreen(elderlyId = elderlyId, onBack = { navController.popBackStack() })
        }

        composable(
            Screen.FamilyReportList.route,
            arguments = listOf(navArgument("elderlyId") { type = NavType.StringType })
        ) { backStackEntry ->
            val elderlyId = backStackEntry.arguments?.getString("elderlyId") ?: return@composable
            ReportListScreen(
                elderlyId = elderlyId,
                onBack = { navController.popBackStack() },
                onReportClick = { reportId ->
                    navController.navigate(Screen.FamilyReportDetail.createRoute(reportId))
                }
            )
        }

        composable(
            Screen.FamilyReportDetail.route,
            arguments = listOf(navArgument("reportId") { type = NavType.StringType })
        ) { backStackEntry ->
            val reportId = backStackEntry.arguments?.getString("reportId") ?: return@composable
            ReportDetailScreen(reportId = reportId, onBack = { navController.popBackStack() })
        }

        composable(Screen.FamilyBind.route) {
            BindElderlyScreen(onBack = { navController.popBackStack() })
        }

        // Community screens
        composable(Screen.CommunityDashboard.route) {
            DashboardScreen(
                onAlarmBoardClick = { navController.navigate(Screen.CommunityAlarmBoard.route) },
                onElderlyClick = { navController.navigate(Screen.CommunityElderlyList.route) },
                onDeviceClick = { navController.navigate(Screen.CommunityDeviceList.route) },
                onSigninClick = { navController.navigate(Screen.CommunitySigninOverview.route) },
                onPatrolClick = { navController.navigate(Screen.CommunityPatrolList.route) },
                onTrendClick = { navController.navigate(Screen.CommunityTrend.route) },
                onLogout = {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(0) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.CommunityAlarmBoard.route) {
            AlarmBoardScreen(
                onAlarmClick = { alarmId ->
                    navController.navigate(Screen.CommunityAlarmDetail.createRoute(alarmId))
                },
                onBack = { navController.popBackStack() }
            )
        }

        composable(
            Screen.CommunityAlarmDetail.route,
            arguments = listOf(navArgument("alarmId") { type = NavType.StringType })
        ) { backStackEntry ->
            val alarmId = backStackEntry.arguments?.getString("alarmId") ?: return@composable
            CommunityAlarmDetailScreen(alarmId = alarmId, onBack = { navController.popBackStack() })
        }

        composable(Screen.CommunityElderlyList.route) {
            ElderlyListScreen(
                onElderlyClick = { elderlyId ->
                    navController.navigate(Screen.CommunityElderlyDetail.createRoute(elderlyId))
                },
                onAddClick = {
                    navController.navigate(Screen.CommunityElderlyForm.createRoute())
                },
                onBack = { navController.popBackStack() }
            )
        }

        composable(
            Screen.CommunityElderlyForm.route,
            arguments = listOf(navArgument("elderlyId") { type = NavType.StringType })
        ) { backStackEntry ->
            val elderlyId = backStackEntry.arguments?.getString("elderlyId")
            ElderlyFormScreen(
                elderlyId = if (elderlyId == "new") null else elderlyId,
                onBack = { navController.popBackStack() },
                onSaved = { navController.popBackStack() }
            )
        }

        composable(
            Screen.CommunityElderlyDetail.route,
            arguments = listOf(navArgument("elderlyId") { type = NavType.StringType })
        ) { backStackEntry ->
            val elderlyId = backStackEntry.arguments?.getString("elderlyId") ?: return@composable
            ElderlyDetailScreen(
                elderlyId = elderlyId,
                onBack = { navController.popBackStack() },
                onReportsClick = { id -> navController.navigate(Screen.CommunityReportList.createRoute(id)) },
                onSigninCalendarClick = { id -> navController.navigate(Screen.CommunitySigninCalendar.createRoute(id)) }
            )
        }

        composable(Screen.CommunityDeviceList.route) {
            DeviceListScreen(
                onBack = { navController.popBackStack() },
                onDeviceClick = { deviceId -> navController.navigate(Screen.CommunityDeviceDetail.createRoute(deviceId)) },
                onAddClick = { navController.navigate(Screen.CommunityDeviceForm.createRoute()) }
            )
        }

        composable(
            Screen.CommunityDeviceDetail.route,
            arguments = listOf(navArgument("deviceId") { type = NavType.StringType })
        ) { backStackEntry ->
            val deviceId = backStackEntry.arguments?.getString("deviceId") ?: return@composable
            DeviceDetailScreen(
                deviceId = deviceId,
                onBack = { navController.popBackStack() },
                onEdit = { id -> navController.navigate(Screen.CommunityDeviceForm.createRoute(id)) }
            )
        }

        composable(
            Screen.CommunityDeviceForm.route,
            arguments = listOf(navArgument("deviceId") { type = NavType.StringType })
        ) { backStackEntry ->
            val deviceId = backStackEntry.arguments?.getString("deviceId")
            DeviceFormScreen(
                deviceId = if (deviceId == "new") null else deviceId,
                onBack = { navController.popBackStack() },
                onSaved = { navController.popBackStack() }
            )
        }

        composable(Screen.CommunitySigninOverview.route) {
            CommunitySigninScreen(onBack = { navController.popBackStack() })
        }

        composable(Screen.CommunityPatrolList.route) {
            PatrolListScreen(
                onRecordSubmit = { taskId, elderlyId ->
                    navController.navigate(Screen.CommunityPatrolRecord.createRoute(taskId, elderlyId))
                },
                onBack = { navController.popBackStack() },
                onRecordsClick = { navController.navigate(Screen.CommunityPatrolRecordList.route) }
            )
        }

        composable(
            Screen.CommunityPatrolRecord.route,
            arguments = listOf(
                navArgument("taskId") { type = NavType.StringType },
                navArgument("elderlyId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val taskId = backStackEntry.arguments?.getString("taskId") ?: return@composable
            val elderlyId = backStackEntry.arguments?.getString("elderlyId") ?: return@composable
            PatrolRecordScreen(
                taskId = taskId,
                elderlyId = elderlyId,
                onBack = { navController.popBackStack() },
                onSubmitted = { navController.popBackStack() }
            )
        }

        composable(Screen.CommunityTrend.route) {
            TrendScreen(onBack = { navController.popBackStack() })
        }

        composable(
            Screen.CommunitySigninCalendar.route,
            arguments = listOf(navArgument("elderlyId") { type = NavType.StringType })
        ) { backStackEntry ->
            val elderlyId = backStackEntry.arguments?.getString("elderlyId") ?: return@composable
            SigninCalendarScreen(elderlyId = elderlyId, onBack = { navController.popBackStack() })
        }

        composable(Screen.CommunityPatrolRecordList.route) {
            PatrolRecordListScreen(onBack = { navController.popBackStack() })
        }

        composable(
            Screen.CommunityReportList.route,
            arguments = listOf(navArgument("elderlyId") { type = NavType.StringType })
        ) { backStackEntry ->
            val elderlyId = backStackEntry.arguments?.getString("elderlyId") ?: return@composable
            ReportListScreen(
                elderlyId = elderlyId,
                onBack = { navController.popBackStack() },
                onReportClick = { reportId ->
                    navController.navigate(Screen.CommunityReportDetail.createRoute(reportId))
                }
            )
        }

        composable(
            Screen.CommunityReportDetail.route,
            arguments = listOf(navArgument("reportId") { type = NavType.StringType })
        ) { backStackEntry ->
            val reportId = backStackEntry.arguments?.getString("reportId") ?: return@composable
            ReportDetailScreen(reportId = reportId, onBack = { navController.popBackStack() })
        }
    }
}
