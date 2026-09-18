# Quote Corpus

`quotes.json` is the source of truth for the cold-open narration corpus (see [PLANNING.md](../PLANNING.md) architecture diagram and schema).

**Schema** (per entry): `text`, `episodeTitle`, `season`, `episode`, `arc`.

## Status: 129 of ~133 episodes

`quotes.json` now holds the cold-open narration line for every Season 1-7 episode that has one (129 entries; the four Season 7 episodes making up the "Siege of Mandalore" finale arc — "Old Friends Not Forgotten," "Phantom Apprentice," "Shattered," "Victory and Death" — open with no narration at all, confirmed against the source below, not omitted by mistake).

## Why this wasn't bulk-generated from memory

Transcribing cold-open lines from memory risks two problems at once: copyright exposure (reproducing a large volume of Lucasfilm/Disney's copyrighted narration text verbatim from an AI's memory, rather than a real source — see PRD §11), and factual inaccuracy (misremembered or misattributed lines baked into the app's core data). Neither was worth the shortcut, so this stayed a single seed entry until a real source was available.

## Where the 129 entries came from

The user supplied a legitimate transcript source: [sagespeculation.com's episode-by-episode compilation](http://www.sagespeculation.com/2017/08/01/star-wars-the-clone-wars-episode-opening-quotes/) of every cold-open line, covering the original broadcast run (Seasons 1-6) and the Disney+ final season. `text`, `episodeTitle`, `season`, and `episode` were transcribed from that page.

Episode titles were cross-checked against [Wikipedia's episode list](https://en.wikipedia.org/wiki/List_of_Star_Wars:_The_Clone_Wars_episodes) and corrected where the two sources disagreed on spelling (e.g. "Mystery of **a** Thousand Moons" not "...the...", "Wooki**ee** Hunt" not "Wooki**e** Hunt", "Counter Attack" as two words).

**One conflict with the original seed entry, flagged rather than silently resolved:** the pre-existing seed entry attributed *"Heroes are made by the path they choose, not the powers they are graced with."* to "Rookies" (S1E5) with `arc: "Malevolence"`. The new source gives Rookies' actual line as *"The best confidence builder is experience,"* and Rookies isn't part of the Malevolence arc (that's Season 1 episodes 2-4 only) — it's a standalone episode that airs right after it. The seed entry was written before any real transcript source existed, specifically as a schema example, and was superseded by the sourced data rather than the other way around. If you have your own copy of "Rookies" and the original line is correct after all, that's worth re-checking directly against the episode audio.

## Where `arc` came from

The transcript source doesn't include story-arc groupings, and no single reference lists one for every episode — multi-episode arcs (e.g. "Malevolence," "Ryloth," "Umbara") are named across fan/wiki usage, but the majority of episodes are standalone one-offs with no real arc name anywhere. Per an explicit decision on this: **standalone episodes use their own episode title as `arc`** (e.g. the "Rookies" episode has `arc: "Rookies"`), so the field never implies a false connection between unrelated episodes. Multi-episode arcs were identified by reading each episode's plot synopsis on Wikipedia's episode list and grouping episodes with a genuinely continuous plot thread — not guessed from memory, and not exhaustive (a couple of minor two-episode arcs may have been missed and are left as two standalone entries instead, which is the safe direction to err in).

## What's still open

- **The 4 Season 7 "Siege of Mandalore" episodes** have no cold-open line to transcribe (confirmed, not a gap) — see PRD/TASKS.md if a future decision is made to handle arc-finale episodes differently in the UI.
- **No independent fact-check against audio/official subtitles yet** — this corpus is sourced from one fan compilation, cross-checked for episode titles only, not re-verified line-by-line against the actual episodes. Worth a pass if/when the user has time with their own copies.
- Claude Code sessions can help with the *structural* side of any future corrections — validating JSON shape, catching duplicate entries, flagging missing fields — the same as before.
