package app.daypanel.next.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.os.Bundle
import android.widget.RemoteViews
import app.daypanel.next.R
import org.json.JSONArray
import java.time.LocalDate

object PanelWidgets {
    fun rows(encoded:String):List<Pair<String,String>> = try {
        val a=JSONArray(encoded)
        if(a.length() !in 1..4) emptyList() else (0 until a.length()).map {
            val row=a.getJSONObject(it);require(row.length()==2)
            val kind=row.getString("kind");val id=row.getString("id")
            require(kind in listOf("habit","task") && id.isNotBlank() && id.length<=128)
            kind to id
        }
    } catch(_:Exception){emptyList()}
    fun views(c:Context,id:Int,binding:WidgetBinding?,snap:WidgetSnapshot?,options:Bundle):RemoteViews {
        val zh=snap?.chinese ?: (c.resources.configuration.locales[0].language=="zh")
        fun t(a:String,b:String)=if(zh)a else b
        val dark=snap?.dark ?: false; val day=snap?.day ?: LocalDate.now()
        val ink=Color.parseColor(if(dark)"#EDF2FA" else "#18223B")
        val muted=Color.parseColor(if(dark)"#A3B3CC" else "#637089")
        val views=RemoteViews(c.packageName,R.layout.daypanel_panel)
        views.setInt(R.id.panel_root,"setBackgroundResource",if(dark)R.drawable.widget_dark else R.drawable.widget_light)
        views.setTextColor(R.id.panel_date,ink);views.setTextColor(R.id.panel_footer,muted);views.setTextColor(R.id.panel_settings,muted)
        views.setTextViewText(R.id.panel_date,day.toString());views.setContentDescription(R.id.panel_date,day.toString())
        views.setContentDescription(R.id.panel_settings,t("配置组合面板","Configure combined widget"))
        val configure=WidgetEngine.pending(c,id,"configure",binding,day)
        views.setOnClickPendingIntent(R.id.panel_settings,configure)
        val valid=binding!=null && snap!=null && binding.generation==snap.generation
        val all=if(valid)rows(binding!!.id)else emptyList()
        val owned=WidgetBindings.plus(c)
        val portrait=c.resources.configuration.orientation!=Configuration.ORIENTATION_LANDSCAPE
        val height=options.getInt(if(portrait)AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT else AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,330)
        val width=options.getInt(if(portrait)AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH else AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH,280)
        val rowHeight=if(c.resources.configuration.fontScale>1.3f)96 else 68
        val visible=((height-120)/rowHeight).coerceIn(1,4)
        views.removeAllViews(R.id.panel_rows)
        for((kind,itemId) in all.take(visible)) {
            val item=snap!!.items["$kind:$itemId"]
            val row=RemoteViews(c.packageName,R.layout.daypanel_panel_row)
            row.setTextColor(R.id.panel_row_title,ink);row.setTextColor(R.id.panel_row_state,muted)
            row.setViewVisibility(R.id.panel_row_icon,if(width>=250 && item!=null)android.view.View.VISIBLE else android.view.View.GONE)
            if(width>=250 && item!=null)row.setImageViewBitmap(R.id.panel_row_icon,if(item.kind=="habit")WidgetAppearance.icon(c,item,snap)else WidgetAppearance.taskIcon(c,dark,item.resident))
            val title=item?.title ?: t("内容不存在","Item unavailable")
            val state=when {
                item==null -> t("请重新选择","Choose again")
                item.archived -> t("已归档","Archived")
                item.rest!=null -> t("休息中","On a break")
                item.schedule=="weeklyTotal" -> t("本周 ","Week ")+"${WidgetDisplayRules.quantity(item.weekTotal)} / ${WidgetDisplayRules.quantity(item.target)} ${item.unit}"
                item.quantity -> "${item.value?.let{WidgetDisplayRules.quantity(it)} ?: "—"} / ${WidgetDisplayRules.quantity(item.target)} ${item.unit}"
                item.schedule=="weekly" -> t("本周 ${item.weekCount}/${item.weekGoal} 天","Week ${item.weekCount}/${item.weekGoal} days")
                item.resident -> if(item.done)t("常驻 · 今天已做","Resident · done") else t("常驻 · 今天未记","Resident · not yet")
                item.done -> t("已完成","Completed")
                else -> t("待完成","To do")
            }
            row.setTextViewText(R.id.panel_row_title,title);row.setTextViewText(R.id.panel_row_state,state)
            row.setContentDescription(R.id.panel_row_body,"$title. $day. $state")
            val rowBinding=binding!!.copy(kind=kind,id=itemId)
            val mode=when{item==null->"configure";!owned||item.archived||item.rest!=null->"view";item.quantity->"quantity";else->"set"}
            val label=when(mode){"quantity"->t("记录","Log");"set"->if(item!!.done)t("撤销","Undo") else t("完成","Done");"configure"->t("选择","Choose");else->t("查看","View")}
            val action=if(mode=="set")WidgetEngine.direct(c,rowBinding,snap,item!!)else WidgetEngine.pending(c,id,mode,if(mode=="configure")binding else rowBinding,day)
            row.setTextViewText(R.id.panel_row_action,label);row.setContentDescription(R.id.panel_row_action,"$label. $title. $day. $state")
            row.setInt(R.id.panel_row_action,"setBackgroundResource",if(item?.done==true)if(dark)R.drawable.widget_action_done_dark else R.drawable.widget_action_done else WidgetAppearance.action(snap.palette))
            row.setTextColor(R.id.panel_row_action,if(item?.done==true)Color.parseColor(if(dark)"#A2DCCD" else "#246B60")else Color.WHITE)
            row.setOnClickPendingIntent(R.id.panel_row_action,action)
            row.setOnClickPendingIntent(R.id.panel_row_body,action)
            views.addView(R.id.panel_rows,row)
        }
        val status=WidgetActionStatus.get(c,id)
        val text=when {
            !valid || all.isEmpty() -> t("选择 1–4 个事项","Choose 1–4 items")
            !owned -> t("查看全部 · Plus","View all · Plus")
            status=="pending" -> t("正在保存…","Saving…")
            status=="stale" -> t("已更新，请重新操作","Updated. Please try again")
            status=="failed" -> t("未能保存，请重试","Could not save. Try again")
            all.size>visible -> t("还有 ${all.size-visible} 项 · 查看全部","${all.size-visible} more · View all")
            else -> t("查看全部","View all")
        }
        views.setTextViewText(R.id.panel_footer,text)
        views.setOnClickPendingIntent(R.id.panel_footer,if(valid)WidgetEngine.pending(c,id,"panelView",binding,day)else configure)
        return views
    }
}
