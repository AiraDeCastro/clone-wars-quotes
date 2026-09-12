# CLAUDE.md

Guidance for Claude Code sessions working in this repo. Full product context lives in [docs/PRD.md](docs/PRD.md) — read it before scoping any feature work; this file is the condensed, enforceable subset.

## Session workflow — do this every time

- **Read [PLANNING.md](PLANNING.md) at the start of every new conversation.** It has the vision, architecture, and tech stack — don't start designing or picking tools without it.
- **Check [TASKS.md](TASKS.md) before starting work.** Find the relevant milestone and task; don't duplicate or contradict what's already tracked there.
- **Mark tasks complete in TASKS.md immediately** when finished — not batched at the end of a session.
- **Add newly discovered tasks to TASKS.md as soon as they're found** — under the right milestone if they fit, otherwise under Backlog or Open items. Don't let discovered work go untracked.

## What this project is

**Cold Open** — a home-screen widget (iOS, Android, later macOS/Windows) that shows a random quote from a *Star Wars: The Clone Wars* pre-credits cold open, and lets the user share it in one tap. The widget is the product — there is no requirement to open a companion app for the core loop (get quote → share quote).

Fan project. Non-commercial: no ads, no paywall, no in-app purchase, ever, unless the user explicitly changes this constraint in conversation. Every quote and share card must carry attribution to *Star Wars: The Clone Wars* and its episode of origin — never drop attribution to simplify a layout.

## Content scope — do not drift

The quote corpus is **cold open narration lines only** (the narrator's line right before the title card), not general episode dialogue. If a task implies pulling in arbitrary in-episode quotes, stop and confirm with the user first — that's explicitly a separate, later effort per the PRD, not a natural extension of this one.

Quote data model, per entry: `text`, `episodeTitle`, `season`, `episode`, `arc`. Treat this as the stable schema; changes to it affect every platform's widget code and the share-card renderer, so surface schema changes explicitly rather than making them incidentally while working on one platform.

## Architecture

- **Data is static and offline-first.** The full quote corpus (~130 episodes) ships bundled with the app as versioned JSON/SQLite. No live backend for v1 — don't introduce a network dependency for rendering the widget.
- **Platform-native widgets, shared data layer.** iOS/macOS use WidgetKit (Swift), and genuinely share the same widget source code between them — see `ios/project.yml`'s `ColdOpenMac`/`ColdOpenWidgetExtensionMac` targets, which compile `ios/ColdOpen`/`ios/ColdOpenWidget` unmodified. Android uses Jetpack Glance / App Widgets (Kotlin); Windows uses the Widgets Board API (treat as stretch — build after the other three are stable). Across that iOS/Android/Windows boundary, widget rendering code is platform-specific; keep the quote corpus and quote-selection logic platform-agnostic where the platform allows it.
- **Share cards are generated on-device at share time** — themed background + quote + attribution line, exported at 1080×1920 and 1080×1080. Don't pre-render or cache share images server-side; there is no server.

## Priority discipline (from the PRD)

When picking up unscoped or ambiguous work, default to P0 before P1, and don't start P2 work without the user asking for it by name:

- **P0:** randomized quote display, manual refresh, tap-to-share, native share targets (IG/X/Facebook/OS sheet), small/medium/large widget sizes.
- **P1:** scheduled auto-refresh, favorites, companion quote browser.
- **P2:** faction-themed skins, lock screen widget.

## Explicitly out of scope (v1)

Don't add these without the user asking first — they were deliberately cut:

- General in-episode dialogue quotes beyond the cold open line
- User-submitted/edited quotes
- Any monetization, ads, or IAP
- Android tablet/foldable-specific layouts
- Audio playback of the narrator's actual voice line (real licensing exposure, distinct from text quotes)

## Non-functional constraints

- Respect each OS's widget refresh/timeline budget — don't work around it with background polling or foreground services just to hit the <150ms refresh goal; that goal is aspirational within the OS's real constraints, not a license to fight the platform.
- Widget text must hit WCAG AA contrast at every size; VoiceOver/TalkBack should read quote + attribution as a single label, not two.
- v1 is English-only; don't hardcode layout assumptions that make later localization harder for free.

## IP awareness

*The Clone Wars* is Lucasfilm/Disney property. This project's non-commercial framing (no ads, no paywall, full attribution) is the whole basis for it being reasonable to build — don't introduce anything that erodes that (monetization, removing attribution, claiming original authorship of quotes). If a task pushes toward public app-store distribution specifics, flag it — that decision (sideload/TestFlight vs. public listing) hasn't been made yet per the PRD's open risks.

## Design direction

Clean, minimal, Clone Wars-themed, beautiful — in that priority order. Deep space-navy/gunmetal grounds, one desaturated accent color per widget instance, generous negative space around the quote text. At most one faction emblem, and only at the large widget size. Refresh transitions should be quick (sub-200ms) and subtle — a wipe or flicker, never a loading spinner.

## Environment note

Claude Code sessions on this project have so far run on a **Windows 11 machine with no Swift toolchain, no Xcode, no XcodeGen, no JDK, no Android SDK, no Gradle, and no .NET SDK/MSBuild/Visual Studio available**. The `ios/`, `android/`, and `windows/` scaffolds were all written and reviewed here but **never compiled or run** — see [ios/README.md](ios/README.md), [android/README.md](android/README.md), and [windows/README.md](windows/README.md) for exactly what is and isn't verified in each. Note that the Windows scaffold is the one case where the *target* OS matches this machine — it's specifically the missing .NET toolchain that blocks it, not the wrong platform. Don't claim an iOS, Android, or Windows build, test run, or Simulator/emulator/Widgets-Board check "passes" unless it was actually run with the required toolchain in that session — check TASKS.md for what's genuinely confirmed vs. just written.

For niche or fast-moving platform APIs (the Windows Widget Service API was the first case of this) — where training-data memory is less reliable than for something as well-documented as WidgetKit or Jetpack Glance — fetch current official docs before scaffolding rather than reconstructing the API from memory. Say explicitly in the resulting README which parts came from a verified doc vs. which are extrapolated.

## Commit standards

This repo enforces quality gates and a commit format via git hooks (husky) — see [PLANNING.md](PLANNING.md#quality-gates) for what each gate checks.

- **Every commit message must follow [Conventional Commits](https://www.conventionalcommits.org/):** `type(scope): subject` — e.g. `feat(ios): add small widget layout`, `fix(corpus): correct season number for Rookies`, `docs: update PRD milestone table`. Common types: `feat`, `fix`, `docs`, `build`, `test`, `refactor`, `chore`. The commit-msg hook (commitlint) rejects anything else.
- **Never bypass the hooks** (`--no-verify`) to force a commit through. If `npm run lint`, `npm test`, `npm run build`, or `npm run audit` fails, fix the underlying issue — a failing gate is real signal, not friction to route around. This matches the general git safety rule already in effect for this project.
- **A failing `npm run audit`** (new dependency vulnerability) should be fixed by upgrading or overriding the vulnerable transitive dependency (see the `overrides` field in `package.json` for a precedent — `smol-toml` was force-upgraded this way rather than downgrading `markdownlint-cli2`), not by lowering `--audit-level` or skipping the check.
- **If a task needs a test that doesn't exist yet, write the test first**, then make it pass — don't commit new corpus/tooling logic without corresponding coverage in `tests/`.

## Session summary

**2026-09-09**

- Wrote the initial PRD (published as a designed artifact and as [docs/PRD.md](docs/PRD.md)), scoping the widget: randomized cold-open quotes, one-tap social sharing, iOS/Android/macOS/Windows.
- Initialized this repo and pushed it to GitHub as a public repo: [AiraDeCastro/clone-wars-quotes](https://github.com/AiraDeCastro/clone-wars-quotes).
- Generated this file (CLAUDE.md), [PLANNING.md](PLANNING.md), and [TASKS.md](TASKS.md) from the PRD, then added the session workflow rules above (read PLANNING.md every session, check/update TASKS.md continuously).
- Started M1's quote-corpus task: created [corpus/quotes.json](corpus/quotes.json) with the schema and one verified seed entry, and [corpus/README.md](corpus/README.md) explaining why the remaining ~129 quotes weren't bulk-transcribed from memory (copyright + accuracy risk — see PRD §11) and how to fill them in properly. TASKS.md updated to reflect this: schema task checked off, transcription task left open with the blocker noted, and a new task added for sourcing the rest of the corpus from a legitimate transcript source.
- Set up the pre-commit quality pipeline: husky-managed `pre-commit` hook running markdown/corpus lint, the new corpus test suite ([tests/corpus.test.js](tests/corpus.test.js)), a corpus build/validation step ([scripts/validate-corpus.js](scripts/validate-corpus.js)), and `npm audit`; a `commit-msg` hook running commitlint to enforce Conventional Commits. Hit and fixed 2 high-severity vulnerabilities in the tooling's own dependencies (`smol-toml`, via a `package.json` override) before wiring the audit gate. Verified the hooks actually block a non-conventional commit message and pass a conventional one — this was committed as `build: add pre-commit quality gates and conventional commit enforcement` (commit `1dccdf6`).
- Documented all of this in [PLANNING.md](PLANNING.md) (new Quality Gates section, Node.js added to Required Tools) and this file (new Commit standards section above), plus follow-on TASKS.md items for wiring native iOS/Android lint+build+test into the same hook once those projects are scaffolded.
- The doc updates (PLANNING.md, TASKS.md, this file) made after that commit are still local, pending review before push.

**2026-09-09 (continued) — iOS scaffold**

- Started scaffolding the iOS app under [ios/](ios/): an [XcodeGen](https://github.com/yonaskolb/XcodeGen) `project.yml` (source of truth for the Xcode project, since a `.xcodeproj` isn't safe to hand-author or verify without Xcode), a `ColdOpen` app target, a `ColdOpenWidgetExtension` widget target, and a local `ColdOpenCore` Swift package (pure `Foundation`, shared by both targets) with `Quote`, `QuoteCorpus`, and `QuoteSelector` (the random no-repeat-until-exhausted algorithm), each with XCTest coverage.
- **None of this has been built or run** — no Swift toolchain exists on this machine (confirmed by checking for `swift` and `xcodegen`, both absent). Added the Environment note above so future sessions don't assume otherwise.
- Found and logged a real design gap while writing this: `QuoteSelector`'s in-memory "already shown" state won't survive a WidgetKit extension process reload, so true no-repeat behavior at the widget level needs App Group-shared persistence — not implemented yet, logged as a TASKS.md item rather than papered over.
- Added `npm run sync:ios` (copies `corpus/quotes.json` into the Swift package's bundled resource) — manual for now, not wired into the Node pre-commit hook or an Xcode build phase yet (both noted as open follow-ons).
- TASKS.md updated in detail: the Xcode-setup task is marked as "scaffold written, not yet generated/built," the quote-selection algorithm task is checked off (it's implemented and unit-tested) with a note about the widget-persistence gap, and three new discovered tasks were logged (App Group persistence, wiring the sync script into a build phase, missing app icon asset catalog).
- Committed as `feat(ios): scaffold Xcode project sources via XcodeGen` (commit `781d5f4`) and pushed to `origin/master`.

**2026-09-10 — Android scaffold**

- Scaffolded the Android app under [android/](android/): a two-module Gradle project (version catalog in `gradle/libs.versions.toml`) — `:core`, a pure Kotlin/JVM module (no Android dependency, mirroring `ColdOpenCore` on iOS) with `Quote`, `QuoteCorpus`, and a unit-tested `QuoteSelector`; and `:app`, the Android application module with a placeholder `MainActivity` and a Jetpack Glance `ColdOpenWidget` + `ColdOpenWidgetReceiver`.
- **None of this has been built, synced, or opened** — confirmed no `java`, `gradle`, or Android SDK/`sdkmanager` on this machine. Extended the Environment note above to cover Android as well as iOS.
- Deliberately did **not** fabricate a Gradle wrapper (`gradlew`/`gradlew.bat`/`gradle-wrapper.jar`) — the `.jar` is a real binary bootstrapper that isn't safe to hand-author; documented in `android/README.md` that Android Studio generates it on first open, or `gradle wrapper` does it manually.
- Found and logged the Android-side counterpart to the iOS persistence gap: `QuoteSelector`'s in-memory state doesn't survive restarts here either, but since an Android widget runs in the app's own process (not a separate extension like iOS), the fix is a plain DataStore/SharedPreferences read/write — logged as a follow-on task, not implemented yet.
- Flagged specifically that the `androidx.glance.*` API calls in `ColdOpenWidget.kt` were written from training knowledge and are **not verified** against the actual pinned Glance 1.1.1 API surface — logged as its own TASKS.md item so it isn't mistaken for confirmed-working code.
- Added `npm run sync:android` (copies `corpus/quotes.json` into `app/src/main/assets/quotes.json`) — manual for now, same pattern as `sync:ios`.
- TASKS.md updated in detail: Android Studio/Glance setup marked "scaffold written, not yet built," the quote-selection algorithm checked off with the persistence caveat, and four new discovered tasks logged (DataStore persistence, wiring the sync script into a Gradle task, missing app icon, unverified Glance API calls).
- Committed as `feat(android): scaffold Gradle project sources` (commit `a8fb813`) and pushed to `origin/master`.

**2026-09-10 (continued) — macOS widget target**

- Extended `ios/project.yml` with two new targets, `ColdOpenMac` and `ColdOpenWidgetExtensionMac`, rather than creating a separate `macos/` folder — per PLANNING.md's existing "macOS: WidgetKit (shared with iOS)" note and the user's own framing ("the shared macOS widget target"), these compile the *exact same* `ios/ColdOpen` and `ios/ColdOpenWidget` Swift source as the iOS targets, plus the same `ColdOpenCore` package (which already declared `.macOS(.v13)` support from the start).
- Actually verified by reading both source files first that nothing in them is iOS-only (plain SwiftUI/WidgetKit/Foundation, no `#if os(iOS)`) before wiring them into a macOS target — this is genuine zero-diff code reuse, not an assumption. `containerBackground(for:)` needs macOS 14, so the macOS deployment target is set to 14.0 to match.
- Added `ColdOpenMac/Info.plist` and `ColdOpenWidgetMac/Info.plist` — separate from the iOS ones since macOS doesn't need `UILaunchScreen`/interface-orientation keys, but everything else about the targets points at the shared source.
- **Still nothing built or run** — same environment constraint as before. Flagged as untested specifically: whether `xcodegen generate` handles 2 app targets + 2 widget extensions + 1 shared package in one project without collision (a project shape not tried here before), and the unverified `ENABLE_HARDENED_RUNTIME: true` setting added to both mac targets.
- Refined the "widget rendering is platform-specific" claim in PLANNING.md and this file's Architecture section — it's only true across the iOS/Android/Windows boundary; within Apple's own platforms the rendering code is now demonstrably shared verbatim.
- No new app icon or DataStore/persistence work done here (mac targets have the same open gaps as iOS) — logged as discovered tasks rather than silently carried over.
- Committed as `feat(ios): scaffold shared macOS widget target` (commit `455e9ed`, one non-blocking commitlint footer-spacing warning) and pushed to `origin/master`.

**2026-09-10 (continued) — Windows widget scaffold**

- Before writing any code, recognized that the Windows third-party Widget Service API (`Microsoft.Windows.Widgets.Providers`) is niche enough that scaffolding it from memory alone would be unreliable in a way WidgetKit/Glance weren't — fetched and read Microsoft's current "Implement a widget provider in a C# Windows App" doc in full first, and adapted the COM plumbing from its actual reference code rather than reconstructing it. Added this as a general rule to the Environment note above: fetch docs first for niche/fast-moving platform APIs.
- Confirmed this machine, unlike the iOS/Android cases, actually **is** the target OS (Windows 11 build 26200) — but still has no `dotnet`, `msbuild`, or Visual Studio, so the same "written, not verified" constraint applies, just for a different reason (missing toolchain, not wrong platform).
- Scaffolded [windows/](windows/): `WidgetProvider.Core` (plain `net8.0`, no Windows dependency — mirrors `ColdOpenCore`/`:core`) with `Quote`, `QuoteCorpus`, `QuoteSelector`, and `QuoteCardTemplate` (Adaptive Card JSON), all unit-tested with xUnit; `WidgetProvider` (`ColdOpenWidgetProvider` implementing `IWidgetProvider`, `FactoryHelper` COM boilerplate, `Program.cs` COM registration); `WidgetProvider.Package/Package.appxmanifest` (the widget-provider manifest extensions).
- Caught and fixed my own mistake mid-task: a `replace_all` rename of the class `WidgetProvider` → `ColdOpenWidgetProvider` also silently corrupted the real Microsoft interface name `IWidgetProvider` into a nonexistent `IColdOpenWidgetProvider` (it's a substring match). Reviewed the file, caught it, fixed it with a precise edit instead of another blind replace-all.
- Deliberately did **not** scaffold the actual `.wapproj` packaging project — unlike a plain SDK-style `.csproj`, that project type is Visual-Studio-templated and riskier to hand-author correctly than the Gradle-wrapper-jar/XcodeGen-project precedents already set; documented in `windows/README.md` exactly how to create it and merge in the manifest content instead.
- Noted a genuine positive contrast rather than repeating the same caveat pattern automatically: because `IWidgetProvider`'s `OnActionInvoked` callback is the same interface used for lifecycle events, wiring the "New quote" `Action.Execute` button (manual refresh) came almost for free here, unlike iOS (needs a separate `AppIntent`) or Android (needs separate Glance action wiring, still open).
- Flagged what's doc-grounded vs. extrapolated in `windows/README.md`: the `runFullTrust`/`Windows.FullTrustApplication` packaging bits and the exact `Microsoft.WindowsAppSDK` version pin are reasonable extensions/guesses beyond what the fetched doc itself showed, called out explicitly rather than presented with the same confidence as the doc-adapted COM code.
- Added `npm run sync:windows` (copies `corpus/quotes.json` into `windows/WidgetProvider/quotes.json`), same pattern as the other two platforms.
- TASKS.md updated: the "evaluate Widgets Board maturity" task checked off (the research itself is the deliverable), the widget-build task marked "scaffold written, not built," and five new discovered tasks logged (the `.wapproj` gap, persistence, missing icons, the unverified NuGet version, and adding a `large` size capability later).
- Not yet committed — pending review.
- Committed as `feat(windows): scaffold widget provider via Windows App SDK` (commit `b8385b0`) and pushed to `origin/master`.

**2026-09-10 (continued) — real JSON → SQLite build step**

- Asked to check TASKS.md and pick the next task. Passed over the M1 corpus tasks blocked on copyright/external sourcing and the platform tasks blocked on missing native toolchains (iOS/Android/Windows all still can't be built here), and picked the one clearly unblocked, verifiable, cross-platform-relevant item: the JSON → SQLite build step, which had been a placeholder since M1 setup.
- Discovered Node 24 (installed on this machine) ships `node:sqlite` built in, unflagged — confirmed by actually running a real CREATE TABLE/INSERT/SELECT against it before relying on it. Used that instead of an npm dependency (e.g. better-sqlite3), keeping the tooling's dependency/audit surface exactly as small as it's been since the pre-commit pipeline was set up.
- Wrote the test first (`tests/build-corpus.test.js`: row mapping, sequential ids, idempotent rebuild, empty-corpus edge case), confirmed it failed for the right reason (missing module), then implemented `scripts/build-corpus.js` to make it pass — per this file's own Commit standards section.
- Schema is one `quotes` table with an auto-incrementing `id`, deliberately no other indexes yet — chosen specifically so a future on-device client can query `WHERE id NOT IN (shown_ids) ORDER BY RANDOM() LIMIT 1` instead of loading the whole corpus into memory the way every platform's `QuoteSelector` still does today; documented that reasoning in the script's own header comment, not just in this log.
- Simplified `scripts/validate-corpus.js` back to pure validation (removed its `--build`/`quotes.compiled.json` placeholder logic, now superseded), updated `package.json`'s `build` script, and swapped the gitignored build artifact from `quotes.compiled.json` to `quotes.sqlite` in `.gitignore` and `.markdownlint-cli2.jsonc`.
- Verified end-to-end, not just via the test suite: ran `npm run build` for real and inspected the resulting `corpus/quotes.sqlite` file's actual contents with a separate `node:sqlite` query.
- Logged a new discovered task: no platform (iOS/Android/Windows) actually reads the compiled SQLite file yet — they all still bundle and parse the flat JSON directly. Wiring that up is separate follow-on work, not something to fold into this change.
- Committed as `feat(corpus): implement real JSON to SQLite build step` (commit `a082e48`) and pushed to `origin/master`.

**2026-09-11 — verify the Windows NuGet version pin**

- Asked again to check TASKS.md and pick the next task. Everything else open was still either copyright-blocked (remaining corpus quotes) or toolchain-blocked (iOS/Android/Windows all still can't be built here) — picked the one item that was neither: the Windows scaffold's `Microsoft.WindowsAppSDK` version pin, which TASKS.md and windows/README.md had both explicitly flagged as "a plausible-but-unverified guess."
- This one didn't need any toolchain to resolve — just needed to actually look it up. Fetched the NuGet.org package page directly rather than continuing to guess: current stable is `2.4.0` (not a preview), last updated 2026-08-13. The scaffold's placeholder (`1.6.240923002`) was genuinely stale.
- Updated the pin in [windows/WidgetProvider/WidgetProvider.csproj](windows/WidgetProvider/WidgetProvider.csproj), and updated both places in windows/README.md that called it out as unverified, plus TASKS.md — checked off, with a note that it's still just a version number until a real `dotnet restore` happens on a machine with the .NET SDK.
- Deliberately small, single-purpose change — didn't bundle in unrelated Windows work (e.g. the `.wapproj`, app icons, or the `large` size capability, all still open) just because I was already in that folder.
