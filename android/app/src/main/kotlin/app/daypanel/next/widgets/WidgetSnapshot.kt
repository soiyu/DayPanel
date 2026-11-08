package app.daypanel.next.widgets

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.content.res.Configuration
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import app.daypanel.next.reminders.RestPeriod

/** Display-only snapshot. Dart owns all writes and plan/achievement decisions. */
data class WidgetItem(
    val id: String, val kind: String, val title: String, val archived: Boolean,
    val quantity: Boolean = false, val value: Long? = null, val target: Long = 1000,
    val unit: String = "", val schedule: String = "weekdays", val scheduled: Boolean = true,
    val weekCount: Int = 0, val weekGoal: Int = 0, val resident: Boolean = false,
    val doneDay: String? = null, val dueDay: String? = null,
    val rest: String? = null, val icon: Int = 0, val color: String = "auto", val frame: String = "auto",
) { val done: Boolean get() = if (kind == "habit") (value ?: -1) >= target else doneDay != null }
data class WidgetSnapshot(val generation: Long, val day: LocalDate, val chinese: Boolean,
    val dark: Boolean, val items: Map<String, WidgetItem>, val palette: String = "blue", val frame: String = "soft", val revision: Long = -1)

object WidgetSnapshotReader {
    fun read(context: Context, day: LocalDate = LocalDate.now()): WidgetSnapshot? {
        val file = context.getDatabasePath("daypanel_flutter.db")
        if (!file.exists()) return null
        SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READWRITE).use { db ->
            if (db.version !in 7..11) return null
            db.beginTransactionNonExclusive()
            try {
                val generation = db.rawQuery("SELECT generation FROM runtime WHERE id=1", null).use { c ->
                    if (!c.moveToFirst()) return null
                    c.getLong(0)
                }
                val revision = if(db.version >= 10) db.rawQuery("SELECT revision FROM runtime WHERE id=1",null).use { it.moveToFirst(); it.getLong(0) } else -1L
                val settings = mutableMapOf<String, String>()
                db.rawQuery("SELECT key,value FROM settings", null).use { c ->
                    while (c.moveToNext()) settings[c.getString(0)] = c.getString(1)
                }
                val chinese = settings["locale"] == "zh" ||
                    (settings["locale"] !in listOf("zh", "en") && context.resources.configuration.locales[0].language == "zh")
                val dark = settings["theme"] == "dark" || (settings["theme"] !in listOf("dark", "light") &&
                    context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES)
                val allRests=mutableMapOf<String,MutableList<RestPeriod>>()
                if(db.version>=9)db.rawQuery("SELECT habit_id,start_day,end_day,kind FROM habit_breaks",null).use { c ->
                    while(c.moveToNext())allRests.getOrPut(c.getString(0)){mutableListOf()}.add(RestPeriod(LocalDate.parse(c.getString(1)),if(c.isNull(2))null else LocalDate.parse(c.getString(2)),c.getString(3)))
                }
                val rests=allRests.mapValues { (_,rows)->rows.firstOrNull { it.contains(day) }?.kind }
                val items = mutableMapOf<String, WidgetItem>()
                val decoration = if(db.version >= 8) "h.icon,h.color,h.frame" else "0,'auto','auto'"
                db.rawQuery("""SELECT h.id,h.title,h.kind,h.archived,h.start_day,p.effective_day,p.target,p.unit,p.schedule,p.weekdays,p.interval_days,p.weekly_goal,$decoration
                    FROM habits h JOIN plans p ON p.habit_id=h.id
                    WHERE p.effective_day=(SELECT MAX(effective_day) FROM plans WHERE habit_id=h.id AND effective_day<=?)""", arrayOf(day.toString())).use { c ->
                    while (c.moveToNext()) {
                        val id = c.getString(0)
                        val planDay = LocalDate.parse(c.getString(5))
                        val start = LocalDate.parse(c.getString(4))
                        val target = c.getLong(6)
                        val schedule = c.getString(8)
                        val scheduled = day >= start && WidgetDisplayRules.scheduled(day, planDay, schedule, c.getInt(9), c.getInt(10))
                        val from = maxOf(planDay, day.minusDays((day.dayOfWeek.value - 1).toLong()))
                        var value: Long? = null
                        var weekCount = 0
                        db.rawQuery("SELECT day,value FROM entries WHERE habit_id=? AND day>=? AND day<=?", arrayOf(id, from.toString(), day.toString())).use { e ->
                            while (e.moveToNext()) {
                                if (e.getString(0) == day.toString()) value = e.getLong(1)
                                if (e.getLong(1) >= target && allRests[id].orEmpty().none { it.contains(LocalDate.parse(e.getString(0))) }) weekCount++
                            }
                        }
                        items["habit:$id"] = WidgetItem(id, "habit", c.getString(1), c.getInt(3) == 1 || day < start,
                            c.getString(2) in setOf("quantity", "count"), value, target, c.getString(7), schedule, scheduled, weekCount, c.getInt(11), rest=rests[id], icon=c.getInt(12), color=c.getString(13), frame=c.getString(14))
                    }
                }
                db.rawQuery("SELECT id,title,resident,archived,completed_day,due_day,start_day FROM tasks", null).use { c ->
                    while (c.moveToNext()) {
                        val id = c.getString(0)
                        val resident = c.getInt(2) == 1
                        val done = if (resident) db.rawQuery("SELECT day FROM task_entries WHERE task_id=? AND day=?", arrayOf(id, day.toString())).use { e ->
                            if (e.moveToFirst()) e.getString(0) else null
                        } else c.getString(4)
                        items["task:$id"] = WidgetItem(id, "task", c.getString(1), c.getInt(3) == 1 ||
                            (resident && day < LocalDate.parse(c.getString(6))), resident = resident, doneDay = done, dueDay = c.getString(5))
                    }
                }
                db.setTransactionSuccessful()
                return WidgetSnapshot(generation, day, chinese, dark, items, settings["palette"] ?: "blue", settings["icon_frame"] ?: "soft", revision)
            } finally { db.endTransaction() }
        }
    }
}

object WidgetDisplayRules {
    fun scheduled(day: LocalDate, start: LocalDate, schedule: String, weekdays: Int, interval: Int): Boolean =
        day >= start && when (schedule) {
            "weekly" -> true
            "weekdays" -> weekdays and (1 shl (day.dayOfWeek.value - 1)) != 0
            "interval" -> interval > 0 && ChronoUnit.DAYS.between(start, day) % interval == 0L
            else -> false
        }
    fun quantity(value: Long) = java.math.BigDecimal.valueOf(value, 3).stripTrailingZeros().toPlainString()
}
