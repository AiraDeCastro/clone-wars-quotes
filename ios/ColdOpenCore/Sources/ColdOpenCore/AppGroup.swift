import Foundation

/// The App Group shared between the widget extension and the container
/// app — used by `QuoteSelector`'s "already shown" persistence (see
/// `ColdOpenWidget.swift`) and by `FavoritesStore`. Pulled out to Core,
/// rather than left as a private constant in the widget target, because
/// `FavoritesStore` needs the same identifier from the app target too —
/// two separate compiled modules, so a private constant in one can't
/// reach the other (same reason `ShareDeepLink` lives here).
///
/// **Not yet registered anywhere.** See `ios/README.md`'s "No-repeat
/// persistence" section for the full explanation — it's an interactive
/// Signing & Capabilities step tied to a real Apple ID/team, not
/// something resolvable from source alone. Every reader of this
/// identifier already degrades gracefully when the suite isn't
/// available: `UserDefaults(suiteName:)` returns `nil` rather than
/// crashing.
public enum AppGroup {
    public static let identifier = "group.com.coldopen.app"
}
