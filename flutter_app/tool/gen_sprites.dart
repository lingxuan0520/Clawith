// Generates pixel-art sprite sheets as PNG files for the virtual office.
// Run: dart run tool/gen_sprites.dart

import 'dart:io';
import 'dart:typed_data';

class PngEncoder {
  static Uint8List encode(int width, int height, Uint8List rgba) {
    final rawRows = <int>[];
    for (int y = 0; y < height; y++) {
      rawRows.add(0);
      for (int x = 0; x < width; x++) {
        final idx = (y * width + x) * 4;
        rawRows.add(rgba[idx]);
        rawRows.add(rgba[idx + 1]);
        rawRows.add(rgba[idx + 2]);
        rawRows.add(rgba[idx + 3]);
      }
    }
    final rawData = Uint8List.fromList(rawRows);
    final compressed = Uint8List.fromList(ZLibCodec().encode(rawData));
    final out = BytesBuilder();
    out.add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    _writeChunk(out, 'IHDR', _ihdr(width, height));
    _writeChunk(out, 'IDAT', compressed);
    _writeChunk(out, 'IEND', Uint8List(0));
    return out.toBytes();
  }

  static Uint8List _ihdr(int w, int h) {
    final b = ByteData(13);
    b.setUint32(0, w); b.setUint32(4, h);
    b.setUint8(8, 8); b.setUint8(9, 6);
    return b.buffer.asUint8List();
  }

  static void _writeChunk(BytesBuilder out, String type, Uint8List data) {
    final lenBytes = ByteData(4)..setUint32(0, data.length);
    out.add(lenBytes.buffer.asUint8List());
    final typeBytes = type.codeUnits;
    out.add(typeBytes); out.add(data);
    final crc = _crc32([...typeBytes, ...data]);
    out.add((ByteData(4)..setUint32(0, crc)).buffer.asUint8List());
  }

  static int _crc32(List<int> data) {
    int crc = 0xFFFFFFFF;
    for (final b in data) {
      crc ^= b;
      for (int i = 0; i < 8; i++) {
        crc = (crc & 1 != 0) ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    return crc ^ 0xFFFFFFFF;
  }
}

class Canvas {
  final int width, height;
  final Uint8List px;
  Canvas(this.width, this.height) : px = Uint8List(width * height * 4);

  void p(int x, int y, int r, int g, int b, [int a = 255]) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    final i = (y * width + x) * 4;
    px[i] = r; px[i+1] = g; px[i+2] = b; px[i+3] = a;
  }

  void rect(int x, int y, int w, int h, int r, int g, int b, [int a = 255]) {
    for (int dy = 0; dy < h; dy++)
      for (int dx = 0; dx < w; dx++)
        p(x + dx, y + dy, r, g, b, a);
  }

  // Draw outline rectangle (border only)
  void border(int x, int y, int w, int h, int r, int g, int b) {
    for (int dx = 0; dx < w; dx++) { p(x+dx, y, r,g,b); p(x+dx, y+h-1, r,g,b); }
    for (int dy = 0; dy < h; dy++) { p(x, y+dy, r,g,b); p(x+w-1, y+dy, r,g,b); }
  }

  Uint8List png() => PngEncoder.encode(width, height, px);
}

void save(String path, Canvas c) {
  File(path).writeAsBytesSync(c.png());
  print('✓ $path');
}

void main() {
  // ─── Floor tile: warm beige with subtle grid ─────────────────────
  final floor = Canvas(16, 16);
  floor.rect(0, 0, 16, 16, 210, 205, 195);
  // Subtle tile lines
  for (int i = 0; i < 16; i++) {
    floor.p(i, 0, 190, 185, 175);
    floor.p(0, i, 190, 185, 175);
    floor.p(i, 8, 195, 190, 182);
    floor.p(8, i, 195, 190, 182);
  }
  save('assets/images/office/floor.png', floor);

  // ─── Carpet tile: dark teal/blue — desk zone ─────────────────────
  final carpet = Canvas(16, 16);
  carpet.rect(0, 0, 16, 16, 55, 85, 105);
  // Subtle weave pattern
  for (int y = 0; y < 16; y++)
    for (int x = 0; x < 16; x++)
      if ((x + y) % 4 == 0) carpet.p(x, y, 45, 75, 95);
  // Border
  for (int i = 0; i < 16; i++) {
    carpet.p(i, 0, 40, 68, 88);
    carpet.p(i, 15, 40, 68, 88);
    carpet.p(0, i, 40, 68, 88);
    carpet.p(15, i, 40, 68, 88);
  }
  save('assets/images/office/carpet.png', carpet);

  // ─── Wall tile: office wall with baseboard ────────────────────────
  final wall = Canvas(16, 16);
  wall.rect(0, 0, 16, 16, 88, 92, 108);
  wall.rect(0, 0, 16, 1, 65, 68, 82);   // top shadow
  wall.rect(0, 14, 16, 2, 105, 112, 125); // baseboard
  // Horizontal mortar lines
  for (int y = 4; y < 14; y += 4)
    for (int x = 0; x < 16; x++) wall.p(x, y, 75, 79, 95);
  // Vertical mortar (staggered)
  for (int y = 0; y < 14; y += 8)
    wall.p(8, y + 2, 75, 79, 95);
  for (int y = 4; y < 14; y += 8)
    wall.p(4, y + 2, 75, 79, 95);
  save('assets/images/office/wall.png', wall);

  // ─── Desk tile: wooden desk surface with edge ────────────────────
  final desk = Canvas(16, 16);
  desk.rect(1, 0, 14, 9, 152, 118, 76);   // desk top
  desk.rect(1, 0, 14, 2, 170, 135, 90);   // front edge highlight
  desk.rect(0, 0, 1, 9, 135, 104, 66);    // left shadow
  desk.rect(15, 0, 1, 9, 135, 104, 66);   // right shadow
  // Grain lines
  for (int y = 2; y < 8; y += 3)
    for (int x = 2; x < 14; x++) desk.p(x, y, 145, 112, 72);
  // Legs
  desk.rect(2, 9, 3, 7, 120, 90, 55);
  desk.rect(11, 9, 3, 7, 120, 90, 55);
  save('assets/images/office/desk.png', desk);

  // ─── Computer: monitor on stand ──────────────────────────────────
  final comp = Canvas(16, 16);
  comp.rect(1, 0, 14, 10, 42, 44, 54);    // bezel
  comp.rect(2, 1, 12, 8, 28, 32, 42);     // screen bg
  // Screen glow — blue/teal "code" look
  comp.rect(3, 2, 10, 6, 40, 120, 190);
  // "Code" lines on screen
  comp.rect(3, 2, 6, 1, 120, 220, 255);
  comp.rect(3, 4, 8, 1, 100, 200, 240);
  comp.rect(3, 6, 5, 1, 90, 180, 220);
  // Screen border
  comp.border(2, 1, 12, 8, 60, 140, 200);
  // Notch
  comp.rect(6, 10, 4, 2, 50, 52, 62);
  // Base
  comp.rect(4, 12, 8, 2, 55, 58, 70);
  comp.rect(3, 13, 10, 1, 65, 68, 82);
  save('assets/images/office/computer.png', comp);

  // ─── Chair: office chair ─────────────────────────────────────────
  final chair = Canvas(16, 16);
  // Backrest
  chair.rect(3, 0, 10, 4, 72, 74, 88);
  chair.rect(4, 1, 8, 2, 84, 86, 100);
  // Seat
  chair.rect(2, 4, 12, 5, 80, 82, 96);
  chair.rect(3, 4, 10, 2, 92, 94, 110);  // seat highlight
  // Center post
  chair.rect(6, 9, 4, 3, 60, 62, 72);
  // Wheel base (5 spokes)
  chair.rect(2, 12, 12, 2, 56, 58, 68);
  chair.p(2, 13, 50, 52, 62); chair.p(14, 13, 50, 52, 62);
  chair.p(7, 14, 50, 52, 62); chair.p(9, 14, 50, 52, 62);
  save('assets/images/office/chair.png', chair);

  // ─── Plant: potted plant ─────────────────────────────────────────
  final plant = Canvas(16, 16);
  // Pot
  plant.rect(5, 11, 6, 5, 165, 110, 60);
  plant.rect(4, 10, 8, 2, 180, 125, 70);  // pot rim
  plant.rect(5, 14, 6, 1, 140, 95, 50);   // pot shadow
  // Soil
  plant.rect(5, 11, 6, 1, 85, 65, 40);
  // Stem
  plant.rect(7, 6, 2, 5, 60, 120, 60);
  // Leaves — layered
  plant.rect(4, 3, 8, 5, 55, 155, 75);
  plant.rect(2, 5, 5, 3, 45, 140, 65);
  plant.rect(9, 4, 5, 4, 45, 140, 65);
  plant.rect(5, 1, 6, 3, 65, 170, 85);
  // Leaf highlights
  plant.rect(5, 4, 3, 1, 80, 185, 95);
  plant.rect(10, 5, 2, 1, 75, 175, 90);
  save('assets/images/office/plant.png', plant);

  // ─── Player sprite sheet: 16px x 16px, 3 frames x 4 dirs = 48x64 ──
  final pSheet = Canvas(48, 64);
  final skin = [225, 185, 150];
  final hair = [55, 38, 28];
  final shirt = [65, 125, 225];
  final pants = [48, 52, 68];
  final shoes = [38, 38, 42];

  for (int dir = 0; dir < 4; dir++) {
    for (int frame = 0; frame < 3; frame++) {
      _drawChar(pSheet, frame * 16, dir * 16,
          skin: skin, hair: hair, shirt: shirt, pants: pants, shoes: shoes,
          facing: dir, frame: frame);
    }
  }
  save('assets/images/player/player.png', pSheet);

  // ─── NPC sprite sheet: 8 variants x 2 frames = 32x128 ─────────────
  final npcSheet = Canvas(32, 128);
  final npcShirts = [
    [210, 70, 70],   // red
    [70, 175, 95],   // green
    [195, 155, 55],  // gold
    [155, 70, 195],  // purple
    [70, 175, 195],  // cyan
    [215, 135, 70],  // orange
    [175, 95, 135],  // pink
    [95, 115, 175],  // steel-blue
  ];
  final npcHairs = [
    [50, 35, 25], [80, 60, 40], [40, 30, 20], [90, 70, 50],
    [55, 40, 30], [70, 50, 35], [45, 35, 25], [85, 65, 45],
  ];
  for (int v = 0; v < 8; v++) {
    for (int frame = 0; frame < 2; frame++) {
      _drawChar(npcSheet, frame * 16, v * 16,
          skin: [218, 180, 145], hair: npcHairs[v],
          shirt: npcShirts[v], pants: [58, 58, 68], shoes: [42, 42, 48],
          facing: 0, frame: frame, sitting: true);
    }
  }
  save('assets/images/npc/npc.png', npcSheet);

  print('\nDone! All sprites generated.');
}

// ─── Character renderer ──────────────────────────────────────────────────────
void _drawChar(Canvas c, int ox, int oy, {
  required List<int> skin, required List<int> hair,
  required List<int> shirt, required List<int> pants, required List<int> shoes,
  int facing = 0, int frame = 0, bool sitting = false,
}) {
  // Shadow
  c.rect(ox+4, oy+14, 8, 1, 0, 0, 0, 60);

  // Hair
  c.rect(ox+4, oy+1, 8, 2, hair[0], hair[1], hair[2]);
  c.rect(ox+5, oy+0, 6, 1, hair[0], hair[1], hair[2]);
  // Hair side
  c.p(ox+4, oy+3, hair[0], hair[1], hair[2]);
  c.p(ox+11, oy+3, hair[0], hair[1], hair[2]);

  // Face
  c.rect(ox+4, oy+2, 8, 4, skin[0], skin[1], skin[2]);
  // Eyes (vary by facing dir)
  if (facing != 3) { // not facing up
    c.p(ox+6, oy+3, 40, 38, 55);
    c.p(ox+9, oy+3, 40, 38, 55);
    // Pupils
    c.p(ox+6, oy+4, 30, 28, 45);
    c.p(ox+9, oy+4, 30, 28, 45);
    // Mouth
    c.p(ox+7, oy+5, 180, 130, 120);
  }
  if (facing == 3) { // back of head
    c.rect(ox+4, oy+2, 8, 4, hair[0], hair[1], hair[2]);
  }

  // Neck
  c.rect(ox+7, oy+6, 2, 1, skin[0], skin[1], skin[2]);

  // Shirt/body
  c.rect(ox+4, oy+7, 8, 4, shirt[0], shirt[1], shirt[2]);
  // Shirt highlight
  c.rect(ox+5, oy+7, 6, 1, _lighter(shirt[0]), _lighter(shirt[1]), _lighter(shirt[2]));
  // Collar
  c.rect(ox+7, oy+7, 2, 1, _lighter(shirt[0]), _lighter(shirt[1]), _lighter(shirt[2]));

  // Arms
  final armSwing = (frame == 1) ? -1 : (frame == 2) ? 1 : 0;
  c.rect(ox+2, oy+7, 2, 3, shirt[0], shirt[1], shirt[2]);
  c.rect(ox+12, oy+7, 2, 3, shirt[0], shirt[1], shirt[2]);
  // Hands
  c.rect(ox+2, oy+10+armSwing, 2, 1, skin[0], skin[1], skin[2]);
  c.rect(ox+12, oy+10-armSwing, 2, 1, skin[0], skin[1], skin[2]);

  if (sitting) {
    // Sitting legs (bent at knee)
    c.rect(ox+4, oy+11, 3, 3, pants[0], pants[1], pants[2]);
    c.rect(ox+9, oy+11, 3, 3, pants[0], pants[1], pants[2]);
    c.rect(ox+4, oy+13, 3, 1, shoes[0], shoes[1], shoes[2]);
    c.rect(ox+9, oy+13, 3, 1, shoes[0], shoes[1], shoes[2]);
  } else {
    // Standing / walking legs
    int lLegOffset = 0, rLegOffset = 0;
    if (frame == 1) { lLegOffset = -1; rLegOffset = 1; }
    if (frame == 2) { lLegOffset = 1; rLegOffset = -1; }
    c.rect(ox+4, oy+11, 3, 3, pants[0], pants[1], pants[2]);
    c.rect(ox+9, oy+11, 3, 3, pants[0], pants[1], pants[2]);
    // Shoe left/right with walk offset
    c.rect(ox+4, oy+14+lLegOffset, 3, 1, shoes[0], shoes[1], shoes[2]);
    c.rect(ox+9, oy+14+rLegOffset, 3, 1, shoes[0], shoes[1], shoes[2]);
  }
}

int _lighter(int v) => (v + 40).clamp(0, 255);
