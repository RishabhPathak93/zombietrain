#!/usr/bin/env python3
"""Neon-apocalypse props: puzzle console, gates, lore note, neon tubes."""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
SS = 4
OL = (24, 20, 32, 255)

def canvas(w, h): return Image.new("RGBA", (w*SS, h*SS), (0,0,0,0))
def save(img, name, w, h):
    img.resize((w, h), Image.LANCZOS).save(os.path.join(OUT, name)); print("wrote", name)

def rr(d, box, r, fill, ol=None, ow=2):
    b = [v*SS for v in box]
    if ol:
        d.rounded_rectangle(b, radius=r*SS, fill=ol)
        o = ow*SS
        d.rounded_rectangle([b[0]+o, b[1]+o, b[2]-o, b[3]-o], radius=max(1,(r-ow)*SS), fill=fill)
    else:
        d.rounded_rectangle(b, radius=r*SS, fill=fill)

# puzzle console: standing terminal with glowing screen
img = canvas(64, 78); d = ImageDraw.Draw(img)
rr(d, (10, 30, 54, 72), 5, (52, 56, 72, 255), OL)
rr(d, (14, 8, 50, 36), 4, (40, 44, 58, 255), OL)
rr(d, (18, 12, 46, 30), 2, (28, 60, 66, 255))
for i, y in enumerate((15, 20, 25)):
    d.line([(20*SS, y*SS), ((44 - i*8)*SS, y*SS)], fill=(90, 240, 220, 255), width=int(1.6*SS))
rr(d, (18, 42, 30, 50), 2, (90, 240, 220, 200))
rr(d, (34, 42, 46, 50), 2, (255, 90, 90, 200))
rr(d, (18, 56, 46, 62), 2, (34, 36, 48, 255))
save(img, "console.png", 64, 78)

# metal gate (tiling horizontally, 128x96)
img = canvas(128, 96); d = ImageDraw.Draw(img)
rr(d, (2, 4, 126, 92), 3, (58, 62, 78, 255), OL, 2.5)
for x in range(10, 128, 18):
    d.line([(x*SS, 8*SS), (x*SS, 88*SS)], fill=(42, 45, 58, 255), width=int(3*SS))
d.line([(4*SS, 26*SS), (124*SS, 26*SS)], fill=(255, 200, 60, 255), width=int(2.5*SS))
d.line([(4*SS, 70*SS), (124*SS, 70*SS)], fill=(255, 200, 60, 255), width=int(2.5*SS))
for x in range(14, 124, 26):  # hazard stripes
    d.polygon([(x*SS, 30*SS), ((x+10)*SS, 30*SS), ((x+4)*SS, 66*SS), ((x-6)*SS, 66*SS)], fill=(226, 178, 52, 90))
save(img, "gate.png", 128, 96)

# lore note: worn paper with scribbles
img = canvas(40, 46); d = ImageDraw.Draw(img)
rr(d, (5, 4, 35, 42), 2, (228, 220, 198, 255), OL, 1.6)
for i, y in enumerate(range(11, 38, 5)):
    d.line([(9*SS, y*SS), ((31 - (i % 3) * 4)*SS, y*SS)], fill=(120, 110, 96, 255), width=int(1.2*SS))
d.polygon([(28*SS, 4*SS), (35*SS, 4*SS), (35*SS, 11*SS)], fill=(190, 180, 158, 255))
save(img, "note.png", 40, 46)

# neon tube strip (additive-friendly): horizontal bar with hot core
w, h = 128, 20
arr = np.zeros((h*SS, w*SS, 4), dtype=np.float32)
yy = np.arange(h*SS)[:, None]
core = np.exp(-((yy - h*SS/2)**2) / (2*(1.6*SS)**2))
halo = np.exp(-((yy - h*SS/2)**2) / (2*(6*SS)**2))
val = np.clip(core*255 + halo*110, 0, 255)
arr[..., 0] = val; arr[..., 1] = val; arr[..., 2] = val; arr[..., 3] = val
img = Image.fromarray(arr.astype(np.uint8))
img.resize((w, h), Image.LANCZOS).save(os.path.join(OUT, "neon_tube.png")); print("wrote neon_tube.png")

# code fragment chip
img = canvas(30, 30); d = ImageDraw.Draw(img)
rr(d, (4, 6, 26, 24), 3, (36, 40, 54, 255), OL, 1.6)
d.rectangle([(8*SS), (10*SS), (22*SS), (20*SS)], fill=(90, 240, 220, 230))
d.line([(11*SS, 10*SS), (11*SS, 20*SS)], fill=(30, 90, 84, 255), width=int(1.2*SS))
d.line([(17*SS, 10*SS), (17*SS, 20*SS)], fill=(30, 90, 84, 255), width=int(1.2*SS))
save(img, "codechip.png", 30, 30)
print("NEON PROPS DONE")
