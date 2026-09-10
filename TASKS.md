# TASKS.md

Task breakdown for **Cold Open**, organized by the milestones defined in [docs/PRD.md](docs/PRD.md) §12. Scope, stack, and rationale live in [PLANNING.md](PLANNING.md); guardrails for Claude Code sessions live in [CLAUDE.md](CLAUDE.md).

Check items off as they land. Exit criteria for each milestone is listed at the end of its section — don't call a milestone done until those pass.

---

## Tooling & Quality Gates

- [x] Set up husky pre-commit hook: markdown + corpus lint, corpus test suite, corpus build/validation, `npm audit`
- [x] Set up husky commit-msg hook + commitlint for Conventional Commits
- [x] Write a corpus schema validator ([scripts/validate-corpus.js](scripts/validate-corpus.js)) and its test suite ([tests/corpus.test.js](tests/corpus.test.js))
- [ ] **(newly discovered)** Once the iOS Xcode project exists (below): add SwiftLint + `xcodebuild`/XCTest to the pre-commit hook
- [ ] **(newly discovered)** Once the Android Studio project exists (below): add ktlint + Gradle build/JUnit to the pre-commit hook
- [ ] **(newly discovered)** Once native projects exist: add native dependency vulnerability scanning (CocoaPods/SPM audit, Gradle dependency check) alongside `npm audit`

---

## M1 — Corpus & Core Widget

**Quote corpus**

- [ ] Transcribe cold-open narration lines episode-by-episode (season, episode, arc, exact text) — **blocked, see [corpus/README.md](corpus/README.md):** Claude won't bulk-generate ~130 episodes of verbatim copyrighted narration from memory (copyright + accuracy risk, see PRD §11); needs sourcing from a legitimate transcript/subtitle source, see newly discovered task below
- [ ] Fact-check transcriptions against source audio/subtitles for accuracy
- [x] Define the JSON schema: `text`, `episodeTitle`, `season`, `episode`, `arc` — seeded in [corpus/quotes.json](corpus/quotes.json) with one verified entry
- [ ] Write the JSON → SQLite build step for on-device querying (`npm run build` currently just re-validates and writes `corpus/quotes.compiled.json` as a placeholder — see [scripts/validate-corpus.js](scripts/validate-corpus.js))
- [x] Add a validation script that catches schema violations and duplicate entries — [scripts/validate-corpus.js](scripts/validate-corpus.js), covered by [tests/corpus.test.js](tests/corpus.test.js)
- [ ] **(newly discovered)** Source the remaining ~129 cold-open quotes from a transcript/subtitle source the user has legitimate access to; Claude can validate structure/schema and write build tooling once real text is supplied

**iOS widget**

- [ ] Set up Xcode project + WidgetKit extension target
- [ ] Bundle the compiled corpus with the app target
- [ ] Implement random, no-repeat-until-exhausted quote selection
- [ ] Build small and medium widget size layouts (quote only / quote + attribution)
- [ ] Wire manual refresh via App Intent + widget timeline reload
- [ ] Verify WCAG AA contrast on both layouts

**Android widget**

- [ ] Set up Android Studio project + Jetpack Glance widget module
- [ ] Bundle the compiled corpus with the app
- [ ] Implement random, no-repeat-until-exhausted quote selection (shared logic/schema with iOS, platform-native implementation)
- [ ] Build small and medium widget size layouts
- [ ] Wire manual refresh via Glance action + widget update
- [ ] Verify custom font renders correctly across target API levels (bitmap fallback if needed)

**Exit criteria:** Widget installable on iOS and Android, shows real random quotes from the actual corpus, manual refresh works, no crashes.

---

## M2 — Sharing

- [ ] Design the share card layout (themed background, quote in display face, attribution line, wordmark)
- [ ] Implement on-device share card rendering — iOS (Core Graphics)
- [ ] Implement on-device share card rendering — Android (Canvas)
- [ ] Export share cards at 1080×1920 (Stories/Reels) and 1080×1080 (feed)
- [ ] Wire iOS share sheet (`UIActivityViewController`) with pre-attached image
- [ ] Wire Android share intent (`ACTION_SEND`, image MIME type) with pre-attached image
- [ ] Integrate Instagram Stories sticker/background API where available
- [ ] Confirm fallback to generic OS share sheet for X, Facebook, Messages, WhatsApp
- [ ] Add attribution text to every generated share card (non-negotiable — see CLAUDE.md)

**Exit criteria:** A quote can go from widget tap to a posted Instagram/X/Facebook story in under 10 seconds, on both platforms.

---

## M3 — Polish & Scheduled Refresh

- [ ] Build the large widget size (quote + attribution + faction emblem) — iOS and Android
- [ ] Implement scheduled auto-refresh respecting each OS's widget timeline budget
- [ ] Add user-facing cadence setting (e.g., daily, every few hours)
- [ ] Implement favorite/pin action (long-press or in-app), excluded from randomize + auto-refresh pool
- [ ] Build the companion app quote browser (searchable by episode/arc)
- [ ] Instrument analytics for the D30 retention and share-rate metrics defined in the PRD
- [ ] Accessibility pass: VoiceOver/TalkBack reads quote + attribution as a single label

**Exit criteria:** D30 retention and share-rate metrics are actually being measured against the PRD §2 goals.

---

## M4 — macOS / Windows

- [ ] Port the WidgetKit target to macOS (Catalyst/native), reusing the iOS corpus and rendering code where possible
- [ ] Verify Notification Center + desktop widget placement on macOS
- [ ] Evaluate current maturity of the Windows Widgets Board API
- [ ] Build the Windows widget target (small/medium/large parity with mobile P0 scope)
- [ ] Confirm share-sheet equivalents work on both desktop platforms

**Exit criteria:** Feature parity with the mobile P0 scope (§4 of the PRD) on macOS and Windows.

---

## Backlog (P2 — not scheduled to a milestone yet)

- [ ] Faction-themed widget skins (Republic / Separatist / Jedi / Mandalorian palettes)
- [ ] Lock screen widget (iOS 16+ family, Android always-on-display equivalent)

## Open items blocking full completion (see PRD §11)

- [ ] Decide distribution plan (sideload/TestFlight vs. public app store listing) before investing further in store-specific polish — IP risk, needs explicit sign-off
- [ ] Spike real WidgetKit refresh-budget behavior on a physical device — confirms whether the <150ms refresh goal is realistic within OS constraints
