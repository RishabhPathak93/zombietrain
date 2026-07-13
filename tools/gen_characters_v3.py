#!/usr/bin/env python3
"""v3 art pass: upright, front-facing cartoon characters (PvZ-style) for a
3/4 view. Big heads, faces with eyes/mouths, arms and legs. All face RIGHT
(code flips horizontally). Plus 3/4-shaded props and guns."""
import math, os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
SS = 4
OL = (26, 22, 34, 255)

def canvas(w, h): return Image.new("RGBA", (w*SS, h*SS), (0,0,0,0))
def save(img, name, w, h):
    img.resize((w, h), Image.LANCZOS).save(os.path.join(OUT, name)); print("wrote", name)

class P:
    def __init__(s, img): s.d = ImageDraw.Draw(img)
    def ell(s, cx, cy, rx, ry, fill, ol=None, ow=2.2):
        b = [(cx-rx)*SS,(cy-ry)*SS,(cx+rx)*SS,(cy+ry)*SS]
        if ol:
            s.d.ellipse(b, fill=ol)
            o = ow*SS
            s.d.ellipse([b[0]+o,b[1]+o,b[2]-o,b[3]-o], fill=fill)
        else: s.d.ellipse(b, fill=fill)
    def cap(s, x1,y1,x2,y2,r,fill,ol=None,ow=1.8):
        if ol:
            s.d.line([(x1*SS,y1*SS),(x2*SS,y2*SS)], fill=ol, width=int(2*(r+ow)*SS))
            for x,y in ((x1,y1),(x2,y2)): s.d.ellipse([(x-r-ow)*SS,(y-r-ow)*SS,(x+r+ow)*SS,(y+r+ow)*SS], fill=ol)
        s.d.line([(x1*SS,y1*SS),(x2*SS,y2*SS)], fill=fill, width=int(2*r*SS))
        for x,y in ((x1,y1),(x2,y2)): s.d.ellipse([(x-r)*SS,(y-r)*SS,(x+r)*SS,(y+r)*SS], fill=fill)
    def poly(s, pts, fill, ol=None):
        pp = [(x*SS,y*SS) for x,y in pts]
        if ol: s.d.polygon(pp, fill=ol, outline=ol, width=int(2*SS))
        s.d.polygon(pp, fill=fill)
    def rect(s, x,y,w,h,r,fill,ol=None,ow=1.8):
        b=[x*SS,y*SS,(x+w)*SS,(y+h)*SS]
        if ol:
            s.d.rounded_rectangle(b, radius=r*SS, fill=ol)
            o=ow*SS
            s.d.rounded_rectangle([b[0]+o,b[1]+o,b[2]-o,b[3]-o], radius=max(1,(r-ow)*SS), fill=fill)
        else: s.d.rounded_rectangle(b, radius=r*SS, fill=fill)
    def line(s, x1,y1,x2,y2,w,fill): s.d.line([(x1*SS,y1*SS),(x2*SS,y2*SS)], fill=fill, width=int(w*SS))
    def arc(s, box, a0, a1, w, fill):
        s.d.arc([v*SS for v in box], a0, a1, fill=fill, width=int(w*SS))

def legs(p, cx, y, gap, lw, lh, col, boot, stagger=0.0):
    for side, dx in ((-1, -gap), (1, gap)):
        off = stagger*side
        p.cap(cx+dx, y+off, cx+dx, y+lh+off, lw, col, OL)
        p.ell(cx+dx+1, y+lh+off+1, lw+1.6, lw*0.9, boot, OL, 1.6)

def eyes(p, cx, cy, r, look=(0.3,0.1), pupil=(30,28,40,255), white=(250,250,246,255), derpy=False, glow=None):
    for i,(dx) in enumerate((-r*1.15, r*1.15)):
        rr = r*(1.25 if (derpy and i==1) else 1.0)
        if glow:
            p.ell(cx+dx, cy, rr, rr, glow, OL, 1.2)
        else:
            p.ell(cx+dx, cy, rr, rr, white, OL, 1.2)
            p.ell(cx+dx+look[0]*rr, cy+look[1]*rr, rr*0.42, rr*0.42, pupil)

# ================================================================ MARA (player)
def player():
    w,h = 60,84; img = canvas(w,h); p = P(img); cx = w/2
    skin=(240,198,166,255); jkt=(46,110,198,255); jhi=(96,158,235,255); jlo=(30,80,150,255)
    pants=(52,56,72,255); hair=(96,58,34,255)
    legs(p, cx, 62, 6.5, 4.2, 12, pants, (40,38,50,255))
    # torso
    p.rect(cx-13, 36, 26, 30, 9, jkt, OL)
    p.rect(cx-13, 36, 26, 12, 9, jhi)
    p.line(cx, 40, cx, 64, 1.6, jlo)                     # zipper
    p.rect(cx-13, 52, 26, 5, 2, (120,86,52,255), OL,1.4) # belt
    # arms relaxed (gun is a separate sprite in-game)
    p.cap(cx-13, 42, cx-18, 56, 3.6, jkt, OL); p.ell(cx-18, 58, 3.2,3.2, skin, OL,1.2)
    p.cap(cx+13, 42, cx+18, 54, 3.6, jkt, OL); p.ell(cx+18, 56, 3.2,3.2, skin, OL,1.2)
    # head
    p.ell(cx, 22, 15, 14.5, skin, OL, 2.4)
    p.ell(cx-2, 12, 15, 8, hair)                          # hair top
    p.poly([(cx-15,16),(cx-9,10),(cx-6,20),(cx-13,24)], hair)  # side fringe
    p.ell(cx-14, 30, 4, 7, hair, OL, 1.4)                 # ponytail
    eyes(p, cx+3, 22, 3.2, look=(0.35,0.05))
    p.line(cx-2, 16.5, cx+9, 16, 1.6, (70,44,26,255))     # brow
    p.arc((cx-1, 26, cx+9, 32), 10, 150, 1.6, (150,90,70,255))  # smirk
    save(img, "player.png", w, h)

# ================================================================ SURVIVOR (Iris)
def survivor():
    w,h = 58,82; img = canvas(w,h); p = P(img); cx = w/2
    skin=(232,190,158,255); coat=(242,244,250,255); clo=(200,206,220,255); hair=(34,34,44,255)
    legs(p, cx, 60, 6, 4, 12, (70,74,92,255), (44,46,60,255))
    p.rect(cx-13, 34, 26, 30, 8, coat, OL)
    p.line(cx-4, 38, cx-4, 62, 1.4, clo); p.line(cx+4, 38, cx+4, 62, 1.4, clo)
    p.cap(cx-13, 40, cx-17, 56, 3.4, coat, OL); p.ell(cx-17, 58, 3,3, skin, OL,1.2)
    p.cap(cx+13, 40, cx+17, 54, 3.4, coat, OL)
    p.rect(cx+13, 52, 10, 12, 2, (122,88,56,255), OL, 1.6)   # satchel
    p.ell(cx, 20, 14, 14, skin, OL, 2.2)
    p.ell(cx, 11, 13.5, 7, hair); p.ell(cx-11, 18, 4, 9, hair)
    eyes(p, cx+3, 20, 3, look=(0.3,0.0))
    for dx in (-1.5, 7.5):  # glasses
        p.d.ellipse([(cx+dx-3.6)*SS,(20-3.6)*SS,(cx+dx+3.6)*SS,(20+3.6)*SS], outline=(30,30,40,255), width=int(1.4*SS))
    p.line(cx+2, 20, cx+4, 20, 1.2, (30,30,40,255))
    p.arc((cx, 25, cx+8, 30), 20, 160, 1.4, (160,100,80,255))
    save(img, "survivor.png", w, h)

# ================================================================ ZOMBIES
def zombie_base(name, w, h, skin, shirt, shi, pants, derpy=True, bulk=1.0, lean=0.0, jaw=True):
    img = canvas(w,h); p = P(img); cx = w/2
    slo = tuple(max(0,c-40) for c in shirt[:3])+(255,)
    hw = 16*bulk
    legs(p, cx, h*0.73, 6.5*bulk, 4*bulk, h*0.14, pants, (40,40,48,255), stagger=2.0)
    # torso (hunched forward)
    p.rect(cx-13*bulk, h*0.42, 26*bulk, h*0.34, 8, shirt, OL)
    p.rect(cx-13*bulk, h*0.42, 26*bulk, h*0.12, 8, shi)
    # torn hem
    for i in range(4):
        p.poly([(cx-11*bulk+i*6*bulk, h*0.74),(cx-8*bulk+i*6*bulk, h*0.70),(cx-5*bulk+i*6*bulk, h*0.74)], slo)
    p.ell(cx-4*bulk, h*0.62, 4*bulk, 3*bulk, slo)   # stain
    # both arms stretched forward-right (classic shamble)
    p.cap(cx+10*bulk, h*0.47, cx+24*bulk, h*0.44, 3.6*bulk, skin, OL)
    p.ell(cx+25*bulk, h*0.44, 4*bulk, 4*bulk, skin, OL, 1.4)
    p.cap(cx+8*bulk, h*0.56, cx+23*bulk, h*0.58, 3.6*bulk, skin, OL)
    p.ell(cx+24*bulk, h*0.58, 4*bulk, 4*bulk, skin, OL, 1.4)
    # head — big, tilted, goofy
    hy = h*0.245
    p.ell(cx, hy, hw, hw*0.95, skin, OL, 2.4)
    p.ell(cx-hw*0.35, hy-hw*0.55, hw*0.5, hw*0.3, tuple(max(0,c-30) for c in skin[:3])+(255,))  # scalp patch
    eyes(p, cx+3, hy-1, 3.4*bulk, derpy=derpy, look=(0.4,0.2))
    if jaw:
        p.ell(cx+4, hy+hw*0.52, hw*0.55, hw*0.32, skin, OL, 1.8)  # hanging jaw
        for i in range(3):
            p.rect(cx-2+i*4, hy+hw*0.34, 2.4, 3.4, 0.8, (245,245,235,255))
    save(img, name, w, h)

# ================================================================ BOSSES
def boss_frame(w, h):
    img = canvas(w,h); return img, P(img), w/2

def conductor():
    w,h = 120,150; img,p,cx = boss_frame(w,h)
    skin=(150,196,150,255); coat=(56,44,86,255); chi=(90,74,130,255)
    legs(p, cx, h*0.72, 12, 6.5, h*0.15, (36,30,54,255), (26,22,40,255))
    # long coat
    p.poly([(cx-26,h*0.40),(cx+26,h*0.40),(cx+32,h*0.78),(cx-32,h*0.78)], coat, OL)
    p.poly([(cx-24,h*0.40),(cx+24,h*0.40),(cx+25,h*0.52),(cx-25,h*0.52)], chi)
    for i in range(4): p.ell(cx-6+i*5, h*0.47+i*4, 2.2, 2.2, (224,188,92,255))
    p.line(cx-16, h*0.50, cx+12, h*0.62, 2, (200,170,90,255))  # watch chain
    # arms forward with claws
    p.cap(cx+20, h*0.45, cx+42, h*0.42, 6, coat, OL); p.ell(cx+44, h*0.42, 6.5, 6.5, skin, OL, 1.8)
    p.cap(cx+18, h*0.55, cx+40, h*0.58, 6, coat, OL); p.ell(cx+42, h*0.58, 7, 7, skin, OL, 1.8)
    # head + underbite jaw
    hy = h*0.275
    p.ell(cx, hy, 20, 19, skin, OL, 2.6)
    p.ell(cx+5, hy+12, 13, 7, skin, OL, 2)
    for i in range(4): p.rect(cx-1+i*5, hy+6.5, 3, 4.5, 1, (245,245,235,255))
    eyes(p, cx+4, hy-3, 4.2, glow=(255,220,90,255))
    # station-master cap
    p.rect(cx-17, hy-19, 34, 10, 4, (34,30,52,255), OL)
    p.rect(cx-19, hy-11, 38, 4.5, 2, (34,30,52,255), OL, 1.4)
    p.line(cx-15, hy-13, cx+15, hy-13, 2.4, (196,60,60,255))
    p.ell(cx, hy-15, 2.6, 2.6, (224,188,92,255))
    save(img, "boss.png", w, h)

def broadcaster():
    w,h = 120,150; img,p,cx = boss_frame(w,h)
    skin=(170,190,160,255); coat=(146,42,60,255); chi=(190,82,96,255)
    legs(p, cx, h*0.72, 12, 6.5, h*0.15, (70,26,38,255), (40,18,26,255))
    p.poly([(cx-26,h*0.40),(cx+26,h*0.40),(cx+31,h*0.78),(cx-31,h*0.78)], coat, OL)
    p.poly([(cx-24,h*0.40),(cx+24,h*0.40),(cx+25,h*0.52),(cx-25,h*0.52)], chi)
    for k in (-1,1): p.line(cx-14, h*0.50+k*7, cx+14, h*0.58-k*4, 2.2, (60,62,78,255))
    p.ell(cx, h*0.55, 6, 6, (40,40,54,255), OL, 1.6); p.ell(cx, h*0.55, 2.6, 2.6, (255,70,60,255))
    p.cap(cx+20, h*0.45, cx+42, h*0.43, 6, coat, OL); p.ell(cx+44, h*0.43, 6.5,6.5, skin, OL,1.8)
    p.cap(cx+18, h*0.56, cx+40, h*0.58, 6, coat, OL); p.ell(cx+42, h*0.58, 7,7, skin, OL,1.8)
    hy = h*0.265
    p.ell(cx, hy, 19, 18, skin, OL, 2.6)
    eyes(p, cx+4, hy-1, 4.2, glow=(255,90,70,255))
    p.arc((cx-6, hy+7, cx+14, hy+15), 200, 340, 2, (90,50,50,255))
    for ang in (-0.85, 0.0, 0.85):  # antenna crown
        x2 = cx + math.sin(ang)*16; y2 = hy-18 - math.cos(ang)*14
        p.line(cx, hy-14, x2, y2, 2, (200,206,222,255))
        p.ell(x2, y2, 2.8, 2.8, (255,70,60,255), OL, 1)
    save(img, "boss2.png", w, h)

def passenger():
    w,h = 112,144; img,p,cx = boss_frame(w,h)
    skin=(178,188,170,255); suit=(34,36,48,255); shi=(60,64,84,255)
    legs(p, cx, h*0.72, 11, 6, h*0.15, suit, (22,22,32,255))
    p.poly([(cx-24,h*0.38),(cx+24,h*0.38),(cx+28,h*0.76),(cx-28,h*0.76)], suit, OL)
    p.poly([(cx-8,h*0.40),(cx+8,h*0.40),(cx+3,h*0.62),(cx-3,h*0.62)], (238,240,246,255))  # shirt
    p.poly([(cx-2.5,h*0.42),(cx+2.5,h*0.42),(cx+1,h*0.60),(cx-1,h*0.60)], (190,52,52,255))  # tie
    p.poly([(cx-24,h*0.38),(cx-6,h*0.38),(cx-10,h*0.50)], shi)  # lapels
    p.poly([(cx+24,h*0.38),(cx+6,h*0.38),(cx+10,h*0.50)], shi)
    # briefcase arm + case
    p.cap(cx+18, h*0.46, cx+36, h*0.60, 5.5, suit, OL)
    p.rect(cx+28, h*0.60, 22, 16, 3, (76,54,36,255), OL)
    p.line(cx+31, h*0.68, cx+47, h*0.68, 1.6, (120,90,60,255))
    p.ell(cx+39, h*0.68, 4, 4, (90,230,210,255))
    p.cap(cx+16, h*0.56, cx+34, h*0.52, 5.5, suit, OL); p.ell(cx+36, h*0.52, 6,6, skin, OL,1.6)
    hy = h*0.26
    p.ell(cx, hy, 18, 17, skin, OL, 2.4)
    eyes(p, cx+4, hy, 3.8, glow=(90,230,210,255))
    p.line(cx-2, hy+9, cx+10, hy+9, 1.8, (90,60,60,255))  # grim mouth
    # fedora
    p.rect(cx-15, hy-17, 30, 9, 4, (24,24,34,255), OL)
    p.rect(cx-20, hy-9.5, 40, 4.5, 2.2, (24,24,34,255), OL, 1.4)
    p.line(cx-13, hy-11, cx+13, hy-11, 2.2, (150,40,40,255))
    save(img, "boss3.png", w, h)

def foreman():
    w,h = 136,156; img,p,cx = boss_frame(w,h)
    skin=(112,162,110,255); vest=(210,120,44,255); vhi=(238,152,70,255)
    legs(p, cx, h*0.72, 14, 7.5, h*0.15, (60,56,66,255), (36,34,42,255))
    p.rect(cx-27, h*0.38, 54, h*0.38, 10, vest, OL)
    p.rect(cx-27, h*0.38, 54, h*0.13, 10, vhi)
    for dy in (h*0.50, h*0.63): p.line(cx-24, dy, cx+24, dy, 3, (244,222,96,255))
    p.rect(cx-9, h*0.40, 18, h*0.33, 4, (96,140,96,255))  # shirt under vest
    # massive arms; wrench over shoulder
    p.cap(cx-22, h*0.44, cx-34, h*0.62, 7.5, skin, OL); p.ell(cx-34, h*0.64, 8,8, skin, OL,1.8)
    p.cap(cx+22, h*0.44, cx+38, h*0.34, 7.5, skin, OL)
    p.line(cx+34, h*0.40, cx+50, h*0.10, 5, (92,96,112,255))
    p.rect(cx+42, h*0.035, 16, 12, 3, (92,96,112,255), OL)
    p.rect(cx+46, h*0.065, 14, 5.5, 2, (62,64,78,255))
    p.ell(cx+38, h*0.335, 8.5, 8.5, skin, OL, 1.8)
    hy = h*0.275
    p.ell(cx, hy, 17, 16, skin, OL, 2.4)
    eyes(p, cx+3, hy, 3.8, glow=(255,150,60,255))
    p.ell(cx+5, hy+9, 9, 5, skin, OL, 1.6)
    for i in range(3): p.rect(cx+1+i*4.4, hy+5.5, 2.6, 3.6, 0.8, (245,245,235,255))
    # hardhat
    p.d.chord([(cx-16)*SS,(hy-22)*SS,(cx+16)*SS,(hy+2)*SS], 180, 360, fill=(244,204,64,255), outline=OL, width=int(2*SS))
    p.rect(cx-19, hy-6, 38, 4, 2, (244,204,64,255), OL, 1.4)
    p.line(cx-8, hy-18, cx+8, hy-18, 3, (255,228,110,255))
    save(img, "boss4.png", w, h)

# ================================================================ GUNS (side view, held right)
def guns():
    w,h = 30,16; img = canvas(w,h); p = P(img)
    p.rect(2, 5, 22, 6, 2, (58,60,74,255), OL, 1.6)
    p.rect(20, 4, 8, 4.5, 1.5, (40,42,54,255))
    p.rect(6, 9, 5.5, 6, 1.5, (98,70,46,255), OL, 1.4)
    p.ell(9, 8, 2.6, 2.6, (240,198,166,255), OL, 1.0)   # hand on grip
    save(img, "gun_pistol.png", w, h)
    w,h = 40,16; img = canvas(w,h); p = P(img)
    p.rect(2, 5, 32, 6.5, 2, (70,52,38,255), OL, 1.6)
    p.rect(24, 4, 14, 5, 1.5, (52,54,66,255), OL, 1.4)
    p.rect(6, 10, 6, 6, 1.5, (98,70,46,255), OL, 1.4)
    p.ell(10, 8, 2.6, 2.6, (240,198,166,255), OL, 1.0)
    p.ell(22, 9, 2.6, 2.6, (240,198,166,255), OL, 1.0)  # pump hand
    save(img, "gun_shotgun.png", w, h)

# ================================================================ 3/4 PROPS
def props():
    # crate: top face + front face
    w,h = 56,60; img = canvas(w,h); p = P(img)
    p.poly([(6,16),(28,6),(50,16),(28,26)], (206,158,96,255), OL)
    p.rect(6, 16, 44, 38, 3, (176,128,72,255), OL)
    p.line(6, 16, 28, 26, 1.6, (140,100,56,255)); p.line(50, 16, 28, 26, 1.6, (140,100,56,255))
    p.line(10, 20, 46, 50, 2, (150,110,62,255)); p.line(46, 20, 10, 50, 2, (150,110,62,255))
    save(img, "crate.png", w, h)
    # barrel: elliptical top + body
    w,h = 48,58; img = canvas(w,h); p = P(img)
    p.rect(6, 12, 36, 40, 8, (168,94,56,255), OL)
    for y in (24, 40): p.line(7, y, 41, y, 2.4, (120,64,40,255))
    p.ell(24, 12, 18, 8, (192,112,66,255), OL, 2)
    p.ell(24, 12, 11, 4.5, (140,76,46,255))
    save(img, "barrel.png", w, h)
    # bench: seat top + legs
    w,h = 96,44; img = canvas(w,h); p = P(img)
    p.poly([(4,14),(92,14),(96,22),(0,22)], (150,108,68,255), OL)
    p.rect(0, 22, 96, 10, 3, (120,82,52,255), OL)
    for x in (8, 82): p.rect(x, 32, 7, 10, 2, (90,62,40,255), OL, 1.4)
    save(img, "bench.png", w, h)
    # wall: shaded brick (light top, dark base) so walls read as standing
    img = Image.new("RGBA", (64,64), (78,68,82,255))
    d = ImageDraw.Draw(img)
    d.rectangle([0,0,64,10], fill=(104,94,108,255))
    d.rectangle([0,54,64,64], fill=(54,46,58,255))
    for y in (10, 25, 40, 54):
        d.line([(0,y),(64,y)], fill=(58,50,62,255), width=2)
    for i, y in enumerate((10, 25, 40)):
        off = 16 if i % 2 else 0
        for x in range(off, 64, 32):
            d.line([(x, y),(x, y+15)], fill=(58,50,62,255), width=2)
    img.save(os.path.join(OUT, "wall.png")); print("wrote wall.png")
    # train interior wall: metal + window with highlight
    img = Image.new("RGBA", (64,64), (52,56,72,255))
    d = ImageDraw.Draw(img)
    d.rectangle([0,0,64,8], fill=(74,80,100,255))
    d.rectangle([0,56,64,64], fill=(36,38,52,255))
    d.rectangle([8,16,56,40], fill=(80,104,140,255), outline=(32,34,46,255), width=2)
    d.polygon([(10,18),(28,18),(16,38),(10,38)], fill=(120,148,185,255))
    img.save(os.path.join(OUT, "trainwall.png")); print("wrote trainwall.png")

player(); survivor()
zombie_base("zombie_walker.png", 62, 86, (110,176,106,255), (96,88,72,255), (122,112,92,255), (66,60,74,255))
zombie_base("zombie_runner.png", 56, 80, (176,200,100,255), (150,110,70,255), (180,140,92,255), (80,70,56,255), bulk=0.9)
zombie_base("zombie_heavy.png", 92, 104, (78,134,98,255), (66,74,92,255), (92,102,124,255), (46,50,64,255), bulk=1.35, jaw=True)
conductor(); broadcaster(); passenger(); foreman(); guns(); props()
print("V3 ART DONE")
