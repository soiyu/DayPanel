package app.daypanel.next.widgets

import android.content.Context
import android.graphics.*
import app.daypanel.next.R

object WidgetAppearance {
    // Material Icons codepoints used by the same constant Flutter icon list.
    // The font ships with Flutter; all these glyphs are referenced and retained.
    private val icons = intArrayOf(0xf4bc, 0xf0695, 0xf8b4, 0xf6bd, 0xf737, 0xf216, 0xf767, 0xf0144, 0xf6b8, 0xf0059, 0xf316, 0xf17b, 0xf1fb, 0xef02, 0xf00d, 0xf83f, 0xf336, 0xef56, 0xf285, 0xef68, 0xf1bf, 0xeecb, 0xf289, 0xf4a9)
    fun icon(c: Context, item: WidgetItem, snapshot: WidgetSnapshot): Bitmap {
        val size = (48 * c.resources.displayMetrics.density).toInt()
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val dark = snapshot.dark
        val name = if (item.color == "auto") when(item.icon % 6) { 0,3 -> "peach"; 2,5 -> "violet"; else -> "blue" } else item.color
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
        paint.style=Paint.Style.FILL;paint.color=color;paint.textSize=size*.52f;paint.textAlign=Paint.Align.CENTER
        paint.typeface=Typeface.createFromAsset(c.assets,"flutter_assets/fonts/MaterialIcons-Regular.otf")
        val glyph=String(Character.toChars(icons.getOrElse(item.icon){icons[0]}))
        canvas.drawText(glyph,size/2f,size/2f-(paint.ascent()+paint.descent())/2f,paint)
        return bitmap
    }
    fun action(palette:String):Int = when(palette) {
        "teal" -> R.drawable.widget_action_teal
        "violet" -> R.drawable.widget_action_violet
        else -> R.drawable.widget_action
    }
}
