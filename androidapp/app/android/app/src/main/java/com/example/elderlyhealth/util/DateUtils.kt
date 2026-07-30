package com.example.elderlyhealth.util

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.time.LocalDateTime

object DateUtils {
    private val isoFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'").withZone(ZoneId.of("UTC"))
    private val dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    private val timeFormatter = DateTimeFormatter.ofPattern("HH:mm")
    private val dateTimeFormatter = DateTimeFormatter.ofPattern("MM-dd HH:mm")

    fun parseIso(dateStr: String): Instant? = try {
        Instant.parse(dateStr)
    } catch (e: Exception) {
        try {
            isoFormatter.parse(dateStr, Instant::from)
        } catch (e2: Exception) {
            try {
                LocalDate.parse(dateStr).atStartOfDay(ZoneId.of("UTC")).toInstant()
            } catch (e3: Exception) { null }
        }
    }

    fun formatDate(dateStr: String): String {
        val instant = parseIso(dateStr) ?: return dateStr
        return dateFormatter.format(instant.atZone(ZoneId.systemDefault()))
    }

    fun formatTime(dateStr: String): String {
        val instant = parseIso(dateStr) ?: return dateStr
        return timeFormatter.format(instant.atZone(ZoneId.systemDefault()))
    }

    fun formatDateTime(dateStr: String): String {
        val instant = parseIso(dateStr) ?: return dateStr
        return dateTimeFormatter.format(instant.atZone(ZoneId.systemDefault()))
    }

    fun formatMonth(month: String): String = month

    fun formatAge(birthDate: String): Int {
        val instant = parseIso(birthDate) ?: return 0
        val birthLocal = instant.atZone(ZoneId.systemDefault()).toLocalDate()
        return ChronoUnit.YEARS.between(birthLocal, LocalDate.now()).toInt()
    }
}
