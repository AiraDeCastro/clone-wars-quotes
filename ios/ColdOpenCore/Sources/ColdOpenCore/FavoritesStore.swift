import Foundation

/// Shared favorite-quote storage — written by the container app (the
/// quote browser's favorite toggle, see `ContentView.swift`) and read by
/// the widget (to exclude favorites from the randomize/auto-refresh
/// pool, see `ColdOpenWidget.swift`), via the same App Group suite
/// `QuoteSelector`'s "already shown" persistence already uses.
///
/// The `UserDefaults` instance is injected rather than looked up
/// internally via `AppGroup.identifier`, so this stays testable without
/// a real App Group — callers pass `UserDefaults(suiteName:
/// AppGroup.identifier)` (or `nil`, which this degrades gracefully
/// from, same as the rest of this App Group's readers).
public struct FavoritesStore {
    private static let key = "favoriteQuoteTexts"
    private let defaults: UserDefaults?

    public init(defaults: UserDefaults?) {
        self.defaults = defaults
    }

    public var favoriteTexts: Set<String> {
        Set(defaults?.stringArray(forKey: Self.key) ?? [])
    }

    public func isFavorite(_ quote: Quote) -> Bool {
        favoriteTexts.contains(quote.text)
    }

    public func toggleFavorite(_ quote: Quote) {
        var favorites = favoriteTexts
        if favorites.contains(quote.text) {
            favorites.remove(quote.text)
        } else {
            favorites.insert(quote.text)
        }
        defaults?.set(Array(favorites), forKey: Self.key)
    }
}
