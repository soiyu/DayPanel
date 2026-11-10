package app.daypanel.next

import android.app.Activity
import android.content.Intent
import android.provider.CalendarContract
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import app.daypanel.next.reminders.SnapshotReader
import app.daypanel.next.reminders.ReminderHabit
import java.time.ZonedDateTime

object CalendarBridge {
    fun next(h: ReminderHabit, minute: Int, now: ZonedDateTime): ZonedDateTime? {
        if (h.archived || minute !in 0..1439) return null
        for (offset in 0L..371L) {
            val day=now.toLocalDate().plusDays(offset)
            if(day < h.start || h.breaks.any { it.contains(day) }) continue
            val p=h.plans.lastOrNull { it.start<=day } ?: continue
            val scheduled=when(p.schedule) {
                "weekdays" -> p.weekdays and (1 shl(day.dayOfWeek.value-1)) != 0
                "interval" -> p.interval>0 && java.time.temporal.ChronoUnit.DAYS.between(p.start,day)%p.interval==0L
                "weekly","weeklyTotal" -> true // one explicitly chosen event, no daily obligation
                else -> false
            }
            val at=day.atTime(minute/60,minute%60).atZone(now.zone)
            if(scheduled && at>now) return at
        }
        return null
    }
    fun recurrence(h:ReminderHabit, at:ZonedDateTime):String? {
        val day=at.toLocalDate();val p=h.plans.lastOrNull{it.start<=day} ?: return null
        // Rest histories are not silently converted into an inaccurate repeating calendar.
        if(h.breaks.any{it.end==null || it.end>=day})return null
        val base=when(p.schedule){
            "weekdays" -> "FREQ=WEEKLY;BYDAY="+listOf("MO","TU","WE","TH","FR","SA","SU").filterIndexed{i,_->p.weekdays and (1 shl i)!=0}.joinToString(",")
            "interval" -> "FREQ=DAILY;INTERVAL=${p.interval}"
            else -> return null
        }
        val next=h.plans.firstOrNull{it.start>day}
        return if(next==null)base else base+";UNTIL="+next.start.atStartOfDay(at.zone).minusSeconds(1).withZoneSameInstant(java.time.ZoneOffset.UTC).format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'"))
    }
    fun register(activity:Activity, engine:FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger,"app.daypanel.next/calendar").setMethodCallHandler { call, reply ->
            if(call.method!="add") { reply.notImplemented();return@setMethodCallHandler }
            try {
                val snap=SnapshotReader.read(activity,includeUnconfigured=true) ?: error("Unavailable")
                val epoch=(call.argument<Number>("generation"))?.toLong()
                require(epoch==snap.generation)
                val h=snap.habits.first { it.id==call.argument<String>("id") }
                val minute=call.argument<Int>("minute") ?: error("Missing time")
                val at=next(h,minute,ZonedDateTime.now()) ?: error("No upcoming date")
                val intent=Intent(Intent.ACTION_INSERT,CalendarContract.Events.CONTENT_URI).apply {
                    putExtra(CalendarContract.Events.TITLE,h.title)
                    recurrence(h,at)?.let{putExtra(CalendarContract.Events.RRULE,it)}
                    putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME,at.toInstant().toEpochMilli())
                    putExtra(CalendarContract.EXTRA_EVENT_END_TIME,at.plusMinutes(10).toInstant().toEpochMilli())
                    putExtra(CalendarContract.Events.DESCRIPTION, if(snap.chinese) "来自 DayPanel 的独立日历副本，请在日历中确认保存；不会同步后续改动。" else "A separate DayPanel calendar copy. Review and save here; later changes are not synchronized.")
                }
                activity.startActivity(intent)
                reply.success(true) // handed to calendar; NOT an assertion that the event was saved
            } catch(_:Exception) { reply.error("unavailable","Calendar is unavailable or this reminder changed",null) }
        }
    }
}
