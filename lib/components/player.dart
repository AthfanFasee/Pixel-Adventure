import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/components/checkpoint.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/components/fruit.dart';
import 'package:pixel_adventure/components/saw.dart';
import 'package:pixel_adventure/components/text_box.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState { idle, running, jumping, falling, hit, appear, dissapear }

// Which class we extend from depens on scenario.
// SpriteAnimationGroupComponent helps easily switching between a lot of animations (states like running, jumping).
// The HasGameRef mixin allows this component to access a reference to the main game class, PixelAdventure.
class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
  // The chosen character type for the player (passed via constructor).
  String character;
  // The position if passed will directly be assigned to the parent(super) class's position variable.
  // If no character is passed via constructor Ninja Frog will be used as default.
  Player({position, this.character = 'Ninja Frog'}) : super(position: position);

  final double stepTime = 0.05;
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runAnimation;
  late final SpriteAnimation jumpAnimation;
  late final SpriteAnimation fallAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearAnimation;
  late final SpriteAnimation disappearAnimation;

  final double _gravity = 10;
  final double _jumpForce = 250;
  final double _terminalVelocity = 300;
  double horizontalMovement = 0;
  double movementSpeed = 100;
  Vector2 startingPosition = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool hasJumped = false;
  bool gotHit = false;
  bool reachedCheckpoint = false;
  List<CollisionBlock> collisionBlocks = [];
  CustomHitbox hitbox =
      CustomHitbox(offsetX: 10, offsetY: 4, width: 14, height: 28);
  double fixedDeltaTime = 1 / 60;
  double accumulatedTime = 0;

  @override
  FutureOr<void> onLoad() {
    // _ means private method (only used in this class itself (or library) just as something which makes code clean).
    _loadAllAnimations();
    // debugMode = true;
    startingPosition = Vector2(position.x, position.y);
    add(RectangleHitbox(
        position: Vector2(hitbox.offsetX, hitbox.offsetY),
        size: Vector2(hitbox.width, hitbox.height)));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    accumulatedTime += dt;
    // Make sure jumping is same in all fps.
    while (accumulatedTime >= fixedDeltaTime) {
      if (!gotHit && !reachedCheckpoint) {
        _updatePlayerState();
        _updatePlayerMovement(fixedDeltaTime);
        _checkHorizontalCollisions();
        _applyGravity(fixedDeltaTime);
        _checkVerticalCollisions();
      }
      accumulatedTime -= fixedDeltaTime;
    }
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

    hasJumped = keysPressed.contains(LogicalKeyboardKey.space);
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!reachedCheckpoint) {
      if (other is Fruit) other.collidedWithPlayer();
      if (other is Saw) _respawn();
      if (other is Checkpoint && !reachedCheckpoint) _reachedCheckpoint();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  // Load and set up the animations that the `Player` class will use.
  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation('Idle', 11);
    runAnimation = _spriteAnimation('Run', 12);
    jumpAnimation = _spriteAnimation('Jump', 1);
    fallAnimation = _spriteAnimation('Fall', 1);
    hitAnimation = _spriteAnimation('Hit', 7)..loop = false;
    appearAnimation = _specialSpriteAnimation('Appearing', 7);
    disappearAnimation = _specialSpriteAnimation('Desappearing', 7);

    // List of all animations.
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runAnimation,
      PlayerState.jumping: jumpAnimation,
      PlayerState.falling: fallAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appear: appearAnimation,
      PlayerState.dissapear: disappearAnimation,
    };
    // Set current animation.
    current = PlayerState.idle;
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

  SpriteAnimation _specialSpriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
        game.images.fromCache('Main Characters/$state (96x96).png'),
        SpriteAnimationData.sequenced(
            amount: amount,
            stepTime: stepTime,
            textureSize: Vector2.all(96),
            loop: false));
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    // Adjust the player's appearance and state based on its current velocity and scale.
    // Player is moving left (velocity.x < 0) but is still facing right (scale.x > 0).
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
      // Player is moving right (velocity.x > 0) but is still facing left (scale.x < 0).
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    // If moving, set player state to running
    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;
    // If falling, set player state to falling
    if (velocity.y > 0) playerState = PlayerState.falling;
    // If jumping, set player state to jumping
    if (velocity.y < 0) playerState = PlayerState.jumping;
    current = playerState;
  }

  void _updatePlayerMovement(double dt) {
    if (hasJumped && isOnGround) _playerJump(dt);
    velocity.x = horizontalMovement * movementSpeed;
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    if (game.playSounds) {
      FlameAudio.play('sfx/jump.wav', volume: game.soundVolume);
    }
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else {
        if (checkCollision(this, block)) {
          // velocity.y > 0 means we are falling
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
          // velocity.y < 0 means player is above the ground (jumping).
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
          }
        }
      }
    }
  }

  void _respawn() async {
    if (game.playSounds) {
      FlameAudio.play('sfx/hit.wav', volume: game.soundVolume);
    }
    const canMoveDuration = Duration(milliseconds: 400);

    gotHit = true;
    current = PlayerState.hit;

    // When an animation plays, wait for it to finish and then reset ticker so it can be used for other animations.
    await animationTicker?.completed;
    animationTicker?.reset();

    // Make sure appearing animation plays in the correct position.
    position = startingPosition - Vector2.all(32);
    current = PlayerState.appear;

    await animationTicker?.completed;
    animationTicker?.reset();

    velocity = Vector2.zero();
    position = startingPosition;
    _updatePlayerState();
    Future.delayed(canMoveDuration, () => gotHit = false);
  }

  void _reachedCheckpoint() async {
    reachedCheckpoint = true;
    if (game.playSounds) {
      FlameAudio.play('sfx/disappear.wav', volume: game.soundVolume);
    }
    // Make sure disappear animation plays at the right spot.
    if (scale.x > 0) {
      position = position - Vector2.all(32);
    } else if (scale.x < 0) {
      position = position + Vector2(32, -32);
    }
    current = PlayerState.dissapear;

    await animationTicker?.completed;
    animationTicker?.reset();

    reachedCheckpoint = false;
    // Player shouldn't be on screen after disappear animation plays.
    position = Vector2.all(-640);

    const waitToShowText = Duration(seconds: 1);
    Future.delayed(waitToShowText, () {
      // Create the text box component
      MyTextBox textBox = MyTextBox(
          text: "You Won!",
          position: gameRef.size / 2,
          anchor: Anchor.centerLeft);
      // Add the text box to the game
      gameRef.add(textBox);
    });
  }
}
