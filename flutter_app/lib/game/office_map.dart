import 'dart:convert';

import 'package:bonfire/bonfire.dart';
import 'package:bonfire/map/tiled/reader/tiled_asset_reader.dart';
import 'package:flutter/services.dart';

const kTileSize = 16.0;

/// Builds the virtual office map from the user's custom Tiled JSON.
/// forceTileSize slightly larger than 16 to eliminate sub-pixel seams.
WorldMap buildOfficeMap() {
  return WorldMapByTiled(
    TiledAssetReader(asset: 'tiled/w.json'),
  );
}

/// Tileset info parsed from the map JSON.
class _TilesetInfo {
  final int firstGid;
  final int lastGid;
  final String imagePath;
  final int columns;
  final double tileWidth;
  final double tileHeight;

  _TilesetInfo({
    required this.firstGid,
    required this.lastGid,
    required this.imagePath,
    required this.columns,
    required this.tileWidth,
    required this.tileHeight,
  });
}

/// Loads tile objects from object layers in w.json and returns them
/// as GameDecoration components. Each decoration gets priority = y
/// position for correct y-sort rendering.
Future<List<GameDecoration>> loadTileObjectDecorations() async {
  // 1. Read and parse the map JSON
  final jsonStr = await rootBundle.loadString('assets/images/tiled/w.json');
  final map = jsonDecode(jsonStr) as Map<String, dynamic>;

  // 2. Read and parse tileset info (from .tsj files)
  final tilesets = <_TilesetInfo>[];
  for (final ts in map['tilesets'] as List) {
    final firstGid = ts['firstgid'] as int;
    final source = ts['source'] as String;
    final tsjStr = await rootBundle.loadString('assets/images/tiled/$source');
    final tsj = jsonDecode(tsjStr) as Map<String, dynamic>;
    final tileCount = tsj['tilecount'] as int;
    tilesets.add(_TilesetInfo(
      firstGid: firstGid,
      lastGid: firstGid + tileCount - 1,
      imagePath: 'tiled/${tsj['image']}',
      columns: tsj['columns'] as int,
      tileWidth: (tsj['tilewidth'] as num).toDouble(),
      tileHeight: (tsj['tileheight'] as num).toDouble(),
    ));
  }
  // Sort by firstGid descending for lookup
  tilesets.sort((a, b) => b.firstGid.compareTo(a.firstGid));

  // 3. Pre-load tileset images
  final imageCache = <String, Image>{};
  for (final ts in tilesets) {
    if (!imageCache.containsKey(ts.imagePath)) {
      imageCache[ts.imagePath] = await Flame.images.load(ts.imagePath);
    }
  }

  // 4. Iterate object layers, create decorations for tile objects
  final decorations = <GameDecoration>[];
  for (final layer in map['layers'] as List) {
    if (layer['type'] != 'objectgroup') continue;
    if (layer['visible'] != true) continue;
    // Skip the collision layer — Bonfire handles it
    if (layer['class'] == 'collision') continue;

    for (final obj in layer['objects'] as List) {
      final gid = obj['gid'];
      if (gid == null) continue; // Not a tile object

      // Decode flip flags from gid (Tiled stores them in high bits)
      final rawGid = gid as int;
      final flipH = (rawGid & 0x80000000) != 0;
      final flipV = (rawGid & 0x40000000) != 0;
      // final flipD = (rawGid & 0x20000000) != 0; // diagonal flip (rotation)
      final tileId = rawGid & 0x0FFFFFFF;

      // Find which tileset this gid belongs to
      _TilesetInfo? tileset;
      for (final ts in tilesets) {
        if (tileId >= ts.firstGid && tileId <= ts.lastGid) {
          tileset = ts;
          break;
        }
      }
      if (tileset == null) continue;

      final localId = tileId - tileset.firstGid;
      final col = localId % tileset.columns;
      final row = localId ~/ tileset.columns;
      final srcX = col * tileset.tileWidth;
      final srcY = row * tileset.tileHeight;

      final image = imageCache[tileset.imagePath]!;
      var sprite = Sprite(
        image,
        srcPosition: Vector2(srcX, srcY),
        srcSize: Vector2(tileset.tileWidth, tileset.tileHeight),
      );

      // Handle flips by creating a flipped sprite composition
      // For now, basic sprite (flips handled via component transform)
      final objX = (obj['x'] as num).toDouble();
      final objY = (obj['y'] as num).toDouble();
      // Tile objects in Tiled: (x, y) is bottom-left corner
      final posX = objX;
      final posY = objY - tileset.tileHeight;

      final decoration = GameDecoration(
        position: Vector2(posX, posY),
        size: Vector2(tileset.tileWidth, tileset.tileHeight),
        sprite: sprite,
      );

      // Apply flips
      if (flipH) {
        decoration.flipHorizontallyAroundCenter();
      }
      if (flipV) {
        decoration.flipVerticallyAroundCenter();
      }

      // Y-sort: priority based on bottom edge y position
      decoration.priority = objY.toInt();

      decorations.add(decoration);
    }
  }

  return decorations;
}

// NPC agent positions [col, row] — for the 50x50 test map.
const _agentPositions = [
  [5, 7],  [8, 7],  [11, 7],  [17, 7],  [20, 7],  [23, 7],
  [5, 10], [8, 10], [11, 10], [17, 10], [20, 10], [23, 10],
  [5, 14], [8, 14], [11, 14], [17, 14], [20, 14], [23, 14],
  [5, 17], [8, 17], [11, 17], [17, 17], [20, 17], [23, 17],
  [12, 26], [14, 27], [24, 26], [26, 27], [10, 30],
];

/// Returns [col, row] positions for each agent NPC.
List<List<double>> getAgentDeskPositions() {
  return _agentPositions
      .map((p) => [p[0].toDouble(), p[1].toDouble()])
      .toList();
}
