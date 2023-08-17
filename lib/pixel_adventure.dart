import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:pixel_adventure/levels/level.dart';

class PixelAdventure extends FlameGame {
  // A trick to remove 2 black side borders by
  // setting the game's background color to a specific value to blend seamlessly with the game world's background.
  @override
  // An arrow function which returns an instance of the Color class.
  // Determines the background color of the game screen.
  Color backgroundColor() => const Color(0xFF211F30);

  late final CameraComponent cam;
  final world = Level();

  @override
  FutureOr<void> onLoad() {
    // Initialize the game camera with a fixed resolution. This resolution defines the size of the "window" through which we see the game world.
    cam = CameraComponent.withFixedResolution(
        world: world, width: 640, height: 360);
    // Position the camera's viewfinder to the top-left corner of the game world. By default, it might be centered.
    cam.viewfinder.anchor = Anchor.topLeft;

    // Add the camera and game level to the game's components. These will be rendered and updated in the game loop.
    addAll([cam, world]);
    return super.onLoad();
  }
}
