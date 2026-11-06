package app.daypanel.next

import android.view.View
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class CompletionFeedbackDeviceTest {
    @Test fun disabledFeedbackNeverStartsSoundOrHaptics() {
        val c = InstrumentationRegistry.getInstrumentation().targetContext
        val feedback = CompletionFeedback(c)
        try {
            assertEquals(mapOf("sound" to false, "haptics" to false), feedback.play(View(c), false, false))
        } finally { feedback.release() }
    }
    @Test fun originalSoundIsBundledAsShortPcmWave() {
        val c = InstrumentationRegistry.getInstrumentation().targetContext
        val bytes = c.resources.openRawResource(R.raw.daypanel_complete).use { it.readBytes() }
        assertEquals("RIFF", String(bytes.copyOfRange(0,4)))
        assertEquals("WAVE", String(bytes.copyOfRange(8,12)))
        assertTrue(bytes.size in 8000..14000)
    }
}
