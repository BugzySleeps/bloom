#!/usr/bin/env python3
"""readme-art.py <shapes.json> <font.ttf> <outdir>: Bloom's logo and the README banner, from the shell's own
shapes (make shapes.json with tools/shapes-json.sh)."""
import json, math, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

shapes = json.load(open(sys.argv[1]))
FONT, OUT = sys.argv[2], sys.argv[3]
SS = 3
GOLD, CREAM, DEEP = (214, 188, 120), (246, 236, 208), (24, 24, 17)


def poly(name, cx, cy, r, rot=0, sx=1.0):
    a = math.radians(rot)
    return [((cx + (x * sx * math.cos(a) - y * math.sin(a)) * r) * SS, (cy + (x * sx * math.sin(a) + y * math.cos(a)) * r) * SS)
            for x, y in shapes[name]]


def font(size, weight):
    f = ImageFont.truetype(FONT, size * SS)
    try:
        f.set_variation_by_axes([weight if a.get("name", b"") in (b"Weight", "Weight") else a["default"] for a in f.get_variation_axes()])
    except Exception:
        pass
    return f


def mark(d, cx, cy, r):
    """the logo: a gold twelve-sided cookie, a cream flower inside it, a little gold sun in the heart"""
    d.polygon(poly("cookie12", cx, cy, r, 8), fill=GOLD)
    d.polygon(poly("flower", cx, cy, r * 0.62, 22), fill=CREAM)
    d.polygon(poly("sunny", cx, cy, r * 0.27), fill=GOLD)


# ---- logo (512 square, see-through)
L = Image.new("RGBA", (512 * SS, 512 * SS), (0, 0, 0, 0))
mark(ImageDraw.Draw(L), 256, 256, 240)
L.resize((512, 512), Image.LANCZOS).save(f"{OUT}/logo.png")

# ---- banner (1280x400)
W, H = 1280, 400
img = Image.new("RGB", (W // 4, H // 4))
px = img.load()
for y in range(H // 4):
    for x in range(W // 4):
        u, v = x / (W / 4), y / (H / 4)
        t = 0.55 * v + 0.45 * u
        c = [int(a + (b - a) * t ** 1.3) for a, b in zip((22, 24, 16), (96, 80, 40))]
        g = max(0.0, 1 - math.hypot(u - 0.85, v - 1.0) / 0.7)
        c = [int(a + (b - a) * g * g * 0.65) for a, b in zip(c, (200, 164, 86))]
        px[x, y] = tuple(c)
img = img.resize((W * SS, H * SS), Image.BICUBIC).convert("RGBA")

soft = Image.new("RGBA", img.size, (0, 0, 0, 0))
ds = ImageDraw.Draw(soft)
for name, cx, cy, r, rot in [("cookie12", 1150, 60, 210, 10), ("clover4", 90, 380, 220, 20), ("sunny", 700, 470, 170, 0)]:
    ds.polygon(poly(name, cx, cy, r, rot), fill=(220, 190, 110, 30))
img = Image.alpha_composite(img, soft.filter(ImageFilter.GaussianBlur(6 * SS)))

near = Image.new("RGBA", img.size, (0, 0, 0, 0))
dn = ImageDraw.Draw(near)
for name, cx, cy, r, rot, a in [("pentagon", 980, 300, 38, -8, 90), ("softBurst", 1080, 190, 26, 0, 110), ("clover8", 870, 120, 30, 12, 80),
                                ("gem", 1190, 300, 22, 14, 90), ("cookie6", 610, 70, 18, 0, 80), ("triangle", 560, 330, 16, 18, 80)]:
    dn.polygon(poly(name, cx, cy, r, rot), fill=(236, 210, 140, a))
pts = [((760 + s) * SS, (350 + math.sin(s / 26 * math.pi) * 7) * SS) for s in range(0, 260, 2)]
dn.line(pts, fill=(236, 210, 140, 110), width=5 * SS, joint="curve")
img = Image.alpha_composite(img, near)

d = ImageDraw.Draw(img)
mark(d, 230, 200, 118)
d.text((390 * SS, 112 * SS), "Bloom", font=font(118, 720), fill=CREAM)
d.text((396 * SS, 262 * SS), "a Quickshell desktop made of shapes", font=font(30, 450), fill=(226, 212, 178))
img.resize((W, H), Image.LANCZOS).convert("RGB").save(f"{OUT}/banner.png", optimize=True)
print("ok")
