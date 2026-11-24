#!/usr/bin/env python3
"""team.py <dir> <cache>: get your character pictures ready for the island's panel. Any picture Pillow can open
(png, webp, avif, jpg…) is trimmed to its see-through edges, scaled to fit 192x192 and saved as a png in the
cache (animated gifs are copied as they are). Prints one line per character: <cache file>\t<original name>.
Only redoes a picture when the original is newer than its copy."""
import os
import shutil
import sys

from PIL import Image

src, cache = sys.argv[1], sys.argv[2]
os.makedirs(cache, exist_ok=True)
keep = set()
for f in sorted(os.listdir(src)):
    p = os.path.join(src, f)
    if not os.path.isfile(p):
        continue
    stem, ext = os.path.splitext(f)
    gif = ext.lower() == ".gif"
    out = os.path.join(cache, stem + (".gif" if gif else ".png"))
    keep.add(os.path.basename(out))
    if not os.path.exists(out) or os.path.getmtime(out) < os.path.getmtime(p):
        try:
            if gif:
                shutil.copyfile(p, out)
            else:
                im = Image.open(p).convert("RGBA")
                box = im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
                if box:
                    im = im.crop(box)
                im.thumbnail((192, 192), Image.LANCZOS)
                im.save(out, optimize=True)
        except Exception:
            continue
    print(out + "\t" + f)
for f in os.listdir(cache):   # copies of pictures you've since taken out
    if f not in keep:
        os.remove(os.path.join(cache, f))
