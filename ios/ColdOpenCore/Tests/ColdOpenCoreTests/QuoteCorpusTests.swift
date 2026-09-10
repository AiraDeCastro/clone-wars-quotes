import XCTest
@testable import ColdOpenCore

final class QuoteCorpusTests: XCTestCase {
    func testLoadsBundledCorpus() throws {
        let quotes = try QuoteCorpus.load(bundle: .module)
        XCTAssertFalse(quotes.isEmpty)
        XCTAssertTrue(quotes.allSatisfy { !$0.text.isEmpty })
    }

    func testDecodesKnownSeedEntry() throws {
        let quotes = try QuoteCorpus.load(bundle: .module)
        XCTAssertTrue(quotes.contains { $0.episodeTitle == "Rookies" && $0.season == 1 && $0.episode == 5 })
    }
}
