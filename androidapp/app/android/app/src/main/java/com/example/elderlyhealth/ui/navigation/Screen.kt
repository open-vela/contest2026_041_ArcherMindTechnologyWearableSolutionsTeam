package com.example.elderlyhealth.ui.navigation

sealed class Screen(val route: String) {
    // Auth
    data object Login : Screen("login")
    data object RoleSelect : Screen("role_select")

    // Family
    data object FamilyHome : Screen("family/home")
    data object FamilyVitalDetail : Screen("family/vital/{elderlyId}") {
        fun createRoute(elderlyId: String) = "family/vital/$elderlyId"
    }
    data object FamilyAlarm : Screen("family/alarm/{alarmId}") {
        fun createRoute(alarmId: String) = "family/alarm/$alarmId"
    }
    data object FamilySigninCalendar : Screen("family/signin/{elderlyId}") {
        fun createRoute(elderlyId: String) = "family/signin/$elderlyId"
    }
    data object FamilyReportList : Screen("family/reports/{elderlyId}") {
        fun createRoute(elderlyId: String) = "family/reports/$elderlyId"
    }
    data object FamilyReportDetail : Screen("family/report/{reportId}") {
        fun createRoute(reportId: String) = "family/report/$reportId"
    }
    data object FamilyBind : Screen("family/bind")

    // Community
    data object CommunityDashboard : Screen("community/dashboard")
    data object CommunityAlarmBoard : Screen("community/alarm_board")
    data object CommunityAlarmDetail : Screen("community/alarm/{alarmId}") {
        fun createRoute(alarmId: String) = "community/alarm/$alarmId"
    }
    data object CommunityElderlyList : Screen("community/elderly")
    data object CommunityElderlyDetail : Screen("community/elderly/{elderlyId}") {
        fun createRoute(elderlyId: String) = "community/elderly/$elderlyId"
    }
    data object CommunityElderlyForm : Screen("community/elderly/form/{elderlyId}") {
        fun createRoute(elderlyId: String? = null) = "community/elderly/form/${elderlyId ?: "new"}"
    }
    data object CommunityDeviceList : Screen("community/devices")
    data object CommunityDeviceDetail : Screen("community/device/{deviceId}") {
        fun createRoute(deviceId: String) = "community/device/$deviceId"
    }
    data object CommunityDeviceForm : Screen("community/device/form/{deviceId}") {
        fun createRoute(deviceId: String? = null) = "community/device/form/${deviceId ?: "new"}"
    }
    data object CommunitySigninOverview : Screen("community/signin")
    data object CommunitySigninCalendar : Screen("community/signin/{elderlyId}") {
        fun createRoute(elderlyId: String) = "community/signin/$elderlyId"
    }
    data object CommunityPatrolList : Screen("community/patrol")
    data object CommunityPatrolRecord : Screen("community/patrol/record/{taskId}/{elderlyId}") {
        fun createRoute(taskId: String, elderlyId: String) = "community/patrol/record/$taskId/$elderlyId"
    }
    data object CommunityTrend : Screen("community/trend")
    data object CommunityPatrolRecordList : Screen("community/patrol/records")
    data object CommunityReportList : Screen("community/reports/{elderlyId}") {
        fun createRoute(elderlyId: String) = "community/reports/$elderlyId"
    }
    data object CommunityReportDetail : Screen("community/report/{reportId}") {
        fun createRoute(reportId: String) = "community/report/$reportId"
    }
}
