# Quote Corpus

`quotes.json` is the source of truth for the cold-open narration corpus (see [PLANNING.md](../PLANNING.md) architecture diagram and schema).

**Schema** (per entry): `text`, `episodeTitle`, `season`, `episode`, `arc`.

## Status: seeded, not complete

This file currently holds **one** verified entry, used as the schema example throughout [docs/PRD.md](../docs/PRD.md) and [CLAUDE.md](../CLAUDE.md). It is not the full ~130-episode corpus yet.

## Why this wasn't bulk-generated

Transcribing all cold-open lines requires reproducing a large volume of Lucasfilm/Disney's copyrighted narration text verbatim. Generating that at scale from memory risks two problems at once: copyright exposure (this is exactly the risk flagged in PRD §11), and factual inaccuracy (misremembered or misattributed lines baked into the app's core data). Neither is worth the shortcut.

## How to fill this in

The reliable path is to transcribe from a source you have legitimate access to (e.g., your own copies of the episodes, official subtitle/caption tracks) rather than from an AI's memory of the dialogue:

1. Go episode by episode, capture the exact cold-open narration line, and fill in the four schema fields.
2. Append entries to `quotes.json` in the same shape as the seed entry above.
3. Claude Code sessions can help with the *structural* side of this — validating JSON shape, catching duplicate entries, flagging missing fields, writing the JSON → SQLite build step (TASKS.md M1) — just not with generating the quote text itself.
