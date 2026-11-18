package app.daypanel.next.reminders

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import org.json.JSONArray
import java.time.LocalDate

data class ReminderSnapshot(
    val generation: Long,
    val habits: List<ReminderHabit>,
    val tasks: List<ReminderTask> = emptyList(),
    val chinese: Boolean,
    val sound: Boolean = false,
    val vibrate: Boolean = false
)

object SnapshotReader {
    fun read(context: Context, includeUnconfigured: Boolean = false): ReminderSnapshot? {
        val file = context.getDatabasePath("daypanel_flutter.db")
        if (!file.exists()) return null
        // No schema creation, user-data mutations or completion writes here.
        // A transaction gives all queries one SQLite snapshot, including WAL.
        SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READWRITE or SQLiteDatabase.ENABLE_WRITE_AHEAD_LOGGING).use { db ->
            if (db.version !in 3..13) return null // Dart owns schema upgrades; these versions share reminder tables.
            if(android.os.Build.VERSION.SDK_INT>=35) db.beginTransactionReadOnly() else db.beginTransactionNonExclusive()
            try {
                val generation = db.rawQuery("SELECT generation FROM runtime WHERE id=1", null).use { c ->
                    if (!c.moveToFirst()) return null
                    c.getLong(0)
                }
                var locale = "system"
                var sound = false
                var vibrate = false
                db.rawQuery("SELECT key, value FROM settings WHERE key IN ('locale', 'reminder_sound', 'reminder_vibrate')", null).use { c ->
                    while (c.moveToNext()) {
                        val k = c.getString(0)
                        val v = c.getString(1)
                        if (k == "locale") locale = v
                        if (k == "reminder_sound") sound = v == "1" || v == "on"
                        if (k == "reminder_vibrate") vibrate = v == "1" || v == "on"
                    }
                }
                val chinese = locale == "zh" || (locale == "system" && context.resources.configuration.locales[0].language == "zh")
                val plans = mutableMapOf<String, MutableList<Plan>>()
                db.rawQuery("SELECT habit_id,effective_day,target,schedule,weekdays,interval_days,weekly_goal FROM plans ORDER BY effective_day", null).use { c ->
                    while (c.moveToNext()) plans.getOrPut(c.getString(0)) { mutableListOf() }.add(
                        Plan(LocalDate.parse(c.getString(1)), c.getLong(2), c.getString(3), c.getInt(4), c.getInt(5), c.getInt(6)))
                }
                val entries = mutableMapOf<String, MutableMap<LocalDate, Long>>()
                db.rawQuery("SELECT habit_id,day,value FROM entries WHERE day>=?", arrayOf(LocalDate.now().minusDays(7).toString())).use { c ->
                    while (c.moveToNext()) entries.getOrPut(c.getString(0)) { mutableMapOf() }[LocalDate.parse(c.getString(1))] = c.getLong(2)
                }
                val rests=mutableMapOf<String,MutableList<RestPeriod>>()
                if(db.version>=9)db.rawQuery("SELECT habit_id,start_day,end_day,kind FROM habit_breaks",null).use { c ->
                    while(c.moveToNext())rests.getOrPut(c.getString(0)){mutableListOf()}.add(RestPeriod(LocalDate.parse(c.getString(1)),if(c.isNull(2))null else LocalDate.parse(c.getString(2)),c.getString(3)))
                }
                val habits = mutableListOf<ReminderHabit>()
                db.rawQuery(if(includeUnconfigured) "SELECT h.id,h.title,h.kind,h.start_day,h.archived,COALESCE(r.enabled,0),COALESCE(r.minutes,'[540]'),COALESCE(r.revision,0) FROM habits h LEFT JOIN reminders r ON r.habit_id=h.id" else "SELECT h.id,h.title,h.kind,h.start_day,h.archived,r.enabled,r.minutes,r.revision FROM habits h JOIN reminders r ON r.habit_id=h.id", null).use { c ->
                    while (c.moveToNext()) {
                        val id = c.getString(0)
                        val times = JSONArray(c.getString(6))
                        val minutes = (0 until times.length()).map { times.getInt(it) }
                        if (minutes.isEmpty() || minutes.size > 5 || minutes.any { it !in 0..1439 }) continue
                        habits.add(ReminderHabit(id,c.getString(1),c.getString(2),LocalDate.parse(c.getString(3)),c.getInt(4)==1,
                            c.getInt(5)==1,minutes,c.getLong(7),plans[id].orEmpty(),entries[id].orEmpty(),rests[id].orEmpty()))
                    }
                }
                val tasks = mutableListOf<ReminderTask>()
                if (db.version >= 13) {
                    val completedDays = mutableMapOf<String, MutableSet<LocalDate>>()
                    db.rawQuery("SELECT task_id, day FROM task_entries", null).use { c ->
                        while (c.moveToNext()) {
                            completedDays.getOrPut(c.getString(0)) { mutableSetOf() }.add(LocalDate.parse(c.getString(1)))
                        }
                    }
                    db.rawQuery(
                        "SELECT t.id, t.title, t.due_day, t.resident, t.archived, t.completed_day, r.enabled, r.minutes, r.revision " +
                        "FROM tasks t JOIN task_reminders r ON r.task_id = t.id", null
                    ).use { c ->
                        while (c.moveToNext()) {
                            val id = c.getString(0)
                            val title = c.getString(1)
                            val dueDay = if (c.isNull(2)) null else LocalDate.parse(c.getString(2))
                            val resident = c.getInt(3) == 1
                            val archived = c.getInt(4) == 1
                            val completed = !c.isNull(5)
                            val enabled = c.getInt(6) == 1
                            val times = JSONArray(c.getString(7))
                            val minutes = (0 until times.length()).map { times.getInt(it) }
                            if (minutes.isEmpty() || minutes.size > 5 || minutes.any { it !in 0..1439 }) continue
                            val revision = c.getLong(8)
                            tasks.add(ReminderTask(id, title, dueDay, resident, archived, completed, enabled, minutes, revision, completedDays[id].orEmpty()))
                        }
                    }
                }
                db.setTransactionSuccessful()
                return ReminderSnapshot(generation, habits, tasks, chinese, sound, vibrate)
            } finally { db.endTransaction() }
        }
    }
}
