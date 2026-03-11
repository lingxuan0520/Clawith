import 'dart:math' as math;
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

/// An Agent NPC sitting at a desk.
class AgentNpc extends SimpleNpc with Sensor<Player> {
  final String agentId;
  final String agentName;
  final String? agentStatus;
  final String? agentTask; // current task description (optional)
  final int colorVariant;
  final void Function(AgentNpc npc)? onPlayerContact;
  final void Function(AgentNpc npc)? onPlayerLeave;

  bool playerNearby = false;
  double _time = 0;

  AgentNpc({
    required this.agentId,
    required this.agentName,
    required Vector2 position,
    this.agentStatus,
    this.agentTask,
    this.colorVariant = 0,
    this.onPlayerContact,
    this.onPlayerLeave,
  }) : super(
          position: position,
          size: Vector2(14, 14),
          speed: 0,
          animation: SimpleDirectionAnimation(
            idleRight: SpriteAnimation.load(
              'npc/npc.png',
              SpriteAnimationData.sequenced(
                amount: 2,
                stepTime: 0.8,
                textureSize: Vector2(16, 16),
                texturePosition: Vector2(0, (colorVariant % 8) * 16.0),
              ),
            ),
            runRight: SpriteAnimation.load(
              'npc/npc.png',
              SpriteAnimationData.sequenced(
                amount: 2,
                stepTime: 0.6,
                textureSize: Vector2(16, 16),
                texturePosition: Vector2(0, (colorVariant % 8) * 16.0),
              ),
            ),
            enabledFlipX: false,
          ),
          initDirection: Direction.down,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(
      size: Vector2(42, 42),
      position: Vector2(-14, -14),
      collisionType: CollisionType.passive,
      isSolid: false,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void onContact(Player component) {
    if (!playerNearby) {
      playerNearby = true;
      onPlayerContact?.call(this);
    }
  }

  @override
  void onContactExit(Player component) {
    playerNearby = false;
    onPlayerLeave?.call(this);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderStatusBadge(canvas);
    _renderNameTag(canvas);
    if (playerNearby) _renderContactGlow(canvas);
  }

  // ── Name tag ──────────────────────────────────────
  void _renderNameTag(Canvas canvas) {
    final label =
        agentName.length > 9 ? '${agentName.substring(0, 8)}…' : agentName;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 3.8,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // background pill
    final bgRect = Rect.fromCenter(
      center: Offset(size.x / 2, -7),
      width: tp.width + 4,
      height: tp.height + 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(2)),
      Paint()..color = Colors.black.withAlpha(160),
    );
    tp.paint(canvas, Offset((size.x - tp.width) / 2, bgRect.top + 1));
  }

  // ── Status badge above name ────────────────────────
  void _renderStatusBadge(Canvas canvas) {
    switch (agentStatus) {
      case 'running':
        _renderRunningBadge(canvas);
        break;
      case 'idle':
        _renderIdleBadge(canvas);
        break;
      case 'error':
        _renderErrorBadge(canvas);
        break;
      default:
        _renderOfflineBadge(canvas);
    }
  }

  void _renderRunningBadge(Canvas canvas) {
    // Spinning arc to show "busy / working"
    final center = Offset(size.x / 2, -16);
    const radius = 4.0;
    final angle = _time * 4.0; // rotation speed

    // Background circle
    canvas.drawCircle(center, radius,
        Paint()..color = const Color(0xFF1A2A1A));
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF34D399)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);

    // Spinning arc
    final arcPaint = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 0.5),
      angle,
      math.pi * 1.2,
      false,
      arcPaint,
    );

    // "▶" play icon in center
    final iconTp = TextPainter(
      text: const TextSpan(
        text: '▶',
        style: TextStyle(color: Color(0xFF34D399), fontSize: 3),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconTp.paint(
        canvas, Offset(center.dx - iconTp.width / 2, center.dy - iconTp.height / 2));

    // Task label (truncated) below spinning circle
    if (agentTask != null && agentTask!.isNotEmpty) {
      final task = agentTask!.length > 12
          ? '${agentTask!.substring(0, 11)}…'
          : agentTask!;
      final tp = TextPainter(
        text: TextSpan(
          text: task,
          style: const TextStyle(
            color: Color(0xFF34D399),
            fontSize: 3.2,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.x - tp.width) / 2, -11));
    }
  }

  void _renderIdleBadge(Canvas canvas) {
    // Pulsing yellow dot — "available"
    final pulse = (math.sin(_time * 2.5) + 1) / 2; // 0..1
    final alpha = (140 + (pulse * 115)).toInt();
    final center = Offset(size.x / 2, -16);
    canvas.drawCircle(
        center, 3.5, Paint()..color = Color.fromARGB(alpha ~/ 3, 251, 191, 36));
    canvas.drawCircle(
        center, 2.5, Paint()..color = Color.fromARGB(alpha, 251, 191, 36));

    final tp = TextPainter(
      text: const TextSpan(
        text: 'Idle',
        style: TextStyle(
          color: Color(0xFFFBBF24),
          fontSize: 3.2,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, -11));
  }

  void _renderErrorBadge(Canvas canvas) {
    // Red exclamation
    final center = Offset(size.x / 2, -16);
    canvas.drawCircle(center, 3.5,
        Paint()..color = const Color(0xFFEF4444));
    final tp = TextPainter(
      text: const TextSpan(
        text: '!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 5,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));

    final labelTp = TextPainter(
      text: const TextSpan(
        text: 'Error',
        style: TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 3.2,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelTp.paint(canvas, Offset((size.x - labelTp.width) / 2, -11));
  }

  void _renderOfflineBadge(Canvas canvas) {
    // Grey dot — offline/stopped
    final center = Offset(size.x / 2, -16);
    canvas.drawCircle(center, 2.5,
        Paint()..color = const Color(0xFF4B5563));
    canvas.drawCircle(
        center,
        2.5,
        Paint()
          ..color = const Color(0xFF6B7280)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);
  }

  // ── Contact glow ──────────────────────────────────
  void _renderContactGlow(Canvas canvas) {
    final pulse = (math.sin(_time * 5) + 1) / 2;
    final alpha = (60 + (pulse * 80)).toInt();
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      10,
      Paint()..color = Color.fromARGB(alpha, 90, 150, 255),
    );
  }
}
