import 'package:bonfire/bonfire.dart';

/// The user's character controlled via joystick.
/// Sprite: player.png — 64×128 (4 frames × 4 dirs, each frame 16×32)
/// Row 0: Down, Row 1: Left, Row 2: Right, Row 3: Up
class OfficePlayer extends SimplePlayer with BlockMovementCollision {
  final void Function()? onInteract;

  OfficePlayer({
    required Vector2 position,
    this.onInteract,
  }) : super(
          position: position,
          size: Vector2(28, 56), // 16×32 scaled up slightly
          speed: 120,
          animation: SimpleDirectionAnimation(
            // Down (facing camera) — row 0
            idleDown: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1,
                textureSize: Vector2(16, 32),
                texturePosition: Vector2(0, 0),
              ),
            ),
            runDown: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 4,
                stepTime: 0.15,
                textureSize: Vector2(16, 32),
                texturePosition: Vector2(0, 0),
              ),
            ),
            // Left — row 1
            idleLeft: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1,
                textureSize: Vector2(16, 32),
                texturePosition: Vector2(0, 32),
              ),
            ),
            runLeft: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 4,
                stepTime: 0.15,
                textureSize: Vector2(16, 32),
                texturePosition: Vector2(0, 32),
              ),
            ),
            // Right — row 2
            idleRight: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1,
                textureSize: Vector2(16, 32),
                texturePosition: Vector2(0, 64),
              ),
            ),
            runRight: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 4,
                stepTime: 0.15,
                textureSize: Vector2(16, 32),
                texturePosition: Vector2(0, 64),
              ),
            ),
            // Up — row 3
            idleUp: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1,
                textureSize: Vector2(16, 32),
                texturePosition: Vector2(0, 96),
              ),
            ),
            runUp: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 4,
                stepTime: 0.15,
                textureSize: Vector2(16, 32),
                texturePosition: Vector2(0, 96),
              ),
            ),
            enabledFlipX: false,
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(
      size: Vector2(20, 20),
      position: Vector2(4, 36),
      collisionType: CollisionType.active,
    ));
  }

  @override
  void onJoystickAction(JoystickActionEvent event) {
    if (event.id == 1 && event.event == ActionEvent.DOWN) {
      onInteract?.call();
    }
    super.onJoystickAction(event);
  }
}
