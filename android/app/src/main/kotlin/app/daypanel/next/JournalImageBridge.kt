package app.daypanel.next

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import java.util.concurrent.Executors

class JournalImageBridge(private val activity: Activity, engine: FlutterEngine) {
    companion object {
        const val REQUEST_CODE_PICK_IMAGES = 4301
    }

    private var pendingPick: MethodChannel.Result? = null
    private var maxItems = 9
    private val worker = Executors.newSingleThreadExecutor()
    private val imageDir = File(activity.filesDir, "note_images").apply { mkdirs() }

    init {
        MethodChannel(engine.dartExecutor.binaryMessenger, "app.daypanel.next/note-images")
            .setMethodCallHandler { call, reply ->
                when (call.method) {
                    "pick" -> {
                        if (pendingPick != null) {
                            reply.error("busy", "Image picker is already active", null)
                            return@setMethodCallHandler
                        }
                        maxItems = (call.argument<Int>("max") ?: 9).coerceIn(1, 9)
                        pendingPick = reply
                        try {
                            val intent = if (Build.VERSION.SDK_INT >= 33) {
                                Intent(MediaStore.ACTION_PICK_IMAGES).apply {
                                    type = "image/*"
                                    if (maxItems > 1) {
                                        putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, maxItems)
                                    }
                                }
                            } else {
                                Intent(Intent.ACTION_GET_CONTENT).apply {
                                    type = "image/*"
                                    addCategory(Intent.CATEGORY_OPENABLE)
                                    if (maxItems > 1) {
                                        putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                                    }
                                }
                            }
                            activity.startActivityForResult(intent, REQUEST_CODE_PICK_IMAGES)
                        } catch (_: Exception) {
                            pendingPick = null
                            reply.error("unavailable", "Photo picker unavailable", null)
                        }
                    }
                    "getPath" -> {
                        val name = call.argument<String>("name")
                        if (name.isNullOrBlank()) {
                            reply.success(null)
                        } else {
                            val file = File(imageDir, name)
                            reply.success(if (file.exists()) file.absolutePath else null)
                        }
                    }
                    "delete" -> {
                        val name = call.argument<String>("name")
                        if (!name.isNullOrBlank()) {
                            try {
                                val file = File(imageDir, name)
                                if (file.exists()) file.delete()
                            } catch (_: Exception) {}
                        }
                        reply.success(null)
                    }
                    else -> reply.notImplemented()
                }
            }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_PICK_IMAGES) return false
        val reply = pendingPick ?: return true
        pendingPick = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            reply.success(emptyList<String>())
            return true
        }

        val uris = mutableListOf<Uri>()
        val clip = data.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) {
                if (uris.size >= maxItems) break
                uris.add(clip.getItemAt(i).uri)
            }
        } else if (data.data != null) {
            uris.add(data.data!!)
        }

        if (uris.isEmpty()) {
            reply.success(emptyList<String>())
            return true
        }

        worker.execute {
            val savedNames = mutableListOf<String>()
            for (uri in uris) {
                try {
                    val fileName = processAndSaveImage(uri)
                    if (fileName != null) savedNames.add(fileName)
                } catch (_: Exception) {}
            }
            activity.runOnUiThread {
                reply.success(savedNames)
            }
        }
        return true
    }

    private fun processAndSaveImage(uri: Uri): String? {
        val resolver = activity.contentResolver
        val boundsOpts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        resolver.openInputStream(uri)?.use { stream ->
            BitmapFactory.decodeStream(stream, null, boundsOpts)
        } ?: return null

        val w = boundsOpts.outWidth
        val h = boundsOpts.outHeight
        if (w <= 0 || h <= 0) return null

        val maxDim = 1600
        var inSampleSize = 1
        val maxSide = maxOf(w, h)
        while (maxSide / inSampleSize > maxDim) {
            inSampleSize *= 2
        }

        val decodeOpts = BitmapFactory.Options().apply {
            this.inSampleSize = inSampleSize
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        val decoded = resolver.openInputStream(uri)?.use { stream ->
            BitmapFactory.decodeStream(stream, null, decodeOpts)
        } ?: return null

        var rotation = 0f
        if (Build.VERSION.SDK_INT >= 24) {
            try {
                resolver.openInputStream(uri)?.use { stream ->
                    val exif = ExifInterface(stream)
                    val orient = exif.getAttributeInt(
                        ExifInterface.TAG_ORIENTATION,
                        ExifInterface.ORIENTATION_NORMAL
                    )
                    rotation = when (orient) {
                        ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                        ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                        ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                        else -> 0f
                    }
                }
            } catch (_: Exception) {}
        }

        val finalBitmap = if (rotation != 0f) {
            val matrix = Matrix().apply { postRotate(rotation) }
            val rotated = Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, matrix, true)
            if (rotated != decoded) decoded.recycle()
            rotated
        } else {
            decoded
        }

        val fileName = "${UUID.randomUUID()}.jpg"
        val destFile = File(imageDir, fileName)
        FileOutputStream(destFile).use { fos ->
            finalBitmap.compress(Bitmap.CompressFormat.JPEG, 85, fos)
        }
        finalBitmap.recycle()
        return fileName
    }

    fun release() {
        pendingPick?.error("closed", "Activity destroyed", null)
        pendingPick = null
        worker.shutdown()
    }
}
