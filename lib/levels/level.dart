import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class Level extends World {
  late TiledComponent level;

  // This will run when the level is being loaded.
  // Add futureOr if the return value could be synchronous (immediate) or asynchronous (future).
  @override
  FutureOr<void> onLoad() async {
    // Load the Tiled map named 'level-01.tmx' with each tile size being 16x16 units.
    // The Vector2.all(16) means that both width and height of each tile is set to 16 units.
    level = await TiledComponent.load('level-01.tmx', Vector2.all(16));
    // Add the loaded level to the game's components to be rendered and updated
    add(level);

    // Make sure to call the onLoad method on the class we inherit from, at the end.
    return super.onLoad();
  }
}
