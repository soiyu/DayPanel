package app.daypanel.next.reminders

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import app.daypanel.next.MainActivity
import app.daypanel.next.R
import org.json.JSONArray
import org.json.JSONObject
import java.time.*
import java.util.UUID
import java.util.concurrent.Executors

data class AlarmEvent(val id: String, val day: LocalDate, val minute: Int, val at: Long,
    val generation: Long, val revision: Long, val token: String, val snoozed: Boolean = false) {
    fun json() = JSONObject().put("id",id).put("day",day.toString()).put("minute",minute).put("at",at)
        .put("generation",generation).put("revision",revision).put("token",token).put("snoozed",snoozed)
    companion object {
        fun from(j: JSONObject) = AlarmEvent(j.getString("id"),LocalDate.parse(j.getString("day")),j.getInt("minute"),j.getLong("at"),
            j.getLong("generation"),j.getLong("revision"),j.getString("token"),j.optBoolean("snoozed"))
    }
}

object ReminderEngine {
    val worker = Executors.newSingleThreadExecutor()
    const val CHANNEL = "habit_reminders_v1"
    const val FIRE = "app.daypanel.next.REMINDER_FIRE"
    const val SNOOZE = "app.daypanel.next.REMINDER_SNOOZE"
    const val OPEN = "app.daypanel.next.REMINDER_OPEN"
    private fun prefs(c: Context) = c.getSharedPreferences("reminder_runtime",Context.MODE_PRIVATE)
    private fun manager(c: Context) = c.getSystemService(NotificationManager::class.java)
    private fun alarms(c: Context) = c.getSystemService(AlarmManager::class.java)
    private fun readMap(c: Context, name: String): MutableMap<String,AlarmEvent> = try {
        val j = JSONObject(prefs(c).getString(name,"{}")!!)
        j.keys().asSequence().associateWith { AlarmEvent.from(j.getJSONObject(it)) }.toMutableMap()
    } catch (_: Exception) { mutableMapOf() }
    private fun saveMap(c: Context, name: String, map: Map<String,AlarmEvent>) {
        val j = JSONObject(); map.forEach { (id,e) -> j.put(id,e.json()) }
        check(prefs(c).edit().putString(name,j.toString()).commit())
    }

    fun ensureChannel(c: Context) {
        val zh = c.resources.configuration.locales[0].language == "zh"
        manager(c).createNotificationChannel(NotificationChannel(CHANNEL,if (zh) "习惯提醒" else "Habit reminders",NotificationManager.IMPORTANCE_DEFAULT).apply {
            description = if (zh) "按你设置的时刻提醒尚未完成的习惯" else "Reminders for your unfinished habits"
            enableVibration(true)
        })
    }
    fun status(c: Context): Map<String,Any> {
        ensureChannel(c)
        val permitted = Build.VERSION.SDK_INT < 33 || c.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)==PackageManager.PERMISSION_GRANTED
        return mapOf("notifications" to (permitted && manager(c).areNotificationsEnabled() && manager(c).getNotificationChannel(CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE),
            "exact" to (Build.VERSION.SDK_INT < 31 || alarms(c).canScheduleExactAlarms()), "pending" to readMap(c,"scheduled").size)
    }
    private fun intent(c: Context, e: AlarmEvent, action: String) = Intent(c,ReminderReceiver::class.java).apply {
        this.action = action
        data = Uri.Builder().scheme("daypanel-reminder").authority(action).appendPath(e.id).build()
        putExtra("event",e.json().toString())
    }
    private fun alarmIntent(c: Context,e: AlarmEvent) = PendingIntent.getBroadcast(c,0,intent(c,e,FIRE),PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    private fun cancelAlarm(c: Context,e: AlarmEvent) { alarms(c).cancel(alarmIntent(c,e)) }
    private fun schedule(c: Context,e: AlarmEvent) {
        val alarm = alarms(c); val pi = alarmIntent(c,e)
        try {
            if (Build.VERSION.SDK_INT < 31 || alarm.canScheduleExactAlarms()) alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,e.at,pi)
            else alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,e.at,pi)
        } catch (_: SecurityException) { alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,e.at,pi) }
    }
    private fun valid(e: AlarmEvent,s: ReminderSnapshot,now: ZonedDateTime): Boolean {
        val h = s.habits.firstOrNull { it.id==e.id } ?: return false
        return e.generation==s.generation && e.revision==h.revision && e.minute in h.minutes && ReminderRules.eligible(h,now.toLocalDate()) && e.day==now.toLocalDate()
    }
    private fun discardStale(c: Context,s: ReminderSnapshot,now: ZonedDateTime) {
        val notices = readMap(c,"notices")
        val stale = notices.filterValues { !valid(it,s,now) }.keys
        stale.forEach { manager(c).cancel(it,1); notices.remove(it) }
        saveMap(c,"notices",notices)
        if(prefs(c).getLong("generation",-1)!=s.generation) {
            readMap(c,"scheduled").values.forEach { cancelAlarm(c,it) }
            saveMap(c,"scheduled",emptyMap());saveMap(c,"snoozes",emptyMap())
            check(prefs(c).edit().putLong("generation",s.generation).putStringSet("delivered",emptySet()).commit())
        }
    }

    // All entry points run on worker. SQLite reads only, preferences are runtime
    // state; every delivery rechecks the authoritative user database.
    fun sync(c: Context, resetClock: Boolean = false) {
        ensureChannel(c)
        val snapshot = SnapshotReader.read(c) ?: return
        val now = ZonedDateTime.now()
        discardStale(c,snapshot,now)
        val previous = readMap(c,"scheduled")
        previous.values.forEach { cancelAlarm(c,it) }
        val allowed = status(c)["notifications"]==true
        if(!allowed) {
            readMap(c,"notices").keys.forEach { manager(c).cancel(it,1) }
            saveMap(c,"notices",emptyMap()); saveMap(c,"scheduled",emptyMap());saveMap(c,"snoozes",emptyMap())
            return
        }
        val delivered = prefs(c).getStringSet("delivered",emptySet())!!.filter { it.startsWith(now.toLocalDate().toString()+"|") }.toSet()
        check(prefs(c).edit().putStringSet("delivered",delivered).commit())
        val snoozes = if(resetClock) mutableMapOf() else readMap(c,"snoozes")
        snoozes.entries.removeAll { (_,e) -> !valid(e,snapshot,now) || e.at<=now.toInstant().toEpochMilli() }
        val scheduled=mutableMapOf<String,AlarmEvent>()
        for(h in snapshot.habits) {
            val due=ReminderRules.next(h,now,delivered,snapshot.generation)
            val normal=due?.let { AlarmEvent(h.id,it.day,it.minute,it.instant.toEpochMilli(),snapshot.generation,h.revision,UUID.randomUUID().toString()) }
            val snooze=snoozes[h.id]
            val next=if(snooze!=null&&(normal==null||snooze.at<normal.at))snooze else normal
            if(next!=null) scheduled[h.id]=next
        }
        saveMap(c,"snoozes",snoozes)
        // Save all tokens before registering any alarm, so a cold receiver can validate it.
        saveMap(c,"scheduled",scheduled)
        scheduled.values.forEach { schedule(c,it) }
    }

    fun receive(c: Context, action: String?, encoded: String?) {
        if(action!=FIRE && action!=SNOOZE) { sync(c,resetClock=true); return }
        val e = try { AlarmEvent.from(JSONObject(encoded!!)) } catch (_: Exception) { return }
        val s = SnapshotReader.read(c) ?: return
        val now = ZonedDateTime.now()
        if(action==SNOOZE) {
            val notices=readMap(c,"notices")
            if(notices[e.id]?.token!=e.token || !valid(e,s,now)) { sync(c); return }
            notices.remove(e.id);saveMap(c,"notices",notices);manager(c).cancel(e.id,1)
            val at=ReminderRules.snooze(now,e.day)
            if(at!=null) {
                val snoozes=readMap(c,"snoozes")
                snoozes[e.id]=e.copy(at=at.toEpochMilli(),token=UUID.randomUUID().toString(),snoozed=true)
                saveMap(c,"snoozes",snoozes)
            }
            sync(c);return
        }
        val scheduled=readMap(c,"scheduled")
        if(scheduled[e.id]?.token!=e.token) return
        if(now.toInstant().toEpochMilli()<e.at) { schedule(c,e);return }
        scheduled.remove(e.id);saveMap(c,"scheduled",scheduled)
        val seen=prefs(c).getStringSet("delivered",emptySet())!!.toMutableSet()
        val key=ReminderRules.key(e.id,e.generation,e.revision,e.day,e.minute)
        val canSend=valid(e,s,now) && now.toInstant().toEpochMilli()-e.at<=120*60*1000 && (e.snoozed || key !in seen) && status(c)["notifications"]==true
        seen.add(key);check(prefs(c).edit().putStringSet("delivered",seen).commit())
        val snoozes=readMap(c,"snoozes");snoozes.remove(e.id);saveMap(c,"snoozes",snoozes)
        if(canSend) {
            // Token is consumed by sync at the end; repeated broadcasts cannot post twice.
            post(c,e,s.habits.first { it.id==e.id },s.chinese)
            val notices=readMap(c,"notices");notices[e.id]=e;saveMap(c,"notices",notices)
        }
        sync(c)
    }
    private fun post(c: Context,e: AlarmEvent,h: ReminderHabit,zh: Boolean) {
        val open=Intent(c,MainActivity::class.java).apply {
            action=OPEN;data=Uri.Builder().scheme("daypanel-open").authority("habit").appendPath(e.id).appendPath(e.token).build()
            putExtra("reminder",e.json().toString()); flags=Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPi=PendingIntent.getActivity(c,0,open,PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val snoozePi=PendingIntent.getBroadcast(c,0,intent(c,e,SNOOZE).apply { data=data!!.buildUpon().appendPath(e.token).build() },PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val n=Notification.Builder(c,CHANNEL).setSmallIcon(R.drawable.ic_reminder).setContentTitle(h.title)
            .setContentText(if(zh) "给这件小事留一点时间。" else "A little time for your habit.")
            .setVisibility(Notification.VISIBILITY_PRIVATE).setAutoCancel(true).setContentIntent(openPi)
            .setCategory(Notification.CATEGORY_REMINDER).setOnlyAlertOnce(false)
            .setTimeoutAfter(Duration.between(ZonedDateTime.now(),e.day.plusDays(1).atStartOfDay(ZoneId.systemDefault())).toMillis().coerceAtLeast(1))
            .addAction(Notification.Action.Builder(null,if(zh) "去记录" else "Log habit",openPi).build())
        if(ReminderRules.snooze(ZonedDateTime.now(),e.day)!=null) n.addAction(Notification.Action.Builder(null,if(zh) "10分钟后" else "In 10 minutes",snoozePi).build())
        try { manager(c).notify(e.id,1,n.build()) } catch (_: SecurityException) { /* revoked between check and post */ }
    }
    fun openRequest(c: Context, encoded: String?): Map<String,Any>? {
        val e=try{AlarmEvent.from(JSONObject(encoded!!))}catch(_:Exception){return null}
        val snapshot=SnapshotReader.read(c)?:return null
        if(!valid(e,snapshot,ZonedDateTime.now())||readMap(c,"notices")[e.id]?.token!=e.token)return null
        manager(c).cancel(e.id,1)
        val notices=readMap(c,"notices");notices.remove(e.id);saveMap(c,"notices",notices)
        return mapOf("id" to e.id,"day" to e.day.toString(),"generation" to e.generation)
    }
}
