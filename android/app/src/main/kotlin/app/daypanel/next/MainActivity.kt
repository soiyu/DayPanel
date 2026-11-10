package app.daypanel.next

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.content.Intent
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import android.Manifest
import android.os.Build
import android.provider.Settings
import android.net.Uri
import app.daypanel.next.reminders.ReminderEngine

open class MainActivity : FlutterActivity() {
    // Keep the main Dart owner alive across Activity recreation. sqflite's native
    // handles outlive a detached engine; destroying Dart mid-transaction could
    // strand a lock until process death. Widget flows explicitly close their store.
    companion object { private var mainEngine: FlutterEngine? = null }
    private var nativeReleased=false
    override fun provideFlutterEngine(context:android.content.Context):FlutterEngine? =
        if(this is app.daypanel.next.widgets.WidgetActivity)null else mainEngine
    override fun shouldDestroyEngineWithHost():Boolean = this is app.daypanel.next.widgets.WidgetActivity
    override fun cleanUpFlutterEngine(flutterEngine:FlutterEngine) {
        if(!nativeReleased) {
            nativeReleased=true
            plusBilling?.close();plusBilling=null
            dataReceiver?.let { unregisterReceiver(it) };dataReceiver=null;widgetChanges=null
            completionFeedback?.release();completionFeedback=null
            pending?.error("closed","Document activity closed",null);pending=null;exportBytes=null
            permissionReply?.error("closed","Permission activity closed",null);permissionReply=null
            for(name in listOf("widgets","reminders","documents","feedback","calendar","about","card-image"))
                MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"app.daypanel.next/$name").setMethodCallHandler(null)
            worker.shutdown()
        }
        super.cleanUpFlutterEngine(flutterEngine)
    }
    private var plusBilling: PlusBilling? = null
    private var pending: MethodChannel.Result? = null
    private var exportBytes: ByteArray? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val limit = 8 * 1024 * 1024
    private var reminderChannel: MethodChannel? = null
    private var permissionReply: MethodChannel.Result? = null
    private var pendingOpen: String? = null
    private var completionFeedback: CompletionFeedback? = null
    private var widgetChanges:MethodChannel? = null
    private var exportBackup = false
    private var dataReceiver:android.content.BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if(this !is app.daypanel.next.widgets.WidgetActivity)mainEngine=flutterEngine
        app.daypanel.next.widgets.WidgetBridge(this, flutterEngine)
        widgetChanges=MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"app.daypanel.next/widgets")
        dataReceiver=object:android.content.BroadcastReceiver() {
            override fun onReceive(context:android.content.Context,intent:Intent) { widgetChanges?.invokeMethod("dataChanged",null) }
        }.also {
            androidx.core.content.ContextCompat.registerReceiver(this,it,android.content.IntentFilter("app.daypanel.next.DATA_CHANGED"),androidx.core.content.ContextCompat.RECEIVER_NOT_EXPORTED)
        }
        plusBilling = PlusBilling(this,flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"app.daypanel.next/about").setMethodCallHandler { call,reply ->
            when(call.method){
                "info" -> reply.success(mapOf("version" to BuildConfig.VERSION_NAME,"code" to BuildConfig.VERSION_CODE,"debug" to BuildConfig.DEBUG,"privacy" to BuildConfig.PRIVACY_URL,"support" to BuildConfig.SUPPORT_EMAIL))
                "privacy" -> try { require(BuildConfig.PRIVACY_URL.startsWith("https://"));startActivity(Intent(Intent.ACTION_VIEW,Uri.parse(BuildConfig.PRIVACY_URL)));reply.success(null) } catch(_:Exception){reply.error("unavailable","Policy page unavailable",null)}
                "support" -> try { require(BuildConfig.SUPPORT_EMAIL.contains("@"));startActivity(Intent(Intent.ACTION_SENDTO,Uri.parse("mailto:"+BuildConfig.SUPPORT_EMAIL)).putExtra(Intent.EXTRA_SUBJECT,"DayPanel support"));reply.success(null) }catch(_:Exception){reply.error("unavailable","Email app unavailable",null)}
                else -> reply.notImplemented()
            }
        }
        CalendarBridge.register(this,flutterEngine)
        CardImageBridge.register(this,flutterEngine)
        completionFeedback = try { CompletionFeedback(this) } catch (_: Exception) { null }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.daypanel.next/feedback").setMethodCallHandler { call, reply ->
            if (call.method != "complete") reply.notImplemented()
            else try {
                reply.success(if (hasWindowFocus()) completionFeedback?.play(window.decorView, call.argument<Boolean>("sound") == true, call.argument<Boolean>("haptics") == true) ?: error("Feedback unavailable") else mapOf("sound" to false, "haptics" to false))
            } catch (_: Exception) { reply.error("feedback", "Feedback unavailable", null) }
        }
        pendingOpen = intent?.getStringExtra("reminder")
        reminderChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"app.daypanel.next/reminders").also { channel ->
            channel.setMethodCallHandler { call, reply ->
                when(call.method) {
                    "sync" -> reminderWork(reply) { syncReminderStatus() }
                    "permission" -> {
                        if(Build.VERSION.SDK_INT>=33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=android.content.pm.PackageManager.PERMISSION_GRANTED) {
                            if(permissionReply!=null) reply.error("busy","Permission request active",null)
                            else { permissionReply=reply; requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS),4201) }
                        } else reminderWork(reply) { syncReminderStatus() }
                    }
                    "settings" -> try {
                        val exact=call.argument<Boolean>("exact")==true
                        val target=if(exact&&Build.VERSION.SDK_INT>=31) Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,Uri.parse("package:$packageName"))
                            else Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE,packageName)
                        startActivity(target);reply.success(null)
                    } catch(_:Exception){reply.error("unavailable","Settings unavailable",null)}
                    "takeOpen" -> {
                        val encoded=pendingOpen;pendingOpen=null
                        intent?.removeExtra("reminder")
                        reminderWork(reply) { ReminderEngine.openRequest(this,encoded) }
                    }
                    else -> reply.notImplemented()
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.daypanel.next/documents")
            .setMethodCallHandler { call, result ->
                if (call.method == "lastExport") {
                    val prefs = getSharedPreferences("device_export_history", MODE_PRIVATE)
                    result.success(if (prefs.contains("last_export")) prefs.getLong("last_export", 0L) else null)
                } else if (call.method == "readLegacy") {
                    val bytes = call.argument<ByteArray>("bytes")
                    if(bytes == null || bytes.size > limit) result.error("legacy", "Unsupported or damaged legacy file", null)
                    else worker.execute {
                        try {
                            val decoded=app.daypanel.next.importing.LegacyDatabaseReader.read(this,bytes)
                            runOnUiThread { result.success(decoded) }
                        } catch (_: Exception) { runOnUiThread { result.error("legacy", "Unsupported or damaged legacy file", null) } }
                    }
                } else if (call.method != "save" && call.method != "pick") {
                    result.notImplemented()
                } else if (pending != null) {
                    result.error("busy", "A document request is already active", null)
                } else {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (call.method == "save" && (bytes == null || bytes.size > limit)) {
                        result.error("invalid", "Invalid document size", null)
                    } else {
                        pending = result
                        exportBytes = bytes
                        exportBackup = call.method == "save" && call.argument<String>("mime") !in listOf("image/png","text/csv")
                        try {
                            val intent = if (call.method == "save") {
                                Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                    type = when(call.argument<String>("mime")) { "image/png" -> "image/png"; "text/csv" -> "text/csv"; else -> "application/json" }
                                    addCategory(Intent.CATEGORY_OPENABLE)
                                    putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "DayPanel.json")
                                }
                            } else {
                                Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                    type = "*/*"
                                    addCategory(Intent.CATEGORY_OPENABLE)
                                }
                            }
                            startActivityForResult(intent, if (call.method == "save") 4101 else 4102)
                        } catch (_: Exception) {
                            pending = null
                            exportBytes = null
                            result.error("unavailable", "Document picker unavailable", null)
                        }
                    }
                }
            }
    }

    private fun syncReminderStatus(): Map<String, Any> {
        if (this !is app.daypanel.next.widgets.WidgetActivity) {
            ReminderEngine.sync(this)
            return ReminderEngine.status(this)
        }
        val result = requireNotNull(contentResolver.call(Uri.parse("content://$packageName.widget-bindings"), "syncReminders", null, null))
        return mapOf("notifications" to result.getBoolean("notifications"), "exact" to result.getBoolean("exact"), "pending" to result.getInt("pending"))
    }
    private fun reminderWork(reply: MethodChannel.Result, work: () -> Any?) {
        ReminderEngine.worker.execute {
            try { val value=work();runOnUiThread { reply.success(value) } }
            catch(_:Exception) { runOnUiThread { reply.error("schedule","Unable to update reminders",null) } }
        }
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if(intent.action==ReminderEngine.OPEN) {
            pendingOpen=intent.getStringExtra("reminder")
            reminderChannel?.invokeMethod("opened",null)
        }
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode,permissions,grantResults)
        if(requestCode==4201) {
            val reply=permissionReply;permissionReply=null
            if(reply!=null) reminderWork(reply) { syncReminderStatus() }
        }
    }

    @Deprecated("Activity result compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 4101 && requestCode != 4102) return
        val reply = pending ?: return
        val bytes = exportBytes
        val isBackup = exportBackup
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending = null
            exportBytes = null
            reply.success(if (requestCode == 4101) false else null)
            return
        }
        worker.execute {
            try {
                val output: Any = if (requestCode == 4101) {
                    requireNotNull(bytes)
                    contentResolver.openOutputStream(uri, "wt")?.use { stream ->
                        stream.write(bytes)
                        stream.flush()
                    } ?: error("Cannot open destination")
                    if (isBackup) getSharedPreferences("device_export_history", MODE_PRIVATE).edit().putLong("last_export", System.currentTimeMillis()).commit()
                    true
                } else {
                    contentResolver.openInputStream(uri)?.use { stream ->
                        val buffer = ByteArray(16 * 1024)
                        val result = ByteArrayOutputStream()
                        while (true) {
                            val count = stream.read(buffer)
                            if (count < 0) break
                            if (result.size() + count > limit) error("File exceeds limit")
                            result.write(buffer, 0, count)
                        }
                        result.toByteArray()
                    } ?: error("Cannot open source")
                }
                runOnUiThread {
                    pending = null
                    exportBytes = null
                    reply.success(output)
                }
            } catch (_: Exception) {
                runOnUiThread {
                    pending = null
                    exportBytes = null
                    reply.error("io", "Document operation failed", null)
                }
            }
        }
    }
}
