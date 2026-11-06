package app.daypanel.next.widgets

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.Bundle

/** Single process owner for device-local configuration. No multi-process preference caches. */
class WidgetBindingProvider : ContentProvider() {
    override fun onCreate() = true
    override fun call(method: String, arg: String?, extras: Bundle?): Bundle {
        val c = requireNotNull(context)
        require(android.os.Binder.getCallingUid() == c.applicationInfo.uid)
        val prefs = c.getSharedPreferences("daypanel_widgets", 0)
        return Bundle().apply {
            when (method) {
                "syncReminders" -> {
                    val status = app.daypanel.next.reminders.ReminderEngine.worker.submit<Map<String, Any>> {
                        app.daypanel.next.reminders.ReminderEngine.sync(c)
                        app.daypanel.next.reminders.ReminderEngine.status(c)
                    }.get()
                    putBoolean("notifications", status["notifications"] == true)
                    putBoolean("exact", status["exact"] == true)
                    putInt("pending", (status["pending"] as? Number)?.toInt() ?: 0)
                }
                "refresh" -> WidgetEngine.worker.submit { WidgetEngine.refresh(c) }.get()
                "get" -> putString("value", prefs.getString(requireNotNull(arg), null))
                "put" -> check(prefs.edit().putString(requireNotNull(arg), requireNotNull(extras?.getString("value"))).commit())
                "remove" -> check(prefs.edit().remove(requireNotNull(arg)).commit())
                "keys" -> putStringArrayList("keys", ArrayList(prefs.all.keys))
                else -> error("Unknown operation")
            }
        }
    }
    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = 0
}
