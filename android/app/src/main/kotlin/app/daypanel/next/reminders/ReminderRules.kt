package app.daypanel.next.reminders

import java.time.*
import java.time.temporal.ChronoUnit

data class Plan(val start: LocalDate, val target: Long, val schedule: String,
    val weekdays: Int, val interval: Int, val weeklyGoal: Int)
data class ReminderHabit(val id: String, val title: String, val kind: String,
    val start: LocalDate, val archived: Boolean, val enabled: Boolean,
    val minutes: List<Int>, val revision: Long, val plans: List<Plan>, val entries: Map<LocalDate, Long>, val breaks: List<RestPeriod> = emptyList())
data class RestPeriod(val start:LocalDate,val end:LocalDate?,val kind:String) { fun contains(day:LocalDate)=day>=start&&(end==null||day<=end) }

data class DueTime(val day: LocalDate, val minute: Int, val instant: Instant)

object ReminderRules {
    fun eligible(h: ReminderHabit, day: LocalDate): Boolean {
        if (!h.enabled || h.archived || day < h.start || h.breaks.any { it.contains(day) }) return false
        val p = h.plans.lastOrNull { it.start <= day } ?: return false
        val scheduled = when (p.schedule) {
            "weekdays" -> p.weekdays and (1 shl (day.dayOfWeek.value - 1)) != 0
            "interval" -> p.interval > 0 && ChronoUnit.DAYS.between(p.start, day) % p.interval == 0L
            "weekly" -> true
            else -> false
        }
        if (!scheduled || (h.entries[day] ?: -1) >= p.target) return false
        if (p.schedule == "weekly") {
            val monday = day.minusDays((day.dayOfWeek.value - 1).toLong())
            val from = maxOf(monday, p.start)
            val achieved = h.entries.count { (date, value) -> date >= from && date <= day && value >= p.target && h.breaks.none { it.contains(date) } }
            if (achieved >= p.weeklyGoal) return false
        }
        return true
    }

    // LocalDate/ZoneId resolve DST gaps forward and select the earlier offset
    // in a repeated hour. A delivered local-day/minute key prevents duplicates.
    fun next(h: ReminderHabit, now: ZonedDateTime, delivered: Set<String>, generation: Long): DueTime? {
        for (offset in 0L..371L) {
            val day = now.toLocalDate().plusDays(offset)
            if (!eligible(h, day)) continue
            for (minute in h.minutes.sorted()) {
                val at = day.atTime(minute / 60, minute % 60).atZone(now.zone).toInstant()
                if (at > now.toInstant() && key(h.id, generation, h.revision, day, minute) !in delivered) {
                    return DueTime(day, minute, at)
                }
            }
        }
        return null
    }

    fun key(id: String, generation: Long, revision: Long, day: LocalDate, minute: Int) =
        "$day|$id|$generation|$revision|$minute"

    fun snooze(now: ZonedDateTime, day: LocalDate): Instant? {
        val next = now.plusMinutes(10)
        return if (now.toLocalDate() == day && next.toLocalDate() == day) next.toInstant() else null
    }
}
