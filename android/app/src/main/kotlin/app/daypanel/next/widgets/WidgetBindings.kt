package app.daypanel.next.widgets

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.net.Uri
import android.os.Bundle
import org.json.JSONObject
import java.util.UUID

/** Device-local bindings, never part of file backup or Launcher restore. */
data class WidgetBinding(val widgetId: Int, val kind: String, val id: String, val generation: Long, val token: String) {
    fun json() = JSONObject().put("widgetId", widgetId).put("kind", kind).put("id", id).put("generation", generation).put("token", token)
}
object WidgetBindings {
    private fun call(c: Context, method: String, key: String? = null, value: String? = null): Bundle =
        requireNotNull(c.contentResolver.call(Uri.parse("content://${c.packageName}.widget-bindings"), method, key,
            value?.let { Bundle().apply { putString("value", it) } }))
    fun kind(c: Context, widgetId: Int): String? = when (AppWidgetManager.getInstance(c).getAppWidgetInfo(widgetId)?.provider?.className) {
        HabitWidgetProvider::class.java.name -> "habit"
        TaskWidgetProvider::class.java.name -> "task"
        else -> null
    }
    fun ids(c: Context): IntArray {
        val manager = AppWidgetManager.getInstance(c)
        return manager.getAppWidgetIds(ComponentName(c, HabitWidgetProvider::class.java)) +
            manager.getAppWidgetIds(ComponentName(c, TaskWidgetProvider::class.java))
    }
    fun get(c: Context, widgetId: Int): WidgetBinding? = try {
        val j = JSONObject(call(c, "get", widgetId.toString()).getString("value") ?: return null)
        WidgetBinding(widgetId, j.getString("kind"), j.getString("id"), j.getLong("generation"), j.getString("token"))
    } catch (_: Exception) { null }
    fun save(c: Context, widgetId: Int, id: String, generation: Long) {
        val kind = kind(c, widgetId) ?: error("Widget no longer exists")
        val snapshot = WidgetSnapshotReader.read(c) ?: error("Data unavailable")
        require(snapshot.generation == generation)
        require(snapshot.items["$kind:$id"]?.archived == false)
        val binding = WidgetBinding(widgetId, kind, id, generation, UUID.randomUUID().toString())
        call(c, "put", widgetId.toString(), binding.json().toString())
    }
    fun remove(c: Context, id: Int) { call(c, "remove", id.toString()) }
    fun prune(c: Context) {
        val live = ids(c).map { it.toString() }.toSet()
        call(c, "keys").getStringArrayList("keys").orEmpty().filter { it !in live }.forEach {
            call(c, "remove", it)
        }
    }
    fun matches(c: Context, request: Map<*, *>): Boolean {
        val widgetId = (request["widgetId"] as? Number)?.toInt() ?: return false
        val binding = get(c, widgetId) ?: return false
        if (kind(c, widgetId) != binding.kind || binding.kind != request["kind"] || binding.id != request["id"] ||
            binding.token != request["token"] || binding.generation != (request["generation"] as? Number)?.toLong()) return false
        return true
    }
    fun valid(c: Context, request: Map<*, *>): Boolean {
        if (!matches(c,request)) return false
        val widgetId=(request["widgetId"] as Number).toInt()
        val binding=get(c,widgetId) ?: return false
        val snapshot = WidgetSnapshotReader.read(c) ?: return false
        if (snapshot.generation != binding.generation || snapshot.day.toString() != request["day"]) return false
        val item = snapshot.items["${binding.kind}:${binding.id}"] ?: return false
        return when(request["mode"]) {
            "view" -> true
            "complete" -> false // Pre-v10 Activity shortcuts have no revision guard.
            "set" -> snapshot.revision >= 0 && !item.archived && item.rest == null && !item.quantity &&
                request["completed"] is Boolean && (request["revision"] as? Number)?.toLong() == snapshot.revision &&
                (if(item.kind=="habit") (request["expectedValue"] as? Number)?.toLong() == item.value else request["expectedValue"] == item.doneDay)
            "quantity" -> !item.archived && item.rest == null && item.quantity
            else -> false
        }
    }
}
