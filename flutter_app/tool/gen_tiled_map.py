#!/usr/bin/env python3
"""
Generate a professional virtual office Tiled JSON map using LimeZu Modern Interiors assets.

Uses two tilesets:
  1. Room_Builder_16x16.png (76 cols × 113 rows) — walls, floors
  2. Interiors_16x16.png (16 cols × 1064 rows) — furniture, decor

Map layout (gather.town style):
  ┌──────────┬────────────────────────────────────┬──────────┐
  │ Lounge   │     Open Plan Workspace A           │ Meeting  │
  │  Area    │     (desks with computers)          │  Room 1  │
  │          │                                     │          │
  ├──────────┤                                     ├──────────┤
  │          │                                     │          │
  │ Kitchen  ├────────────────────────────────────┤ Meeting  │
  │ & Break  │     Open Plan Workspace B           │  Room 2  │
  │          │     (desks with computers)          │          │
  ├──────────┤                                     ├──────────┤
  │ Recep-   │                                     │ Server   │
  │  tion    │     Hallway / Lobby                 │  Room    │
  └──────────┴────────────────────────────────────┴──────────┘

Also generates character spritesheets for player and NPCs from LimeZu legacy characters.
"""

import json
import os
import shutil
from PIL import Image

# ─── Paths ────────────────────────────────────────────────────────────
LIMEZ_DIR = '/Users/Apple/Downloads/moderninteriors-win'
ROOM_BUILDER = os.path.join(LIMEZ_DIR, '1_Interiors/16x16/Room_Builder_16x16.png')
INTERIORS = os.path.join(LIMEZ_DIR, '1_Interiors/16x16/Interiors_16x16.png')
CHAR_DIR = os.path.join(LIMEZ_DIR, '2_Characters/Old/Single_Characters_Legacy/16x16')

FLUTTER_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_TILED = os.path.join(FLUTTER_DIR, 'assets/images/tiled')
OUT_PLAYER = os.path.join(FLUTTER_DIR, 'assets/images/player')
OUT_NPC = os.path.join(FLUTTER_DIR, 'assets/images/npc')
OUT_MAP = os.path.join(OUT_TILED, 'office_map.json')

TILE = 16

# ─── Tileset constants ─────────────────────────────────────────────────
RB_COLS = 76   # Room_Builder columns
RB_ROWS = 113
INT_COLS = 16  # Interiors columns
INT_ROWS = 1064

# GID offsets in Tiled JSON
RB_FIRSTGID = 1
INT_FIRSTGID = RB_COLS * RB_ROWS + 1  # 8589

# ─── Map dimensions ───────────────────────────────────────────────────
MAP_W = 48  # tiles wide
MAP_H = 36  # tiles tall


def rb_gid(col, row):
    """Room_Builder tile → GID."""
    return RB_FIRSTGID + row * RB_COLS + col


def int_gid(col, row):
    """Interiors tile → GID."""
    return INT_FIRSTGID + row * INT_COLS + col


# ─── Tile shortcuts (from reverse-engineering LimeZu pre-built designs) ──

# Floors (Room_Builder)
FLOOR_WOOD = rb_gid(35, 40)        # Main wood floor
FLOOR_WOOD_LIGHT = rb_gid(35, 39)  # Lighter wood variant
FLOOR_STONE = rb_gid(47, 43)       # Kitchen/stone floor
FLOOR_STONE_EDGE_L = rb_gid(46, 43)
FLOOR_STONE_EDGE_R = rb_gid(48, 43)
FLOOR_STONE_BOT = rb_gid(47, 44)
FLOOR_STONE_BL = rb_gid(46, 44)
FLOOR_STONE_BR = rb_gid(48, 44)

# Walls (Room_Builder) — top-facing wall segments
WALL_TOP_L = rb_gid(56, 56)       # Wall face (top part) - horizontal run
WALL_TOP_R = rb_gid(56, 56)       # Same tile for middle sections
WALL_BOT_L = rb_gid(56, 57)       # Wall face (bottom part)
WALL_BOT_R = rb_gid(56, 57)

# Wall corners and edges
WALL_OUTER_TL_TOP = rb_gid(52, 54)
WALL_OUTER_TL_BOT = rb_gid(52, 55)
WALL_OUTER_TR_TOP = rb_gid(57, 54)
WALL_OUTER_TR_BOT = rb_gid(57, 55)
WALL_OUTER_BL_TOP = rb_gid(52, 57)
WALL_OUTER_BL_BOT = rb_gid(52, 58)
WALL_OUTER_BR_TOP = rb_gid(57, 57)
WALL_OUTER_BR_BOT = rb_gid(57, 58)

# Inner corners
WALL_INNER_TL_TOP = rb_gid(54, 55)
WALL_INNER_TL_BOT = rb_gid(54, 57)
WALL_INNER_TR_BOT = rb_gid(57, 57)

# Vertical wall segments
WALL_LEFT_TOP = rb_gid(52, 57)
WALL_LEFT_BOT = rb_gid(52, 58)
WALL_RIGHT_TOP = rb_gid(58, 59)
WALL_RIGHT_BOT = rb_gid(58, 59)

# Side wall runs
WALL_SIDE_L = rb_gid(53, 59)   # Left wall vertical run
WALL_SIDE_R = rb_gid(58, 59)   # Right wall vertical run

# Door
DOOR_TOP = rb_gid(52, 49)
DOOR_BOT = rb_gid(55, 41)

# ─── Furniture (Interiors) ───────────────────────────────────────────
# Desk with computer (2×2 tiles)
DESK_TL = int_gid(11, 823)
DESK_TR = int_gid(12, 823)
DESK_BL = int_gid(11, 824)
DESK_BR = int_gid(12, 824)

# Chair facing down
CHAIR_TOP = int_gid(10, 33)
CHAIR_BOT = int_gid(9, 34)

# Bookshelf (3×3)
SHELF_TL = int_gid(6, 749)
SHELF_TM = int_gid(4, 749)
SHELF_TR = int_gid(5, 749)
SHELF_ML = int_gid(3, 750)
SHELF_MM = int_gid(4, 750)
SHELF_MR = int_gid(5, 750)
SHELF_BL = int_gid(3, 750)  # reuse middle
SHELF_BM = int_gid(4, 751)
SHELF_BR = int_gid(5, 751)

# Tall cabinet/shelf
CABINET_TOP = int_gid(2, 603)
CABINET_MID = int_gid(2, 604)
CABINET_BOT = int_gid(2, 605)

# Wall art
WALL_ART = int_gid(4, 218)

# Window
WINDOW_TL = int_gid(12, 646)
WINDOW_TR = int_gid(13, 646)
WINDOW_BL = int_gid(12, 647)
WINDOW_BR = int_gid(13, 647)

# Conference table (3 wide)
CONF_L = int_gid(6, 772)
CONF_M = int_gid(7, 772)  # Use int_gid(7,731) for single piece
CONF_R = int_gid(8, 772)

# Plants (from Generic theme)
PLANT_TL = int_gid(0, 5)
PLANT_TR = int_gid(1, 5)
PLANT_BL = int_gid(0, 6)
PLANT_BR = int_gid(1, 6)

# Small plant / potted plant
SMALL_PLANT_T = int_gid(3, 5)
SMALL_PLANT_B = int_gid(3, 6)

# Sofa (from Generic)
SOFA_L = int_gid(9, 5)
SOFA_R = int_gid(10, 5)
SOFA_LB = int_gid(9, 6)
SOFA_RB = int_gid(10, 6)

# Rug / carpet pieces (from Generic rows ~200+)
RUG_TL = int_gid(11, 200)
RUG_TM = int_gid(12, 200)
RUG_TR = int_gid(13, 200)
RUG_ML = int_gid(11, 201)
RUG_MM = int_gid(12, 201)
RUG_MR = int_gid(13, 201)
RUG_BL = int_gid(11, 202)
RUG_BM = int_gid(12, 202)
RUG_BR = int_gid(13, 202)

# Conference chairs (from Conference Hall theme)
CONF_CHAIR_L_T = int_gid(1, 314)
CONF_CHAIR_L_B = int_gid(1, 315)
CONF_CHAIR_R_T = int_gid(2, 314)
CONF_CHAIR_R_B = int_gid(2, 315)

# Conference table segments
CONF_TABLE_T = int_gid(6, 317)
CONF_TABLE_M = int_gid(6, 318)
CONF_TABLE_B = int_gid(6, 319)
CONF_TABLE_T2 = int_gid(7, 317)
CONF_TABLE_M2 = int_gid(7, 318)
CONF_TABLE_B2 = int_gid(7, 319)

# Kitchen items
FRIDGE_T = int_gid(14, 478)
FRIDGE_B = int_gid(14, 479)
FRIDGE_T2 = int_gid(15, 479)

# Sink/counter (from Kitchen theme row ~132)
COUNTER_T = int_gid(12, 132)
COUNTER_B = int_gid(12, 133)

# ─── Map building ─────────────────────────────────────────────────────

def create_empty_layer(name, data=None):
    """Create a Tiled tile layer."""
    return {
        "id": 0,  # will be set later
        "name": name,
        "type": "tilelayer",
        "x": 0, "y": 0,
        "width": MAP_W,
        "height": MAP_H,
        "opacity": 1,
        "visible": True,
        "data": data or [0] * (MAP_W * MAP_H),
    }


def set_tile(layer, x, y, gid):
    """Set a tile in the layer data."""
    if 0 <= x < MAP_W and 0 <= y < MAP_H:
        layer["data"][y * MAP_W + x] = gid


def fill_rect(layer, x, y, w, h, gid):
    """Fill a rectangle with a single tile."""
    for dy in range(h):
        for dx in range(w):
            set_tile(layer, x + dx, y + dy, gid)


def place_wall_box(walls_layer, x, y, w, h):
    """Place a room's wall outline (2 tiles tall for top wall, 1 tile for sides)."""
    # Top wall (2 tiles tall)
    for dx in range(w):
        set_tile(walls_layer, x + dx, y, rb_gid(56, 56))      # wall top part
        set_tile(walls_layer, x + dx, y + 1, rb_gid(56, 57))   # wall bottom part

    # Corners - top left
    set_tile(walls_layer, x, y, rb_gid(52, 54))
    set_tile(walls_layer, x, y + 1, rb_gid(52, 55))
    # Corners - top right
    set_tile(walls_layer, x + w - 1, y, rb_gid(57, 54))
    set_tile(walls_layer, x + w - 1, y + 1, rb_gid(57, 55))

    # Side walls
    for dy in range(2, h):
        set_tile(walls_layer, x, y + dy, rb_gid(53, 59))       # left wall
        set_tile(walls_layer, x + w - 1, y + dy, rb_gid(58, 59))  # right wall

    # Bottom wall
    for dx in range(1, w - 1):
        set_tile(walls_layer, x + dx, y + h - 1, rb_gid(53, 59))

    # Bottom corners
    set_tile(walls_layer, x, y + h - 1, rb_gid(52, 57))
    set_tile(walls_layer, x + w - 1, y + h - 1, rb_gid(57, 57))


def place_desk_pod(furniture_layer, x, y, facing_down=True):
    """Place a 2×2 desk with computer. Agent sits on the chair side."""
    set_tile(furniture_layer, x, y, DESK_TL)
    set_tile(furniture_layer, x + 1, y, DESK_TR)
    set_tile(furniture_layer, x, y + 1, DESK_BL)
    set_tile(furniture_layer, x + 1, y + 1, DESK_BR)


def place_chair(furniture_layer, x, y):
    """Place a chair (1×2 tiles, facing down)."""
    set_tile(furniture_layer, x, y, CHAIR_TOP)
    set_tile(furniture_layer, x, y + 1, CHAIR_BOT)


def place_plant(furniture_layer, x, y, variant=0):
    """Place a 2×2 plant."""
    if variant == 0:
        set_tile(furniture_layer, x, y, PLANT_TL)
        set_tile(furniture_layer, x + 1, y, PLANT_TR)
        set_tile(furniture_layer, x, y + 1, PLANT_BL)
        set_tile(furniture_layer, x + 1, y + 1, PLANT_BR)
    else:
        set_tile(furniture_layer, x, y, SMALL_PLANT_T)
        set_tile(furniture_layer, x, y + 1, SMALL_PLANT_B)


def place_bookshelf(furniture_layer, x, y):
    """Place a 3×3 bookshelf."""
    set_tile(furniture_layer, x, y, SHELF_TL)
    set_tile(furniture_layer, x + 1, y, SHELF_TM)
    set_tile(furniture_layer, x + 2, y, SHELF_TR)
    set_tile(furniture_layer, x, y + 1, SHELF_ML)
    set_tile(furniture_layer, x + 1, y + 1, SHELF_MM)
    set_tile(furniture_layer, x + 2, y + 1, SHELF_MR)
    set_tile(furniture_layer, x, y + 2, SHELF_BL)
    set_tile(furniture_layer, x + 1, y + 2, SHELF_BM)
    set_tile(furniture_layer, x + 2, y + 2, SHELF_BR)


def place_rug(furniture_layer, x, y, w=3, h=3):
    """Place a rug of specified size."""
    for dy in range(h):
        for dx in range(w):
            if dy == 0:
                if dx == 0: gid = RUG_TL
                elif dx == w - 1: gid = RUG_TR
                else: gid = RUG_TM
            elif dy == h - 1:
                if dx == 0: gid = RUG_BL
                elif dx == w - 1: gid = RUG_BR
                else: gid = RUG_BM
            else:
                if dx == 0: gid = RUG_ML
                elif dx == w - 1: gid = RUG_MR
                else: gid = RUG_MM
            set_tile(furniture_layer, x + dx, y + dy, gid)


def place_conference_table(furniture_layer, x, y, length=4):
    """Place a conference table (2 wide × length tall) with chairs on both sides."""
    for dy in range(length):
        if dy == 0:
            set_tile(furniture_layer, x, y + dy, CONF_TABLE_T)
            set_tile(furniture_layer, x + 1, y + dy, CONF_TABLE_T2)
        elif dy == length - 1:
            set_tile(furniture_layer, x, y + dy, CONF_TABLE_B)
            set_tile(furniture_layer, x + 1, y + dy, CONF_TABLE_B2)
        else:
            set_tile(furniture_layer, x, y + dy, CONF_TABLE_M)
            set_tile(furniture_layer, x + 1, y + dy, CONF_TABLE_M2)


def place_sofa(furniture_layer, x, y):
    """Place a 2×2 sofa."""
    set_tile(furniture_layer, x, y, SOFA_L)
    set_tile(furniture_layer, x + 1, y, SOFA_R)
    set_tile(furniture_layer, x, y + 1, SOFA_LB)
    set_tile(furniture_layer, x + 1, y + 1, SOFA_RB)


def build_map():
    """Build the complete office map."""
    # 3 layers: floor, walls, furniture (above player)
    floor = create_empty_layer("floor")
    walls = create_empty_layer("walls")
    furniture = create_empty_layer("furniture")

    # ─── FLOOR ─────────────────────────────────────────────
    # Fill entire map with wood floor
    fill_rect(floor, 0, 0, MAP_W, MAP_H, FLOOR_WOOD)

    # Kitchen area floor (stone) — left side, rows 18-27
    fill_rect(floor, 1, 19, 9, 8, FLOOR_STONE)

    # Lighter wood for hallways
    fill_rect(floor, 0, 14, MAP_W, 3, FLOOR_WOOD_LIGHT)  # horizontal hallway
    fill_rect(floor, 10, 0, 2, MAP_H, FLOOR_WOOD_LIGHT)  # vertical hallway

    # ─── OUTER WALLS ──────────────────────────────────────
    # Top wall (2 tiles tall)
    for x in range(MAP_W):
        set_tile(walls, x, 0, rb_gid(56, 56))
        set_tile(walls, x, 1, rb_gid(56, 57))

    # Bottom wall
    for x in range(MAP_W):
        set_tile(walls, x, MAP_H - 1, rb_gid(53, 59))

    # Left wall
    for y in range(2, MAP_H - 1):
        set_tile(walls, 0, y, rb_gid(53, 59))

    # Right wall
    for y in range(2, MAP_H - 1):
        set_tile(walls, MAP_W - 1, y, rb_gid(58, 59))

    # Corners
    set_tile(walls, 0, 0, rb_gid(52, 54))
    set_tile(walls, 0, 1, rb_gid(52, 55))
    set_tile(walls, MAP_W - 1, 0, rb_gid(57, 54))
    set_tile(walls, MAP_W - 1, 1, rb_gid(57, 55))
    set_tile(walls, 0, MAP_H - 1, rb_gid(52, 57))
    set_tile(walls, MAP_W - 1, MAP_H - 1, rb_gid(57, 57))

    # ─── INTERNAL WALLS ───────────────────────────────────
    # Left column divider (x=10) — partial walls with doorways
    for y in range(2, 14):
        set_tile(walls, 10, y, rb_gid(53, 59))
    # Gap for hallway at y=14-16
    for y in range(17, MAP_H - 1):
        set_tile(walls, 10, y, rb_gid(53, 59))

    # Right column divider (x=37)
    for y in range(2, 14):
        set_tile(walls, 37, y, rb_gid(58, 59))
    for y in range(17, MAP_H - 1):
        set_tile(walls, 37, y, rb_gid(58, 59))

    # Horizontal divider for Meeting Room 1 (top right)
    for x in range(38, MAP_W - 1):
        set_tile(walls, x, 13, rb_gid(53, 59))

    # Horizontal divider for Meeting Room 2 / Server Room
    for x in range(38, MAP_W - 1):
        set_tile(walls, x, 17, rb_gid(56, 56))
        set_tile(walls, x, 18, rb_gid(56, 57))
    set_tile(walls, 38, 17, rb_gid(52, 54))
    set_tile(walls, 38, 18, rb_gid(52, 55))

    # Meeting room 1 top wall
    for x in range(38, MAP_W - 1):
        set_tile(walls, x, 0, rb_gid(56, 56))
        set_tile(walls, x, 1, rb_gid(56, 57))

    # Left rooms horizontal dividers
    # Lounge / Kitchen divider at y=17
    for x in range(1, 10):
        set_tile(walls, x, 17, rb_gid(56, 56))
        set_tile(walls, x, 18, rb_gid(56, 57))

    # Door openings
    # Left rooms → hallway (x=10, y=5-6 gap for lounge door)
    set_tile(walls, 10, 5, 0)
    set_tile(walls, 10, 6, 0)
    set_tile(walls, 10, 7, 0)

    # Kitchen door (x=10, y=21-23)
    set_tile(walls, 10, 21, 0)
    set_tile(walls, 10, 22, 0)
    set_tile(walls, 10, 23, 0)

    # Meeting room 1 door (x=37, y=5-7)
    set_tile(walls, 37, 5, 0)
    set_tile(walls, 37, 6, 0)
    set_tile(walls, 37, 7, 0)

    # Meeting room 2 door
    set_tile(walls, 37, 21, 0)
    set_tile(walls, 37, 22, 0)
    set_tile(walls, 37, 23, 0)

    # ─── ENTRANCE ─────────────────────────────────────────
    # Main entrance at bottom center
    set_tile(walls, 23, MAP_H - 1, 0)
    set_tile(walls, 24, MAP_H - 1, 0)
    set_tile(walls, 25, MAP_H - 1, 0)

    # ─── WINDOWS (on outer walls) ─────────────────────────
    # Top wall windows
    for wx in [4, 7, 15, 20, 25, 30, 41, 44]:
        if wx < MAP_W - 2:
            set_tile(furniture, wx, 0, WINDOW_BL)
            set_tile(furniture, wx + 1, 0, WINDOW_BR)

    # ─── FURNITURE: OPEN PLAN WORKSPACE A (y=2-13, x=12-36) ──
    # Row of desk pods facing each other (gather.town style)
    agent_positions = []

    # Workspace A — top section (y=3-6)
    # Row 1: desks facing down, row 2: desks facing up
    for i, dx in enumerate([13, 16, 19, 22, 25, 28, 31, 34]):
        if dx + 1 < 37:
            place_desk_pod(furniture, dx, 3)
            # Agent sits at the desk (below the desk)
            agent_positions.append((dx, 5))

    # Row 2 of desks (y=8-11)
    for i, dx in enumerate([13, 16, 19, 22, 25, 28, 31, 34]):
        if dx + 1 < 37:
            place_desk_pod(furniture, dx, 8)
            agent_positions.append((dx, 10))

    # ─── FURNITURE: OPEN PLAN WORKSPACE B (y=19-32, x=12-36) ──
    # Row 3 of desks (y=20-23)
    for i, dx in enumerate([13, 16, 19, 22, 25, 28, 31, 34]):
        if dx + 1 < 37:
            place_desk_pod(furniture, dx, 20)
            agent_positions.append((dx, 22))

    # Row 4 of desks (y=25-28)
    for i, dx in enumerate([13, 16, 19, 22, 25, 28, 31, 34]):
        if dx + 1 < 37:
            place_desk_pod(furniture, dx, 25)
            agent_positions.append((dx, 27))

    # ─── PLANTS along hallway and corners ─────────────────
    place_plant(furniture, 11, 2, 0)    # Top of vertical hallway
    place_plant(furniture, 11, 14, 1)   # Mid hallway
    place_plant(furniture, 35, 2, 0)    # Near meeting room
    place_plant(furniture, 35, 14, 1)
    place_plant(furniture, 11, 30, 0)   # Bottom section
    place_plant(furniture, 35, 30, 0)

    # ─── LOUNGE AREA (top-left, x=1-9, y=2-13) ───────────
    place_sofa(furniture, 2, 4)
    place_sofa(furniture, 5, 4)
    place_rug(furniture, 2, 6, 5, 3)
    place_plant(furniture, 8, 2, 0)
    place_bookshelf(furniture, 2, 10)
    set_tile(furniture, 6, 10, WALL_ART)  # Wall decoration

    # ─── KITCHEN / BREAK ROOM (bottom-left, x=1-9, y=19-34) ──
    # Counter along top wall
    set_tile(furniture, 2, 19, COUNTER_T)
    set_tile(furniture, 3, 19, COUNTER_T)
    set_tile(furniture, 4, 19, COUNTER_T)
    set_tile(furniture, 2, 20, COUNTER_B)
    set_tile(furniture, 3, 20, COUNTER_B)
    set_tile(furniture, 4, 20, COUNTER_B)

    # Fridge
    set_tile(furniture, 7, 19, FRIDGE_T)
    set_tile(furniture, 7, 20, FRIDGE_B)

    # Table in kitchen
    place_rug(furniture, 3, 23, 4, 3)

    # ─── MEETING ROOM 1 (top-right, x=38-46, y=2-12) ─────
    place_conference_table(furniture, 41, 4, 4)
    place_rug(furniture, 39, 3, 6, 6)
    place_plant(furniture, 38, 2, 1)
    set_tile(furniture, 45, 2, WALL_ART)

    # ─── MEETING ROOM 2 (bottom-right, x=38-46, y=19-34) ──
    place_conference_table(furniture, 41, 22, 4)
    place_rug(furniture, 39, 21, 6, 6)
    place_plant(furniture, 45, 19, 0)
    place_bookshelf(furniture, 38, 28)

    # ─── RECEPTION / LOBBY (bottom center, y=30-34) ───────
    # Welcome rug
    place_rug(furniture, 22, 31, 4, 3)
    place_plant(furniture, 19, 31, 0)
    place_plant(furniture, 27, 31, 0)

    # ─── HALLWAY DECORATIONS ──────────────────────────────
    # Plants along horizontal hallway
    place_plant(furniture, 15, 14, 1)
    place_plant(furniture, 21, 14, 1)
    place_plant(furniture, 27, 14, 1)
    place_plant(furniture, 33, 14, 1)

    # Set layer IDs
    floor["id"] = 1
    walls["id"] = 2
    furniture["id"] = 3

    # Furniture layer renders above player
    furniture["properties"] = [
        {"name": "type", "type": "string", "value": "above"}
    ]

    return floor, walls, furniture, agent_positions


def build_collision_objects(walls_layer):
    """Generate collision rectangles from wall tiles."""
    objects = []
    obj_id = 1
    visited = set()

    for y in range(MAP_H):
        for x in range(MAP_W):
            gid = walls_layer["data"][y * MAP_W + x]
            if gid != 0 and (x, y) not in visited:
                # Find horizontal extent of this wall segment
                end_x = x
                while end_x < MAP_W and walls_layer["data"][y * MAP_W + end_x] != 0 and (end_x, y) not in visited:
                    visited.add((end_x, y))
                    end_x += 1

                objects.append({
                    "id": obj_id,
                    "x": x * TILE,
                    "y": y * TILE,
                    "width": (end_x - x) * TILE,
                    "height": TILE,
                    "rotation": 0,
                    "visible": True,
                })
                obj_id += 1

    # Add boundary walls
    # Top
    objects.append({"id": obj_id, "x": 0, "y": 0, "width": MAP_W * TILE, "height": TILE, "rotation": 0, "visible": True})
    obj_id += 1
    # Bottom (except entrance)
    objects.append({"id": obj_id, "x": 0, "y": (MAP_H - 1) * TILE, "width": 23 * TILE, "height": TILE, "rotation": 0, "visible": True})
    obj_id += 1
    objects.append({"id": obj_id, "x": 26 * TILE, "y": (MAP_H - 1) * TILE, "width": (MAP_W - 26) * TILE, "height": TILE, "rotation": 0, "visible": True})
    obj_id += 1

    return {
        "id": 4,
        "name": "collision",
        "type": "objectgroup",
        "class": "collision",
        "x": 0, "y": 0,
        "opacity": 1,
        "visible": True,
        "objects": objects,
        "draworder": "topdown",
    }


def build_tiled_json(floor, walls, furniture, agent_positions):
    """Build the complete Tiled JSON map."""
    collision = build_collision_objects(walls)

    # Agent spawn objects
    spawn_objects = []
    for i, (ax, ay) in enumerate(agent_positions):
        spawn_objects.append({
            "id": 1000 + i,
            "name": f"agent_{i}",
            "type": "spawn",
            "x": ax * TILE,
            "y": ay * TILE,
            "width": TILE,
            "height": TILE,
            "rotation": 0,
            "visible": True,
        })

    # Player spawn
    spawn_objects.append({
        "id": 999,
        "name": "player_spawn",
        "type": "spawn",
        "x": 24 * TILE,
        "y": 33 * TILE,
        "width": TILE,
        "height": TILE,
        "rotation": 0,
        "visible": True,
    })

    spawns_layer = {
        "id": 5,
        "name": "spawns",
        "type": "objectgroup",
        "x": 0, "y": 0,
        "opacity": 1,
        "visible": True,
        "objects": spawn_objects,
        "draworder": "topdown",
    }

    return {
        "compressionlevel": -1,
        "height": MAP_H,
        "width": MAP_W,
        "infinite": False,
        "orientation": "orthogonal",
        "renderorder": "right-down",
        "tileheight": TILE,
        "tilewidth": TILE,
        "tiledversion": "1.10.1",
        "type": "map",
        "version": "1.10",
        "nextlayerid": 6,
        "nextobjectid": 2000,
        "layers": [floor, walls, furniture, collision, spawns_layer],
        "tilesets": [
            {
                "columns": RB_COLS,
                "firstgid": RB_FIRSTGID,
                "image": "Room_Builder_16x16.png",
                "imageheight": RB_ROWS * TILE,
                "imagewidth": RB_COLS * TILE,
                "margin": 0,
                "name": "Room_Builder",
                "spacing": 0,
                "tilecount": RB_COLS * RB_ROWS,
                "tileheight": TILE,
                "tilewidth": TILE,
            },
            {
                "columns": INT_COLS,
                "firstgid": INT_FIRSTGID,
                "image": "Interiors_16x16.png",
                "imageheight": INT_ROWS * TILE,
                "imagewidth": INT_COLS * TILE,
                "margin": 0,
                "name": "Interiors",
                "spacing": 0,
                "tilecount": INT_COLS * INT_ROWS,
                "tileheight": TILE,
                "tilewidth": TILE,
            },
        ],
    }


# ─── Character sprite extraction ──────────────────────────────────────

def extract_player_sprite():
    """
    Create a Bonfire-compatible player spritesheet from LimeZu Adam character.

    Bonfire SimpleDirectionAnimation expects horizontal strips.
    We create a single spritesheet: 4 rows × N frames.
    Row 0: Down (front) — 4 frames
    Row 1: Left — 4 frames (we'll use the side walk from Adam)
    Row 2: Right — mirror of left
    Row 3: Up (back) — 4 frames

    Each frame is 16×32.
    Output: player.png (64×128 = 4 frames wide × 4 dirs × 32px tall)
    """
    adam_path = os.path.join(CHAR_DIR, 'Adam_16x16.png')
    if not os.path.exists(adam_path):
        print(f"WARNING: {adam_path} not found, keeping existing player sprite")
        return None

    adam = Image.open(adam_path)
    frame_w, frame_h = 16, 32
    num_frames = 4

    # Output: 4 frames × 4 rows
    out = Image.new('RGBA', (num_frames * frame_w, 4 * frame_h), (0, 0, 0, 0))

    # Row 0 in Adam: down/front idle + walk (4 frames at y=0)
    for i in range(num_frames):
        frame = adam.crop((i * frame_w, 0, (i + 1) * frame_w, frame_h))
        out.paste(frame, (i * frame_w, 0))

    # Row 3 in Adam (y=96): left walk (has left-biased pixels)
    # Actually row 3 has 13 frames, first frame is idle left
    for i in range(min(num_frames, 4)):
        x = i * frame_w
        y = 3 * frame_h  # row 3 = y=96
        if x + frame_w <= adam.size[0] and y + frame_h <= adam.size[1]:
            frame = adam.crop((x, y, x + frame_w, y + frame_h))
            out.paste(frame, (i * frame_w, frame_h))  # put in row 1 (left)

    # Row 2 (right) = mirror of row 1 (left)
    for i in range(num_frames):
        frame = out.crop((i * frame_w, frame_h, (i + 1) * frame_w, 2 * frame_h))
        flipped = frame.transpose(Image.FLIP_LEFT_RIGHT)
        out.paste(flipped, (i * frame_w, 2 * frame_h))

    # Row 4 in Adam (y=128): up/back walk
    for i in range(min(num_frames, 4)):
        x = i * frame_w
        y = 4 * frame_h  # row 4 = y=128
        if x + frame_w <= adam.size[0] and y + frame_h <= adam.size[1]:
            frame = adam.crop((x, y, x + frame_w, y + frame_h))
            out.paste(frame, (i * frame_w, 3 * frame_h))

    return out


def extract_npc_sprites():
    """
    Create NPC spritesheets from various LimeZu legacy characters.

    NPCs only need front-facing (sitting at desk) + idle animation.
    Output: npc.png — 8 color variants in vertical strips.
    Each variant: 2 frames wide × 32px tall (idle animation).
    Full sheet: 32×256 (2 frames × 8 variants × 32px per variant)
    """
    npc_chars = [
        'Adam', 'Alex', 'Amelia', 'Bob', 'Lucy', 'Molly', 'Dan', 'Edward',
        'Rob', 'Ash', 'Bruce', 'Pier', 'Samuel', 'Roki', 'Old_man_Josh', 'Old_woman_Jenny',
    ]

    frame_w, frame_h = 16, 32
    num_variants = min(16, len(npc_chars))
    num_frames = 2  # idle animation frames

    out = Image.new('RGBA', (num_frames * frame_w, num_variants * frame_h), (0, 0, 0, 0))

    for v in range(num_variants):
        char_name = npc_chars[v]
        char_path = os.path.join(CHAR_DIR, f'{char_name}_16x16.png')
        if not os.path.exists(char_path):
            print(f"  WARNING: {char_path} not found, skipping")
            continue

        char_img = Image.open(char_path)

        # Row 0 = front idle, take first 2 frames for idle animation
        for f in range(num_frames):
            x = f * frame_w
            if x + frame_w <= char_img.size[0] and frame_h <= char_img.size[1]:
                frame = char_img.crop((x, 0, x + frame_w, frame_h))
                out.paste(frame, (f * frame_w, v * frame_h))

    return out


# ─── Main ─────────────────────────────────────────────────────────────

def main():
    print("=== LimeZu Office Map Generator ===\n")

    # Ensure output directories exist
    os.makedirs(OUT_TILED, exist_ok=True)
    os.makedirs(OUT_PLAYER, exist_ok=True)
    os.makedirs(OUT_NPC, exist_ok=True)

    # 1. Copy tileset images
    print("Copying tileset images...")
    shutil.copy2(ROOM_BUILDER, os.path.join(OUT_TILED, 'Room_Builder_16x16.png'))
    shutil.copy2(INTERIORS, os.path.join(OUT_TILED, 'Interiors_16x16.png'))
    print(f"  → Room_Builder_16x16.png ({RB_COLS}×{RB_ROWS} tiles)")
    print(f"  → Interiors_16x16.png ({INT_COLS}×{INT_ROWS} tiles)")

    # 2. Build map
    print("\nBuilding office map...")
    floor, walls, furniture, agent_positions = build_map()

    print(f"  Map size: {MAP_W}×{MAP_H} tiles")
    print(f"  Agent desk positions: {len(agent_positions)}")

    # 3. Generate Tiled JSON
    tiled_json = build_tiled_json(floor, walls, furniture, agent_positions)

    with open(OUT_MAP, 'w') as f:
        json.dump(tiled_json, f)
    print(f"  → {OUT_MAP}")

    # 4. Extract player sprite
    print("\nExtracting player sprite...")
    player_img = extract_player_sprite()
    if player_img:
        player_img.save(os.path.join(OUT_PLAYER, 'player.png'))
        print(f"  → player.png ({player_img.size[0]}×{player_img.size[1]})")

    # 5. Extract NPC sprites
    print("Extracting NPC sprites...")
    npc_img = extract_npc_sprites()
    if npc_img:
        npc_img.save(os.path.join(OUT_NPC, 'npc.png'))
        print(f"  → npc.png ({npc_img.size[0]}×{npc_img.size[1]})")

    # 6. Print agent positions for Dart code
    print(f"\n=== Agent Positions ({len(agent_positions)}) ===")
    print("// Paste into office_map.dart → _agentPositions")
    print("const _agentPositions = [")
    for i, (x, y) in enumerate(agent_positions):
        comma = "," if i < len(agent_positions) - 1 else ""
        print(f"  [{x}, {y}]{comma}")
    print("];")

    print("\n=== Player spawn: (24, 33) ===")
    print("Done!")


if __name__ == '__main__':
    main()
