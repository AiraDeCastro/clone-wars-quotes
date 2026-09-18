#if os(iOS)
import UIKit
import ColdOpenCore

/// The two export sizes required by TASKS.md M2: Stories/Reels (9:16) and
/// the square feed crop (1:1). Both render the same design at whatever
/// resolution is requested — every metric in `ShareCardRenderer` is a
/// fraction of `size`, not a fixed pixel value, so both sizes share the
/// same drawing code.
enum ShareCardSize {
    static let story = CGSize(width: 1080, height: 1920)
    static let square = CGSize(width: 1080, height: 1080)
}

/// Renders the cold-open quote onto a themed share card, matching the
/// "Starfield Minimal" concept the user picked from a 3-way proposal: a
/// deep-navy ground, a handful of gold star flecks (the same restrained
/// count as the app icon's own starfield — a denser field read as noise
/// when that was tested at icon scale), the quote in a large serif face,
/// and the required Star Wars attribution as two lines at the bottom —
/// never dropped, per CLAUDE.md.
///
/// This lives in the `ColdOpen` app target rather than `ColdOpenCore`
/// because it needs UIKit (`UIGraphicsImageRenderer`, `NSAttributedString`
/// drawing) — unlike the rest of Core, which stays plain Foundation so it
/// can build for the widget extension and macOS too. `ColdOpen/` is also
/// compiled into the `ColdOpenMac` target (see project.yml), so this file
/// is scoped to `#if os(iOS)` rather than breaking that macOS build;
/// a macOS-compatible version (plain CoreGraphics/CoreText, no UIKit) is
/// a tracked follow-on, not done here — see TASKS.md.
enum ShareCardRenderer {
    /// The width the concept mockup was designed at (the artifact's
    /// artboards) — every other metric below scales off this so the two
    /// export sizes reproduce the same proportions, not a redrawn guess.
    private static let referenceWidth: CGFloat = 340

    private static let backgroundColor = UIColor(red: 0x0B / 255, green: 0x0F / 255, blue: 0x17 / 255, alpha: 1)
    private static let starColor = UIColor(red: 0xC9 / 255, green: 0xA2 / 255, blue: 0x27 / 255, alpha: 1)
    private static let quoteColor = UIColor(red: 0xF5 / 255, green: 0xF3 / 255, blue: 0xEC / 255, alpha: 1)
    private static let attributionPrimaryColor = UIColor(red: 0x9A / 255, green: 0xA3 / 255, blue: 0xB8 / 255, alpha: 1)
    private static let attributionSecondaryColor = UIColor(red: 0x6E / 255, green: 0x76 / 255, blue: 0x90 / 255, alpha: 1)

    private struct Star {
        let x: CGFloat
        let yFromTop: CGFloat
        let radius: CGFloat
        let opacity: CGFloat
    }

    // Same fractional positions as the approved concept artifact — not
    // re-picked, so the shipped card matches what was actually approved.
    private static let stars: [Star] = [
        Star(x: 0.188, yFromTop: 0.093, radius: 4, opacity: 0.9),
        Star(x: 0.741, yFromTop: 0.159, radius: 3, opacity: 0.6),
        Star(x: 0.529, yFromTop: 0.066, radius: 5, opacity: 0.75),
        Star(x: 0.118, yFromTop: 0.248, radius: 3, opacity: 0.5),
        Star(x: 0.859, yFromTop: 0.802, radius: 4, opacity: 0.7),
        Star(x: 0.235, yFromTop: 0.851, radius: 3, opacity: 0.55),
    ]

    static func render(quote: Quote, size: CGSize) -> UIImage {
        let scale = size.width / referenceWidth
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { rendererContext in
            let context = rendererContext.cgContext

            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            for star in stars {
                let radius = star.radius * scale
                let center = CGPoint(x: star.x * size.width, y: star.yFromTop * size.height)
                starColor.withAlphaComponent(star.opacity).setFill()
                context.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            }

            let marginX = 36 * scale
            let bottomMargin = 32 * scale
            let lineGap = 16 * scale
            let attributionFontSize = 10 * scale
            let attributionLineHeight = attributionFontSize * 1.4

            // Reserve room for both attribution lines so the quote frame
            // never overlaps them, regardless of how long the quote is.
            let attributionBandHeight = bottomMargin + lineGap + attributionLineHeight * 2

            drawQuote(
                quote.text,
                availableWidth: size.width - marginX * 2,
                availableHeight: size.height - attributionBandHeight,
                marginX: marginX,
                scale: scale
            )

            // Primary (app + show name) sits above secondary (episode),
            // which sits closest to the bottom edge — matching the
            // approved mockup's stacking order.
            let secondaryY = size.height - bottomMargin - attributionLineHeight
            let primaryY = secondaryY - lineGap - attributionLineHeight

            drawAttributionLine(
                "COLD OPEN \u{00B7} STAR WARS: THE CLONE WARS",
                rect: CGRect(x: marginX, y: primaryY, width: size.width - marginX * 2, height: attributionLineHeight),
                fontSize: attributionFontSize,
                weight: .semibold,
                color: attributionPrimaryColor
            )
            drawAttributionLine(
                "\(quote.episodeTitle.uppercased()) \u{00B7} SEASON \(quote.season), EPISODE \(quote.episode)",
                rect: CGRect(x: marginX, y: secondaryY, width: size.width - marginX * 2, height: attributionLineHeight),
                fontSize: attributionFontSize,
                weight: .medium,
                color: attributionSecondaryColor
            )
        }
    }

    private static func drawQuote(_ text: String, availableWidth: CGFloat, availableHeight: CGFloat, marginX: CGFloat, scale: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Georgia", size: 34 * scale) ?? UIFont.systemFont(ofSize: 34 * scale),
            .foregroundColor: quoteColor,
        ]
        let attributed = NSAttributedString(string: "\u{201C}\(text)\u{201D}", attributes: attributes)

        let fitRect = attributed.boundingRect(
            with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        // Center the measured block within the space above the
        // attribution band; if it's somehow taller than that space,
        // clamp to it rather than let text run into the attribution lines.
        let blockHeight = min(fitRect.height, availableHeight)
        let originY = max(0, (availableHeight - blockHeight) / 2)

        attributed.draw(
            with: CGRect(x: marginX, y: originY, width: availableWidth, height: blockHeight),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
    }

    private static func drawAttributionLine(_ text: String, rect: CGRect, fontSize: CGFloat, weight: UIFont.Weight, color: UIColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: weight),
            .foregroundColor: color,
            .kern: 0.6,
        ]
        NSAttributedString(string: text, attributes: attributes)
            .draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }
}
#endif
