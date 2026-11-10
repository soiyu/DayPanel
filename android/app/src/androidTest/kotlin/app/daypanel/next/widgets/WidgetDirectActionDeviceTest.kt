package app.daypanel.next.widgets

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.SystemClock
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.*
import org.junit.Assert.*
import java.time.LocalDate

/** Actual queued Flutter writer, in an explicitly disposable Android user only. */
class WidgetDirectActionDeviceTest {
    private val instrumentation=InstrumentationRegistry.getInstrumentation()
    private val c=instrumentation.targetContext
    private val host=AppWidgetHost(c,1618)
    private var widget=0
    private lateinit var db:SQLiteDatabase
    private val habit="__direct_widget_fixture__"
    private val day=LocalDate.now().toString()
    private fun shell(command:String):String=instrumentation.uiAutomation.executeShellCommand(command).use {
        java.io.FileInputStream(it.fileDescriptor).readBytes().toString(Charsets.UTF_8)
    }
    private fun awaitCondition(message:String,condition:()->Boolean) {
        val end=SystemClock.elapsedRealtime()+120000
        while(!condition() && SystemClock.elapsedRealtime()<end) SystemClock.sleep(100)
        assertTrue(message,condition())
    }
    // Test fixture writes may overlap the app's short snapshot transactions.
    // Retry one failed atomic SQLite statement, never a product action.
    private fun fixtureWrite(sql:String,args:Array<out Any?>?=null) {
        val until=android.os.SystemClock.elapsedRealtime()+120000
        while(true)try {
            if(args==null) db.execSQL(sql) else db.execSQL(sql,args)
            return
        }catch(e:android.database.sqlite.SQLiteDatabaseLockedException){
            if(android.os.SystemClock.elapsedRealtime()>=until)throw e
            android.os.SystemClock.sleep(100)
        }
    }
    @Before fun setup() {
        assertTrue("Only run in a temporary Android user",android.os.Process.myUid()/100000 != 0)
        val user=android.os.Process.myUid()/100000
        c.startActivity(Intent(c,app.daypanel.next.MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        awaitCondition("App must create/upgrade the real database") {
            if(!c.getDatabasePath("daypanel_flutter.db").exists()) false else try {
                SQLiteDatabase.openDatabase(c.getDatabasePath("daypanel_flutter.db").path,null,SQLiteDatabase.OPEN_READWRITE or SQLiteDatabase.ENABLE_WRITE_AHEAD_LOGGING).use { it.version==12 }
            }catch(_:Exception){false}
        }
        awaitCondition("Main Activity finishes launching before Home") { shell("dumpsys activity activities").lineSequence().filter{it.contains("ResumedActivity")}.any{it.contains("app.daypanel.next.MainActivity")} }
        c.startActivity(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        shell("appwidget grantbind --package ${c.packageName} --user $user")
        db=SQLiteDatabase.openDatabase(c.getDatabasePath("daypanel_flutter.db").path,null,SQLiteDatabase.OPEN_READWRITE or SQLiteDatabase.ENABLE_WRITE_AHEAD_LOGGING)
        fixtureWrite("PRAGMA foreign_keys=ON")
        fixtureWrite("DELETE FROM habits WHERE id=?",arrayOf(habit))
        fixtureWrite("INSERT INTO habits(id,title,kind,start_day,target,unit,weekdays,icon) VALUES(?,?,'check',?,1000,'',127,2)",arrayOf(habit,"Direct widget fixture",day))
        fixtureWrite("INSERT INTO plans(habit_id,effective_day,target,unit,schedule,weekdays,interval_days,weekly_goal) VALUES(?,?,1000,'','weekdays',127,1,3)",arrayOf(habit,day))
        fixtureWrite("INSERT INTO habit_activity(habit_id,day,archived) VALUES(?,?,0)",arrayOf(habit,day))
        widget=host.allocateAppWidgetId()
        assertTrue(AppWidgetManager.getInstance(c).bindAppWidgetIdIfAllowed(widget,ComponentName(c,HabitWidgetProvider::class.java)))
        val snap=WidgetSnapshotReader.read(c)!!
        WidgetBindings.save(c,widget,habit,snap.generation)
        c.startActivity(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        awaitCondition("Launcher is visible before executing widget actions") { shell("dumpsys activity activities").lineSequence().filter{it.contains("ResumedActivity")}.any{it.contains("launcher",true)} }
    }
    private fun value():Long?=db.rawQuery("SELECT value FROM entries WHERE habit_id=? AND day=?",arrayOf(habit,day)).use {if(it.moveToFirst())it.getLong(0)else null}
    private fun action():android.app.PendingIntent {
        val snap=WidgetSnapshotReader.read(c)!!
        return WidgetEngine.direct(c,WidgetBindings.get(c,widget)!!,snap,snap.items["habit:$habit"]!!)
    }
    @After fun cleanup() {
        awaitCondition("Background job finishes before fixture cleanup") {
            val state=shell("cmd jobscheduler get-job-state -u ${android.os.Process.myUid()/100000} ${c.packageName} 1617")
            !state.contains("active") && !state.contains("pending")
        }
        if(widget!=0){WidgetBindings.remove(c,widget);host.deleteAppWidgetId(widget)}
        if(::db.isInitialized){fixtureWrite("DELETE FROM habits WHERE id=?",arrayOf(habit));fixtureWrite("DELETE FROM tasks WHERE id IN (?,?)",arrayOf("${habit}_resident","${habit}_once"));db.close()}
        val user=android.os.Process.myUid()/100000
        if(user!=0)shell("appwidget revokebind --package ${c.packageName} --user $user")
    }
    @Test fun backgroundCompleteUndoAndDuplicateNeverOpenAnActivity() {
        val complete=action();complete.send();complete.send()
        awaitCondition("Headless Dart must commit completion"){value()==1000L}
        val undo=action();undo.send()
        awaitCondition("Headless Dart must explicitly clear the record"){value()==null}
        // An old completion arriving after undo cannot resurrect it.
        complete.send();SystemClock.sleep(1000);assertNull(value())
        val resumed=shell("dumpsys activity activities").lineSequence().filter { it.contains("ResumedActivity") || it.contains("mResumedActivity") }.joinToString()
        assertTrue("Launcher must remain visible: $resumed",resumed.contains("launcher",ignoreCase=true))
    }
    @Test fun pendingUndoCannotEraseAnABANewRecord() {
        action().send();awaitCondition("Complete first"){value()==1000L}
        val oldUndo=action()
        fixtureWrite("DELETE FROM entries WHERE habit_id=?",arrayOf(habit))
        fixtureWrite("INSERT INTO entries(habit_id,day,value) VALUES(?,?,1000)",arrayOf(habit,day))
        oldUndo.send();SystemClock.sleep(1000)
        assertEquals(1000L,value())
        assertFalse(WidgetBindings.valid(c,mapOf("widgetId" to widget,"mode" to "set")))
    }
    @Test fun residentAndOneTimeTasksCompleteAndReopenOnLauncher() {
        WidgetBindings.remove(c,widget);host.deleteAppWidgetId(widget)
        widget=host.allocateAppWidgetId()
        assertTrue(AppWidgetManager.getInstance(c).bindAppWidgetIdIfAllowed(widget,ComponentName(c,TaskWidgetProvider::class.java)))
        for(resident in listOf(true,false)) {
            val id=habit+if(resident)"_resident" else "_once"
            fixtureWrite("INSERT INTO tasks(id,title,resident,start_day) VALUES(?,?,?,?)",arrayOf<Any?>(id,"Direct task fixture",if(resident)1 else 0,if(resident)day else null))
            WidgetBindings.save(c,widget,id,WidgetSnapshotReader.read(c)!!.generation)
            fun taskAction():android.app.PendingIntent {
                val snap=WidgetSnapshotReader.read(c)!!
                return WidgetEngine.direct(c,WidgetBindings.get(c,widget)!!,snap,snap.items["task:$id"]!!)
            }
            fun done():Boolean=if(resident)db.rawQuery("SELECT day FROM task_entries WHERE task_id=?",arrayOf(id)).use {it.moveToFirst()}
                else db.rawQuery("SELECT completed_day FROM tasks WHERE id=?",arrayOf(id)).use {it.moveToFirst();!it.isNull(0)}
            taskAction().send();awaitCondition("Task completion must persist"){done()}
            taskAction().send();awaitCondition("Task reopening must persist"){!done()}
        }
        val resumed=shell("dumpsys activity activities").lineSequence().filter {it.contains("ResumedActivity")}.joinToString()
        assertTrue(resumed.contains("launcher",ignoreCase=true))
    }
}
