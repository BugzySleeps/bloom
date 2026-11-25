#!/usr/bin/env python3
"""seed.py <image>: print the colour Bloom builds its theme from: the most common colourful hue in the picture
(weighted by how colourful each pixel is, so a big grey sky doesn't win). Greys only if there's no colour."""
import colorsys
import math
import sys

from PIL import Image

try:
    im = Image.open(sys.argv[1])
    im.draft("RGB", (192, 192))   # JPEGs decode at reduced size: a big wallpaper takes a fraction of the time
    im = im.convert("RGB")
except Exception:
    print("#b59a4c")
    sys.exit()
im.thumbnail((96, 96))
buckets = [[0.0, 0.0, 0.0, 0.0, 0.0] for _ in range(36)]   # weight, sum h-x, sum h-y, sum s, sum v
total = 0.0
px = im.tobytes()
for j in range(0, len(px), 3):
    r, g, b = px[j], px[j + 1], px[j + 2]
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    w = s * s * (0.25 + v) * (v > 0.12)
    total += 1
    if w < 0.02:
        continue
    k = buckets[int(h * 36) % 36]
    k[0] += w
    k[1] += math.cos(h * 2 * math.pi) * w
    k[2] += math.sin(h * 2 * math.pi) * w
    k[3] += s * w
    k[4] += v * w
# the best hue counts its neighbours too, so a gradient isn't split across buckets
score = [buckets[i][0] + 0.5 * (buckets[i - 1][0] + buckets[(i + 1) % 36][0]) for i in range(36)]
i = max(range(36), key=lambda i: score[i])
if score[i] < total * 0.01:
    print("#8a8a8a")
    sys.exit()
group = [buckets[(i + d) % 36] for d in (-1, 0, 1)]
W = sum(k[0] for k in group)
h = (math.atan2(sum(k[2] for k in group), sum(k[1] for k in group)) / (2 * math.pi)) % 1
s = max(0.35, min(0.8, sum(k[3] for k in group) / W))
v = max(0.55, min(0.85, sum(k[4] for k in group) / W))
r, g, b = colorsys.hsv_to_rgb(h, s, v)
print("#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255)))
