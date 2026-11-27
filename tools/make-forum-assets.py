#!/usr/bin/env python3
"""Generate Forum's icon: the gilt eagle on a porphyry tablet with a gilt rim.

Writes art/forum/forum-<size>.png for the hicolor icon theme.

Run from anywhere:  python3 tools/make-forum-assets.py
"""
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art/forum")
SIZES = (48, 64, 128, 256, 512)


def tablet(size):
    s = 1024  # draw large, then shrink
    stone = Image.open(os.path.join(ROOT, "art/textures/porphyry.jpg")).convert("RGB")
    side = min(stone.size)
    stone = stone.crop((0, 0, side, side)).resize((s, s), Image.LANCZOS)
    img = stone.convert("RGBA")
    d = ImageDraw.Draw(img)

    # Bevel: lit top-left edges, shadowed bottom-right, then a gilt rim.
    edge = s // 40
    for i in range(edge):
        a = int(110 * (1 - i / edge))
        d.line([(i, i), (s - 1 - i, i)], fill=(255, 235, 200, a))
        d.line([(i, i), (i, s - 1 - i)], fill=(255, 235, 200, a))
        d.line([(i, s - 1 - i), (s - 1 - i, s - 1 - i)], fill=(0, 0, 0, a))
        d.line([(s - 1 - i, i), (s - 1 - i, s - 1 - i)], fill=(0, 0, 0, a))
    rim = s // 14
    d.rectangle([rim, rim, s - 1 - rim, s - 1 - rim], outline=(234, 197, 94, 255), width=s // 90)
    d.rectangle([rim + s // 45, rim + s // 45, s - 1 - rim - s // 45, s - 1 - rim - s // 45],
                outline=(138, 101, 24, 255), width=s // 220)

    # The eagle, with a soft shadow beneath it.
    eagle = Image.open(os.path.join(ROOT, "art/branding/eagle.png")).convert("RGBA")
    eagle = eagle.crop(eagle.getbbox())
    w = int(s * 0.66)
    h = int(eagle.size[1] * w / eagle.size[0])
    eagle = eagle.resize((w, h), Image.LANCZOS)
    x, y = (s - w) // 2, (s - h) // 2
    shadow = Image.new("RGBA", eagle.size, (0, 0, 0, 0))
    shadow.putalpha(eagle.getchannel("A").point(lambda v: v * 0.6))
    shadow = shadow.filter(ImageFilter.GaussianBlur(s // 120))
    img.alpha_composite(shadow, (x + s // 160, y + s // 90))
    img.alpha_composite(eagle, (x, y))
    return img.resize((size, size), Image.LANCZOS)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for size in SIZES:
        tablet(size).save(os.path.join(OUT, f"forum-{size}.png"))
    print("wrote", ", ".join(f"forum-{n}.png" for n in SIZES), "to art/forum/")
