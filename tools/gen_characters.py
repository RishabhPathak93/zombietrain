#!/usr/bin/env python3
"""Humanoid top-down character sprites (v2 art pass) + ch3/ch4 props.
All characters face +X (right). Layer order: feet, back arm, torso,
front arm, weapon/prop, head, headgear."""
import math, os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
SS = 4
OL = (24, 22, 34, 255)

def canvas(px):
    return Image.new("RGBA", (px * SS, px * SS), (0, 0, 0, 0))

def save(img, name, px):
    img.resize((px, px), Image.LANCZOS).save(os.path.join(OUT, name))
    print("wrote", name)

class Pen:
    def __init__(self, img):
        self.d = ImageDraw.Draw(img)
    def ell(self, cx, cy, rx, ry, fill, outline=None, ow=2.5):
        b = [ (cx-rx)*SS, (cy-ry)*SS, (cx+rx)*SS, (cy+ry)*SS ]
        if outline:
            self.d.ellipse(b, fill=outline)
            o = ow*SS
            self.d.ellipse([b[0]+o, b[1]+o, b[2]-o, b[3]-o], fill=fill)
        else:
            self.d.ellipse(b, fill=fill)
    def capsule(self, x1, y1, x2, y2, r, fill, outline=None, ow=2):
        if outline:
            self.d.line([(x1*SS, y1*SS), (x2*SS, y2*SS)], fill=outline, width=int(2*(r+ow)*SS))
            for (x, y) in ((x1, y1), (x2, y2)):
                self.d.ellipse([(x-r-ow)*SS, (y-r-ow)*SS, (x+r+ow)*SS, (y+r+ow)*SS], fill=outline)
        self.d.line([(x1*SS, y1*SS), (x2*SS, y2*SS)], fill=fill, width=int(2*r*SS))
        for (x, y) in ((x1, y1), (x2, y2)):
            self.d.ellipse([(x-r)*SS, (y-r)*SS, (x+r)*SS, (y+r)*SS], fill=fill)
    def poly(self, pts, fill, outline=None, ow=2):
        p = [(x*SS, y*SS) for x, y in pts]
        if outline:
            self.d.polygon(p, fill=outline)
        self.d.polygon(p, fill=fill)
    def rect(self, x, y, w, h, r, fill, outline=None, ow=2):
        b = [x*SS, y*SS, (x+w)*SS, (y+h)*SS]
        if outline:
            self.d.rounded_rectangle(b, radius=r*SS, fill=outline)
            o = ow*SS
            self.d.rounded_rectangle([b[0]+o, b[1]+o, b[2]-o, b[3]-o], radius=max(1, (r-ow)*SS), fill=fill)
        else:
            self.d.rounded_rectangle(b, radius=r*SS, fill=fill)
    def line(self, x1, y1, x2, y2, w, fill):
        self.d.line([(x1*SS, y1*SS), (x2*SS, y2*SS)], fill=fill, width=int(w*SS))

def torso(p, c, w, h, base, hi, lo, outline=OL, tail=0.0):
    """Shaded torso ellipse. tail>0 extends coat behind (left)."""
    if tail > 0:
        p.ell(c - tail, c, w*0.75, h*0.42, lo, outline, 2.5)
    p.ell(c, c, w/2, h/2, base, outline, 3)
    # lower-left shade crescent
    p.ell(c - w*0.10, c + h*0.10, w*0.34, h*0.30, lo)
    # top-right highlight
    p.ell(c + w*0.10, c - h*0.12, w*0.26, h*0.22, hi)

def head(p, c, hr, skin, hair=None, fringe=True, bald_patch=None):
    hx = c + 3
    p.ell(hx, c, hr, hr, skin, OL, 2.5)
    if hair:
        p.ell(hx - hr*0.18, c, hr*0.92, hr*0.92, hair)
        if fringe:
            p.ell(hx + hr*0.34, c, hr*0.5, hr*0.62, skin)
    if bald_patch:
        p.ell(hx - hr*0.1, c - hr*0.2, hr*0.4, hr*0.3, bald_patch)
    return hx

# ------------------------------------------------------------------ player
def make_player():
    px = 64; img = canvas(px); p = Pen(img); c = px/2
    skin = (238, 198, 166, 255); jacket = (44, 108, 194, 255)
    jhi = (92, 158, 232, 255); jlo = (32, 82, 152, 255)
    # back arm (left shoulder) reaching to rifle grip
    p.capsule(c+2, c-11, c+15, c-4, 3.4, jacket, OL)
    torso(p, c, 40, 30, jacket, jhi, jlo)
    # backpack strap + pack
    p.rect(c-16, c-8, 7, 16, 2, (86, 62, 40, 255), OL)
    p.line(c-6, c-13, c-2, c+13, 2.2, (30, 70, 130, 255))
    # rifle
    p.rect(c+8, c-3.2, 22, 6.4, 2, (54, 56, 70, 255), OL)
    p.rect(c+26, c-2, 8, 4, 1.5, (34, 36, 48, 255))
    p.rect(c+10, c+2, 6, 5, 1.5, (90, 66, 44, 255))  # grip
    # front arm to fore-grip
    p.capsule(c+2, c+11, c+18, c+4, 3.4, jacket, OL)
    p.ell(c+18, c+4, 3.2, 3.2, skin, OL, 1.5)   # front hand
    p.ell(c+15, c-4, 3.0, 3.0, skin, OL, 1.5)   # back hand
    hx = head(p, c, 8.5, skin, hair=(96, 58, 34, 255))
    p.ell(hx - 2, c, 2.6, 4.8, (120, 76, 46, 255))  # ponytail knot
    save(img, "player.png", px)

# ------------------------------------------------------------------ survivor
def make_survivor():
    px = 64; img = canvas(px); p = Pen(img); c = px/2
    skin = (232, 190, 158, 255); coat = (240, 243, 248, 255)
    chi = (255, 255, 255, 255); clo = (198, 204, 216, 255)
    p.capsule(c+2, c-11, c+13, c-6, 3.2, coat, OL)
    torso(p, c, 38, 29, coat, chi, clo)
    p.line(c-4, c-12, c-4, c+12, 1.6, (170, 178, 194, 255))  # coat seam
    # satchel
    p.rect(c-4, c+8, 10, 8, 2, (122, 88, 56, 255), OL)
    p.capsule(c+2, c+11, c+14, c+6, 3.2, coat, OL)
    p.ell(c+14, c+6, 3, 3, skin, OL, 1.5)
    p.ell(c+13, c-6, 3, 3, skin, OL, 1.5)
    head(p, c, 8.2, skin, hair=(32, 32, 40, 255))
    save(img, "survivor.png", px)

# ------------------------------------------------------------------ zombies
def zombie(name, px, skin, shirt, shi, slo, lean=0.0, bulk=1.0, arms="both"):
    img = canvas(px); p = Pen(img); c = px/2
    wound = tuple(max(0, v-46) for v in skin[:3]) + (255,)
    aw = 3.4 * bulk * px / 64
    reach = px * 0.42
    # arms outstretched forward — instant zombie silhouette
    if arms in ("both", "sprint"):
        back_dy = -px*0.17
        fwd = (c + reach, c + back_dy*0.35)
        if arms == "sprint":
            p.capsule(c, c - px*0.16, c - px*0.30, c - px*0.05, aw, shirt, OL)  # back arm trails
        else:
            p.capsule(c, c - px*0.16, c + reach, c - px*0.10, aw, skin, OL)
            p.ell(c + reach, c - px*0.10, aw+1, aw+1, skin, OL, 1.5)
    torso(p, c, px*0.60*bulk, px*0.47*bulk, shirt, shi, slo)
    # tattered shirt edge
    for i in range(4):
        ang = -0.7 + i*0.45
        ex = c + math.cos(ang) * px*0.28*bulk
        ey = c + math.sin(ang) * px*0.22*bulk
        p.ell(ex, ey, 2.6, 2.6, slo)
    # wound patches
    p.ell(c - px*0.08, c + px*0.10, px*0.06, px*0.045, wound)
    # front arm
    p.capsule(c, c + px*0.16, c + reach, c + px*0.08, aw, skin, OL)
    p.ell(c + reach, c + px*0.08, aw+1.2, aw+1.2, skin, OL, 1.5)
    hx = head(p, c, px*0.14, skin, hair=None, bald_patch=wound)
    # milky eyes visible from above-front
    for dy in (-1, 1):
        p.ell(hx + px*0.10, c + dy*px*0.05, 1.6, 1.6, (235, 240, 210, 255))
    if lean:
        img = img.transform(img.size, Image.AFFINE, (1, -lean, lean*img.size[1]*0.5, 0, 1, 0), resample=Image.BICUBIC)
    save(img, name, px)

# ------------------------------------------------------------------ bosses
def boss_conductor():
    px = 150; img = canvas(px); p = Pen(img); c = px/2
    skin = (150, 196, 150, 255); coat = (58, 46, 88, 255)
    chi = (92, 76, 132, 255); clo = (40, 32, 62, 255)
    aw = 7
    p.capsule(c, c-24, c+56, c-14, aw, coat, OL)
    p.ell(c+56, c-14, 9, 9, skin, OL, 2)   # claw back
    torso(p, c, 92, 70, coat, chi, clo, tail=18)
    # brass buttons + chain
    for i in range(4):
        p.ell(c-8+i*8, c-2+i*3, 2.2, 2.2, (222, 186, 90, 255))
    p.line(c-20, c-10, c+6, c+16, 2.2, (200, 170, 90, 255))
    p.capsule(c, c+24, c+58, c+12, aw, coat, OL)
    p.ell(c+58, c+12, 9.5, 9.5, skin, OL, 2)
    for dy in (-1, 1):  # claw fingers
        p.ell(c+64, c+12+dy*4, 3, 3, skin)
        p.ell(c+62, c-14+dy*4, 2.8, 2.8, skin)
    hx = head(p, c, 15, skin)
    # station-master cap
    p.ell(hx-2, c, 15.5, 15.5, (34, 30, 52, 255), OL, 2.5)
    p.ell(hx-2, c, 11, 11, (46, 40, 70, 255))
    p.rect(hx+10, c-6, 8, 12, 2, (34, 30, 52, 255), OL)  # brim
    p.line(hx-13, c-8, hx-13, c+8, 2.4, (196, 60, 60, 255))  # red band
    # glowing eyes
    for dy in (-1, 1):
        p.ell(hx+11, c+dy*6, 2.4, 2.4, (255, 220, 90, 255))
    save(img, "boss.png", px)

def boss_broadcaster():
    px = 150; img = canvas(px); p = Pen(img); c = px/2
    skin = (170, 190, 160, 255); coat = (140, 40, 58, 255)
    chi = (186, 78, 92, 255); clo = (104, 28, 44, 255)
    aw = 7
    p.capsule(c, c-24, c+54, c-14, aw, coat, OL)
    torso(p, c, 92, 70, coat, chi, clo, tail=14)
    # cable harness arcs
    for k in (-1, 1):
        p.line(c-18, c+k*14, c+16, c-k*6, 2.4, (60, 62, 78, 255))
    p.ell(c-2, c+2, 6, 6, (40, 40, 54, 255), OL, 1.5)
    p.ell(c-2, c+2, 2.6, 2.6, (255, 70, 60, 255))  # chest beacon
    p.capsule(c, c+24, c+56, c+12, aw, coat, OL)
    p.ell(c+56, c+12, 9.5, 9.5, skin, OL, 2)
    p.ell(c+54, c-14, 9, 9, skin, OL, 2)
    hx = head(p, c, 15, skin)
    # antenna crown
    for i, ang in enumerate((-0.9, 0.0, 0.9)):
        x2 = hx - 6 + math.cos(ang+math.pi)*22
        y2 = c + math.sin(ang)*20
        p.line(hx-4, c, x2, y2, 2.2, (196, 202, 220, 255))
        p.ell(x2, y2, 3, 3, (255, 70, 60, 255), OL, 1)
    for dy in (-1, 1):
        p.ell(hx+11, c+dy*6, 2.4, 2.4, (255, 90, 70, 255))
    save(img, "boss2.png", px)

def boss_passenger():
    px = 140; img = canvas(px); p = Pen(img); c = px/2
    skin = (176, 186, 168, 255); suit = (32, 34, 46, 255)
    shi = (58, 62, 82, 255); slo = (20, 22, 32, 255)
    aw = 6
    p.capsule(c, c-22, c+50, c-13, aw, suit, OL)
    p.ell(c+50, c-13, 8, 8, skin, OL, 2)
    torso(p, c, 82, 62, suit, shi, slo)
    # white shirt wedge + red tie
    p.poly([(c+4, c-9), (c+30, c), (c+4, c+9)], (236, 238, 244, 255))
    p.line(c+6, c, c+26, c, 3.4, (188, 52, 52, 255))
    # briefcase arm (the beacon)
    p.capsule(c, c+22, c+44, c+18, aw, suit, OL)
    p.rect(c+40, c+10, 20, 15, 3, (74, 52, 34, 255), OL)
    p.line(c+43, c+17.5, c+57, c+17.5, 1.8, (120, 90, 60, 255))
    p.ell(c+50, c+17.5, 4.2, 4.2, (90, 230, 210, 255))  # glowing seal
    hx = head(p, c, 13.5, skin)
    # fedora
    p.ell(hx-2, c, 15, 15, (24, 24, 34, 255), OL, 2)
    p.ell(hx-2, c, 9.5, 9.5, (38, 38, 52, 255))
    p.line(hx-2-9, c-4, hx-2-9, c+4, 2, (150, 40, 40, 255))
    for dy in (-1, 1):
        p.ell(hx+10, c+dy*5, 2.2, 2.2, (90, 230, 210, 255))
    save(img, "boss3.png", px)

def boss_foreman():
    px = 160; img = canvas(px); p = Pen(img); c = px/2
    skin = (110, 160, 108, 255); vest = (196, 110, 40, 255)
    vhi = (232, 148, 66, 255); vlo = (150, 80, 28, 255)
    aw = 9
    # wrench held two-handed across the front
    p.capsule(c, c-28, c+52, c-16, aw, skin, OL)
    torso(p, c, 108, 84, vest, vhi, vlo)
    # hi-vis stripes
    for dy in (-10, 8):
        p.line(c-26, c+dy, c+26, c+dy, 3.4, (240, 220, 90, 255))
    p.capsule(c, c+28, c+54, c+16, aw, skin, OL)
    # giant pipe wrench
    p.line(c+50, c-22, c+62, c+26, 5, (88, 92, 108, 255))
    p.rect(c+54, c-34, 16, 15, 3, (88, 92, 108, 255), OL)
    p.rect(c+58, c-30, 14, 7, 2, (60, 62, 76, 255))
    p.ell(c+52, c-16, 10, 10, skin, OL, 2)
    p.ell(c+56, c+18, 10.5, 10.5, skin, OL, 2)
    hx = head(p, c, 13, skin)
    # hardhat
    p.ell(hx-1, c, 14.5, 14.5, (240, 200, 60, 255), OL, 2.5)
    p.ell(hx-1, c, 9, 9, (255, 224, 100, 255))
    p.rect(hx+8, c-5, 8, 10, 2, (240, 200, 60, 255), OL)
    for dy in (-1, 1):
        p.ell(hx+10, c+dy*5.5, 2.4, 2.4, (255, 150, 60, 255))
    save(img, "boss4.png", px)

# ------------------------------------------------------------------ props
def make_props():
    # glowing luggage (ch3 search point)
    px = 52; img = canvas(px); p = Pen(img)
    p.rect(6, 12, 40, 30, 4, (128, 90, 56, 255), OL, 2.5)
    p.rect(6, 12, 40, 8, 4, (104, 72, 44, 255))
    for x in (16, 36):
        p.line(x, 12, x, 42, 2, (84, 58, 36, 255))
    p.rect(21, 6, 10, 8, 2, (104, 72, 44, 255), OL, 2)
    p.line(10, 27, 42, 27, 1.6, (90, 230, 210, 255))  # glowing crack
    save(img, "luggage.png", px)
    # boss projectile orb
    px = 24; img = canvas(px); p = Pen(img)
    p.ell(12, 12, 10, 10, (150, 60, 200, 120))
    p.ell(12, 12, 6.5, 6.5, (210, 120, 255, 255))
    p.ell(12, 12, 3, 3, (250, 230, 255, 255))
    save(img, "orb.png", px)
    # train interior floor
    img = Image.new("RGBA", (128, 128), (58, 58, 70, 255))
    d = ImageDraw.Draw(img)
    for y in (0, 42, 84):
        d.line([(0, y), (128, y)], fill=(44, 44, 56, 255), width=3)
    for x in range(8, 128, 24):
        for y in (20, 62, 104):
            d.ellipse([x-2, y-2, x+2, y+2], fill=(76, 76, 92, 255))
    img.save(os.path.join(OUT, "trainfloor.png")); print("wrote trainfloor.png")
    # train interior wall
    img = Image.new("RGBA", (64, 64), (46, 50, 66, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 63, 63], outline=(32, 34, 46, 255), width=3)
    d.rectangle([8, 14, 56, 34], fill=(70, 90, 120, 255), outline=(32, 34, 46, 255), width=2)  # window
    d.rectangle([10, 16, 30, 24], fill=(96, 120, 155, 255))
    img.save(os.path.join(OUT, "trainwall.png")); print("wrote trainwall.png")
    # shipping container tile (ch4)
    img = Image.new("RGBA", (128, 128), (150, 70, 50, 255))
    d = ImageDraw.Draw(img)
    for x in range(0, 128, 16):
        d.line([(x, 0), (x, 128)], fill=(122, 54, 40, 255), width=5)
    d.rectangle([0, 0, 127, 127], outline=(90, 40, 30, 255), width=4)
    img.save(os.path.join(OUT, "container.png")); print("wrote container.png")

make_player()
make_survivor()
zombie("zombie_walker.png", 64, (110, 176, 106, 255), (94, 112, 88, 255), (120, 140, 112, 255), (70, 86, 66, 255))
zombie("zombie_runner.png", 56, (172, 198, 96, 255), (140, 120, 70, 255), (170, 148, 92, 255), (106, 90, 52, 255), lean=0.13, arms="sprint")
zombie("zombie_heavy.png", 92, (76, 132, 96, 255), (66, 74, 92, 255), (92, 102, 124, 255), (46, 52, 66, 255), bulk=1.18)
boss_conductor()
boss_broadcaster()
boss_passenger()
boss_foreman()
make_props()
print("CHARACTER ART v2 DONE")
