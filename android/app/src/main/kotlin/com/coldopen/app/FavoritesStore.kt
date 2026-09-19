package com.coldopen.app

import android.content.Context
import com.coldopen.core.Quote
import com.coldopen.app.widget.ColdOpenWidget

/**
 * Shared favorite-quote storage, backed by the same `SharedPreferences`
 * file [ColdOpenWidget]'s "already shown" persistence already uses —
 * written by the companion browser ([MainActivity]) when the user taps
 * the favorite toggle, read by the widget to exclude favorites from the
 * randomize/auto-refresh pool. Unlike iOS, this needs no App
 * Group-equivalent: the widget and the app run in the same process here.
 */
object FavoritesStore {
    private const val PREF_FAVORITE_TEXTS = "favorite_quote_texts"

    private fun prefs(context: Context) =
        context.getSharedPreferences(ColdOpenWidget.PREFS_NAME, Context.MODE_PRIVATE)

    fun favoriteTexts(context: Context): Set<String> =
        prefs(context).getStringSet(PREF_FAVORITE_TEXTS, emptySet()) ?: emptySet()

    fun isFavorite(context: Context, quote: Quote): Boolean =
        favoriteTexts(context).contains(quote.text)

    fun toggleFavorite(context: Context, quote: Quote) {
        val favorites = favoriteTexts(context).toMutableSet()
        if (!favorites.add(quote.text)) {
            favorites.remove(quote.text)
        }
        prefs(context).edit().putStringSet(PREF_FAVORITE_TEXTS, favorites).apply()
    }
}
