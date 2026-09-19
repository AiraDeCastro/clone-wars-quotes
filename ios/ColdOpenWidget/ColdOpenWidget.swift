import AppIntents
import WidgetKit
import SwiftUI
import ColdOpenCore

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote?
}

struct ColdOpenWidgetProvider: TimelineProvider {
    private static let shownTextsKey = "shownQuoteTexts"

    // Scheduled auto-refresh (M3/P1): WidgetKit needs every entry's date
    // known up front — it doesn't call back into the provider between
    // entries firing — so getTimeline pre-computes a batch covering the
    // next scheduledEntryCount * refreshInterval, then asks for a new
    // batch via .atEnd. Actual firing is still subject to the OS's own
    // background-refresh budget (see CLAUDE.md's non-functional
    // constraints) — pre-computing several hours ahead is exactly what
    // respecting that budget looks like, not a way around it.
    private static let refreshInterval: TimeInterval = 4 * 60 * 60
    private static let scheduledEntryCount = 6

    // Used if the corpus can't be loaded at all (missing/corrupt resource) —
    // the widget should never render fully empty.
    static let fallbackQuote = Quote(
        text: "Heroes are made by the path they choose, not the powers they are graced with.",
        episodeTitle: "Rookies",
        season: 1,
        episode: 5,
        arc: "Malevolence"
    )

    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: Self.fallbackQuote)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(QuoteEntry(date: Date(), quote: Self.nextQuote()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let now = Date()
        let entries = (0..<Self.scheduledEntryCount).map { index in
            QuoteEntry(date: now.addingTimeInterval(Double(index) * Self.refreshInterval), quote: Self.nextQuote())
        }
        // .atEnd asks WidgetKit to call getTimeline again once the last
        // entry's date has passed, continuing the schedule — manual
        // refresh (RefreshQuoteIntent) still works the same way it did
        // under .never: it forces an early getTimeline call, which
        // regenerates a fresh batch starting from "now".
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// Draws the next no-repeat quote, persisting the "already shown" set
    /// to the shared App Group suite (falling back to un-persisted random
    /// selection if that suite isn't available — see `AppGroup`'s doc
    /// comment). Favorited quotes (set via the companion browser) are
    /// excluded from the pool — unless every quote is favorited, in which
    /// case excluding them all would leave nothing to show, so the filter
    /// is skipped rather than falling back to the generic placeholder.
    private static func nextQuote() -> Quote {
        guard let quotes = try? QuoteCorpus.load(), !quotes.isEmpty else {
            return fallbackQuote
        }

        let defaults = UserDefaults(suiteName: AppGroup.identifier)
        let favorites = FavoritesStore(defaults: defaults).favoriteTexts
        let nonFavoriteQuotes = quotes.filter { !favorites.contains($0.text) }
        let eligibleQuotes = nonFavoriteQuotes.isEmpty ? quotes : nonFavoriteQuotes

        let alreadyShown = Set(defaults?.stringArray(forKey: shownTextsKey) ?? [])
        let selector = QuoteSelector(quotes: eligibleQuotes, alreadyShown: alreadyShown)

        guard let quote = selector.next() else {
            return fallbackQuote
        }
        defaults?.set(Array(selector.shownTexts), forKey: shownTextsKey)
        return quote
    }
}

/// Manual refresh, as a widget button action (iOS 17+ interactive widgets).
/// `perform()` just asks WidgetKit to re-run `getTimeline` — the actual
/// no-repeat draw already lives in `ColdOpenWidgetProvider.nextQuote()`, so
/// this intent doesn't duplicate that logic, it just triggers it again.
struct RefreshQuoteIntent: AppIntent {
    static var title: LocalizedStringResource = "New quote"

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: ColdOpenWidget.kind)
        return .result()
    }
}

struct ColdOpenWidgetView: View {
    let entry: QuoteEntry
    @Environment(\.widgetFamily) private var family

    private var isLarge: Bool { family == .systemLarge }

    var body: some View {
        VStack(alignment: .leading, spacing: isLarge ? 16 : 8) {
            if let quote = entry.quote {
                Text(quote.text)
                    .font(isLarge ? .system(.title3, design: .rounded).weight(.semibold) : .system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.8)
                // A faction emblem was considered for this size specifically
                // (see CLAUDE.md's design direction: "at most one faction
                // emblem, and only at the large widget size") but
                // deliberately left out here — it needs both a design
                // decision (which emblem, in what style) and a
                // quote-to-faction mapping that doesn't exist in the schema
                // yet. Tracked as its own TASKS.md item rather than
                // guessed at.
                Spacer(minLength: 4)
                HStack(spacing: 12) {
                    Text("\(quote.episodeTitle) · S\(quote.season)E\(quote.episode)")
                        .font(isLarge ? .caption : .caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    // Tapping this deep-links into the container app (via
                    // ShareDeepLink), which renders the share card and
                    // presents the OS share sheet immediately — a widget
                    // extension can't present that UI itself. See
                    // ColdOpenApp.swift's onOpenURL handler.
                    Link(destination: ShareDeepLink.url(for: quote)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(isLarge ? .caption : .caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Button(intent: RefreshQuoteIntent()) {
                        Image(systemName: "arrow.clockwise")
                            .font(isLarge ? .caption : .caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("No quote available.")
                    .font(.caption)
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(red: 0.05, green: 0.07, blue: 0.12)
        }
    }
}

struct ColdOpenWidget: Widget {
    static let kind = "ColdOpenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: ColdOpenWidgetProvider()) { entry in
            ColdOpenWidgetView(entry: entry)
        }
        .configurationDisplayName("Cold Open")
        .description("A random line from a Clone Wars cold open.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
