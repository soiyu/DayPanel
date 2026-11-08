package app.daypanel.next.widgets

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.*
import org.junit.Assert.*
import java.time.LocalDate
import java.util.UUID

class WidgetPinDeviceTest {
    private val target = InstrumentationRegistry.getInstrumentation().targetContext
    private val host = AppWidgetHost(target, 1704)
    private val ids = mutableListOf<Int>()
    private lateinit var c: Context
    private lateinit var db: SQLiteDatabase
    @Before fun setup() {
        val user = android.os.Process.myUid() / 100000
        Assume.assumeTrue("Temporary Android user required", user != 0)
        InstrumentationRegistry.getInstrumentation().uiAutomation.executeShellCommand("appwidget grantbind --package ${target.packageName} --user $user").use { java.io.FileInputStream(it.fileDescriptor).readBytes() }
        c = object: ContextWrapper(target) {
            override fun getDatabasePath(name: String) = java.io.File(target.cacheDir, "pin-fixture.db")
            override fun getSharedPreferences(name: String, mode: Int) = target.getSharedPreferences("pin_fixture_$name", mode)
        }
        c.getDatabasePath("").delete()
        c.getSharedPreferences("widget_pin_requests", Context.MODE_PRIVATE).edit().clear().commit()
        db = SQLiteDatabase.openOrCreateDatabase(c.getDatabasePath(""), null)
        db.version = 11
        db.execSQL("CREATE TABLE runtime(id INTEGER,generation INTEGER,revision INTEGER)");db.execSQL("INSERT INTO runtime VALUES(1,0,0)")
        db.execSQL("CREATE TABLE settings(key TEXT,value TEXT)")
        db.execSQL("CREATE TABLE habits(id TEXT,title TEXT,kind TEXT,start_day TEXT,archived INTEGER,icon INTEGER DEFAULT 0,color TEXT DEFAULT 'auto',frame TEXT DEFAULT 'auto')")
        db.execSQL("CREATE TABLE habit_breaks(id TEXT,habit_id TEXT,start_day TEXT,end_day TEXT,kind TEXT)")
        db.execSQL("CREATE TABLE plans(habit_id TEXT,effective_day TEXT,target INTEGER,unit TEXT,schedule TEXT,weekdays INTEGER,interval_days INTEGER,weekly_goal INTEGER)")
        db.execSQL("CREATE TABLE entries(habit_id TEXT,day TEXT,value INTEGER)")
        db.execSQL("CREATE TABLE tasks(id TEXT,title TEXT,resident INTEGER,archived INTEGER,completed_day TEXT,due_day TEXT,start_day TEXT)")
        db.execSQL("CREATE TABLE task_entries(task_id TEXT,day TEXT)")
        val day=LocalDate.now().toString()
        for(id in listOf("a","b")) {
            db.execSQL("INSERT INTO habits(id,title,kind,start_day,archived) VALUES(?,?,'count',?,0)",arrayOf(id,id,day))
            db.execSQL("INSERT INTO plans VALUES(?,?,3000,'times','weekdays',127,1,3)",arrayOf(id,day))
        }
    }
    @After fun cleanup() {
        ids.forEach {WidgetBindings.remove(target,it);host.deleteAppWidgetId(it)}
        if (::db.isInitialized) db.close()
        if (::c.isInitialized) c.getDatabasePath("").delete()
        val user=android.os.Process.myUid()/100000
        if(user!=0) InstrumentationRegistry.getInstrumentation().uiAutomation.executeShellCommand("appwidget revokebind --package ${target.packageName} --user $user").use {java.io.FileInputStream(it.fileDescriptor).readBytes()}
    }
    private fun bind():Int {
        val id=host.allocateAppWidgetId();ids.add(id)
        assertTrue(AppWidgetManager.getInstance(target).bindAppWidgetIdIfAllowed(id,ComponentName(target,HabitWidgetProvider::class.java)))
        return id
    }
    private fun callback(id:Int,item:String,generation:Long=0):Intent {
        val token=UUID.randomUUID().toString()
        c.getSharedPreferences("widget_pin_requests",Context.MODE_PRIVATE).edit().putString(token,
            JSONObject().put("kind","habit").put("id",item).put("generation",generation).put("created",System.currentTimeMillis()).toString()).commit()
        return Intent(c,WidgetPinReceiver::class.java).setAction("${c.packageName}.PIN_WIDGET").setData(Uri.parse("daypanel-pin://request/$token")).putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID,id)
    }
    @Test fun confirmedInstancesBindIndependentlyAndCallbackIsOneShot() {
        val first=bind();val second=bind()
        val a=callback(first,"a");val b=callback(second,"b")
        assertTrue(WidgetPin.accept(c,a));assertTrue(WidgetPin.accept(c,b))
        assertEquals("a",WidgetBindings.get(c,first)!!.id);assertEquals("b",WidgetBindings.get(c,second)!!.id)
        assertFalse(WidgetPin.accept(c,a))
    }
    @Test fun invalidInstanceAndLateRestoreCallbackNeverCreateBinding() {
        val pending=callback(AppWidgetManager.INVALID_APPWIDGET_ID,"a")
        assertFalse(WidgetPin.accept(c,pending))
        val id=bind();val old=callback(id,"a")
        db.execSQL("UPDATE runtime SET generation=1")
        assertFalse(WidgetPin.accept(c,old));assertNull(WidgetBindings.get(c,id))
    }
}
