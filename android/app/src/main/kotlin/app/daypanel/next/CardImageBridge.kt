package app.daypanel.next

import android.content.Intent
import android.content.ClipData
import android.graphics.BitmapFactory
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

object CardImageBridge {
    fun register(activity:MainActivity,engine:FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger,"app.daypanel.next/card-image").setMethodCallHandler { call,reply ->
            if(call.method!="share")reply.notImplemented()
            else try {
                val send=prepare(activity,call.argument<ByteArray>("bytes") ?: error("Missing image"))
                activity.startActivity(Intent.createChooser(send,null));reply.success(null)
            } catch(_:Exception){reply.error("image","Unable to open image sharing",null)}
        }
    }
    fun prepare(context:android.content.Context,bytes:ByteArray):Intent {
                require(bytes.size in 8..(8*1024*1024))
                require(bytes.copyOfRange(0,8).contentEquals(byteArrayOf(-119,80,78,71,13,10,26,10)))
                val bounds=BitmapFactory.Options().apply{inJustDecodeBounds=true};BitmapFactory.decodeByteArray(bytes,0,bytes.size,bounds)
                require(bounds.outWidth in 1..4096&&bounds.outHeight in 1..16000)
                val root=File(context.cacheDir,"shared-cards").apply{mkdirs()}
                root.listFiles()?.filter{System.currentTimeMillis()-it.lastModified()>86400000}?.forEach{it.delete()}
                val file=File.createTempFile("DayPanel-",".png",root);file.writeBytes(bytes)
                val uri=FileProvider.getUriForFile(context,"${context.packageName}.card-images",file)
                val send=Intent(Intent.ACTION_SEND).apply{
                    type="image/png";putExtra(Intent.EXTRA_STREAM,uri)
                    clipData=ClipData.newUri(context.contentResolver,"DayPanel",uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
        return send
    }

}
