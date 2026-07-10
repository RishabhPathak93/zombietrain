#!/usr/bin/env python3
"""Chapter 2 + cinematic intro assets (city skylines, side train, relays, tower)."""
import math, os, random, subprocess
import numpy as np
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
rng = random.Random(21)

# ---------- parallax skylines (side view, tile horizontally) ----------
def skyline(name, w, h, base_col, win_col, win_chance, min_bw, max_bw, min_bh, max_bh, broken=False):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x = 0
    while x < w:
        bw = rng.randint(min_bw, max_bw)
        bh = rng.randint(min_bh, max_bh)
        top = h - bh
        if broken and rng.random() < 0.35:
            # jagged ruined top
            d.rectangle([x, top + 14, x + bw, h], fill=base_col)
            pts = [(x, top + 14)]
            seg_x = x
            while seg_x < x + bw:
                seg_w = rng.randint(8, 22)
                pts.append((seg_x, top + rng.randint(0, 18)))
                seg_x += seg_w
            pts.append((x + bw, top + 14))
            pts.append((x + bw, h)); pts.append((x, h))
            d.polygon(pts, fill=base_col)
        else:
            d.rectangle([x, top, x + bw, h], fill=base_col)
        # antenna
        if rng.random() < 0.25:
            ax = x + rng.randint(6, max(7, bw - 6))
            d.line([(ax, top), (ax, top - rng.randint(8, 22))], fill=base_col, width=2)
        # windows
        for wy in range(top + 8, h - 6, 12):
            for wx in range(x + 5, x + bw - 5, 10):
                if rng.random() < win_chance:
                    d.rectangle([wx, wy, wx + 4, wy + 6], fill=win_col)
        x += bw + rng.randint(2, 10)
    img.save(os.path.join(OUT, name)); print("wrote", name)

skyline("city_far.png", 960, 300, (30, 34, 58, 255), (255, 216, 120, 200), 0.05, 30, 70, 90, 280)
skyline("city_near.png", 960, 380, (16, 18, 32, 255), (255, 200, 100, 230), 0.03, 60, 130, 120, 360, broken=True)

# ---------- side-view armored train (for the cinematic) ----------
w, h = 760, 170
img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
def rr(box, r, fill, outline=None, ow=3):
    if outline:
        d.rounded_rectangle(box, radius=r, fill=outline)
        d.rounded_rectangle([box[0]+ow, box[1]+ow, box[2]-ow, box[3]-ow], radius=max(1, r-ow), fill=fill)
    else:
        d.rounded_rectangle(box, radius=r, fill=fill)
OL = (18, 16, 26, 255)
for seg in range(3):
    x0 = 10 + seg * 235
    rr((x0, 30, x0 + 220, 130), 12, (58, 70, 92, 255), OL)
    rr((x0 + 12, 44, x0 + 208, 72), 6, (96, 112, 138, 255))
    for wx in range(x0 + 20, x0 + 200, 34):
        rr((wx, 50, wx + 18, 66), 3, (255, 216, 130, 235))
    rr((x0 + 12, 84, x0 + 208, 118), 6, (44, 52, 70, 255))
    for rx in (x0 + 30, x0 + 90, x0 + 150):
        d.ellipse([rx, 118, rx + 44, 162], fill=(30, 32, 44, 255), outline=OL, width=3)
        d.ellipse([rx + 14, 132, rx + 30, 148], fill=(80, 86, 104, 255))
# engine nose (right)
d.polygon([(690, 30), (748, 70), (748, 130), (690, 130)], fill=(70, 84, 108, 255), outline=OL)
rr((712, 78, 746, 112), 8, (255, 224, 140, 255), OL)
# couplers
for cx in (230, 465):
    d.rectangle([cx, 95, cx + 18, 108], fill=(30, 30, 42, 255))
img.save(os.path.join(OUT, "train_side.png")); print("wrote train_side.png")

# ---------- moon ----------
size = 140
img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.ellipse([8, 8, size - 8, size - 8], fill=(236, 238, 250, 255))
for (cx, cy, r) in [(48, 52, 12), (86, 78, 9), (66, 96, 7), (94, 40, 6)]:
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(208, 212, 232, 255))
img.save(os.path.join(OUT, "moon.png")); print("wrote moon.png")

# ---------- chapter 2 top-down tiles ----------
img = Image.new("RGBA", (128, 128), (52, 54, 62, 255))
d = ImageDraw.Draw(img)
for _ in range(80):
    x, y = rng.randrange(128), rng.randrange(128)
    c = 52 + rng.randint(-8, 8)
    d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=(c, c, c + 6, 255))
for dx in range(0, 128, 32):
    d.rectangle([dx, 60, dx + 18, 68], fill=(180, 176, 120, 255))
img.save(os.path.join(OUT, "road.png")); print("wrote road.png")

img = Image.new("RGBA", (128, 128), (38, 40, 52, 255))
d = ImageDraw.Draw(img)
d.rectangle([0, 0, 127, 127], outline=(26, 28, 38, 255), width=4)
for _ in range(3):
    x, y = rng.randrange(12, 90), rng.randrange(12, 90)
    d.rectangle([x, y, x + rng.randint(14, 26), y + rng.randint(14, 26)],
                fill=(50, 54, 68, 255), outline=(26, 28, 38, 255), width=2)
img.save(os.path.join(OUT, "roof.png")); print("wrote roof.png")

# ---------- relay pylon (top-down-ish icon) ----------
w, h = 72, 72
img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.ellipse([10, 10, 62, 62], fill=(60, 64, 80, 255), outline=OL, width=3)
d.ellipse([22, 22, 50, 50], fill=(84, 90, 110, 255))
for ang in range(0, 360, 60):
    a = math.radians(ang)
    x1, y1 = 36 + 14 * math.cos(a), 36 + 14 * math.sin(a)
    x2, y2 = 36 + 30 * math.cos(a), 36 + 30 * math.sin(a)
    d.line([(x1, y1), (x2, y2)], fill=(120, 128, 150, 255), width=4)
d.ellipse([29, 29, 43, 43], fill=(255, 70, 60, 255), outline=OL, width=2)
img.save(os.path.join(OUT, "relay.png")); print("wrote relay.png")

# ---------- broadcast tower (top-down base) ----------
size = 220
img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
c = size / 2
d.ellipse([14, 14, size - 14, size - 14], fill=(58, 60, 74, 255), outline=OL, width=5)
d.ellipse([44, 44, size - 44, size - 44], fill=(74, 78, 96, 255))
for ang in range(0, 360, 45):
    a = math.radians(ang)
    x1, y1 = c + 36 * math.cos(a), c + 36 * math.sin(a)
    x2, y2 = c + 92 * math.cos(a), c + 92 * math.sin(a)
    d.line([(x1, y1), (x2, y2)], fill=(120, 128, 150, 255), width=7)
d.ellipse([c - 26, c - 26, c + 26, c + 26], fill=(40, 40, 54, 255), outline=OL, width=4)
d.ellipse([c - 12, c - 12, c + 12, c + 12], fill=(255, 70, 60, 255))
img.save(os.path.join(OUT, "tower.png")); print("wrote tower.png")

# ---------- boss 2: The Broadcaster (crimson variant with antenna) ----------
SS = 4
def s(v): return v * SS
size = 150
img = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
cx = size / 2
def ell(box, fill, outline=None, ow=3):
    b = [s(v) for v in box]
    if outline:
        d.ellipse(b, fill=outline)
        d.ellipse([b[0] + s(ow), b[1] + s(ow), b[2] - s(ow), b[3] - s(ow)], fill=fill)
    else:
        d.ellipse(b, fill=fill)
body, body_hi, skin = (150, 42, 62, 255), (190, 80, 96, 255), (150, 190, 150, 255)
ar = size * 0.13
for side in (-1, 1):
    ell((cx + size * 0.05 - ar, cx + side * size * 0.26 - ar, cx + size * 0.05 + ar, cx + side * size * 0.26 + ar), body, OL, 2)
bw, bh = size * 0.62, size * 0.72
ell((cx - bw / 2, cx - bh / 2, cx + bw / 2, cx + bh / 2), body, OL, 3)
d.polygon([(s(cx - bw * 0.1), s(cx - bh * 0.3)), (s(cx + bw * 0.42), s(cx)), (s(cx - bw * 0.1), s(cx + bh * 0.3))], fill=body_hi)
hr = size * 0.20
ell((cx - hr + size * 0.04, cx - hr, cx + hr + size * 0.04, cx + hr), skin, OL, 3)
ell((cx - hr, cx - hr - size * 0.01, cx + hr + size * 0.05, cx + hr + size * 0.01), (30, 26, 40, 255), OL, 2)
# antenna array on the back
for off in (-0.16, 0.0, 0.16):
    x0, y0 = cx - size * 0.30, cx + off * size
    d.line([(s(x0), s(y0)), (s(x0 - size * 0.16), s(y0 - size * 0.05))], fill=(200, 205, 220, 255), width=s(2))
    ell((x0 - size * 0.19, y0 - size * 0.08, x0 - size * 0.13, y0 - size * 0.02), (255, 70, 60, 255))
img = img.resize((size, size), Image.LANCZOS)
img.save(os.path.join(OUT, "boss2.png")); print("wrote boss2.png")

# ---------- extra SFX ----------
SR = 22050
AOUT = "/tmp/zte_audio2"
os.makedirs(AOUT, exist_ok=True)
def wav_write(name, x):
    x = np.asarray(x, dtype=np.float64)
    x = x / (np.max(np.abs(x)) or 1) * 0.85
    import wave
    p = os.path.join(AOUT, name + ".wav")
    with wave.open(p, "w") as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR)
        f.writeframes((x * 32767).astype(np.int16).tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", p, "-c:a", "libvorbis", "-q:a", "3", p[:-4] + ".ogg"], check=True)
    print("wrote", name + ".ogg")

def env(n, pts):
    e = np.zeros(n); i = 0
    for L, v0, v1 in pts:
        L = min(int(L * SR), n - i)
        if L <= 0: break
        e[i:i + L] = np.linspace(v0, v1, L); i += L
    return e

# power_down: descending saw sweep + crackle
dur = 1.0; n = int(SR * dur)
f = np.linspace(420, 32, n)
ph = 2 * np.pi * np.cumsum(f) / SR
x = (2 * ((ph / (2 * np.pi)) % 1) - 1) * 0.6
crack = np.random.default_rng(3).uniform(-1, 1, n) * (np.random.default_rng(4).uniform(0, 1, n) > 0.97)
x = (x + crack * 0.7) * env(n, [(0.02, 0, 1), (0.7, 1, 0.5), (0.28, 0.5, 0)])
wav_write("power_down", x)

# signal: eerie repeating beep pattern
dur = 1.6; n = int(SR * dur)
x = np.zeros(n)
for i, (t0, f0) in enumerate([(0.0, 880), (0.25, 880), (0.5, 660), (0.9, 990), (1.15, 990)]):
    i0 = int(t0 * SR); L = int(0.12 * SR)
    seg = np.sin(2 * np.pi * f0 * np.arange(L) / SR) * env(L, [(0.01, 0, 1), (0.09, 1, 0.3), (0.02, 0.3, 0)])
    x[i0:i0 + L] += seg * 0.5
wav_write("signal", x)
print("CH2 ASSETS DONE")
