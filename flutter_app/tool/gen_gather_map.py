#!/usr/bin/env python3
"""
Generate a Gather.town-style office map using LimeZu Modern Office assets.
V2 — corrected tile mappings based on visual analysis.

Tilesets:
  1. Room Builder Office 48x48 (16×14 = 224 tiles, GID 1-224)
  2. Modern Office Black Shadow 48x48 (16×53 = 848 tiles, GID 225-1072)

The Room Builder floor+wall combo system (rows 5-12):
  Each style has 2 rows. Within each 2-row group:
    Cols 0-2 top row: [TL corner | Top edge | TR corner] — wall on top
    Cols 0-2 bot row: [BL corner | Bot edge | BR corner] — wall on bottom
    Col 3: plain floor fill tile (no walls)
    Cols 4-6: second wall style (same floor)
    Cols 7-9: third wall style (same floor)
    Cols 10-15: solid color floor fills (various materials)
"""

import json, shutil, os
from pathlib import Path

# ─── Paths ────────────────────────────────────────────────────────
ASSET_ROOT = Path(os.path.expanduser(
    "~/Downloads/Modern_Office_Revamped_v1.2"))
RB_SRC = ASSET_ROOT / "1_Room_Builder_Office/Room_Builder_Office_48x48.png"
BS_SRC = ASSET_ROOT / "2_Modern_Office_Black_Shadow/Modern_Office_Black_Shadow_48x48.png"
OUT_DIR = Path(__file__).resolve().parent.parent / "assets/images/tiled"

TILE = 48
RB_COLS, RB_ROWS = 16, 14
BS_COLS, BS_ROWS = 16, 53
RB_GID = 1
BS_GID = RB_COLS * RB_ROWS + 1  # 225

MAP_W, MAP_H = 48, 36


def rb(c, r):
    return RB_GID + r * RB_COLS + c

def bs(c, r):
    return BS_GID + r * BS_COLS + c

# ─── Floor+Wall combo tiles ──────────────────────────────────────
# Each "style" = 2 rows of Room Builder
# We use cols 0-2 for top edge, cols 0-2 of row+1 for bottom edge
# Col 3 for plain fill (or the center floor from cols 4-6)

class FloorStyle:
    def __init__(self, base_row, fill_col=3):
        r = base_row
        # Top edge (wall on top) — use first group (cols 0-2)
        self.top_l = rb(0, r)
        self.top_m = rb(1, r)
        self.top_r = rb(2, r)
        # Bottom edge (wall on bottom)
        self.bot_l = rb(0, r + 1)
        self.bot_m = rb(1, r + 1)
        self.bot_r = rb(2, r + 1)
        # Plain floor fill (no walls) — col 3 or use second group center
        self.fill = rb(fill_col, r)
        # Alternative fills — use the solid color floors on the right
        self.fill_alt = rb(5, r)  # second group center

# 4 floor styles
PURPLE_FLOOR = FloorStyle(5)    # rows 5-6: purple/lavender brick
GRAY_FLOOR   = FloorStyle(7)    # rows 7-8: gray stone
TAN_FLOOR    = FloorStyle(9)    # rows 9-10: tan/brown brick
LIGHT_FLOOR  = FloorStyle(11)   # rows 11-12: light lavender

# Solid floor fills (right side, various colors)
SOLID_GRAY_1    = rb(10, 7)   # dark gray
SOLID_GRAY_2    = rb(11, 7)   # medium gray
SOLID_TAN_1     = rb(14, 7)   # tan checkered
SOLID_DARK_GRAY = rb(10, 9)   # darker gray checkered
SOLID_BROWN     = rb(14, 9)   # brown
SOLID_RED       = rb(10, 11)  # wine/maroon
SOLID_DARK_RED  = rb(12, 11)  # dark red checkered

# ─── Furniture (Black Shadow tileset) ─────────────────────────────

# Cubicle partitions (beige desk dividers)
# Row 0-3: Various cubicle configurations (multi-tile)
CUBICLE_2x2_TL = bs(0, 0)
CUBICLE_2x2_TR = bs(1, 0)
CUBICLE_2x2_BL = bs(0, 1)
CUBICLE_2x2_BR = bs(1, 1)

# Office chairs — gray (row 8-9)
# Looking at catalog: row 8 has gray chairs in various orientations
CHAIR_GRAY_1 = bs(0, 8)    # chair variant 1
CHAIR_GRAY_2 = bs(1, 8)    # chair variant 2
CHAIR_GRAY_3 = bs(2, 8)    # chair facing different dir
CHAIR_GRAY_4 = bs(3, 8)    # another orientation
CHAIR_GRAY_5 = bs(4, 8)    # another
CHAIR_GRAY_6 = bs(5, 8)    # another

# More chairs (row 9)
CHAIR_SM_1 = bs(0, 9)
CHAIR_SM_2 = bs(1, 9)
CHAIR_SM_3 = bs(2, 9)
CHAIR_SM_4 = bs(3, 9)

# Executive chairs — orange/brown (row 10-11)
CHAIR_EXEC_1 = bs(0, 10)
CHAIR_EXEC_2 = bs(1, 10)
CHAIR_EXEC_3 = bs(2, 10)
CHAIR_EXEC_4 = bs(3, 10)
CHAIR_EXEC_5 = bs(4, 10)
CHAIR_EXEC_6 = bs(5, 10)

# Plants
PLANT_TALL_TOP = bs(4, 7)    # tall plant (top portion, occupies 1 tile)
PLANT_TALL_2   = bs(5, 11)   # another plant
PLANT_CACTUS   = bs(6, 13)   # small cactus/plant
PLANT_POT      = bs(7, 7)    # small potted

# Computers & monitors (row 13-14 right side)
MONITOR_1  = bs(13, 13)   # blue screen
MONITOR_2  = bs(14, 13)   # blue screen variant
MONITOR_3  = bs(15, 13)   # blue screen 3
LAPTOP     = bs(9, 13)    # small laptop/device
COMPUTER   = bs(15, 9)    # computer unit

# Desks — using the assembled desk pieces from lower rows
# Row 36-39: Desk surface tiles
DESK_TAN_TL  = bs(0, 36)   # tan desk surface top-left
DESK_TAN_TR  = bs(1, 36)
DESK_TAN_BL  = bs(0, 37)
DESK_TAN_BR  = bs(1, 37)

DESK_WHITE_TL = bs(2, 38)  # white/light desk
DESK_WHITE_TR = bs(3, 38)
DESK_WHITE_BL = bs(2, 39)
DESK_WHITE_BR = bs(3, 39)

DESK_GRAY_TL  = bs(2, 36)  # gray desk
DESK_GRAY_TR  = bs(3, 36)
DESK_GRAY_BL  = bs(2, 37)
DESK_GRAY_BR  = bs(3, 37)

# Complete desk+computer combos (rows 39, 42-43)
DESK_COMBO_1 = bs(7, 39)   # desk+chair+monitor combo south
DESK_COMBO_2 = bs(8, 39)   # variant
DESK_COMBO_3 = bs(9, 39)   # variant
DESK_COMBO_4 = bs(10, 39)  # variant
DESK_COMBO_5 = bs(11, 39)  # variant (orange chair)
DESK_COMBO_6 = bs(12, 39)  # variant
DESK_COMBO_7 = bs(13, 39)  # variant

# Desk combos facing north (row 42-43)
DESK_NORTH_1 = bs(7, 42)
DESK_NORTH_2 = bs(8, 42)
DESK_NORTH_3 = bs(9, 42)
DESK_NORTH_4 = bs(10, 42)

# Wall-mounted items
PICTURE_1    = bs(0, 12)   # photos/collage
PICTURE_2    = bs(1, 12)   # photo frame
WHITEBOARD_1 = bs(8, 13)   # whiteboard
WHITEBOARD_2 = bs(9, 14)   # chart
FRAME_ART_1  = bs(15, 0)   # wall art
FRAME_ART_2  = bs(15, 1)   # wall art 2

# Bookshelves (row 13 area, left side)
BOOKSHELF_L  = bs(6, 13)   # bookshelf left half
BOOKSHELF_R  = bs(7, 13)   # bookshelf right half

# Sofas (rows 18-19)
SOFA_TL = bs(0, 18)
SOFA_TR = bs(1, 18)
SOFA_BL = bs(0, 19)
SOFA_BR = bs(1, 19)

SOFA_SINGLE_L = bs(2, 19)  # smaller sofa piece
SOFA_SINGLE_R = bs(3, 19)

# Long counter/table (rows 27-28)
COUNTER_L = bs(0, 27)
COUNTER_M = bs(1, 27)
COUNTER_R = bs(2, 27)

# Filing cabinets (rows 23-24)
CABINET_T = bs(0, 23)
CABINET_B = bs(0, 24)

# Vending machines / appliances (rows 24-25)
VENDING_T = bs(1, 23)
VENDING_B = bs(1, 24)

PRINTER   = bs(5, 26)  # printer/copier

# Award / certificate
AWARD = bs(7, 7)

# Folder / papers
PAPERS_1 = bs(2, 12)
PAPERS_2 = bs(3, 12)

# Desk lamps (row 21)
LAMP_1 = bs(8, 21)
LAMP_2 = bs(9, 21)

# Backpacks / bags (row 48-50)
BAG_1 = bs(7, 48)   # blue backpack
BAG_2 = bs(8, 48)   # blue variant
BAG_3 = bs(9, 48)   # red/brown
BAG_4 = bs(10, 48)  # orange
BAG_5 = bs(11, 48)  # green/plant

# ─── Map data ─────────────────────────────────────────────────────
floor = [0] * (MAP_W * MAP_H)
walls = [0] * (MAP_W * MAP_H)
furn  = [0] * (MAP_W * MAP_H)
above = [0] * (MAP_W * MAP_H)

def s(layer, x, y, gid):
    if 0 <= x < MAP_W and 0 <= y < MAP_H:
        layer[y * MAP_W + x] = gid

def fill_rect(layer, x, y, w, h, gid):
    for dy in range(h):
        for dx in range(w):
            s(layer, x+dx, y+dy, gid)

def draw_room(style, x, y, w, h):
    """Draw room with wall-bordered edges and floor fill interior."""
    # Fill entire room with floor
    fill_rect(floor, x, y, w, h, style.fill)

    # Top wall edge
    s(walls, x, y, style.top_l)
    for dx in range(1, w-1):
        s(walls, x+dx, y, style.top_m)
    s(walls, x+w-1, y, style.top_r)

    # Bottom wall edge
    s(walls, x, y+h-1, style.bot_l)
    for dx in range(1, w-1):
        s(walls, x+dx, y+h-1, style.bot_m)
    s(walls, x+w-1, y+h-1, style.bot_r)

def door(x, y):
    """Clear wall tile at position to make a door."""
    s(walls, x, y, 0)

# ─── Desk pod helper ──────────────────────────────────────────────
def desk_pod(x, y, variant=0):
    """4-wide x 3-tall desk pod: chairs-desk-chairs.
    Uses the pre-made desk+chair combos for best visual.
    variant: 0=standard gray, 1=orange exec, 2=mixed
    """
    combos_s = [DESK_COMBO_1, DESK_COMBO_2, DESK_COMBO_3, DESK_COMBO_4]
    combos_n = [DESK_NORTH_1, DESK_NORTH_2, DESK_NORTH_3, DESK_NORTH_4]

    if variant == 1:
        combos_s = [DESK_COMBO_5, DESK_COMBO_6, DESK_COMBO_7, DESK_COMBO_1]

    # Top row: desk combos facing south (person looking at screen)
    for dx in range(min(4, len(combos_s))):
        s(furn, x+dx, y, combos_s[dx])

    # Middle row: desk surface
    s(furn, x, y+1, DESK_TAN_TL)
    s(furn, x+1, y+1, DESK_TAN_TR)
    s(furn, x+2, y+1, DESK_TAN_TL)
    s(furn, x+3, y+1, DESK_TAN_TR)

    # Bottom row: desk combos facing north
    for dx in range(min(4, len(combos_n))):
        s(furn, x+dx, y+2, combos_n[dx])


def desk_pair_v(x, y):
    """Vertical desk pair: 2 wide × 4 tall.
    Two desks facing each other with monitors.
    """
    # Top desk: desk surface + monitor
    s(furn, x, y, DESK_TAN_TL)
    s(furn, x+1, y, DESK_TAN_TR)
    s(furn, x, y+1, MONITOR_1)
    s(furn, x+1, y+1, LAPTOP)
    # Bottom desk: monitor + desk surface
    s(furn, x, y+2, MONITOR_2)
    s(furn, x+1, y+2, LAPTOP)
    s(furn, x, y+3, DESK_TAN_BL)
    s(furn, x+1, y+3, DESK_TAN_BR)


def meeting_table(x, y, w=4, h=2):
    """Meeting room table."""
    for dy in range(h):
        for dx in range(w):
            if dy == 0:
                s(furn, x+dx, y+dy, DESK_GRAY_TL if dx == 0 else DESK_GRAY_TR)
            else:
                s(furn, x+dx, y+dy, DESK_GRAY_BL if dx == 0 else DESK_GRAY_BR)


# ─── BUILD THE OFFICE ─────────────────────────────────────────────
def build():
    # === LOBBY (top, light floor) ===
    draw_room(LIGHT_FLOOR, 1, 1, 46, 6)

    # === OPEN OFFICE (main area, gray floor) ===
    draw_room(GRAY_FLOOR, 1, 6, 32, 17)

    # === BREAK ROOM (right-top, tan floor) ===
    draw_room(TAN_FLOOR, 32, 6, 15, 8)

    # === LOUNGE (right-bottom, purple floor) ===
    draw_room(PURPLE_FLOOR, 32, 13, 15, 10)

    # === HALLWAY (connecting strip) ===
    fill_rect(floor, 1, 22, 46, 2, GRAY_FLOOR.fill)
    # Top edge of hallway
    for dx in range(46):
        s(walls, 1+dx, 22, GRAY_FLOOR.top_m)

    # === MEETING ROOM 1 (bottom-left) ===
    draw_room(PURPLE_FLOOR, 1, 23, 12, 10)

    # === MEETING ROOM 2 (bottom-center) ===
    draw_room(PURPLE_FLOOR, 12, 23, 12, 10)

    # === MANAGER OFFICE 1 ===
    draw_room(TAN_FLOOR, 23, 23, 12, 10)

    # === MANAGER OFFICE 2 ===
    draw_room(TAN_FLOOR, 34, 23, 13, 10)

    # ── DOORS ──
    # Lobby → Open Office (wide opening)
    for dx in range(6):
        door(14+dx, 6)
    for dx in range(6):
        door(24+dx, 6)

    # Open Office → Break Room
    door(32, 8); door(32, 9)

    # Open Office → Lounge
    door(32, 15); door(32, 16)

    # Open Office → Hallway
    for dx in range(4):
        door(10+dx, 22)
    for dx in range(4):
        door(22+dx, 22)

    # Hallway → Meeting Room 1
    door(5, 23); door(6, 23)

    # Hallway → Meeting Room 2
    door(16, 23); door(17, 23)

    # Hallway → Manager Office 1
    door(27, 23); door(28, 23)

    # Hallway → Manager Office 2
    door(39, 23); door(40, 23)

    # ────────────────────────────
    # FURNITURE
    # ────────────────────────────

    # ── LOBBY ──
    # Reception desk (center)
    s(furn, 21, 3, DESK_WHITE_TL)
    s(furn, 22, 3, DESK_WHITE_TR)
    s(furn, 23, 3, DESK_WHITE_TL)
    s(furn, 24, 3, DESK_WHITE_TR)
    s(furn, 23, 4, CHAIR_GRAY_1)
    s(furn, 22, 4, MONITOR_1)

    # Lobby sofas (left area)
    s(furn, 3, 3, SOFA_TL); s(furn, 4, 3, SOFA_TR)
    s(furn, 3, 4, SOFA_BL); s(furn, 4, 4, SOFA_BR)

    s(furn, 7, 3, SOFA_TL); s(furn, 8, 3, SOFA_TR)
    s(furn, 7, 4, SOFA_BL); s(furn, 8, 4, SOFA_BR)

    # Lobby sofas (right area)
    s(furn, 36, 3, SOFA_TL); s(furn, 37, 3, SOFA_TR)
    s(furn, 36, 4, SOFA_BL); s(furn, 37, 4, SOFA_BR)

    s(furn, 40, 3, SOFA_TL); s(furn, 41, 3, SOFA_TR)
    s(furn, 40, 4, SOFA_BL); s(furn, 41, 4, SOFA_BR)

    # Plants throughout lobby
    for px in [2, 6, 12, 19, 26, 34, 39, 44]:
        s(furn, px, 2, PLANT_TALL_TOP)

    # Wall art in lobby
    s(above, 10, 1, FRAME_ART_1)
    s(above, 30, 1, FRAME_ART_2)
    s(above, 42, 1, PICTURE_1)

    # ── OPEN OFFICE — Desk Pods ──
    # Row 1 (y=8)
    desk_pod(3, 8)
    desk_pod(9, 8)
    desk_pod(16, 8)
    desk_pod(22, 8)

    # Row 2 (y=13)
    desk_pod(3, 13)
    desk_pod(9, 13)
    desk_pod(16, 13, variant=1)
    desk_pod(22, 13, variant=1)

    # Row 3 (y=18)
    desk_pod(3, 18)
    desk_pod(9, 18)
    desk_pod(16, 18)
    desk_pod(22, 18)

    # Decorations between rows
    for px in [28, 29]:
        s(furn, px, 8, PLANT_TALL_TOP)
        s(furn, px, 13, PLANT_TALL_TOP)
        s(furn, px, 18, PLANT_TALL_TOP)

    # Printers along right wall
    s(furn, 30, 9, PRINTER)
    s(furn, 30, 16, PRINTER)

    # ── BREAK ROOM ──
    # Counter/bar
    s(furn, 35, 8, COUNTER_L)
    s(furn, 36, 8, COUNTER_M)
    s(furn, 37, 8, COUNTER_M)
    s(furn, 38, 8, COUNTER_R)

    # Chairs at counter
    s(furn, 35, 9, CHAIR_GRAY_1)
    s(furn, 37, 9, CHAIR_GRAY_2)
    s(furn, 35, 7, CHAIR_GRAY_3)
    s(furn, 37, 7, CHAIR_GRAY_4)

    # Vending machines
    s(furn, 43, 7, VENDING_T); s(furn, 43, 8, VENDING_B)
    s(furn, 44, 7, CABINET_T); s(furn, 44, 8, CABINET_B)

    # Small table
    s(furn, 40, 10, DESK_TAN_TL); s(furn, 41, 10, DESK_TAN_TR)
    s(furn, 40, 11, CHAIR_GRAY_1); s(furn, 41, 11, CHAIR_GRAY_2)

    s(furn, 34, 11, PLANT_TALL_TOP)

    # ── LOUNGE ──
    # Sofas in L-shape
    s(furn, 34, 15, SOFA_TL); s(furn, 35, 15, SOFA_TR)
    s(furn, 34, 16, SOFA_BL); s(furn, 35, 16, SOFA_BR)

    s(furn, 38, 15, SOFA_TL); s(furn, 39, 15, SOFA_TR)
    s(furn, 38, 16, SOFA_BL); s(furn, 39, 16, SOFA_BR)

    # Coffee table
    s(furn, 36, 16, DESK_GRAY_TL); s(furn, 37, 16, DESK_GRAY_TR)

    # More seating
    s(furn, 42, 15, SOFA_TL); s(furn, 43, 15, SOFA_TR)
    s(furn, 42, 16, SOFA_BL); s(furn, 43, 16, SOFA_BR)

    # Bookshelf
    s(furn, 44, 14, BOOKSHELF_L); s(furn, 45, 14, BOOKSHELF_R)

    # Plants
    s(furn, 33, 14, PLANT_TALL_TOP)
    s(furn, 33, 19, PLANT_TALL_TOP)
    s(furn, 45, 19, PLANT_TALL_TOP)

    # Wall art
    s(above, 36, 13, PICTURE_2)
    s(above, 40, 13, FRAME_ART_1)

    # ── MEETING ROOM 1 ──
    meeting_table(4, 26, 5, 2)
    # Chairs around table
    for dx in range(5):
        s(furn, 4+dx, 25, CHAIR_GRAY_1)  # top row
        s(furn, 4+dx, 28, CHAIR_GRAY_3)  # bottom row
    # Whiteboard on wall
    s(above, 10, 24, WHITEBOARD_1)
    s(furn, 2, 30, PLANT_TALL_TOP)
    s(furn, 10, 30, PLANT_TALL_TOP)

    # ── MEETING ROOM 2 ──
    meeting_table(15, 26, 5, 2)
    for dx in range(5):
        s(furn, 15+dx, 25, CHAIR_GRAY_2)
        s(furn, 15+dx, 28, CHAIR_GRAY_4)
    s(above, 21, 24, WHITEBOARD_2)
    s(furn, 13, 30, PLANT_TALL_TOP)
    s(furn, 21, 30, PLANT_TALL_TOP)

    # ── MANAGER OFFICE 1 ──
    # Executive desk
    s(furn, 26, 25, CHAIR_EXEC_1)
    s(furn, 27, 25, CHAIR_EXEC_2)
    s(furn, 26, 26, DESK_WHITE_TL); s(furn, 27, 26, DESK_WHITE_TR)
    s(furn, 26, 27, MONITOR_1); s(furn, 27, 27, LAPTOP)
    # Bookshelf
    s(furn, 31, 24, BOOKSHELF_L); s(furn, 32, 24, BOOKSHELF_R)
    # Guest chairs
    s(furn, 26, 29, CHAIR_GRAY_1); s(furn, 28, 29, CHAIR_GRAY_2)
    # Plant
    s(furn, 24, 24, PLANT_TALL_TOP)
    s(furn, 33, 31, PLANT_TALL_TOP)
    s(above, 29, 23, FRAME_ART_2)

    # ── MANAGER OFFICE 2 ──
    s(furn, 38, 25, CHAIR_EXEC_3)
    s(furn, 39, 25, CHAIR_EXEC_4)
    s(furn, 38, 26, DESK_WHITE_TL); s(furn, 39, 26, DESK_WHITE_TR)
    s(furn, 38, 27, MONITOR_2); s(furn, 39, 27, LAPTOP)
    s(furn, 43, 24, BOOKSHELF_L); s(furn, 44, 24, BOOKSHELF_R)
    s(furn, 37, 29, CHAIR_GRAY_3); s(furn, 40, 29, CHAIR_GRAY_4)
    s(furn, 35, 24, PLANT_TALL_TOP)
    s(furn, 45, 31, PLANT_TALL_TOP)
    s(above, 41, 23, FRAME_ART_1)

    # ── SCATTERED DECORATIONS ──
    # Bags near desks (adds life)
    s(furn, 2, 9, BAG_1)
    s(furn, 2, 14, BAG_3)
    s(furn, 14, 9, BAG_2)
    s(furn, 14, 19, BAG_4)


# ─── NPC positions ────────────────────────────────────────────────
def get_npc_positions():
    """Positions at desk chairs (top of each desk pod = facing south)."""
    positions = []
    # Desk pods at y=8: top chairs at y=8, bottom at y=10
    for pod_x in [3, 9, 16, 22]:
        for dx in range(4):
            positions.append([pod_x+dx, 8])
    # Desk pods at y=13
    for pod_x in [3, 9, 16, 22]:
        for dx in range(4):
            positions.append([pod_x+dx, 13])
    # Take first 29
    return positions[:29]


# ─── Collision objects (basic outer walls) ────────────────────────
def get_collisions():
    objs = []
    oid = 1
    # We could add detailed collision per wall tile, but for now
    # just prevent walking outside the building
    for rect in [
        (0, 0, MAP_W*TILE, 1*TILE),        # top border
        (0, (MAP_H-1)*TILE, MAP_W*TILE, TILE), # bottom
        (0, 0, 1*TILE, MAP_H*TILE),         # left
        ((MAP_W-1)*TILE, 0, TILE, MAP_H*TILE), # right
    ]:
        objs.append({"id": oid, "x": rect[0], "y": rect[1],
                      "width": rect[2], "height": rect[3],
                      "rotation": 0, "visible": True, "type": ""})
        oid += 1
    return objs


# ─── Tiled JSON output ───────────────────────────────────────────
def generate():
    build()

    return {
        "compressionlevel": -1,
        "height": MAP_H, "width": MAP_W,
        "tileheight": TILE, "tilewidth": TILE,
        "infinite": False,
        "orientation": "orthogonal",
        "renderorder": "right-down",
        "tiledversion": "1.10.2",
        "type": "map", "version": "1.10",
        "nextlayerid": 6, "nextobjectid": 100,
        "tilesets": [
            {
                "columns": RB_COLS, "firstgid": RB_GID,
                "image": "room_builder_48.png",
                "imageheight": RB_ROWS * TILE, "imagewidth": RB_COLS * TILE,
                "margin": 0, "spacing": 0,
                "name": "room_builder",
                "tilecount": RB_COLS * RB_ROWS,
                "tileheight": TILE, "tilewidth": TILE,
            },
            {
                "columns": BS_COLS, "firstgid": BS_GID,
                "image": "office_furniture_48.png",
                "imageheight": BS_ROWS * TILE, "imagewidth": BS_COLS * TILE,
                "margin": 0, "spacing": 0,
                "name": "office_furniture",
                "tilecount": BS_COLS * BS_ROWS,
                "tileheight": TILE, "tilewidth": TILE,
            },
        ],
        "layers": [
            {"id":1, "name":"floor", "type":"tilelayer",
             "width":MAP_W, "height":MAP_H, "x":0, "y":0,
             "opacity":1, "visible":True, "data":floor},
            {"id":2, "name":"walls", "type":"tilelayer",
             "width":MAP_W, "height":MAP_H, "x":0, "y":0,
             "opacity":1, "visible":True, "data":walls},
            {"id":3, "name":"furniture", "type":"tilelayer",
             "width":MAP_W, "height":MAP_H, "x":0, "y":0,
             "opacity":1, "visible":True, "data":furn},
            {"id":4, "name":"above", "type":"tilelayer",
             "width":MAP_W, "height":MAP_H, "x":0, "y":0,
             "opacity":1, "visible":True, "data":above},
            {"id":5, "name":"collision", "type":"objectgroup",
             "draworder":"topdown", "x":0, "y":0,
             "opacity":1, "visible":True,
             "objects":get_collisions(), "class":"collision"},
        ],
    }


def main():
    print("Generating office map v2...")
    tiled = generate()

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # Copy tilesets
    for src, name in [(RB_SRC, "room_builder_48.png"), (BS_SRC, "office_furniture_48.png")]:
        dst = OUT_DIR / name
        shutil.copy2(src, dst)
        print(f"  {name} → {dst}")

    # Write JSON
    path = OUT_DIR / "office_map.json"
    with open(path, 'w') as f:
        json.dump(tiled, f)
    print(f"  office_map.json → {path}")

    # Stats
    for name, layer in [("floor", floor), ("walls", walls), ("furn", furn), ("above", above)]:
        used = sum(1 for t in layer if t)
        print(f"  {name}: {used} tiles")

    positions = get_npc_positions()
    print(f"  NPC seats: {len(positions)}")
    print("\n  const _agentPositions = [")
    for p in positions:
        print(f"    [{p[0]}, {p[1]}],")
    print("  ];")


if __name__ == "__main__":
    main()
