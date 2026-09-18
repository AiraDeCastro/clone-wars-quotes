#if os(iOS)
import UIKit

/// Direct-to-Instagram-Stories sharing, bypassing the generic OS share
/// sheet — implemented against Meta's documented mechanism: writing the
/// rendered image to `UIPasteboard` under a specific key, then opening
/// `instagram-stories://share`, which Instagram reads on launch.
/// (developers.facebook.com/docs/instagram-platform/sharing-to-stories)
///
/// **This can't actually work yet, and can't be made to from here.**
/// Instagram has required a registered Facebook App ID since January
/// 2023 — passed as `source_application` — and rejects the share
/// ("doesn't currently support sharing to Stories") without one. That
/// registration is an interactive step tied to a real Meta for Developers
/// account, the same shape of gap as the iOS App Group identifier: this
/// writes the real, doc-grounded integration, but `facebookAppID` stays a
/// placeholder until someone actually registers an app and fills it in.
/// `isAvailable` is `false` while it's empty, so callers (see
/// `ColdOpenApp.handleIncomingURL`) safely fall back to the generic share
/// sheet rather than attempting a share that Instagram will just reject.
enum InstagramStorySharing {
    /// Set this to the real numeric Facebook App ID once one exists
    /// (developers.facebook.com → your app → Settings → Basic). Left
    /// blank deliberately — see the type's doc comment.
    private static let facebookAppID = ""

    private static let backgroundImageKey = "com.instagram.sharedSticker.backgroundImage"
    private static let shareURL = URL(string: "instagram-stories://share")!

    static var isAvailable: Bool {
        guard !facebookAppID.isEmpty else { return false }
        return UIApplication.shared.canOpenURL(shareURL)
    }

    /// Writes `image` to the pasteboard under Instagram's documented key
    /// and opens the Stories composer. Returns `false` (having done
    /// nothing) if `isAvailable` is `false` — callers should fall back to
    /// the generic share sheet in that case, not treat it as an error.
    @discardableResult
    static func share(image: UIImage) -> Bool {
        guard isAvailable, let pngData = image.pngData() else { return false }

        var urlComponents = URLComponents(url: shareURL, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "source_application", value: facebookAppID)]

        // Instagram reads this pasteboard entry once, immediately after
        // the URL below opens it — a short expiration keeps the image
        // data from lingering on the shared pasteboard if that open fails
        // or Instagram never actually reads it.
        let expirationDate = Date().addingTimeInterval(5 * 60)
        UIPasteboard.general.setItems(
            [[backgroundImageKey: pngData]],
            options: [.expirationDate: expirationDate]
        )

        guard let url = urlComponents.url else { return false }
        UIApplication.shared.open(url)
        return true
    }
}
#endif
