// Generates pixel-art sprite sheets as PNG files for the virtual office.
// Run: dart run tool/gen_sprites.dart
//
// Creates:
//   assets/images/player/player.png  — 4-dir walk sprite sheet (3 frames x 4 dirs)
//   assets/images/npc/npc.png        — NPC sitting idle sprite sheet
//   assets/images/office/floor.png   — floor tile
//   assets/images/office/wall.png    — wall tile
//   assets/images/office/desk.png    — desk tile
//   assets/images/office/chair.png   — chair tile
//   assets/images/office/plant.png   — plant decoration
//   assets/images/office/computer.png — computer on desk

import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

// Minimal PNG encoder for RGBA pixel data
class PngEncoder {
  static Uint8List encode(int width, int height, Uint8List rgba) {
    // Build raw image data (filter byte 0 for each row + RGBA pixels)
    final rawRows = <int>[];
    for (int y = 0; y < height; y++) {
      rawRows.add(0); // filter: none
      for (int x = 0; x < width; x++) {
        final idx = (y * width + x) * 4;
        rawRows.add(rgba[idx]);
        rawRows.add(rgba[idx + 1]);
        rawRows.add(rgba[idx + 2]);
        rawRows.add(rgba[idx + 3]);
      }
    }

    final rawData = Uint8List.fromList(rawRows);
    final compressed = zLibEncode(rawData);

    final out = BytesBuilder();
    // PNG signature
    out.add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    // IHDR
    _writeChunk(out, 'IHDR', _ihdr(width, height));
    // IDAT
    _writeChunk(out, 'IDAT', compressed);
    // IEND
    _writeChunk(out, 'IEND', Uint8List(0));

    return out.toBytes();
  }

  static Uint8List _ihdr(int w, int h) {
    final b = ByteData(13);
    b.setUint32(0, w);
    b.setUint32(4, h);
    b.setUint8(8, 8);  // bit depth
    b.setUint8(9, 6);  // color type RGBA
    b.setUint8(10, 0);
    b.setUint8(11, 0);
    b.setUint8(12, 0);
    return b.buffer.asUint8List();
  }

  static void _writeChunk(BytesBuilder out, String type, Uint8List data) {
    final lenBytes = ByteData(4)..setUint32(0, data.length);
    out.add(lenBytes.buffer.asUint8List());
    final typeBytes = type.codeUnits;
    out.add(typeBytes);
    out.add(data);
    // CRC32 over type + data
    final crcInput = <int>[...typeBytes, ...data];
    final crc = _crc32(crcInput);
    final crcBytes = ByteData(4)..setUint32(0, crc);
    out.add(crcBytes.buffer.asUint8List());
  }

  static int _crc32(List<int> data) {
    int crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if (crc & 1 != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc ^ 0xFFFFFFFF;
  }

  // Simple DEFLATE (zlib) using dart:io's ZLibCodec
  static Uint8List zLibEncode(Uint8List data) {
    return Uint8List.fromList(ZLibCodec().encode(data));
  }
}

class SpriteCanvas {
  final int width, height;
  final Uint8List pixels;

  SpriteCanvas(this.width, this.height)
      : pixels = Uint8List(width * height * 4);

  void setPixel(int x, int y, int r, int g, int b, [int a = 255]) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    final idx = (y * width + x) * 4;
    pixels[idx] = r;
    pixels[idx + 1] = g;
    pixels[idx + 2] = b;
    pixels[idx + 3] = a;
  }

  void fillRect(int x0, int y0, int w, int h, int r, int g, int b,
      [int a = 255]) {
    for (int y = y0; y < y0 + h; y++) {
      for (int x = x0; x < x0 + w; x++) {
        setPixel(x, y, r, g, b, a);
      }
    }
  }

  Uint8List toPng() => PngEncoder.encode(width, height, pixels);

  /// Draw a simple pixel art character at offset (ox, oy) in a 16x16 grid
  /// Colors: skin, hair, shirt, pants, shoes
  void drawCharacter(int ox, int oy,
      {required List<int> skin,
      required List<int> hair,
      required List<int> shirt,
      required List<int> pants,
      required List<int> shoes,
      int walkFrame = 0, // 0=stand, 1=walk-L, 2=walk-R
      bool sitting = false}) {
    // Hair (top of head)
    fillRect(ox + 5, oy + 0, 6, 2, hair[0], hair[1], hair[2]);
    fillRect(ox + 4, oy + 2, 8, 1, hair[0], hair[1], hair[2]);

    // Face/skin
    fillRect(ox + 5, oy + 3, 6, 3, skin[0], skin[1], skin[2]);
    // Eyes
    setPixel(ox + 6, oy + 4, 40, 40, 60);
    setPixel(ox + 9, oy + 4, 40, 40, 60);

    // Neck
    fillRect(ox + 7, oy + 6, 2, 1, skin[0], skin[1], skin[2]);

    // Body/shirt
    fillRect(ox + 4, oy + 7, 8, 4, shirt[0], shirt[1], shirt[2]);
    // Arms
    fillRect(ox + 2, oy + 7, 2, 3, shirt[0], shirt[1], shirt[2]);
    fillRect(ox + 12, oy + 7, 2, 3, shirt[0], shirt[1], shirt[2]);
    // Hands
    fillRect(ox + 2, oy + 10, 2, 1, skin[0], skin[1], skin[2]);
    fillRect(ox + 12, oy + 10, 2, 1, skin[0], skin[1], skin[2]);

    if (sitting) {
      // Sitting: shorter legs, bent
      fillRect(ox + 5, oy + 11, 6, 2, pants[0], pants[1], pants[2]);
      fillRect(ox + 5, oy + 13, 6, 1, shoes[0], shoes[1], shoes[2]);
    } else {
      // Standing legs
      fillRect(ox + 5, oy + 11, 2, 3, pants[0], pants[1], pants[2]);
      fillRect(ox + 9, oy + 11, 2, 3, pants[0], pants[1], pants[2]);

      // Walk animation offset
      if (walkFrame == 1) {
        // Left leg forward
        fillRect(ox + 4, oy + 12, 2, 2, pants[0], pants[1], pants[2]);
        fillRect(ox + 9, oy + 11, 2, 3, pants[0], pants[1], pants[2]);
      } else if (walkFrame == 2) {
        // Right leg forward
        fillRect(ox + 5, oy + 11, 2, 3, pants[0], pants[1], pants[2]);
        fillRect(ox + 10, oy + 12, 2, 2, pants[0], pants[1], pants[2]);
      }

      // Shoes
      fillRect(ox + 4, oy + 14, 3, 1, shoes[0], shoes[1], shoes[2]);
      fillRect(ox + 9, oy + 14, 3, 1, shoes[0], shoes[1], shoes[2]);
    }
  }
}

void main() {
  // ===== Player sprite sheet: 3 frames x 4 directions = 48x64 =====
  // Each frame: 16x16, sheet: (3 cols x 16) x (4 rows x 16) = 48x64
  final playerSheet = SpriteCanvas(48, 64);
  final playerSkin = [232, 190, 155];
  final playerHair = [60, 40, 30];
  final playerShirt = [70, 130, 230]; // Blue
  final playerPants = [50, 55, 70];
  final playerShoes = [40, 40, 45];

  // 4 directions: down(0), left(1), right(2), up(3)
  for (int dir = 0; dir < 4; dir++) {
    for (int frame = 0; frame < 3; frame++) {
      playerSheet.drawCharacter(
        frame * 16,
        dir * 16,
        skin: playerSkin,
        hair: playerHair,
        shirt: playerShirt,
        pants: playerPants,
        shoes: playerShoes,
        walkFrame: frame,
      );
    }
  }
  File('assets/images/player/player.png')
      .writeAsBytesSync(playerSheet.toPng());
  print('✓ player.png');

  // ===== NPC sprite sheet: sitting idle, 2 frames for subtle animation =====
  // 8 color variants x 2 frames = 32x32 per variant, laid out as 2x8 = 32x128
  final npcColors = [
    // shirt colors for variety
    [220, 80, 80],   // red
    [80, 180, 100],  // green
    [200, 160, 60],  // gold
    [160, 80, 200],  // purple
    [80, 180, 200],  // cyan
    [220, 140, 80],  // orange
    [180, 100, 140], // pink
    [100, 120, 180], // steel blue
  ];
  final npcSheet = SpriteCanvas(32, 128);
  for (int variant = 0; variant < 8; variant++) {
    for (int frame = 0; frame < 2; frame++) {
      npcSheet.drawCharacter(
        frame * 16,
        variant * 16,
        skin: [220, 185, 150],
        hair: [variant.isEven ? 50 : 80, 40, variant.isEven ? 30 : 50],
        shirt: npcColors[variant],
        pants: [60, 60, 70],
        shoes: [45, 45, 50],
        sitting: true,
        walkFrame: frame, // slight arm movement
      );
    }
  }
  File('assets/images/npc/npc.png').writeAsBytesSync(npcSheet.toPng());
  print('✓ npc.png');

  // ===== Office tiles: 16x16 each =====
  // Floor
  final floor = SpriteCanvas(16, 16);
  floor.fillRect(0, 0, 16, 16, 200, 200, 195); // light gray
  // Subtle grid lines
  for (int i = 0; i < 16; i++) {
    floor.setPixel(i, 0, 185, 185, 180);
    floor.setPixel(0, i, 185, 185, 180);
  }
  File('assets/images/office/floor.png').writeAsBytesSync(floor.toPng());
  print('✓ floor.png');

  // Wall
  final wall = SpriteCanvas(16, 16);
  wall.fillRect(0, 0, 16, 16, 90, 95, 110); // dark blue-gray
  wall.fillRect(0, 0, 16, 2, 70, 75, 90);
  wall.fillRect(0, 14, 16, 2, 110, 115, 130);
  // Brick pattern
  for (int y = 3; y < 14; y += 4) {
    for (int x = 0; x < 16; x++) {
      wall.setPixel(x, y, 80, 85, 100);
    }
  }
  File('assets/images/office/wall.png').writeAsBytesSync(wall.toPng());
  print('✓ wall.png');

  // Desk
  final desk = SpriteCanvas(16, 16);
  desk.fillRect(1, 2, 14, 10, 140, 110, 75); // wood color
  desk.fillRect(1, 2, 14, 2, 155, 125, 85);  // top highlight
  desk.fillRect(2, 12, 3, 4, 120, 95, 65);   // left leg
  desk.fillRect(11, 12, 3, 4, 120, 95, 65);  // right leg
  File('assets/images/office/desk.png').writeAsBytesSync(desk.toPng());
  print('✓ desk.png');

  // Chair
  final chair = SpriteCanvas(16, 16);
  chair.fillRect(3, 3, 10, 8, 70, 70, 80);   // seat
  chair.fillRect(3, 0, 10, 3, 80, 80, 90);    // backrest
  chair.fillRect(4, 11, 2, 4, 60, 60, 65);    // left leg
  chair.fillRect(10, 11, 2, 4, 60, 60, 65);   // right leg
  chair.fillRect(6, 11, 4, 1, 60, 60, 65);    // crossbar
  File('assets/images/office/chair.png').writeAsBytesSync(chair.toPng());
  print('✓ chair.png');

  // Plant
  final plant = SpriteCanvas(16, 16);
  plant.fillRect(6, 10, 4, 6, 120, 80, 50); // pot
  plant.fillRect(5, 9, 6, 2, 140, 95, 55);  // pot rim
  // Leaves
  plant.fillRect(5, 3, 6, 6, 60, 160, 80);
  plant.fillRect(3, 5, 3, 3, 50, 140, 70);
  plant.fillRect(10, 4, 3, 4, 50, 140, 70);
  plant.fillRect(6, 1, 4, 3, 70, 175, 90);
  File('assets/images/office/plant.png').writeAsBytesSync(plant.toPng());
  print('✓ plant.png');

  // Computer/monitor
  final computer = SpriteCanvas(16, 16);
  computer.fillRect(2, 2, 12, 8, 50, 50, 60);   // screen bezel
  computer.fillRect(3, 3, 10, 6, 100, 160, 220); // screen
  computer.fillRect(6, 10, 4, 2, 60, 60, 65);    // stand
  computer.fillRect(4, 12, 8, 1, 60, 60, 65);    // base
  // Screen content - some "text" lines
  computer.fillRect(4, 4, 6, 1, 180, 220, 255);
  computer.fillRect(4, 6, 8, 1, 160, 200, 240);
  File('assets/images/office/computer.png')
      .writeAsBytesSync(computer.toPng());
  print('✓ computer.png');

  print('\nAll sprites generated!');
}
