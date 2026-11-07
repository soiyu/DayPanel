package app.daypanel.next.widgets

import android.content.Context
import android.graphics.*
import app.daypanel.next.R

object WidgetAppearance {
    fun icon(c: Context, item: WidgetItem, snapshot: WidgetSnapshot): Bitmap {
        val size = (48 * c.resources.displayMetrics.density).toInt()
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val dark = snapshot.dark
        val name = if (item.color == "auto") when(item.icon) { 0,10,16,18 -> "peach"; 2,4,13,19,23 -> "rose"; 5,7,12,21 -> "violet"; 3,9,11,17,20 -> "teal"; else -> "blue" } else item.color
        val color = Color.parseColor(when(name) {
            "teal" -> if(dark) "#9DDACD" else "#146A5B"
            "rose" -> if(dark) "#F5B8CF" else "#9D365D"
            "violet" -> if(dark) "#D1BEFF" else "#7252BE"
            "peach" -> if(dark) "#FFC395" else "#A95824"
            else -> if(dark) "#AFC5FF" else "#1656DF"
        })
        val frame = if(item.frame == "auto") snapshot.frame else item.frame
        paint.color = color
        val rect = RectF(2f, 2f, size-2f, size-2f)
        if(frame == "ring") {
            paint.style=Paint.Style.STROKE;paint.strokeWidth=1.6f*c.resources.displayMetrics.density
            canvas.drawOval(rect,paint)
        } else if(frame == "soft") {
            paint.alpha=if(dark) 36 else 22
            canvas.drawRoundRect(rect,size*.32f,size*.32f,paint)
        }
        val asset="flutter_assets/assets/habit_icons/%02d.png".format(java.util.Locale.ROOT,item.icon.coerceIn(0,23))
        c.assets.open(asset).use { stream ->
            val art=BitmapFactory.decodeStream(stream) ?: error("Missing habit artwork")
            paint.reset();paint.isAntiAlias=true;paint.isFilterBitmap=true
            canvas.drawBitmap(art,null,RectF(0f,0f,size.toFloat(),size.toFloat()),paint)
            art.recycle()
        }
        return bitmap
    }
    fun action(palette:String):Int = when(palette) {
        "teal" -> R.drawable.widget_action_teal
        "violet" -> R.drawable.widget_action_violet
        else -> R.drawable.widget_action
    }
}
