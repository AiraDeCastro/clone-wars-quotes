package com.coldopen.core

/**
 * Picks quotes at random without repeating one until the whole corpus has
 * been shown once, then reshuffles.
 *
 * This only tracks state in memory. Unlike iOS's WidgetKit extension (a
 * separate, short-lived process), an Android widget's Glance code runs
 * inside the app's own process, so persisting the "already shown" set
 * across restarts is a straightforward DataStore/SharedPreferences
 * read-in/write-out — not a fundamentally separate-process problem like on
 * iOS. That wiring isn't done yet; tracked as a follow-on task in
 * TASKS.md. This type itself is algorithmically correct and unit-tested.
 */
class QuoteSelector(private val allQuotes: List<Quote>) {
    private var pool: MutableList<Quote> = allQuotes.toMutableList()

    /**
     * Returns a random quote, removing it from the pool. Refills the pool
     * from the full corpus once it's exhausted. Returns `null` only if the
     * corpus itself is empty.
     */
    fun next(): Quote? {
        if (pool.isEmpty()) {
            pool = allQuotes.toMutableList()
        }
        if (pool.isEmpty()) return null
        val index = pool.indices.random()
        return pool.removeAt(index)
    }
}
