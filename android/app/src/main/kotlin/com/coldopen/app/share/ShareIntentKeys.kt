package com.coldopen.app.share

/**
 * Plain string constants for the Intent extras carrying a [com.coldopen.core.Quote]
 * from the widget's Glance `actionStartActivity` call (in `ColdOpenWidget.kt`)
 * to [ShareActivity]. Kept as raw strings (not just `ActionParameters.Key`
 * objects read back via a `.name` property) so both sides can agree on the
 * exact same key without relying on that property's exact shape — the two
 * files are in the same module, so a mismatch here would be a real bug, not
 * an unverifiable cross-module guess, but there's still no Kotlin compiler
 * here to catch a typo either way.
 */
object ShareIntentKeys {
    const val TEXT = "quote_text"
    const val EPISODE_TITLE = "quote_episode_title"
    const val SEASON = "quote_season"
    const val EPISODE = "quote_episode"
    const val ARC = "quote_arc"
}
