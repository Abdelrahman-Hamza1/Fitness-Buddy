package io.github.abdelrahmanhamza1.fitnessbuddy

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** A73: which widget layout at which size (WidgetSizing.kt). Host JVM only. */
class HomeWidgetSizingTest {
    private fun choose(family: WidgetFamily, w: Int, h: Int) =
        WidgetSizing.choose(family, w.toFloat(), h.toFloat())

    @Test
    fun `A73 UX-082 medium picks the row at 4x1 and grows with the cells`() {
        // Stock launcher 4 x 1 and One UI 4 x 1 (cells ~90-110 dp tall).
        assertEquals(WidgetVariant.MEDIUM_ROW, choose(WidgetFamily.MEDIUM, 300, 80))
        assertEquals(WidgetVariant.MEDIUM_ROW, choose(WidgetFamily.MEDIUM, 370, 110))
        // A small 4 x 2 and a One UI 4 x 2.
        assertEquals(WidgetVariant.MEDIUM_REGULAR, choose(WidgetFamily.MEDIUM, 300, 150))
        assertEquals(WidgetVariant.MEDIUM_LARGE, choose(WidgetFamily.MEDIUM, 360, 210))
        // Tall but narrow stays regular: the large one needs its width.
        assertEquals(WidgetVariant.MEDIUM_REGULAR, choose(WidgetFamily.MEDIUM, 300, 400))
    }

    @Test
    fun `A73 UX-082 numbers picks a row at 2x1 and the ring above protein at 2x2`() {
        assertEquals(WidgetVariant.NUMBERS_ROW, choose(WidgetFamily.NUMBERS, 120, 70))
        assertEquals(WidgetVariant.NUMBERS_ROW_LARGE, choose(WidgetFamily.NUMBERS, 175, 100))
        assertEquals(WidgetVariant.NUMBERS_REGULAR, choose(WidgetFamily.NUMBERS, 130, 130))
        assertEquals(WidgetVariant.NUMBERS_LARGE, choose(WidgetFamily.NUMBERS, 175, 210))
        // Wide and short: the large row, not the ring above protein.
        assertEquals(WidgetVariant.NUMBERS_ROW_LARGE, choose(WidgetFamily.NUMBERS, 300, 100))
    }

    @Test
    fun `A73 UX-082 buttons get labels once they are tall enough`() {
        assertEquals(WidgetVariant.BUTTONS_REGULAR, choose(WidgetFamily.BUTTONS, 130, 50))
        assertEquals(WidgetVariant.BUTTONS_LARGE, choose(WidgetFamily.BUTTONS, 175, 100))
    }

    @Test
    fun `A73 exact minimums fit, smaller falls back to the smallest, unknown is regular`() {
        for (v in WidgetVariant.entries) {
            assertEquals(v.name, v, WidgetSizing.choose(v.family, v.widthDp, v.heightDp))
        }
        for (family in WidgetFamily.entries) {
            val smallest = WidgetSizing.variants(family).first()
            assertEquals(smallest, choose(family, 10, 10))
            assertEquals(WidgetSizing.regular(family), choose(family, 0, 0))
            assertEquals(WidgetSizing.regular(family), choose(family, 0, 500))
        }
    }

    @Test
    fun `A73 the smallest variant is the smallest on both axes, so every allowed size has a variant whose declared size fits`() {
        for (family in WidgetFamily.entries) {
            val variants = WidgetSizing.variants(family)
            val smallest = variants.first()
            for (v in variants) {
                assertTrue("$v", smallest.widthDp <= v.widthDp && smallest.heightDp <= v.heightDp)
            }
            // A sweep of every size from the minimum up: the chosen variant's declared minimum fits.
            // (Declared sizes only; whether the content fits them is the layouts' header maths.)
            for (w in smallest.widthDp.toInt()..500 step 5) {
                for (h in smallest.heightDp.toInt()..500 step 5) {
                    val chosen = choose(family, w, h)
                    assertTrue("$family $w x $h -> $chosen", chosen.fitsIn(w.toFloat(), h.toFloat()))
                }
            }
            // Distinct sizes: the RemoteViews(Map) keys.
            assertEquals(variants.size, variants.map { it.widthDp to it.heightDp }.toSet().size)
            assertTrue(variants.size <= 16)
        }
    }

    @Test
    fun `A73 review fractional sizes follow Android's tolerance (ceil(actual) + 1 above the layout)`() {
        assertEquals(WidgetVariant.MEDIUM_LARGE, WidgetSizing.choose(WidgetFamily.MEDIUM, 319.5f, 184f))
        assertEquals(WidgetVariant.MEDIUM_LARGE, WidgetSizing.choose(WidgetFamily.MEDIUM, 319.01f, 183.2f))
        assertEquals(WidgetVariant.MEDIUM_REGULAR, WidgetSizing.choose(WidgetFamily.MEDIUM, 318.9f, 184f))
        assertEquals(WidgetVariant.MEDIUM_REGULAR, WidgetSizing.choose(WidgetFamily.MEDIUM, 319f, 184f))
        assertTrue(WidgetVariant.NUMBERS_ROW.fitsIn(109.2f, 63.5f))
        assertFalse(WidgetVariant.NUMBERS_ROW.fitsIn(108.9f, 64f))
    }

    @Test
    fun `A73 UX-085 every variant's face for numbers, hidden or no day, and signed out`() {
        for (v in WidgetVariant.entries) {
            val shown = WidgetFace.of(v, hasNumbers = true, signedOut = false)
            val none = WidgetFace.of(v, hasNumbers = false, signedOut = false)
            val out = WidgetFace.of(v, hasNumbers = false, signedOut = true)
            // Signed out never shows numbers, even with a stale day.
            assertEquals(v.name, out, WidgetFace.of(v, hasNumbers = true, signedOut = true))
            when (v.family) {
                WidgetFamily.BUTTONS -> for (f in listOf(shown, none, out)) {
                    assertEquals(v.name, WidgetFace(false, false, false, PlainText.NONE, true), f)
                }
                WidgetFamily.NUMBERS -> {
                    assertEquals(v.name, WidgetFace(true, true, false, PlainText.NONE, false), shown)
                    assertEquals(v.name, WidgetFace(true, false, true, PlainText.NONE, false), none)
                    assertEquals(v.name, WidgetFace(true, false, true, PlainText.OPEN_APP, false), out)
                }
                WidgetFamily.MEDIUM -> {
                    assertEquals(v.name, WidgetFace(true, false, true, PlainText.OPEN_APP, false), out)
                    if (v == WidgetVariant.MEDIUM_ROW) {
                        // One row: numbers without buttons; no numbers -> only the buttons.
                        assertEquals(WidgetFace(true, true, false, PlainText.NONE, false), shown)
                        assertEquals(WidgetFace(false, false, true, PlainText.PROMPT, true), none)
                    } else {
                        assertEquals(v.name, WidgetFace(true, true, false, PlainText.NONE, true), shown)
                        assertEquals(v.name, WidgetFace(true, false, true, PlainText.PROMPT, true), none)
                    }
                }
            }
        }
        assertEquals(
            setOf(WidgetVariant.MEDIUM_ROW, WidgetVariant.NUMBERS_ROW, WidgetVariant.NUMBERS_ROW_LARGE),
            WidgetVariant.entries.filter { it.compactMacros }.toSet(),
        )
    }

    // The res folder (Gradle runs host tests in the app module's folder).
    private val res = File("src/main/res")

    private fun attr(xml: String, name: String): Float =
        Regex("""android:$name="(\d+)dp"""").find(xml)!!.groupValues[1].toFloat()

    @Test
    fun `A73 D4 the provider XML advertises the smallest variant and defaults to the regular one`() {
        val files = mapOf(
            WidgetFamily.MEDIUM to "widget_medium_info.xml",
            WidgetFamily.NUMBERS to "widget_numbers_info.xml",
            WidgetFamily.BUTTONS to "widget_buttons_info.xml",
        )
        for ((family, file) in files) {
            val xml = File(res, "xml/$file").readText()
            val smallest = WidgetSizing.variants(family).first()
            val regular = WidgetSizing.regular(family)
            assertEquals(file, smallest.widthDp, attr(xml, "minResizeWidth"))
            assertEquals(file, smallest.heightDp, attr(xml, "minResizeHeight"))
            assertEquals(file, regular.widthDp, attr(xml, "minWidth"))
            assertEquals(file, regular.heightDp, attr(xml, "minHeight"))
        }
    }

    @Test
    fun `A73 D5 every layout declares the view ids the render path sets`() {
        val macros = listOf("protein", "carbs", "fat", "fiber")
            .flatMap { listOf("${it}_value", "${it}_bar", "${it}_over") }
        val ring = listOf("ring", "ring_over", "ring_value", "ring_caption", "numbers_block", "plain_block",
            "plain_text")
        val medium = ring + macros + listOf("widget_body", "buttons", "button_speak", "button_ask", "button_weigh")
        val numbers = ring + listOf("protein_value", "protein_bar", "protein_over")
        val layouts = mapOf(
            WidgetVariant.MEDIUM_ROW to ("widget_medium_row" to medium),
            WidgetVariant.MEDIUM_REGULAR to ("widget_medium" to medium + "eaten_of"),
            WidgetVariant.MEDIUM_LARGE to ("widget_medium_large" to medium + "eaten_of"),
            WidgetVariant.NUMBERS_ROW to ("widget_numbers_row" to numbers),
            WidgetVariant.NUMBERS_ROW_LARGE to ("widget_numbers_row_large" to numbers),
            WidgetVariant.NUMBERS_REGULAR to ("widget_numbers" to numbers),
            WidgetVariant.NUMBERS_LARGE to ("widget_numbers_large" to numbers),
            WidgetVariant.BUTTONS_REGULAR to ("widget_buttons" to listOf("button_speak", "button_ask")),
            WidgetVariant.BUTTONS_LARGE to ("widget_buttons_large" to listOf("button_speak", "button_ask")),
        )
        assertEquals(WidgetVariant.entries.toSet(), layouts.keys)
        for ((name, ids) in layouts.values) {
            val xml = File(res, "layout/$name.xml").readText()
            // The numbers widget's tap target is the card itself.
            assertTrue(name, xml.contains("android:id=\"@android:id/background\""))
            for (id in ids) assertTrue("$name: $id", xml.contains("android:id=\"@+id/$id\""))
        }
    }
}
