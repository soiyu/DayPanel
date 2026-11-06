package app.daypanel.next.widgets

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import app.daypanel.next.MainActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class WidgetActivity : MainActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(Activity.RESULT_CANCELED)
    }
    // A second tap returns to the already open, explicitly labelled form. It must
    // not replace its target or create another Flutter writer in this process.
    override fun onNewIntent(intent: Intent) { /* Keep the current flow until closed. */ }
}

class WidgetBridge(private val activity: MainActivity, engine: FlutterEngine) {
    init {
        MethodChannel(engine.dartExecutor.binaryMessenger, "app.daypanel.next/widgets").setMethodCallHandler { call, reply ->
            when (call.method) {
                "refresh" -> work(reply) { refresh(); null }
                "launch" -> work(reply) { launch() }
                "validate" -> work(reply) { WidgetBindings.valid(activity, call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()) }
                "configure" -> work(reply) {
                    check(activity is WidgetActivity)
                    val widgetId = call.argument<Int>("widgetId") ?: error("Missing widget")
                    require(widgetId == activity.intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1))
                    WidgetBindings.save(activity, widgetId, call.argument<String>("id") ?: error("Missing item"),
                        call.argument<Number>("generation")?.toLong() ?: error("Missing generation"))
                    refresh()
                    activity.runOnUiThread {
                        activity.setResult(Activity.RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
                    }
                    null
                }
                "close" -> { reply.success(null); if (activity is WidgetActivity) activity.finish() }
                "openApp" -> {
                    activity.startActivity(Intent(activity, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP))
                    reply.success(null)
                    if (activity is WidgetActivity) activity.finish()
                }
                else -> reply.notImplemented()
            }
        }
    }
    private fun refresh() {
        if (activity is WidgetActivity) activity.contentResolver.call(
            android.net.Uri.parse("content://${activity.packageName}.widget-bindings"), "refresh", null, null)
        else WidgetEngine.refresh(activity)
    }
    private fun launch(): Map<String, Any?>? {
        if (activity !is WidgetActivity) return null
        val id = activity.intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        val kind = WidgetBindings.kind(activity, id)
        if (kind == null) return mapOf("mode" to "stale")
        val encoded = activity.intent.getStringExtra("widget")
        val request: MutableMap<String, Any?> = if (encoded != null) try {
            val j = JSONObject(encoded)
            j.keys().asSequence().associateWith { j.get(it) }.toMutableMap<String, Any?>()
        } catch (_: Exception) { mutableMapOf<String, Any?>("mode" to "stale") }
        else mutableMapOf<String, Any?>("mode" to "configure", "widgetId" to id)
        if (request["mode"] == "configure") {
            val binding = WidgetBindings.get(activity, id)
            request["kind"] = kind
            request["id"] = binding?.id
            request["generation"] = binding?.generation
        } else if (!WidgetBindings.valid(activity, request)) request["mode"] = "stale"
        return request
    }
    private fun work(reply: MethodChannel.Result, action: () -> Any?) {
        WidgetEngine.worker.execute {
            try { val result = action(); activity.runOnUiThread { reply.success(result) } }
            catch (_: Exception) { activity.runOnUiThread { reply.error("widgets", "Widget operation unavailable", null) } }
        }
    }
}
