package com.coldopen.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class QuoteCorpusTest {

    private val sampleJson = """
        [
          {
            "text": "Heroes are made by the path they choose, not the powers they are graced with.",
            "episodeTitle": "Rookies",
            "season": 1,
            "episode": 5,
            "arc": "Malevolence"
          }
        ]
    """.trimIndent()

    @Test
    fun `parses a well-formed corpus`() {
        val quotes = QuoteCorpus.parse(sampleJson)
        assertEquals(1, quotes.size)
        assertFalse(quotes[0].text.isEmpty())
    }

    @Test
    fun `parses the known seed entry correctly`() {
        val quotes = QuoteCorpus.parse(sampleJson)
        assertTrue(quotes.any { it.episodeTitle == "Rookies" && it.season == 1 && it.episode == 5 })
    }
}
