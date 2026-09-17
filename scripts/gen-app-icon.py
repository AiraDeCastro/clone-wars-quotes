"""Generates the "Cold Open Wipe + Starfield" app icon (see the icon-concepts
proposals) at every pixel size the iOS/macOS, Android, and Windows scaffolds
need.

Reproduces the approved design as flat shapes rather than rasterizing the
original SVG mockup: a full navy ground, a lighter-navy triangle over the
top-left half, an accent diagonal bar along the seam, and three small
warm-gold flecks scattered over the triangle. The star count and size were
chosen deliberately — a denser 9-star version was rendered and rejected
because it looked like noise at 22px; this 3-star version was pixel-tested
at 22/44/128px before being approved. Don't add more stars without
re-checking legibility at the smallest sizes. Requires Pillow
(`pip install Pillow`) — not a project dependency, just a local tool for
regenerating these assets if the design ever changes.

Usage:
    python scripts/gen-app-icon.py            # regenerate every platform's assets
    python scripts/gen-app-icon.py 256:out.png # render one arbitrary size

Android needs no PNGs from this script at all — its adaptive icon is
implemented as vector drawables (see
android/app/src/main/res/drawable/ic_launcher_background.xml), which encode
the same two polygons as XML paths instead.
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw

REPO_ROOT = Path(__file__).resolve().parent.parent

BG = (11, 14, 22)        # #0B0E16
TRIANGLE = (22, 29, 40)  # #161D28
ACCENT = (76, 134, 176)  # #4C86B0
STAR = (156, 133, 80)    # #9C8550 — muted gold, texture not a second accent

# Fractions of the 1024 base the original SVG concept used, so any output
# size stays exactly proportional to the approved design.
BAR_LEFT_TOP = 984 / 1024
BAR_LEFT_BOTTOM = 944 / 1024

# (x, y, radius), all as fractions of the 1024 base — the exact 3-star
# layout verified at 22/44/128px in the starfield-concepts proposal.
STARS = [
    (190 / 1024, 230 / 1024, 10 / 1024),
    (320 / 1024, 650 / 1024, 7 / 1024),
    (110 / 1024, 560 / 1024, 6 / 1024),
]

# (size, path relative to repo root) for every platform asset currently
# referenced by a manifest. Keep in sync with:
# - ios/AppIcon.xcassets/AppIcon.appiconset/Contents.json
# - windows/WidgetProvider.Package/Package.appxmanifest
#
# Windows Square44x44Logo/Square150x150Logo use the documented
# `<Name>.scale-<N>.png` qualifier convention (auto-discovered by Windows'
# resource system alongside the manifest's unqualified base reference — no
# manifest change needed) rather than one bare file, matching what Visual
# Studio's own asset generator produces and Microsoft's documented minimum
# (100/200/400% scale) — see:
# https://learn.microsoft.com/windows/apps/design/iconography/app-icon-construction
# StoreLogo stays a single 100%-scale file for now: scale variants and the
# rest of the Store-required asset set (AppList target-size icons, tiles,
# splash screen) are a separate, larger task gated on the distribution-plan
# decision in TASKS.md, not something to build out incidentally here.
OUTPUTS = [
    (16, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-16.png"),
    (32, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-32.png"),
    (64, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-64.png"),
    (128, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-128.png"),
    (256, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-256.png"),
    (512, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-512.png"),
    (1024, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-1024.png"),
    (50, "windows/WidgetProvider.Package/Images/StoreLogo.png"),
    (44, "windows/WidgetProvider.Package/Images/Square44x44Logo.scale-100.png"),
    (88, "windows/WidgetProvider.Package/Images/Square44x44Logo.scale-200.png"),
    (176, "windows/WidgetProvider.Package/Images/Square44x44Logo.scale-400.png"),
    (150, "windows/WidgetProvider.Package/Images/Square150x150Logo.scale-100.png"),
    (300, "windows/WidgetProvider.Package/Images/Square150x150Logo.scale-200.png"),
    (600, "windows/WidgetProvider.Package/Images/Square150x150Logo.scale-400.png"),
    (96, "windows/WidgetProvider.Package/ProviderAssets/ColdOpen_Icon.png"),
]


def render(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size), BG)
    draw = ImageDraw.Draw(img)
    draw.polygon([(0, 0), (size, 0), (0, size)], fill=TRIANGLE)
    for fx, fy, fr in STARS:
        x, y, r = fx * size, fy * size, max(fr * size, 0.5)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=STAR)
    draw.polygon(
        [
            (BAR_LEFT_TOP * size, 0),
            (size, 0),
            (size, size),
            (BAR_LEFT_BOTTOM * size, size),
        ],
        fill=ACCENT,
    )
    return img


def main() -> None:
    if len(sys.argv) == 1:
        for size, rel_path in OUTPUTS:
            out_path = REPO_ROOT / rel_path
            render(size).save(out_path, "PNG")
            print(f"Wrote {rel_path} ({size}x{size})")
        return

    for arg in sys.argv[1:]:
        size_str, out_path = arg.split(":", 1)
        size = int(size_str)
        render(size).save(out_path, "PNG")
        print(f"Wrote {out_path} ({size}x{size})")


if __name__ == "__main__":
    main()
