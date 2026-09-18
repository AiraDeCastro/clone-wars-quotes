import SwiftUI
import ColdOpenCore

/// Companion quote browser (TASKS.md M3) — searchable by episode title,
/// arc, or the line itself. Loads the full corpus once; filtering is done
/// in-memory since 129 quotes is trivially small, no need for anything
/// fancier than `localizedCaseInsensitiveContains`.
struct ContentView: View {
    @State private var quotes: [Quote] = []
    @State private var errorMessage: String?
    @State private var searchText = ""

    private var filteredQuotes: [Quote] {
        guard !searchText.isEmpty else { return quotes }
        return quotes.filter { quote in
            quote.episodeTitle.localizedCaseInsensitiveContains(searchText)
                || quote.arc.localizedCaseInsensitiveContains(searchText)
                || quote.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Cold Open")
                .searchable(text: $searchText, prompt: "Search by episode, arc, or line")
        }
        .task { loadQuotes() }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage {
            ContentUnavailableView(errorMessage, systemImage: "exclamationmark.triangle")
        } else if quotes.isEmpty {
            ProgressView()
        } else if filteredQuotes.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            List(filteredQuotes) { quote in
                QuoteRow(quote: quote)
            }
        }
    }

    private func loadQuotes() {
        do {
            quotes = try QuoteCorpus.load()
        } catch {
            errorMessage = "Failed to load corpus: \(error)"
        }
    }
}

private struct QuoteRow: View {
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(quote.text)
                .font(.body)
            Text("\(quote.episodeTitle) · S\(quote.season)E\(quote.episode) · \(quote.arc)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
