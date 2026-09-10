# iOS Scaffold

This is a source-level scaffold for the iOS app + widget extension, written and reviewed on a Windows machine with no Swift toolchain, Xcode, or XcodeGen available. **Nothing in here has been compiled, opened in Xcode, or run in Simulator yet.** Treat it as a strong starting point, not a verified build — that verification is the first thing to do on a Mac.

## What's here

- `project.yml` — an [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec. `.xcodeproj` files are fragile, hand-edited plist/binary structures that are unsafe to author or patch without Xcode itself to verify them, so this repo defines the project declaratively instead and generates the real Xcode project from it.
- `ColdOpen/` — the app target (SwiftUI). `ContentView.swift` is a placeholder that just proves the app can load the shared corpus; the real companion browser is a P1 task (see [TASKS.md](../TASKS.md) M3).
- `ColdOpenWidget/` — the WidgetKit extension target: a `TimelineProvider` + SwiftUI view supporting small and medium widget families.
- `ColdOpenCore/` — a local Swift package with no Apple-only imports (pure `Foundation`), shared by both targets: the `Quote` model, the corpus loader, and a `QuoteSelector` implementing random-no-repeat-until-exhausted selection. Because it has no UIKit/WidgetKit dependency, this package alone can be built and tested with `swift test` on any Mac (or Linux with Swift installed) without needing Xcode at all — the fastest way to verify the actual logic before touching the Xcode project.

## Setup (macOS required from here on)

```bash
brew install xcodegen
cd ios
xcodegen generate
open ColdOpen.xcodeproj
```

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

Then, in Xcode: select the `ColdOpen` scheme, run on the iOS Simulator, and separately add the `ColdOpenWidget` widget to a Simulator home screen to check it renders.

## Known gaps (see TASKS.md for the tracked version of this list)

- **Not yet built or run anywhere.** First real task on a Mac: does `xcodegen generate` + a Simulator run actually work?
- **No-repeat selection doesn't persist across widget reloads.** `QuoteSelector`'s in-memory state doesn't survive a WidgetKit extension process relaunch; the widget currently just uses `randomElement()`. Needs shared storage (App Group `UserDefaults`) to actually satisfy the no-repeat requirement at the widget level.
- **No manual-refresh App Intent yet.** The timeline provider uses `.never` as its reload policy; wiring an `AppIntent` for a "refresh" button is still open.
- **No app icon or launch screen assets.** `Info.plist` references `AppIcon` but no asset catalog exists yet.
- **No accessibility/contrast verification** — can't check WCAG AA without rendering the widget.
