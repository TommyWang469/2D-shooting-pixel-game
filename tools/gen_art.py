#!/usr/bin/env python3
"""Generate all pixel-art sprite sheets for Pixel Dungeon Blaster.

Every sheet lays frames out horizontally so Godot can use Sprite2D.hframes.
Run:  python3 tools/gen_art.py
Output: new-game-project/assets/*.png
"""
import os
import math
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


# ---------------------------------------------------------------- heroes 16x16 x8
def gen_hero(fname, head_grid, C):
    """8-frame hero sheet (4 idle + 4 walk). head_grid = 6 rows of 10 chars;
    C maps grid keys to colors (needs b/B body, g/G gun, o boots)."""
    W = H = 16
    img = new_sheet(8, W, H)
    px = img.load()

    def draw(fi, bob, leg):
        ox = fi * W
        oy = bob
        blit(px, ox + 3, oy + 1, head_grid, C)
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
    img.save(os.path.join(OUT, fname))


def gen_heroes():
    # Gunner: blue hood, teal jacket (the original hero)
    gunner_head = [
        "...hhhh...",
        "..hhhhhh..",
        ".hhHHHHhh.",
        ".hssssssh.",
        ".hswwswsh.",
        "..ssssss..",
    ]
    gen_hero("player.png", gunner_head, {
        "h": HOOD, "H": HOOD_D, "s": SKIN, "w": WHITE,
        "b": BODY, "B": BODY_D, "g": GUN, "G": GUN_D, "o": BOOT,
    })

    # Knight: steel helmet with dark visor slit + red plume, steel armor
    STEEL = (176, 186, 204, 255)
    STEEL_D = (120, 130, 152, 255)
    PLUME = (220, 70, 80, 255)
    knight_head = [
        "....pp....",
        "..hhhhhh..",
        ".hhhhhhhh.",
        ".hHHHHHHh.",
        ".hhwhhwhh.",
        "..hhhhhh..",
    ]
    gen_hero("knight.png", knight_head, {
        "h": STEEL, "H": STEEL_D, "p": PLUME, "w": (90, 100, 120, 255),
        "b": STEEL, "B": STEEL_D, "g": GUN, "G": GUN_D, "o": BOOT,
    })

    # Rogue: deep-green hood, face in shadow with bright eyes, dark leathers
    RGRN = (70, 150, 90, 255)
    RGRN_D = (45, 105, 65, 255)
    RDARK = (40, 46, 52, 255)
    rogue_head = [
        "...hhhh...",
        "..hhhhhh..",
        ".hhhhhhhh.",
        ".hddddddh.",
        ".hdwddwdh.",
        "..hddddh..",
    ]
    gen_hero("rogue.png", rogue_head, {
        "h": RGRN, "H": RGRN_D, "d": RDARK, "w": (220, 250, 200, 255),
        "b": RGRN_D, "B": RDARK, "g": GUN, "G": GUN_D, "o": BOOT,
    })


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
    # also export standalone 16x16 floor + wall tiles for tiled room drawing
    img.crop((0, 0, W, H)).save(os.path.join(OUT, "floor.png"))
    img.crop((W, 0, 2 * W, H)).save(os.path.join(OUT, "wall.png"))


MAGE = (110, 120, 220, 255)
MAGE_D = (70, 80, 170, 255)
MAGE_HAT = (60, 60, 120, 255)
GEM = (120, 230, 240, 255)


# ---------------------------------------------------------------- mage 16x16 x4
def gen_mage():
    W = H = 16
    img = new_sheet(4, W, H)
    px = img.load()
    C = {"m": MAGE, "M": MAGE_D, "h": MAGE_HAT, "s": SKIN, "g": GEM,
         "w": WHITE, "k": BLACK}

    def draw(fi, arm_up, gem_bright):
        ox = fi * W
        # pointy hat
        hat = [
            "....h....",
            "...hhh...",
            "..hhhhh..",
            ".hhhhhhh.",
        ]
        blit(px, ox + 3, 1, hat, C)
        # face
        blit(px, ox + 5, 5, ["sss", "sws"], C)
        # robe
        robe = [
            ".mmmmm.",
            "mmMMMmm",
            "mmMMMmm",
            "mMMMMMm",
            ".mMMMm.",
        ]
        blit(px, ox + 4, 7, robe, C)
        # staff with gem (right side), raised when casting
        sy = 5 if arm_up else 7
        gcol = WHITE if gem_bright else GEM
        px[ox + 12, sy] = gcol
        px[ox + 12, sy + 1] = GEM
        for y in range(sy + 1, 13):
            px[ox + 12, y] = WOOD
        outline(px, W, H, ox, 0)

    draw(0, False, False)
    draw(1, False, True)
    draw(2, True, True)     # casting
    # death frame 3: crumpled robe
    ox = 3 * W
    for y in range(11, 15):
        for x in range(4, 12):
            if (x + y) % 2 == 0:
                px[ox + x, y] = MAGE_D
    outline(px, W, H, ox, 0)
    img.save(os.path.join(OUT, "mage.png"))


# ---------------------------------------------------------------- soft fx dots
def gen_shadow():
    W, H = 16, 8
    img = Image.new("RGBA", (W, H), T)
    px = img.load()
    cx, cy = 7.5, 3.5
    for y in range(H):
        for x in range(W):
            dx = (x - cx) / 7.5
            dy = (y - cy) / 3.5
            d = dx * dx + dy * dy
            if d <= 1.0:
                a = int((1.0 - d) * 110)
                px[x, y] = (0, 0, 0, a)
    img.save(os.path.join(OUT, "shadow.png"))


def gen_spark():
    S = 6
    img = Image.new("RGBA", (S, S), T)
    px = img.load()
    c = (S - 1) / 2.0
    for y in range(S):
        for x in range(S):
            d = math.hypot(x - c, y - c) / (c + 0.5)
            if d <= 1.0:
                a = int((1.0 - d) * 255)
                px[x, y] = (255, 255, 255, a)
    img.save(os.path.join(OUT, "spark.png"))


def gen_glow():
    S = 64
    img = Image.new("RGBA", (S, S), T)
    px = img.load()
    c = (S - 1) / 2.0
    for y in range(S):
        for x in range(S):
            d = math.hypot(x - c, y - c) / c
            if d <= 1.0:
                a = int((1.0 - d) ** 2 * 255)
                px[x, y] = (255, 255, 255, a)
    img.save(os.path.join(OUT, "glow.png"))


# ---------------------------------------------------------------- imp 16x16 x4
def gen_imp():
    W = H = 16
    img = new_sheet(4, W, H)
    px = img.load()
    ORG = (235, 120, 60, 255)
    ORG_D = (180, 80, 40, 255)
    HORN = (120, 40, 30, 255)

    def draw(fi, crouch, legs_apart):
        ox = fi * W
        oy = 2 if crouch else 0
        # horns
        px[ox + 5, 3 + oy] = HORN
        px[ox + 10, 3 + oy] = HORN
        px[ox + 5, 2 + oy] = HORN
        px[ox + 10, 2 + oy] = HORN
        # head+body blob
        for y in range(4 + oy, 11):
            for x in range(5, 11):
                px[ox + x, y] = ORG if y < 9 else ORG_D
        # eyes (bright when winding up)
        ec = WHITE if not crouch else YELLOW
        px[ox + 6, 6 + oy] = ec
        px[ox + 9, 6 + oy] = ec
        # tail
        px[ox + 11, 9] = ORG_D
        px[ox + 12, 8] = ORG_D
        # legs
        if legs_apart:
            blit(px, ox + 5, 11, ["o...o", "o...o"], {"o": ORG_D})
        else:
            blit(px, ox + 6, 11, ["o.o", "o.o"], {"o": ORG_D})
        outline(px, W, H, ox, 0)

    draw(0, False, True)
    draw(1, False, False)
    draw(2, True, False)          # windup crouch
    ox = 3 * W                     # death splat
    for x, y in [(5, 12), (7, 11), (9, 13), (10, 11), (6, 13), (11, 12)]:
        px[ox + x, y] = ORG_D
    outline(px, W, H, ox, 0)
    img.save(os.path.join(OUT, "imp.png"))


# ---------------------------------------------------------------- spitter 16x16 x3
def gen_spitter():
    W = H = 16
    img = new_sheet(3, W, H)
    px = img.load()
    RK = (140, 110, 95, 255)
    RK_D = (95, 72, 62, 255)
    LAVA = (255, 140, 50, 255)
    LAVA_B = (255, 210, 90, 255)

    def mound(ox, mouth_open):
        for y in range(6, 14):
            half = min(6, (y - 4))
            for x in range(8 - half, 8 + half):
                px[ox + x, y] = RK if (x + y) % 2 else RK_D
        # lava cracks
        for (cx, cy) in [(5, 11), (10, 9), (7, 12)]:
            px[ox + cx, cy] = LAVA
        # mouth
        if mouth_open:
            for y in range(8, 11):
                for x in range(6, 10):
                    px[ox + x, y] = LAVA
            px[ox + 7, 9] = LAVA_B
            px[ox + 8, 9] = LAVA_B
        else:
            for x in range(6, 10):
                px[ox + x, 9] = RK_D
        outline(px, W, H, ox, 0)

    mound(0, False)
    mound(W, True)
    ox = 2 * W                     # death rubble
    for x, y in [(4, 12), (6, 13), (8, 11), (10, 13), (11, 12), (7, 12)]:
        px[ox + x, y] = RK_D
    outline(px, W, H, ox, 0)
    img.save(os.path.join(OUT, "spitter.png"))


# ---------------------------------------------------------------- ghost 16x16 x3
def gen_ghost():
    W = H = 16
    img = new_sheet(3, W, H)
    px = img.load()
    GH = (205, 225, 255, 255)
    GH_D = (150, 180, 230, 255)

    def sheet(ox, wave):
        # rounded head
        for y in range(3, 8):
            for x in range(5, 11):
                px[ox + x, y] = GH
        px[ox + 4, 5] = GH
        px[ox + 11, 5] = GH
        # body tapering with wavy hem
        for y in range(8, 12):
            for x in range(5, 11):
                px[ox + x, y] = GH if y < 10 else GH_D
        hem = [(5, 12), (7, 13), (9, 12)] if wave == 0 else [(6, 13), (8, 12), (10, 13)]
        for (hx, hy) in hem:
            px[ox + hx, hy] = GH_D
        # eyes + mouth
        px[ox + 6, 5] = (40, 50, 80, 255)
        px[ox + 9, 5] = (40, 50, 80, 255)
        px[ox + 7, 7] = GH_D
        px[ox + 8, 7] = GH_D
        outline(px, W, H, ox, 0, (110, 140, 190, 255))

    sheet(0, 0)
    sheet(W, 1)
    ox = 2 * W                     # dissipating wisps
    for x, y in [(6, 6), (9, 5), (7, 9), (10, 8), (5, 10), (8, 11)]:
        px[ox + x, y] = GH_D
    img.save(os.path.join(OUT, "ghost.png"))


# ---------------------------------------------------------------- ice slime 16x16 x4
def gen_ice_slime():
    W = H = 16
    img = new_sheet(4, W, H)
    px = img.load()
    ICE = (150, 220, 245, 255)
    ICE_D = (95, 165, 210, 255)
    ICE_L = (225, 250, 255, 255)

    def crystal(fi, squash):
        ox = fi * W
        top = 7 + squash
        # angular faceted body (triangle-ish stack)
        for y in range(top, 15):
            spread = min(6, y - top + 2)
            for x in range(8 - spread, 8 + spread):
                px[ox + x, y] = ICE if y < 13 else ICE_D
        # facet highlights
        px[ox + 6, top + 2] = ICE_L
        px[ox + 7, top + 1] = ICE_L
        px[ox + 9, top + 3] = ICE_L
        # crystal spike on top
        px[ox + 8, top - 1] = ICE_L
        px[ox + 8, top - 2] = ICE
        # eyes
        px[ox + 6, top + 4] = BLACK
        px[ox + 10, top + 4] = BLACK
        outline(px, W, H, ox, 0)

    crystal(0, 0)
    crystal(1, 1)
    crystal(2, -1)
    ox = 3 * W                     # shatter
    for x, y in [(4, 12), (6, 10), (8, 13), (10, 11), (12, 12), (7, 12), (9, 9)]:
        px[ox + x, y] = ICE_D
    outline(px, W, H, ox, 0)
    img.save(os.path.join(OUT, "ice_slime.png"))


# ---------------------------------------------------------------- boss 32x32 x4
def gen_boss():
    W = H = 32
    img = new_sheet(4, W, H)
    px = img.load()

    def draw(fi, squash, glow):
        ox = fi * W
        top = 10 + squash
        bw = 24 - squash
        left = ox + (W - bw) // 2
        for y in range(top, 29):
            for x in range(bw):
                col = SLIME if y < 25 else SLIME_D
                if glow and (x + y) % 3 == 0:
                    col = (200, 255, 160, 255)
                px[left + x, y] = col
        # highlight
        for x in range(3, 9):
            px[left + x, top + 2] = SLIME_L
        # crown
        crown = ["y.y.y.y", "yyyyyyy"]
        blit(px, left + bw // 2 - 3, top - 3, crown, {"y": GOLD})
        for x in range(bw // 2 - 3, bw // 2 + 4):
            px[ox + (W - bw) // 2 + x, top - 1] = GOLD_D
        # angry eyes
        ey = top + 6
        for e in (left + 6, left + bw - 8):
            px[e, ey] = WHITE
            px[e + 1, ey] = WHITE
            px[e, ey + 1] = RED if glow else BLACK
            px[e + 1, ey + 1] = RED if glow else BLACK
        # mouth
        for x in range(left + 9, left + bw - 8):
            px[x, top + 11] = BLACK
        outline(px, W, H, ox, 0)

    draw(0, 0, False)
    draw(1, 3, False)
    draw(2, -1, True)     # attacking / charged
    # death frame 3: collapsed puddle
    ox = 3 * W
    for y in range(24, 30):
        for x in range(4, 28):
            if (x + y) % 2 == 0:
                px[ox + x, y] = SLIME_D
    for x in range(6, 26):
        px[ox + x, 27] = SLIME
    outline(px, W, H, ox, 0)
    img.save(os.path.join(OUT, "boss.png"))
    img.save(os.path.join(OUT, "boss_stone.png"))   # Summoner King (stone biome)


# ------------------------------------------------- ember boss 32x32 x4 (Magma Tyrant)
def gen_boss_ember():
    W = H = 32
    img = new_sheet(4, W, H)
    px = img.load()
    ROCK = (74, 44, 40, 255)
    ROCK_D = (52, 30, 28, 255)
    LAVA = (255, 140, 40, 255)
    LAVA_B = (255, 210, 90, 255)

    def draw(fi, bob, rage):
        ox = fi * W
        top = 8 + bob
        # horns
        for i in range(5):
            px[ox + 6 - i // 2, top - 1 - i] = ROCK_D
            px[ox + 25 + i // 2, top - 1 - i] = ROCK_D
        # bulky body
        for y in range(top, 29):
            wdt = 20 if y < top + 8 else 24
            left = ox + (W - wdt) // 2
            for x in range(wdt):
                col = ROCK if (x + y) % 2 else ROCK_D
                # lava cracks
                if (x * 3 + y * 5) % 11 == 0:
                    col = LAVA_B if rage else LAVA
                px[left + x, y] = col
        # burning eyes
        ey = top + 5
        for e in (ox + 10, ox + 19):
            px[e, ey] = LAVA_B
            px[e + 1, ey] = LAVA_B
            px[e, ey + 1] = LAVA if not rage else LAVA_B
            px[e + 1, ey + 1] = LAVA if not rage else LAVA_B
        # molten mouth
        for x in range(ox + 12, ox + 20):
            px[x, top + 11] = LAVA if rage else BLACK
        # fists
        for fy in range(3):
            for fx in range(3):
                px[ox + 3 + fx, top + 12 + fy] = ROCK_D
                px[ox + 26 + fx, top + 12 + fy] = ROCK_D
        outline(px, W, H, ox, 0)

    draw(0, 0, False)
    draw(1, 1, False)
    draw(2, 0, True)      # attacking: cracks + mouth flare
    # death frame: crumbled smoking rubble
    ox = 3 * W
    for y in range(22, 30):
        for x in range(4, 28):
            if (x * 3 + y) % 4 != 0:
                px[ox + x, y] = ROCK_D if (x + y) % 2 else ROCK
    for x, y in [(9, 24), (16, 23), (23, 25), (13, 27)]:
        px[ox + x, y] = LAVA
    outline(px, W, H, ox, 0)
    img.save(os.path.join(OUT, "boss_ember.png"))


# ------------------------------------------------- frost boss 32x32 x4 (Frozen Warden)
def gen_boss_frost():
    W = H = 32
    img = new_sheet(4, W, H)
    px = img.load()
    ICE = (150, 200, 240, 255)
    ICE_D = (95, 140, 195, 255)
    ICE_L = (215, 240, 255, 255)
    CORE = (60, 90, 150, 255)

    def draw(fi, bob, glow):
        ox = fi * W
        top = 6 + bob
        # crown of crystal spikes
        for sx, h in ((9, 4), (13, 6), (17, 6), (21, 4)):
            for i in range(h):
                px[ox + sx + (0 if i < h - 1 else 0), top + 2 - i] = ICE_L if glow else ICE
        # tall angular body (tapers to the base)
        for y in range(top + 2, 30):
            t = (y - top) / 26.0
            wdt = int(18 - 6 * abs(t - 0.35) * 2)
            left = ox + (W - wdt) // 2
            for x in range(wdt):
                col = ICE if (x + y) % 2 else ICE_D
                # inner dark core column
                if abs((left + x) - (ox + W // 2)) < 3 and y > top + 8:
                    col = CORE
                px[left + x, y] = col
        # facets
        for x, y in [(11, top + 7), (20, top + 9), (14, top + 15), (18, top + 20)]:
            px[ox + x, y] = ICE_L
        # glowing eyes
        ey = top + 6
        for e in (ox + 12, ox + 18):
            px[e, ey] = ICE_L
            px[e + 1, ey] = ICE_L if glow else ICE
            px[e, ey + 1] = (140, 255, 255, 255) if glow else CORE
        outline(px, W, H, ox, 0)

    draw(0, 0, False)
    draw(1, 1, False)
    draw(2, 0, True)      # attacking: bright crown + eyes
    # death frame: shattered shards on the ground
    ox = 3 * W
    for x, y, s in [(7, 26, 2), (12, 24, 3), (18, 27, 2), (23, 25, 3), (15, 28, 2), (26, 28, 1)]:
        for dy in range(s):
            for dx in range(s - dy):
                px[ox + x + dx, y - dy] = ICE if (dx + dy) % 2 else ICE_L
    outline(px, W, H, ox, 0)
    img.save(os.path.join(OUT, "boss_frost.png"))


# ---------------------------------------------------------------- portal 24x24 x4
def gen_portal():
    W = H = 24
    img = new_sheet(4, W, H)
    px = img.load()
    c = 11.5
    cols = [(120, 90, 230, 255), (150, 120, 250, 255),
            (190, 160, 255, 255), (230, 220, 255, 255)]
    for fi in range(4):
        ox = fi * W
        for y in range(H):
            for x in range(W):
                d = math.hypot(x - c, y - c)
                if d <= 11.0:
                    ring = int(d - fi) % 4
                    if ring < len(cols) and (d < 11.0):
                        alpha = max(0, min(255, int((11.0 - d) / 11.0 * 255) + 40))
                        col = cols[ring]
                        px[ox + x, y] = (col[0], col[1], col[2], alpha)
    img.save(os.path.join(OUT, "portal.png"))


# ---------------------------------------------------------------- chest 16x16 x2
def gen_chest():
    W = H = 16
    img = new_sheet(2, W, H)
    px = img.load()

    def base(ox, lid_open):
        # box body
        for y in range(8, 14):
            for x in range(3, 13):
                px[ox + x, y] = WOOD if (x + y) % 2 else WOOD_D
        # gold trim + lock
        for x in range(3, 13):
            px[ox + x, 10] = GOLD_D
        px[ox + 7, 11] = GOLD
        px[ox + 8, 11] = GOLD
        # lid
        if lid_open:
            for x in range(3, 13):
                px[ox + x, 3] = WOOD_D
                px[ox + x, 4] = WOOD
            # glow spilling out
            for x in range(5, 11):
                px[ox + x, 6] = (255, 240, 150, 255)
                px[ox + x, 7] = (255, 220, 110, 255)
        else:
            for y in range(4, 8):
                for x in range(3, 13):
                    px[ox + x, y] = WOOD if (x + y) % 2 else WOOD_D
            for x in range(3, 13):
                px[ox + x, 4] = GOLD_D
        outline(px, W, H, ox, 0)

    base(0, False)
    base(W, True)
    img.save(os.path.join(OUT, "chest.png"))


# ---------------------------------------------------------------- weapon icon 12x8
def gen_weapon_icon():
    # White/gray gun silhouette; tinted per-weapon by bullet_color in engine.
    W, H = 12, 8
    img = Image.new("RGBA", (W, H), T)
    px = img.load()
    grid = [
        ".gggggggg..",
        "gWWWWWWWWg.",
        "gWWWWWWWWgg",
        "ggggggWWWg.",
        "...gWWg....",
        "...gWWg....",
        "...gggg....",
    ]
    blit(px, 0, 0, grid, {"W": (245, 245, 245, 255), "g": (200, 200, 200, 255)})
    outline(px, W, H, 0, 0)
    img.save(os.path.join(OUT, "weapon_icon.png"))


# ---------------------------------------------------------------- torch 8x16
def gen_torch():
    W, H = 8, 16
    img = Image.new("RGBA", (W, H), T)
    px = img.load()
    # bracket / pole
    for y in range(6, 14):
        px[3, y] = WOOD_D
        px[4, y] = WOOD
    # holder cup
    blit(px, 2, 5, ["gggg"], {"g": GUN_D})
    # ember top (flame drawn by particles in-engine, this is the glowing coal)
    blit(px, 2, 2, [".oo.", "oOOo", "oOOo", ".oo."],
         {"o": (240, 140, 40, 255), "O": (255, 210, 90, 255)})
    outline(px, W, H, 0, 0)
    img.save(os.path.join(OUT, "torch.png"))


# ---------------------------------------------------------------- gem 8x8 x4
def gen_gem():
    # Persistent-currency crystal: cyan diamond with a magenta core, 4 sparkle frames.
    W = H = 8
    img = new_sheet(4, W, H)
    px = img.load()
    CY = (90, 230, 240, 255)
    CY_D = (40, 150, 190, 255)
    MG = (220, 120, 240, 255)

    def gem(fi, spark):
        ox = fi * W
        blit(px, ox + 1, 1, [
            "..cc..",
            ".cCCc.",
            "cCmmCc",
            ".cCCc.",
            "..cc..",
            "...c..",
        ], {"c": CY_D, "C": CY, "m": MG})
        if spark == 1:
            px[ox + 2, 2] = WHITE
        elif spark == 2:
            px[ox + 5, 3] = WHITE
        elif spark == 3:
            px[ox + 3, 5] = WHITE
        outline(px, W, H, ox, 0)

    for i in range(4):
        gem(i, i)
    img.save(os.path.join(OUT, "gem.png"))


# ---------------------------------------------------------------- crosshair 15x15
def gen_crosshair():
    # Open-center crosshair cursor: 4 ticks + corner dots, white with dark outline.
    W = H = 15
    img = Image.new("RGBA", (W, H), T)
    px = img.load()
    c = W // 2
    for i in range(2, 6):
        px[c, i] = WHITE            # top tick
        px[c, H - 1 - i] = WHITE    # bottom
        px[i, c] = WHITE            # left
        px[W - 1 - i, c] = WHITE    # right
    px[c, c] = (255, 255, 255, 90)  # faint center dot
    outline(px, W, H, 0, 0)
    img.save(os.path.join(OUT, "crosshair.png"))


# ---------------------------------------------------------------- app icon 128x128
def gen_icon():
    # Window/app icon: gunner hero frame 0 on a dark rounded tile, 8x nearest upscale.
    tile = Image.new("RGBA", (16, 16), (26, 22, 38, 255))
    tpx = tile.load()
    for x, y in [(0, 0), (15, 0), (0, 15), (15, 15)]:
        tpx[x, y] = T               # knock out corners for a rounded feel
    hero = Image.open(os.path.join(OUT, "player.png")).crop((0, 0, 16, 16))
    tile.alpha_composite(hero)
    tile.resize((128, 128), Image.NEAREST).save(os.path.join(OUT, "icon.png"))


def main():
    gen_heroes()
    gen_imp()
    gen_spitter()
    gen_ghost()
    gen_ice_slime()
    gen_slime()
    gen_bat()
    gen_mage()
    gen_bullet("bullet.png", YELLOW, YELLOW_D)
    gen_bullet("enemy_bullet.png", RED, RED_D)
    gen_muzzle()
    gen_coin()
    gen_heart()
    gen_crate()
    gen_tiles()
    gen_shadow()
    gen_spark()
    gen_glow()
    gen_boss()
    gen_boss_ember()
    gen_boss_frost()
    gen_portal()
    gen_chest()
    gen_weapon_icon()
    gen_torch()
    gen_gem()
    gen_crosshair()
    gen_icon()
    print("Generated art in", OUT)
    for f in sorted(os.listdir(OUT)):
        if f.endswith(".png"):
            im = Image.open(os.path.join(OUT, f))
            print(f"  {f:20s} {im.size[0]}x{im.size[1]}")


if __name__ == "__main__":
    main()
