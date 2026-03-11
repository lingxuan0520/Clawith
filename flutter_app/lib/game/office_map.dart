import 'package:bonfire/bonfire.dart';
import 'package:bonfire/map/base/layer.dart';

// Tile constants
const kTileSize = 16.0;

/// Builds the virtual office tile map programmatically.
WorldMap buildOfficeMap() {
  return _buildOffice();
}

// ─────────────────────────────────────────────────────
// Desk workstation layout:
//   [desk agent] = NPC sits here  (agent_npc position)
//   [desk]       = desk tile (1 tile below the NPC)
//   [computer]   = monitor on desk (same tile as desk)
//   [chair]      = 1 tile below desk
//
// Per station:  col=C
//   C, row-1 → computer (on desk surface, no collision)
//   C, row   → desk tile (solid top, blocks movement from above)
//   C, row+1 → chair tile (walkable)
//   NPC sits at C, row-1 (above the desk facing down)
// ─────────────────────────────────────────────────────

// NPC agent positions [col, row]
// These are where the NPC sprite stands (in front of the desk)
const _agentPositions = [
  // Zone A (top-left cluster, cols 6-16, rows 3-5)
  [7, 3], [11, 3], [15, 3],
  [7, 8], [11, 8], [15, 8],
  // Zone B (top-right cluster, cols 20-30, rows 3-5)
  [21, 3], [25, 3], [29, 3],
  [21, 8], [25, 8], [29, 8],
  // Zone C (bottom-left, cols 6-16, rows 14-16)
  [7, 14], [11, 14], [15, 14],
  [7, 19], [11, 19], [15, 19],
  // Zone D (bottom-right, cols 20-30, rows 14-16)
  [21, 14], [25, 14], [29, 14],
  [21, 19], [25, 19],
];

/// Returns [col, row] positions for each agent NPC.
List<List<double>> getAgentDeskPositions() {
  return _agentPositions
      .map((p) => [p[0].toDouble(), p[1].toDouble()])
      .toList();
}

WorldMap _buildOffice() {
  const cols = 38;
  const rows = 26;

  final tiles = <Tile>[];

  // ── Base layer: carpet in desk zones, floor elsewhere, outer walls ──
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      if (r == 0 || r == rows - 1 || c == 0 || c == cols - 1) {
        tiles.add(_wallTile(c.toDouble(), r.toDouble()));
      } else if (_isDeskZone(c, r)) {
        tiles.add(_carpetTile(c.toDouble(), r.toDouble()));
      } else {
        tiles.add(_floorTile(c.toDouble(), r.toDouble()));
      }
    }
  }

  // ── Reception / lobby area (top-left corner, cols 1-5, rows 1-5) ──
  // Horizontal divider at row 6, cols 1-5
  for (int c = 1; c <= 5; c++) {
    if (c != 3) tiles.add(_wallTile(c.toDouble(), 6)); // door at col 3
  }
  // Vertical divider at col 5, rows 1-5
  for (int r = 1; r <= 5; r++) {
    tiles.add(_wallTile(5, r.toDouble()));
  }
  // Reception desk at col 2-3, row 3-4
  tiles.add(_deskTile(2, 3));
  tiles.add(_deskTile(3, 3));
  tiles.add(_computerTile(2, 2));
  // Plants in reception
  tiles.add(_plantTile(1, 1));
  tiles.add(_plantTile(4, 1));

  // ── Corridor dividers between zones ──
  // Vertical divider between left & right desks (col 18, rows 1-24)
  for (int r = 1; r <= rows - 2; r++) {
    if (r < 10 || r > 12) { // gap for corridor at rows 10-12
      tiles.add(_wallTile(18, r.toDouble()));
    }
  }

  // ── Desk workstations for each agent ──
  for (final pos in _agentPositions) {
    final c = pos[0];
    final r = pos[1];
    // Desk tile (1 tile below NPC, NPC stands at row r, desk at row r+1)
    tiles.add(_deskTile(c, r + 1));
    // Computer on desk
    tiles.add(_computerTile(c, r));
    // Chair 1 tile below desk (walkable, no hard collision)
    tiles.add(_chairTile(c, r + 2));
  }

  // ── Partition walls between desk rows within each zone ──
  // Zone A/B: horizontal partitions at row 6 (between row-groups 3 and 8)
  for (int c = 6; c <= 16; c++) {
    if (c % 4 != 3) tiles.add(_wallTile(c.toDouble(), 6)); // gap for walking
  }
  for (int c = 20; c <= 30; c++) {
    if (c % 4 != 1) tiles.add(_wallTile(c.toDouble(), 6));
  }
  // Zone C/D: horizontal partitions at row 17
  for (int c = 6; c <= 16; c++) {
    if (c % 4 != 3) tiles.add(_wallTile(c.toDouble(), 17));
  }
  for (int c = 20; c <= 30; c++) {
    if (c % 4 != 1) tiles.add(_wallTile(c.toDouble(), 17));
  }

  // ── Corner plants ──
  tiles.add(_plantTile(cols - 2, 1));
  tiles.add(_plantTile(cols - 2, rows - 2));
  tiles.add(_plantTile(1, rows - 2));
  tiles.add(_plantTile(20, 1));
  tiles.add(_plantTile(20, rows - 2));

  // ── Break area (bottom-right corner, cols 31-36, rows 18-24) ──
  for (int c = 31; c <= 36; c++) {
    tiles.add(_wallTile(c.toDouble(), 18));
  }
  tiles.add(_wallTile(31, 18));
  // Sofa/lounge (bookshelf tiles as stand-ins)
  tiles.add(_deskTile(33, 20));
  tiles.add(_deskTile(34, 20));
  tiles.add(_deskTile(35, 20));
  tiles.add(_plantTile(35, 22));
  tiles.add(_plantTile(32, 22));

  return WorldMap([
    Layer(id: 0, tiles: tiles),
  ]);
}

// ─────────────────────────────────────────────
// Tile builders
// ─────────────────────────────────────────────

Tile _floorTile(double c, double r) => Tile(
      x: c,
      y: r,
      width: kTileSize,
      height: kTileSize,
      sprite: TileSprite(path: 'office/floor.png'),
    );

Tile _wallTile(double c, double r) => Tile(
      x: c,
      y: r,
      width: kTileSize,
      height: kTileSize,
      sprite: TileSprite(path: 'office/wall.png'),
      collisions: [RectangleHitbox(size: Vector2.all(kTileSize))],
    );

Tile _deskTile(int c, int r) => Tile(
      x: c.toDouble(),
      y: r.toDouble(),
      width: kTileSize,
      height: kTileSize,
      sprite: TileSprite(path: 'office/desk.png'),
      collisions: [
        RectangleHitbox(size: Vector2(kTileSize, 10), position: Vector2(0, 0)),
      ],
    );

Tile _computerTile(int c, int r) => Tile(
      x: c.toDouble(),
      y: r.toDouble(),
      width: kTileSize,
      height: kTileSize,
      sprite: TileSprite(path: 'office/computer.png'),
    );

Tile _chairTile(int c, int r) => Tile(
      x: c.toDouble(),
      y: r.toDouble(),
      width: kTileSize,
      height: kTileSize,
      sprite: TileSprite(path: 'office/chair.png'),
    );

Tile _carpetTile(double c, double r) => Tile(
      x: c,
      y: r,
      width: kTileSize,
      height: kTileSize,
      sprite: TileSprite(path: 'office/carpet.png'),
    );

/// Returns true if this cell falls inside a desk zone (carpet area).
bool _isDeskZone(int c, int r) {
  // Zone A: top-left desks (cols 6-17, rows 1-12)
  if (c >= 6 && c <= 17 && r >= 1 && r <= 12) return true;
  // Zone B: top-right desks (cols 19-31, rows 1-12)
  if (c >= 19 && c <= 31 && r >= 1 && r <= 12) return true;
  // Zone C: bottom-left desks (cols 6-17, rows 13-24)
  if (c >= 6 && c <= 17 && r >= 13 && r <= 24) return true;
  // Zone D: bottom-right desks (cols 19-31, rows 13-24)
  if (c >= 19 && c <= 31 && r >= 13 && r <= 24) return true;
  return false;
}

Tile _plantTile(int c, int r) => Tile(
      x: c.toDouble(),
      y: r.toDouble(),
      width: kTileSize,
      height: kTileSize,
      sprite: TileSprite(path: 'office/plant.png'),
      collisions: [
        RectangleHitbox(size: Vector2(10, 10), position: Vector2(3, 3)),
      ],
    );
