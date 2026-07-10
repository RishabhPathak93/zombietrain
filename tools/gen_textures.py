#!/usr/bin/env python3
"""Generates all placeholder art for Zombie Train Escape. Flat, bright, outlined shapes."""
import math, os, random
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
os.makedirs(OUT, exist_ok=True)
SS = 4  # supersample

def canvas(w, h):
    return Image.new("RGBA", (w*SS, h*SS), (0,0,0,0))

def save(img, name, w, h):
    img = img.resize((w, h), Image.LANCZOS)
    img.save(os.path.join(OUT, name))
    print("wrote", name)

def s(v):
    return v*SS

def ellipse(d, box, fill, outline=None, ow=3):
    b = [s(x) for x in box]
    if outline:
        d.ellipse(b, fill=outline)
        b2 = [b[0]+s(ow)//1, b[1]+s(ow)//1, b[2]-s(ow)//1, b[3]-s(ow)//1]
        d.ellipse(b2, fill=fill)
    else:
        d.ellipse(b, fill=fill)

def rrect(d, box, r, fill, outline=None, ow=3):
    b = [s(x) for x in box]
    if outline:
        d.rounded_rectangle(b, radius=s(r), fill=outline)
        b2 = [b[0]+s(ow), b[1]+s(ow), b[2]-s(ow), b[3]-s(ow)]
        d.rounded_rectangle(b2, radius=max(1, s(r)-s(ow)), fill=fill)
    else:
        d.rounded_rectangle(b, radius=s(r), fill=fill)

def poly(d, pts, fill):
    d.polygon([(s(x), s(y)) for x, y in pts], fill=fill)

OUTLINE = (24, 22, 34, 255)

# ---------- characters (top-down, facing +X/right) ----------
def character(name, size, body_col, body_hi, head_col, arm_col, gun=False, hair=None, cap=None):
    w = h = size
    img = canvas(w, h); d = ImageDraw.Draw(img)
    c = size/2
    bw, bh = size*0.62, size*0.72   # body (shoulders wide on Y since facing +X)
    # arms (held forward if gun)
    ar = size*0.13
    ax = c + size*0.18 if gun else c + size*0.05
    for sideY in (-1, 1):
        ay = c + sideY*size*0.26
        if gun and sideY == 1:
            ay = c + size*0.13
            ax2 = c + size*0.30
        else:
            ax2 = ax
        ellipse(d, (ax2-ar, ay-ar, ax2+ar, ay+ar), arm_col, OUTLINE, 2)
    # gun barrel
    if gun:
        rrect(d, (c+size*0.22, c-size*0.055, c+size*0.52, c+size*0.055), size*0.03, (52,54,66,255), OUTLINE, 2)
    # torso
    ellipse(d, (c-bw/2, c-bh/2, c+bw/2, c+bh/2), body_col, OUTLINE, 3)
    # jacket highlight wedge (pointing forward)
    poly(d, [(c-bw*0.1, c-bh*0.30), (c+bw*0.42, c), (c-bw*0.1, c+bh*0.30)], body_hi)
    # head
    hr = size*0.20
    ellipse(d, (c-hr+size*0.04, c-hr, c+hr+size*0.04, c+hr), head_col, OUTLINE, 3)
    if hair:
        ellipse(d, (c-hr+size*0.01, c-hr+size*0.01, c+hr-size*0.02+size*0.04, c+hr-size*0.01), hair)
        ellipse(d, (c-hr+size*0.10, c-hr+size*0.06, c+hr+size*0.06, c+hr-size*0.06), head_col)
    if cap:
        ellipse(d, (c-hr, c-hr-size*0.01, c+hr+size*0.05, c+hr+size*0.01), cap, OUTLINE, 2)
        rrect(d, (c+hr-size*0.02, c-size*0.10, c+hr+size*0.13, c+size*0.10), size*0.02, cap, OUTLINE, 2)
    save(img, name, w, h)

character("player.png", 64, (46,110,196,255), (92,160,235,255), (240,200,168,255), (46,110,196,255), gun=True, hair=(88,52,32,255))
character("survivor.png", 64, (240,244,248,255), (255,255,255,255), (232,190,158,255), (240,244,248,255), gun=False, hair=(30,30,36,255))
character("zombie_walker.png", 64, (96,168,92,255), (128,196,120,255), (150,208,140,255), (96,168,92,255))
character("zombie_runner.png", 56, (168,196,84,255), (198,222,116,255), (196,222,150,255), (168,196,84,255))
character("zombie_heavy.png", 92, (60,120,86,255), (86,150,110,255), (120,180,140,255), (60,120,86,255))
character("boss.png", 150, (96,66,140,255), (130,96,178,255), (150,190,150,255), (96,66,140,255), cap=(40,36,60,255))

# ---------- portraits ----------
def portrait(name, skin, hair, hair_style, shirt, extra=None):
    wdt = hgt = 128
    img = canvas(wdt, hgt); d = ImageDraw.Draw(img)
    rrect(d, (4,4,124,124), 18, (36,40,58,255), OUTLINE, 3)
    # shoulders
    ellipse(d, (18,86,110,150), shirt, OUTLINE, 3)
    # head
    ellipse(d, (38,24,90,84), skin, OUTLINE, 3)
    # hair
    if hair_style == "short":
        d.chord([s(36),s(20),s(92),s(64)], 180, 360, fill=hair)
    elif hair_style == "long":
        d.chord([s(34),s(18),s(94),s(66)], 180, 360, fill=hair)
        rrect(d, (34,40,44,86), 4, hair)
        rrect(d, (84,40,94,86), 4, hair)
    elif hair_style == "cap":
        d.chord([s(34),s(16),s(94),s(62)], 180, 360, fill=hair)
        rrect(d, (32,36,96,44), 3, hair)
    # eyes
    for ex in (52, 76):
        ellipse(d, (ex-3, 50, ex+3, 58), (30,30,40,255))
    # mouth
    rrect(d, (58,68,72,72), 2, (150,90,80,255))
    if extra == "glasses":
        for ex in (52, 76):
            d.ellipse([s(ex-8),s(46),s(ex+8),s(62)], outline=(20,20,30,255), width=s(2))
        d.line([s(60),s(53),s(68),s(53)], fill=(20,20,30,255), width=s(2))
    if extra == "beard":
        d.chord([s(42),s(52),s(86),s(88)], 0, 180, fill=hair)
        rrect(d, (56,64,74,74), 3, skin)
    save(img, name, wdt, hgt)

portrait("port_mara.png", (240,200,168,255), (88,52,32,255), "long", (46,110,196,255))
portrait("port_redd.png", (222,178,140,255), (120,120,128,255), "cap", (110,58,44,255), extra="beard")
portrait("port_iris.png", (232,190,158,255), (30,30,36,255), "short", (240,244,248,255), extra="glasses")
# radio portrait: speaker grille
img = canvas(128,128); d = ImageDraw.Draw(img)
rrect(d, (4,4,124,124), 18, (36,40,58,255), OUTLINE, 3)
rrect(d, (24,30,104,98), 10, (60,64,84,255), OUTLINE, 3)
for i in range(5):
    rrect(d, (34, 40+i*11, 94, 44+i*11), 2, (30,32,44,255))
ellipse(d, (88,14,100,26), (255,90,80,255), OUTLINE, 2)
save(img, "port_radio.png", 128, 128)

# ---------- tiles / environment ----------
rng = random.Random(7)
def tile(name, base, speck, w=128, h=128, cracks=False, lines=None):
    img = Image.new("RGBA", (w,h), base)
    d = ImageDraw.Draw(img)
    for _ in range(90):
        x, y = rng.randrange(w), rng.randrange(h)
        r = rng.randrange(1,3)
        col = tuple(min(255, max(0, base[i]+rng.randrange(-speck, speck))) for i in range(3))+(255,)
        d.ellipse([x-r,y-r,x+r,y+r], fill=col)
    if lines:
        for ly in lines:
            d.line([(0,ly),(w,ly)], fill=tuple(max(0,c-14) for c in base[:3])+(255,), width=2)
    if cracks:
        for _ in range(3):
            x, y = rng.randrange(w), rng.randrange(h)
            for _ in range(6):
                nx, ny = x+rng.randrange(-14,14), y+rng.randrange(-14,14)
                d.line([(x,y),(nx,ny)], fill=tuple(max(0,c-20) for c in base[:3])+(255,), width=1)
                x, y = nx, ny
    img.save(os.path.join(OUT, name)); print("wrote", name)

tile("floor.png", (94,98,112,255), 10, cracks=True)
tile("platform.png", (128,124,116,255), 8, lines=[0, 64])
tile("grass.png", (74,120,66,255), 14)
tile("wall.png", (70,62,74,255), 8, w=64, h=64, lines=[0,16,32,48])

# rail segment (horizontal, 128x64)
img = Image.new("RGBA",(128,64),(0,0,0,0)); d = ImageDraw.Draw(img)
for i in range(4):
    d.rectangle([i*32+6, 4, i*32+22, 60], fill=(96,72,52,255), outline=(50,38,28,255), width=2)
for ry in (12, 44):
    d.rectangle([0, ry, 128, ry+7], fill=(150,155,168,255), outline=(70,72,84,255), width=2)
img.save(os.path.join(OUT,"rail.png")); print("wrote rail.png")

def simple(name, wdt, hgt, fn):
    img = canvas(wdt, hgt); d = ImageDraw.Draw(img)
    fn(d)
    save(img, name, wdt, hgt)

# crate
def _crate(d):
    rrect(d, (3,3,53,53), 6, (176,128,72,255), OUTLINE, 3)
    rrect(d, (8,8,48,48), 3, (196,148,88,255))
    poly(d, [(8,8),(14,8),(48,42),(48,48),(42,48),(8,14)], (160,116,62,255))
    poly(d, [(48,8),(48,14),(14,48),(8,48),(8,42),(42,8)], (160,116,62,255))
simple("crate.png", 56, 56, _crate)

def _bench(d):
    rrect(d, (2,2,94,30), 6, (110,78,50,255), OUTLINE, 3)
    for x in (10, 46, 82):
        rrect(d, (x, 8, x+8, 24), 2, (140,102,66,255))
simple("bench.png", 96, 32, _bench)

def _fuel(d):
    rrect(d, (4,8,36,38), 5, (214,64,58,255), OUTLINE, 3)
    rrect(d, (10,2,26,10), 3, (150,42,40,255), OUTLINE, 2)
    rrect(d, (10,16,30,30), 3, (240,120,110,255))
    rrect(d, (14,19,26,27), 2, (214,64,58,255))
simple("fuel.png", 40, 40, _fuel)

def _medkit(d):
    rrect(d, (3,7,37,35), 6, (245,247,250,255), OUTLINE, 3)
    rrect(d, (14,5,26,11), 2, (200,205,214,255), OUTLINE, 2)
    rrect(d, (17,14,23,30), 2, (46,180,110,255))
    rrect(d, (12,19,28,25), 2, (46,180,110,255))
simple("medkit.png", 40, 40, _medkit)

def _coin(d):
    ellipse(d, (2,2,22,22), (255,204,74,255), (170,120,20,255), 2)
    ellipse(d, (6,6,18,18), (255,228,140,255))
simple("coin.png", 24, 24, _coin)

def _ammo(d):
    rrect(d, (2,8,30,28), 4, (86,120,74,255), OUTLINE, 2)
    for x in (8, 14, 20):
        rrect(d, (x, 2, x+5, 14), 2, (230,190,90,255), OUTLINE, 1)
simple("ammo.png", 32, 32, _ammo)

def _bullet(d):
    rrect(d, (0,0,16,6), 3, (255,235,150,255))
    rrect(d, (8,1,16,5), 2, (255,255,220,255))
simple("bullet.png", 16, 6, _bullet)

def _cage(d):
    rrect(d, (2,2,94,94), 6, (70,74,88,255), OUTLINE, 3)
    rrect(d, (10,10,86,86), 3, (40,42,54,255))
    for x in range(18, 90, 14):
        rrect(d, (x, 8, x+5, 88), 2, (110,116,134,255), OUTLINE, 1)
simple("cage.png", 96, 96, _cage)

# armored train (top-down, horizontal, 520x150)
img = canvas(520,150); d = ImageDraw.Draw(img)
rrect(d, (6,20,514,130), 18, (70,84,104,255), OUTLINE, 4)
for seg in range(4):
    x0 = 14+seg*126
    rrect(d, (x0,28,x0+118,122), 10, (92,108,132,255), OUTLINE, 3)
    rrect(d, (x0+12,40,x0+106,66), 5, (120,140,168,255))
    for rx in range(x0+16, x0+104, 24):
        ellipse(d, (rx,96,rx+10,106), (60,66,84,255))
# engine nose
poly(d, [(514,36),(519,55),(519,95),(514,114)], (60,72,92,255))
rrect(d, (470,44,506,106), 8, (255,214,120,255), OUTLINE, 3)  # headlight block
save(img, "train.png", 520, 150)

# ---------- fx ----------
def radial(name, size, inner, outer, power=2.0):
    img = Image.new("RGBA",(size,size),(0,0,0,0))
    px = img.load()
    c = size/2
    for y in range(size):
        for x in range(size):
            dd = math.hypot(x-c, y-c)/c
            t = min(1.0, dd)**power
            col = tuple(int(inner[i]+(outer[i]-inner[i])*t) for i in range(4))
            px[x,y] = col
    img.save(os.path.join(OUT,name)); print("wrote", name)

radial("glow.png", 128, (255,255,255,235), (255,255,255,0), 1.4)
radial("softdot.png", 64, (255,255,255,180), (255,255,255,0), 1.2)
radial("shadow.png", 64, (0,0,0,110), (0,0,0,0), 1.6)
radial("vignette_hole.png", 256, (0,0,0,0), (10,10,18,215), 2.4)

def _spark(d):
    poly(d, [(8,0),(10,6),(16,8),(10,10),(8,16),(6,10),(0,8),(6,6)], (255,240,180,255))
simple("spark.png", 16, 16, _spark)

def _goo(d):
    for (x,y,r) in [(24,26,16),(12,20,8),(38,18,7),(34,36,8),(14,34,6)]:
        ellipse(d, (x-r,y-r,x+r,y+r), (110,190,90,220))
simple("goo.png", 48, 48, _goo)

# joystick
img = canvas(160,160); d = ImageDraw.Draw(img)
d.ellipse([s(6),s(6),s(154),s(154)], outline=(255,255,255,120), width=s(6))
d.ellipse([s(22),s(22),s(138),s(138)], outline=(255,255,255,50), width=s(3))
save(img, "joy_base.png", 160, 160)
img = canvas(80,80); d = ImageDraw.Draw(img)
ellipse(d, (6,6,74,74), (255,255,255,150), (255,255,255,200), 4)
save(img, "joy_knob.png", 80, 80)

def _arrow(d):
    poly(d, [(48,24),(20,6),(28,24),(20,42)], (255,220,90,255))
simple("arrow.png", 48, 48, _arrow)

def _lamp(d):
    ellipse(d, (8,8,40,40), (255,230,160,255), OUTLINE, 3)
    ellipse(d, (16,16,32,32), (255,250,220,255))
simple("lamp.png", 48, 48, _lamp)

def _barrel(d):
    ellipse(d, (3,3,45,45), (150,80,50,255), OUTLINE, 3)
    ellipse(d, (10,10,38,38), (180,100,60,255))
    ellipse(d, (18,18,30,30), (120,64,40,255))
simple("barrel.png", 48, 48, _barrel)

# muzzle flash
def _muzzle(d):
    poly(d, [(0,10),(22,2),(16,10),(30,10),(16,10),(22,18)], (255,240,170,255))
    poly(d, [(0,6),(20,10),(0,14)], (255,255,230,255))
simple("muzzle.png", 32, 20, _muzzle)

# app icon 512
img = canvas(512,512); d = ImageDraw.Draw(img)
rrect(d, (16,16,496,496), 96, (28,32,52,255))
# rails
for ry in (400, 440):
    d.rectangle([s(40),s(ry),s(472),s(ry+14)], fill=(120,126,142,255))
for rx in range(56, 470, 64):
    d.rectangle([s(rx),s(390),s(rx+28),s(462)], fill=(96,72,52,255))
# train nose
rrect(d, (96,140,416,392), 40, (92,108,132,255), OUTLINE, 8)
rrect(d, (136,180,376,260), 20, (255,214,120,255), OUTLINE, 6)
rrect(d, (136,290,376,352), 16, (60,66,84,255))
# zombie hand
ellipse(d, (350,330,470,450), (96,168,92,255), OUTLINE, 8)
for i,(fx,fy) in enumerate([(360,318),(392,306),(424,310),(452,330)]):
    rrect(d, (fx,fy,fx+26,fy+70), 12, (96,168,92,255), OUTLINE, 6)
save(img, "icon_full.png", 512, 512)
print("ALL TEXTURES DONE")
