package com.coldopen.app.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.coldopen.app.FavoritesStore
import com.coldopen.app.share.ShareActivity
import com.coldopen.app.share.ShareIntentKeys
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
 *
 * [sizeMode] declares three responsive size buckets (small/medium/large,
 * matching the three fixed WidgetKit families the iOS side supports) —
 * Glance calls `provideGlance` once per bucket and [LocalSize] inside the
 * composable reports which one is actually showing, so [ColdOpenWidgetContent]
 * can scale typography/padding up for the large bucket rather than just
 * stretching the same small layout into more space.
 */
class ColdOpenWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Responsive(setOf(SmallSize, MediumSize, LargeSize))

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

        // Favorited quotes (set via the companion browser) are excluded
        // from the pool — unless every quote is favorited, in which case
        // excluding them all would leave nothing to show, so the filter
        // is skipped rather than falling back to the generic placeholder.
        val favorites = FavoritesStore.favoriteTexts(context)
        val nonFavoriteQuotes = quotes.filterNot { favorites.contains(it.text) }
        val eligibleQuotes = nonFavoriteQuotes.ifEmpty { quotes }

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val alreadyShown = prefs.getStringSet(PREF_SHOWN_TEXTS, emptySet()) ?: emptySet()
        val selector = QuoteSelector(eligibleQuotes, alreadyShown = alreadyShown)
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

// Matches cold_open_widget_info.xml's minWidth/minHeight/maxResizeWidth/
// maxResizeHeight — these are the three buckets Glance picks between via
// SizeMode.Responsive, not just documentation of the XML bounds.
private val SmallSize = DpSize(180.dp, 110.dp)
private val MediumSize = DpSize(270.dp, 110.dp)
private val LargeSize = DpSize(270.dp, 300.dp)

@Composable
private fun ColdOpenWidgetContent(quote: Quote) {
    val size = LocalSize.current
    val isLarge = size.height >= LargeSize.height
    val quoteFontSize = if (isLarge) 20.sp else 15.sp
    val attributionFontSize = if (isLarge) 13.sp else 11.sp

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(Color(0xFF0D1116))
            .padding(if (isLarge) 20.dp else 16.dp),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        Text(
            text = quote.text,
            style = TextStyle(
                color = ColorProvider(Color.White),
                fontWeight = FontWeight.Medium,
                fontSize = quoteFontSize,
            ),
            // Non-functional constraint (CLAUDE.md): TalkBack should read
            // quote + attribution as one label, not two. Unlike SwiftUI,
            // Glance's semantics package (androidx.glance.semantics) only
            // exposes contentDescription/testTag — no mergeDescendants or
            // an accessibilityHidden equivalent to explicitly silence the
            // visual attribution Text below, so this can't be verified as
            // a clean single-announcement the way the iOS fix can.
            modifier = GlanceModifier.semantics {
                contentDescription =
                    "${quote.text}. ${quote.episodeTitle}, season ${quote.season}, episode ${quote.episode}."
            },
        )
        // A faction emblem was considered for this size specifically (see
        // CLAUDE.md's design direction: "at most one faction emblem, and
        // only at the large widget size") but deliberately left out here —
        // it needs both a design decision (which emblem, in what style) and
        // a quote-to-faction mapping that doesn't exist in the schema yet.
        // Tracked as its own TASKS.md item rather than guessed at.
        Row(modifier = GlanceModifier.fillMaxWidth()) {
            Text(
                text = "${quote.episodeTitle} · S${quote.season}E${quote.episode}",
                style = TextStyle(color = ColorProvider(Color(0xFFB7C0D8)), fontSize = attributionFontSize),
                modifier = GlanceModifier.defaultWeight(),
            )
            // Launches ShareActivity, which renders the card and hands off
            // to the OS share sheet immediately — a widget's click handler
            // can't present that UI itself. See ShareActivity's doc comment.
            Text(
                text = "Share",
                style = TextStyle(color = ColorProvider(Color(0xFFB7C0D8)), fontSize = attributionFontSize),
                modifier = GlanceModifier.clickable(
                    onClick = actionStartActivity<ShareActivity>(
                        actionParametersOf(
                            ActionParameters.Key<String>(ShareIntentKeys.TEXT) to quote.text,
                            ActionParameters.Key<String>(ShareIntentKeys.EPISODE_TITLE) to quote.episodeTitle,
                            ActionParameters.Key<Int>(ShareIntentKeys.SEASON) to quote.season,
                            ActionParameters.Key<Int>(ShareIntentKeys.EPISODE) to quote.episode,
                            ActionParameters.Key<String>(ShareIntentKeys.ARC) to quote.arc,
                        )
                    ),
                ),
            )
            Text(
                text = "New quote",
                style = TextStyle(color = ColorProvider(Color(0xFFB7C0D8)), fontSize = attributionFontSize),
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
