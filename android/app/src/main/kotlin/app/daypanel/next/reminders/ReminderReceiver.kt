package app.daypanel.next.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        ReminderEngine.worker.execute {
            try { ReminderEngine.receive(context.applicationContext,intent.action,intent.getStringExtra("event")) }
            catch (_: Exception) { android.util.Log.w("DayPanelReminders","Scheduling failed; next foreground sync will retry") }
            finally { pending.finish() }
        }
    }
}
