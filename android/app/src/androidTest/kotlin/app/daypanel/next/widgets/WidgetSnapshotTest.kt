package app.daypanel.next.widgets

import android.content.Context
import android.content.ContextWrapper
import android.database.sqlite.SQLiteDatabase
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import java.io.File
import java.time.LocalDate

@RunWith(AndroidJUnit4::class)
class WidgetSnapshotTest {
    private lateinit var c:Context
    private lateinit var db:SQLiteDatabase
    private val day=LocalDate.of(2026,11,6)
    @Before fun setup() {
        val target=InstrumentationRegistry.getInstrumentation().targetContext
        c=object:ContextWrapper(target) {
            override fun getDatabasePath(name:String)=File(target.cacheDir,"widget-test.db")
            override fun getSharedPreferences(name:String,mode:Int)=target.getSharedPreferences("widget_test_$name",mode)
        }
        c.getDatabasePath("").delete()
        db=SQLiteDatabase.openOrCreateDatabase(c.getDatabasePath(""),null)
        db.version=7
        db.execSQL("CREATE TABLE runtime(id INTEGER,generation INTEGER)");db.execSQL("INSERT INTO runtime VALUES(1,0)")
        db.execSQL("CREATE TABLE settings(key TEXT,value TEXT)")
        db.execSQL("CREATE TABLE habits(id TEXT,title TEXT,kind TEXT,start_day TEXT,archived INTEGER)")
        db.execSQL("CREATE TABLE plans(habit_id TEXT,effective_day TEXT,target INTEGER,unit TEXT,schedule TEXT,weekdays INTEGER,interval_days INTEGER,weekly_goal INTEGER)")
        db.execSQL("CREATE TABLE entries(habit_id TEXT,day TEXT,value INTEGER)")
        db.execSQL("CREATE TABLE tasks(id TEXT,title TEXT,resident INTEGER,archived INTEGER,completed_day TEXT,due_day TEXT,start_day TEXT)")
        db.execSQL("CREATE TABLE task_entries(task_id TEXT,day TEXT)")
        db.execSQL("INSERT INTO habits VALUES('h','Water','quantity','2026-11-01',0)")
        db.execSQL("INSERT INTO plans VALUES('h','2026-11-01',2000000,'ml','weekdays',127,1,3)")
        db.execSQL("INSERT INTO plans VALUES('h','2026-11-07',3000000,'cups','weekly',127,1,4)")
        db.execSQL("INSERT INTO entries VALUES('h','2026-11-06',250001)")
        db.execSQL("INSERT INTO tasks VALUES('r','Stretch',1,0,NULL,NULL,'2026-11-01')")
        db.execSQL("INSERT INTO tasks VALUES('t','Post',0,0,'2026-11-05','2026-11-04',NULL)")
        db.execSQL("INSERT INTO task_entries VALUES('r','2026-11-06')")
    }
    @After fun cleanup(){db.close();c.getDatabasePath("").delete()}
    @Test fun historicalPlanAndQuantityAreReadWithoutWrites() {
        val today=WidgetSnapshotReader.read(c,day)!!.items["habit:h"]!!
        assertEquals(2000000L,today.target);assertEquals("ml",today.unit);assertEquals(250001L,today.value)
        val tomorrow=WidgetSnapshotReader.read(c,day.plusDays(1))!!.items["habit:h"]!!
        assertEquals(3000000L,tomorrow.target);assertEquals("cups",tomorrow.unit);assertNull(tomorrow.value)
        db.rawQuery("SELECT COUNT(*) FROM entries",null).use {it.moveToFirst();assertEquals(1,it.getInt(0))}
    }
    @Test fun residentResetsViewButOneTimeKeepsActualDate() {
        assertTrue(WidgetSnapshotReader.read(c,day)!!.items["task:r"]!!.done)
        val next=WidgetSnapshotReader.read(c,day.plusDays(1))!!
        assertFalse(next.items["task:r"]!!.done)
        assertEquals("2026-11-05",next.items["task:t"]!!.doneDay)
        db.rawQuery("SELECT COUNT(*) FROM task_entries",null).use {it.moveToFirst();assertEquals(1,it.getInt(0))}
    }
    @Test fun generationArchiveDeleteLocaleThemeAndUnsupportedVersion() {
        db.execSQL("UPDATE runtime SET generation=3")
        db.execSQL("INSERT INTO settings VALUES('locale','zh')");db.execSQL("INSERT INTO settings VALUES('theme','dark')")
        db.execSQL("UPDATE habits SET archived=1")
        val snap=WidgetSnapshotReader.read(c,day)!!
        assertEquals(3L,snap.generation);assertTrue(snap.chinese);assertTrue(snap.dark);assertTrue(snap.items["habit:h"]!!.archived)
        db.execSQL("DELETE FROM habits");assertNull(WidgetSnapshotReader.read(c,day)!!.items["habit:h"])
        db.version=8;assertNull(WidgetSnapshotReader.read(c,day));assertEquals(8,db.version)
    }
    @Test fun pendingIntentsSeparateInstancesConfigurationDayAndAction() {
        val a=WidgetBinding(101,"habit","h",0,"a")
        val b=a.copy(widgetId=102)
        val first=WidgetEngine.pending(c,101,"complete",a,day)
        assertEquals(first,WidgetEngine.pending(c,101,"complete",a,day))
        assertNotEquals(first,WidgetEngine.pending(c,102,"complete",b,day))
        assertNotEquals(first,WidgetEngine.pending(c,101,"view",a,day))
        assertNotEquals(first,WidgetEngine.pending(c,101,"complete",a,day.plusDays(1)))
        assertNotEquals(first,WidgetEngine.pending(c,101,"complete",a.copy(token="new"),day))
        assertNotEquals(first,WidgetEngine.pending(c,101,"complete",a.copy(generation=1),day))
    }
}
