"""Makes app-sized copies of menu photos.

Reads every JPEG in assets/images/ (the originals, left untouched) and writes
an optimised copy to assets/images/optimized/: at most 800 px on the longest
side (aspect ratio kept, never upscaled), JPEG quality 80, colour profile
kept. Only the optimised folder is bundled into the app.

Run from the project root (needs Pillow: `pip install pillow`):
    python tool/images/optimize_photos.py
"""

from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets" / "images"
OUT = SOURCE / "optimized"
MAX_SIDE = 800
QUALITY = 80


def main() -> None:
    OUT.mkdir(exist_ok=True)
    for path in sorted(SOURCE.glob("*.jp*g")):
        with Image.open(path) as original:
            icc = original.info.get("icc_profile")
            # Honour the camera's orientation flag; no other changes.
            image = ImageOps.exif_transpose(original).convert("RGB")
            image.thumbnail((MAX_SIDE, MAX_SIDE), Image.LANCZOS)
            target = OUT / f"{path.stem}.jpg"
            options = {"quality": QUALITY, "optimize": True, "progressive": True}
            if icc:
                options["icc_profile"] = icc
            image.save(target, "JPEG", **options)
        print(f"{path.name}: {original.size} -> {image.size}, "
              f"{path.stat().st_size // 1024} KB -> {target.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
