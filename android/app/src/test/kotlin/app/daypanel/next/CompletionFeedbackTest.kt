package app.daypanel.next

import org.junit.Assert.*
import org.junit.Test

class CompletionFeedbackTest {
    @Test fun onlyNormalRingerAllInterruptionsAndAudibleSystemVolumeAllowSound() {
        assertTrue(CompletionFeedback.allowed(2, 1, 3))
        for (ringer in listOf(0, 1)) assertFalse(CompletionFeedback.allowed(ringer, 1, 3))
        for (filter in listOf(0, 2, 3, 4)) assertFalse(CompletionFeedback.allowed(2, filter, 3))
        assertFalse(CompletionFeedback.allowed(2, 1, 0))
    }
}
