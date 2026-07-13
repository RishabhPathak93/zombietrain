#!/usr/bin/env python3
"""Minecraft-style 16x16 pixel tiles + mob faces for the 3D mode."""
import os, random
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
rng = random.Random(9)

def tile(name, base, jitter=14, grid=None, накладка=None):
    img = Image.new("RGBA", (16, 16))
    px = img.load()
    for y in range(16):
        for x in range(16):
            j = rng.randint(-jitter, jitter)
            px[x, y] = tuple(max(0, min(255, c + j)) for c in base[:3]) + (255,)
    if grid:  # mortar/plank lines
        for (x0, y0, x1, y1) in grid:
            for x in range(x0, x1 + 1):
                for y in range(y0, y1 + 1):
                    px[x % 16, y % 16] = накладка
    img.save(os.path.join(OUT, name)); print("wrote", name)

MORTAR = (44, 40, 52, 255)
tile("mc_stone.png", (110, 112, 122))
tile("mc_brick.png", (96, 78, 92), grid=[(0,3,15,3),(0,11,15,11),(4,0,4,3),(12,4,12,11),(7,12,7,15)], накладка=MORTAR)
tile("mc_planks.png", (128, 96, 58), jitter=10, grid=[(0,3,15,3),(0,7,15,7),(0,11,15,11)], накладка=(84,60,36,255))
tile("mc_grass.png", (58, 84, 52), jitter=16)
tile("mc_platform.png", (124, 118, 106), jitter=8, grid=[(0,7,15,7)], накладка=(90,86,78,255))
tile("mc_metal.png", (78, 84, 100), jitter=6, grid=[(0,0,15,0),(0,15,15,15)], накладка=(52,56,70,255))

# glowstone-ish lamp block
img = Image.new("RGBA", (16, 16))
px = img.load()
for y in range(16):
    for x in range(16):
        hot = (x // 4 + y // 4) % 2 == 0
        c = (255, 220, 140) if hot else (200, 150, 70)
        j = rng.randint(-12, 12)
        px[x, y] = tuple(max(0, min(255, v + j)) for v in c) + (255,)
img.save(os.path.join(OUT, "mc_lamp.png")); print("wrote mc_lamp.png")

def face(name, skin, eyes, mouth_row=11, boss=False, eye_glow=None):
    img = Image.new("RGBA", (16, 16))
    px = img.load()
    for y in range(16):
        for x in range(16):
            j = rng.randint(-10, 10)
            px[x, y] = tuple(max(0, min(255, c + j)) for c in skin) + (255,)
    ec = eye_glow if eye_glow else eyes
    for (ex, ey) in [(3, 6), (11, 6)]:
        for dx in range(2):
            for dy in range(2):
                px[ex + dx, ey + dy] = ec + (255,)
    # scowl brows for bosses
    if boss:
        for dx in range(3):
            px[2 + dx, 4] = (20, 20, 24, 255)
            px[11 + dx, 4] = (20, 20, 24, 255)
    # mouth
    for dx in range(6):
        px[5 + dx, mouth_row] = (30, 26, 30, 255)
    for dx in (5, 8, 10):
        px[dx, mouth_row + 1] = (235, 230, 215, 255)
    img.save(os.path.join(OUT, name)); print("wrote", name)

face("mc_zombie_face.png", (72, 132, 72), (40, 40, 46), eye_glow=(140, 255, 140))
face("mc_boss_face.png", (96, 150, 96), (0, 0, 0), boss=True, eye_glow=(255, 210, 90))
print("MC TILES DONE")
