package com.coldopen.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class QuoteSelectorTest {

    @Test
    fun `never repeats before exhausting the pool`() {
        val quotes = (0 until 5).map { i ->
            Quote(text = "Quote $i", episodeTitle = "Ep", season = 1, episode = i + 1, arc = "Arc")
        }
        val selector = QuoteSelector(quotes)

        val seen = mutableSetOf<String>()
        repeat(5) {
            val quote = selector.next() ?: error("expected a quote")
            assertTrue("quote repeated before pool exhausted", seen.add(quote.text))
        }
        assertEquals(5, seen.size)
    }

    @Test
    fun `refills pool after exhaustion`() {
        val quotes = listOf(Quote(text = "Only one", episodeTitle = "Ep", season = 1, episode = 1, arc = "Arc"))
        val selector = QuoteSelector(quotes)

        assertEquals("Only one", selector.next()?.text)
        assertEquals("Only one", selector.next()?.text)
    }

    @Test
    fun `empty corpus returns null`() {
        val selector = QuoteSelector(emptyList())
        assertNull(selector.next())
    }

    @Test
    fun `shownTexts accumulates as quotes are drawn`() {
        val quotes = (0 until 3).map { i ->
            Quote(text = "Quote $i", episodeTitle = "Ep", season = 1, episode = i + 1, arc = "Arc")
        }
        val selector = QuoteSelector(quotes)

        assertEquals(emptySet<String>(), selector.shownTexts)
        val first = selector.next()!!
        assertEquals(setOf(first.text), selector.shownTexts)
        val second = selector.next()!!
        assertEquals(setOf(first.text, second.text), selector.shownTexts)
    }

    @Test
    fun `resuming with a saved shown set excludes those quotes until the pool exhausts`() {
        val quotes = (0 until 3).map { i ->
            Quote(text = "Quote $i", episodeTitle = "Ep", season = 1, episode = i + 1, arc = "Arc")
        }
        // Simulate a process restart after "Quote 0" and "Quote 1" were already shown.
        val selector = QuoteSelector(quotes, alreadyShown = setOf("Quote 0", "Quote 1"))

        assertEquals("Quote 2", selector.next()?.text)
        // Pool is now exhausted (all 3 shown across the restart boundary) — refills.
        val seen = mutableSetOf<String>()
        repeat(3) { seen.add(selector.next()!!.text) }
        assertEquals(setOf("Quote 0", "Quote 1", "Quote 2"), seen)
    }

    @Test
    fun `resuming with every quote already shown refills immediately`() {
        val quotes = listOf(Quote(text = "Only one", episodeTitle = "Ep", season = 1, episode = 1, arc = "Arc"))
        val selector = QuoteSelector(quotes, alreadyShown = setOf("Only one"))

        assertEquals("Only one", selector.next()?.text)
    }

    @Test
    fun `refilling after exhaustion clears the shown set, not just the pool`() {
        val quotes = listOf(Quote(text = "Only one", episodeTitle = "Ep", season = 1, episode = 1, arc = "Arc"))
        val selector = QuoteSelector(quotes)

        selector.next()
        assertEquals(setOf("Only one"), selector.shownTexts)
        selector.next() // triggers refill since the pool was already empty
        assertEquals(setOf("Only one"), selector.shownTexts)
    }
}
