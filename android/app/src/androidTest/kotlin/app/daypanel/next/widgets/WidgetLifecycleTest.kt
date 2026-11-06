package app.daypanel.next.widgets

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.*
import org.junit.Assert.*

/** Isolated fixture data plus real platform widget IDs; never modifies user records. */
class WidgetLifecycleTest {
    private val target=InstrumentationRegistry.getInstrumentation().targetContext
    private val host=AppWidgetHost(target,1616)
    private val allocated=mutableListOf<Int>()
    @Before fun permission() {
        Assume.assumeTrue("Run in a temporary Android user",android.os.Process.myUid()/100000 != 0)
        val user=android.os.Process.myUid()/100000
        InstrumentationRegistry.getInstrumentation().uiAutomation.executeShellCommand(
            "appwidget grantbind --package ${target.packageName} --user $user").use { p ->
            java.io.FileInputStream(p.fileDescriptor).readBytes()
        }
    }
    @After fun cleanup() {
        allocated.forEach { WidgetBindings.remove(target,it);host.deleteAppWidgetId(it) }
        val user=android.os.Process.myUid()/100000
        if(user!=0) InstrumentationRegistry.getInstrumentation().uiAutomation.executeShellCommand(
            "appwidget revokebind --package ${target.packageName} --user $user").use { p ->
                java.io.FileInputStream(p.fileDescriptor).readBytes()
            }
    }
    @Test fun identitiesCannotCrossInstancesAndDeletionRemovesBinding() {
        val manager=AppWidgetManager.getInstance(target)
        fun bind():Int {
            val id=host.allocateAppWidgetId();allocated.add(id)
            assertTrue(manager.bindAppWidgetIdIfAllowed(id,ComponentName(target,HabitWidgetProvider::class.java)))
            return id
        }
        val first=bind();val second=bind()
        assertNotEquals(first,second)
        assertEquals("habit",WidgetBindings.kind(target,first))
        val binding=WidgetBinding(first,"habit","fixture-only",30,"token")
        val uri=android.net.Uri.parse("content://${target.packageName}.widget-bindings")
        target.contentResolver.call(uri,"put",first.toString(),android.os.Bundle().apply { putString("value",binding.json().toString()) })
        assertEquals(binding,WidgetBindings.get(target,first));assertNull(WidgetBindings.get(target,second))
        WidgetBindings.remove(target,first);assertNull(WidgetBindings.get(target,first))
        host.deleteAppWidgetId(second)
        assertNull(WidgetBindings.kind(target,second))
        assertFalse(WidgetBindings.valid(target,mapOf("widgetId" to second,"generation" to 30)))
    }
    @Test fun savedBindingRejectsOldGenerationConfigDayArchiveAndDeletion() {
        val c = object: android.content.ContextWrapper(target) {
            override fun getDatabasePath(name:String)=java.io.File(target.cacheDir,"widget-binding-fixture.db")
        }
        c.getDatabasePath("").delete()
        val db=android.database.sqlite.SQLiteDatabase.openOrCreateDatabase(c.getDatabasePath(""),null)
        try {
            db.version=7
            db.execSQL("CREATE TABLE runtime(id INTEGER,generation INTEGER)");db.execSQL("INSERT INTO runtime VALUES(1,0)")
            db.execSQL("CREATE TABLE settings(key TEXT,value TEXT)")
            db.execSQL("CREATE TABLE habits(id TEXT,title TEXT,kind TEXT,start_day TEXT,archived INTEGER)")
            db.execSQL("CREATE TABLE plans(habit_id TEXT,effective_day TEXT,target INTEGER,unit TEXT,schedule TEXT,weekdays INTEGER,interval_days INTEGER,weekly_goal INTEGER)")
            db.execSQL("CREATE TABLE entries(habit_id TEXT,day TEXT,value INTEGER)")
            db.execSQL("CREATE TABLE tasks(id TEXT,title TEXT,resident INTEGER,archived INTEGER,completed_day TEXT,due_day TEXT,start_day TEXT)")
            db.execSQL("CREATE TABLE task_entries(task_id TEXT,day TEXT)")
            val day=java.time.LocalDate.now()
            for(id in listOf("a","b")) {
                db.execSQL("INSERT INTO habits VALUES(?,?,'check',?,0)",arrayOf(id,id,day.toString()))
                db.execSQL("INSERT INTO plans VALUES(?,?,1000,'','weekdays',127,1,3)",arrayOf(id,day.toString()))
            }
            val id=host.allocateAppWidgetId();allocated.add(id)
            assertTrue(AppWidgetManager.getInstance(target).bindAppWidgetIdIfAllowed(id,ComponentName(target,HabitWidgetProvider::class.java)))
            WidgetBindings.save(c,id,"a",0)
            val a=WidgetBindings.get(c,id)!!
            fun request(b:WidgetBinding):MutableMap<String,Any?> = mutableMapOf("widgetId" to id,"kind" to "habit","id" to b.id,"token" to b.token,"generation" to b.generation,"day" to day.toString(),"mode" to "complete")
            val old=request(a)
            assertTrue(WidgetBindings.valid(c,old));assertTrue(WidgetBindings.valid(c,old))
            assertFalse(WidgetBindings.valid(c,old+mapOf("day" to day.minusDays(1).toString())))
            WidgetBindings.save(c,id,"b",0)
            assertFalse(WidgetBindings.valid(c,old))
            val current=request(WidgetBindings.get(c,id)!!)
            assertTrue(WidgetBindings.valid(c,current))
            db.execSQL("UPDATE habits SET archived=1 WHERE id='b'")
            assertFalse(WidgetBindings.valid(c,current))
            db.execSQL("UPDATE habits SET archived=0 WHERE id='b'")
            db.execSQL("UPDATE runtime SET generation=1")
            assertFalse(WidgetBindings.valid(c,current))
            WidgetBindings.save(c,id,"b",1)
            val restored=request(WidgetBindings.get(c,id)!!)
            assertTrue(WidgetBindings.valid(c,restored))
            db.execSQL("DELETE FROM habits WHERE id='b'")
            assertFalse(WidgetBindings.valid(c,restored))
        } finally {db.close();c.getDatabasePath("").delete()}
    }

}
