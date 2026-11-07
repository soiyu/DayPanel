package app.daypanel.next.reminders

import android.content.Context
import android.content.ContextWrapper
import android.app.NotificationManager
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import java.io.File
import java.time.*

@RunWith(AndroidJUnit4::class)
class ReminderEngineTest {
    private lateinit var c: Context
    private lateinit var db: SQLiteDatabase
    private val id="__daypanel_reminder_test__"
    @Before fun setup() {
        val target=InstrumentationRegistry.getInstrumentation().targetContext
        if(Build.VERSION.SDK_INT>=33) {
            val user=android.os.Process.myUid()/100000
            InstrumentationRegistry.getInstrumentation().uiAutomation.executeShellCommand("pm grant --user $user ${target.packageName} android.permission.POST_NOTIFICATIONS").use { p ->
                java.io.FileInputStream(p.fileDescriptor).readBytes()
            }
        }
        c=object:ContextWrapper(target) {
            override fun getDatabasePath(name:String)=File(target.cacheDir,"reminder-native-test.db")
            override fun getSharedPreferences(name:String,mode:Int)=target.getSharedPreferences("reminder_native_test_$name",mode)
        }
        c.getDatabasePath("").delete()
        db=SQLiteDatabase.openOrCreateDatabase(c.getDatabasePath(""),null)
        db.version=7
        db.execSQL("CREATE TABLE habit_breaks(id TEXT,habit_id TEXT,start_day TEXT,end_day TEXT,kind TEXT)")
        db.execSQL("CREATE TABLE runtime (id INTEGER,generation INTEGER)")
        db.execSQL("INSERT INTO runtime VALUES(1,0)")
        db.execSQL("CREATE TABLE habits(id TEXT,title TEXT,kind TEXT,start_day TEXT,archived INTEGER)")
        db.execSQL("CREATE TABLE reminders(habit_id TEXT,enabled INTEGER,minutes TEXT,revision INTEGER)")
        db.execSQL("CREATE TABLE plans(habit_id TEXT,effective_day TEXT,target INTEGER,schedule TEXT,weekdays INTEGER,interval_days INTEGER,weekly_goal INTEGER)")
        db.execSQL("CREATE TABLE entries(habit_id TEXT,day TEXT,value INTEGER)")
        db.execSQL("CREATE TABLE settings(key TEXT,value TEXT)")
        val day=LocalDate.now().toString()
        val minute=LocalTime.now().plusMinutes(2).let { it.hour*60+it.minute }
        db.execSQL("INSERT INTO habits VALUES(?,?,'check',?,0)",arrayOf(id,"Reminder test",day))
        db.execSQL("INSERT INTO reminders VALUES(?,1,?,0)",arrayOf(id,"[$minute]"))
        db.execSQL("INSERT INTO plans VALUES(?,?,1000,'weekdays',127,1,3)",arrayOf(id,day))
        c.getSharedPreferences("reminder_runtime",0).edit().clear().commit()
        ReminderEngine.ensureChannel(c)
        assertTrue("Notification tests must execute with permission, not silently skip", ReminderEngine.status(c)["notifications"]==true)
        c.getSystemService(NotificationManager::class.java).cancel(id,1)
        awaitNotice(false)
    }
    @After fun cleanup() {
        if(::db.isInitialized) { db.execSQL("DELETE FROM reminders");ReminderEngine.sync(c);db.close();c.getDatabasePath("").delete() }
        if(::c.isInitialized)c.getSystemService(NotificationManager::class.java).cancel(id,1)
    }
    private fun awaitNotice(expected:Boolean) {
        val manager=c.getSystemService(NotificationManager::class.java)
        val deadline=android.os.SystemClock.elapsedRealtime()+5000
        while(manager.activeNotifications.any { it.tag==id } != expected && android.os.SystemClock.elapsedRealtime()<deadline) {
            android.os.SystemClock.sleep(50)
        }
        assertEquals("Notification service must reach the requested state",expected,manager.activeNotifications.any { it.tag==id })
    }
    private fun event():AlarmEvent {
        ReminderEngine.sync(c)
        val prefs=c.getSharedPreferences("reminder_runtime",0)
        val raw=JSONObject(prefs.getString("scheduled","{}")!!)
        val e=AlarmEvent.from(raw.getJSONObject(id)).copy(day=LocalDate.now(),at=System.currentTimeMillis()-100)
        raw.put(id,e.json());prefs.edit().putString("scheduled",raw.toString()).commit()
        return e
    }
    @Test fun schemaThreeThroughNineRemainReadableWithoutUserDataWrites() {
        for(version in 3..9) {
            db.version=version
            val snapshot=SnapshotReader.read(c)
            assertNotNull(snapshot)
            assertEquals(id,snapshot!!.habits.single().id)
            assertEquals(version,db.version)
        }
        db.version=10
        assertNull(SnapshotReader.read(c))
        db.version=7
        db.rawQuery("SELECT COUNT(*) FROM entries",null).use { it.moveToFirst();assertEquals(0,it.getInt(0)) }
    }
    @Test fun deliverDeduplicatesAndSnoozeDoesNotWriteUserData() {
        val e=event()
        ReminderEngine.receive(c,ReminderEngine.FIRE,e.json().toString())
        val manager=c.getSystemService(NotificationManager::class.java)
        awaitNotice(true)
        val notice=JSONObject(c.getSharedPreferences("reminder_runtime",0).getString("notices","{}")!!).getJSONObject(id)
        ReminderEngine.receive(c,ReminderEngine.FIRE,e.json().toString())
        assertEquals(e.token,notice.getString("token"))
        ReminderEngine.receive(c,ReminderEngine.SNOOZE,notice.toString())
        awaitNotice(false)
        db.rawQuery("SELECT COUNT(*) FROM entries",null).use { it.moveToFirst();assertEquals(0,it.getInt(0)) }
        val before=c.getSharedPreferences("reminder_runtime",0).getString("snoozes","")
        ReminderEngine.receive(c,ReminderEngine.SNOOZE,notice.toString())
        assertEquals(before,c.getSharedPreferences("reminder_runtime",0).getString("snoozes",""))
    }
    @Test fun completionCancelsNoticeAndSchedulesNextEligibleDay() {
        val e=event();ReminderEngine.receive(c,ReminderEngine.FIRE,e.json().toString())
        db.execSQL("INSERT INTO entries VALUES(?,?,1000)",arrayOf(id,LocalDate.now().toString()))
        ReminderEngine.sync(c)
        awaitNotice(false)
        val next=JSONObject(c.getSharedPreferences("reminder_runtime",0).getString("scheduled","{}")!!).getJSONObject(id)
        assertTrue(LocalDate.parse(next.getString("day"))>LocalDate.now())
    }
    @Test fun disableAndGenerationChangeRejectOldNotificationActions() {
        val e=event();ReminderEngine.receive(c,ReminderEngine.FIRE,e.json().toString())
        db.execSQL("UPDATE runtime SET generation=1")
        assertNull(ReminderEngine.openRequest(c,e.json().toString()))
        ReminderEngine.sync(c)
        db.execSQL("UPDATE reminders SET enabled=0,revision=1")
        ReminderEngine.sync(c)
        assertEquals(0,ReminderEngine.status(c)["pending"])
        awaitNotice(false)
    }
    @Test fun rebootStyleRescheduleUsesStoredDataAndClearsSnoozesOnClockChange() {
        val e=event();ReminderEngine.receive(c,ReminderEngine.FIRE,e.json().toString())
        ReminderEngine.receive(c,ReminderEngine.SNOOZE,e.json().toString())
        ReminderEngine.sync(c,resetClock=true)
        assertEquals("{}",c.getSharedPreferences("reminder_runtime",0).getString("snoozes",""))
        assertEquals(1,ReminderEngine.status(c)["pending"])
        db.execSQL("UPDATE habits SET archived=1");ReminderEngine.sync(c)
        assertEquals(0,ReminderEngine.status(c)["pending"])
    }
    @Test fun notificationOpenIsConsumedAndNeverCreatesAnEntry() {
        val e=event();ReminderEngine.receive(c,ReminderEngine.FIRE,e.json().toString())
        val request=ReminderEngine.openRequest(c,e.json().toString())
        assertEquals(id,request!!["id"])
        assertEquals(LocalDate.now().toString(),request["day"])
        assertNull(ReminderEngine.openRequest(c,e.json().toString()))
        db.rawQuery("SELECT COUNT(*) FROM entries",null).use { it.moveToFirst();assertEquals(0,it.getInt(0)) }
    }
    @Test fun outdatedRevisionAndStaleDayCannotPostOrSnooze() {
        val e=event()
        db.execSQL("UPDATE reminders SET revision=1")
        ReminderEngine.receive(c,ReminderEngine.FIRE,e.json().toString())
        awaitNotice(false)
        val old=event().copy(day=LocalDate.now().minusDays(1))
        val map=JSONObject().put(id,old.json())
        c.getSharedPreferences("reminder_runtime",0).edit().putString("scheduled",map.toString()).commit()
        ReminderEngine.receive(c,ReminderEngine.FIRE,old.json().toString())
        awaitNotice(false)
        assertNull(ReminderEngine.openRequest(c,old.json().toString()))
    }
    @Test fun pauseCancelsNoticeAndResumeReschedulesFromDatabase() {
        db.version=9
        val e=event();ReminderEngine.receive(c,ReminderEngine.FIRE,e.json().toString());awaitNotice(true)
        db.execSQL("INSERT INTO habit_breaks VALUES('pause',?,?,NULL,'pause')",arrayOf(id,LocalDate.now().toString()))
        ReminderEngine.sync(c);awaitNotice(false)
        assertEquals(0,ReminderEngine.status(c)["pending"])
        assertNull(ReminderEngine.openRequest(c,e.json().toString()))
        db.execSQL("DELETE FROM habit_breaks");ReminderEngine.sync(c)
        assertEquals(1,ReminderEngine.status(c)["pending"])
    }

}
