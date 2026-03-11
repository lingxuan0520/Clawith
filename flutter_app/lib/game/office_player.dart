import 'package:bonfire/bonfire.dart';

/// The user's character controlled via joystick.
class OfficePlayer extends SimplePlayer with BlockMovementCollision {
  final void Function()? onInteract;

  OfficePlayer({
    required Vector2 position,
    this.onInteract,
  }) : super(
          position: position,
          size: Vector2(14, 14),
          speed: 60,
          animation: SimpleDirectionAnimation(
            // Down (facing camera) — row 0 in spritesheet
            idleDown: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1,
                textureSize: Vector2(16, 16),
                texturePosition: Vector2(0, 0),
              ),
            ),
            runDown: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 3,
                stepTime: 0.15,
                textureSize: Vector2(16, 16),
                texturePosition: Vector2(0, 0),
              ),
            ),
            // Left — row 1
            idleLeft: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1,
                textureSize: Vector2(16, 16),
                texturePosition: Vector2(0, 16),
              ),
            ),
            runLeft: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 3,
                stepTime: 0.15,
                textureSize: Vector2(16, 16),
                texturePosition: Vector2(0, 16),
              ),
            ),
            // Right — row 2
            idleRight: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1,
                textureSize: Vector2(16, 16),
                texturePosition: Vector2(0, 32),
              ),
            ),
            runRight: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 3,
                stepTime: 0.15,
                textureSize: Vector2(16, 16),
                texturePosition: Vector2(0, 32),
              ),
            ),
            // Up — row 3
            idleUp: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1,
                textureSize: Vector2(16, 16),
                texturePosition: Vector2(0, 48),
              ),
            ),
            runUp: SpriteAnimation.load(
              'player/player.png',
              SpriteAnimationData.sequenced(
                amount: 3,
                stepTime: 0.15,
                textureSize: Vector2(16, 16),
                texturePosition: Vector2(0, 48),
              ),
            ),
            enabledFlipX: false,
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(
      size: Vector2(10, 10),
      position: Vector2(2, 4),
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
