#!/usr/bin/env python3
"""Generate all pixel-art sprite sheets for Pixel Dungeon Blaster.

Every sheet lays frames out horizontally so Godot can use Sprite2D.hframes.
Run:  python3 tools/gen_art.py
Output: new-game-project/assets/*.png
"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "new-game-project", "assets"))
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- palette
T = (0, 0, 0, 0)              # transparent
BLACK = (24, 20, 34, 255)     # outline
WHITE = (244, 244, 236, 255)

# player
HOOD = (60, 164, 214, 255)
HOOD_D = (40, 120, 170, 255)
SKIN = (240, 200, 160, 255)
BODY = (70, 200, 160, 255)
BODY_D = (40, 150, 120, 255)
GUN = (110, 110, 130, 255)
GUN_D = (70, 70, 90, 255)
BOOT = (90, 66, 50, 255)

# slime
SLIME = (120, 214, 90, 255)
SLIME_D = (70, 160, 60, 255)
SLIME_L = (180, 240, 150, 255)

# bat
BAT = (150, 100, 200, 255)
BAT_D = (100, 60, 150, 255)

# fx / items
YELLOW = (255, 224, 90, 255)
YELLOW_D = (220, 170, 40, 255)
RED = (230, 70, 80, 255)
RED_D = (170, 40, 55, 255)
GOLD = (255, 205, 70, 255)
GOLD_D = (200, 150, 30, 255)
WOOD = (150, 100, 60, 255)
WOOD_D = (100, 66, 40, 255)

FLOOR = (58, 52, 74, 255)
FLOOR_2 = (66, 60, 84, 255)
WALL = (92, 84, 112, 255)
WALL_D = (60, 54, 78, 255)
WALL_TOP = (120, 112, 146, 255)


def new_sheet(frames, w, h):
    return Image.new("RGBA", (frames * w, h), T)


def blit(px, ox, oy, grid, colors):
    """Draw a grid of single-char keys at offset (ox,oy) using a color map."""
    for y, row in enumerate(grid):
        for x, ch in enumerate(row):
            if ch != "." and ch in colors:
                px[ox + x, oy + y] = colors[ch]


def outline(px, w, h, ox, oy, color=BLACK):
    """Add a 1px outline around every opaque cluster within the frame box."""
    src = {}
    for y in range(h):
        for x in range(w):
            p = px[ox + x, oy + y]
            if p[3] != 0:
                src[(x, y)] = True
    for (x, y) in list(src.keys()):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in src:
                if px[ox + nx, oy + ny][3] == 0:
                    px[ox + nx, oy + ny] = color


# ---------------------------------------------------------------- player 16x16 x8
def gen_player():
    W = H = 16
    img = new_sheet(8, W, H)
    px = img.load()
    C = {"h": HOOD, "H": HOOD_D, "s": SKIN, "b": BODY, "B": BODY_D,
         "g": GUN, "G": GUN_D, "o": BOOT, "w": WHITE}

    def draw(fi, bob, leg):
        ox = fi * W
        oy = bob
        head = [
            "...hhhh...",
            "..hhhhhh..",
            ".hhHHHHhh.",
            ".hssssssh.",
            ".hswwswsh.",
            "..ssssss..",
        ]
        blit(px, ox + 3, oy + 1, head, C)
        body = [
            ".bbbbbb.",
            "bbBBBBbb",
            "bbBbbBbb",
            ".bBBBBb.",
        ]
        blit(px, ox + 4, oy + 7, body, C)
        gun = [
            "gg",
            "gGGg",
            ".gg.",
        ]
        blit(px, ox + 10, oy + 8, gun, C)
        ly = oy + 11
        if leg == 0:
            blit(px, ox + 5, ly, ["o.o", "o.o"], C)
        elif leg == 1:
            blit(px, ox + 4, ly, ["o..", "o.."], C)
            blit(px, ox + 8, ly, ["..o", "..o"], C)
        else:
            blit(px, ox + 5, ly, ["..o", "..o"], C)
            blit(px, ox + 6, ly - 1, ["o..", "o.."], C)
        outline(px, W, H, ox, 0)

    for i, bob in enumerate((0, 0, 1, 0)):
        draw(i, bob, 0)
    for i, leg in enumerate((1, 0, -1, 0)):
        draw(4 + i, 0, leg if i % 2 == 0 else 0)
    img.save(os.path.join(OUT, "player.png"))


# ---------------------------------------------------------------- slime 16x16 x4
def gen_slime():
    W = H = 16
    img = new_sheet(4, W, H)
    px = img.load()

    def body(fi, squash):
        ox = fi * W
        top = 8 + squash
        wdt = 12 - squash
        left = ox + (16 - wdt) // 2
        for y in range(top, 15):
            for x in range(wdt):
                col = SLIME if y < 13 else SLIME_D
                px[left + x, y] = col
        for x in range(2, 5):
            px[left + x, top + 1] = SLIME_L
        ey = top + 3
        px[left + 3, ey] = WHITE
        px[left + 3, ey + 1] = BLACK
        px[left + wdt - 4, ey] = WHITE
        px[left + wdt - 4, ey + 1] = BLACK
        outline(px, W, H, ox, 0)

    body(0, 0)
    body(1, 2)
    body(2, -1)
    ox = 3 * W
    for y in range(12, 15):
        for x in range(2, 14):
            if (x + y) % 2 == 0:
                px[ox + x, y] = SLIME_D
    for x in range(4, 12):
        px[ox + x, 13] = SLIME
    outline(px, W, H, ox, 0)
    img.save(os.path.join(OUT, "slime.png"))


# ---------------------------------------------------------------- bat 16x16 x3
def gen_bat():
    W = H = 16
    img = new_sheet(3, W, H)
    px = img.load()

    def bat(fi, wing):
        ox = fi * W
        for y in range(6, 11):
            for x in range(6, 10):
                px[ox + x, y] = BAT
        for x in range(6, 10):
            px[ox + x, 10] = BAT_D
        px[ox + 6, 7] = RED
        px[ox + 9, 7] = RED
        px[ox + 6, 5] = BAT
        px[ox + 9, 5] = BAT
        if wing == "up":
            blit(px, ox + 1, 4, ["dd..", "ddd.", ".ddd"], {"d": BAT})
            blit(px, ox + 11, 4, ["..dd", ".ddd", "ddd."], {"d": BAT})
        else:
            blit(px, ox + 1, 7, [".ddd", "ddd.", "dd.."], {"d": BAT})
            blit(px, ox + 11, 7, ["ddd.", ".ddd", "..dd"], {"d": BAT})
        outline(px, W, H, ox, 0)

    bat(0, "up")
    bat(1, "down")
    ox = 2 * W
    for x, y in [(6, 9), (8, 8), (9, 10), (7, 11), (10, 9), (5, 8)]:
        px[ox + x, y] = BAT_D
    outline(px, W, H, ox, 0)
    img.save(os.path.join(OUT, "bat.png"))


# ---------------------------------------------------------------- bullets 8x8
def gen_bullet(name, core, edge):
    W = H = 8
    img = Image.new("RGBA", (W, H), T)
    px = img.load()
    for x, y in [(2, 3), (2, 4), (5, 3), (5, 4), (3, 2), (4, 2), (3, 5), (4, 5)]:
        px[x, y] = edge
    for x, y in [(3, 3), (4, 3), (3, 4), (4, 4)]:
        px[x, y] = core
    outline(px, W, H, 0, 0)
    img.save(os.path.join(OUT, name))


# ---------------------------------------------------------------- muzzle 8x8 x2
def gen_muzzle():
    W = H = 8
    img = new_sheet(2, W, H)
    px = img.load()
    blit(px, 1, 1, ["..y..", ".yYy.", "yYWYy", ".yYy.", "..y.."],
         {"y": YELLOW_D, "Y": YELLOW, "W": WHITE})
    blit(px, W + 2, 2, ["....", ".yY.", ".Yy.", "...."],
         {"y": YELLOW_D, "Y": YELLOW})
    img.save(os.path.join(OUT, "muzzle.png"))


# ---------------------------------------------------------------- coin 8x8 x4
def gen_coin():
    W = H = 8
    img = new_sheet(4, W, H)
    px = img.load()

    def coin(fi, width):
        ox = fi * W
        left = ox + 4 - width // 2
        for y in range(1, 7):
            for x in range(width):
                px[left + x, y] = GOLD if 1 < y < 6 else GOLD_D
        if width >= 4:
            px[left + 1, 2] = WHITE
        outline(px, W, H, ox, 0)

    coin(0, 6)
    coin(1, 4)
    coin(2, 2)
    coin(3, 4)
    img.save(os.path.join(OUT, "coin.png"))


# ---------------------------------------------------------------- heart 8x8
def gen_heart():
    W = H = 8
    img = Image.new("RGBA", (W, H), T)
    px = img.load()
    blit(px, 0, 1, [
        ".rr.rr.",
        "rRRrRRr",
        "rRRRRRr",
        ".rRRRr.",
        "..rRr..",
        "...r...",
    ], {"r": RED_D, "R": RED})
    px[2, 2] = WHITE
    outline(px, W, H, 0, 0)
    img.save(os.path.join(OUT, "heart.png"))


# ---------------------------------------------------------------- crate 16x16
def gen_crate():
    W = H = 16
    img = Image.new("RGBA", (W, H), T)
    px = img.load()
    for y in range(2, 15):
        for x in range(2, 15):
            px[x, y] = WOOD if (x + y) % 2 else WOOD_D
    for x in range(2, 15):
        px[x, 2] = WOOD_D
        px[x, 14] = WOOD_D
        px[x, 8] = WOOD_D
    blit(px, 5, 6, ["ggggg", "gG..g", "gg..."], {"g": GUN, "G": GUN_D})
    outline(px, W, H, 0, 0)
    img.save(os.path.join(OUT, "crate.png"))


# ---------------------------------------------------------------- tiles 16x16 x2
def gen_tiles():
    W = H = 16
    img = new_sheet(2, W, H)
    px = img.load()
    for y in range(H):
        for x in range(W):
            px[x, y] = FLOOR if (x // 4 + y // 4) % 2 == 0 else FLOOR_2
    for (x, y) in [(3, 5), (11, 9), (6, 12), (13, 3)]:
        px[x, y] = WALL_D
    ox = W
    for y in range(H):
        for x in range(W):
            px[ox + x, y] = WALL if y > 4 else WALL_TOP
    for x in range(W):
        px[ox + x, 4] = WALL_D
    for y in range(5, H, 4):
        for x in range(W):
            px[ox + x, y] = WALL_D
    img.save(os.path.join(OUT, "tiles.png"))


def main():
    gen_player()
    gen_slime()
    gen_bat()
    gen_bullet("bullet.png", YELLOW, YELLOW_D)
    gen_bullet("enemy_bullet.png", RED, RED_D)
    gen_muzzle()
    gen_coin()
    gen_heart()
    gen_crate()
    gen_tiles()
    print("Generated art in", OUT)
    for f in sorted(os.listdir(OUT)):
        if f.endswith(".png"):
            im = Image.open(os.path.join(OUT, f))
            print(f"  {f:20s} {im.size[0]}x{im.size[1]}")


if __name__ == "__main__":
    main()
