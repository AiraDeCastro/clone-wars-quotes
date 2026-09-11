package com.coldopen.core

import org.json.JSONArray
import java.io.InputStream

/**
 * Parses the quote corpus. This module has no Android dependency on purpose
 * (see build.gradle.kts) — it takes raw JSON in and hands `Quote`s back, so
 * it stays testable with plain `gradle :core:test` and a JDK, no Android SDK
 * or emulator required. The `:app` module is responsible for supplying the
 * actual bundled corpus (from `app/src/main/assets/quotes.json`, synced via
 * `npm run sync:android` at the repo root).
 */
object QuoteCorpus {
    fun parse(json: String): List<Quote> {
        val array = JSONArray(json)
        return (0 until array.length()).map { i ->
            val obj = array.getJSONObject(i)
            Quote(
                text = obj.getString("text"),
                episodeTitle = obj.getString("episodeTitle"),
                season = obj.getInt("season"),
                episode = obj.getInt("episode"),
                arc = obj.getString("arc"),
            )
        }
    }

    fun load(stream: InputStream): List<Quote> =
        parse(stream.bufferedReader().use { it.readText() })
}
