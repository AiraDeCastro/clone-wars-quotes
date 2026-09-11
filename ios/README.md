# iOS & macOS Scaffold

This is a source-level scaffold for the iOS app + widget extension, and the shared macOS app + widget extension, written and reviewed on a Windows machine with no Swift toolchain, Xcode, or XcodeGen available. **Nothing in here has been compiled, opened in Xcode, or run in Simulator/on a Mac yet.** Treat it as a strong starting point, not a verified build — that verification is the first thing to do on a Mac.

## What's here

- `project.yml` — an [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec defining **four targets**: `ColdOpen` + `ColdOpenWidgetExtension` (iOS), `ColdOpenMac` + `ColdOpenWidgetExtensionMac` (macOS). `.xcodeproj` files are fragile, hand-edited plist/binary structures that are unsafe to author or patch without Xcode itself to verify them, so this repo defines the project declaratively instead and generates the real Xcode project from it.
- `ColdOpen/` — the app SwiftUI source, compiled into **both** `ColdOpen` (iOS) and `ColdOpenMac` (macOS) — the same files, not a copy. `ContentView.swift` is a placeholder that just proves the app can load the shared corpus; the real companion browser is a P1 task (see [TASKS.md](../TASKS.md) M3).
- `ColdOpenWidget/` — the WidgetKit extension source, likewise compiled into **both** `ColdOpenWidgetExtension` (iOS) and `ColdOpenWidgetExtensionMac` (macOS): a `TimelineProvider` + SwiftUI view supporting small and medium widget families. Verified by inspection that nothing in it is iOS-only (plain SwiftUI/WidgetKit/Foundation, no `#if os(iOS)`) — this is genuine shared code per PLANNING.md's "macOS: WidgetKit (shared with iOS)" note, not just a shared corpus.
- `ColdOpenMac/`, `ColdOpenWidgetMac/` — hold *only* each macOS target's `Info.plist` (distinct from the iOS ones, since macOS doesn't need `UILaunchScreen`/interface-orientation keys). No Swift source lives here; it's all in `ColdOpen/` and `ColdOpenWidget/` above.
- `ColdOpenCore/` — a local Swift package with no Apple-only imports (pure `Foundation`), declaring both `.iOS(.v16)` and `.macOS(.v13)` platform support, shared by all four targets: the `Quote` model, the corpus loader, and a `QuoteSelector` implementing random-no-repeat-until-exhausted selection. Because it has no UIKit/WidgetKit dependency, this package alone can be built and tested with `swift test` on any Mac (or Linux with Swift installed) without needing Xcode at all — the fastest way to verify the actual logic before touching the Xcode project. **No separate corpus sync step is needed for macOS** — it reads the exact same bundled resource `npm run sync:ios` already keeps current.

## Setup (macOS required from here on)

```bash
brew install xcodegen
cd ios
xcodegen generate
open ColdOpen.xcodeproj
```

Opening the generated project gives you all four schemes (`ColdOpen`, `ColdOpenWidgetExtension`, `ColdOpenMac`, `ColdOpenWidgetExtensionMac`) in one workspace.

Before generating, make sure the bundled corpus resource is current:

```bash
npm run sync:ios
```

(from the repo root — copies `corpus/quotes.json` into `ColdOpenCore/Sources/ColdOpenCore/Resources/quotes.json`. Not automated into an Xcode build phase yet; see TASKS.md.)

## Verify the logic first, then the app

```bash
cd ios/ColdOpenCore
swift test
```

This runs `QuoteSelectorTests` and `QuoteCorpusTests` without needing the Xcode project generated at all. If this fails, nothing built on top of it will work either.

Then, in Xcode: select the `ColdOpen` scheme, run on the iOS Simulator, and separately add the `ColdOpenWidget` widget to a Simulator home screen to check it renders. For macOS, select `ColdOpenMac`, run it directly on the Mac (no simulator needed), and check the widget via the macOS widget gallery (Notification Center / desktop, depending on macOS version).

## Known gaps (see TASKS.md for the tracked version of this list)

- **Not yet built or run anywhere, on either platform.** First real task on a Mac: does `xcodegen generate` even produce a project with all four targets without collision? Untested — this is the first time a project this shape (two application targets + two widget extensions, sharing one package and two source directories) has been generated here.
- **No-repeat selection doesn't persist across widget reloads.** `QuoteSelector`'s in-memory state doesn't survive a WidgetKit extension process relaunch; the widget currently just uses `randomElement()`. Needs shared storage (App Group `UserDefaults`) to actually satisfy the no-repeat requirement at the widget level — true on both iOS and macOS.
- **No manual-refresh App Intent yet.** The timeline provider uses `.never` as its reload policy; wiring an `AppIntent` for a "refresh" button is still open.
- **No app icon or launch screen assets, on either platform.** iOS `Info.plist` references `AppIcon` but no asset catalog exists yet; the macOS `Info.plist` doesn't reference an icon at all yet.
- **No accessibility/contrast verification** — can't check WCAG AA without rendering the widget.
- **`ENABLE_HARDENED_RUNTIME: true`** is set on both macOS targets as a reasonable default for eventual notarization, but hasn't been verified to build cleanly — if it causes issues before code signing is set up, it's safe to drop for local development.
