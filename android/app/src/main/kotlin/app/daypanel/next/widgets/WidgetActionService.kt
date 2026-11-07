package app.daypanel.next.widgets

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.app.job.JobWorkItem
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.Bundle
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.concurrent.Executors

internal fun widgetRequest(encoded:String):Map<String,Any?> {
    val json=JSONObject(encoded)
    return json.keys().asSequence().associateWith { json.opt(it).takeUnless { v -> v==JSONObject.NULL } }
}

/** Receiver queues explicit targets; it never opens an Activity or writes SQLite. */
class WidgetActionReceiver:BroadcastReceiver() {
    override fun onReceive(context:Context,intent:Intent) {
        val pending=goAsync()
        WidgetEngine.worker.execute {
            val encoded=intent.getStringExtra("widget")
            try {
                val request=widgetRequest(encoded ?: error("Missing action"))
                val id=(request["widgetId"] as Number).toInt()
                if(!WidgetBindings.valid(context,request)) {
                    WidgetActionStatus.set(context,id,"stale")
                } else {
                    val builder=JobInfo.Builder(1617,ComponentName(context,WidgetActionService::class.java))
                    if(android.os.Build.VERSION.SDK_INT>=31) builder.setExpedited(true) else builder.setOverrideDeadline(0)
                    val scheduler=context.getSystemService(JobScheduler::class.java)
                    var queued=scheduler.enqueue(builder.build(),JobWorkItem(Intent().putExtra("widget",encoded)))
                    if(queued!=JobScheduler.RESULT_SUCCESS && android.os.Build.VERSION.SDK_INT>=31) {
                        queued=scheduler.enqueue(builder.setExpedited(false).setOverrideDeadline(0).build(),JobWorkItem(Intent().putExtra("widget",encoded)))
                    }
                    WidgetActionStatus.set(context,id,if(queued==JobScheduler.RESULT_SUCCESS) "pending" else "failed")
                }
                WidgetEngine.refresh(context)
            } catch(_:Exception) { /* Invalid external inputs cannot start a writer. */ }
            finally {pending.finish()}
        }
    }
}

/** Main-process-only transient UI status, never part of a file backup. */
object WidgetActionStatus {
    fun set(c:Context,id:Int,status:String) {
        c.getSharedPreferences("widget_action_status",0).edit()
            .putString(id.toString(),status).putLong("$id-at",System.currentTimeMillis()).commit()
    }
    fun get(c:Context,id:Int):String? {
        val p=c.getSharedPreferences("widget_action_status",0)
        val age=System.currentTimeMillis()-p.getLong("$id-at",0)
        return if(age in 0..30000) p.getString(id.toString(),null) else null
    }
}

/** Separate process, same Dart storage rules. No UI, notification or native data writer. */
class WidgetActionService:JobService() {
    private val main=Handler(Looper.getMainLooper())
    private val io=Executors.newSingleThreadExecutor()
    private var engine:FlutterEngine?=null
    private var channel:MethodChannel?=null
    private var active:JobParameters?=null
    private var work:JobWorkItem?=null
    private val timeout=Runnable { finish(true) }
    override fun onStartJob(params:JobParameters):Boolean {
        if(active!=null) return true
        active=params
        main.postDelayed(timeout,120000)
        val loader=FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationCompleteAsync(applicationContext,null,main) {
            if(active!==params) return@ensureInitializationCompleteAsync
            try {
                val flutter=FlutterEngine(applicationContext)
                engine=flutter
                channel=MethodChannel(flutter.dartExecutor.binaryMessenger,"app.daypanel.next/widget-actions").also { bridge ->
                    bridge.setMethodCallHandler { call,reply ->
                        when(call.method) {
                            "ready" -> {reply.success(null);next()}
                            "binding" -> io.execute {
                                val valid=try {WidgetBindings.matches(this,call.arguments as? Map<*,*> ?: emptyMap<Any,Any>())}catch(_:Exception){false}
                                main.post {reply.success(valid)}
                            }
                            else -> reply.notImplemented()
                        }
                    }
                }
                flutter.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(loader.findAppBundlePath(),
                    "package:daypanel/application/widget_action_runner.dart","widgetActionMain"))
            }catch(_:Exception){finish(true)}
        }
        return true
    }
    private fun next() {
        val params=active ?: return
        val current=params.dequeueWork()
        if(current==null){finish(false);return}
        work=current
        val request=try {widgetRequest(current.intent.getStringExtra("widget")!!)}catch(_:Exception){
            params.completeWork(current);work=null;next();return
        }
        io.execute {
            val valid=try {WidgetBindings.valid(this,request)}catch(_:Exception){false}
            main.post {
                if(active!==params) return@post
                if(!valid){complete("stale",request);return@post}
                channel?.invokeMethod("execute",request,object:MethodChannel.Result {
                    override fun success(result:Any?) {complete(result as? String ?: "failed",request)}
                    override fun error(code:String,message:String?,details:Any?) {complete("failed",request)}
                    override fun notImplemented(){complete("failed",request)}
                })
            }
        }
    }
    private fun complete(status:String,request:Map<String,Any?>) {
        val params=active ?: return
        val current=work ?: return
        // Sync even on rejected/redelivered actions: a previous process may have
        // committed before it died. The revision prevents writing that commit twice.
        io.execute {
            var synced=true
            try {
                contentResolver.call(Uri.parse("content://$packageName.widget-bindings"),"actionFinished",null,
                    Bundle().apply {putInt("widgetId",(request["widgetId"] as Number).toInt());putString("status",status)})
            }catch(_:Exception){synced=false}
            main.post {
                if(active!==params) return@post
                if(!synced){finish(true);return@post}
                params.completeWork(current);work=null;next()
            }
        }
    }
    private fun finish(retry:Boolean) {
        val params=active ?: return
        active=null;work=null;main.removeCallbacks(timeout)
        channel?.setMethodCallHandler(null);channel=null;engine?.destroy();engine=null
        jobFinished(params,retry)
    }
    override fun onStopJob(params:JobParameters):Boolean {
        active=null;work=null;main.removeCallbacks(timeout)
        channel?.setMethodCallHandler(null);channel=null;engine?.destroy();engine=null
        return true
    }
    override fun onDestroy(){main.removeCallbacks(timeout);engine?.destroy();io.shutdown();super.onDestroy()}
}
