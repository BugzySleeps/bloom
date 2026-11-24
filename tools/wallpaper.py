#!/usr/bin/env python3
"""wallpaper.py <shapes.json> <out.png>: Bloom's own wallpaper. Big soft shapes (the same ones the shell uses;
make shapes.json with tools/shapes-json.sh) and a few squiggles on a warm olive-gold dusk."""
import json
import math
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

W, H, SS = 1920, 1080, 2
shapes = json.load(open(sys.argv[1]))
rnd = random.Random(7)


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


# the sky: dark olive at the top to a warm gold glow low on the right
base = Image.new("RGB", (W // 8, H // 8))
px = base.load()
for y in range(H // 8):
    for x in range(W // 8):
        u, v = x / (W / 8), y / (H / 8)
        t = v * 0.75 + u * 0.25
        c = lerp((30, 32, 22), (92, 78, 40), t ** 1.4)
        g = max(0.0, 1 - math.hypot(u - 0.78, v - 0.92) / 0.75)
        c = lerp(c, (196, 160, 82), g ** 2 * 0.7)
        px[x, y] = c
img = base.resize((W * SS, H * SS), Image.BICUBIC).convert("RGBA")


def shape(name, cx, cy, r, rot, fill, sx=1.0):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    a = math.radians(rot)
    pts = []
    for x, y in shapes[name]:
        x *= sx
        pts.append(((cx + (x * math.cos(a) - y * math.sin(a)) * r) * SS, (cy + (x * math.sin(a) + y * math.cos(a)) * r) * SS))
    d.polygon(pts, fill=fill)
    return layer


def squiggle(x0, y0, length, amp, wave, angle, width, fill):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    a = math.radians(angle)
    pts = []
    for i in range(int(length / 2)):
        s = i * 2
        o = math.sin(s / wave * 2 * math.pi) * amp
        pts.append(((x0 + s * math.cos(a) - o * math.sin(a)) * SS, (y0 + s * math.sin(a) + o * math.cos(a)) * SS))
    d.line(pts, fill=fill, width=width * SS, joint="curve")
    r = width * SS / 2
    for p in (pts[0], pts[-1]):
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=fill)
    return layer


# far shapes: big, faint, partly off the edges
for name, cx, cy, r, rot, col in [
    ("cookie12", 1660, 170, 330, 8, (214, 184, 104, 34)),
    ("clover4", 180, 900, 380, 20, (150, 160, 96, 30)),
    ("sunny", 980, 1150, 300, 0, (230, 196, 110, 26)),
    ("flower", -40, 120, 260, 12, (170, 150, 80, 26)),
]:
    img = Image.alpha_composite(img, shape(name, cx, cy, r, rot, col))
img = img.filter(ImageFilter.GaussianBlur(3 * SS))

# nearer shapes: smaller, crisper
for name, cx, cy, r, rot, col in [
    ("cookie9", 1500, 760, 120, 0, (232, 204, 128, 70)),
    ("pentagon", 420, 250, 70, -8, (200, 190, 120, 60)),
    ("softBurst", 820, 360, 46, 0, (240, 214, 140, 70)),
    ("clover8", 1240, 330, 58, 10, (180, 176, 104, 60)),
    ("gem", 640, 820, 52, 14, (226, 196, 120, 55)),
    ("cookie6", 1780, 560, 40, 0, (240, 214, 140, 60)),
    ("triangle", 1080, 720, 34, 18, (210, 186, 110, 55)),
]:
    img = Image.alpha_composite(img, shape(name, cx, cy, r, rot, col))

for x0, y0, ln, amp, wave, ang, w, col in [
    (90, 470, 380, 12, 70, -12, 6, (236, 210, 140, 70)),
    (1300, 980, 420, 10, 60, -6, 5, (236, 210, 140, 60)),
    (980, 120, 300, 9, 54, 8, 4, (200, 190, 130, 50)),
]:
    img = Image.alpha_composite(img, squiggle(x0, y0, ln, amp, wave, ang, w, col))

img = img.resize((W, H), Image.LANCZOS).convert("RGB")
# a little grain so the gradient doesn't band
noise = Image.effect_noise((W, H), 10).convert("RGB")
img = Image.blend(img, noise, 0.025)
img.save(sys.argv[2], optimize=True)
