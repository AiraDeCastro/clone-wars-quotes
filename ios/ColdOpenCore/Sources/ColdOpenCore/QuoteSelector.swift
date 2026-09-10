import Foundation

/// Picks quotes at random without repeating one until the whole corpus has
/// been shown once, then reshuffles.
///
/// NOTE: this only tracks state in memory. A WidgetKit extension process is
/// short-lived and effectively stateless between timeline reloads, so using
/// this directly inside a `TimelineProvider` will NOT stay no-repeat across
/// reloads — that needs the "already shown" set persisted somewhere shared
/// between reloads (e.g. an App Group `UserDefaults` suite). Tracked as an
/// open task in TASKS.md; this type is correct and unit-tested, it just
/// isn't wired to persistent storage yet.
public final class QuoteSelector {
    private let allQuotes: [Quote]
    private var pool: [Quote]

    public init(quotes: [Quote]) {
        self.allQuotes = quotes
        self.pool = quotes
    }

    /// Returns a random quote, removing it from the pool. Refills the pool
    /// from the full corpus once it's exhausted. Returns `nil` only if the
    /// corpus itself is empty.
    public func next() -> Quote? {
        if pool.isEmpty {
            pool = allQuotes
        }
        guard !pool.isEmpty else { return nil }
        let index = Int.random(in: 0..<pool.count)
        return pool.remove(at: index)
    }
}
