import SwiftUI
import ColdOpenCore

/// Placeholder companion view — just enough to prove the app target can load
/// the shared corpus. The real searchable browser is a P1 task (TASKS.md M3).
struct ContentView: View {
    @State private var quote: Quote?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            if let quote {
                Text(quote.text)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("\(quote.episodeTitle) — S\(quote.season)E\(quote.episode)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else {
                ProgressView()
            }
        }
        .padding()
        .task { loadQuote() }
    }

    private func loadQuote() {
        do {
            quote = try QuoteCorpus.load().first
        } catch {
            errorMessage = "Failed to load corpus: \(error)"
        }
    }
}
