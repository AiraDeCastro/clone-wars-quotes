import Foundation

public enum QuoteCorpusError: Error {
    case resourceNotFound
    case decodingFailed(Error)
}

/// Loads the bundled quote corpus (`Resources/quotes.json`, copied from
/// `corpus/quotes.json` at the repo root via `npm run sync:ios`).
public enum QuoteCorpus {
    public static func load(bundle: Bundle = .module) throws -> [Quote] {
        guard let url = bundle.url(forResource: "quotes", withExtension: "json") else {
            throw QuoteCorpusError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode([Quote].self, from: data)
        } catch {
            throw QuoteCorpusError.decodingFailed(error)
        }
    }
}
