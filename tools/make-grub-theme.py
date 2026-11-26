#!/usr/bin/python3
"""Render the Armatos GRUB theme into art/grub/armatos/.

Under Secure Boot, Ubuntu's signed GRUB refuses to load font files, so every
word here is drawn into images in Cinzel: the lettering is baked into the
background, each menu entry is its own image (shown as the entry's icon, with
GRUB's own text made transparent), and the countdown is a draining gold bar.

GRUB can't blur or shade anything at boot, so the look is baked here:
the Atlas art, a frosted (blurred, darkened) tablet where the menu sits,
between the two giants, framed in gilded rules and a bead-and-reel moulding,
and a porphyry highlight for the chosen entry. The menu is laid out with wide
margins inside the tablet, so it stays on the frosted glass when GRUB's "crop"
scaling trims a 16:9 screen as well as on the 13 Pro's 3:2.

  tools/make-grub-theme.py        (needs python3-pil and grub-common)
"""
import os
import random
import shutil
import subprocess
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art/grub/armatos")
ART = os.path.join(ROOT, "art/wallpapers/atlas.png")
FONTS = os.path.join(ROOT, "art/fonts")
W, H = 1920, 1280                       # 3:2, the 13 Pro's shape
PANEL = (0.30, 0.43, 0.70, 0.83)        # frosted tablet: left, top, right, bottom
GOLD = (214, 172, 70)
GOLD_HI = (246, 222, 140)
GOLD_LO = (122, 90, 22)


def cover(img, w, h):
    """Scale and centre-crop to fill w×h."""
    s = max(w / img.width, h / img.height)
    img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
    x, y = (img.width - w) // 2, (img.height - h) // 2
    return img.crop((x, y, x + w, y + h))


def bead_and_reel(width, height):
    """A gilded bead-and-reel moulding strip."""
    strip = Image.new("RGBA", (width, height), GOLD_LO + (255,))
    d = ImageDraw.Draw(strip)
    unit = height * 3
    for x0 in range(-unit, width + unit, unit):
        # Bead: long oval, shaded by stacked ellipses from dark rim to highlight.
        bx0, bx1 = x0 + height * 0.25, x0 + height * 1.75
        for i in range(8):
            t = i / 7
            c = tuple(int(GOLD_LO[k] + (GOLD_HI[k] - GOLD_LO[k]) * t) for k in range(3))
            inset = t * height * 0.32
            d.ellipse((bx0 + inset, 2 + inset * 0.7, bx1 - inset * 1.2, height - 2 - inset), fill=c + (255,))
        # Reels: two small upright discs.
        for rx in (x0 + height * 2.05, x0 + height * 2.6):
            for i in range(6):
                t = i / 5
                c = tuple(int(GOLD_LO[k] + (GOLD_HI[k] - GOLD_LO[k]) * t) for k in range(3))
                inset = t * height * 0.15
                d.ellipse((rx - height * 0.2 + inset, 3 + inset, rx + height * 0.2 - inset, height - 3 - inset), fill=c + (255,))
    return strip


def font(weight, size):
    return ImageFont.truetype(os.path.join(FONTS, f"Cinzel-{weight}.ttf"), size)


def tracked(draw, xy_center, text, fnt, fill, tracking=0.16, shadow=True):
    """Draw letter-spaced text centred on xy_center, with a carved shadow."""
    gap = int(fnt.size * tracking)
    widths = [(fnt.getbbox(c)[2] - fnt.getbbox(c)[0]) if c != " " else fnt.size // 3 for c in text]
    total = sum(widths) + gap * (len(text) - 1)
    x = xy_center[0] - total // 2
    y = xy_center[1] - fnt.size // 2
    for c, w in zip(text, widths):
        if c != " ":
            ox = -fnt.getbbox(c)[0]
            if shadow:
                draw.text((x + ox + 2, y + 2), c, font=fnt, fill=(0, 0, 0, 170))
            draw.text((x + ox, y), c, font=fnt, fill=fill)
        x += w + gap


# GRUB 2.14 (as signed by Ubuntu) draws the selection slab ~82 px wider than the
# menu box, to the right, and draws the icon 7 px in. The box is placed so the
# slab is centred, and the text is centred on the slab, not on the image.
SLAB_EXTRA, ICON_INSET = 90, 7
MENU_W = 600
ENTRY_H = 50                 # room for four entries on an installed system


def entry_icon(name, text, w=600, h=ENTRY_H):
    """A menu entry drawn as an image: GRUB shows it as the entry's icon."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    centre = (MENU_W + SLAB_EXTRA) // 2 - ICON_INSET
    tracked(ImageDraw.Draw(img), (centre, h // 2 + 2), text, font("Bold", 28), (236, 228, 216, 255), tracking=0.10)
    os.makedirs(os.path.join(OUT, "icons"), exist_ok=True)
    img.save(os.path.join(OUT, "icons", f"{name}.png"))


def background():
    art = cover(Image.open(ART).convert("RGB"), W, H)
    x0, y0, x1, y1 = int(W * PANEL[0]), int(H * PANEL[1]), int(W * PANEL[2]), int(H * PANEL[3])
    # Frosted glass: the art behind the tablet, blurred, dimmed, warmed.
    glass = art.crop((x0, y0, x1, y1)).filter(ImageFilter.GaussianBlur(22))
    # A soft shadow so the tablet sits on the scene rather than in it.
    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rectangle((x0 - 6, y0 + 10, x1 + 6, y1 + 22), fill=150)
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))
    art = Image.composite(Image.new("RGB", (W, H), (8, 4, 3)), art, shadow)
    # (The glass is made below from this untouched copy, so the shadow doesn't muddy it.)
    glass = ImageEnhance.Brightness(glass).enhance(0.58)
    glass = Image.blend(glass, Image.new("RGB", glass.size, (42, 12, 14)), 0.20)
    art.paste(glass, (x0, y0))
    d = ImageDraw.Draw(art)
    mh = 16
    strip = bead_and_reel(x1 - x0 + 8, mh)
    art.paste(strip, (x0 - 4, y0 - mh), strip)
    art.paste(strip, (x0 - 4, y1), strip)
    d.rectangle((x0 - 4, y0 - mh - 4, x1 + 4, y0 - mh - 3), fill=GOLD)
    d.rectangle((x0 - 4, y1 + mh + 2, x1 + 4, y1 + mh + 3), fill=GOLD)
    for x in (x0 - 4, x1 + 2):
        d.rectangle((x, y0 - mh, x + 2, y1 + mh), fill=GOLD)
    d.rectangle((x0 + 10, y0 + 10, x1 - 10, y1 - 10), outline=GOLD_LO, width=1)
    # Lettering, baked in (GRUB can't load fonts under Secure Boot).
    art = art.convert("RGBA")
    layer = Image.new("RGBA", art.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    tracked(ld, (W // 2, int(H * 0.475)), "ARMATOS LINUX", font("Black", 58), (234, 197, 94, 255))
    tracked(ld, (W // 2, int(H * 0.522)), "MMDCCLXXIX · AVE, IMPERATOR", font("Bold", 21), (216, 207, 196, 255), tracking=0.22)
    ld.rectangle((W // 2 - 160, int(H * 0.540), W // 2 + 160, int(H * 0.540) + 1), fill=GOLD + (255,))
    tracked(ld, (W // 2, int(H * 0.800)), "SAGITTIS ELIGE · ENTER INCIPE · E MVTA · C IMPERIVM", font("Bold", 17), (234, 197, 94, 255), tracking=0.14)
    art = Image.alpha_composite(art, layer).convert("RGB")
    art.save(os.path.join(OUT, "background.jpg"), quality=90)


def highlight():
    """9-slice porphyry tile with a gilded edge, for the selected entry."""
    por = Image.open(os.path.join(ROOT, "art/textures/porphyry.jpg")).convert("RGB")
    size, c = 48, 6
    tile = por.crop((0, 0, size, size)).convert("RGBA")
    d = ImageDraw.Draw(tile)
    d.rectangle((0, 0, size - 1, size - 1), outline=GOLD + (255,), width=2)
    d.rectangle((3, 3, size - 4, size - 4), outline=GOLD_LO + (255,), width=1)
    parts = {
        "nw": (0, 0, c, c), "n": (c, 0, size - c, c), "ne": (size - c, 0, size, c),
        "w": (0, c, c, size - c), "c": (c, c, size - c, size - c), "e": (size - c, c, size, size - c),
        "sw": (0, size - c, c, size), "s": (c, size - c, size - c, size), "se": (size - c, size - c, size, size),
    }
    for name, box in parts.items():
        tile.crop(box).save(os.path.join(OUT, f"select_{name}.png"))


def bar_images():
    """The countdown: a thin gold rule that drains (GRUB's bar has a minimum
    height, so the rule is painted into the middle of taller transparent slices)."""
    for name, col in (("bar", (58, 46, 28, 255)), ("hl", GOLD + (255,))):
        for part, (w, h) in {"c": (8, 24), "n": (8, 1), "s": (8, 1), "w": (1, 24), "e": (1, 24),
                             "nw": (1, 1), "ne": (1, 1), "sw": (1, 1), "se": (1, 1)}.items():
            img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            if part in ("c", "w", "e"):
                ImageDraw.Draw(img).rectangle((0, 11, w - 1, 13), fill=col)
            img.save(os.path.join(OUT, f"{name}_{part}.png"))


def icons():
    # The live ISO's entries (its grub.cfg is written by tools/build-iso.sh)
    entry_icon("salve", "SALVE · LIVE SESSION")
    entry_icon("salvesafe", "SALVE · SAFE GRAPHICS")
    # An installed system's (written by /etc/grub.d/09_armatos)
    entry_icon("imperium", "SALVE · ARMATOS LINUX")
    entry_icon("imperiumprior", "SALVE · EARLIER KERNEL")
    entry_icon("imperiumtuta", "SALVE · RECOVERY")
    # Both
    entry_icon("fundamenta", "FVNDAMENTA · FIRMWARE")


def theme_txt():
    text = '''# Armatos GRUB theme — rendered by tools/make-grub-theme.py
# All lettering is in the images: under Secure Boot GRUB can't load fonts.
title-text: ""
desktop-image: "background.jpg"
desktop-image-scale-method: "crop"
desktop-color: "#120D0B"

+ boot_menu {
	left = 50%-345 width = 600 top = 55% height = 18%
	item_color = "#00000000"
	selected_item_color = "#00000000"
	selected_item_pixmap_style = "select_*.png"
	icon_width = 600 icon_height = 50 item_icon_space = 0
	item_height = 50 item_padding = 0 item_spacing = 6
	scrollbar = false scrollbar_width = 0
}
+ progress_bar {
	id = "__timeout__"
	left = 40% width = 20% top = 75% height = 24
	show_text = false
	bar_style = "bar_*.png" highlight_style = "hl_*.png"
}
'''
    with open(os.path.join(OUT, "theme.txt"), "w") as f:
        f.write(text)


def main():
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(OUT)
    background()
    highlight()
    bar_images()
    icons()
    theme_txt()
    print("theme written to", OUT)


if __name__ == "__main__":
    random.seed(7)
    main()
