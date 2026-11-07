package app.daypanel.next.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import app.daypanel.next.R
import java.time.LocalDate
import java.time.ZoneId
import java.util.concurrent.Executors
import org.json.JSONObject

object WidgetEngine {
    val worker = Executors.newSingleThreadExecutor()
    const val REFRESH = "app.daypanel.next.WIDGET_REFRESH"
    const val OPEN = "app.daypanel.next.WIDGET_OPEN"
    fun refresh(context: Context) {
        WidgetBindings.prune(context)
        val snapshot = try { WidgetSnapshotReader.read(context) } catch (_: Exception) { null }
        WidgetBindings.ids(context).forEach { id -> render(context, id, snapshot) }
        schedule(context)
    }
    private fun schedule(c: Context) {
        val alarm = c.getSystemService(AlarmManager::class.java)
        val intent = PendingIntent.getBroadcast(c, 1600, Intent(c, WidgetSystemReceiver::class.java).setAction(REFRESH),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        alarm.cancel(intent)
        if (WidgetBindings.ids(c).isNotEmpty()) {
            val midnight = LocalDate.now().plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli() + 1000
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, midnight, intent)
        }
    }
    fun pending(c: Context, widgetId: Int, mode: String, binding: WidgetBinding?, day: LocalDate): PendingIntent {
        val payload = (binding?.json() ?: JSONObject().put("widgetId", widgetId)).put("mode", mode).put("day", day.toString())
        // Identity is display context, not a physical-click ID. All writes are explicit values.
        val data = Uri.Builder().scheme("daypanel-widget").authority(c.packageName).appendPath(widgetId.toString())
            .appendPath(binding?.token ?: "unbound").appendPath((binding?.generation ?: -1).toString())
            .appendPath(day.toString()).appendPath(mode).build()
        val activity=when(mode){"quantity"->WidgetQuantityActivity::class.java;"configure"->WidgetConfigureActivity::class.java;else->WidgetActivity::class.java}
        val intent = Intent(c, activity).setAction(OPEN).setData(data)
            .putExtra("widget", payload.toString()).putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        return PendingIntent.getActivity(c, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
    fun direct(c:Context,binding:WidgetBinding,snapshot:WidgetSnapshot,item:WidgetItem):PendingIntent {
        val payload=binding.json().put("mode","set").put("day",snapshot.day.toString())
            .put("revision",snapshot.revision).put("completed",!item.done)
            .put("expectedValue",(if(item.kind=="habit")item.value else item.doneDay) ?: JSONObject.NULL)
        val data=Uri.Builder().scheme("daypanel-widget-action").authority(c.packageName)
            .appendPath(binding.widgetId.toString()).appendPath(binding.token).appendPath(binding.generation.toString())
            .appendPath(snapshot.day.toString()).appendPath(snapshot.revision.toString()).appendPath((!item.done).toString()).build()
        return PendingIntent.getBroadcast(c,0,Intent(c,WidgetActionReceiver::class.java).setData(data).putExtra("widget",payload.toString()),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
    fun render(c: Context, id: Int, snapshot: WidgetSnapshot?) {
        val manager = AppWidgetManager.getInstance(c)
        manager.updateAppWidget(id, views(c, id, snapshot, manager.getAppWidgetOptions(id)))
    }
    internal fun views(c: Context, id: Int, snapshot: WidgetSnapshot?, options: Bundle): RemoteViews {
        val binding = WidgetBindings.get(c, id)
        val validBinding = binding?.takeIf { it.generation == snapshot?.generation }
        val item = validBinding?.let { snapshot?.items?.get("${it.kind}:${it.id}") }
        val zh = snapshot?.chinese ?: (c.resources.configuration.locales[0].language == "zh")
        fun t(chinese: String, english: String) = if (zh) chinese else english
        val day = snapshot?.day ?: LocalDate.now()
        val views = RemoteViews(c.packageName, R.layout.daypanel_widget)
        views.setInt(R.id.widget_action, "setBackgroundResource", WidgetAppearance.action(snapshot?.palette ?: "blue"))
        val dark = snapshot?.dark ?: (c.resources.configuration.uiMode and 48 == 32)
        val ink = Color.parseColor(if (dark) "#EDF1FF" else "#18223B")
        val secondary = Color.parseColor(if (dark) "#B6C2E0" else "#52627F")
        views.setInt(R.id.widget_root, "setBackgroundResource", if (dark) R.drawable.widget_dark else R.drawable.widget_light)
        listOf(R.id.widget_title, R.id.widget_state).forEach { views.setTextColor(it, ink) }
        listOf(R.id.widget_date, R.id.widget_hint, R.id.widget_settings, R.id.widget_details).forEach { views.setTextColor(it, secondary) }
        val portrait = c.resources.configuration.orientation != Configuration.ORIENTATION_LANDSCAPE
        val width = options.getInt(if(portrait) AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH else AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 160)
        val date = if (width < 160 || c.resources.configuration.fontScale > 1.3f)
            "${day.year}\n%02d/%02d".format(day.monthValue, day.dayOfMonth)
            else day.toString().replace('-', '/')
        views.setTextViewText(R.id.widget_date, date)
        views.setTextViewText(R.id.widget_settings, "⚙")
        views.setContentDescription(R.id.widget_settings, t("配置桌面组件", "Configure widget"))
        views.setOnClickPendingIntent(R.id.widget_settings, pending(c, id, "configure", binding, day))
        views.setContentDescription(R.id.widget_details,t("查看详情","View details"))
        views.setOnClickPendingIntent(R.id.widget_details,pending(c,id,if(item==null)"configure" else "view",binding,day))
        val height = options.getInt(if(portrait) AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT else AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 180)
        val large = height >= 240 && c.resources.configuration.fontScale <= 1.3f
        val compactText = height < 240 && c.resources.configuration.fontScale > 1.3f
        views.setInt(R.id.widget_title, "setMaxLines", if (compactText) 1 else 2)
        views.setInt(R.id.widget_state, "setMaxLines", if (compactText) 1 else 2)
        views.setViewVisibility(R.id.widget_hint, if (large) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.widget_icon, if (large && item?.kind == "habit") View.VISIBLE else View.GONE)
        if (large && item?.kind == "habit" && snapshot != null) {
            views.setImageViewBitmap(R.id.widget_icon, WidgetAppearance.icon(c,item,snapshot))
        }
        val title: String
        val state: String
        val hint: String
        val action: String
        val mode: String
        if (item == null) {
            title = t("你的日常，放在桌面", "Your day, at a glance")
            state = if (snapshot == null) t("打开 App 以读取数据", "Open the app to load data")
                else if (binding == null) t("选择要显示的内容", "Choose an item to show")
                else t("内容已变，请重新选择", "Content changed. Choose again")
            hint = t("每个组件独立保存选择", "Each widget keeps its own selection")
            action = t("选择内容", "Choose item")
            mode = "configure"
        } else {
            title = item.title
            hint = when {
                item.archived -> t("归档内容保留记录", "Archived; history is preserved")
                item.rest != null -> t("休息期间不提醒，历史记录保留", "Reminders pause; history stays")
                item.kind == "task" && item.resident -> t("常驻 · 按需记录，无欠账", "Resident · as needed, no overdue days")
                item.kind == "task" -> t("一次性 · 完成后不会自动重建", "One-time · does not repeat automatically")
                item.schedule == "weekly" -> t("本周 ${item.weekCount}/${item.weekGoal} 天", "This week ${item.weekCount}/${item.weekGoal} days")
                !item.scheduled -> t("今天未安排", "Not scheduled today")
                else -> t("今天的安排", "Scheduled today")
            }
            state = when {
                item.archived -> t("已归档 · 查看记录", "Archived · view records")
                item.rest != null -> when(item.rest) { "skip" -> t("这天已跳过", "Skipped this day"); "vacation" -> t("休假中", "On a break"); else -> t("已暂停", "Paused") }
                item.quantity -> "${item.value?.let { WidgetDisplayRules.quantity(it) } ?: "—"} / ${WidgetDisplayRules.quantity(item.target)} ${item.unit}"
                item.kind == "habit" && item.done -> t("今天已完成", "Completed today")
                item.kind == "habit" && item.schedule == "weekly" -> t("本周 ${item.weekCount}/${item.weekGoal} 天", "Week ${item.weekCount}/${item.weekGoal} days")
                item.kind == "habit" && !item.scheduled -> t("今天未安排", "Not scheduled today")
                item.kind == "habit" -> t("今天未记录", "Not recorded today")
                item.resident -> if (item.done) t("常驻 · 今天已做", "Resident · done today") else t("常驻 · 今天未记录", "Resident · not recorded today")
                item.done -> t("完成于 ${item.doneDay}", "Done ${item.doneDay}")
                item.dueDay != null -> t("一次性 · ${item.dueDay}", "One-time · ${item.dueDay}")
                else -> t("一次性 · 未设日期", "One-time · no planned date")
            }
            mode = when {
                item.rest != null -> "view"
                item.archived -> "view"
                item.quantity -> "quantity"
                snapshot?.revision == null || snapshot.revision < 0 -> "configure"
                else -> "set"
            }
            action = when (mode) {
                "quantity" -> t("输入总量", "Enter total")
                "set" -> if(item.done) {
                    if(item.kind=="task" && !item.resident) t("重新待办","Reopen") else t("取消完成","Mark undone")
                } else t("完成", "Complete")
                "configure" -> t("打开更新","Open to update")
                else -> t("查看记录", "View records")
            }
        }
        views.setTextViewText(R.id.widget_title, title)
        views.setTextViewText(R.id.widget_state, state)
        views.setTextViewText(R.id.widget_hint, hint)
        val status=WidgetActionStatus.get(c,id)
        val actionLabel=when(status){"pending"->t("正在保存…","Saving…");"failed"->t("重试","Retry");else->action}
        views.setTextViewText(R.id.widget_action, actionLabel)
        if(status=="failed") {
            views.setTextViewText(R.id.widget_state,t("未能保存，请重试","Could not save. Try again"))
        }
        views.setContentDescription(R.id.widget_content, "$title. $day. $state. $hint")
        views.setContentDescription(R.id.widget_action, "$actionLabel. $title. $day")
        val primary=if(mode=="set" && validBinding!=null && snapshot!=null && item!=null) direct(c,validBinding,snapshot,item) else pending(c,id,mode,binding,day)
        views.setOnClickPendingIntent(R.id.widget_content, primary)
        views.setOnClickPendingIntent(R.id.widget_action, primary)
        return views
    }
}
