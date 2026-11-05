package app.daypanel.next

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.content.Intent
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private var exportBytes: ByteArray? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val limit = 8 * 1024 * 1024

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.daypanel.next/documents")
            .setMethodCallHandler { call, result ->
                if (call.method != "save" && call.method != "pick") {
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
                        try {
                            val intent = if (call.method == "save") {
                                Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                    type = "application/json"
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

    @Deprecated("Activity result compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 4101 && requestCode != 4102) return
        val reply = pending ?: return
        val bytes = exportBytes
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
