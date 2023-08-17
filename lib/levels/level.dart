import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:pixel_adventure/actors/player.dart';

class Level extends World {
  final String levelName;
  final Player player;
  Level({required this.levelName, required this.player});
  late TiledComponent level;

  // This will run when the level is being loaded.
  // Add futureOr if the return value could be synchronous (immediate) or asynchronous (future).
  @override
  FutureOr<void> onLoad() async {
    // Load the Tiled map named 'level-01.tmx' with each tile size being 16x16 units.
    // The Vector2.all(16) means that both width and height of each tile is set to 16 units.
    level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));
    // Add the loaded level to the game's components to be rendered and updated
    add(level);
    // getLayer is a method that can fetch a layer of any type from the tile map.
    // <ObjectGroup> is a generic type argument. By using this, you're specifically telling the getLayer method that you expect it to return a layer that contains objects (like spawn points) and not just tiles.
    final spawnPointLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');
    // ! is a null assertion operator, telling dart that spawnPointLayer is not null for sure.
    for (final spawnPoint in spawnPointLayer!.objects) {
      switch (spawnPoint.class_) {
        case 'Player':
          // Add player to specific spawn location.
          player.position = Vector2(spawnPoint.x, spawnPoint.y);
          add(player);
          break;
        default:
      }
    }

    // Make sure to call the onLoad method on the class we inherit from, at the end.
    return super.onLoad();
  }
}
