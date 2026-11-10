package app.daypanel.next

import app.daypanel.next.reminders.*
import org.junit.Assert.*
import org.junit.Test
import java.time.*

class PlusCalendarRulesTest {
 private val monday=LocalDate.parse("2026-11-09")
 private fun habit(schedule:String="weekdays",target:Long=1000,entries:Map<LocalDate,Long> = emptyMap()) = ReminderHabit("h","Read","quantity",monday,false,true,listOf(540),0,listOf(Plan(monday,target,schedule,1,2,3)),entries)
 @Test fun calendarIsNextFutureAppointmentAndNeverChangesCompletion(){
   val now=ZonedDateTime.parse("2026-11-09T10:00:00+08:00[Asia/Shanghai]")
   assertEquals(monday.plusDays(7),CalendarBridge.next(habit(),540,now)!!.toLocalDate())
   assertEquals(monday,CalendarBridge.next(habit(),660,now)!!.toLocalDate())
   assertNull(CalendarBridge.next(habit().copy(archived=true),660,now));assertNull(CalendarBridge.next(habit(),1440,now))
 }
 @Test fun intervalAndBreakCalendarRespectRealRules(){
   val now=ZonedDateTime.parse("2026-11-09T10:00:00+08:00[Asia/Shanghai]")
   val h=habit("interval").copy(breaks=listOf(RestPeriod(monday.plusDays(2),monday.plusDays(3),"vacation")))
   assertEquals(monday.plusDays(4),CalendarBridge.next(h,540,now)!!.toLocalDate())
 }
 @Test fun weeklyAmountStopsRemindersAtTotalAndResetsNextWeek(){
   val h=habit("weeklyTotal",10000,mapOf(monday to 4000,monday.plusDays(1) to 6000))
   assertTrue(ReminderRules.eligible(h,monday));assertFalse(ReminderRules.eligible(h,monday.plusDays(2)));assertTrue(ReminderRules.eligible(h,monday.plusDays(7)))
   val edited=h.copy(plans=h.plans+Plan(monday.plusDays(2),10000,"weeklyTotal",127,1,3))
   assertTrue(ReminderRules.eligible(edited,monday.plusDays(2)))
 }
 @Test fun weeklyCountsAreDifferentFromWeeklyDays(){
   val entries=mapOf(monday to 3000L)
   assertFalse(ReminderRules.eligible(habit("weeklyTotal",3000,entries).copy(kind="count"),monday.plusDays(1)))
   assertTrue(ReminderRules.eligible(habit("weekly",1000,entries).copy(kind="count"),monday.plusDays(1)))
 }
 @Test fun calendarRecurrenceNeverTurnsFlexibleWeeklyIntoDailyDuty(){
   val at=ZonedDateTime.parse("2026-11-09T11:00:00+08:00[Asia/Shanghai]")
   assertEquals("FREQ=WEEKLY;BYDAY=MO",CalendarBridge.recurrence(habit(),at))
   assertEquals("FREQ=DAILY;INTERVAL=2",CalendarBridge.recurrence(habit("interval"),at))
   assertNull(CalendarBridge.recurrence(habit("weeklyTotal"),at));assertNull(CalendarBridge.recurrence(habit("weekly"),at))
   assertNull(CalendarBridge.recurrence(habit().copy(breaks=listOf(RestPeriod(monday.plusDays(1),null,"pause"))),at))
 }
}
