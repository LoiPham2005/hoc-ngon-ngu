package com.loipham.lingua.widget

import android.content.SharedPreferences
import java.time.LocalDate
import java.time.temporal.ChronoUnit

/**
 * Dữ liệu widget do Flutter ghi (HomeWidgetService, lib/modules/home_widget) — khoá khớp
 * `buildHomeWidgetData`. Giá trị phụ thuộc ngày tính lại ở đây để đúng cả khi app không chạy.
 */
data class WidgetData(
    val streak: Int = 0,
    val today: Int = 0,
    val goal: Int = 10,
    val due: Int = 0,
    val courseFlag: String = "🇯🇵",
    val continueTitle: String = "Hiragana",
    /** Lượt học 7 ngày kết thúc hôm nay (cũ → mới) + chữ viết tắt thứ tương ứng. */
    val bars: List<Int> = List(7) { 0 },
    val weekdays: List<String> = DEFAULT_WEEKDAYS,
    val labelStreak: String = "ngày liên tiếp",
    val labelToday: String = "Hôm nay",
    val labelDue: String = "Không có mục cần ôn",
    val labelContinue: String = "Học tiếp",
) {
    companion object {
        private val DEFAULT_WEEKDAYS = listOf("T2", "T3", "T4", "T5", "T6", "T7", "CN")

        /** Ngày học gần nhất không phải hôm nay → lượt hôm nay = 0; cũ hơn hôm qua → chuỗi = 0. */
        fun from(prefs: SharedPreferences, now: LocalDate = LocalDate.now()): WidgetData {
            val base = WidgetData()
            if (!prefs.contains("streak")) return base.copy(weekdays = weekdaysEnding(now, base.weekdays))
            val today = now.toString()
            val last = prefs.getString("lastActiveDay", "") ?: ""
            fun int(key: String) = (prefs.all[key] as? Number)?.toInt() ?: 0
            fun str(key: String, fallback: String) = prefs.getString(key, null) ?: fallback

            val values = (prefs.getString("last7", "") ?: "").split(",").map { it.toIntOrNull() ?: 0 }
            val end = runCatching { LocalDate.parse(prefs.getString("last7End", "")) }.getOrNull()
            val bars = if (values.size == 7 && end != null) {
                val lag = ChronoUnit.DAYS.between(end, now).toInt()
                List(7) { i -> values.getOrNull(i + lag) ?: 0 }
            } else {
                base.bars
            }
            val names = (prefs.getString("labelWeekdays", "") ?: "").split(",")
            return WidgetData(
                streak = if (last == today || last == now.minusDays(1).toString()) int("streak") else 0,
                today = if (last == today) int("todayCount") else 0,
                goal = int("dailyGoal").coerceAtLeast(1),
                due = int("dueCount"),
                courseFlag = str("courseFlag", base.courseFlag),
                continueTitle = str("continueTitle", base.continueTitle),
                bars = bars,
                weekdays = weekdaysEnding(now, if (names.size == 7) names else base.weekdays),
                labelStreak = str("labelStreak", base.labelStreak),
                labelToday = str("labelToday", base.labelToday),
                labelDue = str("labelDue", base.labelDue),
                labelContinue = str("labelContinue", base.labelContinue),
            )
        }

        /** [mondayFirst] = Thứ 2 → Chủ nhật; trả 7 ngày kết thúc hôm nay. */
        private fun weekdaysEnding(now: LocalDate, mondayFirst: List<String>) =
            List(7) { i -> mondayFirst[now.minusDays((6 - i).toLong()).dayOfWeek.value - 1] }
    }
}
