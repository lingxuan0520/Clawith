import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

/// An Agent NPC sitting at a desk. Uses Sensor<Player> to detect proximity.
class AgentNpc extends SimpleNpc with Sensor<Player> {
  final String agentId;
  final String agentName;
  final String? agentStatus;
  final int colorVariant;
  final void Function(AgentNpc npc)? onPlayerContact;
  final void Function(AgentNpc npc)? onPlayerLeave;

  bool playerNearby = false;

  AgentNpc({
    required this.agentId,
    required this.agentName,
    required Vector2 position,
    this.agentStatus,
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
    // Override the default sensor hitbox with a larger interaction radius
    // The Sensor mixin will have added a basic hitbox in super.onLoad()
    // We add a wider sensor hitbox so the player can be detected nearby
    add(RectangleHitbox(
      size: Vector2(40, 40),
      position: Vector2(-13, -13),
      collisionType: CollisionType.passive,
      isSolid: false,
    ));
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
    _renderNameTag(canvas);
    _renderStatusDot(canvas);
    if (playerNearby) {
      _renderInteractHint(canvas);
    }
  }

  void _renderNameTag(Canvas canvas) {
    final label = agentName.length > 8
        ? '${agentName.substring(0, 7)}…'
        : agentName;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 4,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, -6));
  }

  void _renderInteractHint(Canvas canvas) {
    // Draw a glowing "chat" dot above the character
    final paint = Paint()..color = const Color(0xFF5A96FF);
    canvas.drawCircle(Offset(size.x / 2, -9), 2, paint);
    canvas.drawCircle(Offset(size.x / 2, -9), 2,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 0.5);
  }

  void _renderStatusDot(Canvas canvas) {
    Color dotColor;
    switch (agentStatus) {
      case 'running':
        dotColor = const Color(0xFF34D399);
        break;
      case 'idle':
        dotColor = const Color(0xFFFBBF24);
        break;
      case 'error':
        dotColor = const Color(0xFFEF4444);
        break;
      default:
        dotColor = const Color(0xFF6B7280);
    }
    canvas.drawCircle(
      Offset(size.x - 1.5, 1.5),
      2,
      Paint()..color = dotColor,
    );
  }
}
