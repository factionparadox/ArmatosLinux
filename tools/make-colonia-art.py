#!/usr/bin/env python3
"""Render the colonia (installer) artwork into art/colonia/.

  welcome.png        the white cliffs landing, with COLONIA carved over it
  slide-*.jpg        the install slideshow's paintings
  marmor.jpg etc.    the textures the installer's stylesheet tiles

Run from anywhere:  python3 tools/make-colonia-art.py
"""
import importlib.util
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "art/installer")
OUT = os.path.join(ROOT, "art/colonia")

_spec = importlib.util.spec_from_file_location("grubtheme", os.path.join(ROOT, "tools/make-grub-theme.py"))
_grub = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_grub)
cover, font, tracked = _grub.cover, _grub.font, _grub.tracked
GOLD, GOLD_HI = _grub.GOLD, _grub.GOLD_HI


def painting(name, w, h):
    """Upscale gently: the soft look reads as paint, not as pixels."""
    img = Image.open(os.path.join(SRC, name)).convert("RGB")
    img = cover(img, w, h)
    if img.width > Image.open(os.path.join(SRC, name)).width:
        img = img.filter(ImageFilter.GaussianBlur(0.6))
    return ImageEnhance.Contrast(img).enhance(1.05)


def welcome():
    w, h = 1000, 430
    img = painting("cliffs.png", w, h).convert("RGBA")
    # Darken towards the foot so the inscription reads.
    shade = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(shade)
    for y in range(h):
        t = max(0, (y - h * 0.35) / (h * 0.65))
        d.line((0, y, w, y), fill=(14, 9, 7, int(205 * t)))
    img = Image.alpha_composite(img, shade)
    d = ImageDraw.Draw(img)
    tracked(d, (w // 2, int(h * 0.70)), "COLONIA", font("Black", 64), GOLD_HI + (255,), tracking=0.18)
    tracked(d, (w // 2, int(h * 0.86)), "CONDE COLONIAM · FOUND A COLONY", font("Bold", 22), (236, 228, 216, 255), tracking=0.16)
    # A thin gilt frame
    d.rectangle((0, 0, w - 1, h - 1), outline=GOLD + (255,), width=3)
    img.convert("RGB").save(os.path.join(OUT, "welcome.png"))


def slides():
    for name, src in (("cursus", "legion.png"), ("damnatio", "colosseum.png"),
                      ("porta", "cliffs.png"), ("titulus", "triumph.png"),
                      ("lingua", "../wallpapers/atlas.png")):
        painting(src, 960, 540).save(os.path.join(OUT, f"slide-{name}.jpg"), quality=88)


def textures():
    for name in ("marmor.jpg", "porphyry.jpg", "beadreel.png", "eagle.png", "emblem.png"):
        Image.open(os.path.join(ROOT, "art/shell", name)).save(os.path.join(OUT, name))
    for name in ("eagle@2x.png", "emblem@2x.png"):
        Image.open(os.path.join(ROOT, "art/shell", name)).save(os.path.join(OUT, name))
    # The installer's wall: the big tile, so the book-matching repeats rarely.
    Image.open(os.path.join(ROOT, "art/shell", "marmor@2x.jpg")).save(os.path.join(OUT, "marmor-wall.jpg"), quality=90)


def main():
    os.makedirs(OUT, exist_ok=True)
    welcome()
    slides()
    textures()
    print("colonia art written to", OUT)


if __name__ == "__main__":
    main()
