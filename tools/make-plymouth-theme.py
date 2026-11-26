#!/usr/bin/python3
"""Render the Armatos Plymouth boot splash into art/plymouth/armatos/.

Plymouth draws text with whatever fonts are in the initramfs, so every word
here is baked into an image in Cinzel. Images are drawn for a 1920-pixel-tall
screen (the 13 Pro) and the script scales them to the screen it finds. Behind
them sits the Atlas art, blurred and darkened, so boot carries on from GRUB. The script shows the emblem, a gold
progress rule, and — when an installed system asks for the LUKS passphrase —
a carved TESSERA prompt with one gold dot per character typed.
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art/plymouth/armatos")
FONTS = os.path.join(ROOT, "art/fonts")
GOLD, CREAM, DIM = (234, 197, 94), (216, 207, 196), (90, 70, 40)


def text_image(name, text, size, color, weight="Bold", tracking=0.18):
    font = ImageFont.truetype(os.path.join(FONTS, f"Cinzel-{weight}.ttf"), size)
    gap = int(size * tracking)
    widths = [font.getbbox(ch)[2] - font.getbbox(ch)[0] if ch != " " else size // 3 for ch in text]
    w = sum(widths) + gap * (len(text) - 1) + 8
    h = int(size * 1.4)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x = 4
    for ch, cw in zip(text, widths):
        if ch != " ":
            d.text((x - font.getbbox(ch)[0], int(size * 0.15)), ch, font=font, fill=color + (255,))
        x += cw + gap
    img.save(os.path.join(OUT, name))


def main():
    os.makedirs(OUT, exist_ok=True)
    emblem = Image.open(os.path.join(ROOT, "art/branding/emblem.png")).convert("RGBA").resize((480, 480), Image.LANCZOS)
    framed = Image.new("RGBA", (504, 504), GOLD + (255,))
    ImageDraw.Draw(framed).rectangle((4, 4, 499, 499), fill=(18, 13, 11, 255))
    framed.paste(emblem, (12, 12))
    framed.save(os.path.join(OUT, "emblem.png"))
    # The Atlas art, blurred and dimmed; small, since blur hides the scaling.
    art = Image.open(os.path.join(ROOT, "art/wallpapers/atlas.png")).convert("RGB")
    art = art.resize((960, round(960 * art.height / art.width)), Image.LANCZOS)
    art = art.filter(ImageFilter.GaussianBlur(14))
    art = ImageEnhance.Brightness(art).enhance(0.38)
    art = Image.blend(art, Image.new("RGB", art.size, (30, 10, 12)), 0.25)
    art.save(os.path.join(OUT, "background.png"), optimize=True)
    Image.new("RGBA", (560, 3), DIM + (255,)).save(os.path.join(OUT, "track.png"))
    Image.new("RGBA", (560, 3), GOLD + (255,)).save(os.path.join(OUT, "fill.png"))
    text_image("ave.png", "AVE · IMPERATOR", 40, CREAM)
    text_image("tessera.png", "TESSERA", 34, GOLD)
    text_image("hint.png", "PORTAE CLAVSAE SVNT", 28, CREAM, weight="Medium")
    dot = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    ImageDraw.Draw(dot).ellipse((2, 2, 15, 15), fill=GOLD + (255,))
    dot.save(os.path.join(OUT, "dot.png"))
    rule = Image.new("RGBA", (460, 3), GOLD + (255,))
    rule.save(os.path.join(OUT, "rule.png"))
    with open(os.path.join(OUT, "armatos.plymouth"), "w") as f:
        f.write("""[Plymouth Theme]
Name=Armatos
Description=Armatos Linux: the emblem, a gold rule, and the Tessera prompt
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/armatos
ScriptFile=/usr/share/plymouth/themes/armatos/armatos.script
""")
    with open(os.path.join(OUT, "armatos.script"), "w") as f:
        f.write(SCRIPT)
    print("theme written to", OUT)


SCRIPT = r"""// Armatos boot splash — rendered by tools/make-plymouth-theme.py
// Images are drawn for a 1920-px-tall screen and scaled to this one.
Window.SetBackgroundTopColor(0.071, 0.051, 0.043);
Window.SetBackgroundBottomColor(0.071, 0.051, 0.043);

sw = Window.GetWidth(); sh = Window.GetHeight();
cx = Window.GetX() + sw / 2;
cy = Window.GetY() + sh / 2;
k = sh / 1920;
if (k > 1) k = 1;

fun scaled(name) {
	img = Image(name);
	return img.Scale(Math.Int(img.GetWidth() * k), Math.Int(img.GetHeight() * k));
}

bg.raw = Image("background.png");
bs = sw / bg.raw.GetWidth();
if (sh / bg.raw.GetHeight() > bs) bs = sh / bg.raw.GetHeight();
bg.image = bg.raw.Scale(Math.Int(bg.raw.GetWidth() * bs), Math.Int(bg.raw.GetHeight() * bs));
bg.sprite = Sprite(bg.image);
bg.sprite.SetPosition(cx - bg.image.GetWidth() / 2, cy - bg.image.GetHeight() / 2, -10);

emblem.image = scaled("emblem.png");
emblem.sprite = Sprite(emblem.image);
emblem.sprite.SetPosition(cx - emblem.image.GetWidth() / 2, cy - emblem.image.GetHeight() / 2 - 110 * k, 1);

ave.image = scaled("ave.png");
ave.sprite = Sprite(ave.image);
ave.sprite.SetPosition(cx - ave.image.GetWidth() / 2, cy + 175 * k, 1);

track.image = scaled("track.png");
track.sprite = Sprite(track.image);
track.sprite.SetPosition(cx - track.image.GetWidth() / 2, cy + 255 * k, 1);
fill.original = scaled("fill.png");
fill.sprite = Sprite();
fill.sprite.SetPosition(cx - track.image.GetWidth() / 2, cy + 255 * k, 2);

fun progress_callback(duration, progress) {
	w = Math.Int(fill.original.GetWidth() * progress);
	if (w < 1) w = 1;
	fill.sprite.SetImage(fill.original.Scale(w, fill.original.GetHeight()));
}
Plymouth.SetBootProgressFunction(progress_callback);

// --- The Tessera: LUKS passphrase prompt --------------------------------
prompt.label = Sprite(scaled("tessera.png"));
prompt.hint = Sprite(scaled("hint.png"));
prompt.rule = Sprite(scaled("rule.png"));
dot.image = scaled("dot.png");
dots = [];
fun hide_prompt() {
	prompt.label.SetOpacity(0); prompt.hint.SetOpacity(0); prompt.rule.SetOpacity(0);
	for (i = 0; dots[i]; i++) dots[i].SetOpacity(0);
}
hide_prompt();

fun display_password_callback(text, bullets) {
	top = cy + 320 * k;
	prompt.hint.SetPosition(cx - prompt.hint.GetImage().GetWidth() / 2, top, 3);
	prompt.label.SetPosition(cx - prompt.label.GetImage().GetWidth() / 2, top + 54 * k, 3);
	prompt.rule.SetPosition(cx - prompt.rule.GetImage().GetWidth() / 2, top + 160 * k, 3);
	prompt.hint.SetOpacity(1); prompt.label.SetOpacity(1); prompt.rule.SetOpacity(1);
	for (i = 0; dots[i]; i++) dots[i].SetOpacity(0);
	shown = bullets; if (shown > 20) shown = 20;
	step = 26 * k;
	start = cx - (shown * step) / 2;
	for (i = 0; i < shown; i++) {
		if (!dots[i]) dots[i] = Sprite(dot.image);
		dots[i].SetPosition(start + i * step, top + 125 * k, 3);
		dots[i].SetOpacity(1);
	}
}
Plymouth.SetDisplayPasswordFunction(display_password_callback);

fun display_normal_callback() { hide_prompt(); }
Plymouth.SetDisplayNormalFunction(display_normal_callback);
"""

if __name__ == "__main__":
    main()
