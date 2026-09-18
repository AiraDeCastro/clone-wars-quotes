package com.coldopen.app.share

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import com.coldopen.core.Quote

/** The two export sizes required by TASKS.md M2: Stories/Reels (9:16) and the square feed crop (1:1). */
object ShareCardSize {
    const val STORY_WIDTH = 1080
    const val STORY_HEIGHT = 1920
    const val SQUARE_WIDTH = 1080
    const val SQUARE_HEIGHT = 1080
}

/**
 * Renders the cold-open quote onto a themed share card, matching the
 * "Starfield Minimal" concept the user picked from a 3-way proposal: a
 * deep-navy ground, a handful of gold star flecks (the same restrained
 * count as the app icon's own starfield — a denser field read as noise
 * when that was tested at icon scale), the quote in a large serif face,
 * and the required Star Wars attribution as two lines at the bottom —
 * never dropped, per CLAUDE.md.
 *
 * Lives in `:app` rather than `:core` because `android.graphics` has no
 * plain-JVM equivalent, unlike `QuoteSelector`'s pure-Kotlin logic — same
 * reason the widget's own rendering code lives here too.
 */
object ShareCardRenderer {
    /** The width the concept mockup was designed at — every other metric below scales off this. */
    private const val REFERENCE_WIDTH = 340f

    private const val BACKGROUND_COLOR = 0xFF0B0F17.toInt()
    private const val STAR_COLOR = 0xFFC9A227.toInt()
    private const val QUOTE_COLOR = 0xFFF5F3EC.toInt()
    private const val ATTRIBUTION_PRIMARY_COLOR = 0xFF9AA3B8.toInt()
    private const val ATTRIBUTION_SECONDARY_COLOR = 0xFF6E7690.toInt()

    private data class Star(val x: Float, val yFromTop: Float, val radius: Float, val alpha: Float)

    // Same fractional positions as the approved concept artifact — not
    // re-picked, so the shipped card matches what was actually approved.
    private val stars = listOf(
        Star(0.188f, 0.093f, 4f, 0.9f),
        Star(0.741f, 0.159f, 3f, 0.6f),
        Star(0.529f, 0.066f, 5f, 0.75f),
        Star(0.118f, 0.248f, 3f, 0.5f),
        Star(0.859f, 0.802f, 4f, 0.7f),
        Star(0.235f, 0.851f, 3f, 0.55f),
    )

    fun render(quote: Quote, width: Int, height: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val scale = width / REFERENCE_WIDTH

        canvas.drawColor(BACKGROUND_COLOR)

        val starPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = STAR_COLOR }
        for (star in stars) {
            starPaint.alpha = (star.alpha * 255).toInt()
            canvas.drawCircle(star.x * width, star.yFromTop * height, star.radius * scale, starPaint)
        }

        val marginX = 36f * scale
        val bottomMargin = 32f * scale
        val lineGap = 16f * scale
        val attributionFontSize = 10f * scale
        // Reserve room for both attribution lines so the quote layout
        // never overlaps them, regardless of how long the quote is.
        val attributionBandHeight = bottomMargin + lineGap + attributionFontSize * 2.8f

        drawQuote(quote.text, canvas, width = width, availableHeight = height - attributionBandHeight, marginX = marginX, scale = scale)

        // Primary (app + show name) sits above secondary (episode), which
        // sits closest to the bottom edge, matching the approved mockup's
        // stacking order. drawText's y is the text BASELINE, not the top.
        val secondaryBaselineY = height - bottomMargin
        val primaryBaselineY = secondaryBaselineY - lineGap - attributionFontSize

        val attributionPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = Typeface.create("sans-serif-condensed", Typeface.NORMAL)
            letterSpacing = 0.08f
            textSize = attributionFontSize
        }

        attributionPaint.color = ATTRIBUTION_PRIMARY_COLOR
        canvas.drawText("COLD OPEN · STAR WARS: THE CLONE WARS", marginX, primaryBaselineY, attributionPaint)

        attributionPaint.color = ATTRIBUTION_SECONDARY_COLOR
        canvas.drawText(
            "${quote.episodeTitle.uppercase()} · SEASON ${quote.season}, EPISODE ${quote.episode}",
            marginX,
            secondaryBaselineY,
            attributionPaint,
        )

        return bitmap
    }

    private fun drawQuote(text: String, canvas: Canvas, width: Int, availableHeight: Float, marginX: Float, scale: Float) {
        val quotePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = QUOTE_COLOR
            typeface = Typeface.SERIF
            textSize = 34f * scale
        }
        val quoteWidth = (width - marginX * 2).toInt().coerceAtLeast(1)
        val layout = StaticLayout.Builder
            .obtain("“$text”", 0, "“$text”".length, quotePaint, quoteWidth)
            .setAlignment(Layout.Alignment.ALIGN_NORMAL)
            .setLineSpacing(0f, 1.3f)
            .build()

        // Center the measured block within the space above the attribution
        // band; if it's somehow taller than that space, clamp to the top
        // rather than let it run into the attribution lines.
        val blockHeight = layout.height.toFloat().coerceAtMost(availableHeight)
        val originY = ((availableHeight - blockHeight) / 2f).coerceAtLeast(0f)

        canvas.save()
        canvas.translate(marginX, originY)
        layout.draw(canvas)
        canvas.restore()
    }
}
