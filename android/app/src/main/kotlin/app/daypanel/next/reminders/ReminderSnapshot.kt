package app.daypanel.next.reminders

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import org.json.JSONArray
import java.time.LocalDate

data class ReminderSnapshot(val generation: Long, val habits: List<ReminderHabit>, val chinese: Boolean)

object SnapshotReader {
    fun read(context: Context): ReminderSnapshot? {
        val file = context.getDatabasePath("daypanel_flutter.db")
        if (!file.exists()) return null
        // No schema creation, user-data mutations or completion writes here.
        // A transaction gives all queries one SQLite snapshot, including WAL.
        SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READWRITE).use { db ->
            if (db.version !in 3..6) return null // Dart owns schema upgrades; these versions share reminder tables.
            db.beginTransactionNonExclusive()
            try {
                val generation = db.rawQuery("SELECT generation FROM runtime WHERE id=1", null).use { c ->
                    if (!c.moveToFirst()) return null
                    c.getLong(0)
                }
                val locale = db.rawQuery("SELECT value FROM settings WHERE key='locale'", null).use { c -> if (c.moveToFirst()) c.getString(0) else "system" }
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
                val habits = mutableListOf<ReminderHabit>()
                db.rawQuery("SELECT h.id,h.title,h.kind,h.start_day,h.archived,r.enabled,r.minutes,r.revision FROM habits h JOIN reminders r ON r.habit_id=h.id", null).use { c ->
                    while (c.moveToNext()) {
                        val id = c.getString(0)
                        val times = JSONArray(c.getString(6))
                        val minutes = (0 until times.length()).map { times.getInt(it) }
                        if (minutes.isEmpty() || minutes.size > 5 || minutes.any { it !in 0..1439 }) continue
                        habits.add(ReminderHabit(id,c.getString(1),c.getString(2),LocalDate.parse(c.getString(3)),c.getInt(4)==1,
                            c.getInt(5)==1,minutes,c.getLong(7),plans[id].orEmpty(),entries[id].orEmpty()))
                    }
                }
                db.setTransactionSuccessful()
                return ReminderSnapshot(generation, habits, chinese)
            } finally { db.endTransaction() }
        }
    }
}
