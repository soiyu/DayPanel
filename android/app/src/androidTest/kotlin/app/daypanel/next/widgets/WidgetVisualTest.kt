package app.daypanel.next.widgets

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Rect
import android.net.Uri
import android.os.Bundle
import android.os.LocaleList
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.test.platform.app.InstrumentationRegistry
import app.daypanel.next.R
import org.junit.After
import org.junit.Assert.*
import org.junit.Assume
import org.junit.Before
import org.junit.Test
import java.io.FileInputStream
import java.time.LocalDate
import java.util.Locale
import kotlin.math.roundToInt

/** Real RemoteViews inflation and measurement; only disposable host bindings are created. */
class WidgetVisualTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val target = instrumentation.targetContext
    private val host = AppWidgetHost(target, 1805)
    private val ids = mutableMapOf<String, Int>()
    private val day = LocalDate.of(2026, 11, 8)
    private val generation = 71L
    private val numeric = WidgetItem(
        "visual-fixture", "habit", "Read a little more of a favourite book", false,
        quantity = true, value = 6000, target = 10000, unit = "pages", icon = 2,
    )

    @Before fun setup() {
        val user = android.os.Process.myUid() / 100000
        Assume.assumeTrue("Run in a temporary Android user", user != 0)
        shell("appwidget grantbind --package ${target.packageName} --user $user")
    }

    @After fun cleanup() {
        ids.values.forEach { id ->
            WidgetBindings.remove(target, id)
            host.deleteAppWidgetId(id)
            target.getSharedPreferences("widget_action_status", 0).edit()
                .remove(id.toString()).remove("$id-at").commit()
        }
        val user = android.os.Process.myUid() / 100000
        if (user != 0) shell("appwidget revokebind --package ${target.packageName} --user $user")
    }

    private fun shell(command: String) {
        instrumentation.uiAutomation.executeShellCommand(command).use {
            FileInputStream(it.fileDescriptor).readBytes()
        }
    }

    private fun context(zh: Boolean, dark: Boolean, scale: Float): Context {
        val config = Configuration(target.resources.configuration).apply {
            fontScale = scale
            orientation = Configuration.ORIENTATION_PORTRAIT
            setLocales(LocaleList(if (zh) Locale.SIMPLIFIED_CHINESE else Locale.US))
            uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or
                (if (dark) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO)
        }
        return target.createConfigurationContext(config)
    }

    private fun id(kind: String): Int = ids.getOrPut(kind) {
        val widgetId = host.allocateAppWidgetId()
        val provider = if (kind == "task") TaskWidgetProvider::class.java else HabitWidgetProvider::class.java
        assertTrue(AppWidgetManager.getInstance(target).bindAppWidgetIdIfAllowed(widgetId, ComponentName(target, provider)))
        val binding = WidgetBinding(widgetId, kind, numeric.id, generation, "visual-$widgetId")
        target.contentResolver.call(
            Uri.parse("content://${target.packageName}.widget-bindings"), "put", widgetId.toString(),
            Bundle().apply { putString("value", binding.json().toString()) },
        )
        widgetId
    }

    private fun render(
        c: Context,
        item: WidgetItem?,
        width: Int = 280,
        height: Int = 300,
        zh: Boolean = false,
        dark: Boolean = false,
    ): ViewGroup {
        val widgetId = id(item?.kind ?: "habit")
        val snapshot = WidgetSnapshot(
            generation, day, zh, dark,
            if (item == null) emptyMap() else mapOf("${item.kind}:${item.id}" to item),
            revision = 4,
        )
        val options = Bundle().apply {
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, width)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, width)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, height)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, height)
        }
        val view = WidgetEngine.views(c, widgetId, snapshot, options).apply(c, FrameLayout(c)) as ViewGroup
        val density = c.resources.displayMetrics.density
        val pixelsWide = (width * density).roundToInt()
        val pixelsHigh = (height * density).roundToInt()
        view.measure(
            View.MeasureSpec.makeMeasureSpec(pixelsWide, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(pixelsHigh, View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, pixelsWide, pixelsHigh)
        return view
    }

    private fun bounds(root: ViewGroup, view: View): Rect = Rect().also {
        view.getDrawingRect(it)
        root.offsetDescendantRectToMyCoords(view, it)
    }

    private fun assertInside(root: ViewGroup, view: View) {
        val rect = bounds(root, view)
        val name = target.resources.getResourceEntryName(view.id)
        assertTrue("$name is visible", view.visibility == View.VISIBLE)
        assertTrue("$name has area: $rect", rect.width() > 0 && rect.height() > 0)
        assertTrue("$name stays inside ${root.width}x${root.height}: $rect",
            rect.left >= 0 && rect.top >= 0 && rect.right <= root.width && rect.bottom <= root.height)
    }

    private fun assertTouchTarget(root: ViewGroup, view: View, density: Float) {
        assertInside(root, view)
        val rect = bounds(root, view)
        val minimum = (48 * density).roundToInt()
        assertTrue("Touch width is at least 48dp: $rect", rect.width() >= minimum)
        assertTrue("Touch height is at least 48dp: $rect", rect.height() >= minimum)
        assertTrue("Visible action remains wired", view.hasOnClickListeners())
        assertFalse("Action is announced", view.contentDescription.isNullOrBlank())
    }

    @Test fun narrowWideAndLargeTextKeepControlsReachableWithoutOverlap() {
        instrumentation.runOnMainSync {
            val sizes = listOf(
                Triple(128, 140, 1f), Triple(180, 200, 1f),
                Triple(160, 200, 1.6f), Triple(280, 240, 1.6f),
                Triple(320, 180, 1f), Triple(280, 300, 1f),
            )
            for (zh in listOf(false, true)) for (dark in listOf(false, true)) {
                for ((width, height, scale) in sizes) {
                    val c = context(zh, dark, scale)
                    val item = numeric.copy(
                        title = if (zh) "阅读一本很喜欢的长篇小说并记录今天读过的页数" else numeric.title,
                        unit = if (zh) "页" else "pages",
                    )
                    val root = render(c, item, width, height, zh, dark)
                    val action = root.findViewById<TextView>(R.id.widget_action)
                    val settings = root.findViewById<ImageView>(R.id.widget_settings)
                    val details = root.findViewById<ImageView>(R.id.widget_details)
                    val density = c.resources.displayMetrics.density
                    listOf(action, settings, details).forEach { assertTouchTarget(root, it, density) }
                    assertNotNull("Settings is a drawn icon", settings.drawable)
                    assertNotNull("Details is a drawn icon", details.drawable)
                    assertFalse("Main and details targets do not overlap", Rect.intersects(bounds(root, action), bounds(root, details)))
                    assertFalse("Settings and main targets do not overlap", Rect.intersects(bounds(root, settings), bounds(root, action)))
                    val title = root.findViewById<TextView>(R.id.widget_title)
                    val state = root.findViewById<TextView>(R.id.widget_state)
                    assertInside(root, title)
                    assertInside(root, state)
                    assertFalse("Title and state do not overlap", Rect.intersects(bounds(root, title), bounds(root, state)))
                    assertTrue("Record text does not run into controls", bounds(root, state).bottom <= bounds(root, action).top)
                    assertEquals("6 / 10 ${item.unit}", state.text.toString())
                    val description = root.findViewById<View>(R.id.widget_content).contentDescription.toString()
                    assertTrue("Full title survives visual truncation", description.contains(item.title))
                    assertTrue("Date remains unambiguous", description.contains(day.toString()))
                    assertTrue("Actual amount is announced", description.contains("6 / 10 ${item.unit}"))
                }
            }
        }
    }

    private fun assertTextLayoutFits(root: ViewGroup, text: TextView, allowEllipsis: Boolean) {
        assertInside(root, text)
        val layout = text.layout
        assertNotNull("Text has a laid out glyph run", layout)
        requireNotNull(layout)
        val name = target.resources.getResourceEntryName(text.id)
        assertTrue("$name retains at least one visible text line", layout.lineCount > 0)
        val availableHeight = text.height - text.compoundPaddingTop - text.compoundPaddingBottom
        val lastLine = layout.lineCount - 1
        assertTrue("$name glyph layout fits its visible height: ${layout.getLineBottom(lastLine)} > $availableHeight",
            layout.getLineTop(0) >= 0 && layout.getLineBottom(lastLine) <= availableHeight + 1)
        assertTrue("$name does not hide excess text lines", layout.lineCount <= text.maxLines)
        if (!allowEllipsis) {
            for (line in 0 until layout.lineCount) {
                assertEquals("$name should remain readable without ellipsis", 0, layout.getEllipsisCount(line))
            }
            assertEquals("$name lays out all of its label", text.text.length, layout.getLineEnd(lastLine))
        }
    }

    @Test fun alreadyPreparedStandardViewsReinflateAtLargeFontWithoutClippedText() {
        instrumentation.runOnMainSync {
            // The Launcher may re-inflate an existing RemoteViews when the user changes
            // font size before DayPanel receives a configuration-change refresh.
            for (zh in listOf(false, true)) for (dark in listOf(false, true)) {
                val normal = context(zh, dark, 1f)
                val enlarged = context(zh, dark, 1.6f)
                val item = numeric.copy(
                    title = if (zh) "阅读一本很喜欢的长篇小说" else "Read a favourite book",
                    unit = if (zh) "页" else "pages",
                )
                for ((width, height) in listOf(220 to 196, 280 to 200)) {
                    val options = Bundle().apply {
                        putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, width)
                        putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, width)
                        putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, height)
                        putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, height)
                    }
                    val snapshot = WidgetSnapshot(generation, day, zh, dark,
                        mapOf("habit:${item.id}" to item), revision = 4)
                    // Deliberately prepare at 100%; do not ask Engine for a compact
                    // layout at 160%, which would mask the stale-layout regression.
                    val prepared = WidgetEngine.views(normal, id("habit"), snapshot, options)
                    val root = prepared.apply(enlarged, FrameLayout(enlarged)) as ViewGroup
                    val density = enlarged.resources.displayMetrics.density
                    val pixelsWide = (width * density).roundToInt()
                    val pixelsHigh = (height * density).roundToInt()
                    repeat(2) {
                        root.measure(
                            View.MeasureSpec.makeMeasureSpec(pixelsWide, View.MeasureSpec.EXACTLY),
                            View.MeasureSpec.makeMeasureSpec(pixelsHigh, View.MeasureSpec.EXACTLY),
                        )
                        root.layout(0, 0, pixelsWide, pixelsHigh)
                    }
                    val title = root.findViewById<TextView>(R.id.widget_title)
                    val state = root.findViewById<TextView>(R.id.widget_state)
                    val date = root.findViewById<TextView>(R.id.widget_date)
                    val action = root.findViewById<TextView>(R.id.widget_action)
                    assertEquals("Inflated views really use enlarged font resources", 1.6f,
                        title.resources.configuration.fontScale, .001f)
                    assertTextLayoutFits(root, title, allowEllipsis = true)
                    assertTextLayoutFits(root, date, allowEllipsis = false)
                    assertTextLayoutFits(root, state, allowEllipsis = false)
                    assertTextLayoutFits(root, action, allowEllipsis = false)
                    assertEquals("6 / 10 ${item.unit}", state.text.toString())
                    assertInside(root, root.findViewById(R.id.widget_progress))
                    assertTrue("Progress remains between the actual amount and the action",
                        bounds(root, state).bottom <= bounds(root, root.findViewById(R.id.widget_progress)).top &&
                        bounds(root, root.findViewById(R.id.widget_progress)).bottom <= bounds(root, action).top)
                    listOf<View>(action, root.findViewById(R.id.widget_settings), root.findViewById(R.id.widget_details))
                        .forEach { assertTouchTarget(root, it, density) }
                    val description = root.findViewById<View>(R.id.widget_content).contentDescription.toString()
                    assertTrue(description.contains(item.title))
                    assertTrue(description.contains(day.toString()))
                }
            }
        }
    }

    private fun rail(root: ViewGroup): Bitmap {
        val image = root.findViewById<ImageView>(R.id.widget_progress)
        assertInside(root, image)
        assertNotNull("Numeric progress has a drawable", image.drawable)
        return Bitmap.createBitmap(image.width, image.height, Bitmap.Config.ARGB_8888).also {
            image.draw(Canvas(it))
        }
    }

    private fun changedColumns(base: Bitmap, other: Bitmap): Int {
        assertEquals(base.width, other.width)
        assertEquals(base.height, other.height)
        val y = base.height / 2
        return (0 until base.width).count { x -> base.getPixel(x, y) != other.getPixel(x, y) }
    }

    @Test fun numericRailTracksActualAmountAndCapsAtGoalWithoutHidingOverachievement() {
        instrumentation.runOnMainSync {
            val c = context(false, false, 1f)
            val zero = rail(render(c, numeric.copy(value = 0)))
            val partial = rail(render(c, numeric))
            val full = rail(render(c, numeric.copy(value = 10000)))
            val overRoot = render(c, numeric.copy(value = 15000))
            val over = rail(overRoot)
            val partialColumns = changedColumns(zero, partial)
            val fullColumns = changedColumns(zero, full)
            assertTrue("Progress is visible at the goal", fullColumns > zero.width * .8)
            assertTrue("Six of ten is visibly partial", partialColumns in (fullColumns * .45).toInt()..(fullColumns * .75).toInt())
            assertEquals("Progress rail caps at 100%", 0, changedColumns(full, over))
            assertEquals("15 / 10 pages", overRoot.findViewById<TextView>(R.id.widget_state).text.toString())
            listOf(zero, partial, full, over).forEach(Bitmap::recycle)
        }
    }

    @Test fun tasksRestArchiveAndMissingContentNeverShowInventedQuantityProgress() {
        instrumentation.runOnMainSync {
            val c = context(false, false, 1f)
            val states = listOf(
                numeric.copy(rest = "pause") to "Paused",
                numeric.copy(archived = true) to "Archived · view records",
                WidgetItem(numeric.id, "task", "Clean when needed", false, resident = true) to "Not yet today",
                WidgetItem(numeric.id, "task", "Clean when needed", false, resident = true, doneDay = day.toString()) to "Done today",
                WidgetItem(numeric.id, "task", "Post a parcel", false, doneDay = "2026-11-07") to "Completed",
            )
            for ((item, expected) in states) {
                val root = render(c, item)
                assertEquals(expected, root.findViewById<TextView>(R.id.widget_state).text.toString())
                assertEquals("No numeric goal is invented for this state", View.GONE, root.findViewById<View>(R.id.widget_progress).visibility)
                assertTouchTarget(root, root.findViewById(R.id.widget_action), c.resources.displayMetrics.density)
                if (item.kind == "task") {
                    val semantics = root.findViewById<View>(R.id.widget_content).contentDescription.toString()
                    assertTrue("Task type remains accessible", semantics.contains(if (item.resident) "Resident" else "One-time"))
                    if (item.doneDay != null) assertTrue("Actual completion date remains accessible", semantics.contains(item.doneDay))
                }
            }
            val missing = render(c, null)
            assertEquals(View.GONE, missing.findViewById<View>(R.id.widget_progress).visibility)
            assertEquals("Content changed. Choose again", missing.findViewById<TextView>(R.id.widget_state).text.toString())
            assertFalse(missing.findViewById<View>(R.id.widget_action).contentDescription.isNullOrBlank())
        }
    }

    @Test fun resizingPreservesNumericFactAndDistinctConfigurationAndDetailActions() {
        instrumentation.runOnMainSync {
            val c = context(false, true, 1f)
            val wide = render(c, numeric, 320, 180, dark = true)
            val tall = render(c, numeric, 280, 300, dark = true)
            val narrow = render(c, numeric, 128, 140, dark = true)
            for (root in listOf(wide, tall, narrow)) {
                assertEquals("6 / 10 pages", root.findViewById<TextView>(R.id.widget_state).text.toString())
                assertEquals("Configure widget", root.findViewById<View>(R.id.widget_settings).contentDescription.toString())
                assertEquals("View details", root.findViewById<View>(R.id.widget_details).contentDescription.toString())
                assertTrue(root.findViewById<View>(R.id.widget_content).hasOnClickListeners())
                assertTrue(root.findViewById<View>(R.id.widget_action).hasOnClickListeners())
            }
            assertEquals(1, ids.size)
        }
    }
}
