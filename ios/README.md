# iOS & macOS Scaffold

This is a source-level scaffold for the iOS app + widget extension, and the shared macOS app + widget extension, written and reviewed on a Windows machine with no Swift toolchain, Xcode, or XcodeGen available. **Nothing in here has been compiled, opened in Xcode, or run in Simulator/on a Mac yet.** Treat it as a strong starting point, not a verified build — that verification is the first thing to do on a Mac.

## What's here

- `project.yml` — an [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec defining **four targets**: `ColdOpen` + `ColdOpenWidgetExtension` (iOS), `ColdOpenMac` + `ColdOpenWidgetExtensionMac` (macOS). `.xcodeproj` files are fragile, hand-edited plist/binary structures that are unsafe to author or patch without Xcode itself to verify them, so this repo defines the project declaratively instead and generates the real Xcode project from it.
- `ColdOpen/` — the app SwiftUI source, compiled into **both** `ColdOpen` (iOS) and `ColdOpenMac` (macOS) — the same files, not a copy. `ContentView.swift` is a placeholder that just proves the app can load the shared corpus; the real companion browser is a P1 task (see [TASKS.md](../TASKS.md) M3).
- `ColdOpenWidget/` — the WidgetKit extension source, likewise compiled into **both** `ColdOpenWidgetExtension` (iOS) and `ColdOpenWidgetExtensionMac` (macOS): a `TimelineProvider` + SwiftUI view supporting small and medium widget families. Verified by inspection that nothing in it is iOS-only (plain SwiftUI/WidgetKit/Foundation, no `#if os(iOS)`) — this is genuine shared code per PLANNING.md's "macOS: WidgetKit (shared with iOS)" note, not just a shared corpus.
- `ColdOpenMac/`, `ColdOpenWidgetMac/` — hold each macOS target's `Info.plist` (distinct from the iOS ones, since macOS doesn't need `UILaunchScreen`/interface-orientation keys) and, as of the App Group work below, `ColdOpenWidgetMac.entitlements`. No Swift source lives here; it's all in `ColdOpen/` and `ColdOpenWidget/` above.
- `ColdOpenWidget/ColdOpenWidget.entitlements`, `ColdOpenWidgetMac/ColdOpenWidgetMac.entitlements` — declare the `com.apple.security.application-groups` capability for the App Group `QuoteSelector`'s persistence uses. **The files exist; the App Group itself isn't registered anywhere yet** — see "No-repeat persistence" below.
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

(from the repo root — copies `corpus/quotes.json` into `ColdOpenCore/Sources/ColdOpenCore/Resources/quotes.json`.)

**This is staying a manual step on purpose, not just an unfinished automation.** The obvious fix — an XcodeGen `preBuildScripts` Run Script phase on the `ColdOpen`/`ColdOpenMac` targets — almost certainly runs too late to help: those targets depend on the `ColdOpenCore` *package*, and a package's own resources are bundled when the package target itself builds, which happens as part of resolving that dependency, before the depending target's own build phases (including its pre-build scripts) execute. By the time a Run Script phase on `ColdOpen` ran, `ColdOpenCore`'s resource bundle would likely already be sealed from whatever `quotes.json` existed beforehand.

The SPM-native way to actually hook into a package's own build is a [build tool plugin](https://github.com/apple/swift-package-manager/blob/main/Documentation/Plugins.md) — but those have a documented rough edge for exactly this case ([swift-package-manager#7120](https://github.com/apple/swift-package-manager/issues/7120): packages with build-tool-plugin-generated resources don't reliably synthesize a `Bundle.module` accessor), which `QuoteCorpus.load()` depends on. Given that, and given there's no way to test either approach here, the manual step stays — it's simple, it already works, and it's called out at the top of every setup path in this README rather than silently assumed. If someone wants to revisit automating this, a build tool plugin is the right direction, but budget time to work around the `Bundle.module` issue.

## Verify the logic first, then the app

```bash
cd ios/ColdOpenCore
swift test
```

This runs `QuoteSelectorTests` and `QuoteCorpusTests` without needing the Xcode project generated at all. If this fails, nothing built on top of it will work either.

Then, in Xcode: select the `ColdOpen` scheme, run on the iOS Simulator, and separately add the `ColdOpenWidget` widget to a Simulator home screen to check it renders. For macOS, select `ColdOpenMac`, run it directly on the Mac (no simulator needed), and check the widget via the macOS widget gallery (Notification Center / desktop, depending on macOS version).

## No-repeat persistence: the App Group is prepared, not registered

`QuoteSelector` (in `ColdOpenCore`) now takes an `alreadyShown` set and exposes `shownTexts`, and `ColdOpenWidget.swift`'s `nextQuote()` reads/writes that via `UserDefaults(suiteName: WidgetAppGroup.identifier)` — the same pattern already implemented for Android (`SharedPreferences`) and Windows (`CustomState`), mirrored on purpose. `ColdOpenWidget.entitlements` and `ColdOpenWidgetMac.entitlements` declare the App Group `group.com.coldopen.app`, wired into `project.yml` via `CODE_SIGN_ENTITLEMENTS`.

**This is different from the corpus-sync question above.** That one was a pure build-mechanics question, resolvable by reading docs — this one genuinely needs an interactive step no amount of research from here resolves: registering an App Group requires opening Signing & Capabilities in Xcode for `ColdOpenWidgetExtension` (and `ColdOpenWidgetExtensionMac`), adding the App Groups capability, and it being tied to a real Apple ID/team's provisioning. Checked this deliberately rather than assumed either way — Apple Developer Forum threads confirm App Group registration is genuinely account-tier/provisioning-dependent in a way the file-format questions elsewhere in this repo weren't.

Until that registration happens, `UserDefaults(suiteName:)` returns `nil` and `nextQuote()` falls back to un-persisted random selection rather than crashing — so the widget still works, it just won't be truly no-repeat until the App Group is actually set up.

## Known gaps (see TASKS.md for the tracked version of this list)

- **Not yet built or run anywhere, on either platform.** First real task on a Mac: does `xcodegen generate` even produce a project with all four targets without collision? Untested — this is the first time a project this shape (two application targets + two widget extensions, sharing one package and two source directories) has been generated here.
- **No-repeat persistence is wired but the App Group isn't registered** — see the section above. Works today as un-persisted random selection; needs a real Apple ID + Signing & Capabilities step to become truly no-repeat.
- **Manual-refresh App Intent is wired but unverified.** `RefreshQuoteIntent` (in `ColdOpenWidget.swift`) calls `WidgetCenter.shared.reloadTimelines(ofKind:)`, triggered by a `Button(intent:)` in the widget's attribution row; the timeline provider itself still uses `.never` since this intent is what forces the reload. No Swift toolchain here to confirm the `AppIntent` conformance actually compiles.
- **App icon done, launch screen still minimal.** [AppIcon.xcassets](AppIcon.xcassets) has the real "Cold Open Wipe + Starfield" icon (see `scripts/gen-app-icon.py` at the repo root — generated pixel-exact from the approved concept, not hand-drawn; a deliberately restrained 3-star treatment, pixel-tested at small sizes after a denser version looked noisy), wired into both app targets. Not yet confirmed inside Xcode itself. No launch screen beyond the existing empty `UILaunchScreen` dict.
- **No accessibility/contrast verification** — can't check WCAG AA without rendering the widget.
- **Share flow is wired but unverified.** Tapping the widget's new share icon deep-links via `coldopen://share?...` (encoded/decoded by `ColdOpenCore`'s `ShareDeepLink`, registered in `Info.plist`'s `CFBundleURLTypes`) into `ColdOpenApp.swift`, which renders the card with `ShareCardRenderer` and presents a `UIActivityViewController` (`ShareSheet.swift`) — deliberately chosen over `ShareLink` since it can present without an extra in-app tap. No Swift toolchain to confirm any of it compiles or that a `Link` and a `Button(intent:)` genuinely coexist as separate tap targets in one widget, which is a newer, less certain corner of WidgetKit than the single refresh button already shipped.
- **`ENABLE_HARDENED_RUNTIME: true`** is set on both macOS targets as a reasonable default for eventual notarization, but hasn't been verified to build cleanly — if it causes issues before code signing is set up, it's safe to drop for local development.
