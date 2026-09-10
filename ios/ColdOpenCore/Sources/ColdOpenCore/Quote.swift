import Foundation

/// A single cold-open narration line. Mirrors the schema in `corpus/schema.json`
/// at the repo root — keep the two in sync if either changes.
public struct Quote: Codable, Identifiable, Hashable, Sendable {
    public var id: String { text }

    public let text: String
    public let episodeTitle: String
    public let season: Int
    public let episode: Int
    public let arc: String

    public init(text: String, episodeTitle: String, season: Int, episode: Int, arc: String) {
        self.text = text
        self.episodeTitle = episodeTitle
        self.season = season
        self.episode = episode
        self.arc = arc
    }
}
