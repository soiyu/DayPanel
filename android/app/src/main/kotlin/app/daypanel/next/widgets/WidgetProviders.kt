package app.daypanel.next.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle

open class DayPanelWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) = refresh(context)
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) = refresh(context)
    override fun onDeleted(context: Context, ids: IntArray) {
        ids.forEach { WidgetBindings.remove(context, it) }
        refresh(context)
    }
    override fun onDisabled(context: Context) = refresh(context)
    override fun onRestored(context: Context, oldIds: IntArray, newIds: IntArray) {
        // Launcher restoration cannot transplant a binding to another widget ID.
        (oldIds + newIds).forEach { WidgetBindings.remove(context, it) }
        refresh(context)
    }
    private fun refresh(context: Context) {
        val pending = goAsync()
        WidgetEngine.worker.execute {
            try { WidgetEngine.refresh(context.applicationContext) } catch (_: Exception) { /* Retry on next update/open. */ }
            finally { pending.finish() }
        }
    }
}
class HabitWidgetProvider : DayPanelWidgetProvider()
class TaskWidgetProvider : DayPanelWidgetProvider()
class PanelWidgetProvider : DayPanelWidgetProvider()
class WidgetSystemReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        WidgetEngine.worker.execute {
            try { WidgetEngine.refresh(context.applicationContext) } catch (_: Exception) { /* Next system/app update retries. */ }
            finally { pending.finish() }
        }
    }
}
