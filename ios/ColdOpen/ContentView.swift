import SwiftUI
import ColdOpenCore

/// Companion quote browser (TASKS.md M3) — searchable by episode title,
/// arc, or the line itself. Loads the full corpus once; filtering is done
/// in-memory since 129 quotes is trivially small, no need for anything
/// fancier than `localizedCaseInsensitiveContains`.
///
/// Also where favoriting lives (TASKS.md M3's "favorite/pin" item) —
/// implemented as an in-app toggle rather than a widget long-press, which
/// isn't really a widget capability WidgetKit exposes as a custom action.
struct ContentView: View {
    @State private var quotes: [Quote] = []
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var favoriteTexts: Set<String> = []

    private let favoritesStore = FavoritesStore(defaults: UserDefaults(suiteName: AppGroup.identifier))

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
                QuoteRow(
                    quote: quote,
                    isFavorite: favoriteTexts.contains(quote.text),
                    onToggleFavorite: { toggleFavorite(quote) }
                )
            }
        }
    }

    private func loadQuotes() {
        do {
            quotes = try QuoteCorpus.load()
            favoriteTexts = favoritesStore.favoriteTexts
        } catch {
            errorMessage = "Failed to load corpus: \(error)"
        }
    }

    private func toggleFavorite(_ quote: Quote) {
        favoritesStore.toggleFavorite(quote)
        favoriteTexts = favoritesStore.favoriteTexts
    }
}

private struct QuoteRow: View {
    let quote: Quote
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(quote.text)
                    .font(.body)
                Text("\(quote.episodeTitle) · S\(quote.season)E\(quote.episode) · \(quote.arc)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        }
        .padding(.vertical, 4)
    }
}
