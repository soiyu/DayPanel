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
    fun progress(ratio: Double, accent: Int, dark: Boolean): Bitmap {
        val bitmap = Bitmap.createBitmap(800, 12, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.color = Color.parseColor(if (dark) "#34425B" else "#E0E7F2")
        canvas.drawRoundRect(RectF(0f, 0f, 800f, 12f), 6f, 6f, paint)
        paint.color = accent
        val length = (ratio.coerceIn(0.0, 1.0) * 800).toFloat()
        if (length > 0) canvas.drawRoundRect(RectF(0f, 0f, length, 12f), minOf(6f, length / 2), minOf(6f, length / 2), paint)
        return bitmap
    }

    fun taskIcon(c: Context, dark: Boolean, resident: Boolean): Bitmap {
        val size = (48 * c.resources.displayMetrics.density).toInt()
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.scale(size / 48f, size / 48f)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.color = Color.parseColor(if (dark) "#2C4548" else "#E8F3F0")
        canvas.drawRoundRect(RectF(0f, 0f, 48f, 48f), 14f, 14f, paint)
        paint.color = Color.parseColor(if (dark) "#A2DCCD" else "#387868")
        paint.style = Paint.Style.STROKE; paint.strokeWidth = 2.2f; paint.strokeCap = Paint.Cap.ROUND; paint.strokeJoin = Paint.Join.ROUND
        canvas.drawRoundRect(RectF(12f, 10f, 36f, 38f), 4f, 4f, paint)
        canvas.drawLine(21f, 19f, 29f, 19f, paint)
        canvas.drawLine(21f, 27f, 29f, 27f, paint)
        val tick = Path().apply { moveTo(15.5f, 18f); lineTo(17f, 20f); lineTo(19f, 16.5f) }
        canvas.drawPath(tick, paint)
        paint.style = Paint.Style.FILL
        paint.color = Color.parseColor(if (resident) "#B4A1E6" else "#EEB578")
        canvas.drawCircle(36f, 12f, 5f, paint)
        return bitmap
    }
    fun action(palette:String):Int = when(palette) {
        "teal" -> R.drawable.widget_action_teal
        "violet" -> R.drawable.widget_action_violet
        else -> R.drawable.widget_action
    }
}
