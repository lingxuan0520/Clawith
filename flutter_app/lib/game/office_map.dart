import 'package:bonfire/bonfire.dart';
import 'package:bonfire/map/base/layer.dart';

// Tile constants
const kTileSize = 16.0;

/// Builds the virtual office tile map programmatically.
WorldMap buildOfficeMap() {
  return _buildCleanOffice();
}

WorldMap _buildCleanOffice() {
  const cols = 40;
  const rows = 28;

  final tiles = <Tile>[];

  // Floor everywhere + outer walls
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      if (r == 0 || r == rows - 1 || c == 0 || c == cols - 1) {
        tiles.add(_wallTile(c.toDouble(), r.toDouble()));
      } else {
        tiles.add(_floorTile(c.toDouble(), r.toDouble()));
      }
    }
  }

  // Meeting room divider — left side (cols 4, rows 1-5)
  for (int r = 1; r <= 5; r++) {
    tiles.add(_wallTile(4, r.toDouble()));
  }
  tiles.add(_wallTile(4, 6));
  // Doorway at row 6 — keep floor (already placed)

  // Meeting room bottom wall
  for (int c = 1; c <= 3; c++) {
    tiles.add(_wallTile(c.toDouble(), 6));
  }

  // Plants
  _addPlants(tiles, cols, rows);

  return WorldMap([
    Layer(id: 0, tiles: tiles),
  ]);
}

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
      collisions: [
        RectangleHitbox(size: Vector2.all(kTileSize)),
      ],
    );

void _addPlants(List<Tile> tiles, int cols, int rows) {
  final positions = [
    [2.0, 2.0],
    [(cols - 3).toDouble(), 2.0],
    [2.0, (rows - 3).toDouble()],
    [(cols - 3).toDouble(), (rows - 3).toDouble()],
    [(cols ~/ 2).toDouble(), 2.0],
    [(cols ~/ 2).toDouble(), (rows - 3).toDouble()],
  ];
  for (final pos in positions) {
    // Plant on top of floor (re-add as separate tile same position)
    tiles.add(Tile(
      x: pos[0],
      y: pos[1],
      width: kTileSize,
      height: kTileSize,
      sprite: TileSprite(path: 'office/plant.png'),
      collisions: [
        RectangleHitbox(
          size: Vector2(10, 10),
          position: Vector2(3, 3),
        ),
      ],
    ));
  }
}

/// Returns desk positions arranged in rows for agents.
/// Each entry is [col, row] in tile coordinates.
List<List<double>> getAgentDeskPositions() {
  return [
    // Row 1 desks (top area, y=3)
    [8, 3], [11, 3], [14, 3],
    [18, 3], [21, 3], [24, 3],
    [28, 3], [31, 3], [34, 3],
    // Row 2 desks (middle, y=10)
    [8, 10], [11, 10], [14, 10],
    [18, 10], [21, 10], [24, 10],
    [28, 10], [31, 10], [34, 10],
    // Row 3 (lower, y=17)
    [8, 17], [11, 17], [14, 17],
    [18, 17], [21, 17],
  ];
}
