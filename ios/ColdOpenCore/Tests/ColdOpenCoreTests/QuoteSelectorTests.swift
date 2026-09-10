import XCTest
@testable import ColdOpenCore

final class QuoteSelectorTests: XCTestCase {
    func testNeverRepeatsBeforeExhaustingPool() {
        let quotes = (0..<5).map { i in
            Quote(text: "Quote \(i)", episodeTitle: "Ep", season: 1, episode: i + 1, arc: "Arc")
        }
        let selector = QuoteSelector(quotes: quotes)

        var seen: Set<String> = []
        for _ in 0..<5 {
            guard let quote = selector.next() else {
                XCTFail("expected a quote")
                return
            }
            XCTAssertFalse(seen.contains(quote.text), "quote repeated before pool exhausted")
            seen.insert(quote.text)
        }
        XCTAssertEqual(seen.count, 5)
    }

    func testRefillsPoolAfterExhaustion() {
        let quotes = [Quote(text: "Only one", episodeTitle: "Ep", season: 1, episode: 1, arc: "Arc")]
        let selector = QuoteSelector(quotes: quotes)

        XCTAssertEqual(selector.next()?.text, "Only one")
        XCTAssertEqual(selector.next()?.text, "Only one")
    }

    func testEmptyCorpusReturnsNil() {
        let selector = QuoteSelector(quotes: [])
        XCTAssertNil(selector.next())
    }
}
