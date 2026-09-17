import AppIntents
import WidgetKit
import SwiftUI
import ColdOpenCore

/// The App Group shared between this widget extension and the container
/// app, used to persist `QuoteSelector`'s "already shown" set across
/// timeline reloads (a WidgetKit extension process is short-lived and
/// stateless between them otherwise).
///
/// **This identifier is not yet registered anywhere.** It follows the
/// existing bundle ID scheme (`com.coldopen.app`/`com.coldopen.app.widget`)
/// but actually enabling it requires an interactive step this scaffold
/// can't complete: open Signing & Capabilities for `ColdOpenWidgetExtension`
/// (and `ColdOpenWidgetExtensionMac`) in Xcode, add the "App Groups"
/// capability, and register this exact identifier — tied to a real Apple
/// ID/team, which is why it's not automated the way the corpus sync or the
/// app icon were. Until that's done, `UserDefaults(suiteName:)` below
/// returns `nil` and the widget falls back to un-persisted random
/// selection rather than crashing — see `nextQuote()`.
private enum WidgetAppGroup {
    static let identifier = "group.com.coldopen.app"
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote?
}

struct ColdOpenWidgetProvider: TimelineProvider {
    private static let shownTextsKey = "shownQuoteTexts"

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
        // Reload policy stays .never — there's no scheduled auto-refresh yet
        // (that's P1/M3). Manual refresh is RefreshQuoteIntent below, which
        // forces a new getTimeline call via WidgetCenter.reloadTimelines.
        let entry = QuoteEntry(date: Date(), quote: Self.nextQuote())
        completion(Timeline(entries: [entry], policy: .never))
    }

    /// Draws the next no-repeat quote, persisting the "already shown" set
    /// to the shared App Group suite (falling back to un-persisted random
    /// selection if that suite isn't available — see `WidgetAppGroup`).
    private static func nextQuote() -> Quote {
        guard let quotes = try? QuoteCorpus.load(), !quotes.isEmpty else {
            return fallbackQuote
        }

        let defaults = UserDefaults(suiteName: WidgetAppGroup.identifier)
        let alreadyShown = Set(defaults?.stringArray(forKey: shownTextsKey) ?? [])
        let selector = QuoteSelector(quotes: quotes, alreadyShown: alreadyShown)

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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let quote = entry.quote {
                Text(quote.text)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                HStack {
                    Text("\(quote.episodeTitle) · S\(quote.season)E\(quote.episode)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Button(intent: RefreshQuoteIntent()) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2)
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
