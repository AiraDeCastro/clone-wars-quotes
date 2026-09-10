# PLANNING.md

Engineering plan for **Cold Open**. Product requirements live in [docs/PRD.md](docs/PRD.md); operating rules for Claude Code sessions live in [CLAUDE.md](CLAUDE.md). This file is the technical planning layer between the two: why the system is shaped this way, what it's built with, and what has to be installed to work on it.

## Vision

Put one *Star Wars: The Clone Wars* cold-open line on the user's home screen, with zero app-opening required to see it or share it. The widget is the entire product experience — glance, refresh, share. Everything else (companion browser, favorites, skins) exists to support that loop, not to replace it.

Success looks like: the widget survives on people's home screens for months (D30 retention ≥ 40%), and it gets used as a way to talk to other people about the show (1 in 5 sessions ends in a share). See PRD §2 for the full metric set.

## Architecture

```text
┌─────────────────────────────┐
│      Quote corpus (data)     │   versioned JSON/SQLite, bundled with app
│  ~130 episodes, cold-open    │   fields: text, episodeTitle, season,
│  narration lines only        │   episode, arc
└──────────────┬───────────────┘
               │  read at build time / app launch
               ▼
┌─────────────────────────────┐
│   Quote selection logic       │   random, no-repeat-until-exhausted;
│   (shared concept, per-       │   favorites pinned out of the pool
│   platform implementation)    │
└──────────────┬───────────────┘
               ▼
┌─────────────────────────────┐        ┌──────────────────────────┐
│   Platform widget surface     │──tap─▶│  Share card renderer      │
│   iOS/macOS: WidgetKit         │       │  on-device, at share time  │
│   Android: Jetpack Glance      │       │  1080x1920 + 1080x1080 PNG │
│   Windows: Widgets Board       │       └────────────┬─────────────┘
└─────────────────────────────┘                       ▼
                                          ┌──────────────────────────┐
                                          │  OS share sheet            │
                                          │  IG Stories / X / Facebook │
                                          │  / generic share targets   │
                                          └──────────────────────────┘
```

Key architectural decisions:

- **Offline-first, no backend.** The quote corpus is finite (~130 episodes) and doesn't change often enough to justify a server. It ships in the app bundle; the widget never blocks on network to render. This also sidesteps a whole category of infra/hosting cost for a non-commercial project.
- **Platform-native widgets over a cross-platform widget framework.** WidgetKit, Jetpack Glance, and the Windows Widgets Board API are different enough (layout models, refresh budgets, render targets) that a shared cross-platform widget UI layer would fight each OS more than it would save work. The corpus and selection *logic* are shared in concept; the widget *rendering* is not.
- **Share cards are generated, not pre-made.** Rendering the image at share time (rather than shipping pre-rendered assets per quote) keeps the corpus lightweight and makes it trivial to reskin later (P2 faction themes) without regenerating hundreds of images.
- **Companion app is secondary.** It exists for search/browse and favorites management — the widget doesn't depend on it being open, ever.

## Technology Stack

| Layer | Choice | Why |
| --- | --- | --- |
| iOS / iPadOS / macOS widget | Swift + WidgetKit | Native widget framework; macOS widget target shares code with iOS via Catalyst/native. |
| Android widget | Kotlin + Jetpack Glance (App Widgets) | Current recommended Android widget toolkit; Glance abstracts RemoteViews without losing widget-safe rendering. |
| Windows widget | Widgets Board (Widget Service API) | Only native widget surface on Windows; least mature of the four, built last (M4). |
| Quote corpus | JSON (source of truth) → compiled to SQLite for query-friendly access on-device | JSON is easy to hand-edit/review in PRs; SQLite gives cheap random/no-repeat queries at runtime. |
| Share card rendering | Native platform 2D drawing (Core Graphics on iOS, Canvas on Android) | Avoids pulling in a heavy image-composition library for a fairly simple text-over-background layout. |
| Companion app UI (P1) | SwiftUI (iOS/macOS) / Jetpack Compose (Android) | Matches each platform's current native UI toolkit; no cross-platform UI framework needed since there's no shared UI layer to leverage. |
| Version control | Git + GitHub ([AiraDeCastro/clone-wars-quotes](https://github.com/AiraDeCastro/clone-wars-quotes)) | Already set up. |

No cross-platform app framework (React Native, Flutter, etc.) is planned. The four targets are widget-first, native-first surfaces, and the amount of genuinely shared code (corpus + selection rules) is small enough that a cross-platform runtime would add more overhead than it removes.

## Required Tools

To work on this project, a contributor needs:

**All platforms**

- [Git](https://git-scm.com/) + [GitHub CLI (`gh`)](https://cli.github.com/) — repo already initialized and authenticated for this machine.
- [Node.js](https://nodejs.org/) (v20+) — runs the repo's quality-gate tooling (markdown/corpus lint, corpus tests, commit hooks). Dev-only: this does not give the product a backend, see the offline-first decision above.
- Run `npm install` once after cloning — this also installs the pre-commit/commit-msg git hooks via husky's `prepare` script.

**iOS / macOS**

- macOS with [Xcode](https://developer.apple.com/xcode/) (current stable) — required for WidgetKit development and Simulator testing; there is no way around needing a Mac for this target.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) — the `.xcodeproj` isn't checked into the repo; `ios/project.yml` is the source of truth and generates it. Chosen because a `.xcodeproj` is a fragile, largely-binary/plist structure that's unsafe to hand-author or patch without Xcode itself to verify — a declarative YAML spec is diffable and reviewable in PRs instead.
- An Apple Developer account — required to test widgets on a physical device and for any future TestFlight/App Store distribution decision (see PRD §11 IP risk — hold off on public listing until that's resolved).

**Android**

- [Android Studio](https://developer.android.com/studio) (current stable) with the Android SDK — required for Jetpack Glance widget development and the emulator.
- A physical Android device or emulator image running a widget-capable API level for real refresh-budget testing (emulator widget refresh behavior doesn't always match real devices).

**Windows** (M4, later)

- Windows 11 with the Widgets Board platform APIs available — evaluate tooling maturity when this phase starts; not needed for M1–M3.

**Not required**

- No backend/cloud tooling (no server, no database service, no CI deploy target) — the offline-first, static-corpus architecture means the only "infrastructure" is the GitHub repo itself.

## Quality Gates

Enforced today via git hooks (husky), scoped to what actually exists in the repo — markdown docs and the JSON quote corpus. See [CLAUDE.md](CLAUDE.md) for the commit convention these hooks require.

| Gate | `npm run` | What it checks |
| --- | --- | --- |
| Lint | `lint` | `markdownlint-cli2` on every `.md` file; a hand-written schema check (`scripts/validate-corpus.js`) on `corpus/quotes.json` — required fields, types, no duplicate quotes. |
| Test | `test` | Node's built-in test runner (`node --test`) against `tests/corpus.test.js`, covering the corpus validator's rules. |
| Build | `build` | Re-runs corpus validation and writes `corpus/quotes.compiled.json` (gitignored) — a placeholder for the real JSON → SQLite compile step (still open, see TASKS.md M1). |
| Dependency audit | `audit` | `npm audit --audit-level=moderate` against this repo's own devDependencies (husky, commitlint, markdownlint-cli2). |

All four run on `git commit` via `.husky/pre-commit`; a failing step blocks the commit. `.husky/commit-msg` separately runs commitlint against the commit message.

**This does not yet cover native app code**, because no iOS/Android project has been scaffolded (TASKS.md M1). Once those exist, this table gets new rows — SwiftLint + `xcodebuild`/XCTest for iOS, ktlint + Gradle/JUnit for Android — wired into the same pre-commit hook rather than replacing it. Tracked as follow-on tasks in TASKS.md.
