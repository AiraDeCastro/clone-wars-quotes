# Provider Assets

`Package.appxmanifest` references `ProviderAssets\ColdOpen_Icon.png` and `ProviderAssets\ColdOpen_Screenshot.png` (plus `Images\StoreLogo.png`, `Images\Square150x150Logo.png`, `Images\Square44x44Logo.png` at the package root — not this folder).

**The icon exists now** — `ColdOpen_Icon.png` (96x96) renders the "Cold Open Wipe" concept (see [ios/AppIcon.xcassets](../../../ios/AppIcon.xcassets) for the same design across iOS/macOS, and `android/app/src/main/res/drawable/ic_launcher_background.xml` for Android's version). Generated pixel-exact from the approved concept via a small script (not committed — see CLAUDE.md's session summary), not hand-drawn or rasterized from the SVG mockup.

**`ColdOpen_Screenshot.png` is still missing on purpose.** It's a different kind of asset — a screenshot of the *widget's* rendered content (the quote card, in the widget picker), not the app icon — and generating a convincing one means either an actual running widget to screenshot or fabricating fake quote text to render, neither of which belongs in an icon task. Left open.
