import XCTest
@testable import ColdOpenCore

final class ShareDeepLinkTests: XCTestCase {
    func testRoundTripsAllFields() {
        let quote = Quote(
            text: "Great leaders inspire greatness in others.",
            episodeTitle: "Ambush",
            season: 1,
            episode: 1,
            arc: "Ambush"
        )

        let url = ShareDeepLink.url(for: quote)
        let decoded = ShareDeepLink.quote(from: url)

        XCTAssertEqual(decoded, quote)
    }

    func testRoundTripsTextContainingReservedURLCharacters() {
        // Quote text routinely contains characters that need percent-encoding
        // in a URL query item (&, =, ?, unicode punctuation) — this is
        // exactly the case a hand-rolled string-concatenation encoder would
        // get wrong, which is why this uses URLComponents/URLQueryItem
        // instead.
        let quote = Quote(
            text: "Fear & hope; who's to say what's real? \u{2014} a test.",
            episodeTitle: "Some Episode",
            season: 3,
            episode: 12,
            arc: "Some Arc"
        )

        let url = ShareDeepLink.url(for: quote)
        let decoded = ShareDeepLink.quote(from: url)

        XCTAssertEqual(decoded, quote)
    }

    func testRejectsAURLWithTheWrongSchemeOrHost() {
        XCTAssertNil(ShareDeepLink.quote(from: URL(string: "https://example.com/share?text=x")!))
        XCTAssertNil(ShareDeepLink.quote(from: URL(string: "coldopen://notshare?text=x")!))
    }

    func testRejectsAURLMissingARequiredField() {
        let incomplete = URL(string: "coldopen://share?text=hello&episodeTitle=Ep")!
        XCTAssertNil(ShareDeepLink.quote(from: incomplete))
    }

    func testRejectsANonIntegerSeasonOrEpisode() {
        let malformed = URL(string: "coldopen://share?text=hello&episodeTitle=Ep&season=one&episode=1&arc=Ep")!
        XCTAssertNil(ShareDeepLink.quote(from: malformed))
    }
}
