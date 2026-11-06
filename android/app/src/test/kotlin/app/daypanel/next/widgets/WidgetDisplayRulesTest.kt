package app.daypanel.next.widgets
import java.time.LocalDate
import org.junit.Test
import org.junit.Assert.*
class WidgetDisplayRulesTest {
    private val day=LocalDate.of(2026,11,6)
    @Test fun weeklyIsFlexibleAndWeekdayUsesLocalDate() {
        assertTrue(WidgetDisplayRules.scheduled(day,day,"weekly",1,1))
        assertFalse(WidgetDisplayRules.scheduled(day,day,"weekdays",1,1))
        assertTrue(WidgetDisplayRules.scheduled(day,day,"weekdays",16,1))
        assertFalse(WidgetDisplayRules.scheduled(day,day.plusDays(1),"weekly",127,1))
    }
    @Test fun intervalsUseCalendarDaysAcrossLeapDay() {
        val leap=LocalDate.of(2024,2,28)
        assertTrue(WidgetDisplayRules.scheduled(leap.plusDays(2),leap,"interval",127,2))
        assertFalse(WidgetDisplayRules.scheduled(leap.plusDays(1),leap,"interval",127,2))
    }
    @Test fun quantityDoesNotRoundOrUseFloatingPoint() {
        assertEquals("250.001",WidgetDisplayRules.quantity(250001))
        assertEquals("0",WidgetDisplayRules.quantity(0))
        assertEquals("999999999.999",WidgetDisplayRules.quantity(999999999999))
    }
}
