"""Generates the "Cold Open Wipe" app icon (see the icon-concepts proposal)
at every pixel size the iOS/macOS, Android, and Windows scaffolds need.

Reproduces the approved design as flat polygons rather than rasterizing the
original SVG mockup, since the design is only two shapes: a full navy
ground, a lighter-navy triangle over the top-left half, and an accent
diagonal bar along the seam. Requires Pillow (`pip install Pillow`) — not a
project dependency, just a local tool for regenerating these assets if the
design ever changes.

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

# Fractions of the 1024 base the original SVG concept used, so any output
# size stays exactly proportional to the approved design.
BAR_LEFT_TOP = 984 / 1024
BAR_LEFT_BOTTOM = 944 / 1024

# (size, path relative to repo root) for every platform asset currently
# referenced by a manifest. Keep in sync with:
# - ios/AppIcon.xcassets/AppIcon.appiconset/Contents.json
# - windows/WidgetProvider.Package/Package.appxmanifest
OUTPUTS = [
    (16, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-16.png"),
    (32, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-32.png"),
    (64, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-64.png"),
    (128, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-128.png"),
    (256, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-256.png"),
    (512, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-512.png"),
    (1024, "ios/AppIcon.xcassets/AppIcon.appiconset/Icon-1024.png"),
    (50, "windows/WidgetProvider.Package/Images/StoreLogo.png"),
    (150, "windows/WidgetProvider.Package/Images/Square150x150Logo.png"),
    (44, "windows/WidgetProvider.Package/Images/Square44x44Logo.png"),
    (96, "windows/WidgetProvider.Package/ProviderAssets/ColdOpen_Icon.png"),
]


def render(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size), BG)
    draw = ImageDraw.Draw(img)
    draw.polygon([(0, 0), (size, 0), (0, size)], fill=TRIANGLE)
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
