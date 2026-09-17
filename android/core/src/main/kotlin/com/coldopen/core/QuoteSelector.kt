package com.coldopen.core

/**
 * Picks quotes at random without repeating one until the whole corpus has
 * been shown once, then reshuffles.
 *
 * Unlike iOS's WidgetKit extension (a separate, short-lived process), an
 * Android widget's Glance code runs inside the app's own process — so the
 * "already shown" state only needs to survive a process restart, not a
 * fundamentally separate-process boundary like on iOS. This class itself
 * stays plain Kotlin with no Android dependency (consistent with the rest
 * of `:core`): it exposes [shownTexts] so a caller can persist it (e.g. via
 * `SharedPreferences.putStringSet`) and pass it back in as [alreadyShown]
 * on the next cold start, via `Quote.text` as the identifier — the same
 * uniqueness key the corpus validator already enforces
 * (`scripts/validate-corpus.js` rejects duplicate `text` values), since
 * `Quote` has no separate numeric id at this layer.
 *
 * The actual `SharedPreferences` read/write lives in `:app`
 * (`ColdOpenWidget.kt`), not here — see TASKS.md for that wiring.
 */
class QuoteSelector(
    private val allQuotes: List<Quote>,
    alreadyShown: Set<String> = emptySet(),
) {
    private var pool: MutableList<Quote> =
        allQuotes.filterNot { it.text in alreadyShown }.toMutableList()
    private val shown: MutableSet<String> = alreadyShown.toMutableSet()

    /** Text of every quote drawn since construction (or resumed via [alreadyShown]). */
    val shownTexts: Set<String>
        get() = shown.toSet()

    /**
     * Returns a random quote, removing it from the pool. Refills the pool
     * (and clears [shownTexts]) once it's exhausted — including
     * immediately, if resuming with every quote already marked shown.
     * Returns `null` only if the corpus itself is empty.
     */
    fun next(): Quote? {
        if (pool.isEmpty()) {
            pool = allQuotes.toMutableList()
            shown.clear()
        }
        if (pool.isEmpty()) return null
        val index = pool.indices.random()
        val quote = pool.removeAt(index)
        shown.add(quote.text)
        return quote
    }
}
