#!/usr/bin/env python3
"""v4 art: stylized-realistic shaded characters with 4-frame walk cycles.
Post-process adds vertical light gradient, top-right rim light, bottom-left
ambient occlusion and film-grain noise for a painterly look."""
import math, os
import numpy as np
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
SS = 4
OL = (22, 18, 28, 255)
rng = np.random.default_rng(11)

def canvas(w, h): return Image.new("RGBA", (w*SS, h*SS), (0,0,0,0))

class P:
    def __init__(s, img): s.d = ImageDraw.Draw(img)
    def ell(s, cx, cy, rx, ry, fill, ol=None, ow=2.0):
        b=[(cx-rx)*SS,(cy-ry)*SS,(cx+rx)*SS,(cy+ry)*SS]
        if ol:
            s.d.ellipse(b, fill=ol); o=ow*SS
            s.d.ellipse([b[0]+o,b[1]+o,b[2]-o,b[3]-o], fill=fill)
        else: s.d.ellipse(b, fill=fill)
    def cap(s, x1,y1,x2,y2,r,fill,ol=None,ow=1.6):
        if ol:
            s.d.line([(x1*SS,y1*SS),(x2*SS,y2*SS)], fill=ol, width=int(2*(r+ow)*SS))
            for x,y in ((x1,y1),(x2,y2)): s.d.ellipse([(x-r-ow)*SS,(y-r-ow)*SS,(x+r+ow)*SS,(y+r+ow)*SS], fill=ol)
        s.d.line([(x1*SS,y1*SS),(x2*SS,y2*SS)], fill=fill, width=int(2*r*SS))
        for x,y in ((x1,y1),(x2,y2)): s.d.ellipse([(x-r)*SS,(y-r)*SS,(x+r)*SS,(y+r)*SS], fill=fill)
    def poly(s, pts, fill, ol=None):
        pp=[(x*SS,y*SS) for x,y in pts]
        if ol: s.d.polygon(pp, fill=ol, outline=ol, width=int(1.8*SS))
        s.d.polygon(pp, fill=fill)
    def rect(s, x,y,w,h,r,fill,ol=None,ow=1.6):
        b=[x*SS,y*SS,(x+w)*SS,(y+h)*SS]
        if ol:
            s.d.rounded_rectangle(b, radius=r*SS, fill=ol); o=ow*SS
            s.d.rounded_rectangle([b[0]+o,b[1]+o,b[2]-o,b[3]-o], radius=max(1,(r-ow)*SS), fill=fill)
        else: s.d.rounded_rectangle(b, radius=r*SS, fill=fill)
    def line(s, x1,y1,x2,y2,w,fill): s.d.line([(x1*SS,y1*SS),(x2*SS,y2*SS)], fill=fill, width=int(w*SS))
    def arc(s, box, a0,a1,w,fill): s.d.arc([v*SS for v in box], a0,a1, fill=fill, width=int(w*SS))

CURRENT_RIM = (52, 52, 52)

def post(img_small):
    """Painterly pass: light gradient, NEON rim light, AO, grain."""
    arr = np.array(img_small).astype(np.float32)
    h, w = arr.shape[:2]
    a = arr[..., 3]
    mask = a > 12
    grad = (1.12 - 0.34 * np.linspace(0, 1, h))[:, None, None]
    arr[..., :3] = arr[..., :3] * np.where(mask[..., None], grad, 1.0)
    rim = mask & ~np.roll(np.roll(mask, 2, 0), -1, 1)
    rim &= np.arange(h)[:, None] < h * 0.9
    arr[..., :3][rim] = np.clip(arr[..., :3][rim] + np.array(CURRENT_RIM, dtype=np.float32), 0, 255)
    rim2 = mask & ~np.roll(np.roll(mask, 1, 0), -2, 1)
    arr[..., :3][rim2] = np.clip(arr[..., :3][rim2] + np.array(CURRENT_RIM, dtype=np.float32) * 0.5, 0, 255)
    ao = mask & ~np.roll(np.roll(mask, -2, 0), 2, 1)
    arr[..., :3][ao] *= 0.72
    noise = rng.normal(0, 6.0, (h, w, 1))
    arr[..., :3] = np.where(mask[..., None], arr[..., :3] + noise, arr[..., :3])
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))

def save(img, name, w, h):
    small = img.resize((w, h), Image.LANCZOS)
    post(small).save(os.path.join(OUT, name)); print("wrote", name)

def eyes(p, cx, cy, r, glow=None, look=(0.3,0.05), angry=False, skin=None):
    for i, dx in enumerate((-r*1.35, r*1.35)):
        if glow:
            p.ell(cx+dx, cy, r, r*1.05, glow, OL, 0.9)
            p.ell(cx+dx, cy, r*0.45, r*0.5, (255,255,255,230))
        else:
            p.ell(cx+dx, cy, r, r*1.1, (246,244,238,255), OL, 0.9)
            p.ell(cx+dx+look[0]*r, cy+look[1]*r, r*0.5, r*0.55, (48,38,34,255))
            p.ell(cx+dx+look[0]*r-r*0.15, cy-r*0.2, r*0.16, r*0.16, (255,255,255,200))
    if angry:
        p.line(cx-r*2.3, cy-r*1.5, cx-r*0.4, cy-r*1.05, 1.6, OL)
        p.line(cx+r*0.4, cy-r*1.05, cx+r*2.3, cy-r*1.5, 1.6, OL)

# =====================================================================
# RIG — upright humanoid, faces right, 4 walk phases + neutral
# =====================================================================
def rig(name, W, H, cfg, frames=True):
    global CURRENT_RIM
    CURRENT_RIM = cfg.get("rim", (52, 52, 52))
    def draw(phase):
        img = canvas(W, H); p = P(img); cx = W/2
        swing = [1.0, 0.0, -1.0, 0.0][phase] if phase >= 0 else 0.0
        passing = [0.0, 1.0, 0.0, 1.0][phase] if phase >= 0 else 0.0
        bob = -passing * 2.6
        skin = cfg["skin"]; leg_h = cfg["leg_h"]; tw2 = cfg["torso_w"]/2
        ground = H - 5 + bob*0.3
        hip = ground - leg_h
        sh_y = hip - cfg["torso_h"] + bob          # shoulder line
        hy = sh_y - cfg["head_r"]*0.75 + cfg.get("head_drop", 0)  # head center
        hr = cfg["head_r"]
        # --- legs: clear scissor stride, one knee lifts high ---
        for side in (-1, 1):
            raised = max(0.0, swing * side)          # 0..1 -> this leg is stepping
            planted = max(0.0, -swing * side)
            lift = raised * 8.0                       # high knee
            fwd = raised * 4.0 - planted * 2.0        # stepping foot swings out
            lx = cx + side * cfg["leg_gap"] + fwd * side
            col = cfg["pants"] if side < 0 else tuple(min(255,int(c*1.12)) for c in cfg["pants"][:3])+(255,)
            knee_bend = raised * 3.0
            p.cap(cx + side*cfg["leg_gap"]*0.6, hip, lx, ground - 3 - lift + knee_bend*0.3, cfg["leg_w"], col, OL)
            p.ell(lx + 1.5 + raised*2.0, ground - 2 - lift, cfg["leg_w"]+2.2, cfg["leg_w"]*0.9, cfg["boot"], OL, 1.4)
        # --- back arm ---
        cfg["arm"](p, cx, sh_y, swing, True, cfg)
        # --- torso ---
        cfg["torso"](p, cx, sh_y, hip, tw2, cfg)
        # --- front arm ---
        cfg["arm"](p, cx, sh_y, swing, False, cfg)
        # --- head ---
        cfg["head"](p, cx + cfg.get("head_fwd", 2), hy, hr, cfg)
        return img
    if frames:
        for i in range(4):
            save(draw(i), "%s_w%d.png" % (name, i), W, H)
    save(draw(-1), name + ".png", W, H)

def std_torso(p, cx, sh_y, hip, tw2, cfg):
    base = cfg["torso_col"]; hi = cfg["torso_hi"]
    p.rect(cx-tw2, sh_y, tw2*2, hip-sh_y+3, min(9, tw2*0.55), base, OL)
    p.rect(cx-tw2, sh_y, tw2*2, (hip-sh_y)*0.34, min(9, tw2*0.55), hi)
    if cfg.get("torso_extra"): cfg["torso_extra"](p, cx, sh_y, hip, tw2, cfg)

def zombie_arm(p, cx, sh_y, swing, back, cfg):
    skin = cfg["skin"]; r = cfg["arm_w"]
    reach = cfg["arm_reach"]
    dy = -3 if back else 5
    wob = swing*4.5 * (-1 if back else 1)
    sleeve = cfg.get("sleeve")
    y0 = sh_y + 6 + dy
    if sleeve:
        p.cap(cx+4, y0, cx+reach*0.45, y0+wob*0.5, r+0.8, sleeve, OL)
    p.cap(cx+4 if not sleeve else cx+reach*0.45, y0, cx+reach, y0+wob, r, skin, OL)
    p.ell(cx+reach+2, y0+wob, r+1.6, r+1.6, skin, OL, 1.2)
    for f in (-1, 1):  # fingers
        p.ell(cx+reach+4, y0+wob+f*2.4, 1.5, 1.5, skin)

def relaxed_arm(p, cx, sh_y, swing, back, cfg):
    col = cfg.get("sleeve", cfg["torso_col"]); skin = cfg["skin"]; r = cfg["arm_w"]
    side = -1 if back else 1
    sw = swing*6.5*side
    x0 = cx + side*(cfg["torso_w"]/2 - 1)
    p.cap(x0, sh_y+5, x0 + side*2 + sw, sh_y+20, r, col, OL)
    p.ell(x0 + side*2 + sw, sh_y+22, r+0.8, r+0.8, skin, OL, 1.1)

# =====================================================================
# CHARACTERS
# =====================================================================
def head_player(p, cx, hy, hr, cfg):
    skin = cfg["skin"]; hair=(74,46,28,255)
    p.ell(cx-hr*0.9, hy+hr*0.5, hr*0.35, hr*0.6, hair, OL, 1.2)      # ponytail
    p.ell(cx, hy, hr, hr*1.06, skin, OL, 1.8)
    p.d.chord([(cx-hr)*SS,(hy-hr*1.15)*SS,(cx+hr)*SS,(hy+hr*0.5)*SS], 180, 360, fill=hair)
    p.poly([(cx+hr*0.2,hy-hr*0.85),(cx+hr*0.95,hy-hr*0.3),(cx+hr*0.5,hy-hr*0.25)], hair)
    eyes(p, cx+hr*0.28, hy, hr*0.17, look=(0.4,0.0))
    p.line(cx-hr*0.25, hy-hr*0.38, cx+hr*0.75, hy-hr*0.42, 1.3, (60,38,24,255))
    p.arc((cx+hr*0.05, hy+hr*0.3, cx+hr*0.6, hy+hr*0.62), 20, 150, 1.2, (150,90,70,255))
    p.ell(cx+hr*0.98, hy+hr*0.1, hr*0.13, hr*0.2, skin, OL, 0.8)      # nose hint

def player_torso_extra(p, cx, sh_y, hip, tw2, cfg):
    p.line(cx-tw2+2, sh_y+2, cx+3, hip-2, 2.2, (54,42,32,255))        # chest strap
    p.rect(cx-tw2, hip-6, tw2*2, 4.5, 2, (94,70,44,255), OL, 1.2)     # belt
    p.rect(cx+2, hip-7, 6, 7, 1.5, (66,52,38,255), OL, 1.1)           # holster
    p.line(cx-tw2+1, sh_y+3, cx-tw2+7, sh_y+1, 2.4, (30,74,140,255))  # collar

rig("player", 64, 110, {
    "skin": (238,196,164,255), "torso_col": (42,104,188,255), "torso_hi": (88,150,226,255),
    "pants": (56,58,74,255), "boot": (38,36,48,255), "sleeve": (36,90,166,255),
    "rim": (70, 190, 255),
    "head_r": 10, "torso_w": 26, "torso_h": 34, "leg_h": 26, "leg_gap": 6, "leg_w": 4.4,
    "arm_w": 3.4, "arm_reach": 15, "arm": relaxed_arm, "torso": std_torso,
    "torso_extra": player_torso_extra, "head": head_player,
})

def head_survivor(p, cx, hy, hr, cfg):
    skin = cfg["skin"]; hair=(36,34,44,255)
    p.ell(cx, hy, hr, hr*1.05, skin, OL, 1.8)
    p.d.chord([(cx-hr)*SS,(hy-hr*1.1)*SS,(cx+hr)*SS,(hy+hr*0.35)*SS], 180, 360, fill=hair)
    eyes(p, cx+hr*0.28, hy+hr*0.05, hr*0.16, look=(0.3,0.0))
    for dx in (-hr*0.18, hr*0.62):
        p.d.ellipse([(cx+dx-hr*0.28)*SS,(hy-hr*0.22)*SS,(cx+dx+hr*0.28)*SS,(hy+hr*0.32)*SS], outline=(28,28,38,255), width=int(1.2*SS))
    p.arc((cx+hr*0.05, hy+hr*0.35, cx+hr*0.55, hy+hr*0.6), 20, 160, 1.1, (150,96,76,255))

rig("survivor", 60, 106, {
    "skin": (230,188,156,255), "torso_col": (236,238,244,255), "torso_hi": (255,255,255,255),
    "pants": (74,78,96,255), "boot": (46,48,60,255), "sleeve": (222,226,236,255),
    "rim": (70, 190, 255),
    "head_r": 9.6, "torso_w": 24, "torso_h": 33, "leg_h": 25, "leg_gap": 5.5, "leg_w": 4.0,
    "arm_w": 3.2, "arm_reach": 14, "arm": relaxed_arm, "torso": std_torso,
    "torso_extra": lambda p,cx,sh_y,hip,tw2,cfg: (
        p.line(cx-3, sh_y+2, cx-3, hip-2, 1.4, (196,202,214,255)),
        p.rect(cx+tw2-3, hip-10, 8, 9, 2, (118,86,54,255), OL, 1.3)),
    "head": head_survivor,
})

def zhead(scars=True, glow=(224,230,200,255), jaw_drop=1.0):
    def f(p, cx, hy, hr, cfg):
        skin = cfg["skin"]; dark = tuple(max(0,c-42) for c in skin[:3])+(255,)
        p.ell(cx, hy, hr, hr*1.08, skin, OL, 1.8)
        p.ell(cx-hr*0.3, hy-hr*0.5, hr*0.55, hr*0.4, dark)             # scalp rot
        eyes(p, cx+hr*0.3, hy-hr*0.05, hr*0.16, glow=glow)
        # gaping jaw
        jw = hr*0.62
        p.ell(cx+hr*0.32, hy+hr*0.72*jaw_drop, jw, hr*0.42, dark, OL, 1.3)
        p.ell(cx+hr*0.32, hy+hr*0.62*jaw_drop, jw*0.8, hr*0.22, (70,26,30,255))
        for i in range(3):
            p.rect(cx+hr*0.02+i*hr*0.26, hy+hr*0.42, hr*0.13, hr*0.2, 0.6, (238,234,222,255))
        if scars:
            p.line(cx-hr*0.6, hy+hr*0.15, cx-hr*0.15, hy+hr*0.45, 1.1, dark)
    return f

def zombie_cfg(skin, shirt, shi, pants, extra=None, **kw):
    cfg = {
        "skin": skin, "torso_col": shirt, "torso_hi": shi, "pants": pants,
        "boot": (40,38,46,255), "rim": (80, 255, 160), "head_r": 10.5, "torso_w": 27, "torso_h": 32,
        "leg_h": 24, "leg_gap": 6, "leg_w": 4.4, "arm_w": 3.6, "arm_reach": 22,
        "arm": zombie_arm, "torso": std_torso, "head": zhead(), "torso_extra": extra,
    }
    cfg.update(kw); return cfg

def torn(p, cx, sh_y, hip, tw2, cfg):
    slo = tuple(max(0,c-40) for c in cfg["torso_col"][:3])+(255,)
    for i in range(4):
        x = cx - tw2 + 3 + i*(tw2*2-6)/3
        p.poly([(x, hip+2), (x+3, hip-3), (x+6, hip+2)], slo)
    p.ell(cx-tw2*0.4, sh_y+(hip-sh_y)*0.55, 4, 3, slo)

# office-worker walker (classic): shirt + crooked tie
def walker_extra(p, cx, sh_y, hip, tw2, cfg):
    torn(p, cx, sh_y, hip, tw2, cfg)
    p.poly([(cx+1,sh_y+2),(cx+5,sh_y+2),(cx+4,sh_y+14),(cx+1,sh_y+13)], (140,44,52,255), OL)
rig("zombie_walker", 66, 106, zombie_cfg(
    (108,172,104,255), (176,180,190,255), (208,212,220,255), (72,66,80,255), walker_extra))

# hoodie runner
def runner_extra(p, cx, sh_y, hip, tw2, cfg):
    p.arc((cx-tw2+1, sh_y-3, cx+tw2-1, sh_y+13), 180, 360, 2.4, (110,84,50,255))
    p.line(cx-2, sh_y+4, cx-2, sh_y+12, 1.2, (110,84,50,255))
    p.line(cx+3, sh_y+4, cx+3, sh_y+12, 1.2, (110,84,50,255))
rig("zombie_runner", 60, 100, zombie_cfg(
    (174,200,102,255), (150,112,70,255), (178,140,92,255), (64,68,58,255), runner_extra,
    sleeve=(150,112,70,255), torso_w=23, arm_reach=24, head_r=9.8))

# butcher heavy
def heavy_extra(p, cx, sh_y, hip, tw2, cfg):
    p.poly([(cx-tw2*0.55, sh_y+3),(cx+tw2*0.55, sh_y+3),(cx+tw2*0.42, hip-2),(cx-tw2*0.42, hip-2)], (188,186,192,255), OL)
    p.line(cx-tw2*0.5, sh_y+5, cx+tw2*0.5, sh_y+5, 2, (120,118,126,255))
    p.ell(cx+2, sh_y+(hip-sh_y)*0.5, 4, 5, (150,60,60,255))
rig("zombie_heavy", 100, 124, zombie_cfg(
    (82,138,100,255), (74,80,98,255), (100,108,128,255), (52,54,66,255), heavy_extra,
    torso_w=44, torso_h=40, leg_h=22, leg_gap=10, leg_w=6.5, arm_w=6, arm_reach=30,
    head_r=10.5, head_drop=4))

# =====================================================================
# BOSSES — bigger, detailed, menacing
# =====================================================================
def coat_torso(coat, chi, hem_col):
    def f(p, cx, sh_y, hip, tw2, cfg):
        p.poly([(cx-tw2,sh_y),(cx+tw2,sh_y),(cx+tw2*1.3,hip+14),(cx-tw2*1.3,hip+14)], coat, OL)
        p.poly([(cx-tw2+2,sh_y+1),(cx+tw2-2,sh_y+1),(cx+tw2*1.05,sh_y+(hip-sh_y)*0.45),(cx-tw2*1.05,sh_y+(hip-sh_y)*0.45)], chi)
        for i in range(5):  # tattered hem
            x = cx - tw2*1.25 + i*(tw2*2.5)/4
            p.poly([(x, hip+15),(x+tw2*0.25, hip+7),(x+tw2*0.5, hip+15)], hem_col)
        if cfg.get("coat_extra"): cfg["coat_extra"](p, cx, sh_y, hip, tw2, cfg)
    return f

def boss_head(skin, glow, hat):
    def f(p, cx, hy, hr, cfg):
        p.ell(cx, hy, hr, hr*1.06, skin, OL, 2.0)
        dark = tuple(max(0,c-46) for c in skin[:3])+(255,)
        p.ell(cx-hr*0.35, hy+hr*0.35, hr*0.3, hr*0.22, dark)
        eyes(p, cx+hr*0.3, hy-hr*0.02, hr*0.15, glow=glow, angry=True)
        p.ell(cx+hr*0.35, hy+hr*0.66, hr*0.55, hr*0.34, dark, OL, 1.2)
        for i in range(4):
            p.rect(cx+hr*0.02+i*hr*0.2, hy+hr*0.42, hr*0.1, hr*0.18, 0.5, (238,234,222,255))
        hat(p, cx, hy, hr, cfg)
    return f

def cap_hat(band, badge=True):
    def f(p, cx, hy, hr, cfg):
        p.d.chord([(cx-hr*1.02)*SS,(hy-hr*1.5)*SS,(cx+hr*1.02)*SS,(hy)*SS], 180, 360, fill=(30,26,46,255), outline=OL, width=int(1.8*SS))
        p.rect(cx-hr*1.1, hy-hr*0.62, hr*2.2, hr*0.3, 1.5, (30,26,46,255), OL, 1.2)
        p.line(cx-hr*0.85, hy-hr*0.75, cx+hr*0.85, hy-hr*0.75, 1.8, band)
        if badge: p.ell(cx, hy-hr*1.0, hr*0.16, hr*0.16, (224,188,92,255), OL, 0.8)
    return f

def conductor():
    def coat_extra(p, cx, sh_y, hip, tw2, cfg):
        for i in range(4): p.ell(cx-4+i*4, sh_y+9+i*5, 1.8, 1.8, (224,188,92,255))
        p.line(cx-tw2*0.7, sh_y+12, cx+tw2*0.5, hip-6, 1.8, (200,170,90,255))
        p.ell(cx+tw2*0.55, hip-4, 3.5, 4.5, (255,190,90,255), OL, 1.2)  # lantern
    rig("boss", 128, 190, {
        "skin": (146,192,148,255), "torso_col": (52,42,84,255), "torso_hi": (88,72,128,255),
        "pants": (34,28,52,255), "boot": (24,20,38,255), "sleeve": (52,42,84,255),
        "rim": (255, 200, 70),
        "head_r": 14, "torso_w": 42, "torso_h": 54, "leg_h": 32, "leg_gap": 10, "leg_w": 6.6,
        "arm_w": 5.8, "arm_reach": 34, "arm": zombie_arm,
        "torso": coat_torso((52,42,84,255),(88,72,128,255),(40,32,64,255)),
        "coat_extra": coat_extra, "head": boss_head((146,192,148,255),(255,214,80,255),cap_hat((196,60,60,255))),
    })

def broadcaster():
    def coat_extra(p, cx, sh_y, hip, tw2, cfg):
        for k in (-1,1): p.line(cx-tw2*0.6, sh_y+12+k*6, cx+tw2*0.6, hip-14-k*4, 2, (62,64,80,255))
        p.ell(cx, sh_y+(hip-sh_y)*0.45, 6, 6, (38,38,52,255), OL, 1.4)
        p.ell(cx, sh_y+(hip-sh_y)*0.45, 2.6, 2.6, (255,72,60,255))
    def hat(p, cx, hy, hr, cfg):
        for ang in (-0.85, 0.0, 0.85):
            x2 = cx + math.sin(ang)*hr*1.1; y2 = hy - hr*1.1 - math.cos(ang)*hr*0.95
            p.line(cx, hy-hr*0.85, x2, y2, 1.8, (198,204,220,255))
            p.ell(x2, y2, 2.6, 2.6, (255,72,60,255), OL, 0.9)
    rig("boss2", 128, 188, {
        "skin": (168,188,158,255), "torso_col": (140,40,58,255), "torso_hi": (184,78,92,255),
        "pants": (66,24,36,255), "boot": (40,18,26,255), "sleeve": (140,40,58,255),
        "rim": (255, 80, 80),
        "head_r": 13.5, "torso_w": 42, "torso_h": 53, "leg_h": 32, "leg_gap": 10, "leg_w": 6.4,
        "arm_w": 5.6, "arm_reach": 33, "arm": zombie_arm,
        "torso": coat_torso((140,40,58,255),(184,78,92,255),(104,28,44,255)),
        "coat_extra": coat_extra, "head": boss_head((168,188,158,255),(255,84,66,255),hat),
    })

def passenger():
    def torso_extra(p, cx, sh_y, hip, tw2, cfg):
        p.poly([(cx-6,sh_y+1),(cx+6,sh_y+1),(cx+2,sh_y+26),(cx-2,sh_y+26)], (234,236,242,255), OL)
        p.poly([(cx-2,sh_y+2),(cx+2,sh_y+2),(cx+1,sh_y+24),(cx-1,sh_y+24)], (186,50,50,255))
        p.poly([(cx-tw2,sh_y),(cx-5,sh_y),(cx-9,sh_y+16)], (46,50,66,255))
        p.poly([(cx+tw2,sh_y),(cx+5,sh_y),(cx+9,sh_y+16)], (46,50,66,255))
    def arm(p, cx, sh_y, swing, back, cfg):
        suit=(30,32,44,255); skin=cfg["skin"]
        if back:
            p.cap(cx+14, sh_y+8, cx+30, sh_y+2, 4.6, suit, OL)
            p.ell(cx+32, sh_y+2, 5, 5, skin, OL, 1.3)
        else:
            p.cap(cx+12, sh_y+16, cx+26, sh_y+34, 4.6, suit, OL)
            p.rect(cx+18, sh_y+34, 20, 14, 2.5, (72,52,36,255), OL)
            p.line(cx+21, sh_y+41, cx+35, sh_y+41, 1.4, (116,88,58,255))
            p.ell(cx+28, sh_y+41, 3.6, 3.6, (92,232,212,255))
    def hat(p, cx, hy, hr, cfg):
        p.d.chord([(cx-hr)*SS,(hy-hr*1.45)*SS,(cx+hr)*SS,(hy-hr*0.1)*SS], 180, 360, fill=(22,22,32,255), outline=OL, width=int(1.8*SS))
        p.rect(cx-hr*1.25, hy-hr*0.68, hr*2.5, hr*0.28, 1.5, (22,22,32,255), OL, 1.1)
        p.line(cx-hr*0.8, hy-hr*0.8, cx+hr*0.8, hy-hr*0.8, 1.8, (150,40,40,255))
    rig("boss3", 118, 180, {
        "skin": (176,186,168,255), "torso_col": (30,32,44,255), "torso_hi": (56,60,80,255),
        "pants": (26,28,38,255), "boot": (18,18,28,255),
        "rim": (90, 240, 220),
        "head_r": 12.5, "torso_w": 38, "torso_h": 52, "leg_h": 32, "leg_gap": 9, "leg_w": 5.8,
        "arm_w": 4.8, "arm_reach": 30, "arm": arm, "torso": std_torso,
        "torso_extra": torso_extra, "head": boss_head((176,186,168,255),(92,232,212,255),hat),
    })

def foreman():
    def torso_extra(p, cx, sh_y, hip, tw2, cfg):
        for dy in (0.35, 0.62): p.line(cx-tw2+3, sh_y+(hip-sh_y)*dy, cx+tw2-3, sh_y+(hip-sh_y)*dy, 3, (246,222,96,255))
        p.line(cx-tw2*0.55, sh_y+2, cx-tw2*0.2, hip-3, 2.4, (96,70,44,255))
    def arm(p, cx, sh_y, swing, back, cfg):
        skin = cfg["skin"]
        if back:  # wrench over the shoulder
            p.cap(cx+16, sh_y+6, cx+34, sh_y-8, 7, skin, OL)
            p.line(cx+30, sh_y-4, cx+46, sh_y-34, 4.5, (94,98,114,255))
            p.rect(cx+38, sh_y-46, 15, 11, 2.5, (94,98,114,255), OL)
            p.rect(cx+42, sh_y-43, 13, 5, 1.5, (60,62,76,255))
            p.ell(cx+34, sh_y-9, 7.5, 7.5, skin, OL, 1.5)
        else:
            p.cap(cx+14, sh_y+14, cx+34, sh_y+26, 7, skin, OL)
            p.ell(cx+36, sh_y+27, 8, 8, skin, OL, 1.5)
    def hat(p, cx, hy, hr, cfg):
        p.d.chord([(cx-hr*1.05)*SS,(hy-hr*1.6)*SS,(cx+hr*1.05)*SS,(hy+hr*0.05)*SS], 180, 360, fill=(244,202,60,255), outline=OL, width=int(1.8*SS))
        p.rect(cx-hr*1.28, hy-hr*0.55, hr*2.56, hr*0.3, 1.5, (244,202,60,255), OL, 1.1)
        p.line(cx-hr*0.5, hy-hr*1.3, cx+hr*0.5, hy-hr*1.3, 2.4, (255,226,110,255))
    rig("boss4", 148, 192, {
        "skin": (108,158,108,255), "torso_col": (208,116,42,255), "torso_hi": (238,150,68,255),
        "pants": (58,54,64,255), "boot": (34,32,40,255),
        "rim": (255, 160, 60),
        "head_r": 13.5, "torso_w": 56, "torso_h": 56, "leg_h": 32, "leg_gap": 13, "leg_w": 8,
        "arm_w": 7, "arm_reach": 34, "arm": arm, "torso": std_torso,
        "torso_extra": torso_extra, "head": boss_head((108,158,108,255),(255,150,60,255),hat),
        "head_drop": 3,
    })

conductor(); broadcaster(); passenger(); foreman()

# =====================================================================
# GUNS (detailed side views) + grenade + slash
# =====================================================================
def gun(name, W, H, draw_fn):
    img = canvas(W, H); p = P(img); draw_fn(p)
    save(img, name, W, H)

gun("gun_pistol.png", 30, 16, lambda p: (
    p.rect(3, 5, 20, 5.5, 1.8, (64,66,80,255), OL, 1.4),
    p.rect(19, 4, 8, 4, 1.2, (44,46,58,255)),
    p.rect(6, 9.5, 5, 6, 1.2, (98,70,46,255), OL, 1.2),
    p.ell(9, 8, 2.4, 2.4, (238,196,164,255), OL, 0.9)))
gun("gun_shotgun.png", 42, 16, lambda p: (
    p.rect(2, 6, 15, 6, 2, (96,66,42,255), OL, 1.4),
    p.rect(14, 5.5, 24, 5, 1.6, (58,60,74,255), OL, 1.4),
    p.rect(20, 9.5, 9, 3.5, 1.4, (76,52,34,255), OL, 1.1),
    p.ell(11, 9, 2.4, 2.4, (238,196,164,255), OL, 0.9),
    p.ell(24, 11, 2.4, 2.4, (238,196,164,255), OL, 0.9)))
gun("gun_smg.png", 34, 20, lambda p: (
    p.rect(3, 5, 24, 6, 1.8, (52,54,66,255), OL, 1.4),
    p.rect(24, 4, 8, 4.5, 1.2, (40,42,52,255)),
    p.rect(12, 10, 4.5, 8, 1.2, (44,46,58,255), OL, 1.1),
    p.rect(6, 10, 4.5, 5.5, 1.2, (98,70,46,255), OL, 1.1),
    p.ell(8.5, 8.5, 2.3, 2.3, (238,196,164,255), OL, 0.9)))
gun("gun_rifle.png", 50, 16, lambda p: (
    p.rect(2, 6.5, 12, 5.5, 1.8, (96,66,42,255), OL, 1.3),
    p.rect(12, 6, 32, 4.5, 1.4, (58,60,74,255), OL, 1.3),
    p.rect(42, 6.5, 7, 3, 1, (40,42,52,255)),
    p.rect(17, 3, 9, 3.5, 1, (44,46,58,255), OL, 1.0),  # scope
    p.rect(20, 10, 4, 6, 1, (44,46,58,255), OL, 1.0),
    p.ell(10, 9.5, 2.3, 2.3, (238,196,164,255), OL, 0.9),
    p.ell(26, 9, 2.3, 2.3, (238,196,164,255), OL, 0.9)))

gun("grenade.png", 26, 32, lambda p: (
    p.rect(9, 2, 8, 5, 1.5, (120,124,136,255), OL, 1.2),
    p.line(17, 4, 22, 7, 2, (150,154,166,255)),
    p.ell(22, 8, 2.5, 2.5, (190,160,60,255), OL, 1.0),
    p.ell(13, 18, 9, 11, (70,96,66,255), OL, 1.6),
    p.line(6, 14, 20, 14, 1.4, (50,70,48,255)),
    p.line(6, 21, 20, 21, 1.4, (50,70,48,255))))

# slash arc for melee hits
img = canvas(64, 64); p = P(img)
for i, (r, al) in enumerate([(28, 235), (23, 140), (18, 70)]):
    p.arc((32-r, 32-r, 32+r, 32+r), -55, 55, 4-i, (255, 255, 255, al))
save(img, "slash.png", 64, 64)
print("V4 ART DONE")
