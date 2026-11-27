#!/usr/bin/env python3
"""Render the colonia (installer) artwork into art/colonia/.

  welcome.png        the white cliffs landing, with COLONIA carved over it
  slide-*.jpg        the install slideshow's paintings
  marmor-wall.jpg    the installer's background: a wall faced with marble slabs
  marmor-slab.jpg    the marble photo, for the plaques cut from it
  porphyry.jpg etc.  the textures the installer's stylesheet tiles

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
    for name in ("porphyry.jpg", "beadreel.png", "eagle.png", "emblem.png", "eagle@2x.png", "emblem@2x.png"):
        Image.open(os.path.join(ROOT, "art/shell", name)).save(os.path.join(OUT, name))
    Image.open(os.path.join(ROOT, "art/shell", "marmor-slab.jpg")).save(
        os.path.join(OUT, "marmor-slab.jpg"), quality=92, optimize=True)


def wall(columns=2, rows=2, cell=(1400, 950)):
    """The installer's background: a wall faced with marble slabs, the way
    the shell lays them. Each slab is a different cut of the one photo, never
    mirrored; every other slab is turned end for end so the veins all run
    the same way, and the joints are hairlines of shadow with a lit edge.
    Joints run along the top and left edges too, so if Calamares tiles the
    wall over a very large window, the repeat still falls on a joint."""
    photo = Image.open(os.path.join(ROOT, "art/textures/marmor-slab.jpg")).convert("RGB")
    cw, ch = cell
    out = Image.new("RGB", (cw * columns, ch * rows))
    cuts = [(30, 60), (90, 410), (0, 300), (60, 120)]
    for r in range(rows):
        for c in range(columns):
            ox, oy = cuts[(r * columns + c) % len(cuts)]
            piece = photo.crop((ox, oy, ox + cw, oy + ch))
            if (r + c) % 2:
                piece = piece.transpose(Image.ROTATE_180)
            out.paste(piece, (c * cw, r * ch))
    d = ImageDraw.Draw(out, "RGBA")
    shadow, light = (59, 46, 41, 56), (255, 255, 255, 140)
    for c in range(columns):
        x = c * cw
        d.line([(x, 0), (x, out.height)], fill=shadow)
        d.line([(x + 1, 0), (x + 1, out.height)], fill=light)
    for r in range(rows):
        y = r * ch
        d.line([(0, y), (out.width, y)], fill=shadow)
        d.line([(0, y + 1), (out.width, y + 1)], fill=light)
    out.save(os.path.join(OUT, "marmor-wall.jpg"), quality=90)


def main():
    os.makedirs(OUT, exist_ok=True)
    welcome()
    slides()
    textures()
    wall()
    print("colonia art written to", OUT)


if __name__ == "__main__":
    main()
