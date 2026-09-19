import XCTest
@testable import ColdOpenCore

final class FavoritesStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    private let quoteA = Quote(text: "A quote", episodeTitle: "Ep", season: 1, episode: 1, arc: "Arc")
    private let quoteB = Quote(text: "Another quote", episodeTitle: "Ep", season: 1, episode: 2, arc: "Arc")

    override func setUp() {
        super.setUp()
        suiteName = "FavoritesStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testStartsWithNoFavorites() {
        let store = FavoritesStore(defaults: defaults)
        XCTAssertFalse(store.isFavorite(quoteA))
        XCTAssertTrue(store.favoriteTexts.isEmpty)
    }

    func testTogglingMarksThenUnmarksAsFavorite() {
        let store = FavoritesStore(defaults: defaults)

        store.toggleFavorite(quoteA)
        XCTAssertTrue(store.isFavorite(quoteA))

        store.toggleFavorite(quoteA)
        XCTAssertFalse(store.isFavorite(quoteA))
    }

    func testTogglingOneQuoteDoesNotAffectAnother() {
        let store = FavoritesStore(defaults: defaults)

        store.toggleFavorite(quoteA)

        XCTAssertTrue(store.isFavorite(quoteA))
        XCTAssertFalse(store.isFavorite(quoteB))
    }

    func testPersistsAcrossSeparateStoreInstancesSharingTheSameDefaults() {
        FavoritesStore(defaults: defaults).toggleFavorite(quoteA)

        let reopened = FavoritesStore(defaults: defaults)
        XCTAssertTrue(reopened.isFavorite(quoteA))
    }

    func testNilDefaultsDegradesGracefullyRatherThanCrashing() {
        let store = FavoritesStore(defaults: nil)
        XCTAssertFalse(store.isFavorite(quoteA))
        store.toggleFavorite(quoteA)
        XCTAssertFalse(store.isFavorite(quoteA))
    }
}
