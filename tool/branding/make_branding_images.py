"""Builds the padded/scaled logo variants that icon and splash generators need.

The logo itself is never edited: each variant is the original
assets/images/logo_icon.png scaled uniformly (aspect ratio kept, Lanczos)
and centred on a canvas, so masks (round icons, Android 12 splash circle,
maskable PWA icons) never cut it off.

Run from the project root (needs Pillow: `pip install pillow`):
    python tool/branding/make_branding_images.py
then:
    dart run flutter_native_splash:create
    dart run flutter_launcher_icons
    python tool/branding/make_branding_images.py --web-maskable
"""

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
LOGO = ROOT / "assets" / "images" / "logo_icon.png"
OUT = ROOT / "tool" / "branding" / "generated"
CREAM = (0xFF, 0xF8, 0xF1, 255)


def logo_scaled(width: int) -> Image.Image:
    logo = Image.open(LOGO).convert("RGBA")
    height = round(logo.height * width / logo.width)  # keep aspect ratio
    return logo.resize((width, height), Image.LANCZOS)


def on_canvas(size: int, logo_width: int, background) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), background)
    logo = logo_scaled(logo_width)
    canvas.alpha_composite(logo, ((size - logo.width) // 2, (size - logo.height) // 2))
    return canvas


def splash_images() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    # Pre-Android 12 and web splash: treated as 4x density by
    # flutter_native_splash, so 640 px = 160 dp (~40% of a 400 dp phone).
    logo_scaled(640).save(OUT / "splash_logo.png")
    # Android 12+: 1152 px canvas, only the centre 768 px circle is visible.
    # Logo at 720 px keeps its round edge inside that circle.
    on_canvas(1152, 720, (0, 0, 0, 0)).save(OUT / "splash_android12.png")
    print("Wrote", OUT / "splash_logo.png", "and", OUT / "splash_android12.png")


def web_maskable() -> None:
    # Maskable PWA icons may be cropped to a circle of 80% diameter; the
    # logo at 76% width keeps its ring inside that safe zone.
    icons = ROOT / "web" / "icons"
    for size in (192, 512):
        on_canvas(size, round(size * 0.76), CREAM).save(icons / f"Icon-maskable-{size}.png")
    print("Wrote padded maskable icons in", icons)


if __name__ == "__main__":
    if "--web-maskable" in sys.argv:
        web_maskable()
    else:
        splash_images()
