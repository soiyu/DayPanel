package app.daypanel.next.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.text.SpannableString
import android.text.Spanned
import android.text.style.RelativeSizeSpan
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import android.graphics.Typeface
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
            .appendPath(day.toString()).appendPath(binding?.kind ?: "").appendPath(binding?.id ?: "").appendPath(mode).build()
        val activity=when(mode){"quantity"->WidgetQuantityActivity::class.java;"configure"->WidgetConfigureActivity::class.java;else->WidgetActivity::class.java}
        val intent = Intent(c, activity).setAction(OPEN).setData(data)
            .putExtra("widget", payload.toString()).putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        return PendingIntent.getActivity(c, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
    fun direct(c:Context,binding:WidgetBinding,snapshot:WidgetSnapshot,item:WidgetItem):PendingIntent {
        val payload=binding.json().put("mode","set").put("day",snapshot.day.toString())
            .put("revision",snapshot.revision).put("completed",!item.done)
            .put("expectedValue",(if(item.kind=="habit")item.value else item.doneDay) ?: JSONObject.NULL)
        if(WidgetBindings.kind(c,binding.widgetId)=="panel")payload.put("itemRevision",item.itemRevision)
        val data=Uri.Builder().scheme("daypanel-widget-action").authority(c.packageName)
            .appendPath(binding.widgetId.toString()).appendPath(binding.token).appendPath(binding.generation.toString())
            .appendPath(snapshot.day.toString()).appendPath(binding.kind).appendPath(binding.id).appendPath(item.itemRevision.toString()).appendPath(snapshot.revision.toString()).appendPath((!item.done).toString()).build()
        return PendingIntent.getBroadcast(c,0,Intent(c,WidgetActionReceiver::class.java).setData(data).putExtra("widget",payload.toString()),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
    fun render(c: Context, id: Int, snapshot: WidgetSnapshot?) {
        val manager = AppWidgetManager.getInstance(c)
        manager.updateAppWidget(id, views(c, id, snapshot, manager.getAppWidgetOptions(id)))
    }
    internal fun views(c: Context, id: Int, snapshot: WidgetSnapshot?, options: Bundle): RemoteViews {
        val binding = WidgetBindings.get(c, id)
        if(WidgetBindings.kind(c,id)=="panel")return PanelWidgets.views(c,id,binding,snapshot,options)
        val validBinding = binding?.takeIf { it.generation == snapshot?.generation }
        val item = validBinding?.let { snapshot?.items?.get("${it.kind}:${it.id}") }
        val zh = snapshot?.chinese ?: (c.resources.configuration.locales[0].language == "zh")
        fun t(chinese: String, english: String) = if (zh) chinese else english
        val day = snapshot?.day ?: LocalDate.now()
        val portrait = c.resources.configuration.orientation != Configuration.ORIENTATION_LANDSCAPE
        val width = options.getInt(if (portrait) AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH else AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 220)
        val height = options.getInt(if (portrait) AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT else AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 180)
        val scale = c.resources.configuration.fontScale
        val compact = width < 200 || height < 190 || scale > 1.3f
        val views = RemoteViews(c.packageName, if (compact) R.layout.daypanel_widget_compact else R.layout.daypanel_widget)
        val dark = snapshot?.dark ?: (c.resources.configuration.uiMode and 48 == 32)
        val ink = Color.parseColor(if (dark) "#EDF2FC" else "#22314A")
        val secondary = Color.parseColor(if (dark) "#A9B8CF" else "#687990")
        val complete = item != null && item.rest == null && !item.archived && item.done
        val accent = Color.parseColor(if (complete) { if (dark) "#A2DCCD" else "#276C5C" }
            else when(snapshot?.palette) { "apricot" -> if(dark) "#F6BD99" else "#9A431D"; "coast" -> if(dark) "#9BDCE4" else "#086F83"; "teal" -> if (dark) "#A2DCCD" else "#276C5C"; "violet" -> if (dark) "#CDBFFA" else "#7156A5"; else -> if (dark) "#B8CDFF" else "#2D5EB4" })
        views.setInt(R.id.widget_root, "setBackgroundResource", if (dark) R.drawable.widget_dark else R.drawable.widget_light)
        views.setInt(R.id.widget_action, "setBackgroundResource", if (complete) { if (dark) R.drawable.widget_action_done_dark else R.drawable.widget_action_done } else WidgetAppearance.action(snapshot?.palette ?: "blue"))
        views.setTextColor(R.id.widget_action, if (complete) accent else Color.WHITE)
        views.setTextColor(R.id.widget_title, ink)
        views.setTextColor(R.id.widget_state, if (item?.quantity == true || complete) accent else ink)
        views.setTextColor(R.id.widget_date, secondary)
        views.setTextColor(R.id.widget_hint, secondary)
        views.setImageViewResource(R.id.widget_settings, if (dark) R.drawable.widget_more_dark else R.drawable.widget_more)
        views.setImageViewResource(R.id.widget_details, if (dark) R.drawable.widget_open_dark else R.drawable.widget_open)
        val shortDate = if (width < 180) "%02d/%02d".format(day.monthValue, day.dayOfMonth)
            else day.format(java.time.format.DateTimeFormatter.ofPattern(if (zh) "M月d日 · E" else "MMM d · E", if (zh) java.util.Locale.SIMPLIFIED_CHINESE else java.util.Locale.ENGLISH))
        views.setTextViewText(R.id.widget_date, shortDate)
        views.setContentDescription(R.id.widget_date, day.toString())
        views.setContentDescription(R.id.widget_settings, t("配置桌面组件", "Configure widget"))
        views.setOnClickPendingIntent(R.id.widget_settings, pending(c, id, "configure", binding, day))
        views.setContentDescription(R.id.widget_details, t("查看详情", "View details"))
        views.setOnClickPendingIntent(R.id.widget_details, pending(c, id, if(item == null) "configure" else "view", binding, day))
        val showIcon = !compact || (width >= 240 && height >= 170 && scale <= 1.3f)
        views.setViewVisibility(R.id.widget_icon, if (showIcon && item != null) View.VISIBLE else View.GONE)
        if (showIcon && item != null && snapshot != null) {
            views.setImageViewBitmap(R.id.widget_icon, if (item.kind == "habit") WidgetAppearance.icon(c, item, snapshot) else WidgetAppearance.taskIcon(c, snapshot.dark, item.resident))
        }
        val importantHint = item == null || item.archived || item.rest != null || item.kind == "task" || item.schedule in setOf("weekly","weeklyTotal") || !item.scheduled
        val showHint = importantHint && (!compact || height >= if (scale > 1.3f) 230 else 190)
        views.setViewVisibility(R.id.widget_hint, if (showHint) View.VISIBLE else View.GONE)
        views.setInt(R.id.widget_state, "setMaxLines", if (!compact || height >= 190) 2 else 1)
        views.setTextViewTextSize(R.id.widget_state, TypedValue.COMPLEX_UNIT_SP, if (compact) { if (width < 160) 15f else 20f } else if (item?.quantity == true) 28f else 21f)
        if (compact && scale > 1.3f) views.setTextViewTextSize(R.id.widget_title, TypedValue.COMPLEX_UNIT_SP, 14f)
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
                item.schedule == "weeklyTotal" -> t("本周累计 · ${item.unit}","Weekly total · ${item.unit}")
                item.schedule == "weekly" -> t("本周 ${item.weekCount}/${item.weekGoal} 天", "This week ${item.weekCount}/${item.weekGoal} days")
                !item.scheduled -> t("今天未安排", "Not scheduled today")
                else -> t("今天的安排", "Scheduled today")
            }
            state = when {
                item.archived -> t("已归档 · 查看记录", "Archived · view records")
                item.rest != null -> when(item.rest) { "skip" -> t("这天已跳过", "Skipped this day"); "vacation" -> t("休假中", "On a break"); else -> t("已暂停", "Paused") }
                item.schedule == "weeklyTotal" -> "${WidgetDisplayRules.quantity(item.weekTotal)} / ${WidgetDisplayRules.quantity(item.target)} ${item.unit}"
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
                "quantity" -> t("记录", "Record")
                "set" -> if(item.done) {
                    if(item.kind=="task" && !item.resident) t("重新待办","Reopen") else t("取消完成","Mark undone")
                } else t("完成", "Complete")
                "configure" -> t("打开更新","Open to update")
                else -> t("查看记录", "View records")
            }
        }
        views.setTextViewText(R.id.widget_title, title)
        val displayState: CharSequence = if (item?.quantity == true && item.rest == null && !item.archived) {
            SpannableString(state).apply {
                val slash = state.indexOf(" /")
                if (slash >= 0) {
                    setSpan(RelativeSizeSpan(if (compact) .8f else .6f), slash, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                    setSpan(ForegroundColorSpan(secondary), slash, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                    setSpan(StyleSpan(Typeface.NORMAL), slash, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                }
            }
        } else if (item?.kind == "task" && !item.archived && item.rest == null) {
            if (item.resident) { if (item.done) t("今天已做", "Done today") else t("今天未记录", "Not yet today") }
            else if (item.done) t("已完成", "Completed") else t("待处理", "To do")
        } else state
        val displayHint = if (item?.kind == "task" && !item.archived && item.rest == null) {
            if (item.resident) t("常驻 · 按需记录", "Resident · as needed")
            else if (item.doneDay != null) t("完成于 ${item.doneDay}", "Done ${item.doneDay}")
            else if (item.dueDay != null) t("安排于 ${item.dueDay}", "Due ${item.dueDay}")
            else t("一次性 · 未设日期", "One-time · no date")
        } else hint
        views.setTextViewText(R.id.widget_hint, displayHint)
        views.setTextViewText(R.id.widget_state, displayState)
        val showProgress = item != null && item.kind == "habit" && !item.archived && item.rest == null &&
            (item.quantity || item.schedule == "weekly") && (!compact || height >= if (scale > 1.3f) 210 else 160)
        views.setViewVisibility(R.id.widget_progress, if (showProgress) View.VISIBLE else View.GONE)
        if (showProgress && item != null) {
            val ratio = if (item.quantity) (if(item.schedule == "weeklyTotal") item.weekTotal else item.value ?: 0L).toDouble() / item.target.coerceAtLeast(1L)
                else item.weekCount.toDouble() / item.weekGoal.coerceAtLeast(1)
            views.setImageViewBitmap(R.id.widget_progress, WidgetAppearance.progress(ratio, accent, dark))
        }
        val status=WidgetActionStatus.get(c,id)
        val shortAction = if (width < 180 || scale > 1.3f) when(mode) {
            "set" -> if (item?.done == true) t("撤销", "Undo") else t("完成", "Done")
            "quantity" -> t("记录", "Record")
            "configure" -> t("选择", "Choose")
            else -> t("查看", "View")
        } else action
        val actionLabel=when(status){"pending"->t("保存中", "Saving");"failed"->t("重试","Retry");else->shortAction}
        views.setTextViewText(R.id.widget_action, actionLabel)
        if(status=="failed") {
            views.setTextViewText(R.id.widget_state,t("未能保存，请重试","Could not save. Try again"))
        }
        views.setContentDescription(R.id.widget_content, "$title. $day. $state. $hint")
        views.setContentDescription(R.id.widget_action, "$actionLabel. $title. $day")
        val primary=if(mode=="set" && validBinding!=null && snapshot!=null && item!=null) direct(c,validBinding,snapshot,item) else pending(c,id,mode,binding,day)
        views.setOnClickPendingIntent(R.id.widget_heading, primary)
        views.setOnClickPendingIntent(R.id.widget_content, primary)
        views.setOnClickPendingIntent(R.id.widget_action, primary)
        return views
    }
}
