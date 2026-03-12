import 'package:bonfire/bonfire.dart';
import 'package:bonfire/map/tiled/reader/tiled_asset_reader.dart';

// Tile constants — must match the Tiled map (48px tiles, native resolution)
const kTileSize = 48.0;
const kRenderTileSize = 48.0;

/// Builds the virtual office map from the Tiled JSON export.
WorldMap buildOfficeMap() {
  return WorldMapByTiled(
    TiledAssetReader(asset: 'tiled/office_map.json'),
  );
}

// NPC agent positions [col, row] — chair positions in the 32x34 tile map.
// Map uses LimeZu Modern Office Design 2 as image layer (no offset).
const _agentPositions = [
  // Open office — row 1 (top desks, chairs facing south)
  [5, 7],  [8, 7],  [11, 7],  [17, 7],  [20, 7],  [23, 7],
  // Row 2 (chairs facing north)
  [5, 10], [8, 10], [11, 10], [17, 10], [20, 10], [23, 10],
  // Row 3 (lower pod, chairs facing south)
  [5, 14], [8, 14], [11, 14], [17, 14], [20, 14], [23, 14],
  // Row 4 (chairs facing north)
  [5, 17], [8, 17], [11, 17], [17, 17], [20, 17], [23, 17],
  // Bottom offices
  [12, 26], [14, 27], [24, 26], [26, 27], [10, 30],
];

/// Returns [col, row] positions for each agent NPC.
/// Coordinates are in tile units — multiply by kRenderTileSize for pixel positions.
List<List<double>> getAgentDeskPositions() {
  return _agentPositions
      .map((p) => [p[0].toDouble(), p[1].toDouble()])
      .toList();
}
