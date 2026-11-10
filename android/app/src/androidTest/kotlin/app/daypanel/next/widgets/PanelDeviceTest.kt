package app.daypanel.next.widgets

import android.appwidget.*
import android.content.*
import android.content.res.Configuration
import android.database.sqlite.SQLiteDatabase
import android.os.*
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import androidx.test.platform.app.InstrumentationRegistry
import app.daypanel.next.R
import org.json.JSONArray
import org.json.JSONObject
import org.junit.*
import org.junit.Assert.*
import java.time.LocalDate
import java.util.Locale

class PanelDeviceTest {
 private val ins=InstrumentationRegistry.getInstrumentation()
 private val c=ins.targetContext
 private val host=AppWidgetHost(c,1619)
 private val names=listOf("__plus_panel_a","__plus_panel_b","__plus_panel_c","__plus_panel_d")
 private lateinit var db:SQLiteDatabase
 private var widget=0
 private val day=LocalDate.now().toString()
 private fun shell(s:String)=ins.uiAutomation.executeShellCommand(s).use{java.io.FileInputStream(it.fileDescriptor).readBytes().toString(Charsets.UTF_8)}
 private fun waitFor(message:String,fn:()->Boolean){val end=SystemClock.elapsedRealtime()+120000;while(!fn()&&SystemClock.elapsedRealtime()<end)SystemClock.sleep(100);assertTrue(message,fn())}
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
 @Before fun setup(){
  val user=android.os.Process.myUid()/100000;assertTrue("Disposable user required",user!=0)
  c.startActivity(Intent(c,app.daypanel.next.MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
  waitFor("SQLite12 ready"){try{SQLiteDatabase.openDatabase(c.getDatabasePath("daypanel_flutter.db").path,null,SQLiteDatabase.OPEN_READWRITE or SQLiteDatabase.ENABLE_WRITE_AHEAD_LOGGING).use{it.version==12}}catch(_:Exception){false}}
  waitFor("Main Activity finishes launching before Home") { shell("dumpsys activity activities").lineSequence().filter{it.contains("ResumedActivity")}.any{it.contains("app.daypanel.next.MainActivity")} }
  c.startActivity(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));shell("appwidget grantbind --package ${c.packageName} --user $user")
  db=SQLiteDatabase.openDatabase(c.getDatabasePath("daypanel_flutter.db").path,null,SQLiteDatabase.OPEN_READWRITE or SQLiteDatabase.ENABLE_WRITE_AHEAD_LOGGING);fixtureWrite("PRAGMA foreign_keys=ON")
  for(id in names){
   fixtureWrite("DELETE FROM habits WHERE id=?",arrayOf(id));
   fixtureWrite("INSERT INTO habits(id,title,kind,start_day,target,unit,weekdays,icon) VALUES(?,?,'check',?,1000,'',127,2)",arrayOf(id,"Read and practice a little every day $id",day))
   fixtureWrite("INSERT INTO plans(habit_id,effective_day,target,unit,schedule,weekdays,interval_days,weekly_goal) VALUES(?,?,1000,'','weekdays',127,1,3)",arrayOf(id,day))
   fixtureWrite("INSERT INTO habit_activity(habit_id,day,archived) VALUES(?,?,0)",arrayOf(id,day))
  }
  widget=host.allocateAppWidgetId();assertTrue(AppWidgetManager.getInstance(c).bindAppWidgetIdIfAllowed(widget,ComponentName(c,PanelWidgetProvider::class.java)))
  bind(names)
  c.startActivity(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
  waitFor("Launcher is visible before executing widget actions") { shell("dumpsys activity activities").lineSequence().filter{it.contains("ResumedActivity")}.any{it.contains("launcher",true)} }
 }
 private fun bind(ids:List<String>){val list=JSONArray();ids.forEach{list.put(JSONObject().put("kind","habit").put("id",it))};WidgetBindings.save(c,widget,list.toString(),WidgetSnapshotReader.read(c)!!.generation)}
 private fun value(id:String):Long?=db.rawQuery("SELECT value FROM entries WHERE habit_id=? AND day=?",arrayOf(id,day)).use{if(it.moveToFirst())it.getLong(0)else null}
 private fun awaitJobsIdle(){
  waitFor("Background widget job must finish before fixture cleanup"){
    val state=shell("cmd jobscheduler get-job-state -u ${android.os.Process.myUid()/100000} ${c.packageName} 1617")
    !state.contains("active") && !state.contains("pending")
  }
 }
 @After fun cleanup(){awaitJobsIdle();if(widget!=0){WidgetBindings.remove(c,widget);host.deleteAppWidgetId(widget)};if(::db.isInitialized){names.forEach{fixtureWrite("DELETE FROM habits WHERE id=?",arrayOf(it))};db.close()};shell("appwidget revokebind --package ${c.packageName} --user ${android.os.Process.myUid()/100000}")}
 @Test fun rapidDistinctRowsCommitAndDuplicateOrReboundOldRequestsReject(){
  val snap=WidgetSnapshotReader.read(c)!!;val binding=WidgetBindings.get(c,widget)!!
  val a=WidgetEngine.direct(c,binding.copy(kind="habit",id=names[0]),snap,snap.items["habit:${names[0]}"]!!)
  val b=WidgetEngine.direct(c,binding.copy(kind="habit",id=names[1]),snap,snap.items["habit:${names[1]}"]!!)
  a.send();b.send();try {waitFor("Two distinct rows save without global conflict"){value(names[0])==1000L&&value(names[1])==1000L}}catch(e:AssertionError){throw AssertionError("Panel completion: a=${value(names[0])}, b=${value(names[1])}, status=${WidgetActionStatus.get(c,widget)}; ${shell("cmd jobscheduler get-job-state -u ${android.os.Process.myUid()/100000} ${c.packageName} 1617")}",e)}
  a.send();SystemClock.sleep(500);assertEquals(1000L,value(names[0]))
  val newSnap=WidgetSnapshotReader.read(c)!!;val oldUndo=WidgetEngine.direct(c,binding.copy(kind="habit",id=names[0]),newSnap,newSnap.items["habit:${names[0]}"]!!)
  bind(listOf(names[2]));oldUndo.send();SystemClock.sleep(700);assertEquals(1000L,value(names[0]));assertNull(value(names[2]))
  assertTrue(shell("dumpsys activity activities").lineSequence().filter{it.contains("ResumedActivity")}.any{it.contains("launcher",true)})
 }
 @Test fun responsiveRemoteViewsHaveReachableActionsAcrossLocaleThemeAndScale(){
  val base=WidgetSnapshotReader.read(c)!!
  for(zh in listOf(false,true))for(dark in listOf(false,true))for(scale in listOf(1f,1.6f))for(width in listOf(160,300)){
   val config=Configuration(c.resources.configuration).apply{fontScale=scale;setLocale(if(zh)Locale.SIMPLIFIED_CHINESE else Locale.US)}
   val ctx=c.createConfigurationContext(config);val height=if(width==160)220 else 420
   val options=Bundle().apply{putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH,width);putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,height);putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT,height)}
   ins.runOnMainSync{
    val view=PanelWidgets.views(ctx,widget,WidgetBindings.get(c,widget),base.copy(chinese=zh,dark=dark),options).apply(ctx,FrameLayout(ctx))
    val density=ctx.resources.displayMetrics.density
    view.measure(View.MeasureSpec.makeMeasureSpec((width*density).toInt(),View.MeasureSpec.EXACTLY),View.MeasureSpec.makeMeasureSpec((height*density).toInt(),View.MeasureSpec.EXACTLY));view.layout(0,0,view.measuredWidth,view.measuredHeight)
    val footer=view.findViewById<TextView>(R.id.panel_footer);assertTrue(footer.measuredHeight>=48*density-1);assertTrue(footer.bottom<=view.height)
    val action=view.findViewById<TextView>(R.id.panel_row_action);assertNotNull(action);assertTrue(action.measuredHeight>=48*density-1);assertTrue(action.measuredWidth>=48*density-1)
    assertTrue(action.contentDescription.toString().contains(names[0]));assertTrue(action.layout.lineCount==1)
   }
  }
 }
 @Test fun panelViewKeepsRowIdentitySeparateAndStaleGenerationRejects(){
  val snap=WidgetSnapshotReader.read(c)!!;val parent=WidgetBindings.get(c,widget)!!
  fun request(id:String)=parent.copy(kind="habit",id=id).json().put("day",day).put("mode","view")
  val req=request(names[0]);assertTrue(WidgetBindings.valid(c,widgetRequest(req.toString())))
  assertFalse(WidgetBindings.valid(c,widgetRequest(request("not-selected").toString())))
  req.put("generation",snap.generation-1);assertFalse(WidgetBindings.valid(c,widgetRequest(req.toString())))
  assertEquals(4,PanelWidgets.rows(parent.id).size)
 }
}
