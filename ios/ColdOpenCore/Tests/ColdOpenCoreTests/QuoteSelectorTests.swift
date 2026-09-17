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

    func testShownTextsAccumulatesAsQuotesAreDrawn() {
        let quotes = (0..<3).map { i in
            Quote(text: "Quote \(i)", episodeTitle: "Ep", season: 1, episode: i + 1, arc: "Arc")
        }
        let selector = QuoteSelector(quotes: quotes)

        XCTAssertEqual(selector.shownTexts, [])
        guard let first = selector.next() else { return XCTFail("expected a quote") }
        XCTAssertEqual(selector.shownTexts, [first.text])
        guard let second = selector.next() else { return XCTFail("expected a quote") }
        XCTAssertEqual(selector.shownTexts, [first.text, second.text])
    }

    func testResumingWithASavedShownSetExcludesThoseQuotesUntilThePoolExhausts() {
        let quotes = (0..<3).map { i in
            Quote(text: "Quote \(i)", episodeTitle: "Ep", season: 1, episode: i + 1, arc: "Arc")
        }
        // Simulate a WidgetKit extension relaunch after "Quote 0" and "Quote 1" were already shown.
        let selector = QuoteSelector(quotes: quotes, alreadyShown: ["Quote 0", "Quote 1"])

        XCTAssertEqual(selector.next()?.text, "Quote 2")
        // Pool is now exhausted (all 3 shown across the relaunch boundary) — refills.
        var seen: Set<String> = []
        for _ in 0..<3 {
            guard let quote = selector.next() else { return XCTFail("expected a quote") }
            seen.insert(quote.text)
        }
        XCTAssertEqual(seen, ["Quote 0", "Quote 1", "Quote 2"])
    }

    func testResumingWithEveryQuoteAlreadyShownRefillsImmediately() {
        let quotes = [Quote(text: "Only one", episodeTitle: "Ep", season: 1, episode: 1, arc: "Arc")]
        let selector = QuoteSelector(quotes: quotes, alreadyShown: ["Only one"])

        XCTAssertEqual(selector.next()?.text, "Only one")
    }

    func testRefillingAfterExhaustionClearsTheShownSetNotJustThePool() {
        let quotes = [Quote(text: "Only one", episodeTitle: "Ep", season: 1, episode: 1, arc: "Arc")]
        let selector = QuoteSelector(quotes: quotes)

        _ = selector.next()
        XCTAssertEqual(selector.shownTexts, ["Only one"])
        _ = selector.next() // triggers refill since the pool was already empty
        XCTAssertEqual(selector.shownTexts, ["Only one"])
    }
}
