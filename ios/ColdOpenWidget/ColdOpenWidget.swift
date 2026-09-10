import WidgetKit
import SwiftUI
import ColdOpenCore

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote?
}

struct ColdOpenWidgetProvider: TimelineProvider {
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
        let quote = (try? QuoteCorpus.load())?.randomElement() ?? Self.fallbackQuote
        completion(QuoteEntry(date: Date(), quote: quote))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        // Manual refresh only for now (TASKS.md M1). Random selection here
        // uses plain randomElement(), not ColdOpenCore's no-repeat
        // QuoteSelector — see that type's doc comment for why: its in-memory
        // "already shown" state wouldn't survive this process reloading.
        let quote = (try? QuoteCorpus.load())?.randomElement() ?? Self.fallbackQuote
        let entry = QuoteEntry(date: Date(), quote: quote)
        completion(Timeline(entries: [entry], policy: .never))
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
                Text("\(quote.episodeTitle) · S\(quote.season)E\(quote.episode)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
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
    let kind = "ColdOpenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ColdOpenWidgetProvider()) { entry in
            ColdOpenWidgetView(entry: entry)
        }
        .configurationDisplayName("Cold Open")
        .description("A random line from a Clone Wars cold open.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
