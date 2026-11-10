package app.daypanel.next.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import org.json.JSONObject
import java.util.UUID

/** Request identities are one-shot configuration capabilities, never record-click IDs. */
object WidgetPin {
    private const val STORE = "widget_pin_requests"
    private const val MAX_AGE = 24 * 60 * 60 * 1000L
    fun supported(c: Context): Boolean = Build.VERSION.SDK_INT >= 26 && AppWidgetManager.getInstance(c).isRequestPinAppWidgetSupported

    fun request(c: Context, kind: String, id: String, generation: Long): Boolean {
        if (!supported(c)) return false
        require(kind in listOf("habit","task","panel"))
        val snapshot = WidgetSnapshotReader.read(c) ?: error("Data unavailable")
        require(snapshot.generation==generation)
        if(kind=="panel"){
            require(app.daypanel.next.PlusReceipt.owned(c))
            val rows=PanelWidgets.rows(id);require(rows.size in 1..4 && rows.distinct().size==rows.size && rows.all { snapshot.items["${it.first}:${it.second}"]?.archived==false })
        }else require(snapshot.items["$kind:$id"]?.archived==false)
        val prefs = c.getSharedPreferences(STORE, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        val edit = prefs.edit()
        prefs.all.forEach { (key, value) ->
            val created = try { JSONObject(value as String).getLong("created") } catch (_: Exception) { 0L }
            if (created > now || now - created > MAX_AGE) edit.remove(key)
        }
        val token = UUID.randomUUID().toString()
        edit.putString(token, JSONObject().put("kind", kind).put("id", id).put("generation", generation).put("created", now).toString()).commit()
        val callback = Intent(c, WidgetPinReceiver::class.java).apply {
            action = "${c.packageName}.PIN_WIDGET"
            data = Uri.parse("daypanel-pin://request/$token")
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0)
        val pending = PendingIntent.getBroadcast(c, 0, callback, flags)
        val provider = ComponentName(c, when(kind){"panel"->PanelWidgetProvider::class.java;"habit"->HabitWidgetProvider::class.java;else->TaskWidgetProvider::class.java})
        return try {
            AppWidgetManager.getInstance(c).requestPinAppWidget(provider, null, pending).also {
                if (!it) { prefs.edit().remove(token).commit(); pending.cancel() }
            }
        } catch (e: Exception) { prefs.edit().remove(token).commit(); pending.cancel(); throw e }
    }

    fun accept(c: Context, intent: Intent): Boolean {
        if (intent.action != "${c.packageName}.PIN_WIDGET") return false
        val token = intent.data?.takeIf { it.scheme == "daypanel-pin" && it.host == "request" }?.lastPathSegment ?: return false
        val prefs = c.getSharedPreferences(STORE, Context.MODE_PRIVATE)
        val raw = prefs.getString(token, null) ?: return false
        val record = try { JSONObject(raw) } catch (_: Exception) { return false }
        val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        val kind = record.getString("kind")
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID || WidgetBindings.kind(c, widgetId) != kind) return false
        // Consume only a real matching Launcher instance. Late callbacks cannot bind restored data.
        prefs.edit().remove(token).commit()
        val now = System.currentTimeMillis()
        val created = record.getLong("created")
        if (created > now || now - created > MAX_AGE) return false
        val snapshot = WidgetSnapshotReader.read(c) ?: return false
        val id = record.getString("id")
        val generation = record.getLong("generation")
        if (snapshot.generation != generation || (kind!="panel" && snapshot.items["$kind:$id"]?.archived != false)) return false
        WidgetBindings.save(c, widgetId, id, generation)
        WidgetEngine.refresh(c)
        return true
    }
}

class WidgetPinReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        WidgetEngine.worker.execute {
            try { WidgetPin.accept(context, intent) } catch (_: Exception) { /* Launcher keeps the unconfigured widget. */ }
            finally { pending.finish() }
        }
    }
}
