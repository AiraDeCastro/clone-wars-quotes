package com.coldopen.core

/**
 * A single cold-open narration line. Mirrors the schema in `corpus/schema.json`
 * at the repo root — keep the two in sync if either changes.
 */
data class Quote(
    val text: String,
    val episodeTitle: String,
    val season: Int,
    val episode: Int,
    val arc: String,
)
