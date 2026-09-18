#if os(iOS)
import SwiftUI
import UIKit

/// Wraps `UIActivityViewController` for SwiftUI — this predates `ShareLink`
/// (iOS 16) and is used instead of it here specifically because `ShareLink`
/// requires the user to tap it directly to open the OS share sheet; it has
/// no programmatic "open now" API. This app needs the sheet to appear the
/// moment the widget's deep link lands (see `ColdOpenApp.onOpenURL`), not
/// after an extra in-app tap, to stay close to the PRD's "widget tap to a
/// posted story in under 10 seconds" goal.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
