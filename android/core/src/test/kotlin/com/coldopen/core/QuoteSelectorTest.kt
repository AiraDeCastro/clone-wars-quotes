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
}
