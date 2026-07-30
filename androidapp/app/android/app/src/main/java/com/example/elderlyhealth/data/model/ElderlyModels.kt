package com.example.elderlyhealth.data.model

import com.google.gson.annotations.SerializedName

// Go sql.NullString / sql.NullInt64 / sql.NullFloat64 / sql.NullTime format
data class NullString(
    @SerializedName("String") val value: String = "",
    @SerializedName("Valid") val valid: Boolean = false
)

data class NullInt64(
    @SerializedName("Int64") val value: Long = 0,
    @SerializedName("Valid") val valid: Boolean = false
)

data class NullFloat64(
    @SerializedName("Float64") val value: Double = 0.0,
    @SerializedName("Valid") val valid: Boolean = false
)

data class NullTime(
    @SerializedName("Time") val value: String = "",
    @SerializedName("Valid") val valid: Boolean = false
)

data class ElderlyDetailResponse(
    @SerializedName("id") val id: String = "",
    @SerializedName("name") val name: String = "",
    @SerializedName("gender") val gender: String = "",
    @SerializedName("birth_date") val birthDate: NullTime = NullTime(),
    @SerializedName("age") val age: NullInt64 = NullInt64(),
    @SerializedName("phone") val phone: String = "",
    @SerializedName("address") val address: NullString = NullString(),
    @SerializedName("community_name") val communityName: String = "",
    @SerializedName("emergency_contact") val emergencyContact: NullString = NullString(),
    @SerializedName("emergency_contact_relation") val emergencyContactRelation: NullString = NullString(),
    @SerializedName("emergency_phone") val emergencyPhone: NullString = NullString(),
    @SerializedName("heart_rate_baseline") val heartRateBaseline: NullFloat64 = NullFloat64(),
    @SerializedName("spo2_baseline") val spo2Baseline: NullFloat64 = NullFloat64(),
    @SerializedName("temp_baseline") val tempBaseline: NullFloat64 = NullFloat64(),
    @SerializedName("status") val status: String = "",
    @SerializedName("created_at") val createdAt: String = "",
    @SerializedName("bound_device_name") val boundDeviceName: String = "",
    @SerializedName("bound_device_sn") val boundDeviceSn: String = "",
    @SerializedName("medical_history_meta") val medicalHistoryMeta: NullString = NullString()
) {
    fun toElderlyProfile() = ElderlyProfile(
        id = id,
        name = name,
        gender = gender,
        birthDate = if (birthDate.valid) birthDate.value.take(10) else "",
        age = if (age.valid) age.value.toInt() else 0,
        phone = phone,
        address = if (address.valid) address.value else "",
        communityName = communityName,
        emergencyContact = if (emergencyContact.valid) EmergencyContact(
            name = emergencyContact.value,
            phone = if (emergencyPhone.valid) emergencyPhone.value else "",
            relation = if (emergencyContactRelation.valid) emergencyContactRelation.value else ""
        ) else null,
        baseline = VitalBaseline(
            heartRateMin = if (heartRateBaseline.valid) heartRateBaseline.value.toInt() else 55,
            heartRateMax = 100,
            spo2Min = if (spo2Baseline.valid) spo2Baseline.value.toInt() else 95
        ),
        device = if (boundDeviceSn.isNotEmpty()) DeviceBrief(
            deviceSn = boundDeviceSn
        ) else null,
        status = status,
        createdAt = createdAt
    )
}

data class ElderlyProfile(
    @SerializedName("id") val id: String = "",
    @SerializedName("name") val name: String = "",
    @SerializedName("gender") val gender: String = "",
    @SerializedName("birth_date") val birthDate: String = "",
    @SerializedName("age") val age: Int = 0,
    @SerializedName("phone") val phone: String = "",
    @SerializedName("id_card") val idCard: String? = null,
    @SerializedName("address") val address: String = "",
    @SerializedName("latitude") val latitude: Double = 0.0,
    @SerializedName("longitude") val longitude: Double = 0.0,
    @SerializedName("community_id") val communityId: String? = null,
    @SerializedName("community_name") val communityName: String? = null,
    @SerializedName("community") val community: CommunityBrief? = null,
    @SerializedName("emergency_contact") val emergencyContact: EmergencyContact? = null,
    @SerializedName("medical_history") val medicalHistory: MedicalHistory? = null,
    @SerializedName("baseline") val baseline: VitalBaseline? = null,
    @SerializedName("device") val device: DeviceBrief? = null,
    @SerializedName("bound_family") val boundFamily: List<FamilyBrief>? = null,
    @SerializedName("device_online") val deviceOnline: Boolean = false,
    @SerializedName("battery") val battery: Int? = null,
    @SerializedName("latest_vital") val latestVital: VitalSnapshot? = null,
    @SerializedName("today_signed_in") val todaySignedIn: Boolean = false,
    @SerializedName("today_signed_in_at") val todaySignedInAt: String? = null,
    @SerializedName("active_alarms") val activeAlarms: Int = 0,
    @SerializedName("status") val status: String = "active",
    @SerializedName("created_at") val createdAt: String = ""
) {
    val elderlyId: String get() = id
}

data class CreateElderlyRequest(
    @SerializedName("name") val name: String,
    @SerializedName("phone") val phone: String,
    @SerializedName("gender") val gender: String,
    @SerializedName("birth_date") val birthDate: String,
    @SerializedName("id_card") val idCard: String?,
    @SerializedName("address") val address: String,
    @SerializedName("latitude") val latitude: Double,
    @SerializedName("longitude") val longitude: Double,
    @SerializedName("community_id") val communityId: String,
    @SerializedName("emergency_contact") val emergencyContact: EmergencyContact,
    @SerializedName("medical_history") val medicalHistory: MedicalHistory?,
    @SerializedName("baseline") val baseline: VitalBaseline?
)

data class CreateElderlyResponse(
    @SerializedName("id") val id: String = "",
    @SerializedName("name") val name: String = "",
    @SerializedName("created_at") val createdAt: String = ""
)

data class UpdateElderlyRequest(
    @SerializedName("address") val address: String? = null,
    @SerializedName("emergency_contact") val emergencyContact: EmergencyContact? = null,
    @SerializedName("medical_history") val medicalHistory: MedicalHistory? = null,
    @SerializedName("baseline") val baseline: VitalBaseline? = null
)

data class CommunityBrief(
    @SerializedName("community_id") val communityId: String = "",
    @SerializedName("name") val name: String = ""
)

data class EmergencyContact(
    @SerializedName("name") val name: String = "",
    @SerializedName("phone") val phone: String = "",
    @SerializedName("relation") val relation: String = ""
)

data class MedicalHistory(
    @SerializedName("hypertension") val hypertension: Boolean = false,
    @SerializedName("diabetes") val diabetes: Boolean = false,
    @SerializedName("heart_disease") val heartDisease: String? = null,
    @SerializedName("allergies") val allergies: List<String>? = null,
    @SerializedName("medications") val medications: List<Medication>? = null
)

data class Medication(
    @SerializedName("name") val name: String = "",
    @SerializedName("dosage") val dosage: String = "",
    @SerializedName("frequency") val frequency: String = ""
)

data class VitalBaseline(
    @SerializedName("heart_rate_min") val heartRateMin: Int = 55,
    @SerializedName("heart_rate_max") val heartRateMax: Int = 100,
    @SerializedName("spo2_min") val spo2Min: Int = 95
)

data class DeviceBrief(
    @SerializedName("device_id") val deviceId: String = "",
    @SerializedName("device_sn") val deviceSn: String = "",
    @SerializedName("online") val online: Boolean = false,
    @SerializedName("battery") val battery: Int = 0,
    @SerializedName("firmware_version") val firmwareVersion: String = "",
    @SerializedName("last_heartbeat_at") val lastHeartbeatAt: String = ""
)

data class FamilyBrief(
    @SerializedName("user_id") val userId: String = "",
    @SerializedName("real_name") val realName: String = "",
    @SerializedName("relation") val relation: String = "",
    @SerializedName("is_primary") val isPrimary: Boolean = false,
    @SerializedName("phone") val phone: String = ""
)

data class BindingInfo(
    @SerializedName("binding_id") val bindingId: String = "",
    @SerializedName("elderly") val elderly: BindingElderly = BindingElderly(),
    @SerializedName("device") val device: DeviceBrief? = null,
    @SerializedName("relation") val relation: String = "",
    @SerializedName("is_primary") val isPrimary: Boolean = false,
    @SerializedName("today_signed_in") val todaySignedIn: Boolean = false,
    @SerializedName("active_alarms") val activeAlarms: Int = 0,
    @SerializedName("device_online") val deviceOnline: Boolean = false,
    @SerializedName("latest_vital") val latestVital: VitalSnapshot? = null,
    @SerializedName("status") val status: String = "active"
)

data class BindingElderly(
    @SerializedName("id") val id: String = "",
    @SerializedName("name") val name: String = ""
) {
    val elderlyId: String get() = id
}

data class BindingsResponse(
    @SerializedName("list") val list: List<BindingInfo> = emptyList(),
    @SerializedName("pagination") val pagination: Pagination = Pagination()
)

data class BindElderlyRequest(
    @SerializedName("elderly_id") val elderlyId: String,
    @SerializedName("relation") val relation: String,
    @SerializedName("verify_code") val verifyCode: String
)