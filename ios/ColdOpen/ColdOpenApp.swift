import SwiftUI
import ColdOpenCore

@main
struct ColdOpenApp: App {
    #if os(iOS)
    @State private var shareItems: [Any]?
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                #if os(iOS)
                .sheet(isPresented: Binding(
                    get: { shareItems != nil },
                    set: { isPresented in if !isPresented { shareItems = nil } }
                )) {
                    if let shareItems {
                        ActivityView(items: shareItems)
                    }
                }
                #endif
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard let quote = ShareDeepLink.quote(from: url) else { return }
        #if os(iOS)
        let image = ShareCardRenderer.render(quote: quote, size: ShareCardSize.story)
        shareItems = [image]
        #endif
        // No macOS handling yet — ShareCardRenderer is iOS-only for now
        // (see its own doc comment and TASKS.md); the deep link parses
        // fine here, there's just nothing to render into yet.
    }
}
