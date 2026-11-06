package app.daypanel.next

import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.View

class CompletionFeedback(private val context: Context) {
    private var loaded = false
    private val pool = SoundPool.Builder().setMaxStreams(1).setAudioAttributes(
        AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
    ).build()
    private val sound: Int
    init {
        pool.setOnLoadCompleteListener { _, _, status -> loaded = status == 0 }
        sound = pool.load(context, R.raw.daypanel_complete, 1)
    }
    fun play(view: View, soundEnabled: Boolean, hapticsEnabled: Boolean): Map<String, Boolean> {
        val audio = context.getSystemService(AudioManager::class.java)
        val notifications = context.getSystemService(NotificationManager::class.java)
        val played = soundEnabled && loaded && allowed(audio.ringerMode, notifications.currentInterruptionFilter, audio.getStreamVolume(AudioManager.STREAM_SYSTEM)) &&
            pool.play(sound, .45f, .45f, 1, 0, 1f) != 0
        val haptic = hapticsEnabled && view.performHapticFeedback(
            if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.CONFIRM else HapticFeedbackConstants.VIRTUAL_KEY
        )
        return mapOf("sound" to played, "haptics" to haptic)
    }
    fun release() { pool.release() }
    companion object {
        fun allowed(ringer: Int, interruption: Int, volume: Int) =
            ringer == AudioManager.RINGER_MODE_NORMAL && interruption == NotificationManager.INTERRUPTION_FILTER_ALL && volume > 0
    }
}
