package com.coldopen.app.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.ActionParameters
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.coldopen.core.Quote
import com.coldopen.core.QuoteCorpus
import com.coldopen.core.QuoteSelector

/**
 * Renders one quote per Glance update, using :core's no-repeat
 * `QuoteSelector`. The "already shown" set is persisted in
 * `SharedPreferences` across process restarts — unlike iOS's WidgetKit
 * extension (a separate, short-lived process), a Glance widget runs in the
 * app's own process, so this is a plain read-in/write-out, not a
 * cross-process problem. See `QuoteSelector`'s doc comment for why the
 * persistence itself lives here in `:app` rather than in `:core`.
 *
 * Manual refresh is [RefreshAction] below — its `onAction` calls
 * [GlanceAppWidget.update], which re-runs [provideGlance] and therefore
 * [loadRandomQuote] again, so the refresh logic doesn't need to be
 * duplicated in the action callback itself.
 */
class ColdOpenWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val quote = loadRandomQuote(context)
        provideContent {
            ColdOpenWidgetContent(quote)
        }
    }

    private fun loadRandomQuote(context: Context): Quote {
        val quotes = try {
            context.assets.open(CORPUS_ASSET_NAME).use { QuoteCorpus.load(it) }
        } catch (e: Exception) {
            // Covers both a missing/unreadable asset (IOException) and a
            // malformed one (org.json.JSONException isn't an IOException) —
            // the widget should never crash or render fully empty.
            return FALLBACK_QUOTE
        }
        if (quotes.isEmpty()) return FALLBACK_QUOTE

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val alreadyShown = prefs.getStringSet(PREF_SHOWN_TEXTS, emptySet()) ?: emptySet()
        val selector = QuoteSelector(quotes, alreadyShown = alreadyShown)
        val quote = selector.next() ?: return FALLBACK_QUOTE
        prefs.edit().putStringSet(PREF_SHOWN_TEXTS, selector.shownTexts).apply()
        return quote
    }

    companion object {
        const val CORPUS_ASSET_NAME = "quotes.json"
        const val PREFS_NAME = "cold_open_widget"
        const val PREF_SHOWN_TEXTS = "shown_quote_texts"

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
        Row(modifier = GlanceModifier.fillMaxWidth()) {
            Text(
                text = "${quote.episodeTitle} · S${quote.season}E${quote.episode}",
                style = TextStyle(color = ColorProvider(Color(0xFFB7C0D8)), fontSize = 11.sp),
                modifier = GlanceModifier.defaultWeight(),
            )
            Text(
                text = "New quote",
                style = TextStyle(color = ColorProvider(Color(0xFFB7C0D8)), fontSize = 11.sp),
                modifier = GlanceModifier.clickable(onClick = actionRunCallback<RefreshAction>()),
            )
        }
    }
}

/**
 * Manual refresh. `update()` re-runs [ColdOpenWidget.provideGlance], which
 * draws the next no-repeat quote via `loadRandomQuote` — this callback just
 * triggers that, it doesn't duplicate the draw logic itself.
 */
class RefreshAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        ColdOpenWidget().update(context, glanceId)
    }
}

class ColdOpenWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ColdOpenWidget()
}
