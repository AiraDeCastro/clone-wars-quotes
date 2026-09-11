package com.coldopen.app.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.coldopen.core.Quote
import com.coldopen.core.QuoteCorpus
import java.io.IOException

/**
 * Renders one quote per Glance update. Random selection uses plain
 * `randomOrNull()`, not :core's no-repeat `QuoteSelector` — wiring that in
 * needs persisted "already shown" state (see QuoteSelector's doc comment
 * and TASKS.md). Manual refresh (a tap action that re-triggers
 * [GlanceAppWidget.update]) isn't wired yet either.
 */
class ColdOpenWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val quote = loadRandomQuote(context)
        provideContent {
            ColdOpenWidgetContent(quote)
        }
    }

    private fun loadRandomQuote(context: Context): Quote = try {
        context.assets.open(CORPUS_ASSET_NAME).use { QuoteCorpus.load(it) }.randomOrNull()
            ?: FALLBACK_QUOTE
    } catch (e: IOException) {
        FALLBACK_QUOTE
    }

    companion object {
        const val CORPUS_ASSET_NAME = "quotes.json"

        // Rendered if the bundled corpus can't be read at all.
        val FALLBACK_QUOTE = Quote(
            text = "Heroes are made by the path they choose, not the powers they are graced with.",
            episodeTitle = "Rookies",
            season = 1,
            episode = 5,
            arc = "Malevolence",
        )
    }
}

@Composable
private fun ColdOpenWidgetContent(quote: Quote) {
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(Color(0xFF0D1116))
            .padding(16.dp),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        Text(
            text = quote.text,
            style = TextStyle(
                color = ColorProvider(Color.White),
                fontWeight = FontWeight.Medium,
                fontSize = 15.sp,
            ),
        )
        Text(
            text = "${quote.episodeTitle} · S${quote.season}E${quote.episode}",
            style = TextStyle(color = ColorProvider(Color(0xFFB7C0D8)), fontSize = 11.sp),
        )
    }
}

class ColdOpenWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ColdOpenWidget()
}
