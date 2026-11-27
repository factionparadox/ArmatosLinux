#!/usr/bin/env python3
"""Generate the textures the Armatos shell (Titulus, launcher, porta) draws with.

Writes into art/shell/. Marble is the whole photo (marmor-slab.jpg), never
mirrored: Marble.qml lays it as slabs, cutting small surfaces from one and
facing large ones with several, edge to edge. Porphyry, which is evenly
speckled, is book-matched (mirrored) into a seamless tile. Tiles come in a 1x
and an @2x size so they stay sharp on the Framework's panel.

Run from anywhere:  python3 tools/make-shell-assets.py
"""
import importlib.util
import os

from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art/shell")

# Reuse the bead-and-reel moulding from the GRUB theme so both match.
_spec = importlib.util.spec_from_file_location("grubtheme", os.path.join(ROOT, "tools/make-grub-theme.py"))
_grub = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_grub)


def bookmatch(img):
    """Mirror an image into a 2x2 block that tiles without seams."""
    w, h = img.size
    out = Image.new(img.mode, (w * 2, h * 2))
    out.paste(img, (0, 0))
    out.paste(img.transpose(Image.FLIP_LEFT_RIGHT), (w, 0))
    out.paste(img.transpose(Image.FLIP_TOP_BOTTOM), (0, h))
    out.paste(img.transpose(Image.ROTATE_180), (w, h))
    return out


def save_pair(name, img_1x, img_2x, **kw):
    base, ext = os.path.splitext(name)
    img_1x.save(os.path.join(OUT, name), **kw)
    img_2x.save(os.path.join(OUT, f"{base}@2x{ext}"), **kw)


def texture(src, name, tile_w):
    """A book-matched tile tile_w logical px wide (half of that per source copy)."""
    img = Image.open(os.path.join(ROOT, src)).convert("RGB")
    half = tile_w // 2
    one = img.resize((half, round(img.height * half / img.width)), Image.LANCZOS)
    two = img.resize((half * 2, round(img.height * half * 2 / img.width)), Image.LANCZOS)
    save_pair(name, bookmatch(one), bookmatch(two), quality=90)


def slab():
    """The marble photo itself, untouched, for Marble.qml to lay as slabs."""
    Image.open(os.path.join(ROOT, "art/textures/marmor-slab.jpg")).convert("RGB").save(
        os.path.join(OUT, "marmor-slab.jpg"), quality=92, optimize=True)


def moulding():
    h = 14
    unit = h * 3
    one = _grub.bead_and_reel(unit * 4, h)
    two = _grub.bead_and_reel(unit * 8, h * 2)
    save_pair("beadreel.png", one, two)


def branding():
    eagle = Image.open(os.path.join(ROOT, "art/branding/eagle.png")).convert("RGBA")
    box = eagle.getbbox()
    eagle = eagle.crop(box)
    for size, suffix in ((64, ""), (128, "@2x")):
        e = eagle.copy()
        e.thumbnail((size, size), Image.LANCZOS)
        e.save(os.path.join(OUT, f"eagle{suffix}.png"))
    emblem = Image.open(os.path.join(ROOT, "art/branding/emblem.png")).convert("RGB")
    for size, suffix in ((160, ""), (320, "@2x")):
        emblem.resize((size, size), Image.LANCZOS).save(os.path.join(OUT, f"emblem{suffix}.png"))


def wallpapers():
    """The desktop art, plus a blurred, darkened copy for the porta (lock screen)."""
    art = Image.open(os.path.join(ROOT, "art/wallpapers/atlas.png")).convert("RGB")
    art.save(os.path.join(OUT, "atlas.jpg"), quality=92)
    small = art.resize((art.width // 2, art.height // 2), Image.LANCZOS)
    blurred = small.filter(ImageFilter.GaussianBlur(14)).point(lambda v: int(v * 0.42))
    blurred.resize(art.size, Image.LANCZOS).save(os.path.join(OUT, "atlas-porta.jpg"), quality=88)


def main():
    os.makedirs(OUT, exist_ok=True)
    slab()
    texture("art/textures/porphyry.jpg", "porphyry.jpg", 360)
    moulding()
    branding()
    wallpapers()
    print("shell assets written to", OUT)


if __name__ == "__main__":
    main()
