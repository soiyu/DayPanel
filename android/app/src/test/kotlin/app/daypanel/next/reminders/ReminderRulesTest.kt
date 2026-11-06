package app.daypanel.next.reminders

import org.junit.Assert.*
import org.junit.Test
import java.time.*

class ReminderRulesTest {
    private fun habit(plans: List<Plan> = listOf(Plan(LocalDate.parse("2026-01-01"),1000,"weekdays",127,1,3)),
        entries: Map<LocalDate,Long> = emptyMap(), minutes: List<Int> = listOf(540,1200)) =
        ReminderHabit("h","Read","check",LocalDate.parse("2026-01-01"),false,true,minutes,0,plans,entries)
    @Test fun nextTimeUsesFutureSlotsOnly() {
        val now=ZonedDateTime.parse("2026-11-06T09:00:00+08:00[Asia/Shanghai]")
        assertEquals(1200,ReminderRules.next(habit(),now,emptySet(),0)!!.minute)
        val night=now.withHour(23)
        assertEquals(LocalDate.parse("2026-11-07"),ReminderRules.next(habit(),night,emptySet(),0)!!.day)
    }
    @Test fun archivedDisabledAndCompletedNeverRemindToday() {
        val day=LocalDate.parse("2026-11-06")
        assertFalse(ReminderRules.eligible(habit().copy(archived=true),day))
        assertFalse(ReminderRules.eligible(habit().copy(enabled=false),day))
        assertFalse(ReminderRules.eligible(habit(entries=mapOf(day to 1000)),day))
        assertTrue(ReminderRules.eligible(habit(entries=mapOf(day to 999)),day))
    }
    @Test fun planSwitchUsesNewDayAndIntervalAnchor() {
        val start=LocalDate.parse("2026-11-07")
        val h=habit(plans=listOf(Plan(start.minusDays(10),1000,"weekdays",127,1,3),Plan(start,2000,"interval",127,2,3)),entries=mapOf(start.minusDays(1) to 1000,start to 1000))
        assertFalse(ReminderRules.eligible(h,start.minusDays(1)))
        assertTrue(ReminderRules.eligible(h,start))
        assertFalse(ReminderRules.eligible(h,start.plusDays(1)))
        assertTrue(ReminderRules.eligible(h,start.plusDays(2)))
    }
    @Test fun weeklyTargetsResetMondayAndDoNotMixPlans() {
        val monday=LocalDate.parse("2026-11-02")
        val h=habit(plans=listOf(Plan(monday,1000,"weekly",127,1,2)),entries=mapOf(monday to 1000,monday.plusDays(2) to 1000))
        assertFalse(ReminderRules.eligible(h,monday.plusDays(4)))
        assertTrue(ReminderRules.eligible(h,monday.plusDays(7)))
        assertTrue(ReminderRules.eligible(h.copy(plans=h.plans+Plan(monday.plusDays(4),2000,"weekly",127,1,2)),monday.plusDays(4)))
    }
    @Test fun weekdayAndYearBoundaryAreCalendarBased() {
        val p=Plan(LocalDate.parse("2026-12-31"),1000,"interval",127,2,3)
        assertTrue(ReminderRules.eligible(habit(plans=listOf(p)),LocalDate.parse("2027-01-02")))
        val mondayOnly=habit(plans=listOf(p.copy(start=LocalDate.parse("2026-01-01"),schedule="weekdays",weekdays=1)))
        assertTrue(ReminderRules.eligible(mondayOnly,LocalDate.parse("2026-11-02")))
        assertFalse(ReminderRules.eligible(mondayOnly,LocalDate.parse("2026-11-03")))
    }
    @Test fun dstGapMovesForwardAndRepeatedHourDoesNotDoubleFire() {
        val gap=ZonedDateTime.of(2026,3,8,0,0,0,0,ZoneId.of("America/New_York"))
        val due=ReminderRules.next(habit(minutes=listOf(150)),gap,emptySet(),1)!!
        assertEquals(3,due.instant.atZone(gap.zone).hour)
        val fall=ZonedDateTime.of(2026,11,1,0,0,0,0,gap.zone)
        val h=habit(minutes=listOf(90))
        val first=ReminderRules.next(h,fall,emptySet(),1)!!
        val seen=setOf(ReminderRules.key("h",1,0,first.day,90))
        val repeat=fall.withHour(1).withMinute(10).withLaterOffsetAtOverlap()
        assertEquals(LocalDate.parse("2026-11-02"),ReminderRules.next(h,repeat,seen,1)!!.day)
    }
    @Test fun snoozeDoesNotSpillIntoNextDay() {
        val now=ZonedDateTime.parse("2026-11-06T23:55:00+08:00[Asia/Shanghai]")
        assertNull(ReminderRules.snooze(now,now.toLocalDate()))
        assertNull(ReminderRules.snooze(now,now.toLocalDate().minusDays(1)))
        assertEquals(now.withHour(12).plusMinutes(10).toInstant(),ReminderRules.snooze(now.withHour(12),now.toLocalDate()))
    }
    @Test fun timezoneChangeKeepsWallClockTime() {
        val h=habit(minutes=listOf(540))
        for(zone in listOf("Asia/Shanghai","America/Los_Angeles","Europe/London")) {
            val now=ZonedDateTime.of(2026,11,6,6,0,0,0,ZoneId.of(zone))
            assertEquals(9,ReminderRules.next(h,now,emptySet(),0)!!.instant.atZone(now.zone).hour)
        }
    }
}
