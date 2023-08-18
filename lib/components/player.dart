import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState { idle, running }

// Which class we extend from depens on scenario.
// SpriteAnimationGroupComponent helps easily switching between a lot of animations (states like running, jumping).
// The HasGameRef mixin allows this component to access a reference to the main game class, PixelAdventure.
class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler {
  // The chosen character type for the player (passed via constructor).
  String character;
  // The position if passed will directly be assigned to the parent(super) class's position variable.
  // If no character is passed via constructor Ninja Frog will be used as default.
  Player({position, this.character = 'Ninja Frog'}) : super(position: position);

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runAnimation;
  final double stepTime = 0.05;

  double horizontalMovement = 0;
  double movementSpeed = 100;
  Vector2 velocity = Vector2.zero();

  @override
  FutureOr<void> onLoad() {
    // _ means private method (only used in this class itself (or library) just as something which makes code clean).
    _loadAllAnimations();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updatePlayerState();
    _updatePlayerMovement(dt);
    super.update(dt);
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);

    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;
    return super.onKeyEvent(event, keysPressed);
  }

  // Load and set up the animations that the `Player` class will use.
  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation('Idle', 11);
    runAnimation = _spriteAnimation('Run', 12);

    // List of all animations.
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runAnimation
    };
    // Set current animation.
    current = PlayerState.running;
  }

  // Animation is sourced from a sprite sheet, which contains multiple frames that make up the animation sequence.
  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
        // game is a reference to the game instance, provided by the mixin `HasGameRef<PixelAdventure>`.
        game.images.fromCache('Main Characters/$character/$state (32x32).png'),
        SpriteAnimationData.sequenced(
            // - The animation has 11 frames. Each frame lasts for a duration of `stepTime` seconds. Each frame has a size of 32x32 pixels.
            amount: amount,
            stepTime: stepTime,
            textureSize: Vector2.all(32)));
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    // If moving, set player state to running
    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;

    current = playerState;
  }

  void _updatePlayerMovement(double dt) {
    velocity.x = horizontalMovement * movementSpeed;
    position.x += velocity.x * dt;
  }
}
