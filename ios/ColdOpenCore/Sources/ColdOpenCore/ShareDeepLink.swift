import Foundation

/// Encodes/decodes the custom URL the widget's share tap deep-links
/// through, so the container app can render and present the share sheet
/// (see `ColdOpenWidget.swift`'s share button and `ColdOpenApp.swift`'s
/// `onOpenURL` handler). Lives in `ColdOpenCore` — not the widget or app
/// target — because both need to agree on the exact same encoding, and
/// this is otherwise plain Foundation logic like the rest of Core.
///
/// The scheme (`coldopen`) must be registered in `CFBundleURLTypes` in
/// the app target's `Info.plist` or the OS won't route the tap here at all.
public enum ShareDeepLink {
    public static let scheme = "coldopen"
    public static let host = "share"

    public static func url(for quote: Quote) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [
            URLQueryItem(name: "text", value: quote.text),
            URLQueryItem(name: "episodeTitle", value: quote.episodeTitle),
            URLQueryItem(name: "season", value: String(quote.season)),
            URLQueryItem(name: "episode", value: String(quote.episode)),
            URLQueryItem(name: "arc", value: quote.arc),
        ]
        // Force-unwrap is safe: every part above is either a fixed literal
        // or handed to URLQueryItem, which handles its own percent-encoding.
        return components.url!
    }

    public static func quote(from url: URL) -> Quote? {
        guard url.scheme == scheme, url.host == host else { return nil }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? { items.first(where: { $0.name == name })?.value }

        guard let text = value("text"),
              let episodeTitle = value("episodeTitle"),
              let seasonString = value("season"), let season = Int(seasonString),
              let episodeString = value("episode"), let episode = Int(episodeString),
              let arc = value("arc")
        else { return nil }

        return Quote(text: text, episodeTitle: episodeTitle, season: season, episode: episode, arc: arc)
    }
}
