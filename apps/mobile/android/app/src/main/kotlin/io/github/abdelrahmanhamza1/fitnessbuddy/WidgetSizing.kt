package io.github.abdelrahmanhamza1.fitnessbuddy

/**
 * Which layout a home-screen widget shows at which size (A73). Pure Kotlin, no Android types, so
 * the JVM tests check it (HomeWidgetSizingTest).
 *
 * Each [WidgetVariant] is one layout and the smallest size (dp) its content needs; the sums are in
 * each layout's header comment. A family's first variant is its smallest on both axes and is what
 * the provider XML advertises as `minResizeWidth/Height`, so every size the launcher allows fits a
 * variant.
 */
enum class WidgetFamily { MEDIUM, NUMBERS, BUTTONS }

enum class WidgetVariant(val family: WidgetFamily, val widthDp: Float, val heightDp: Float) {
    /** 4 x 1: ring and the four macros in one row; with no numbers, Speak · Ask · Weigh. */
    MEDIUM_ROW(WidgetFamily.MEDIUM, 280f, 72f),
    /** 4 x 2 on most launchers: ring, "eaten / target", 2 x 2 macros, the buttons. */
    MEDIUM_REGULAR(WidgetFamily.MEDIUM, 280f, 136f),
    /** 4 x 2 on large cells (One UI): the same, bigger. */
    MEDIUM_LARGE(WidgetFamily.MEDIUM, 320f, 184f),

    /** 2 x 1: a small ring and protein beside it. */
    NUMBERS_ROW(WidgetFamily.NUMBERS, 110f, 64f),
    /** 2 x 1 on large cells: the same, bigger. */
    NUMBERS_ROW_LARGE(WidgetFamily.NUMBERS, 150f, 84f),
    /** 2 x 2 on most launchers: ring and protein under it. */
    NUMBERS_REGULAR(WidgetFamily.NUMBERS, 110f, 120f),
    /** 2 x 2 on large cells: the same, bigger. */
    NUMBERS_LARGE(WidgetFamily.NUMBERS, 150f, 170f),

    /** 2 x 1: Speak and Ask icons. */
    BUTTONS_REGULAR(WidgetFamily.BUTTONS, 110f, 40f),
    /** Taller: bigger icons with their labels. */
    BUTTONS_LARGE(WidgetFamily.BUTTONS, 140f, 72f);

    val area: Float get() = widthDp * heightDp

    /**
     * Whether this layout may show at [widthDp] x [heightDp]: Android's test
     * (RemoteViews.fitsIn, `ceil(actual) + 1 > layout`), which allows up to 1 dp less than the
     * layout's size on each axis for fractional sizes.
     */
    fun fitsIn(widthDp: Float, heightDp: Float) =
        kotlin.math.ceil(widthDp) + 1 > this.widthDp && kotlin.math.ceil(heightDp) + 1 > this.heightDp

    /** The one-row layouts show only the eaten grams per macro (A73 review: no room for "/target"). */
    val compactMacros: Boolean
        get() = this == MEDIUM_ROW || this == NUMBERS_ROW || this == NUMBERS_ROW_LARGE
}

/** The fixed word under the mark when there are no numbers. */
enum class PlainText { NONE, PROMPT, OPEN_APP }

/**
 * What a layout shows in a state (A71 + A73): pure, so the host tests check every variant.
 * [body] is the medium widget's tap area (numbers or plain), [buttons] its button row.
 */
data class WidgetFace(
    val body: Boolean,
    val numbers: Boolean,
    val plain: Boolean,
    val plainText: PlainText,
    val buttons: Boolean,
) {
    companion object {
        /**
         * [variant] with today's numbers ([hasNumbers]) or without (hidden, no day for today,
         * signed out). Signed out never shows numbers or buttons, only "Open Fitness Buddy".
         */
        fun of(variant: WidgetVariant, hasNumbers: Boolean, signedOut: Boolean): WidgetFace {
            val numbers = hasNumbers && !signedOut
            return when (variant.family) {
                WidgetFamily.BUTTONS -> WidgetFace(false, false, false, PlainText.NONE, true)
                WidgetFamily.NUMBERS -> WidgetFace(
                    body = true,
                    numbers = numbers,
                    plain = !numbers,
                    plainText = if (!numbers && signedOut) PlainText.OPEN_APP else PlainText.NONE,
                    buttons = false,
                )
                WidgetFamily.MEDIUM -> {
                    val plainText = when {
                        numbers -> PlainText.NONE
                        signedOut -> PlainText.OPEN_APP
                        else -> PlainText.PROMPT
                    }
                    if (variant == WidgetVariant.MEDIUM_ROW) {
                        // One row: no numbers but signed in -> the buttons take the row (UX-085).
                        val buttonsOnly = !numbers && !signedOut
                        WidgetFace(!buttonsOnly, numbers, !numbers, plainText, buttonsOnly)
                    } else {
                        WidgetFace(true, numbers, !numbers, plainText, !signedOut)
                    }
                }
            }
        }
    }
}

object WidgetSizing {
    /** The variants of [family], smallest first. */
    fun variants(family: WidgetFamily): List<WidgetVariant> =
        WidgetVariant.entries.filter { it.family == family }

    /** The variant for the default cell size (initialLayout, previewLayout). */
    fun regular(family: WidgetFamily): WidgetVariant = when (family) {
        WidgetFamily.MEDIUM -> WidgetVariant.MEDIUM_REGULAR
        WidgetFamily.NUMBERS -> WidgetVariant.NUMBERS_REGULAR
        WidgetFamily.BUTTONS -> WidgetVariant.BUTTONS_REGULAR
    }

    /**
     * The variant [family] shows at [widthDp] x [heightDp]: the platform's rule for a
     * `RemoteViews(Map<SizeF, RemoteViews>)` (Android 12+, RemoteViews.findBestFitLayout, with
     * its rounding tolerance [WidgetVariant.fitsIn]), used as is below Android 12: of the variants
     * that fit, the closest (squared distance); none fits, the smallest. One deliberate
     * difference: an unknown size (0 or less, only below Android 12, when the launcher hasn't
     * reported one) gets the regular variant, the default cell size.
     */
    fun choose(family: WidgetFamily, widthDp: Float, heightDp: Float): WidgetVariant {
        if (widthDp <= 0f || heightDp <= 0f) return regular(family)
        val all = variants(family)
        return all.filter { it.fitsIn(widthDp, heightDp) }.minByOrNull {
            val dw = widthDp - it.widthDp
            val dh = heightDp - it.heightDp
            dw * dw + dh * dh
        } ?: all.minBy { it.area }
    }
}
