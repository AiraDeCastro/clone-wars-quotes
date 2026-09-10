# Cold Open — A Clone Wars Quote Widget

**Status:** Draft — for review
**Owner:** Aira Nicole de Castro
**Platforms:** iOS · Android · macOS · Windows
**Classification:** Fan project — non-commercial

> A home-screen widget that surfaces a random line from a *Star Wars: The Clone Wars* pre-credits cold open — the narrator's line that opens every episode before the title card — and lets people share it in one tap.

Full designed version: see the [PRD artifact](https://claude.ai/code/artifact/a9dc14cf-86c8-47a1-a63b-cb4e1f451a62).

## 1. Overview

Every episode of *The Clone Wars* opens with a newsreel-style narrator setting the wartime scene, closing on a single quotable line before the titles hit ("Heroes are made by the path they choose, not the powers they are graced with"). Those lines don't live anywhere as a browsable collection today. This widget puts one on the home screen — glance at it, get a new one, tap to share it.

## 2. Goals & Metrics

- **D30 retention ≥ 40%** — widget still on the home screen 30 days after add.
- **1 in 5 sessions ends in a share**, not just a refresh.
- **< 150ms** from tap-to-refresh to new quote rendered.

## 3. Users & Use Cases

- **The rewatcher** — wants a low-effort daily touchpoint with the show without opening a streaming app.
- **The poster** — wants a caption-ready line fast; the quote is the content.
- **The gifter of vibes** — shares a quote card straight into a group chat mid-conversation.

## 4. Feature Scope

| Requirement | Priority | Detail |
|---|---|---|
| Randomized quote display | P0 | One quote at a time, random, no-repeat-until-exhausted. |
| Manual refresh | P0 | Tap swaps in a new quote without opening the app. |
| Scheduled auto-refresh | P1 | Rotates on a user-set cadence within OS widget budgets. |
| Tap-to-share | P0 | Opens OS share sheet with a generated share card. |
| Platform-native share targets | P0 | Instagram Stories, X, Facebook, generic OS share sheet. |
| Multiple widget sizes | P0 | Small / medium / large per OS widget spec. |
| Save / favorite a quote | P1 | Pins a quote out of the randomize/auto-refresh pool. |
| Companion app quote browser | P1 | Full searchable list by episode/arc. |
| Faction-themed widget skins | P2 | Republic / Separatist / Jedi / Mandalorian palettes. |
| Lock screen widget | P2 | iOS 16+ lock screen family, Android AOD equivalent. |

## 5. Quote Content

Scoped to **cold open narration lines only** — not general in-episode dialogue (a separate, larger effort for later).

- **Fields per quote:** text, episode title, season/episode number, story arc.
- **Source of truth:** static, versioned JSON/SQLite bundle shipped with the app — no live backend needed for v1 (~130 episodes, finite corpus).
- **Attribution always on:** every quote and share card credits *Star Wars: The Clone Wars* and its episode of origin.

## 6. Sharing

Sharing generates an image card on-device at share time (themed background, quote in the display face, attribution line, small wordmark), exported at 1080×1920 (Stories/Reels) and 1080×1080 (feed). iOS uses `UIActivityViewController`; Android uses `Intent.ACTION_SEND` with image MIME type; Instagram Stories uses its sticker/background API where available, otherwise falls back to the OS share sheet.

## 7. Design Direction

Clean, minimal, Clone Wars-themed, beautiful — in that priority order. Deep space-navy/gunmetal grounds, one desaturated Republic-blue accent, generous negative space. Condensed display face for the quote itself, quiet sans for attribution. Refresh transitions as a quick sub-200ms wipe/holo-flicker, never a spinner. One accent color and at most one faction emblem per widget instance.

## 8. Platform Notes

| Platform | Framework | Constraint |
|---|---|---|
| iOS / iPadOS | WidgetKit (Swift) | System-budgeted timeline reloads (~40–70/day); tap-to-refresh needs a deep link + App Intent. |
| Android | Jetpack Glance / App Widgets | RemoteViews layout limits; custom fonts need a bitmap fallback on older API levels. |
| macOS | WidgetKit (shared with iOS) | Same target via shared code; Notification Center + desktop placement. |
| Windows | Widgets Board API | Least mature API of the four; ship after iOS/Android/macOS are stable. |

## 9. Non-Functional Requirements

- **Offline-first:** full corpus ships in the bundle; widget never blocks on network to render.
- **Accessibility:** WCAG AA contrast at every widget size; VoiceOver/TalkBack reads quote + attribution as one label.
- **Battery/refresh budget:** auto-refresh respects each OS's widget timeline budget.
- **Localization:** English-only for v1; layout shouldn't assume it stays that way.

## 10. Out of Scope (v1)

- General in-episode dialogue quotes beyond the cold open line.
- User-submitted or user-edited quotes.
- Monetization, ads, or in-app purchase (see licensing risk).
- Android tablet / foldable-specific layouts.
- Audio playback of the narrator's actual voice line.

## 11. Risks & Open Questions

- **High — IP ownership.** *The Clone Wars* is Lucasfilm/Disney property. Scoped as non-commercial with no ads/paywall and full attribution, but public-store distribution still carries takedown risk. Confirm distribution plan (sideload/TestFlight vs. public listing) before investing in store-specific polish.
- **Medium — Widget refresh limits.** iOS's timeline budget may make tap-to-refresh feel less snappy than the <150ms goal; needs an early spike against real WidgetKit budgets.
- **Low — Corpus completeness.** Not every cold open narration line is easy to source verbatim; needs a transcription + fact-check pass.

## 12. Milestones

| Phase | Scope | Exit criteria |
|---|---|---|
| M1 — Corpus & core widget | Quote data built; iOS + Android small/medium widget, manual refresh | Installable, shows real random quotes, no crashes |
| M2 — Sharing | Share card generation, share sheet wiring, IG/X/FB targets | Quote can go from widget tap to posted story in <10s |
| M3 — Polish & scheduled refresh | Large widget size, auto-refresh cadence, favorites | D30 retention measured against §2 goal |
| M4 — macOS / Windows | Port widget target to desktop platforms | Feature parity with mobile P0 scope |

---
*Not affiliated with or endorsed by Lucasfilm or Disney.*
