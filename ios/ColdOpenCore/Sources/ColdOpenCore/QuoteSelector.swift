import Foundation

/// Picks quotes at random without repeating one until the whole corpus has
/// been shown once, then reshuffles.
///
/// A WidgetKit extension process is short-lived and effectively stateless
/// between timeline reloads, so this class stays free of that persistence
/// concern — it exposes `shownTexts` so a caller can persist it (e.g. into
/// an App Group `UserDefaults` suite shared between the app and widget
/// extension) and pass it back in as `alreadyShown` on the next
/// `TimelineProvider` call, keyed on `Quote.text` — the same uniqueness key
/// the corpus validator already enforces (`scripts/validate-corpus.js`
/// rejects duplicate `text` values), since `Quote` has no separate numeric
/// id at this layer. The actual `UserDefaults`/App Group read-write lives
/// in `ColdOpenWidget.swift`, not here — see TASKS.md for that wiring, and
/// why the App Group's actual registration (Signing & Capabilities, tied to
/// a real Apple ID) is a separate, interactive step this scaffold can
/// prepare for but not complete.
public final class QuoteSelector {
    private let allQuotes: [Quote]
    private var pool: [Quote]
    private var shown: Set<String>

    public init(quotes: [Quote], alreadyShown: Set<String> = []) {
        self.allQuotes = quotes
        self.pool = quotes.filter { !alreadyShown.contains($0.text) }
        self.shown = alreadyShown
    }

    /// Text of every quote drawn since construction (or resumed via `alreadyShown`).
    public var shownTexts: Set<String> { shown }

    /// Returns a random quote, removing it from the pool. Refills the pool
    /// (and clears `shownTexts`) once it's exhausted — including
    /// immediately, if resuming with every quote already marked shown.
    /// Returns `nil` only if the corpus itself is empty.
    public func next() -> Quote? {
        if pool.isEmpty {
            pool = allQuotes
            shown.removeAll()
        }
        guard !pool.isEmpty else { return nil }
        let index = Int.random(in: 0..<pool.count)
        let quote = pool.remove(at: index)
        shown.insert(quote.text)
        return quote
    }
}
